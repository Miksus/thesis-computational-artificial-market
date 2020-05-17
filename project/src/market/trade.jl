
struct Trade
    price::Int64
    quantity::Int64
    timestamp::Int64

    seller::Union{String, AbstractInvestor}
    buyer::Union{String, AbstractInvestor}
end

"Trade limit orders"
function trade!(buy::BuyLimitOrder, sell::SellLimitOrder; price::Int64, from::AbstractAsset, to::AbstractAsset)
    
    quantity = get_clearable_quantity(buy, sell)
    buy.quantity -= quantity
    sell.quantity -= quantity

    println("Trading $price * $quantity ($from --> $to)")
    # TODO: How to specify which currency? (asset to seller)
    transfer!(buy.dealer, sell.dealer, asset=from, quantity=quantity * price)
    transfer!(sell.dealer, buy.dealer, asset=to, quantity=quantity)

    #release!(buy.dealer, )

    return Trade(price, quantity, get_time(), sell.dealer, buy.dealer)
end

# Allow argument order insensitive
trade!(sell::SellLimitOrder, buy::BuyLimitOrder; side=:equal, asset::Union{Nothing, AbstractAsset}=nothing) = trade!(buy, sell, asset, side=side, asset=asset)
