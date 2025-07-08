include("plot_graph.jl")
using Makie.Colors 
using Random
using StatsBase
using Colors

mutable struct NodeInfo
    label::Int
    neighbors::Vector{Int}
end

# I copied this label propagation section direct from the provided code in mini01.jl

function label_propagation(g, node_info)
    label_changed = true
    while label_changed
        label_changed = false
        shuffled_nodes = shuffle(1:nv(g))
        for n in shuffled_nodes
            neighbor_labels = [node_info[j].label for j in node_info[n].neighbors]
            most_common = findmax(countmap(neighbor_labels))[2]
            if node_info[n].label != most_common
                node_info[n].label = most_common
                label_changed = true
            end
        end
    end
end

# Now i will define my scoring function
# I commonly refer to the has_edge defined as has_edge(graph, src_node, dest_node)

function score_function(g, communities)
    t = length(communities)
    total_score = 0.0

    for (i, community) in enumerate(communities)
        println("\nGroup $i: ", community)

        internal_edges = Set{Tuple{Int, Int}}()
        for i in 1:length(community), j in (i+1):length(community)
            u, v = community[i], community[j]
            if has_edge(g, u, v)
                push!(internal_edges, (min(u, v), max(u, v)))
            end
        end
        println("  Internal edges: ", collect(internal_edges))

        max_internal = length(community) * (length(community) - 1) / 2

        external_edges = Set{Tuple{Int, Int}}()
        for u in community
            for v in neighbors(g, u)
                if v ∉ community
                    push!(external_edges, (min(u, v), max(u, v)))
                end
            end
        end
        println("  External edges: ", collect(external_edges))

        external_possible = length(community) * (nv(g) - length(community))
        internal_ratio = max_internal == 0 ? 0.0 : length(internal_edges) / max_internal
        external_ratio = external_possible == 0 ? 0.0 : length(external_edges) / external_possible
#finally here i intergrate the internal calc and external calc together to my scoring formula excluding deviding it by the total goups t
        group_score = internal_ratio * (1 - external_ratio)
        println("  Group score: ", round(group_score, digits=3))

        total_score += group_score
    end

    final_score = total_score / t
    println("\nScore: ", round(final_score, digits=3))
    return final_score
end

function main(filename = "graph08.txt")
    edge_list = read_edges(filename)
    g = build_graph(edge_list)

    # Build a dictionary mapping node indices to the node's info
    node_info = Dict{Int, NodeInfo}()
    for n in 1:nv(g)
        node_info[n] = NodeInfo(n, collect(neighbors(g, n)))
    end
    
    label_propagation(g, node_info)

    labels = [(node, info.label) for (node, info) in node_info]
    label_groups = Dict{Int, Vector{Int}}()
    for (node, label) in labels
        push!(get!(label_groups, label, Int[]), node)
    end
    groups = collect(values(label_groups))

    score = score_function(g, groups)
    println("Detected groups: ", groups)
    println("Community score: ", score)

    # I copied this below section direct from the provided code in mini01.jl
    palette_size = 16
    color_palette = Makie.distinguishable_colors(palette_size)

    unique_labels = unique([node.label for node in values(node_info)])
    sort!(unique_labels)  # Optional: for consistent color assignment
    label_to_color_index = Dict(unique_labels[i] => mod1(i, palette_size) for i in eachindex(unique_labels))
    node_color_indices = [label_to_color_index[node_info[n].label] for n in 1:nv(g)]
    node_colors = [color_palette[i] for i in node_color_indices]
    node_text_colors = [Colors.Lab(RGB(c)).l > 50 ? :black : :white for c in node_colors]

    interactive_plot_graph(g, node_colors, node_text_colors, node_color_indices, color_palette)
end

main()