
mutable struct Stock <: AbstractAsset
    name::String
    dividend_policy::Function
    paid_dividends::Float64
    function Stock(name::String, expr::Expr)
        div_func = quote
            function get_dividend()
                return $expr
            end
        end
        new(name, div_func)
    end
    function Stock(name::String)
        new(name)
    end
end


function pay_dividend!(stock::Stock, investors::Array{MultiAssetInvestor}) where T <: AbstractInvestor
    div_per_share = stock.dividend_policy(paid_dividends)
    for inv in investors
        q = get_position(inv, stock)
        total_dividend = q * div_per_share
        inv.cash += total_dividend
    end
end

function pay_dividend!(stock::Stock, investors::Array{SingleAssetInvestor})
    div_per_share = stock.dividend_policy(paid_dividends)
    for inv in investors
        q = get_position(inv, stock)
        total_dividend = q * div_per_share
        inv.cash += total_dividend
    end
end
