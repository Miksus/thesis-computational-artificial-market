

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

function get_prices(orders::Array{<:LimitOrder, 1})
    return [order.price for order in orders]
end

function get_equlibrium(bids::Array{BidLimitOrder, 1}, asks::Array{AskLimitOrder, 1})
    clearable_quantities = Dict{Int64, Int64}()
    
    prices = Set(vcat(get_prices(bids), get_prices(asks)))
    
    for price_level in prices
        println(price_level)
        bids_clearable = [bid.quantity for bid in bids if bid.price >= price_level]
        
        asks_clearable = [ask.quantity for ask in asks if ask.price <= price_level]
        clearable_quantity = minimum([sum(bids_clearable), sum(asks_clearable)])
        
        #clearable_quantities = vcat(clearable_quantities, [price_level clearable_quantity])
        clearable_quantities[price_level] = clearable_quantity
    end
    
    #eq_quantity = findmax(clearable_quantities, dims=2)
    val, ind = findmax(clearable_quantities)
    eq_prices = [key for (key, val) in clearable_quantities if val == eq_quantity]

    eq_quantity = val
    eq_price = round(mean([minimum(eq_prices), maximum(eq_prices)]))
    return eq_quantity, eq_price
end