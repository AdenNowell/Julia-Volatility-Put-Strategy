using DataFrames, Dates

function simulate_trades(df::DataFrame, cfg::BacktestConfig)::DataFrame
    trades = DataFrame(
        entry_idx = Int[],
        exit_idx = Int[],
        entry_date = Date[],
        expiry_date = Date[],
        entry_spot = Float64[],
        exit_spot = Float64[],
        iv = Float64[],
        iv_threshold = Float64[],
        strike = Float64[],
        premium_per_share = Float64[],
        premium_total = Float64[],
        intrinsic_value = Float64[],
        assigned = Bool[],
        transaction_cost = Float64[],
        pnl = Float64[]
    )

    active_expiries = Int[]

    for i in 1:nrow(df)
        filter!(x -> x > i, active_expiries)

        if i + cfg.tenor > nrow(df)
            continue
        end
        if !df.sell_put[i]
            continue
        end
        if length(active_expiries) >= cfg.max_open_positions
            continue
        end

        S0 = df.Close[i]
        ST = df.Close[i + cfg.tenor]
        σ  = df.IV[i]
        K  = strike_from_spot(S0, cfg.otm_pct)
        T  = cfg.tenor / 252.0

        premium_per_share = bs_put(S0, K, σ, T)
        premium_total     = premium_per_share * cfg.contract_multiplier
        intrinsic_value   = max(K - ST, 0.0)
        assigned          = ST < K

        pnl = (premium_per_share - intrinsic_value) * cfg.contract_multiplier -
              cfg.transaction_cost_per_contract

        push!(trades, (
            i,
            i + cfg.tenor,
            df.Date[i],
            df.Date[i + cfg.tenor],
            S0,
            ST,
            σ,
            Float64(df.iv_threshold[i]),
            K,
            premium_per_share,
            premium_total,
            intrinsic_value,
            assigned,
            cfg.transaction_cost_per_contract,
            pnl
        ))

        push!(active_expiries, i + cfg.tenor)
    end

    return trades
end

function simulate_account(df::DataFrame, trades::DataFrame, cfg::BacktestConfig)::DataFrame
    dates = df.Date

    if nrow(trades) == 0
        return DataFrame(
            Date = dates,
            cash = fill(cfg.initial_capital, length(dates)),
            reserved_collateral = zeros(length(dates)),
            equity = fill(cfg.initial_capital, length(dates)),
            open_positions = zeros(Int, length(dates))
        )
    end

    by_entry  = Dict{Date, Vector{Int}}()
    by_expiry = Dict{Date, Vector{Int}}()

    for (idx, row) in enumerate(eachrow(trades))
        push!(get!(by_entry, row.entry_date, Int[]), idx)
        push!(get!(by_expiry, row.expiry_date, Int[]), idx)
    end

    cash = cfg.initial_capital
    reserved = 0.0

    daily = DataFrame(
        Date = Date[],
        cash = Float64[],
        reserved_collateral = Float64[],
        equity = Float64[],
        open_positions = Int[]
    )

    for d in dates
        if haskey(by_entry, d)
            for idx in by_entry[d]
                collateral = trades.strike[idx] * cfg.contract_multiplier
                premium    = trades.premium_total[idx]
                fee        = trades.transaction_cost[idx]

                cash     -= collateral
                reserved += collateral
                cash     += premium
                cash     -= fee
            end
        end

        if haskey(by_expiry, d)
            for idx in by_expiry[d]
                collateral = trades.strike[idx] * cfg.contract_multiplier
                intrinsic  = trades.intrinsic_value[idx] * cfg.contract_multiplier

                reserved -= collateral
                cash     += collateral
                cash     -= intrinsic
            end
        end

        open_mask = (trades.entry_date .<= d) .& (d .< trades.expiry_date)
        open_positions = count(identity, open_mask)

        push!(daily, (
            d,
            cash,
            reserved,
            cash + reserved,
            open_positions
        ))
    end

    return daily
end
