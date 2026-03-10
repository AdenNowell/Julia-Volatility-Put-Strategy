Base.@kwdef struct BacktestConfig
    initial_capital::Float64 = 100_000.0
    window::Int = 100
    pct::Float64 = 0.80
    tenor::Int = 30
    otm_pct::Float64 = 0.00
    contract_multiplier::Int = 100
    max_open_positions::Int = 2
    transaction_cost_per_contract::Float64 = 1.50
    seed::Int = 42
end
