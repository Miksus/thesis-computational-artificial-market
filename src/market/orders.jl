
mutable struct BuyLimitOrder <: LimitOrder
    dealer::Union{Investor, String}
    price::Float64
    quantity::Int64

    timestamp::Int64
    function BuyLimitOrder(dealer::Union{Investor, String}; price, quantity)
        new(dealer, price, quantity, 0)
    end
end

mutable struct SellLimitOrder <: LimitOrder
    dealer::Union{Investor, String}
    price::Float64
    quantity::Int64

    timestamp::Int64
    function SellLimitOrder(dealer::Union{Investor, String}; price, quantity)
        new(dealer, price, quantity, 0)
    end
end


function place!(market::AbstractMarket, order::LimitOrder)
    nth = market.timestamp + 1
    order.timestamp = nth
    market.timestamp = nth
    _place!(market, order)
end

function _place!(market::AbstractMarket, order::BuyLimitOrder)
    push!(market.buy_limit_orders, order)
end

function _place!(market::AbstractMarket, order::SellLimitOrder)
    push!(market.sell_limit_orders, order)
end


struct Trade
    price::Float64
    quantity::Int64

    spread::Float64

    seller::Union{String, Investor}
    buyer::Union{String, Investor}
end

"Settle limit orders"
function settle!(buy::BuyLimitOrder, sell::SellLimitOrder; method=:fair)
    if method == :fair
        price = (buy.price + sell.price) / 2
        buy_price = price
        sell_price = price
    elseif method == :middleman
        price = (buy.price + sell.price) / 2
        buy_price = buy.price
        sell_price = sell.price
    elseif method == :sell_side
        price = sell.price
        buy_price = price
        sell_price = price
    elseif method == :buy_side
        price = buy.price
        buy_price = price
        sell_price = price
    else
        throw(DomainError(method, "Invalid settling method"))
    end
    quantity = getquantity(buy, sell)
    println("\nTrade between $(buy.dealer.name) and $(sell.dealer.name): $(Float64(price)) x $quantity")
    # println("$(buy.dealer.name) --- $(buy.quantity) --> $(sell.dealer.name)")
    # println("$(buy.dealer.name) <-- $(buy.quantity * price) ---$(sell.dealer.name)")

    sell.dealer.cash += quantity * sell_price
    buy.dealer.cash -= quantity * buy_price

    sell.dealer.position -= quantity
    buy.dealer.position += quantity

    spread = buy_price - sell_price
    return Trade(price, quantity, spread, sell.dealer, buy.dealer)
end

# Allow argument order insensitive
settle!(buy::SellLimitOrder, sell::BuyLimitOrder; method=:fair) = settle!(sell, buy, method=method)

getprice() = buy.timestamp < sell.timestamp ? buy.price : sell.price
getquantity(buy::BuyLimitOrder, sell::SellLimitOrder) = min(buy.quantity, sell.quantity)
