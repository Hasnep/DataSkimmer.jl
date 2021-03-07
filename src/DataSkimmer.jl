module DataSkimmer

import Tables
using Statistics: mean, std, median
using PrettyTables: pretty_table, tf_borderless, ft_round, Crayon, hl_col
using StructArrays
using IterTools: partition
import Dates

include("helpers.jl")
include("histogram.jl")

export skim

struct Summary
    type::Type
    n_rows::Int64
    n_columns::Int64
    n_numeric::Int64
    n_categorical::Int64
    n_datetime::Int64
end

struct NumericColumn
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

    function NumericColumn(data, column_name)
        column = Tables.getcolumn(data, column_name)
        n_missing = count(ismissing, column)
        return new(
            column_name,
            Tables.columntype(data, column_name),
            n_missing,
            1 - (n_missing / count_rows(data)),
            mean(column),
            std(column),
            minimum(column),
            median(column),
            maximum(column),
            unicode_histogram(column, 5),
        )
    end
end

struct CategoricalColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64

    function CategoricalColumn(data, column_name)
        n_missing = count(ismissing, Tables.getcolumn(data, column_name))
        return new(
            column_name,
            Tables.columntype(data, column_name),
            n_missing,
            1 - (n_missing / count_rows(data)),
        )
    end
end

struct DateTimeColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64
    minimum::Union{Dates.Date, Dates.DateTime}
    maximum::Union{Dates.Date, Dates.DateTime}
    histogram::String

    function DateTimeColumn(data, column_name)
        column = Tables.getcolumn(data, column_name)
        n_missing = count(ismissing, column)
        return new(
            column_name,
            Tables.columntype(data, column_name),
            n_missing,
            1 - (n_missing / count_rows(data)),
            minimum(column),
            maximum(column),
            unicode_histogram(column, 5),
        )
    end
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
    numeric_column_names = filter(
        column_name -> is_numeric(Tables.columntype(data, column_name)),
        column_names,
    )
    numeric_columns =
        collect(map(column_name -> NumericColumn(data, column_name), numeric_column_names))

    # Categorical columns
    categorical_column_names = filter(
        column_name -> is_categorical(Tables.columntype(data, column_name)),
        column_names,
    )
    categorical_columns = collect(
        map(column_name -> CategoricalColumn(data, column_name), categorical_column_names),
    )

    # DateTime columns
    datetime_column_names = filter(
        column_name -> is_datetime(Tables.columntype(data, column_name)),
        column_names,
    )
    datetime_columns = collect(
        map(column_name -> DateTimeColumn(data, column_name), datetime_column_names),
    )

    # Summary
    summary = Summary(
        typeof(data),
        count_rows(data),
        count_columns(data),
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

plural(n) = n == 1 ? "" : "s"

function plural() end

function Base.show(io::IO, skimmed::Skimmed)
    # TODO: Use displaysize(stdout)[2] to abbreviate column headers when the table is too wide
    # Summary
    summary = skimmed.summary
    summary_table = [
        "Type" summary.type
        "N. rows" summary.n_rows
        "N. cols" summary.n_columns
        "N. numeric cols" summary.n_numeric
        "N. categorical cols" summary.n_categorical
        "N. datetime cols" summary.n_datetime
    ]
    pretty_table(
        io,
        summary_table;
        noheader = true,
        backend = :text,
        highlighters = (hl_col(1, Crayon(bold = true))),
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
        println(io, "$(summary.n_numeric) numeric column$(plural(summary.n_numeric))")
        pretty_table(
            io,
            numeric_table,
            numeric_header;
            backend = :text,
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
        println(
            io,
            "$(summary.n_categorical) categorical column$(plural(summary.n_categorical))",
        )
        pretty_table(
            io,
            categorical_table,
            categorical_header;
            backend = :text,
            formatters = categorical_formatters,
        )
    else
        println(io, "No categorical columns")
    end

    # DateTime
    println(io, "")
    if length(skimmed.datetime_columns) > 0
        datetime_table = StructArray(skimmed.datetime_columns)
        datetime_header = ["Name", "Type", "Missings", "Complete", "Min.", "Max.", "Hist."]
        datetime_rounded = [:completion_rate]
        datetime_formatters = (
            ft_round(
                2,
                findall(n -> n in datetime_rounded, Tables.columnnames(datetime_table)),
            ),
            formatter_percent(datetime_table, :completion_rate),
        )
        println(io, "$(summary.n_datetime) datetime column$(plural(summary.n_datetime))")
        pretty_table(
            io,
            datetime_table,
            datetime_header;
            backend = :text,
            formatters = datetime_formatters,
        )
    else
        println(io, "No datetime columns")
    end
end

end
