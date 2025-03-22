using CSV
using DataFrames
using JSON
using Statistics

function normalize_coordinates(coords::Vector)
    isempty(coords) && return []

    x_values = first.(coords)
    y_values = last.(coords)

    x_min, x_max = extrema(x_values)
    y_min, y_max = extrema(y_values)

    normalized_coords = [
        (
            x_max ≠ x_min ? (x - x_min) / (x_max - x_min) : 0.0,
            y_max ≠ y_min ? (y - y_min) / (y_max - y_min) : 0.0
        )
        for (x, y) ∈ coords
    ]

    return normalized_coords
end


function calculate_point_distance(point1, point2)
    println("calculation")
    return √((point1[1] - point2[1])^2 + (point1[2] - point2[2])^2)
end


function directed_hausdorff_distance(coords1, coords2)
    max_min_dist = 0.0
    for point1 ∈ coords1
        min_dist = Inf
        for point2 ∈ coords2
            println(point1)
            println(point2)
            dist = calculate_point_distance(point1, point2)
            min_dist = min(min_dist, dist)
        end
        max_min_dist = max(max_min_dist, min_dist)
    end
    return max_min_dist
end


function create_comparison_matrix(coordinate_sets)
    n = length(coordinate_sets)
    building_ids = [string(coords[1]) for coords in coordinate_sets]

    println("\nCoordinates:")
    for (id, coords) in coordinate_sets
        println("Building $id: $(length(coords)) coordinates")
    end

    hausdorff_matrix = zeros(n, n)

    for i ∈ 1:n, j ∈ (i+1):n
        forward = directed_hausdorff_distance(coordinate_sets[i][2], coordinate_sets[j][2])
        backward = directed_hausdorff_distance(coordinate_sets[j][2], coordinate_sets[i][2])
        distance = max(forward, backward)
        hausdorff_matrix[i, j] = hausdorff_matrix[j, i] = distance
    end

    hausdorff_df = DataFrame(hausdorff_matrix, Symbol.(building_ids))
    rename!(hausdorff_df, Symbol.(building_ids))

    mkpath("results")

    CSV.write("results/similarity_matrix.csv", hausdorff_df)
    println("ran calculate_similarities")

    return hausdorff_df
end

function main()
    pathname = "../EX3/data"
    building_coordinates = []

    for filename ∈ readdir(pathname)
        println(filename)
        ehr_code = parse(Int, replace(filename, ".ehr.json" => ""))

        data = open(joinpath(pathname, filename)) do f
            JSON.parse(read(f, String))
        end

        coords_raw = try
            data[1]["ehitis"]["ehitiseKujud"]["ruumikuju"][1]["geometry"]["coordinates"][1]
        catch e
            println("Error accessing coordinates in $filename: $e")
            []
        end

        println("Raw coordinates: ", coords_raw)

        coords_typed = [(Float64(point[1]), Float64(point[2])) for point in coords_raw]
        coordinates = (ehr_code, normalize_coordinates(coords_typed))
        push!(building_coordinates, coordinates)
    end

    similarity_matrix = create_comparison_matrix(building_coordinates)
end

main()
