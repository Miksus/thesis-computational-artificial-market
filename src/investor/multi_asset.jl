
mutable struct MultiAssetInvestor <: AbstractInvestor
    name::String
    cash::Float64
    position::Dict{AbstractAsset, Int64}

    decide::Function
    trade_with::Function

    function MultiAssetInvestor(name; cash=0, positions=nothing, order_decision::Function, stock_decision::Function)
        if positions == nothing
            positions = Dict{AbstractAsset, Int64}()
        end
        new(name, cash, positions, order_decision, stock_decision)
    end

    function MultiAssetInvestor(name; cash=0, positions=0,
        market_filter::Expr,
        quantity_expr::Expr, price_expr::Expr, order_expr::Expr)

        trade_with_func = _get_trade_with_func(market_filter)
        decision_func = _get_decision_func(quantity_expr, price_expr, order_expr)

        new(name, cash, positions, decision_func, trade_with_func)
    end
end

"
Allowed expression symbols: cash, position, last_price, trader, market, all_markets
    Additional: max_quantity, max_price
"
function _get_decision_func(quantity_expr::Expr, price_expr::Expr, order_expr::Expr)
    max_quantity = :(order == SellLimitOrder ? position : order == BuyLimitOrder ? floor(cash/price) : throw(DomainError(order, "Not implmented placement")))
    max_price = :(order == SellLimitOrder ? Inf : order == BuyLimitOrder ? cash / quantity : throw(DomainError(order, "Not implmented placement")))

    # Add predefined conventions
    quantity_expr = substitute(quantity_expr, :max_quantity, max_quantity)
    price_expr = substitute(price_expr, :max_price, max_price)

    exp_1, exp_2, exp_3 = get_expression_order(:(price = $price_expr), :(quantity = $quantity_expr), :(order = $order_expr))
    func = quote
        function get_order(cash, position, last_price, trader, market, all_markets)
            $exp_1
            $exp_2
            $exp_3
            return order(trader, price=price, quantity=quantity)
        end
    end # End of Quote
    return eval(func)
end

"
Allowed expression symbols: market, markets
"
function _get_trade_with_func(market_filter::Expr)
    func = quote
        function get_markets(trader, markets)
            trading_markets = Array{AbstractMarket, 1}()
            for market in markets
                if $market_filter
                    push!(trading_markets, market)
                end
            end
            return trading_markets
        end
    end # End of Quote
    return eval(func)
end


function place!(trader::MultiAssetInvestor, markets::Array{T, 1}) where T <: AbstractMarket
    markets = trader.trade_with(trader, markets)
    for market in markets
        position = get(trader.position, market.asset, 0)
        order = trader.decide(trader.cash, position, market.last_price, trader, market, markets)

        if order == nothing
            return
        end
        if order.quantity > 0
            place!(market, order)
        elseif order.quantity == 0
            # No need to add zero order to order book
            return
        elseif order.quantity < 0
            throw(DomainError(order, "Quantity of below 0 not accepted"))
        end
    end
end

function place_and_clear!(trader::MultiAssetInvestor, markets::Array{T, 1}) where T <: AbstractMarket
    markets = trader.trade_with(trader, markets)

    trades = Dict{AbstractMarket, Array{Trade, 1}}
    for market in markets
        position = get(trader.position, market.asset, 0)
        order = trader.decide(trader.cash, position, market.last_price, trader, market, markets)
        if order.quantity > 0
            settle!(market, order)
            #trades[market] = settle!(market, order)
            #return trades
        else
            trades[market] = Array{Trade, 1}()
        end
    end
end
