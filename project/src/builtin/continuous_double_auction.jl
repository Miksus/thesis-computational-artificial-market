
# Let defines new name space
let state = 0
    global _get_next_market_id() = (state += 1)
 end

mutable struct ContinuousDoubleAuctionMarket <: AbstractMarket
    name::String

    traded_asset::AbstractAsset
    currency::AbstractAsset
    last_price::Float64
    ask_limit_orders::Array{AskLimitOrder, 1}
    bid_limit_orders::Array{BidLimitOrder, 1}

    function ContinuousDoubleAuctionMarket(; name::Union{String, Nothing}=nothing)
        name = isnothing(name) ? _get_next_market_id() : name
        new(name, generic_stock, generic_currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}()) # , Array{BidLimitOrder, 1}()
    end

    function ContinuousDoubleAuctionMarket(ccy::AbstractAsset, asset::AbstractAsset; name::Union{String, Nothing}=nothing)
        name = isnothing(name) ? _get_next_market_id() : name
        new(name, ccy, asset, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}()) # , Array{BidLimitOrder, 1}()
    end

    function ContinuousDoubleAuctionMarket(asset::AbstractAsset)
        new(asset, generic_currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}()) # , Array{BidLimitOrder, 1}()
    end

    function ContinuousDoubleAuctionMarket(asset::AbstractAsset, currency::AbstractAsset)
        new(asset, currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}()) # , Array{BidLimitOrder, 1}()
    end
end


function place!(market::ContinuousDoubleAuctionMarket, order::LimitOrder)
    push!(market, order)
    clear!(market)
end

function get_trade_price(buy::BidLimitOrder, sell::AskLimitOrder; market::ContinuousDoubleAuctionMarket)
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
function cancel_all!(market::ContinuousDoubleAuctionMarket)
    market.ask_limit_orders = typeof(market.ask_limit_orders)()
    market.bid_limit_orders = typeof(market.bid_limit_orders)()

end
