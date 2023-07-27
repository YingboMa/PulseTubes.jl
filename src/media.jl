using Interpolations, JLD2

Base.@kwdef struct SinglePhaseGas{T}
    "Name of ideal gas"
    name::String
    "Mass specific density [kg/m^3]"
    Dmass::T
    "Mass specific internal energy [J/kg]"
    Umass::T
    "Mass specific entropy [J/kg/K]"
    Smass::T
    "Mass specific enthalpy [J/kg]"
    Hmass::T
    "Mass specific constant volume specific heat [J/kg/K]"
    Cvmass::T
    "Mass specific constant pressure specific heat [J/kg/K]"
    Cpmass::T
    "Thermal conductivity [W/m/K]"
    conductivity::T
    "Viscosity [Pa s]"
    viscosity::T
end

function SinglePhaseGas(name)
    dir = dirname(@__FILE__)
    data = jldopen(joinpath(dir, "..", "data", "$name.jld2"))
    SinglePhaseGas(;
        name,
        Dmass = data["Dmass"],
        Umass = data["Umass"],
        Smass = data["Smass"],
        Hmass = data["Hmass"],
        Cvmass = data["Cvmass"],
        Cpmass = data["Cpmass"],
        conductivity = data["conductivity"],
        viscosity = data["viscosity"],
    )
end

const Air = SinglePhaseGas("Air")
const Nitrogen = SinglePhaseGas("Nitrogen")
const Helium = SinglePhaseGas("Helium")
const Hydrogen = SinglePhaseGas("Hydrogen")

function ThermodynamicState(data::SinglePhaseGas; name)
    vars = @variables T(t) = 298.15 P(t) = 101325.0
    ODESystem(Equation[], t, vars, [], name = name)
end

"""
- `T`: Temperature [K]
- `P`: Pressure [Pa]
- `ρ`: Density [kg/m³]
- `u`: Specific internal energy [J/kg]
- `s`: Specific entropy  [J/(kg*K)]
- `h`: Specific enthalpy [J/kg]
- `cv`: Specific isochoric heat capacity [J/(kg*K)]
- `cp`: Specific isobaric heat capacity [J/(kg*K)]
- `k`: Thermal conductivity [W/(m*K)]
- `μ`: Viscosity [Pa s]
"""
function BaseProperties(data::SinglePhaseGas; name)
    systems = @named begin
        state = ThermodynamicState(data)
    end
    vars = @variables begin
        T(t)
        P(t)
        ρ(t)
        u(t)
        s(t)
        h(t)
        cv(t)
        cp(t)
        k(t)
        μ(t)
    end
    eqs = [
        T ~ state.T
        P ~ state.P
        ρ ~ density(state, data)
        u ~ specific_internal_energy(state, data)
        s ~ specific_entropy(state, data)
        h ~ specific_enthalpy(state, data)
        cv ~ specific_Cv(state, data)
        cp ~ specific_Cp(state, data)
        k ~ conductivity(state, data)
        μ ~ viscosity(state, data)
    ]
    ODESystem(eqs, t, vars, []; name = name, systems)
end

@register_symbolic interpolate(_::Interpolations.AbstractInterpolationWrapper, x, y)
interpolate(interp::Interpolations.AbstractInterpolationWrapper, x, y) = interp(x, y)
density(state, data::SinglePhaseGas) = interpolate(data.Dmass, state.T, state.P)
specific_internal_energy(state, data::SinglePhaseGas) =
    interpolate(data.Umass, state.T, state.P)
specific_entropy(state, data::SinglePhaseGas) = interpolate(data.Smass, state.T, state.P)
specific_enthalpy(state, data::SinglePhaseGas) = interpolate(data.Hmass, state.T, state.P)
specific_Cv(state, data::SinglePhaseGas) = interpolate(data.Cvmass, state.T, state.P)
specific_Cp(state, data::SinglePhaseGas) = interpolate(data.Cpmass, state.T, state.P)
conductivity(state, data::SinglePhaseGas) = interpolate(data.conductivity, state.T, state.P)
viscosity(state, data::SinglePhaseGas) = interpolate(data.viscosity, state.T, state.P)
