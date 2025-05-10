include("./clustering.jl")

for i in 2:4
    clustering(
        "building_data.csv",
        k=i,
        features=[:maht, :koetavPind, :ehitisalunePind, :maxKorrusteArv],
        print_results=true,
        output_file="k$(i).png")
end
