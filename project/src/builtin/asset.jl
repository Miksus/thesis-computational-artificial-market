
using Distributions

mutable struct RandomWalkAsset <: AbstractAsset
    last_dividend::Float64

    # Random Walk Parameters
    α::Float64 # Drift
    ϕ::Float64 # Phi of the random walk (1=stationary)
    σ::Float64 # Standard deviation of a step 

    name::String
end

"Get cashflow of the RandomWalkAsset. 
The cashflow would be interest in case of currency
and dividend in case of stock"
function get_cashflow(asset::RandomWalkAsset)
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