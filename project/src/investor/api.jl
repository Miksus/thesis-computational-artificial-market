

function place!(trader::AbstractInvestor, market::AbstractMarket)
    order = get_order(trader, market)
    if ~is_valid_order(order, market, trader)
        if ~isnothing(order)
            #println("Invalid order $(order.price) * $(order.quantity) $(typeof(order))")
            #println("Has in position $(order.dealer.positions[order.from]) (reserved: $(get(trader.reserved, order.from, 0)) and active $(market ∉ keys(trader.active_orders) ? 0 : get_reserved(trader.active_orders[market])))")
        end
        return
    end

    # Cancel active order if has any and overwrite it with this
    println("------")
    println("$(trader.name): Making order $(order.price) * $(order.quantity) $(typeof(order))")
    cancel!(trader, market) 
    # Store the active order
    trader.active_orders[market] = order
    reserve!(trader, order)


    trades = place!(market, order)

    return trades
end

function is_valid_order(order::BuyLimitOrder, market::AbstractMarket, trader::AbstractInvestor)
    active_amount = market ∈ keys(trader.active_orders) ? get_reserved(trader.active_orders[market]) : 0
    unreserved = get_unreserved(trader, order.from)
    # We multiply the active amount as we take its effect off
    # the active order is overwritten with this (if passed)
    # so the current active order does not matter
    if get_reserved(order) > trader.positions[order.from]
        println("Invalid order: $(order.price) * $(order.quantity) $(typeof(order)) (reserved $(get_reserved(order)))")
        println("Unverserved: $(unreserved), active amount $(active_amount), reserved $(get(trader.reserved, order.from, 0)), positions: $(trader.positions[order.from])")
        #throw(DomainError(quantity, "Cannot reserve more asset ($quantity) than there is in the positions (Position: $(inv.positions[asset]), reserved: $(inv.reserved[asset])) $(inv.name)"))
    end
    is_not_over_reserved = (unreserved + active_amount) >= get_reserved(order)
    is_not_none = order != nothing
    is_positive = order.quantity > 0
    return is_not_none && is_positive && is_not_over_reserved
end

function is_valid_order(order::SellLimitOrder, market::AbstractMarket, trader::AbstractInvestor)
    active_amount = market ∈ keys(trader.active_orders) ? get_reserved(trader.active_orders[market]) : 0
    unreserved = get_unreserved(trader, order.from)
    # We multiply the active amount as we take its effect off
    # the active order is overwritten with this (if passed)
    # so the current active order does not matter
    if get_reserved(order) > trader.positions[order.from]
        println("Invalid order: $(order.price) * $(order.quantity) $(typeof(order)) (reserved $(get_reserved(order)))")
        println("Unverserved: $(unreserved), active amount $(active_amount), reserved $(get(trader.reserved, order.from, 0)), positions: $(trader.positions[order.from])")
        #throw(DomainError(quantity, "Cannot reserve more asset ($quantity) than there is in the positions (Position: $(inv.positions[asset]), reserved: $(inv.reserved[asset])) $(inv.name)"))
    end
    is_not_over_reserved = (unreserved + active_amount) >= get_reserved(order)
    is_not_none = order != nothing
    is_positive = order.quantity > 0
    return is_not_none && is_positive && is_not_over_reserved
end

function is_valid_order(order::Nothing, market::AbstractMarket, trader::AbstractInvestor)
    return false
end

function transfer!(from::AbstractInvestor, to::AbstractInvestor; asset, quantity)
    from[asset] -= quantity
    to[asset] += quantity
end

function get_unreserved(inv::AbstractInvestor, asset::AbstractAsset)
    reserved = get(inv.reserved, asset, 0)
    in_position = inv.positions[asset]
    return in_position - reserved
end

"Reserve asset (so that investor has the capital for future transaction)"
function reserve!(inv::AbstractInvestor, order::LimitOrder)
    
    #println("$order")
    # THIS WAS THE BUG:
    asset = order.from

    quantity = get_reserved(order)
    #println("Reserving $quantity of $(asset.name) for $(inv.name) ($(get(inv.reserved, asset, 0)))")
    #quantity = order isa BuyLimitOrder ? order.quantity * order.price : order.quantity
    # ∉ is same as "not in" Python
    if asset ∉ keys(inv.reserved)
        inv.reserved[asset] = quantity
        return
    end

    # Check the reserved does not surpass the position
    if inv.positions[asset] < inv.reserved[asset]
        throw(DomainError(inv.reserved[asset], "The reserve is more ($(inv.reserved[asset])) than there is in the positions ($(inv.positions[asset]))"))
    elseif quantity > inv.positions[asset]
        println("Invalid order: $(order.price) * $(order.quantity) $(typeof(order)) (asset $(asset.name))")
        throw(DomainError(quantity, "Cannot reserve more asset ($quantity) than there is in the positions (Position: $(inv.positions[asset]), reserved: $(inv.reserved[asset])) $(inv.name)"))
    end

    #println("Reserving asset $asset")
    inv.reserved[asset] += quantity
    #println(inv.reserved[asset])
end

"Release reserved asset"
function release!(inv::AbstractInvestor, quantity::Int64, asset::AbstractAsset)
    # ∉ is same as "not in" Python
    #println("Releasing $quantity of $(asset.name) for investor $(inv.name) ($(get(inv.reserved, asset, 0)))")
    if asset ∉ keys(inv.reserved)
        inv.reserved[asset] = 0
        return
    end
    if inv.positions[asset] < inv.reserved[asset]
        throw(DomainError(inv.reserved[asset], "The reserve is more ($(inv.reserved[asset])) than there is in the positions ($(inv.positions[asset]))"))
    elseif inv.positions[asset] < quantity
        throw(DomainError(quantity, "Cannot release more asset ($quantity) than there is in the positions ($(inv.positions[asset]))"))
    elseif inv.reserved[asset] < quantity
        throw(DomainError(quantity, "Cannot release more asset ($quantity) than there is in the reserve ($(inv.reserved[asset]), Investor $(inv.name))"))
    end
    inv.reserved[asset] -= quantity
    #println(inv.reserved[asset])
end

"Release all reserved asset"
function release_all!(inv::AbstractInvestor)
    inv.reserved = Dict{AbstractAsset, Int64}()
end

function Base.getindex(inv::AbstractInvestor, asset::AbstractAsset)
    get(inv.positions, asset, 0)
end
function Base.setindex!(inv::AbstractInvestor, val::Int64, asset::AbstractAsset)
    inv.positions[asset] = val
end

"Cancel active order"
function cancel!(trader::AbstractInvestor, market::AbstractMarket)
    # Cancelling order is conducted the following manner:
    #   1. Set the quantity of the active order to zero
    #   2. Release the asset from reserved
    #   3. Let the market clean the order away on next clearing
    if market ∉ keys(trader.active_orders)
        # No active orders
        return 
    end
    active_order = trader.active_orders[market]
    active_quantity = get_reserved(active_order)
    #println("Active Quantity $active_quantity. Previous active: $active_order")
    
    release!(trader, active_quantity, active_order.from)
    # BUG: For some reason cash is not completely released here!
    #println("Asset $asset reserved $(trader.reserved[asset])")

    # There is no elegant way of deleting it from the market 
    # completely so we set quantity as 0 and market will
    # clean it away
    active_order.quantity = 0
    if trader.active_orders[market].quantity != 0
        throw(DomainError(trader.active_orders[market].quantity, "Active amount not zero"))
    end
end