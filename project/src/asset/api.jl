function pay_dividend!(stock::AbstractAsset, investors::Array{AbstractInvestor})
    div_per_share = get_dividend(stock)
    payment_currency = get_currency(stock)
    for inv in investors
        n_stocks = inv[stock]
        inv[payment_currency] += n_stocks * total_dividend
    end
end

function pay_interest!(currency::AbstractCurrency, investors::Array{AbstractInvestor})
    interest_rate = get_interest(currency)
    for inv in investors
        cash_amount = inv[currency]
        inv[currency] += cash_amount * interest_rate
    end
end

