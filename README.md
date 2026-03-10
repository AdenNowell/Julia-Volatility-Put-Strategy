# Julia Experiment

## Project Summary
This is a research-style Julia backtest for a volatility-triggered cash-secured put strategy on SPY. The goal is not to claim production alpha, but to demonstrate systematic research workflow.
## Research Question
Does selling short-dated cash-secured puts during elevated implied-volatility regimes improve risk-adjusted performance relative to passive SPY exposure?

## Methodology
1. Load SPY price data and implied-volatility data.
3. Trigger put-selling only when current IV exceeds the historical threshold.
4. Price each option using a Black-Scholes approximation.
5. Simulate trade PnL with transaction costs and collateral accounting.
6. Evaluate portfolio performance, drawdowns, and trade-level distributions.
7. Run parameter sweeps and bootstrap robustness tests.

## Improvements Over the Original Version
- Fixed put payoff logic.
- Corrected collateral and accounting mechanics.
- Removed look-ahead bias from signal construction.
- Added transaction costs.
- Added max-open-position control.
- Added drawdown and trade-level metrics.
- Added 5+ output charts.
- Added parameter sweep heatmap.
- Added bootstrap robustness analysis.

## Files
- `main.jl`: top-level runner
- `src/data.jl`: load and prepare data
- `src/signals.jl`: IV signal logic
- `src/pricing.jl`: Black-Scholes put pricing
- `src/backtest.jl`: trades and account simulation
- `src/metrics.jl`: performance and trade metrics
- `src/plots.jl`: charts
- `src/sweep.jl`: parameter sweep + heatmap
- `src/bootstrap.jl`: bootstrap robustness

## Input Data Format
### `data/spy_prices.csv`
Columns:
- `Date`
- `Close`

### `data/spy_iv.csv`
Columns:
- `Date`
- `IV`

If these files are missing, the project generates simulated placeholder data so the full research pipeline can still be executed.

## Setup
In Julia:

```julia
using Pkg
Pkg.activate(".")
Pkg.add(["CSV", "DataFrames", "Distributions", "Plots", "StatsBase"])
```

Then run:

```julia
julia --project=. main.jl
```

## Outputs
### Tables
- `outputs/tables/daily.csv`
- `outputs/tables/trades.csv`
- `outputs/tables/performance_summary.csv`
- `outputs/tables/parameter_sweep.csv`
- `outputs/tables/bootstrap_summary.csv`

### Figures
- `01_equity_vs_spy.png`
- `02_drawdown.png`
- `03_trade_pnl_hist.png`
- `04_entry_iv_vs_pnl.png`
- `05_open_positions.png`
- `06_sweep_heatmap_sharpe.png`
- `07_bootstrap_total_pnl.png`

## Limitations
- Uses a Black-Scholes approximation instead of real option chain execution.
- Assumes European expiry-style payoff.
- Does not model assignment carry, early exercise, dividends, or margin rules.
- Designed as a research prototype rather than a production execution engine.

## Why Julia
I wanted to learn it compared to matlab
