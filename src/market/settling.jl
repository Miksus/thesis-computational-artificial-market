

"Settle limit order books"
function settle!(buy_book::Array{BuyLimitOrder, 1}, sell_book::Array{SellLimitOrder, 1}, market::DoubleAuctionMarket)

    trades = Array{Trade, 1}()
    while maxprice(buy_book) >= minprice(sell_book)

        index_sell = argmin(map(x -> x.price, sell_book))
        index_buy = argmax(map(x -> x.price, buy_book))

        order_sell = sell_book[index_sell]
        order_buy = buy_book[index_buy]


        trade = settle!(order_buy, order_sell, market.asset, side=:equal)

        trade_quantity = getquantity(order_buy, order_sell)
        sell_book[index_sell].quantity -= trade.quantity
        buy_book[index_buy].quantity -= trade.quantity

        if sell_book[index_sell].quantity == 0
            deleteat!(sell_book, index_sell)
        end
        if buy_book[index_buy].quantity == 0
            deleteat!(buy_book, index_buy)
        end

        push!(trades, trade)
    end
    if length(trades) > 0
        trade_price_weights = map(x -> x.price * float(x.quantity), trades)
        trade_quantities = map(x -> x.quantity, trades)
        market.last_price = sum(trade_price_weights) / sum(float(trade_quantities))
    end
    return trades
end


"Settle One Sell Order"
function settle!(market::DoubleAuctionMarket, sell_order::SellLimitOrder)
    trades = Array{Trade, 1}()
    while (maxprice(market.buy_limit_orders) >= sell_order.price) & (sell_order.quantity > 0)
        trade = _settle_trade!(market.buy_limit_orders, sell_order, market.asset, side=:buy)
        market.last_price = trade.price
        push!(trades, trade)
    end
    if sell_order.quantity > 0
        # Not all fulfilled, putting rest to the order to orderbook
        place!(market, sell_order)
    end

    return trades
end

"Settle One Buy Order"
function settle!(market::DoubleAuctionMarket, buy_order::BuyLimitOrder)
    trades = Array{Trade, 1}()
    while (minprice(market.sell_limit_orders) <= buy_order.price) & (buy_order.quantity > 0)
        trade = _settle_trade!(market.sell_limit_orders, buy_order, market.asset, side=:sell)
        market.last_price = trade.price
        push!(trades, trade)
    end
    if buy_order.quantity > 0
        # Not all fulfilled, putting rest to the order to orderbook
        place!(market, buy_order)
    end

    return trades
end


"Settle One Trade"
function _settle_trade!(book::Array{T, 1}, order::LimitOrder, stock::AbstractAsset; side::Symbol) where T <: LimitOrder
    index_best = best_order_index(book)# argmax(map(x -> x.price, buy_book))
    best_counter_order = book[index_best]

    trade = settle!(order, best_counter_order, stock, side=side)
    book[index_best].quantity -= trade.quantity
    order.quantity -= trade.quantity

    if book[index_best].quantity == 0
        deleteat!(book, index_best)
    end

    return trade
end
best_order_index(book::Array{BuyLimitOrder, 1}) = argmax(map(x -> x.price, book))
best_order_index(book::Array{SellLimitOrder, 1}) = argmin(map(x -> x.price, book))
