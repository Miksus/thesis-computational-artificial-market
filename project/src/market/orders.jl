
mutable struct BidLimitOrder <: LimitOrder
    dealer::Union{AbstractInvestor, String}
    price::Int64
    quantity::Int64

    from::AbstractAsset # This is the asset that is traded away (ie. currency in buy order)
    to::AbstractAsset # This is the asset that is traded to (ie. stock in buy order)

    timestamp::Int64
    function BidLimitOrder(dealer::Union{AbstractInvestor, String}; price, quantity, from, to)
        new(
            dealer, 
            price, 
            quantity, 
            from, 
            to, 
            get_time()
        )
    end
    function BidLimitOrder(dealer::Union{AbstractInvestor, String}; price, quantity, market)
        new(
            dealer, 
            price, 
            quantity, 
            market.currency, 
            market.traded_asset, 
            get_time()
        )
    end
end

mutable struct AskLimitOrder <: LimitOrder
    dealer::Union{AbstractInvestor, String}
    price::Int64
    quantity::Int64

    from::AbstractAsset # This is the asset that is traded away (ie. stock in sell order)
    to::AbstractAsset # This is the asset that is traded to (ie. currency in sell order)

    timestamp::Int64
    function AskLimitOrder(dealer::Union{AbstractInvestor, String}; price::Int64, quantity::Int64, from::AbstractAsset, to::AbstractAsset)
        new(
            dealer, 
            price, 
            quantity, 
            from, 
            to, 
            get_time()
        )
    end
    function AskLimitOrder(dealer::Union{AbstractInvestor, String}; price::Int64, quantity::Int64, market::AbstractMarket)
        new(
            dealer, 
            price, quantity, 
            market.traded_asset, 
            market.currency, 
            get_time()
        )
    end
end

"Get amount of asset commited in the order (seller commits the asset and buyer currency)¨
This is side independent;
    BidLimitOrder: returned amount in traded currency
    AskLimitOrder: returned amount in traded asset"
function get_amount_commited(order)
    if order isa BidLimitOrder
        return order.price * order.quantity
    elseif order isa AskLimitOrder
        return order.quantity
    end
end


"Push order to the orderbook of the market"
function Base.push!(market::AbstractMarket, order::BidLimitOrder)
    push!(market.bid_limit_orders, order)
end

"Push order to the orderbook of the market"
function Base.push!(market::AbstractMarket, order::AskLimitOrder)
    push!(market.ask_limit_orders, order)
end


get_clearable_quantity(buy::BidLimitOrder, sell::AskLimitOrder) = min(buy.quantity, sell.quantity)

CURRENT_TIME = 0
# Let defines new name space
let state = 0
    global get_time() = (state += 1)
 end