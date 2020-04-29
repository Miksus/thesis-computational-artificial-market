
Investor api:
- get_order() : Calculate
- place!(Investor, Market) : Place 

Market api:
- Define one of the following
    - get_trade_price(::BuyLimitOrder, ::SellLimitOrder; market::MyMarket) 
        Get the price of a trade in the market. For continuous markets
    - get_trade_price(::MyMarket)
        Get the price of a clearing cycle. For call markets

Examples:

world = ExternalWorld()

stock = Stock()
investors = [ZeroIntelligence(cash=500, positions=Dict(stock => 50)) for i in 1:100]
markets = [ContinuousDoubleAuctionMarket() for i in range(2)]

for day in range(100)
    # Trading day

    for investor in investors, market in markets
        place!(investor, market)
    end
    update!(world)
    
    for market in markets
        cancel_all!(market)
    end

end


---

stock = DoubleAuctionMarket("NOK")
stock.last_price = 95
prices = Array{Float64,1}()
inv = [SingleAssetInvestor(
        "Player " * string(n), starting_cash, n_stocks
        , price_expr=price_expr, order_expr=order_expr, quantity_expr=quantity_expr
        ) for n in 1:n_traders]


for n in 1:n_iters
    println("Placing...")
    for inv in inv
        place!(inv, stock)
    end
    println("Clearing...")
    clear!(stock)
    push!(prices, stock.last_price)

    if n < n_iters
        cancel!(stock)
    end
end