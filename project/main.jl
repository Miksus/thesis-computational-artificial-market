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

function save_trades(trades, trd_day_of_trade; path)
    df_main = DataFrame()
    for market in keys(trades)

        df = DataFrame(
            market = market.name,
            from = market.currency.name, 
            to = market.traded_asset.name, 
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
        df_main[!, :trading_day] .= trd_day_of_trade
    end
    CSV.write(path, df_main)
    df_main
end

function get_market_books(markets::Array{T, 1} where {T<:AbstractMarket})
    df_books = DataFrame()
    for market in markets
        for (side, book) in (("bid", market.bid_limit_orders), ("ask", market.ask_limit_orders))
            if isempty(book)
                continue
            end
            df = DataFrame(
                [(side, order.dealer.name, order.from.name, order.to.name, order.price, order.quantity, market.name) for order in book],
            )
            rename!(df, [:side, :trader, :from, :to, :price, :quantity, :market])
            df_books = vcat(df_books, df)
        end
    end
    return df_books
end


function run_price_discovery(investors::Array{T, 1} where {T<:AbstractInvestor}, markets::Array{T, 1} where {T<:AbstractMarket})
    
    # Placing
    for investor in investors, market in markets
            
        place!(investor, market)
    end

    # Clearing
    trades = Dict{AbstractMarket, Array{Trade, 1}}(market => [] for market in markets)
    for market in markets
        trds = clear!(market)
        if ~isempty(trds)
            append!(trades[market], trds)
        end
    end
    return trades
end

function run_day(investors::Array{T, 1} where {T<:AbstractInvestor}, markets::Array{T, 1} where {T<:AbstractMarket})
    trades = Dict{AbstractMarket, Array{Trade, 1}}(market => [] for market in markets)
    for investor in investors, market in markets[shuffle(1:end)]
            
        place!(investor, market)
        trds = clear!(market)
        if ~isempty(trds)
            append!(trades[market], trds)
        end
    end
    
    return trades
end


function run_simulation(
        investors::Array{T, 1} where {T<:AbstractInvestor}, 
        markets::Array{T, 1} where {T<:AbstractMarket}, 
        assets::Array{T, 1} where {T<:AbstractAsset}, 
        trading_days::Int64, speak_ratio::Float64,
        name::String
    )
    save_positions(investors, "results/$name/pos_start.csv")
    trades = Dict{AbstractMarket, Array{Trade, 1}}(market => [] for market in markets)
    df_books = DataFrame()

    day_index = []
    for day in 1:trading_days
        # Trading day
        #println("Trading day ", day)

        session_trades = run_day(sample(investors, Int64(round(length(investors) * speak_ratio)), replace = false), markets)
        pay_cashflows!(investors, assets)
        update!(world)

        for market in keys(session_trades)
            trades[market] = vcat(trades[market], session_trades[market])
            end_price = length(session_trades[market]) > 0 ? session_trades[market][end].price : "<no trades>"
            println("Price of the day $day: $(end_price) ($(market.name))")
        end
        n_trades = sum([length(val) for val in values(session_trades)])
        day_index = vcat(day_index, repeat([day], n_trades))

        # Order book and its content
        df_book = get_market_books(markets)
        if ~isempty(df_book)
            df_book[!, :day] .= day
            df_books = vcat(df_books, df_book)
        end
    end


    save_positions(investors, "results/$name/pos_end.csv")

    save_trades(trades, day_index, path="results/$name/trades.csv")
    CSV.write("results/$name/books.csv", df_books)
end