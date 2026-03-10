using DataFrames, CSV, Plots

function run_parameter_sweep(raw_df::DataFrame, base_cfg::BacktestConfig;
                             pct_grid = [0.70, 0.80, 0.90],
                             tenor_grid = [15, 30, 45])::DataFrame
    results = DataFrame(
        pct = Float64[],
        tenor = Int[],
        total_return = Float64[],
        annual_return = Float64[],
        annual_vol = Float64[],
        sharpe = Float64[],
        max_drawdown = Float64[],
        n_trades = Int[]
    )

    for pct in pct_grid
        for tenor in tenor_grid
            cfg = BacktestConfig(
                initial_capital = base_cfg.initial_capital,
                window = base_cfg.window,
                pct = pct,
                tenor = tenor,
                otm_pct = base_cfg.otm_pct,
                contract_multiplier = base_cfg.contract_multiplier,
                max_open_positions = base_cfg.max_open_positions,
                transaction_cost_per_contract = base_cfg.transaction_cost_per_contract,
                seed = base_cfg.seed
            )

            sig_df = add_iv_signal(raw_df; window = cfg.window, pct = cfg.pct)
            trades = simulate_trades(sig_df, cfg)
            daily  = simulate_account(sig_df, trades, cfg)
            p = performance_namedtuple(daily, trades)

            push!(results, (
                pct,
                tenor,
                p.total_return,
                p.annual_return,
                p.annual_vol,
                p.sharpe,
                p.max_drawdown,
                p.n_trades
            ))
        end
    end

    return results
end

function plot_sweep_heatmap(sweep_df::DataFrame;
                            value_col::Symbol = :sharpe,
                            outpath::String = "outputs/figures/06_sweep_heatmap_sharpe.png")
    pcts = sort(unique(sweep_df.pct))
    tenors = sort(unique(sweep_df.tenor))

    z = fill(NaN, length(pcts), length(tenors))

    for (i, p) in enumerate(pcts)
        for (j, t) in enumerate(tenors)
            row = sweep_df[(sweep_df.pct .== p) .& (sweep_df.tenor .== t), :]
            if nrow(row) > 0
                z[i, j] = row[1, value_col]
            end
        end
    end

    p = heatmap(tenors, pcts, z,
        xlabel = "Tenor (Trading Days)",
        ylabel = "IV Percentile Trigger",
        title = "Parameter Sweep: $(String(value_col))",
        framestyle = :box)

    savefig(p, outpath)
end
