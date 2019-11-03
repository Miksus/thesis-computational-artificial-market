function get_position(investor::SingleAssetInvestor, stock::AbstractAsset)
    return investor.position
end

function get_position(investor::MultiAssetInvestor, stock::AbstractAsset)
    return investor.position[stock]
end

function increase(inv::SingleAssetInvestor, n::Int64, asset::AbstractAsset)
    inv.position += n
end
function increase(inv::MultiAssetInvestor, n::Int64, asset::AbstractAsset)
    inv.position[asset] += n
end

function decrease(inv::SingleAssetInvestor, n::Int64, asset::AbstractAsset)
    inv.position -= n
end
function decrease(inv::MultiAssetInvestor, n::Int64, asset::AbstractAsset)
    inv.position[asset] -= n
end
