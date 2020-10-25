"""Count the number of rows of a table."""
function count_rows(data)::Integer
    if Tables.rowaccess(data)
        return length(Tables.rows(data))
    else
        @error "Can't count the number of rows"
    end
end

"""Count the number of columns of a table."""
function count_columns(data)::Integer
    data_schema = Tables.schema(data)
    if isnothing(data_schema)
        if Tables.columnaccess(data)
            return length(Tables.columns(data))
        else
            @error "Can't count the number of columns"
        end
    else
        return length(data_schema.names)
    end
end

"""Plots a histogram using unicode characters."""
function unicode_histogram(x::Vector{T}, n_bins::Integer) where {T <: Real}
    n_nonmissing_datapoints = count(!ismissing, x)
    if n_nonmissing_datapoints == 0
        return repeat(" ", n_bins)
    else
        x = skipmissing(x)
        min_value = minimum(x)
        max_value = maximum(x)
        bin_edges = range(min_value, length = n_bins + 1, stop = max_value)
        weights = [
            count(datapoint -> edge_lower < datapoint <= edge_upper, x)
            for (edge_lower, edge_upper) in partition(bin_edges, 2, 1)
        ]
        weights_normalised = weights ./ n_nonmissing_datapoints
        bars = [w == 0 ? ' ' : Char(0x2581 + floor(Int, w * 8)) for w in weights]
        return join(bars, "")
    end
end

function mylinspace(d1::Union{Dates.Date, Dates.DateTime}, d2::Union{Dates.Date, Dates.DateTime}, n::Integer)
    Δ = d2 - d1
    T = typeof(Δ)
    δ = T(round(Int, Dates.value(Δ) / (n - 1)))
    d2 = d1 + δ * (n - 1)
    return d1:δ:d2
end

"""Plot a histogram using unicode characters."""
function unicode_histogram(x::Vector{T}, n_bins)::String where {T <: Union{Dates.Date, Dates.DateTime}}
    n_nonmissing_datapoints = count(!ismissing, x)
    if n_nonmissing_datapoints == 0
        return repeat(" ", n_bins)
    else
        x = skipmissing(x)
        min_value = minimum(x)
        max_value = maximum(x)
        bin_edges = mylinspace(min_value, max_value, n_bins + 1)
        weights = [            count(datapoint -> edge_lower < datapoint <= edge_upper, x)            for (edge_lower, edge_upper) in partition(bin_edges, 2, 1)        ]
        weights_normalised = weights ./ n_nonmissing_datapoints
        bars = [w == 0 ? ' ' : Char(0x2581 + floor(Int, w * 8)) for w in weights]
        return join(bars, "")
    end
end
