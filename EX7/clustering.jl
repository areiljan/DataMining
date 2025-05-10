using CSV
using DataFrames: DataFrame
using Clustering: kmeans, hclust, cutree, dbscan
using Statistics: mean, std
using Distances: Euclidean, pairwise
using Plots: scatter, plot, savefig, @layout
using CategoricalArrays: categorical
using MultivariateStats
using ColorSchemes
using TSne: tsne
using StatsPlots
using GaussianMixtures: GMM, gmmposterior

function clustering(filepath::String;
    k::Int=3,
    features=[:ehr, :maht, :koetavPind, :ehitisalunePind, :maxKorrusteArv],
    id_column::Symbol=:ehr,
    print_results::Bool=true,
    plot_features=(:ehitisalunePind, :maht),
    output_file::String="clustering_result.png",
    clustering_method::Symbol=:hierarchical_clustering)

    valid_modes = [:pca, :tsne, :direct]

    data = CSV.read(filepath, DataFrame)
    println(data)

    feature_matrix = Matrix(data[:, features])

    # Normalize the data (z-score normalization)
    feature_means = mean(feature_matrix, dims=1)
    feature_stds = std(feature_matrix, dims=1)
    normalized_features = (feature_matrix .- feature_means) ./ feature_stds

    p_pca_kmeans = plot()
    p_pca_gmm = plot()
    p_pca_dbscan = plot()
    p_pca_hier = plot()


    # ---------- MAIN SCATTERS ----------
    pca_model = fit(PCA, normalized_features'; maxoutdim=2)
    pca_data = MultivariateStats.transform(pca_model, normalized_features')'

    palette = ColorSchemes.tableau_10.colors[1:k]

    # <-- k-means -->
    # Partitions the data into 𝑘 clusters by minimizing the total sum of squared distances to cluster centroids.
    # discrete
    try
        kmeans_res = kmeans(normalized_features', k)
        data.km_cluster_int = kmeans_res.assignments
        data.km_cluster = categorical(data.km_cluster_int)

        # t-SNE colored by kmeans clusters
        p_pca_kmeans = scatter(
            pca_data[:, 1], pca_data[:, 2];
            group=data.km_cluster_int,
            palette=palette,
            title="PCA: KMeans",
            legend=false, markersize=7
        )
    catch e
        print("kmeans failed $e")
    end

    # <-- Gaussian Mixtures -->
    # Models the data as a weighted sum of k Gaussians, then fits via Expectation–Maximization to allow soft assignment.
    # this is not discrete
    try
        gmm = GMM(4, normalized_features; method=:kmeans, kind=:full, nInit=50, nIter=20)
        resp, _ = gmmposterior(gmm, normalized_features)           # n×k matrix
        labels = [argmax(resp[i, :]) for i in 1:size(resp, 1)]
        data.gmm_cluster_int = labels
        data.gmm_cluster = categorical(labels)


        p_pca_gmm = scatter(
            pca_data[:, 1], pca_data[:, 2];
            group=data.gmm_cluster_int,
            palette=palette,
            title="PCA: Gaussian Mixtures",
            legend=false, markersize=7
        )
    catch e
        print("GMM failed $e")
    end

    # <-- Hierarchical clustering -->
    # discrete
    try
        hc = hclust(pairwise(Euclidean(), normalized_features, dims=1), linkage=:ward)
        clusters = cutree(hc, k=k)
        data.hier_cluster = clusters

        data.ClusterCategory = categorical(data.hier_cluster)

        p_pca_hier = scatter(
            pca_data[:, 1], pca_data[:, 2];
            group=data.hier_cluster,
            palette=palette,
            title="PCA: Hierarchical",
            legend=false, markersize=7
        )
    catch e
        print("hierarchical_clustering failed $e")
    end

    colors = ColorSchemes.tableau_10.colors[1:k]

    # <-- DBSCAN -->
    # Forms clusters by “growing” regions of high point density, marking low-density points as noise.
    # discrete
    try
        POINTS = normalized_features'
        db = dbscan(
            POINTS,
            0.5,
            min_neighbors=1,
            min_cluster_size=1,
            metric=Euclidean()
        )
        data.dbscan_cluster_int = db.assignments
        data.dbscan_cluster = categorical(db.assignments)

        p_pca_dbscan = scatter(
            pca_data[:, 1], pca_data[:, 2];
            group=data.dbscan_cluster_int,
            palette=palette,
            title="PCA: DBSCAN",
            legend=false, markersize=7
        )
        cluster_summary = Dict()
    catch e
        print("DBSCAN failed $e")
    end

    algos = Dict(
        "Hierarchical" => data.hier_cluster,
        "GMM" => data.gmm_cluster_int,
        "KMeans" => data.km_cluster_int,
        "DBSCAN" => data.dbscan_cluster_int,
    )

    println("Cluster memberships for k = $k\n")
    for (algo, labels) ∈ algos
        println("$algo Clustering:")
        for c ∈ 1:k
            members = data[labels.==c, id_column]
            size_c = length(members)
            means_c = Dict(f => round(mean(data[labels.==c, f]), digits=2) for f in features)

            header = " Cluster $c (n=$size_c) "
            width = max(length(header), 50)
            top = "╔" * repeat("═", width) * "╗"
            midsep = "╟" * repeat("─", width) * "╢"
            bottom = "╚" * repeat("═", width) * "╝"

            println(top)
            pad = (width - length(header)) ÷ 2
            println("║", " "^pad, header, " "^(width - length(header) - pad), "║")
            println(midsep)
            println("║ Buildings: ", rpad("", width - 12), "║")
            for id ∈ members
                idstr = string(id)
                println("║   • ", idstr, rpad("", width - 5 - length(idstr)), "║")
            end
            println(midsep)
            println("║ Stats:", rpad("", width - 7), "║")
            println("║   Size: $size_c", rpad("", width - 9 - length(string(size_c))), "║")
            for (f, m) ∈ means_c
                entry = "Mean $(f): $m"
                println("║   ", entry, rpad("", width - 3 - length(entry)), "║")
            end
            println(bottom, "\n")
        end
    end

    final_plot = plot(p_pca_gmm, p_pca_hier, p_pca_dbscan, p_pca_kmeans,
        layout=@layout([a; b; c; d]),
        size=(900, 1800),
        dpi=300)
    savefig(final_plot, output_file)
    println("Output plot saved -> $(output_file)")
end
