mutable struct DoubleAuctionMarket <: AbstractMarket
    name::String
    last_price::Float64
    sell_limit_orders::Array{SellLimitOrder, 1}
    buy_limit_orders::Array{BuyLimitOrder, 1}

    function DoubleAuctionMarket(name::String)
        new(name, NaN, Array{SellLimitOrder, 1}(), Array{BuyLimitOrder, 1}())
    end
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


getprice(buy::BuyLimitOrder, sell::SellLimitOrder) = mean([buy.price, sell.price])
getquantity(buy::BuyLimitOrder, sell::SellLimitOrder) = min(buy.quantity, sell.quantity)


"Settle market"
function clear!(market::DoubleAuctionMarket)
    println("Initializing settling")
    settle!(market.buy_limit_orders, market.sell_limit_orders, market)
end


"Settle limit order books"
function settle!(buy_book::Array{BuyLimitOrder, 1}, sell_book::Array{SellLimitOrder, 1}, market::DoubleAuctionMarket)

    trade_prices = Array{Float64, 1}()
    trade_quantities = Array{Int64, 1}()
    while maxprice(buy_book) >= minprice(sell_book)

        index_sell = argmin(map(x -> x.price, sell_book))
        index_buy = argmax(map(x -> x.price, buy_book))

        order_sell = sell_book[index_sell]
        order_buy = buy_book[index_buy]


        price, quantity = settle!(order_buy, order_sell)

        trade_quantity = getquantity(order_buy, order_sell)
        sell_book[index_sell].quantity -= trade_quantity
        buy_book[index_buy].quantity -= trade_quantity

        if sell_book[index_sell].quantity == 0
            deleteat!(sell_book, index_sell)
        end
        if buy_book[index_buy].quantity == 0
            deleteat!(buy_book, index_buy)
        end

        push!(trade_prices, price)
        push!(trade_quantities, quantity)
    end
    market.last_price = sum(trade_prices.* float(trade_quantities)) / sum(float(trade_quantities))
    return trade_prices, trade_quantities
end

"Settle limit orders"
function settle!(buy::BuyLimitOrder, sell::SellLimitOrder)
    price = getprice(buy, sell)
    quantity = getquantity(buy, sell)
    println("\nTrade between $(buy.dealer.name) and $(sell.dealer.name): $(Float64(price)) x $quantity")
    # println("$(buy.dealer.name) --- $(buy.quantity) --> $(sell.dealer.name)")
    # println("$(buy.dealer.name) <-- $(buy.quantity * price) ---$(sell.dealer.name)")

    sell.dealer.cash += quantity * price
    buy.dealer.cash -= quantity * price

    sell.dealer.position -= quantity
    buy.dealer.position += quantity
    return price, quantity
end




function place!(market::AbstractMarket, order::BuyLimitOrder)
    push!(market.buy_limit_orders, order)
end

function place!(market::AbstractMarket, order::SellLimitOrder)
    push!(market.sell_limit_orders, order)
end

"Cancel all orders"
function cancel!(market::DoubleAuctionMarket)
    market.sell_limit_orders = typeof(market.sell_limit_orders)()
    market.buy_limit_orders = typeof(market.buy_limit_orders)()
end
