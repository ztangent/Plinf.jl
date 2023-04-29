import GenParticleFilters: ParticleFilterView

export probvec

"""
    probvec(pf::ParticleFilterView, addr)

Returns a probability vector for values of `addr` in the particle filter.
"""
function probvec(pf::ParticleFilterView, addr)
    pmap = proportionmap(pf, addr)
    keys = collect(keys(pmap))
    if hasmethod(isless, Tuple{eltype(keys), eltype(keys)})
        sort!(keys)
    end
    return [pmap[k] for k in keys]
end

function probvec(pf::ParticleFilterView, addr, support)
    pmap = proportionmap(pf, addr)
    return [get(pmap, k, 0.0) for k in support]
end
