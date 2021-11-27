module DataSkimmer

import Tables
using Statistics: mean, std, median
using PrettyTables: Crayon, ft_printf, hl_col, pretty_table
using StructArrays: StructArray
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
    n_allmissing::Int64
end

struct NumericColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64
    mean::Union{Float64, Missing}
    standard_deviation::Union{Float64, Missing}
    minimum::Union{Float64, Missing}
    median::Union{Float64, Missing}
    maximum::Union{Float64, Missing}
    histogram::String

    function NumericColumn(data, column_name)
        column = Tables.getcolumn(data, column_name)
        type = Tables.columntype(data, column_name)
        n_missing = count(ismissing, column)
        n_rows = count_rows(data)
        completion_rate = 1 - (n_missing / n_rows)
        # Check if all rows are missing
        if n_missing == n_rows
            aggregated = repeat([missing], 5)
        else
            column = skipmissing(column)
            aggregated = [f(column) for f in [mean, std, minimum, median, maximum]]
        end
        histogram = unicode_histogram(column, 5)
        return new(column_name, type, n_missing, completion_rate, aggregated..., histogram)
    end
end

struct CategoricalColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64
    n_unique::Int64

    function CategoricalColumn(data, column_name)
        n_missing = count(ismissing, Tables.getcolumn(data, column_name))
        n_unique = length(unique(skipmissing(Tables.getcolumn(data, column_name))))
        return new(
            column_name,
            Tables.columntype(data, column_name),
            n_missing,
            1 - (n_missing / count_rows(data)),
            n_unique,
        )
    end
end

struct DateTimeColumn
    name::Symbol
    type::Type
    n_missing::Int64
    completion_rate::Float64
    minimum::Union{Dates.Date, Dates.DateTime, Missing}
    maximum::Union{Dates.Date, Dates.DateTime, Missing}
    histogram::String

    function DateTimeColumn(data, column_name)
        column = Tables.getcolumn(data, column_name)
        column = skipmissing(column)
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

struct AllMissingColumn
    name::Symbol
    type::Type

    function AllMissingColumn(data, column_name)
        return new(column_name, Tables.columntype(data, column_name))
    end
end

struct Skimmed
    summary::Summary
    numeric_columns::Vector{NumericColumn}
    categorical_columns::Vector{CategoricalColumn}
    datetime_columns::Vector{DateTimeColumn}
    allmissing_columns::Vector{AllMissingColumn}
end

"""
    function skim(data)::Skimmed

Skim any Tables.jl compatible table.
"""
function skim(input_data)::Skimmed
    if !Tables.istable(input_data)
        throw(ArgumentError("Input to skim() must be a valid Tables.jl table."))
    end

    data = Tables.columns(input_data)

    data_schema = Tables.schema(data)
    if isnothing(data_schema)
        column_names = Tables.columnnames(data)
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

    # AllMissing columns
    allmissing_column_names = filter(
        column_name -> is_allmissing(Tables.columntype(data, column_name)),
        column_names,
    )
    allmissing_columns = collect(
        map(column_name -> AllMissingColumn(data, column_name), allmissing_column_names),
    )
    # Summary
    summary = Summary(
        typeof(data),
        count_rows(data),
        count_columns(data),
        length(numeric_columns),
        length(categorical_columns),
        length(datetime_columns),
        length(allmissing_columns),
    )

    return Skimmed(
        summary,
        numeric_columns,
        categorical_columns,
        datetime_columns,
        allmissing_columns,
    )
end

function Base.show(io::IO, summary::Summary)
    summary_table = [
        "Type" summary.type
        "N. rows" summary.n_rows
        "N. cols" summary.n_columns
        "N. numeric cols" summary.n_numeric
        "N. categorical cols" summary.n_categorical
        "N. datetime cols" summary.n_datetime
        "N. allmissing cols" summary.n_allmissing
    ]
    pretty_table(
        io,
        summary_table;
        noheader = true,
        backend = Val(:text),
        highlighters = (hl_col(1, Crayon(bold = true))),
    )
    return
end

function Base.show(io::IO, numeric_columns::Vector{NumericColumn})
    n_numeric_columns = length(numeric_columns)
    if n_numeric_columns > 0
        numeric_table = StructArray(numeric_columns)
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
        numeric_formatters = (
            formatter_numeric(
                numeric_table,
                [:mean, :standard_deviation, :minimum, :median, :maximum];
                n_decimal_places = 2,
            ),
            formatter_percent(numeric_table, [:completion_rate]; n_decimal_places = 1),
            formatter_missing,
        )
        println(io, "$(n_numeric_columns) numeric column$(plural(n_numeric_columns))")
        pretty_table(
            io,
            numeric_table;
            header = numeric_header,
            backend = Val(:text),
            formatters = numeric_formatters,
        )
    end
    return
end

function Base.show(io::IO, categorical_columns::Vector{CategoricalColumn})
    n_categorical_columns = length(categorical_columns)
    if n_categorical_columns > 0
        categorical_table = StructArray(categorical_columns)
        categorical_header = ["Name", "Type", "Missings", "Complete", "Unique"]
        categorical_formatters =
            formatter_percent(categorical_table, [:completion_rate]; n_decimal_places = 1)
        println(
            io,
            "$(n_categorical_columns) categorical column$(plural(n_categorical_columns))",
        )
        pretty_table(
            io,
            categorical_table;
            header = categorical_header,
            backend = Val(:text),
            formatters = categorical_formatters,
        )
    end
    return
end

function Base.show(io::IO, datetime_columns::Vector{DateTimeColumn})
    n_datetime_columns = length(datetime_columns)
    if n_datetime_columns > 0
        datetime_table = StructArray(datetime_columns)
        datetime_header = ["Name", "Type", "Missings", "Complete", "Min.", "Max.", "Hist."]
        datetime_formatters =
            formatter_percent(datetime_table, [:completion_rate]; n_decimal_places = 1)
        println(io, "$(n_datetime_columns) datetime column$(plural(n_datetime_columns))")
        pretty_table(
            io,
            datetime_table;
            header = datetime_header,
            backend = Val(:text),
            formatters = datetime_formatters,
        )
    end
    return
end

function Base.show(io::IO, allmissing_columns::Vector{AllMissingColumn})
    n_allmissing_columns = length(allmissing_columns)
    if n_allmissing_columns > 0
        allmissing_table = StructArray(allmissing_columns)
        allmissing_header = ["Name", "Type"]
        println(
            io,
            "$(n_allmissing_columns) allmissing column$(plural(n_allmissing_columns))",
        )
        pretty_table(io, allmissing_table; header = allmissing_header, backend = Val(:text))
    end
    return
end

function Base.show(io::IO, skimmed::Skimmed)
    println(io, skimmed.summary)
    println(io, skimmed.numeric_columns)
    println(io, skimmed.categorical_columns)
    println(io, skimmed.datetime_columns)
    println(io, skimmed.allmissing_columns)
    return
end

end # module
