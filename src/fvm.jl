using ModelingToolkit
# States: ṁ, P, T
# Energy grid: n+1
# Momentum grid: n

midpoint(a, b) = (a + b)/2
N = 10
L = 1

Base.@kwdef struct Grid{T1, T2, T3}
    energy_grid::T1
    momentum_grid::T2
    areas::T3
end
Δx(g::Grid, i) = g.energy_grid[i + 1] - g.energy_grid[i]
δx(g::Grid, i) = g.momentum_grid[i] - g.momentum_grid[i - 1]
PA(g::Grid, i) = g.areas[i]
MA(g::Grid, i) = midpoint(PA(g, i + 1), PA(g, i))

energy_grid = range(0, L, length = N)
areas = fill(1, N)
momentum_grid = [midpoint(energy_grid[i+1], energy_grid[i]) for i in 1:N-1]
grid = Grid(;energy_grid, momentum_grid, areas)

@variables t
D = Differential(t)
@variables begin
    # mass
    ṁs(t)[1:N+1]
    ḣs(t)[1:N+1]
    ḣb(t)[1:N]
    ms(t)[1:N]
    # fluid thermo states
    Ps(t)[1:N]
    hs(t)[1:N]
    # fluid properties
    ρs(t)[1:N] # density
    us(t)[1:N] # internal energy
    Ts(t)[1:N] # temperature
    vs(t)[1:N] # velocity
    ks(t)[1:N] # thermal conductivity
    μs(t)[1:N] # viscosity
    # flow device
    Q̇e(t)[1:N]
    Ff(t)[1:N-1]
    Fs_p(t)[1:N-1]
    Fs_fg(t)[1:N-1]
    # momemtum
    Ib_flows(t)[1:N-1]
    Is(t)[1:N-1]
    Δp(t)[1:N-1]
end


#         k
# |  |    |    |    |  |         mass/energy [ṁ, Ḣ]            N + 1
#      j   j+1
# -    -    -    -     -         property [m, ρ, v, h, p, A]    N
#         i
#    0    0    0    0            momentum [I, İ]               N - 1
#
# k = i + 1
# j = k - 1

semiLinear(m, a, b) = ifelse(m >= 0, a, b) * m
eqs = Equation[
               [D(ms[j]) ~ ṁs[j] - ṁs[j + 1] for j in 1:N]
               [Ib_flows[j] ~ (ρs[j] * vs[j]^2 * PA(grid, j)) -
                              (ρs[j + 1] * vs[j + 1]^2 * PA(grid, j + 1))
                for j in 1:N-1]
               [Fs_fg[j] ~ 0
                for j in 1:N-1]
               [Fs_p[j] ~ MA(grid, j) * (Ps[j + 1] - Ps[j])
                for j in 1:N-1]
               [D(Is[j]) ~ Ib_flows[j] - Fs_p[j] - Fs_fg[j]
                for j in 1:N-1]
               ḣs[1] ~ ifelse(ṁs[1] > 0 ? 0 : hs[1]) * ṁs[1]
               ḣs[N+1] ~ ifelse(ṁs[N+1] > 0 ? hs[N] : 0) * ṁs[N+1]
               [ḣs[j] ~ semiLinear(m_flows[j], hs[j-1], hs[j]) for j in 2:N]
               [ḣb[j] ~ ḣs[j] - ḣs[j + 1] for j in 1:N]
              ]
@named system = ODESystem(eqs)
