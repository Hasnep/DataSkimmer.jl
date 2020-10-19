module DataSkimmer

import Tables
using Statistics: mean, std, median
using PrettyTables: pretty_table, borderless, ft_round
using StructArrays
using IterTools: partition

include("helpers.jl")


export skim

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

"""
    function skim(data)::Skimmed

Skim a table.
"""
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
    numeric_columns =
        map(
            column_name -> begin
                n_missing = count(ismissing, Tables.getcolumn(data, column_name))
                return NumericColumn(
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
                )
            end,
            filter(n -> (Tables.columntype(data, n) <: Real), column_names),
        ) |> collect

    # Categorical columns
    categorical_columns =
        map(
            column_name -> begin
                n_missing = count(ismissing, Tables.getcolumn(data, column_name))
                return CategoricalColumn(
                    name = column_name,
                    type = Tables.columntype(data, column_name),
                    n_missing = n_missing,
                    completion_rate = 1 - (n_missing / n_rows),
                )
            end,
            filter(n -> !(Tables.columntype(data, n) <: Real), column_names),
        ) |> collect

    # Summary
    summary = Summary(
        n_rows = n_rows,
        n_columns = n_columns,
        n_numeric = length(numeric_columns),
        n_categorical = length(categorical_columns),
    )

    return Skimmed(summary, numeric_columns, categorical_columns)
end

function formatter_percent(data, percent_name)
    return (v, i, j) -> begin
        findfirst(n -> n == percent_name, Tables.columnnames(data)) == j ? "$(100 * v)%" : v
    end
end

function Base.show(io::IO, skimmed::Skimmed)
    # TODO: Use displaysize(stdout)[2] to abbreviate column headers when the table is too wide
    # Summary
    summary = skimmed.summary
    pretty_table(
        io,
        Dict(field_name => getfield(summary, field_name) for field_name in fieldnames(Summary));
        noheader = true,
        backend = :text,
        tf = borderless,
    )

    # Numeric
    if length(skimmed.numeric_columns) > 0
        numeric_table = StructArray(skimmed.numeric_columns)
        numeric_header = ["Name", "Type", "Missings", "Complete", "Mean", "Std.", "Min.", "Med.", "Max.", "Hist."]
        numeric_rounded = [:completion_rate, :mean, :standard_deviation, :minimum, :median, :maximum]
        numeric_formatters = (
            ft_round(2, findall(n -> n in numeric_rounded, Tables.columnnames(numeric_table))),
            formatter_percent(numeric_table, :completion_rate),
        )
        println(io, "")
        pretty_table(
            io,
            numeric_table,
            numeric_header;
            backend = :text,
            tf = borderless,
            formatters = numeric_formatters,
        )
    else
        println(io, "No numeric columns")
    end

    # Categorical
    if length(skimmed.categorical_columns) > 0
        categorical_table = StructArray(skimmed.categorical_columns)
        categorical_header = ["Name", "Type", "Missings", "Complete"]
        categorical_rounded = [:completion_rate]
        categorical_formatters = (
            ft_round(2, findall(n -> n in categorical_rounded, Tables.columnnames(categorical_table))),
            formatter_percent(categorical_table, :completion_rate),
        )
        println(io, "")
        pretty_table(
            io,
            categorical_table,
            categorical_header;
            backend = :text,
            tf = borderless,
            formatters = categorical_formatters,
        )
    else
        println(io, "No categorical columns")
    end
end


end
