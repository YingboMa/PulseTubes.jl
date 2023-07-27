using CoolProp
using JLD2
using Interpolations
using Memoize
@memoize PropsSIm(args...) = PropsSI(args...)

function generate_property_file(fluid, (T_min, T_max), (P_min, P_max), filename)
    T_coarse = range(T_min, T_max, length = 16)
    P_coarse = range(P_min, P_max, length = 16)
    T = range(T_min, T_max, length = 64)
    P = range(P_min, P_max, length = 64)
    T_fine = range(T_min, T_max, length = 256)
    P_fine = range(P_min, P_max, length = 256)

    interps = Dict{Symbol,Any}()
    for f in [:Dmass, :Umass, :Hmass, :Smass, :Cvmass, :Cpmass, :viscosity, :conductivity]
        T, P = f in (:Dmass,) ? (T, P) : (T_coarse, P_coarse)
        s = string(f)
        ref = PropsSIm.(s, "T", T, "P", P', fluid)
        itp = scale(interpolate(ref, BSpline(Cubic())), T, P)
        ref2 = PropsSIm.(s, "T", T_fine, "P", P_fine', fluid)
        interp = itp.(T_fine, P_fine')
        interps[f] = itp
        Main._a[] = ref2, interp
        r_err = maximum(abs, (ref2 .- interp) ./ interp) * 100
        r_err > 2 && error("Property $f is not accrate enough. Relative error: $(r_err)%.")
    end
    jldsave(filename; interps...)
end
Ts = T_min, T_max = 100, 400
Ps = P_min, P_max = 50e3, 500e3
@time generate_property_file("Air", Ts, Ps, "Air.jld2")
@time generate_property_file("Nitrogen", Ts, Ps, "Nitrogen.jld2")
#@time generate_property_file("Argon", Ts, Ps, "Argon.jld2")

Ts = T_min, T_max = 50, 400
Ps = P_min, P_max = 50e3, 100e3
@time generate_property_file("Helium", Ts, Ps, "Helium.jld2")
@time generate_property_file("Hydrogen", Ts, Ps, "Hydrogen.jld2")
