
# Volatility-Based Put Selling Strategy in Julia

This is a fully self-contained backtesting engine in Julia for simulating a volatility-triggered, cash-secured put strategy on SPY.

## Strategy Overview

- Calculate 80th percentile of implied volatility (IV) over a rolling 100-day window
- When IV > threshold → sell 30-day at-the-money (ATM) SPY put
- Options are priced using the Black-Scholes model
- Tracks account equity, cash, and collateral over time
- Benchmarks performance against SPY

## Example Output

```
Performance Summary
-------------------
Total Return      :   12.43 %
Annual Volatility :   17.86 %
Sharpe Ratio      :    0.76
```

## Packages Needed

- Julia 1.9+
- Packages:
  - DataFrames
  - CSV
  - Distributions
  - Statistics
  - Plots

Install with:
```julia
using Pkg
Pkg.add(["DataFrames", "CSV", "Distributions", "Plots"])
```

## How to Run

```bash
julia main.jl
```

No data setup required — dummy data is simulated if no CSVs are found.

MIT License
