
using Distributions

mutable struct ZeroIntelligentInvestor <: AbstractInvestor
    positions::Dict{AbstractAsset, Int64}
    reserved::Dict{AbstractAsset, Int64}
    feasible_range::Tuple{Float64, Int64}

    function ZeroIntelligentInvestor(positions::Dict{AbstractAsset, Int64}; min=0, max=100) # , assets::Dict{}
        new(positions, Dict(), (min, max))
    end
    function ZeroIntelligentInvestor(cash, stock; min=0, max=100) # , assets::Dict{}
        new(Dict(generic_currency=>cash, generic_stock=>stock), Dict(), (0, 1000))
    end
end

function get_order(trader::ZeroIntelligentInvestor, market::AbstractMarket)
    prev_position = trader[market.asset]
    cash = trader[market.currency]

    side = rand([SellLimitOrder, BuyLimitOrder])
    
    # max_possible = side == SellLimitOrder ? Inf : side == BuyLimitOrder ? cash / prev_position : throw(DomainError(order, "Not implmented placement"))

    min_price = trader.feasible_range[1]
    max_price = trader.feasible_range[2]

    mean_price = isnan(market.last_price) ? rand(Uniform(min_price, max_price)) : market.last_price
    std_price = mean([min_price, max_price]) / 10
    order_price = rand(truncated(Normal(mean_price, std_price), min_price, max_price))

    max_quantity = side == SellLimitOrder ? prev_position : side == BuyLimitOrder ? floor(cash / order_price) : throw(DomainError(side, "Not implmented placement"))
    order_quantity = max_quantity == 0 ? 0 : rand(1:Int(max_quantity))

    price = Int64(floor(order_price))
    quantity = Int64(floor(order_quantity))
    println("Creating order $side $price * $quantity")
    return side(trader, price=price, quantity=quantity, market=market)
end
