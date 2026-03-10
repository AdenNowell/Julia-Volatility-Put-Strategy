using DataFrames, Statistics

function drawdown_series(equity::AbstractVector{<:Real})
    dd = Vector{Float64}(undef, length(equity))
    peak = -Inf

    for i in eachindex(equity)
        peak = max(peak, float(equity[i]))
        dd[i] = float(equity[i]) / peak - 1.0
    end

    return dd
end

function performance_namedtuple(daily::DataFrame, trades::DataFrame)
    if nrow(daily) < 2
        return (
            total_return = 0.0,
            annual_return = 0.0,
            annual_vol = 0.0,
            sharpe = 0.0,
            max_drawdown = 0.0,
            n_trades = nrow(trades),
            win_rate = 0.0,
            avg_trade_pnl = 0.0,
            median_trade_pnl = 0.0,
            best_trade_pnl = 0.0,
            worst_trade_pnl = 0.0,
            profit_factor = 0.0
        )
    end

    rets = diff(daily.equity) ./ daily.equity[1:end-1]
    total_return = daily.equity[end] / daily.equity[1] - 1.0

    n_periods = max(length(rets), 1)
    annual_return = daily.equity[end] > 0 ?
        (daily.equity[end] / daily.equity[1])^(252 / n_periods) - 1.0 : -1.0

    annual_vol = length(rets) > 1 ? std(rets) * sqrt(252) : 0.0
    sharpe = (length(rets) > 1 && std(rets) > 0) ? mean(rets) / std(rets) * sqrt(252) : 0.0
    max_drawdown = minimum(drawdown_series(daily.equity))

    if nrow(trades) == 0
        return (
            total_return = total_return,
            annual_return = annual_return,
            annual_vol = annual_vol,
            sharpe = sharpe,
            max_drawdown = max_drawdown,
            n_trades = 0,
            win_rate = 0.0,
            avg_trade_pnl = 0.0,
            median_trade_pnl = 0.0,
            best_trade_pnl = 0.0,
            worst_trade_pnl = 0.0,
            profit_factor = 0.0
        )
    end

    wins = trades.pnl .> 0
    gross_profit = sum(trades.pnl[trades.pnl .> 0])
    gross_loss   = abs(sum(trades.pnl[trades.pnl .< 0]))
    profit_factor = gross_loss > 0 ? gross_profit / gross_loss : Inf

    return (
        total_return = total_return,
        annual_return = annual_return,
        annual_vol = annual_vol,
        sharpe = sharpe,
        max_drawdown = max_drawdown,
        n_trades = nrow(trades),
        win_rate = mean(wins),
        avg_trade_pnl = mean(trades.pnl),
        median_trade_pnl = median(trades.pnl),
        best_trade_pnl = maximum(trades.pnl),
        worst_trade_pnl = minimum(trades.pnl),
        profit_factor = profit_factor
    )
end

function performance_summary(daily::DataFrame, trades::DataFrame)::DataFrame
    p = performance_namedtuple(daily, trades)

    return DataFrame(
        metric = [
            "Total Return",
            "Annual Return",
            "Annual Volatility",
            "Sharpe Ratio",
            "Max Drawdown",
            "Number of Trades",
            "Win Rate",
            "Average Trade PnL",
            "Median Trade PnL",
            "Best Trade PnL",
            "Worst Trade PnL",
            "Profit Factor"
        ],
        value = Any[
            p.total_return,
            p.annual_return,
            p.annual_vol,
            p.sharpe,
            p.max_drawdown,
            p.n_trades,
            p.win_rate,
            p.avg_trade_pnl,
            p.median_trade_pnl,
            p.best_trade_pnl,
            p.worst_trade_pnl,
            p.profit_factor
        ]
    )
end

function trade_summary(trades::DataFrame)::DataFrame
    if nrow(trades) == 0
        return DataFrame(metric = ["Trades Generated"], value = [0])
    end

    return DataFrame(
        metric = [
            "Trades Generated",
            "Average Premium",
            "Average Intrinsic",
            "Assignment Rate",
            "Average Entry IV"
        ],
        value = [
            nrow(trades),
            mean(trades.premium_total),
            mean(trades.intrinsic_value .* 100),
            mean(trades.assigned),
            mean(trades.iv)
        ]
    )
end
