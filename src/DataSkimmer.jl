module DataSkimmer

import Tables
using StatsBase: Histogram, fit
using Statistics: mean, std, median
using PrettyTables: pretty_table, borderless, ft_round
using StructArrays

export skim

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

Base.@kwdef struct Summary
    n_rows::Integer
    n_columns::Integer
    n_numeric::Integer
    n_categorical::Integer
end

Base.@kwdef struct NumericColumn
    name::Symbol
    type::DataType
    n_missing::Integer
    completion_rate::Real
    mean::Real
    standard_deviation::Real
    minimum::Real
    median::Real
    maximum::Real
    histogram::String
end

Base.@kwdef struct CategoricalColumn
    name::Symbol
    type::DataType
    n_missing::Integer
    completion_rate::Real
end

struct Skimmed
    summary::Summary
    numeric_columns::Vector{NumericColumn}
    categorical_columns::Vector{CategoricalColumn}
end

get_n_missing(data, column_name) = count(ismissing, Tables.getcolumn(data, column_name))

function skim(data)::Skimmed
    @assert Tables.istable(data) "Input must be a table"

    n_rows = count_rows(data)
    n_columns = count_columns(data)

    data_schema = Tables.schema(data)
    if isnothing(data_schema)
        column_names = Tables.columnnames(categorical_table)
        column_types = missing
        @error "Can't get column types"
    else
        column_names = data_schema.names
        column_types = data_schema.types
    end

    # Numeric columns
    numeric_column_names = filter(n -> (Tables.columntype(data, n) <: Real), column_names)
    numeric_columns = []
    for column_name in numeric_column_names
        n_missing::Real = get_n_missing(data, column_name)
        push!(
            numeric_columns,
            NumericColumn(
                name = column_name,
                type = Tables.columntype(data, column_name),
                n_missing = n_missing,
                completion_rate = 1 - (n_missing / n_rows),
                mean = mean(Tables.getcolumn(data, column_name)),
                standard_deviation = std(Tables.getcolumn(data, column_name)),
                minimum = minimum(Tables.getcolumn(data, column_name)),
                median = median(Tables.getcolumn(data, column_name)),
                maximum = maximum(Tables.getcolumn(data, column_name)),
                histogram = unicode_histogram(Tables.getcolumn(data, column_name), 5),
            ),
        )
    end

    # Categorical columns
    categorical_column_names =
        filter(n -> !(Tables.columntype(data, n) <: Real), column_names)
    categorical_columns = []
    for column_name in categorical_column_names
        n_missing = get_n_missing(data, column_name)
        push!(
            categorical_columns,
            CategoricalColumn(
                name = column_name,
                type = Tables.columntype(data, column_name),
                n_missing = n_missing,
                completion_rate = 1 - (n_missing / n_rows),
            ),
        )
    end

    # Summary
    summary = Summary(
        n_rows = n_rows,
        n_columns = n_columns,
        n_numeric = length(numeric_column_names),
        n_categorical = length(categorical_column_names),
    )

    return Skimmed(summary, numeric_columns, categorical_columns)
end

function formater_percent(data, percent_name)
    return (v, i, j) -> begin
        findfirst(n -> n == percent_name, Tables.columnnames(data)) == j ?
            "$(100 * v)%" : v
    end
end

function Base.show(io::IO, skimmed::Skimmed)
    # Summary
    println("data")
    summary = skimmed.summary
    pretty_table(
        io,
        Dict(field_name => getfield(summary, field_name) for field_name ∈ fieldnames(Summary));
        backend = :text,
        # tf = borderless
    )

    # println(io, "n_rows: $(skimmed.summary.n_rows)")
    # println(io, "n_columns: $(skimmed.summary.n_columns)")
    # println(io, "n_numeric: $(skimmed.summary.n_numeric)")
    # println(io, "n_categorical: $(skimmed.summary.n_categorical)")
    # TODO: Use displaysize(stdout)[2] to abbreviate column headers when the table is too wide
    # Numeric table
    if length(skimmed.numeric_columns) > 0
        numeric_table = StructArray(skimmed.numeric_columns)
        numeric_header = [
            "Name",
            "Type",
            "Missings",
            "Complete",
            "Mean",
            "Std.",
            "Min.",
            "Med.",
            "Max.",
            "Hist.",
        ]
        numeric_rounded =
            [:completion_rate, :mean, :standard_deviation, :minimum, :median, :maximum]
        numeric_formatters = (
            ft_round(
                2,
                findall(n -> n in numeric_rounded, Tables.columnnames(numeric_table)),
            ),
            formater_percent(numeric_table, :completion_rate),
        )
        pretty_table(
            io,
            numeric_table,
            numeric_header;
            backend = :text,
            # tf = borderless,
            formatters = numeric_formatters,
        )
    else
        println("No numeric columns")
    end
    # Categorical
    if length(skimmed.categorical_columns) > 0
        categorical_table = StructArray(skimmed.categorical_columns)
        categorical_header = ["Name", "Type", "Missings", "Complete"]
        categorical_rounded = [:completion_rate]
        categorical_formatters = (
            ft_round(
                2,
                findall(
                    n -> n in categorical_rounded,
                    Tables.columnnames(categorical_table),
                ),
            ),
            formater_percent(categorical_table, :completion_rate),
        )
        pretty_table(
            io,
            categorical_table,
            categorical_header;
            backend = :text,
            # tf = borderless,
            formatters = categorical_formatters,
        )
    else
        println("No categorical columns")
    end
end

"""Plots a histogram using unicode characters."""
function unicode_histogram(x::Vector{T}, n_bins::Integer) where {T<:Real}
    data_min = minimum(x)
    bin_width = (maximum(x) - data_min) / n_bins
    bin_edges = [data_min + i * bin_width for i = 0:n_bins]
    weights = [length(x[bin_edges[i].<x.<=bin_edges[i+1]]) for i = 1:n_bins] ./ length(x)
    output = [b == 0 ? ' ' : Char(0x2581 + floor(Int, b * 8)) for b in weights]
    return join(output, "")
end

end
