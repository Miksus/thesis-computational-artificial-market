
mutable struct BuyLimitOrder <: LimitOrder
    dealer::Union{AbstractInvestor, String}
    price::Float64
    quantity::Int64

    timestamp::Int64
    function BuyLimitOrder(dealer::Union{AbstractInvestor, String}; price, quantity)
        new(dealer, price, quantity, 0)
    end
end

mutable struct SellLimitOrder <: LimitOrder
    dealer::Union{AbstractInvestor, String}
    price::Float64
    quantity::Int64

    timestamp::Int64
    function SellLimitOrder(dealer::Union{AbstractInvestor, String}; price, quantity)
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

    seller::Union{String, AbstractInvestor}
    buyer::Union{String, AbstractInvestor}
end

"Settle limit orders"
function settle!(buy::BuyLimitOrder, sell::SellLimitOrder, stock::AbstractAsset; side=:equal)
    if side == :equal
        price = (buy.price + sell.price) / 2
        buy_price = price
        sell_price = price
    elseif side == :sell
        price = sell.price
        buy_price = price
        sell_price = price
    elseif side == :buy
        price = buy.price
        buy_price = price
        sell_price = price
    else
        throw(DomainError(side, "Invalid settling side"))
    end
    quantity = getquantity(buy, sell)
    println("\nTrade between $(buy.dealer.name) and $(sell.dealer.name): $(Float64(price)) x $quantity")
    # println("$(buy.dealer.name) --- $(buy.quantity) --> $(sell.dealer.name)")
    # println("$(buy.dealer.name) <-- $(buy.quantity * price) ---$(sell.dealer.name)")

    sell.dealer[cash] += quantity * sell_price
    buy.dealer[cash] -= quantity * buy_price

    sell.dealer[stock] -= quantity
    buy.dealer[stock] += quantity
    #decrease(sell.dealer, quantity, stock)
    #increase(sell.dealer, quantity, stock)

    #sell.dealer.position -= quantity
    #buy.dealer.position += quantity

    spread = buy_price - sell_price
    return Trade(price, quantity, sell.dealer, buy.dealer)
end


# Allow argument order insensitive
settle!(buy::SellLimitOrder, sell::BuyLimitOrder, asset::AbstractAsset; side=:equal) = settle!(sell, buy, asset, side=side)

getprice() = buy.timestamp < sell.timestamp ? buy.price : sell.price
getquantity(buy::BuyLimitOrder, sell::SellLimitOrder) = min(buy.quantity, sell.quantity)
