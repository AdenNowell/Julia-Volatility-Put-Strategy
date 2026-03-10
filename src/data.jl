using CSV, DataFrames, Dates, Random

function ensure_dirs()
    mkpath("outputs/figures")
    mkpath("outputs/tables")
    mkpath("data")
end

function load_data(; price_path::String = "data/spy_prices.csv",
                     iv_path::String = "data/spy_iv.csv",
                     seed::Int = 42)::DataFrame
    if isfile(price_path) && isfile(iv_path)
        prices = CSV.read(price_path, DataFrame)
        ivs    = CSV.read(iv_path, DataFrame)

        if !(eltype(prices.Date) <: Date)
            prices.Date = Date.(prices.Date)
        end
        if !(eltype(ivs.Date) <: Date)
            ivs.Date = Date.(ivs.Date)
        end

        df = innerjoin(prices[:, [:Date, :Close]], ivs[:, [:Date, :IV]], on = :Date)
        sort!(df, :Date)
        return df
    end

    Random.seed!(seed)
    dates = collect(Date(2024, 1, 2):Day(1):Date(2024, 12, 31))
    dates = filter(d -> dayofweek(d) ∈ 1:5, dates)

    n = length(dates)
    close = cumsum(randn(n) .* 1.5 .+ 0.1) .+ 450.0
    iv    = clamp.(randn(n) .* 0.04 .+ 0.20, 0.05, 0.60)

    return DataFrame(Date = dates, Close = close, IV = iv)
end
