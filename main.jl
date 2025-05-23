
#!/usr/bin/env julia
# main.jl — Volatility-Triggered Cash-Secured Put Back-tester
#
# Dependencies:
#   DataFrames, CSV, Distributions, Statistics, Plots, Dates
# -----------------------------------------------------------

using CSV, DataFrames, Dates, Random
using Statistics, Distributions, Plots, Printf

# -----------------------------------------------------------
# 1. Load or simulate SPY + IV data
# -----------------------------------------------------------
function load_data(price_path::String="spy_prices.csv",
                   iv_path::String="spy_iv.csv")::DataFrame
    if isfile(price_path) && isfile(iv_path)
        prices = CSV.read(price_path, DataFrame)
        ivs    = CSV.read(iv_path,    DataFrame)
        return innerjoin(prices, ivs, on = :Date)
    end

    # --- Dummy data (≈250 trading days) ---
    Random.seed!(42)
    dates = collect(Date(2024,1,2):Day(1):Date(2024,12,31))
    dates = filter(d -> dayofweek(d) ∈ 1:5, dates)           # weekdays
    n     = length(dates)

    close = cumsum(randn(n) .* 1.5 .+ 0.1) .+ 450.0          # random walk
    iv    = clamp.(randn(n) .* 0.04 .+ 0.20, 0.05, 0.60)     # IV 5-60%

    return DataFrame(Date = dates, Close = close, IV = iv)
end

# -----------------------------------------------------------
# 2. Calculate rolling IV 80th-percentile & signal
# -----------------------------------------------------------
function add_iv_signal!(df::DataFrame; window::Int = 100,
                                      pct::Float64 = 0.80)
    n = nrow(df)
    iv_thr  = Vector{Union{Missing,Float64}}(undef, n)
    trigger = falses(n)

    for i in 1:n
        if i ≥ window
            thr = quantile(df.IV[i-window+1:i], pct)
            iv_thr[i]  = thr
            trigger[i] = df.IV[i] > thr
        else
            iv_thr[i]  = missing
        end
    end
    df.iv_p80   = iv_thr
    df.sell_put = trigger
    return df
end

# -----------------------------------------------------------
# 3. Black-Scholes put pricer (r = 0)
# -----------------------------------------------------------
bsN = Normal()
function bs_put(S, K, σ, T)
    d1 = (log(S / K) + 0.5*σ^2*T) / (σ * sqrt(T))
    d2 = d1 - σ*sqrt(T)
    return K*cdf(bsN, -d2) - S*cdf(bsN, -d1)
end

# -----------------------------------------------------------
# 4. Create trades DataFrame
# -----------------------------------------------------------
function simulate_trades(df::DataFrame)::DataFrame
    trades = DataFrame(entry_date = Date[],
                       expiry_date = Date[],
                       strike      = Float64[],
                       entry_price = Float64[],
                       exit_price  = Float64[],
                       premium     = Float64[],
                       pnl         = Float64[])

    tenor   = 30                               # trading days
    for i in 1:nrow(df)
        if df.sell_put[i] && i + tenor ≤ nrow(df)
            S    = df.Close[i]
            σ    = df.IV[i]
            prem = bs_put(S, S, σ, tenor / 252)

            exit_price = df.Close[i + tenor]
            pnl        = prem - max(0.0, S - exit_price)      # net profit/loss

            push!(trades, (; entry_date  = df.Date[i],
                            expiry_date = df.Date[i + tenor],
                            strike      = S,
                            entry_price = S,
                            exit_price,
                            premium = prem,
                            pnl))
        end
    end
    return trades
end

# -----------------------------------------------------------
# 5. Simulate account (cash, collateral, equity)
# -----------------------------------------------------------
function simulate_account(trades::DataFrame)::DataFrame
    start_d = minimum(trades.entry_date)
    end_d   = maximum(trades.expiry_date)
    days    = collect(start_d:Day(1):end_d)

    by_entry  = Dict{Date,Vector{Int}}()
    by_expiry = Dict{Date,Vector{Int}}()
    for (idx, row) in enumerate(eachrow(trades))
        push!(get!(by_entry,  row.entry_date,  Int[]), idx)
        push!(get!(by_expiry, row.expiry_date, Int[]), idx)
    end

    cash, collateral = 100_000.0, 0.0
    daily = DataFrame(Date = Date[], cash = Float64[],
                      collateral = Float64[], equity = Float64[])

    for d in days
        # — new trades —
        if haskey(by_entry, d)
            for idx in by_entry[d]
                strike  = trades.strike[idx]
                prem    = trades.premium[idx]
                cash      -= strike          # post collateral
                cash      += prem            # receive premium
                collateral += strike
            end
        end

        # — expiries —
        if haskey(by_expiry, d)
            for idx in by_expiry[d]
                strike  = trades.strike[idx]
                expireP = trades.exit_price[idx]
                collateral -= strike
                cash       += expireP        # return collateral minus loss
            end
        end

        push!(daily, (; Date = d,
                       cash,
                       collateral,
                       equity = cash + collateral))
    end
    return daily
end

# -----------------------------------------------------------
# 6. Performance stats
# -----------------------------------------------------------
function perf_stats(daily::DataFrame)
    rets = diff(daily.equity) ./ daily.equity[1:end-1]
    total_ret = daily.equity[end] / daily.equity[1] - 1
    ann_vol   = std(rets) * sqrt(252)
    sharpe    = mean(rets) / std(rets) * sqrt(252)
    @printf("\nPerformance Summary\n-------------------\n")
    @printf("Total Return      : %8.2f %%\n", total_ret * 100)
    @printf("Annual Volatility : %8.2f %%\n", ann_vol * 100)
    @printf("Sharpe Ratio      : %8.2f\n\n", sharpe)
end

# -----------------------------------------------------------
# 7. Plot equity vs. SPY
# -----------------------------------------------------------
function plot_equity(daily::DataFrame, df::DataFrame)
    merged = innerjoin(daily, df[:, [:Date, :Close]], on = :Date)
    base   = merged.equity[1]
    merged.SPY = merged.Close ./ merged.Close[1] .* base

    plot(merged.Date, merged.equity, lw = 2, label = "Strategy Equity")
    plot!(merged.Date, merged.SPY,     lw = 2, label = "SPY Rebased")
    xlabel!("Date"); ylabel!("Equity ($)")
    title!("Equity Curve vs. SPY")
    savefig("plots/equity_vs_spy.png")
end

# -----------------------------------------------------------
# 8. Main
# -----------------------------------------------------------
function main()
    df      = add_iv_signal!(load_data())
    trades  = simulate_trades(df)
    daily   = simulate_account(trades)

    perf_stats(daily)
    plot_equity(daily, df)
end

main()
