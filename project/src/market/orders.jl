
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


"Push order to the orderbook of the market"
function push!(market::AbstractMarket, order::BuyLimitOrder)
    push!(market.buy_limit_orders, order)
end

"Push order to the orderbook of the market"
function push!(market::AbstractMarket, order::SellLimitOrder)
    push!(market.sell_limit_orders, order)
end


get_clearable_quantity(buy::BuyLimitOrder, sell::SellLimitOrder) = min(buy.quantity, sell.quantity)
