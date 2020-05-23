
# Author: Mikael Koli
# All rights reserved

module BotMarket

    # Functions and structs for the module
    export AbstractInvestor, AbstractMarket,
        # Structs
        ContinuousDoubleAuctionMarket,
        
        ZeroIntelligentInvestor,
        ExternalWorld,
        AskLimitOrder, BidLimitOrder, 
        RandomWalkStock,
        RandomWalkCurrency,

        # Functions
        place!, 
        clear!, 
        cancel_all!,
        release_all!,
        get_interest,
        get_dividend,
        update!,

        # Generics
        generic_currency,
        generic_stock,

        # For debugging
        get_order,
        get_order_quantity,
        get_order_price,
        get_unreserved

    
    # Including the module files where the
    # the above structs and functions come
    # from

    include("abstracts.jl")

    include("market/orders.jl")
    include("market/trade.jl")
    include("market/clear.jl")
    include("market/limitorderbook.jl")
    

    include("investor/api.jl")
    include("investor/generic.jl")
    include("investor/position.jl")

    include("asset/api.jl")
    include("external_world/external_world.jl")

    # Built in
    include("builtin/zero_intelligent.jl")
    include("builtin/asset.jl")
    include("builtin/continuous_double_auction.jl")
    include("builtin/currency.jl")

    # Defining some generics for easier use
    generic_currency = RandomWalkCurrency(0, 0, 0, 0, "ccy")
    generic_stock = RandomWalkStock(0, 0, 0, 0, "stock")

end