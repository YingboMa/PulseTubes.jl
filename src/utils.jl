@connector FluidPort begin
    p(t) = 0
    m_flow(t) = 0.02, [connect = Flow]
    h_outflow(t) = 0.0, [connect = Stream]
end

@component function PartialDistributedVolume(; name, n = 2)
    @named begin
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
end

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
