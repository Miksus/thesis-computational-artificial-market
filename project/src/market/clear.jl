

function clear!(market::AbstractMarket)
    sell_book = market.sell_limit_orders
    buy_book = market.buy_limit_orders

    trades = Array{Trade, 1}()

    return clear!(buy_book, sell_book, market=market)
end


"Clear limit order books"
function clear!(buy_book::Array{BuyLimitOrder, 1}, sell_book::Array{SellLimitOrder, 1}; market)

    clearing_price = get_trade_price(market)

    trades = Array{Trade, 1}()

    # Clear empty orders before the clearing
    # ie. if an investor has set quantity
    # of an order to zero, it will be cleaned now
    clear_empty!(sell_book)
    clear_empty!(buy_book)

    while maxprice(buy_book) >= minprice(sell_book)

        order_sell = get_best(sell_book)
        order_buy = get_best(buy_book)
        
        trade_price = isnothing(clearing_price) ? get_trade_price(order_buy, order_sell, market=market) : clearing_price
        
        println("")
        println("------")
        println("Trade")
        println("Before buy $(order_buy.dealer.active_orders[market].quantity), sell $(order_sell.dealer.active_orders[market].quantity). Traders: $(order_buy.dealer.name) and $(order_sell.dealer.name)")
        trade = trade!(order_buy, order_sell, price=trade_price, from=market.currency, to=market.asset)
        println("After buy $(order_buy.dealer.active_orders[market].quantity), sell $(order_sell.dealer.active_orders[market].quantity)")
        println("------")
        println("")

        clear_empty!(sell_book)
        clear_empty!(buy_book)

        push!(trades, trade)
    end
    if ~isempty(trades)
        market.last_price = trades[end].price
    end
    return trades
end

function get_trade_price(market::AbstractMarket)
    # Must be redefined by market type. If not defined, nothing returned
    return nothing
end

