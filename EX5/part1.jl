function run_command(command)
    println("Running command: $(join(command, " "))")
    try
        output = read(`$(command)`, String)
        return output
    catch e
        println("Error running command: $e")
        return nothing
    end
end

function main()
    input_file = "transactions.txt"
    if !isfile(input_file)
        println("Error: Transactions file $(input_file) not found. Please run the Python script first.")
        return
    end

    # Generate association rules
    output_file1 = "shopping_association_rules.txt"
    association_rules_command = ["apriori", "-tr", "-c70", input_file, output_file1]
    run_command(association_rules_command)
    println("Association rules generated in: $(output_file1)")

    # Generate frequent itemsets: search for combinations of exactly 4 items with a minimum frequency of 3%
    output_file2 = "shopping_frequent_itemsets.txt"
    frequent_itemsets_command = ["apriori", "-m4", "-s3", input_file, output_file2]
    run_command(frequent_itemsets_command)
    println("Frequent itemsets generated in: $(output_file2)")

    println("\nYou can also run the commands manually:")
    println("apriori -tr $(input_file) $(output_file1)")
    println("apriori $(input_file) $(output_file2)")
end

main()
