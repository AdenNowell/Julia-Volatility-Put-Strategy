using DataFrames, Statistics

function add_iv_signal(df::DataFrame; window::Int = 100, pct::Float64 = 0.80)::DataFrame
    out = copy(df)
    n = nrow(out)

    iv_thr = Vector{Union{Missing, Float64}}(undef, n)
    fill!(iv_thr, missing)
    trigger = falses(n)

    for i in 1:n
        if i > window
            hist = out.IV[i-window:i-1]
            thr = quantile(hist, pct)
            iv_thr[i] = thr
            trigger[i] = out.IV[i] > thr
        end
    end

    out.iv_threshold = iv_thr
    out.sell_put = trigger
    return out
end
