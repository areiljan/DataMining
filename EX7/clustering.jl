using CSV
using DataFrames
using Clustering
using Statistics
using StatsBase
using Distances
using Plots
using CategoricalArrays
using MultivariateStats
using StatsPlots
using ColorSchemes
using TSne
using GaussianMixtures
using Distributions



function clustering(filepath::String;
    k::Int=3,
    features=[:ehr, :maht, :koetavPind, :ehitisalunePind, :maxKorrusteArv],
    id_column::Symbol=:ehr,
    print_results::Bool=true,
    plot_features=(:ehitisalunePind, :maht),
    output_file::String = "clustering_result.png",
    clustering_method::Symbol=:hierarchical_clustering)

    valid_modes = [:pca, :tsne, :direct]

    data = CSV.read(filepath, DataFrame)
    println(data)

    feature_matrix = Matrix(data[:, features])

    # Normalize the data (z-score normalization)
    feature_means = mean(feature_matrix, dims=1)
    feature_stds = std(feature_matrix, dims=1)
    normalized_features = (feature_matrix .- feature_means) ./ feature_stds

    # <-- k-means -->
    kmeans_res = kmeans(normalized_features', k)
    data.km_cluster_int = kmeans_res.assignments
    data.km_cluster = categorical(data.km_cluster_int)

    # <-- Gaussian Mixtures -->
    gmm = GMM(4, normalized_features; method = :kmeans, kind = :full, nInit = 50, nIter = 20)
    resp, _ = gmmposterior(gmm, normalized_features)           # n×k matrix
    labels = [argmax(resp[i, :]) for i in 1:size(resp, 1)]
    data.gmm_cluster_int = labels
    data.gmm_cluster = categorical(labels)

    # <-- Hierarchical clustering -->
    hc = hclust(pairwise(Euclidean(), normalized_features, dims=1), linkage=:ward)
    clusters = cutree(hc, k=k)
    data.hier_cluster = clusters

    data.ClusterCategory = categorical(data.hier_cluster)
    colors = ColorSchemes.tableau_10.colors[1:k]

    cluster_summary = Dict()

    algos = Dict(
      "Hierarchical" => data.hier_cluster,
      "GMM"          => data.gmm_cluster_int,
      "KMeans"       => data.km_cluster_int
    )

    println("Cluster memberships for k = $k\n")
    for (algo, labels) in algos
        println("▶ $algo Clustering:")
        for c in 1:k
            members = data[labels .== c, id_column]
            size_c  = length(members)
            means_c = Dict(f => round(mean(data[labels .== c, f]), digits=2) for f in features)

            header = " Cluster $c (n=$size_c) "
            width  = max(length(header), 50)
            top    = "╔" * repeat("═", width) * "╗"
            midsep = "╟" * repeat("─", width) * "╢"
            bottom = "╚" * repeat("═", width) * "╝"

            println(top)
            pad = (width - length(header)) ÷ 2
            println("║", " "^pad, header, " "^ (width - length(header) - pad), "║")
            println(midsep)
            println("║ Buildings: ", rpad("", width - 12), "║")
            for id in members
                idstr = string(id)
                println("║   • ", idstr, rpad("", width - 5 - length(idstr)), "║")
            end
            println(midsep)
            println("║ Stats:", rpad("", width - 7),       "║")
            println("║   Size: $size_c", rpad("", width - 9 - length(string(size_c))), "║")
            for (f, m) in means_c
                entry = "Mean $(f): $m"
                println("║   ", entry, rpad("", width - 3 - length(entry)), "║")
            end
            println(bottom, "\n")
        end
    end

    p_main = nothing

    # ---------- MAIN SCATTERS ----------
    # (a) PCA - this will show how the data spreads --------------------------
    pca_model  = fit(PCA, normalized_features' ; maxoutdim = 2)
    pca_data   = MultivariateStats.transform(pca_model, normalized_features')'
    p_pca = scatter(pca_data[:,1], pca_data[:,2];
                    group = data.ClusterCategory, title = "PCA",
                    xlabel = "PC1", ylabel = "PC2", seriescolor = colors,
                    legend = false, markersize = 7)

    # (b) TSNE - this will show how the clusters group together --------------
    tsne_coords = tsne(normalized_features, 2, 5, 1000, 0.5)

    # t-SNE colored by hierarchical clusters
    p_tsne_hier = scatter(
        tsne_coords[:,1], tsne_coords[:,2];
        group = data.hier_cluster,
        title = "t-SNE: Hierarchical",
        xlabel = "Dim 1", ylabel = "Dim 2",
        seriescolor = colors,
        legend = false, markersize = 7
    )

    # t-SNE colored by GMM clusters
    p_tsne_gmm = scatter(
        tsne_coords[:,1], tsne_coords[:,2];
        group = data.gmm_cluster,
        title = "t-SNE: GMM",
        xlabel = "Dim 1", ylabel = "Dim 2",
        seriescolor = colors,
        legend = false, markersize = 7
    )

    # Dendrogram visualization
    p_dendro = plot(
        hc,
        xticks=false,
        title="Hierarchical clustering Dendrogram",
        xlabel="Buildings",
        ylabel="Distance",
        linewidth=1.5,
        size=(800, 400),
        dpi=300
    )

    final_plot = plot(p_pca, p_tsne_gmm, p_tsne_hier, p_dendro,
        layout = @layout([a; b; c; d]),
        size=(900, 1800),
        dpi=300)
    savefig(final_plot, output_file)
    println("Output plot saved -> $(output_file)")
end
