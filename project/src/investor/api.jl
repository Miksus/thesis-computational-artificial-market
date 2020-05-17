

function place!(trader::AbstractInvestor, market::AbstractMarket)
    order = get_order(trader, market)
    if ~is_valid_order(order, market, trader)
        return
    end

    reserve!(trader, order)
    place!(market, order)
end

function is_valid_order(order::BuyLimitOrder, market::AbstractMarket, trader::AbstractInvestor)

    is_not_none = order != nothing
    is_not_over_reserved = (order.quantity * order.price) <= get_unreserved(trader, market.currency)
    is_positive = order.quantity > 0
    return is_not_none && is_not_over_reserved && is_positive
end

function is_valid_order(order::SellLimitOrder, market::AbstractMarket, trader::AbstractInvestor)

    is_not_none = order != nothing
    is_not_over_reserved = order.quantity <= get_unreserved(trader, market.currency)
    is_positive = order.quantity > 0
    return is_not_none && is_not_over_reserved && is_positive
end

function is_valid_order(order::Nothing, market::AbstractMarket, trader::AbstractInvestor)
    return false
end

function transfer!(from::AbstractInvestor, to::AbstractInvestor; asset, quantity)
    from[asset] -= quantity
    to[asset] += quantity
end

function get_unreserved(inv::AbstractInvestor, asset::AbstractAsset)
    return inv[asset] - get(inv.reserved, asset, 0)
end

"Reserve asset (so that investor has the capital for future transaction)"
function reserve!(inv::AbstractInvestor, order::LimitOrder)
    # ∉ is same as "not in" Python
    asset = order.from
    quantity = order isa BuyLimitOrder ? order.quantity * order.price : order.quantity
    if asset ∉ keys(inv.reserved)
        inv.reserved[asset] = 0
    end
    inv.reserved[asset] += quantity
end

"Release reserved asset"
function release!(inv::AbstractInvestor, quantity::Float64, asset::AbstractAsset)
    # ∉ is same as "not in" Python
    if asset ∉ keys(inv.reserved)
        inv.reserved[asset] = 0
    end
    inv.reserved[asset] -= quantity
end

function Base.getindex(inv::AbstractInvestor, asset::AbstractAsset)
    get(inv.positions, asset, 0)
end
function Base.setindex!(inv::AbstractInvestor, val::Int64, asset::AbstractAsset)
    inv.positions[asset] = val
end
