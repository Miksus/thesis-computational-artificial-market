

module BotMarket
    export SingleAssetInvestor, DoubleAuctionMarket, Market, SellLimitOrder, BuyLimitOrder, settle!, place!, place_and_clear!, clear!, cancel!

    include("abstracts.jl")
    include("investor/single_asset.jl")
    include("market/orders.jl")
    include("market/market.jl")

    include("market/settling.jl")

end # module
