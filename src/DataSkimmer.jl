module DataSkimmer

import Tables
using Statistics: mean, std, median
using PrettyTables: pretty_table, tf_borderless, ft_round
using StructArrays
using IterTools: partition
import Dates

include("helpers.jl")
include("histogram.jl")

export skim

struct Summary
    n_rows::Int64
    n_columns::Int64
    n_numeric::Int64
    n_categorical::Int64
    n_datetime::Int64
end

Base.@kwdef struct NumericColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64
    mean::Float64
    standard_deviation::Float64
    minimum::Float64
    median::Float64
    maximum::Float64
    histogram::String
end

Base.@kwdef struct CategoricalColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64
end

Base.@kwdef struct DateTimeColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64
    minimum::Union{Dates.Date, Dates.DateTime}
    maximum::Union{Dates.Date, Dates.DateTime}
    histogram::String
end

struct Skimmed
    summary::Summary
    numeric_columns::Vector{NumericColumn}
    categorical_columns::Vector{CategoricalColumn}
    datetime_columns::Vector{DateTimeColumn}
end

"""
    function skim(data)::Skimmed

Skim any Tables.jl compatible table.
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
    numeric_column_names = filter(n -> Tables.columntype(data, n) <: Real, column_names)
    numeric_columns =
        map(
            column_name -> begin
                column = Tables.getcolumn(data, column_name)
                n_missing = count(ismissing, column)
                return NumericColumn(
                    name = column_name,
                    type = Tables.columntype(data, column_name),
                    n_missing = n_missing,
                    completion_rate = 1 - (n_missing / n_rows),
                    mean = mean(column),
                    standard_deviation = std(column),
                    minimum = minimum(column),
                    median = median(column),
                    maximum = maximum(column),
                    histogram = unicode_histogram(column, 5),
                )
            end,
            numeric_column_names,
        ) |> collect

    # Categorical columns
    categorical_column_names =
        filter(n -> is_categorical(Tables.columntype(data, n)), column_names)
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
            categorical_column_names,
        ) |> collect

    # Datetime columns
    datetime_column_names =
        filter(n -> is_datetime(Tables.columntype(data, n)), column_names)
    datetime_columns =
        map(
            column_name -> begin
                column = Tables.getcolumn(data, column_name)
                n_missing = count(ismissing, column)
                return DateTimeColumn(
                    name = column_name,
                    type = Tables.columntype(data, column_name),
                    n_missing = n_missing,
                    completion_rate = 1 - (n_missing / n_rows),
                    minimum = minimum(column),
                    maximum = maximum(column),
                    histogram = unicode_histogram(column, 5),
                )
            end,
            datetime_column_names,
        ) |> collect

    # Summary
    summary = Summary(
        n_rows,
        n_columns,
        length(numeric_columns),
        length(categorical_columns),
        length(datetime_columns),
    )

    return Skimmed(summary, numeric_columns, categorical_columns, datetime_columns)
end

function formatter_percent(data, percent_name)
    return (v, i, j) -> begin
        if findfirst(n -> n == percent_name, Tables.columnnames(data)) == j
            "$(100 * v)%"
        else
            v
        end
    end
end

function Base.show(io::IO, skimmed::Skimmed)
    # TODO: Use displaysize(stdout)[2] to abbreviate column headers when the table is too wide
    # Summary
    summary = skimmed.summary
    pretty_table(
        io,
        Dict(
            field_name => getfield(summary, field_name) for
            field_name in fieldnames(Summary)
        );
        noheader = true,
        backend = :text,
        tf = tf_borderless,
    )

    println(io, "")
    # Numeric
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
            formatter_percent(numeric_table, :completion_rate),
        )
        println(io, "Numeric columns")
        pretty_table(
            io,
            numeric_table,
            numeric_header;
            backend = :text,
            tf = tf_borderless,
            formatters = numeric_formatters,
        )
    else
        println(io, "No numeric columns")
    end

    # Categorical
    println(io, "")
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
            formatter_percent(categorical_table, :completion_rate),
        )
        println(io, "Categorical columns")
        pretty_table(
            io,
            categorical_table,
            categorical_header;
            backend = :text,
            tf = tf_borderless,
            formatters = categorical_formatters,
        )
    else
        println(io, "No categorical columns")
    end

    # Datetime
    println(io, "")
    if length(skimmed.datetime_columns) > 0
        datetime_table = StructArray(skimmed.datetime_columns)
        datetime_header = ["Name", "Type", "Missings", "Complete", "Min", "Max", "Hist."]
        datetime_rounded = [:completion_rate]
        datetime_formatters = (
            ft_round(
                2,
                findall(n -> n in datetime_rounded, Tables.columnnames(datetime_table)),
            ),
            formatter_percent(datetime_table, :completion_rate),
        )
        println(io, "Datetime columns")
        pretty_table(
            io,
            datetime_table,
            datetime_header;
            backend = :text,
            tf = tf_borderless,
            formatters = datetime_formatters,
        )
    else
        println(io, "No datetime columns")
    end
end

end
