using Distributions

const BSN = Normal()

function strike_from_spot(S::Real, otm_pct::Real)
    return round(S * (1.0 - otm_pct), digits = 2)
end

function bs_put(S::Real, K::Real, σ::Real, T::Real; r::Real = 0.0)
    if T <= 0 || σ <= 0
        return max(K - S, 0.0)
    end

    d1 = (log(S / K) + (r + 0.5 * σ^2) * T) / (σ * sqrt(T))
    d2 = d1 - σ * sqrt(T)

    return K * exp(-r * T) * cdf(BSN, -d2) - S * cdf(BSN, -d1)
end
