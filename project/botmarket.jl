

module BotMarket
    export ContinuousDoubleAuctionMarket,
        # Structs
        ZeroIntelligentInvestor,
        ExternalWorld,
        SellLimitOrder, BuyLimitOrder, 
        RandomWalkStock,
        RandomWalkCurrency,

        # Functions
        place!, 
        clear!, 
        cancel!,
        get_interest,
        get_dividend,

        # Generics
        generic_currency,
        generic_stock
    
    include("abstracts.jl")

    include("market/orders.jl")
    include("market/trade.jl")
    include("market/clear.jl")
    include("market/limitorderbook.jl")
    

    include("investor/api.jl")
    include("investor/generic.jl")

    include("asset/api.jl")
    include("external_world/external_world.jl")

    # Built in
    include("builtin/zero_intelligent.jl")
    include("builtin/asset.jl")
    include("builtin/continuous_double_auction.jl")
    include("builtin/currency.jl")

    generic_currency = RandomWalkCurrency(0, 0, 0, 0)
    generic_stock = RandomWalkStock(0, 0, 0, 0)

end # module
