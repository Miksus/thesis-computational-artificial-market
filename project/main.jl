using Parameters
using Statistics
using Distributions
using Plots
using StatsPlots
using CSV
using DataFrames

# Standard library
using Random

#using .BotMarket

function save_positions(investors, path, assets=nothing)
    if isnothing(assets)
        assets = [
            :generic_currency, 
            :generic_stock,
        ]
    end

    df = DataFrame(
        name = [inv.name for inv in investors], 
    )
    for asset in assets
        df[:, string(asset) * "_position"] = [get(inv.positions, eval(asset), 0) for inv in investors]
        df[:, string(asset) * "_reserve"] = [get(inv.reserved, eval(asset), 0) for inv in investors]
    end
    CSV.write(path, df) # "results/pos_start.csv"
    df
end




function run_simulation(investors, markets, trading_days)
    save_positions(investors, "results/pos_start.csv")
    trades = []
    trd_day_of_trade = []
    orderbook = []
    for day in 1:trading_days
        # Trading day
        #println("Trading day ", day)
        trades_day = []
        for investor in investors, market in markets
            
            trds = place!(investor, market)
            
            if isnothing(trds)
                # Do nothing, cannot put to the same
                # check as below because the there
                # is no method isempty with nothing
            elseif ~isempty(trds)
                trades_day = vcat(trades_day, trds)
                trd_day_of_trade = vcat(trd_day_of_trade, repeat([day], length(trds)))
            end
        end
        trades = vcat(trades, trades_day)
        update!(world)
        #println("Price: $(markets[1].last_price), Trades: $(length(trades_day))")
        #for market in markets
        #    cancel_all!(market)
        #    
        #end
        #for inv in investors
            # Otherwise they cannot trade
        #    release_all!(inv)
        #end
    
    end


    save_positions(investors, "results/pos_end.csv")

    df = DataFrame(
        timestamp = [trade.timestamp for trade in trades], 
        trading_day =  trd_day_of_trade,
        price = [trade.price for trade in trades],
        quantity = [trade.quantity for trade in trades],
        seller = [trade.seller.name for trade in trades],
        buyer = [trade.buyer.name for trade in trades],
    )
    CSV.write("results/trades.csv", df)
    df
end