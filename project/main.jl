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

function save_trades(trades, trd_day_of_trade)
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

function save_trades(trades, trd_day_of_trade, placements)
    df_main = DataFrame()
    for market in keys(trades)

        df = DataFrame(
            market = market.name,
            timestamp = [trade.timestamp for trade in trades[market]], 
            price = [trade.price for trade in trades[market]],
            quantity = [trade.quantity for trade in trades[market]],
            seller = [trade.seller.name for trade in trades[market]],
            buyer = [trade.buyer.name for trade in trades[market]],
        )
        df_main = vcat(df_main, df)
    end
    sort!(df_main, [:timestamp]);
    begin
        df_main[:trading_day] = trd_day_of_trade
        df_main[:placement_num] = placements
    end
    CSV.write("results/trades.csv", df_main)
    df_main
end


function run_simulation(investors::Array{T, 1} where {T<:AbstractInvestor}, markets::Array{T, 1} where {T<:AbstractMarket}, assets::Array{T, 1} where {T<:AbstractAsset}, trading_days::Int64)
    save_positions(investors, "results/pos_start.csv")
    trades = Dict{AbstractMarket, Array{Trade, 1}}(market => [] for market in markets)
    trd_day_of_trade, placements = [], []
    orderbook = []
    n_placement = 1
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
                append!(trades[market], trds)
                trades_day = vcat(trades_day, trds)
                trd_day_of_trade = vcat(trd_day_of_trade, repeat([day], length(trds)))
                placements = vcat(placements, repeat([n_placement], length(trds)))
            end
            n_placement += 1
        end
        pay_cashflows!(investors, assets)
        update!(world)
    
    end


    save_positions(investors, "results/pos_end.csv")

    save_trades(trades, trd_day_of_trade, placements)
end