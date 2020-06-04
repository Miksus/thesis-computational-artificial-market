
# Let defines new name space
let state = 0
    global _get_next_market_id() = (state += 1)
 end

mutable struct DoubleAuctionMarket <: AbstractMarket
    name::String

    traded_asset::AbstractAsset
    currency::AbstractAsset
    last_price::Float64
    ask_limit_orders::Array{AskLimitOrder, 1}
    bid_limit_orders::Array{BidLimitOrder, 1}
    continuous::Bool

    function DoubleAuctionMarket(; name::Union{String, Nothing}=nothing)
        name = isnothing(name) ? _get_next_market_id() : name
        new(name, generic_stock, generic_currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}(), true) # , Array{BidLimitOrder, 1}()
    end

    function DoubleAuctionMarket(ccy::AbstractAsset, asset::AbstractAsset; name::Union{String, Nothing}=nothing)
        name = isnothing(name) ? _get_next_market_id() : name
        new(name, ccy, asset, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}(), true) # , Array{BidLimitOrder, 1}()
    end

    function DoubleAuctionMarket(asset::AbstractAsset)
        new(asset, generic_currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}(), true) # , Array{BidLimitOrder, 1}()
    end

    function DoubleAuctionMarket(asset::AbstractAsset, currency::AbstractAsset)
        new(asset, currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}(), true) # , Array{BidLimitOrder, 1}()
    end
end


function place!(market::DoubleAuctionMarket, order::LimitOrder)
    push!(market, order)
    #clear!(market)
end

function get_trade_price(buy::BidLimitOrder, sell::AskLimitOrder; market::DoubleAuctionMarket)
    # This is used in clearing two orders
    if buy.timestamp < sell.timestamp
        return Int64(buy.price)
    elseif sell.timestamp < buy.timestamp
        return Int64(sell.price)
    else
        throw
    end
end

# Market matching
"Cancel all orders"
function cancel_all!(market::DoubleAuctionMarket)
    # TODO: release assets from traders
    market.ask_limit_orders = typeof(market.ask_limit_orders)()
    market.bid_limit_orders = typeof(market.bid_limit_orders)()

end

function get_trade_price(market::DoubleAuctionMarket)
    if market.continuous
        # Continuous is matched per order basis (not per book)
        return nothing
    else
        # Call is matched per book basis
        (q, p) = get_equlibrium(market.bid_limit_orders, market.ask_limit_orders)
        return p
    end
end