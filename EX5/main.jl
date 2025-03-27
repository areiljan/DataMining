using XLSX
using PyCall


# import pyfim package (install using install.sh), set up in julia Pkg
pyfim = pyimport("fim")

function open_xlsx(path::String)
    println("Reading Excel file $path")
    transactions = []

    xf = XLSX.readxlsx(path)
    sheet = xf[1]

    for row in XLSX.eachtablerow(sheet)
        values = []

        for value in row
            if value !== nothing && value !== ""
                push!(values, string(value))
            end
        end

        if !isempty(values)
            push!(transactions, values)
        end
    end

    return transactions

end


function create_client_items_dict(transactions)
    client_items = Dict{String,Vector{String}}()
    current_client_id = 1
    last_number = nothing

    for transaction in transactions
        number = transaction[1]
        item = transaction[2]

        if last_number !== nothing && number != last_number
            current_client_id += 1
        end

        unique_client = string(current_client_id)

        if !haskey(client_items, unique_client)
            client_items[unique_client] = String[]
        end

        if !(item in client_items[unique_client])
            push!(client_items[unique_client], item)
        end

        last_number = number
    end

    return client_items
end


function main()
    tshekid_path = "data/tshekid_office2003.xlsx"

    transactions = open_xlsx(tshekid_path)
    client_items = create_client_items_dict(transactions)

    println("Total unique clients: ", length(client_items))
    println("\nFirst few clients:")
    for (i, (client, items)) in enumerate(collect(client_items)[1:min(5, end)])
        println("Client $client: $items")
    end

    # Try importing
    fim = pyimport("fim")
    if fim !== empty
        println("import successful")
    end

    transactions = [
        [1, 2, 3],
        [1, 2],
        [2, 3],
        [1, 3]
    ]

    result = fim.Experiment(tshekid_path)  # 40% support threshold

    # Print the results
    println("Frequent Itemsets:")
    for itemset in result
        println(itemset)
    end
end

main()
