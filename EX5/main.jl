
function transform_data_for_apriori(path)
    data = open(joinpath(pathname, filename)) do f
        JSON.parse(read(f, String))
    end
end

main()
    tshekid_path = ("../data/tshekid.csv")
    transform_data_for_apriori(tshekid_path)
