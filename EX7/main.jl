include("./clustering.jl")

clustering(
    "building_data.csv",
    k=3,
    features=[:maht, :koetavPind, :ehitisalunePind, :maxKorrusteArv],
    print_results=true)
