

mutable struct ContinuousDoubleAuctionMarket <: AbstractMarket
    traded_asset::AbstractAsset
    currency::AbstractCurrency
    last_price::Float64
    ask_limit_orders::Array{AskLimitOrder, 1}
    bid_limit_orders::Array{BidLimitOrder, 1}

    function ContinuousDoubleAuctionMarket()
        new(generic_stock, generic_currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}()) # , Array{BidLimitOrder, 1}()
    end

    function ContinuousDoubleAuctionMarket(asset::AbstractAsset)
        new(asset, generic_currency, NaN, Array{AskLimitOrder, 1}(), Array{BidLimitOrder, 1}()) # , Array{BidLimitOrder, 1}()
    end

    function ContinuousDoubleAuctionMarket(asset::AbstractAsset, currency::AbstractCurrency)
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
