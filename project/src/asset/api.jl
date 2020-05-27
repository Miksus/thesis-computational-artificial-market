
function pay_cashflows!(investors::Array{T, 1} where {T<:AbstractInvestor}, assets::Array{T, 1} where {T<:AbstractAsset})
    rates = Dict{AbstractAsset, Float64}()
    for asset in assets
        rate = get_rate(asset)
        for investor in investors
            n_assets = investor.positions[asset]
            n_asset_new = n_assets * (1 + rate)
            n_asset_new = rate > 0 ? floor(n_asset_new) : ceil(n_asset_new)
            investor.positions[asset] = Int64(n_asset_new)
        end
        rates[asset] = rate
    end
    rates
end

function pay_cashflow(asset::AbstractAsset, investor::AbstractInvestor)
    rate = get_rate(asset)
    n_assets = investor.positions[asset]
    n_asset_new = n_stocks * (1 - rate)
    n_asset_new = rate > 0 ? floor(n_asset_new) : ceil(n_asset_new)
    inv[payment_currency] += int(n_asset_new)
    return rate
end

"Place holder function to be defined"
function get_rate(asset::AbstractAsset)
    return 0
end