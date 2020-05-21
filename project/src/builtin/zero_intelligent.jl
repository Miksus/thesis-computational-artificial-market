
using Distributions

# Let defines new name space
let state = 0
    global _get_next_id() = (state += 1)
 end


mutable struct ZeroIntelligentInvestor <: AbstractInvestor
    name::String
    positions::Dict{AbstractAsset, Int64}
    reserved::Dict{AbstractAsset, Int64}
    feasible_range::Tuple{Float64, Int64}

    active_orders:: Dict{AbstractMarket, LimitOrder}
    function ZeroIntelligentInvestor(positions::Dict{AbstractAsset, Int64}; min=0, max=100) # , assets::Dict{}
        new(
            string(_get_next_id()),
            positions, 
            Dict(), 
            (min, max),
            Dict()
            )
    end
    function ZeroIntelligentInvestor(cash, stock; min=0, max=100) # , assets::Dict{}
        new(
            _get_next_id(),
            Dict(
                    generic_currency=>cash, 
                    generic_stock=>stock), 
                    Dict(), 
                    (0, 1000),
                    Dict()
                )
    end
end

"Decide the side of the order the trader does"
function get_side(trader::ZeroIntelligentInvestor, market::AbstractMarket)
    return rand([SellLimitOrder, BuyLimitOrder, nothing])
end

"Not strictly the order quantity but the quantity of 
the asset the investor is trading away"
function get_order_quantity(trader::ZeroIntelligentInvestor, market::AbstractMarket, asset::AbstractAsset)

    # Here is a problem: the max_tradeable should be amount of
    # unreserved + reserved by the active order for this market.
    # The active order does get cancelled if this order passes
    # which is the reason it should not have impact here.
    # We must use unreserved because of multiasset scenario.
    active_quantity = (
        # Active order makes 
        market ∈ keys(trader.active_orders) && market.from == asset ? 
        get_reserved(trader.active_orders[market]) 
        : 0
    ) # BUG: should be the quantity only if the active order is same side as the current chosen
    max_tradeable = get_unreserved(trader, asset) + active_quantity

    if max_tradeable < 0
        throw(DomainError(max_tradeable, "Max quantity cannot be <0: $trader"))
    end
    distr = 0:Int(max_tradeable)
    #println(max_tradeable)
    return rand(distr)
end

function get_order_price(trader::ZeroIntelligentInvestor, market::AbstractMarket)
    min_price = trader.feasible_range[1]
    max_price = trader.feasible_range[2]

    # Define the order price
    if isnan(market.last_price)
        mean_price = rand(
            Uniform(
                # This range should start
                # from market's tick (which is set to 1 for now)
                1, trader.positions[market.currency]
            )
        )
    else
        mean_price = market.last_price
    end
    std_price = 100 #mean([min_price, max_price]) / 100

    distr = truncated(Normal(mean_price, std_price), min_price, max_price)

    return rand(distr)
end

"Decide the order to do to the market"
function get_order(trader::ZeroIntelligentInvestor, market::AbstractMarket)
    available_ = trader[market.asset]
    cash = trader[market.currency]

    side = get_side(trader, market)
    if isnothing(side)
        return
    end

    if side == SellLimitOrder
        from_asset = market.asset
        to_asset = market.currency

    elseif side == BuyLimitOrder
        from_asset = market.currency
        to_asset = market.asset
    else
        throw(DomainError(side, "Not implmented placement"))
    end

    # Max quantity the trader can trade the asset it
    # is transacting away; either the market currency
    # or market asset
    order_quantity = get_order_quantity(trader, market, from_asset)

    order_price = get_order_price(trader, market)

    if side == BuyLimitOrder
        # The quantity the investor
        # is trading away is the
        # amount in currency
        # so it is turned as the
        # market asset. LimitOrders
        # does not accept the amount
        # in currency for earlier
        # design decisions.
        #println("$order_price * $order_quantity")
        order_quantity = order_quantity / order_price

        # BUG? does not treat buy symmetrically
        # if order_price > order_quantity,
        # the buy order gets 0 and not inserted
    end

    price = Int64(floor(order_price))
    quantity = Int64(floor(order_quantity))

    #println("Creating order $side $price * $quantity (has $(trader.positions))")
    return side(trader, price=price, quantity=quantity, market=market)
end

