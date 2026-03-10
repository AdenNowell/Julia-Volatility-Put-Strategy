using DataFrames, StatsBase, Random, Statistics, Plots

function bootstrap_trade_pnl(trades::DataFrame; n_boot::Int = 2000, seed::Int = 42)
    if nrow(trades) == 0
        summary = DataFrame(stat = ["mean", "median", "p05", "p95"],
                            value = [0.0, 0.0, 0.0, 0.0])
        dist = DataFrame(sim = Int[], total_pnl = Float64[])
        return summary, dist
    end

    Random.seed!(seed)
    pnls = collect(trades.pnl)
    n = length(pnls)

    sims = Vector{Float64}(undef, n_boot)

    for b in 1:n_boot
        draw = sample(pnls, n; replace = true)
        sims[b] = sum(draw)
    end

    summary = DataFrame(
        stat = ["mean", "median", "p05", "p95"],
        value = [
            mean(sims),
            median(sims),
            quantile(sims, 0.05),
            quantile(sims, 0.95)
        ]
    )

    dist = DataFrame(sim = 1:n_boot, total_pnl = sims)
    return summary, dist
end

function plot_bootstrap_hist(dist::DataFrame;
                             outpath::String = "outputs/figures/07_bootstrap_total_pnl.png")
    if nrow(dist) == 0
        no_data_plot("Bootstrap Trade PnL", outpath)
        return
    end

    p = histogram(dist.total_pnl,
        bins = 30,
        xlabel = "Bootstrapped Total PnL",
        ylabel = "Frequency",
        title = "Bootstrap Robustness: Total PnL Distribution",
        label = "Bootstrap",
        framestyle = :box)

    savefig(p, outpath)
end
