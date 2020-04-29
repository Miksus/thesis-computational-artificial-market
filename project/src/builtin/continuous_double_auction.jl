

mutable struct ContinuousDoubleAuctionMarket <: AbstractMarket
    asset::AbstractAsset
    currency::AbstractCurrency
    last_price::Float64
    sell_limit_orders::Array{SellLimitOrder, 1}
    buy_limit_orders::Array{BuyLimitOrder, 1}

    function ContinuousDoubleAuctionMarket()
        new(generic_stock, generic_currency, NaN, Array{SellLimitOrder, 1}(), Array{BuyLimitOrder, 1}()) # , Array{BuyLimitOrder, 1}()
    end

    function ContinuousDoubleAuctionMarket(asset::AbstractAsset)
        new(asset, generic_currency, NaN, Array{SellLimitOrder, 1}(), Array{BuyLimitOrder, 1}()) # , Array{BuyLimitOrder, 1}()
    end

    function ContinuousDoubleAuctionMarket(asset::AbstractAsset, currency::AbstractCurrency)
        new(asset, currency, NaN, Array{SellLimitOrder, 1}(), Array{BuyLimitOrder, 1}()) # , Array{BuyLimitOrder, 1}()
    end
end


function place!(market::ContinuousDoubleAuctionMarket, order::LimitOrder)
    push!(market, order)
    clear!(order, market.sell_limit_orders)

end

function get_trade_price(buy::BuyLimitOrder, sell::SellLimitOrder; market::ContinuousDoubleAuctionMarket)
    # This is used in clearing two orders
    if buy.timestamp < sell.timestamp
        return buy.price
    elseif sell.timestamp < buy.timestamp
        return sell.price
    else
        throw
    end
end

# Market matching
"Cancel all orders"
function cancel_all!(market::ContinuousDoubleAuctionMarket)
    market.sell_limit_orders = typeof(market.sell_limit_orders)()
    market.buy_limit_orders = typeof(market.buy_limit_orders)()
end
