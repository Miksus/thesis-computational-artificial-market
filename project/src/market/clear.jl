

function clear!(market::AbstractMarket)
    sell_book = get_sell_book(market)
    buy_book = get_buy_book(market)

    trades = Array{Trade, 1}()

    return clear!(buy_book, sell_book, market=market)
end


"Clear limit order books"
function clear!(buy_book::Array{BuyLimitOrder, 1}, sell_book::Array{SellLimitOrder, 1}; market)

    clearing_price = get_trade_price(market)

    trades = Array{Trade, 1}()
    while maxprice(buy_book) >= minprice(sell_book)

        order_sell = get_best(sell_book)
        order_buy = get_best(buy_book)
        
        trade_price = isnothing(clearing_price) ? get_trade_price(order_buy, order_sell, market=market) : clearing_price
        trade = trade!(order_buy, order_sell, price=trade_price)

        clear_empty!(sell_book)
        clear_empty!(buy_book)

        push!(trades, trade)
    end
    market.last_price = trades[end].price
    return trades
end

function get_trade_price(market::AbstractMarket)
    # Must be redefined by market type. If not defined, nothing returned
    return nothing
end

