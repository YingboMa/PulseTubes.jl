using PulseTubes
using Documenter

DocMeta.setdocmeta!(PulseTubes, :DocTestSetup, :(using PulseTubes); recursive=true)

makedocs(;
    modules=[PulseTubes],
    authors="Yingbo Ma <mayingbo5@gmail.com> and contributors",
    repo="https://github.com/YingboMa/PulseTubes.jl/blob/{commit}{path}#{line}",
    sitename="PulseTubes.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://YingboMa.github.io/PulseTubes.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/YingboMa/PulseTubes.jl",
    devbranch="master",
)
