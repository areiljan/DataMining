using CSV, DataFrames, Printf, Statistics
# these are all native .jl packages, dataframes is identical to the one in python

CSV_FILE = "data/bank-data.csv"
OUTPUT_FIMI_FILE = "input2.txt"
COLUMNS_TO_REMOVE = ["id"]
NUMERIC_TO_DISCRETIZE = ["age", "income"]
N_BINS = 5

df = CSV.read(CSV_FILE, DataFrame)
# select! modifies a df in place, NOT() removes columns
select!(df, Not(COLUMNS_TO_REMOVE))

for col ∈ NUMERIC_TO_DISCRETIZE
    # get min and max values
    mn, mx = minimum(df[!, col]), maximum(df[!, col])
    edges = collect(range(mn, mx, length=N_BINS+1))
    # lambda function assignment
    discretize_val(x) = begin
        for i ∈ 1:(length(edges)-1)
            if (i < length(edges)-1 && x ≥ edges[i] && x < edges[i+1]) ||
                (i == length(edges)-1 && x ≥ edges[i] && x ≤ edges[i+1])
                return @sprintf("%s_%.1f_%.1f", col, edges[i], edges[i+1])
            end
        end
        ""
    end
    df[!, col] = [discretize_val(x) for x ∈ df[!, col]]
end

transactions = [ [ (col ∈ NUMERIC_TO_DISCRETIZE ? string(row[col]) :
    string(col, "_", row[col])) for col ∈ names(df) if !ismissing(row[col]) ]
for row ∈ eachrow(df) ]

open(OUTPUT_FIMI_FILE, "w") do io
    for trans ∈ transactions
        println(io, join(trans, " "))
    end
end
