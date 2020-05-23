

# Utils

"Get best Bid offer from the buy order book (order with highest price)"
function get_best(buy_book::Array{BidLimitOrder, 1})
    index_for_best = argmax(map(x -> x.price, buy_book))
    return buy_book[index_for_best]
end

"Get best Ask offer from the buy order book (order with lowest price)"
function get_best(sell_book::Array{AskLimitOrder, 1})
    index_for_best = argmin(map(x -> x.price, sell_book))
    return sell_book[index_for_best]
end


function minprice(orders::Array{<:LimitOrder, 1})
    if isempty(orders)
        return NaN
    end
    prices = map(order -> order.price, orders)
    minimum(prices)
end

function maxprice(orders::Array{<:LimitOrder, 1})
    if isempty(orders)
        return NaN
    end
    prices = map(order -> order.price, orders)
    maximum(prices)
end

best_order_index(book::Array{BidLimitOrder, 1}) = argmax(map(x -> x.price, book))
best_order_index(book::Array{AskLimitOrder, 1}) = argmin(map(x -> x.price, book))

"Clear empty orders (orders with quantity of 0)"
function clear_empty!(book::Array{<:LimitOrder, 1})
    empty_orders = findall(x -> x.quantity <= 0, book)
    deleteat!(book, empty_orders)
end