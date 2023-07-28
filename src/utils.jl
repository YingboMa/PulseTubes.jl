@connector FluidPort begin
    p(t) = 0
    m_flow(t) = 0.02, [connect = Flow]
    h_outflow(t) = 0.0, [connect = Stream]
end

@component function PartialDistributedVolume(; name, n = 2)
    systems = @named begin
        fluidVolumeInputs = RealInput(; nin = n)
    end
    fluidVolumes = collect(fluidVolumeInputs.u)
    @variables begin
        Us(t)[1:n], [description = "Internal energy of fluid"]
        ms(t)[1:n], [description = "Fluid mass"]
        mb_flows(t)[1:n], [description = "Mass flow rate, source or sink"]
        Hb_flows(t)[1:n], [description = "Enthalpy flow rate, source or sink"]
        Qb_flows(t)[1:n], [description = "Heat flow rate, source or sink"]
        Wb_flows(t)[1:n], [description = "Mechanical power, p*der(V) etc."]
    end
    eqs = Equation[]
    for i = 1:n
        push!(eqs, ms[i] ~ fluidVolumes[i] * mediums[i].d)
        push!(eqs, Us[i] ~ ms[i] * mediums[i].u)
        # Energy and mass balances
        push!(eqs, D(Us[i]) ~ Hb_flows[i] + Wb_flows[i] + Qb_flows[i])
        push!(eqs, D(ms[i]) ~ mb_flows[i])
    end
    ODESystem(eqs; systems = [systems...;], name)
end

# PartialTwoPort just has two ports
@component function PartialTwoPortFlow(; name, n = 2)
    @named port_a = FluidPort()
    @named port_b = FluidPort()
    @named dvol = PartialDistributedVolume(n)
    #@unpack = dvol
    @parameters begin
        lengths[1:n]
        crossAreas[1:n]
        dimensions[1:n]
        roughnesses[1:n]
        dheights[1:n]
    end
end

function IdealFlowHeatTransfer(;name, state, n = 1)
    systems = @named begin
        states[1:n] = ThermodynamicState(state)
        heatPorts[1:n] = HeatPort()
    end
    Medium.Temperature[n]  = Medium.temperature(states)
    @parameters begin
        surfaceAreas[1:n]
        k [description="Heat transfer coefficient to ambient"]
        T_ambient
    end
    @states begin
        Q_flows(t)[1:n]
        Ts(t)[1:n]
    end
    eqs = [Q_flows[i] ~ heatPorts[i].Q_flow + k*surfaceAreas[i]*(T_ambient - heatPorts[i].T) for i in 1:n]
    append!(eqs, [Ts[i] ~ heatPorts[i].T for i in 1:n])
    ODESystem(eqs; systems = [systems...;], name)
end

function DetailedPipeFlow(;name )
end

function PartialStaggeredFlowModel(;name, state, n = 2)
end

# DynamicPipe:
# - extends PartialStraightPipe
#   - extends PartialTwoPort [just two ports]
#   - composes DetailedPipeFlow "Wall friction, gravity, momentum flow"
# - extends PartialTwoPortFlow
#   - extends PartialTwoPort [just two ports]
#   - extends PartialDistributedVolume [Medium]
#   - composes DetailedPipeFlow "Wall friction, gravity, momentum flow"
#     - extends PartialGenericPipeFlow
#       - PartialStaggeredFlowModel
#       - WallFriction.Detailed
# - composes IdealFlowHeatTransfer
#   - extends PartialFlowHeatTransfer
#     - extends PartialHeatTransfer [Medium]
