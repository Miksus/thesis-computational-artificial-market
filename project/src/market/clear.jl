

function clear!(market::AbstractMarket)
    sell_book = market.ask_limit_orders
    buy_book = market.bid_limit_orders

    trades = Array{Trade, 1}()

    return clear!(buy_book, sell_book, market=market)
end


"Clear limit order books"
function clear!(bid_book::Array{BidLimitOrder, 1}, ask_book::Array{AskLimitOrder, 1}; market)

    

    trades = Array{Trade, 1}()

    # Clear empty orders before the clearing
    # ie. if an investor has set quantity
    # of an order to zero, it will be cleaned now
    clear_empty!(ask_book)
    clear_empty!(bid_book)

    # The clearing price is defined here
    # in case of call market. Nothing
    # should be returned if the price
    # is defined per order pair basis
    clearing_price = get_trade_price(market)
    while maxprice(bid_book) >= minprice(ask_book)

        order_ask = get_best(ask_book)
        order_bid = get_best(bid_book)
        
        # trade_price is clearing_price if defined,
        # else calculated per order pairs
        trade_price = (
            ~isnothing(clearing_price) ? 
            clearing_price
            : get_trade_price(order_bid, order_ask, market=market)
        )

        trade = trade!(
            order_bid, order_ask, 
            price=trade_price, 
            from=market.currency, 
            to=market.traded_asset
        )

        clear_empty!(ask_book)
        clear_empty!(bid_book)

        push!(trades, trade)
    end
    if ~isempty(trades)
        market.last_price = trades[end].price
    end
    return trades
end

function get_trade_price(market::AbstractMarket)
    # Must be redefined by market type. If not defined, nothing returned
    return nothing
end

