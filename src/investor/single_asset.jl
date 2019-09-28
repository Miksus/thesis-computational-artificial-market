include("../utils/expressions.jl")
using Distributions

mutable struct SingleAssetInvestor <: Investor
    name::String
    cash::Float64
    position::Int64

    decide::Function

    function SingleAssetInvestor(name, cash=0, position=0; quantity_expr::Expr, price_expr::Expr, order_expr::Expr)

        max_quantity = :(order == SellLimitOrder ? position : order == BuyLimitOrder ? floor(cash/price) : throw(DomainError(order, "Not implmented placement")))
        max_price = :(order == SellLimitOrder ? Inf : order == BuyLimitOrder ? cash / quantity : throw(DomainError(order, "Not implmented placement")))

        # Add predefined conventions
        quantity_expr = substitute(quantity_expr, :max_quantity, max_quantity)
        price_expr = substitute(price_expr, :max_price, max_price)

        exp_1, exp_2, exp_3 = get_expression_order(:(price = $price_expr), :(quantity = $quantity_expr), :(order = $order_expr))
        decision_func = quote
            function get_order(cash, position, last_price, trader, market)
                $exp_1
                $exp_2
                $exp_3
                return order(trader, price=price, quantity=quantity)
            end
        end
        new(name, cash, position, eval(decision_func))
    end

    function SingleAssetInvestor(name::String, cash::Float64, position::Int64, func::Function)
        new(name, cash, position, func)
    end
end


function place!(trader::SingleAssetInvestor, market::AbstractMarket)
    order = trader.decide(trader.cash, trader.position, market.last_price, trader, market)

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

function place_and_clear!(trader::SingleAssetInvestor, market::AbstractMarket)
    order = trader.decide(trader.cash, trader.position, market.last_price, trader, market)
    if order.quantity > 0
        trades = settle!(market, order)
        return trades
    end
    return Array{Trade, 1}()
end
