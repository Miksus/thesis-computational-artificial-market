
using Distributions

mutable struct RandomWalkAsset <: AbstractAsset
    last_rate::Float64

    # Random Walk Parameters
    α::Float64 # Drift
    ϕ::Float64 # Phi of the random walk (1=stationary)
    σ::Float64 # Standard deviation of a step 

    name::String
end

mutable struct FixedAsset <: AbstractAsset
    last_rate::Float64

    rate::Float64

    name::String
    function FixedAsset(rate::Float64; name::String="asset")
        new(NaN, rate, name) # , Array{BidLimitOrder, 1}()
    end
    function FixedAsset(name::String="asset")
        new(NaN, 0.0, name) # , Array{BidLimitOrder, 1}()
    end
end

"Get cashflow of the RandomWalkAsset. 
The cashflow would be interest in case of currency
and dividend in case of stock"
function get_rate(asset::RandomWalkAsset)
    return get_random_walk_step(
        asset.α, 
        asset.ϕ,
        asset.σ,
        asset.last_interest
    )
end

function get_random_walk_step(α::Float64, ϕ::Float64, σ::Float64, x_prev::Float64)
    μ = 0
    u = rand(Normal(μ, σ))
    return α + ϕ * x_prev + u
end


function get_rate(asset::FixedAsset)
    return asset.rate
end