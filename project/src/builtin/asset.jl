
using Distributions

mutable struct RandomWalkStock <: AbstractAsset
    last_dividend::Float64

    # Random Walk Parameters
    α::Float64 # Drift
    ϕ::Float64 # Phi of the random walk (1=stationary)
    σ::Float64 # Standard deviation of a step 

end

mutable struct RandomWalkCurrency <: AbstractCurrency
    last_interest::Float64

    # Random Walk Parameters
    α::Float64 # Drift
    ϕ::Float64 # Phi of the random walk (1=stationary)
    σ::Float64 # Standard deviation of a step 

end

function get_interest(currency::RandomWalkCurrency)
    return get_random_walk_step(
        currency.α, 
        currency.ϕ,
        currency.σ,
        currency.last_interest
    )
end

function get_dividend(stock::RandomWalkStock)
    return get_random_walk_step(
        stock.α, 
        stock.ϕ,
        stock.σ,
        stock.last_dividend
    )
end

function get_random_walk_step(α::Float64, ϕ::Float64, σ::Float64, x_prev::Float64)
    μ = 0
    u = rand(Normal(μ, σ))
    return α + ϕ * x_prev + u
end