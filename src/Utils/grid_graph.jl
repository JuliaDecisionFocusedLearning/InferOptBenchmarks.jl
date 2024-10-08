"""
$TYPEDSIGNATURES

Compute the number of edges in a grid graph of size `(h, w)`.
"""
function count_edges(h::Integer, w::Integer; acyclic::Bool)
    @assert h >= 2 && w >= 2
    if acyclic
        return (h - 1) * (w - 1) * 3 + ((h - 1) + (w - 1)) * 1 + 0
    else
        return (h - 2) * (w - 2) * 8 + (2(h - 2) + 2(w - 2)) * 5 + 4 * 3
    end
end

# function possible_neighbors(i::Integer, j::Integer)
#     return (
#         # col - 1
#         (i - 1, j - 1),
#         (i + 0, j - 1),
#         (i + 1, j - 1),
#         # col 0
#         (i - 1, j + 0),
#         (i + 1, j + 0),
#         # col + 1
#         (i - 1, j + 1),
#         (i + 0, j + 1),
#         (i + 1, j + 1),
#     )
# end

"""
$TYPEDSIGNATURES

Given a pair of row-column coordinates `(i, j)` on a grid of size `(h, w)`, compute the corresponding vertex index in the graph generated by [`grid_graph`](@ref).
"""
function coord_to_index(i::Integer, j::Integer, h::Integer, w::Integer)
    if (1 <= i <= h) && (1 <= j <= w)
        v = (j - 1) * h + (i - 1) + 1  # enumerate column by column
        return v
    else
        return 0
    end
end

"""
$TYPEDSIGNATURES

Given a vertex index in the graph generated by [`grid_graph`](@ref), compute the corresponding row-column coordinates `(i, j)` on a grid of size `(h, w)`.
"""
function index_to_coord(v::Integer, h::Integer, w::Integer)
    if 1 <= v <= h * w
        j = (v - 1) ÷ h + 1
        i = (v - 1) - h * (j - 1) + 1
        return (i, j)
    else
        return (0, 0)
    end
end

"""
$TYPEDSIGNATURES

Retrieve a path from the `parents` array and start `s`` and end `d`` of path.
"""
function get_path(parents::AbstractVector{<:Integer}, s::Integer, d::Integer)
    path = [d]
    v = d
    while v != s
        v = parents[v]
        pushfirst!(path, v)
    end
    return path
end

"""
$TYPEDSIGNATURES

Transform `path` into a binary matrix of size `(h, w)` where each cell is 1 if the cell is part of the path, 0 otherwise.
"""
function path_to_matrix(path::Vector{<:Integer}, h::Integer, w::Integer)
    y = zeros(Int, h, w)
    for v in path
        i, j = index_to_coord(v, h, w)
        y[i, j] += 1
    end
    return y
end

"""
$TYPEDSIGNATURES

Convert a grid of cell costs into a weighted directed graph from [SimpleWeightedGraphs.jl](https://github.com/JuliaGraphs/SimpleWeightedGraphs.jl), where the vertices correspond to the cells and the edges are weighted by the cost of the arrival cell.

- If `acyclic = false`, a cell has edges to each one of its 8 neighbors.
- If `acyclic = true`, a cell has edges to its south, east and southeast neighbors only (ensures an acyclic graph where topological sort will work)

This can be used to model the Warcraft shortest paths problem of
> [Differentiation of Blackbox Combinatorial Solvers](https://openreview.net/forum?id=BkevoJSYPB), Vlastelica et al. (2019)
"""
function grid_graph(costs::AbstractMatrix{R}; acyclic::Bool=false) where {R}
    h, w = size(costs)
    V = h * w
    E = count_edges(h, w; acyclic)

    sources = Int[]
    destinations = Int[]
    weights = R[]

    sizehint!(sources, E)
    sizehint!(destinations, E)
    sizehint!(weights, E)

    for v1 in 1:V
        i1, j1 = index_to_coord(v1, h, w)
        for Δi in (-1, 0, 1), Δj in (-1, 0, 1)
            i2, j2 = i1 + Δi, j1 + Δj
            valid_destination = 1 <= i2 <= h && 1 <= j2 <= w
            valid_step = if acyclic
                (Δi != 0 || Δj != 0) && Δi >= 0 && Δj >= 0
            else
                (Δi != 0 || Δj != 0)
            end
            if valid_destination && valid_step
                v2 = coord_to_index(i2, j2, h, w)
                push!(sources, v1)
                push!(destinations, v2)
                push!(weights, costs[v2])
            end
        end
    end

    return SimpleWeightedDiGraph(sources, destinations, weights)
end
