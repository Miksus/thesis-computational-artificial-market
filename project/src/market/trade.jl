
struct Trade
    price::Float64
    quantity::Int64

    seller::Union{String, AbstractInvestor}
    buyer::Union{String, AbstractInvestor}
end

"Trade limit orders"
function trade!(buy::BuyLimitOrder, sell::SellLimitOrder; price::Float64, asset::AbstractAsset)

    quantity = get_clearable_quantity(buy, sell)
    buy.quantity -= quantity
    sell.quantity -= quantity

    # TODO: How to specify which currency? (asset to seller)
    transfer!(buy.dealer, sell.dealer, asset=:cash, quantity=quantity * price)
    transfer!(sell.dealer, buy.dealer, asset=asset, quantity=quantity)

    #release!(buy.dealer, )

    return Trade(price, quantity, sell.dealer, buy.dealer)
end

# Allow argument order insensitive
trade!(sell::SellLimitOrder, buy::BuyLimitOrder; side=:equal, asset::Union{Nothing, AbstractAsset}=nothing) = trade!(buy, sell, asset, side=side, asset=asset)
