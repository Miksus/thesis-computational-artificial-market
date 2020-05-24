function pay_dividend!(stock::AbstractAsset, investors::Array{AbstractInvestor})
    div_per_share = get_dividend(stock)
    payment_currency = get_currency(stock)
    for inv in investors
        n_stocks = inv[stock]
        inv[payment_currency] += n_stocks * total_dividend
    end
end
