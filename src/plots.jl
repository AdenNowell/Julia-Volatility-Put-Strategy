using Plots, DataFrames, Statistics

default(size = (900, 500), legend = :top, linewidth = 2)

function no_data_plot(title_text::String, outpath::String)
    p = plot([0.0, 1.0], [0.0, 1.0],
        label = "",
        linealpha = 0.0,
        grid = false,
        xticks = false,
        yticks = false,
        framestyle = :box,
        title = title_text)
    annotate!(0.5, 0.5, text("No trades generated", 12))
    savefig(p, outpath)
end

function plot_equity_vs_benchmark(daily::DataFrame, df::DataFrame;
                                  outpath::String = "outputs/figures/01_equity_vs_spy.png")
    merged = innerjoin(daily, df[:, [:Date, :Close]], on = :Date)
    base = merged.equity[1]
    merged.spy_rebased = merged.Close ./ merged.Close[1] .* base

    p = plot(merged.Date, merged.equity,
        label = "Strategy Equity",
        xlabel = "Date",
        ylabel = "Portfolio Value",
        title = "Equity Curve vs SPY",
        framestyle = :box)

    plot!(p, merged.Date, merged.spy_rebased, label = "SPY Rebased")
    savefig(p, outpath)
end

function plot_drawdown(daily::DataFrame;
                       outpath::String = "outputs/figures/02_drawdown.png")
    dd = drawdown_series(daily.equity)

    p = plot(daily.Date, dd,
        label = "Drawdown",
        xlabel = "Date",
        ylabel = "Drawdown",
        title = "Strategy Drawdown",
        framestyle = :box)

    hline!(p, [minimum(dd)], label = "Max DD")
    savefig(p, outpath)
end

function plot_pnl_histogram(trades::DataFrame;
                            outpath::String = "outputs/figures/03_trade_pnl_hist.png")
    if nrow(trades) == 0
        no_data_plot("Trade PnL Distribution", outpath)
        return
    end

    p = histogram(trades.pnl,
        bins = 20,
        xlabel = "Trade PnL",
        ylabel = "Frequency",
        title = "Trade PnL Distribution",
        label = "PnL",
        framestyle = :box)

    savefig(p, outpath)
end

function plot_iv_scatter(trades::DataFrame;
                         outpath::String = "outputs/figures/04_entry_iv_vs_pnl.png")
    if nrow(trades) == 0
        no_data_plot("Entry IV vs Trade PnL", outpath)
        return
    end

    p = scatter(trades.iv, trades.pnl,
        xlabel = "Entry IV",
        ylabel = "Trade PnL",
        title = "Entry IV vs Trade PnL",
        label = "Trades",
        framestyle = :box)

    savefig(p, outpath)
end

function plot_open_positions(daily::DataFrame;
                             outpath::String = "outputs/figures/05_open_positions.png")
    p = plot(daily.Date, daily.open_positions,
        xlabel = "Date",
        ylabel = "Contracts Open",
        title = "Open Positions Through Time",
        label = "Open Positions",
        framestyle = :box)

    savefig(p, outpath)
end
