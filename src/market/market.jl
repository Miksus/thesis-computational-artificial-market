

mutable struct DoubleAuctionMarket <: AbstractMarket
    asset::AbstractAsset
    last_price::Float64
    sell_limit_orders::Array{SellLimitOrder, 1}
    buy_limit_orders::Array{BuyLimitOrder, 1}

    timestamp::Int64
    function DoubleAuctionMarket(name::String)
        new(Stock(name), NaN, Array{SellLimitOrder, 1}(), Array{BuyLimitOrder, 1}(), 1)
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


# Market matching


"Settle market"
function clear!(market::DoubleAuctionMarket)
    println("Initializing settling")
    settle!(market.buy_limit_orders, market.sell_limit_orders, market)
end

"Cancel all orders"
function cancel!(market::DoubleAuctionMarket)
    market.sell_limit_orders = typeof(market.sell_limit_orders)()
    market.buy_limit_orders = typeof(market.buy_limit_orders)()
end
