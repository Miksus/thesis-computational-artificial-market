

function place!(trader::AbstractInvestor, market::AbstractMarket)
    order = get_order(trader, market)
    if ~is_valid_order(order, market, trader)
        if ~isnothing(order)
            println("Invalid order $(order.price) * $(order.quantity) $(typeof(order))")
            #println("Has in position $(order.dealer.positions[order.from]) (reserved: $(get(trader.reserved, order.from, 0)) and active $(market ∉ keys(trader.active_orders) ? 0 : get_reserved(trader.active_orders[market])))")
        end
        return
    end

    # Cancel active order if has any and overwrite it with this
    #println("------")
    #println("$(trader.name): Making order $(order.price) * $(order.quantity) $(typeof(order))")
    cancel!(trader, market) 
    # Store the active order
    trader.active_orders[market] = order
    reserve!(trader, order)


    trades = place!(market, order)

    return trades
end

function is_valid_order(order::BuyLimitOrder, market::AbstractMarket, trader::AbstractInvestor)
    is_not_over_reserved = get_unreserved(order.dealer, order.from, exclude=market) >= get_amount_commited(order)
    is_not_none = order != nothing
    is_positive = order.quantity > 0
    return is_not_none && is_positive && is_not_over_reserved
end

function is_valid_order(order::SellLimitOrder, market::AbstractMarket, trader::AbstractInvestor)
    
    is_not_over_reserved = get_unreserved(order.dealer, order.from, exclude=market) >= get_amount_commited(order)
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




"Reserve asset (so that investor has the capital for future transaction)"
function reserve!(inv::AbstractInvestor, order::LimitOrder)
    
    #println("$order")
    # THIS WAS THE BUG:
    asset = order.from

    quantity = get_amount_commited(order)
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


"Cancel active order"
function cancel!(trader::AbstractInvestor, market::AbstractMarket)
    # Cancelling order is conducted the following manner:
    #   1. Set the quantity of the active order to zero
    #   2. Release the asset from reserved
    #   3. Let the market clean the order away on next clearing
    active = get_active_order(trader, market)
    if isnothing(active)
        # No active orders
        return 
    end

    active_quantity = get_amount_commited(active)
    #println("Active Quantity $active_quantity. Previous active: $active_order")
    
    release!(trader, active_quantity, active.from)
    # BUG: For some reason cash is not completely released here!
    #println("Asset $asset reserved $(trader.reserved[asset])")

    # There is no elegant way of deleting it from the market 
    # completely so we set quantity as 0 and market will
    # clean it away
    active.quantity = 0

    # Check for debugging
    if trader.active_orders[market].quantity != 0
        throw(DomainError(trader.active_orders[market].quantity, "Active amount not zero"))
    end
end

