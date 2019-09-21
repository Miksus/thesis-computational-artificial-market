mutable struct BuyLimitOrder <: LimitOrder
    dealer::Investor
    price::Float64
    quantity::Int64
end

mutable struct SellLimitOrder <: LimitOrder
    dealer::Investor
    price::Float64
    quantity::Int64
end
