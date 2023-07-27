using PulseTubes, ModelingToolkit, OrdinaryDiffEq, Test

@named prop = BaseProperties(Nitrogen)
prop = complete(prop)
sys = structural_simplify(prop, ((prop.T, prop.P), ()))[1];
prob = ODEProblem(sys, [], (0, 1.0), [prop.T => 100, prop.P => 200e3])
sol = solve(prob, Rodas5P())

@test sol[prop.k, 1] * 1000 ≈ 9.5 atol = 1e-3
