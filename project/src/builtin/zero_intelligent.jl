
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
    return rand([AskLimitOrder, BidLimitOrder, nothing])
end


"Not strictly the order quantity but the quantity of 
the asset the investor is trading away"
function get_order_quantity(trader::ZeroIntelligentInvestor, market::AbstractMarket, asset::AbstractAsset)

    
    max_tradeable = get_unreserved(trader, asset, exclude=market)
    # Note: max_tradeable is automatically in the asset which
    # is traded away (Sell => stock, buy => currency)

    if max_tradeable < 0
        return NaN
        #throw(DomainError(max_tradeable, "Max quantity cannot be <0: $trader"))
    end
    distr = 0:Int(max_tradeable)
    #println(max_tradeable)
    return rand(distr)
end


function get_order_price(trader::ZeroIntelligentInvestor, market::AbstractMarket, asset::AbstractAsset, min_price::Union{Int64,Float64}, max_price::Union{Int64,Float64})


    # Define the order price
    if isnan(market.last_price)
        # We pick something
        mean_price = mean([min_price, get_unreserved(trader, asset, exclude=market)])
    else
        mean_price = market.last_price
    end
    std_price = 10 #mean([min_price, max_price]) / 100

    distr = truncated(Normal(mean_price, std_price), min_price, max_price)

    return rand(distr)
end

"Decide the order to do to the market"
function get_order(trader::ZeroIntelligentInvestor, market::AbstractMarket)

    # Define side
    side = get_side(trader, market)
    if isnothing(side)
        return
    end

    # Define price limits and assets
    min_price = 1
    if side == AskLimitOrder
        from_asset = market.traded_asset
        to_asset = market.currency
        max_price = Inf

    elseif side == BidLimitOrder
        from_asset = market.currency
        to_asset = market.traded_asset
        max_price = get_unreserved(trader, from_asset, exclude=market) # Absolute maximum is such that the investor can buy one unit

    else
        throw(DomainError(side, "Not implmented placement"))
    end

    if max_price <= min_price
        println("Seems investor $(trader.name) is out of asset $from_asset: $(get_unreserved(trader, from_asset, exclude=market)) (min: $min_price max: $max_price)")
        return
    end

    # Max quantity the trader can trade the asset it
    # is transacting away; either the market currency
    # or market asset
    
    # First we define the price from normal distribution
    # then the quantity from uniform distribution
    order_price = get_order_price(trader, market, from_asset, min_price, max_price)
    order_quantity = get_order_quantity(trader, market, from_asset)

    if isnan(order_price) | isnan(order_quantity)
        # Cannot make order
        return nothing
    end

    price = Int64(round(order_price))
    if side == BidLimitOrder
        # Convert the allocating currency
        # to the quantity of the order 
        # (amount of stock to buy)

        order_quantity = order_quantity / price

    end

    
    quantity = Int64(floor(order_quantity))

    #println("Creating order $side $price * $quantity (has $(trader.positions))")
    return side(trader, price=price, quantity=quantity, market=market)
end

