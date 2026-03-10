using Pkg
Pkg.activate(@__DIR__)

using CSV, DataFrames, Dates, Distributions, Plots, Printf, Random, Statistics, StatsBase

include("src/types.jl")
include("src/data.jl")
include("src/signals.jl")
include("src/pricing.jl")
include("src/backtest.jl")
include("src/metrics.jl")
include("src/plots.jl")
include("src/sweep.jl")
include("src/bootstrap.jl")

function main()
    ensure_dirs()

    cfg = BacktestConfig(
        initial_capital = 100_000.0,
        window = 100,
        pct = 0.80,
        tenor = 30,
        otm_pct = 0.00,
        contract_multiplier = 100,
        max_open_positions = 2,
        transaction_cost_per_contract = 1.50,
        seed = 42
    )

    raw_df = load_data(seed = cfg.seed)
    sig_df = add_iv_signal(raw_df; window = cfg.window, pct = cfg.pct)

    trades = simulate_trades(sig_df, cfg)
    daily  = simulate_account(sig_df, trades, cfg)

    perf_df = performance_summary(daily, trades)
    trade_df = trade_summary(trades)

    CSV.write("outputs/tables/daily.csv", daily)
    CSV.write("outputs/tables/trades.csv", trades)
    CSV.write("outputs/tables/performance_summary.csv", perf_df)
    CSV.write("outputs/tables/trade_summary.csv", trade_df)

    plot_equity_vs_benchmark(daily, sig_df)
    plot_drawdown(daily)
    plot_pnl_histogram(trades)
    plot_iv_scatter(trades)
    plot_open_positions(daily)

    sweep_df = run_parameter_sweep(raw_df, cfg;
        pct_grid = [0.70, 0.80, 0.90],
        tenor_grid = [15, 30, 45])

    CSV.write("outputs/tables/parameter_sweep.csv", sweep_df)
    plot_sweep_heatmap(sweep_df; value_col = :sharpe)

    boot_summary, boot_dist = bootstrap_trade_pnl(trades; n_boot = 2000, seed = cfg.seed)
    CSV.write("outputs/tables/bootstrap_summary.csv", boot_summary)
    CSV.write("outputs/tables/bootstrap_distribution.csv", boot_dist)
    plot_bootstrap_hist(boot_dist)

    println("\n================ PERFORMANCE SUMMARY ================\n")
    println(perf_df)

    println("\n================ TRADE SUMMARY ================\n")
    println(trade_df)

    println("\n================ BOOTSTRAP SUMMARY ================\n")
    println(boot_summary)

    println("\nFiles written to outputs/tables and outputs/figures")
end

main()
