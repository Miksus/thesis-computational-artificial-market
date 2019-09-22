mutable struct BuyLimitOrder <: LimitOrder
    dealer::SingleAssetInvestor
    price::Float64
    quantity::Int64

    timestamp::Int64
    function BuyLimitOrder(dealer::SingleAssetInvestor, price, quantity)
        new(dealer, price, quantity, 0)
    end
end

mutable struct SellLimitOrder <: LimitOrder
    dealer::SingleAssetInvestor
    price::Float64
    quantity::Int64

    timestamp::Int64
    function SellLimitOrder(dealer::SingleAssetInvestor, price, quantity)
        new(dealer, price, quantity, 0)
    end
end
