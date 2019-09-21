
mutable struct Investor
    name::String
    cash::Float64
    position::Int64

    decide::Function

    function Investor(name, cash=0, position=0; quantity_expr, price_expr, order_expr)

        max_quantity = :(order == SellLimitOrder ? position : order == BuyLimitOrder ? floor(cash/price) : throw(DomainError(order, "Not implmented placement")))
        max_price = :(order == SellLimitOrder ? Inf : order == BuyLimitOrder ? cash / quantity : throw(DomainError(order, "Not implmented placement")))

        # Add predefined conventions
        quantity_expr = substitute(quantity_expr, :max_quantity, max_quantity)
        price_expr = substitute(price_expr, :max_price, max_price)

        exp_1, exp_2, exp_3 = get_expression_order(:(price = $price_expr), :(quantity = $quantity_expr), :(order = $order_expr))
        decision_func = quote
            function get_order(cash, position, last_price, trader, market)
                $exp_1
                $exp_2
                $exp_3
                return order(trader, price, quantity)
            end
        end
        new(name, cash, position, eval(decision_func))
    end
    function Investor(name; quantity_expr, price_expr, cash=0, position=0)
        new(name, cash, position, price_expr, quantity_expr)
    end
end


function place!(trader::Investor, market::AbstractMarket)
    order = trader.decide(trader.cash, trader.position, market.last_price, trader, market)
    if order == nothing
        return
    end
    place!(market, order)
end


function create_order(trader, market::AbstractMarket)

    order
    return order(trader, price, quantity)
end
