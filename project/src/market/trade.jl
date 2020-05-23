
struct Trade
    price::Int64
    quantity::Int64
    timestamp::Int64

    from::AbstractAsset
    to::AbstractAsset

    seller::Union{String, AbstractInvestor}
    buyer::Union{String, AbstractInvestor}
end

"Trade limit orders"
function trade!(buy::BidLimitOrder, sell::AskLimitOrder; price::Int64, from::AbstractAsset, to::AbstractAsset)
    
    quantity = get_clearable_quantity(buy, sell)
    # Both order's quantity is reduced by trade quantity
    buy.quantity -= quantity
    sell.quantity -= quantity
    #println("Trading $quantity with $(buy.dealer.name) ($(from.name)) <--> $(sell.dealer.name) ($(to.name)) with price $price ")
    # Must be released before transfer
    # as the reserve cannot be higher
    # than the amount at any given time
    release!(buy.dealer, quantity * buy.price, from) # We must reduce buy price for reserve accounting
    release!(sell.dealer, quantity, to)

    #println("Trading $price * $quantity ($from --> $to)")
    # TODO: How to specify which currency? (asset to seller)
    transfer!(buy.dealer, sell.dealer, asset=from, quantity=quantity * price)
    transfer!(sell.dealer, buy.dealer, asset=to, quantity=quantity)

    return Trade(price, quantity, get_time(), from, to, sell.dealer, buy.dealer)
end

# Allow argument order insensitive
trade!(sell::AskLimitOrder, buy::BidLimitOrder; side=:equal, asset::Union{Nothing, AbstractAsset}=nothing) = trade!(buy, sell, asset, side=side, asset=asset)
