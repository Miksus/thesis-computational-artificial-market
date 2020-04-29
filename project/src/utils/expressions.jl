"Replace old symbol with new (expression or symbol) in expression"
function substitute!(e::Expr, old::Symbol, new::Union{Expr, Symbol})
   for (i,a) in enumerate(e.args)
       if a==old
           e.args[i] = new
       elseif a isa Expr
           substitute!(a, old, new)
       end
       ## otherwise do nothing
   end
   e
end

function substitute(e::Expr, old::Symbol, new::Union{Expr, Symbol})
    e_copy = copy(e)
   for (i,a) in enumerate(e_copy.args)
       if a==old
           e_copy.args[i] = new
       elseif a isa Expr
           substitute!(a, old, new)
       end
       ## otherwise do nothing
   end
   e_copy
end

"For example: (x = y, y = 5*2, z = y / x) --> (y = 5*2, x = y, z = y / x)"
function get_expression_order(vargs::Expr...)
    n_expressions = length(vargs)
    exprs_left = collect(vargs)
    exprs_placed = Array{Expr, 1}()
    while length(exprs_left) > 0
        if length(exprs_left) == 1
            push!(exprs_placed, exprs_left[1])
            break
        end

        found_independent = false
        for (i, expr) in enumerate(exprs_left)

            return_symbols = Array{Symbol, 1}()
            for expr_other in filter(x -> x != expr, exprs_left)
                if expr_other.head == :(=)
                    if expr_other.args[1] isa Expr
                        # expr_other as "(x, y) = ..."
                        push!(return_symbols, expr_other.args[1].args...)
                    else
                        # expr_other as "x = ..."
                        push!(return_symbols, expr_other.args[1])
                    end
                end
            end

            expr_rightside = is_assignment(expr) ? expr.args[2] : expr # Check if like "x = ..." or "y * 2"
            if expr_rightside isa Symbol
                # expr_rightside as format "y"
                has_no_dependency = all(
                    expr_rightside == return_symbol
                    for return_symbol in return_symbols
                )
            else
                # expr_rightside as format "y * 2"
                has_no_dependency = all(
                    ~occursin(return_symbol, expr_rightside)
                    for return_symbol in return_symbols
                )
            end

            if has_no_dependency
                push!(exprs_placed, expr)
                deleteat!(exprs_left, i)
                found_independent = true
                break
            end
        end
        if ~found_independent
            throw(ArgumentError("Cross reference in expressions: $exprs_left."))
        end
    end
    exprs_placed
end


is_assignment(e::Expr) = e.head == :(=)
import Base: occursin

function Base.occursin(s::Symbol, e::Expr)

    for arg in e.args
        if s == arg
            return true
        elseif typeof(arg) == Expr
            if occursin(s, arg)
                 return true
            end
        end
    end
    return false
end
