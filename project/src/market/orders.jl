
mutable struct BuyLimitOrder <: LimitOrder
    dealer::Union{AbstractInvestor, String}
    price::Int64
    quantity::Int64

    from::AbstractAsset # This is the asset that is traded away (ie. currency in buy order)
    to::AbstractAsset # This is the asset that is traded to (ie. stock in buy order)

    timestamp::Int64
    function BuyLimitOrder(dealer::Union{AbstractInvestor, String}; price, quantity, from, to)
        new(
            dealer, 
            price, 
            quantity, 
            from, 
            to, 
            get_time()
        )
    end
    function BuyLimitOrder(dealer::Union{AbstractInvestor, String}; price, quantity, market)
        new(
            dealer, 
            price, 
            quantity, 
            market.currency, 
            market.asset, 
            get_time()
        )
    end
end

mutable struct SellLimitOrder <: LimitOrder
    dealer::Union{AbstractInvestor, String}
    price::Int64
    quantity::Int64

    from::AbstractAsset # This is the asset that is traded away (ie. stock in sell order)
    to::AbstractAsset # This is the asset that is traded to (ie. currency in sell order)

    timestamp::Int64
    function SellLimitOrder(dealer::Union{AbstractInvestor, String}; price::Int64, quantity::Int64, from::AbstractAsset, to::AbstractAsset)
        new(
            dealer, 
            price, 
            quantity, 
            from, 
            to, 
            get_time()
        )
    end
    function SellLimitOrder(dealer::Union{AbstractInvestor, String}; price::Int64, quantity::Int64, market::AbstractMarket)
        new(
            dealer, 
            price, quantity, 
            market.asset, 
            market.currency, 
            get_time()
        )
    end
end

"Get amount of asset the order requires from the investor, aka what the order has reserved"
function get_reserved(order)
    if order isa BuyLimitOrder
        return order.price * order.quantity
    elseif order isa SellLimitOrder
        return order.quantity
    end
end


"Push order to the orderbook of the market"
function Base.push!(market::AbstractMarket, order::BuyLimitOrder)
    push!(market.buy_limit_orders, order)
end

"Push order to the orderbook of the market"
function Base.push!(market::AbstractMarket, order::SellLimitOrder)
    push!(market.sell_limit_orders, order)
end


get_clearable_quantity(buy::BuyLimitOrder, sell::SellLimitOrder) = min(buy.quantity, sell.quantity)

CURRENT_TIME = 0
# Let defines new name space
let state = 0
    global get_time() = (state += 1)
 end