

# NOTE: get_unreserved must be defined in this order because otherwise 
# the one with keyword argument "exclude" will be called either case

"Get unreserved excluding the active order in specified market (if affects)"
function get_unreserved(inv::AbstractInvestor, asset::AbstractAsset; exclude::AbstractMarket)
    position = get_position(inv, asset)
    total_reserved = get_reserved(inv, asset)
    active = get_active_order(inv, exclude)
    if isnothing(active) || (active.from != asset)
        # Active order does not affect here
        # This include:
        #   active is buy while asset is stock (buy needs only currency to execute)
        #   active is sell while asset is currency (sell needs only stock to execute)
        exclude_quantity = 0
    else
        # Active order is the same setindex
        # of the 
        exclude_quantity =  active.quantity
    end
    reserved = total_reserved - exclude_quantity
    return position - reserved

end

function get_unreserved(inv::AbstractInvestor, asset::AbstractAsset)
    return get_position(inv, asset) - get_reserved(inv, asset)
end

function get_reserved(inv::AbstractInvestor, asset::AbstractAsset)
    reserved = get(inv.reserved, asset, 0)
    return reserved
end

function get_position(inv::AbstractInvestor, asset::AbstractAsset)
    return get(inv.positions, asset, 0)
end

function Base.getindex(inv::AbstractInvestor, asset::AbstractAsset)
    get(inv.positions, asset, 0)
end

function Base.setindex!(inv::AbstractInvestor, val::Int64, asset::AbstractAsset)
    inv.positions[asset] = val
end

"Get the current active order in the market (or nothing if none)"
function get_active_order(trader::AbstractInvestor, market::AbstractMarket)
    return get(trader.active_orders, market, nothing)
end