module DataSkimmer

import Tables
using StatsBase: Histogram, fit
using Statistics: mean, std, median
using PrettyTables: pretty_table, borderless, ft_round

export skim

struct Summary
    n_rows::Union{Integer,Missing}
    n_columns::Integer
    n_numeric::Integer
    n_categorical::Integer

    function Summary(data)
        if Tables.rowaccess(data)
            n_rows = length(Tables.rows(data))
        else
            n_rows = missing
        end
        data_schema = Tables.schema(data)
        if isnothing(data_schema)
            @warn "Data has no schema"
            n_columns = missing
        else
            n_columns = length(data_schema.names)
        end
        n_numeric = length(filter(t -> t <: Real, data_schema.types))
        n_categorical = length(filter(t -> t <: String, data_schema.types))
        return new(n_rows, n_columns, n_numeric, n_categorical)
    end
end

Base.@kwdef struct NumericColumns
    names::Vector{Symbol}
    types::Vector{DataType}
    n_missings::Vector{Integer}
    completion_rates::Vector{Real}
    means::Vector{Real}
    standard_deviations::Vector{Real}
    minima::Vector{Real}
    medians::Vector{Real}
    maxima::Vector{Real}
    histograms::Vector{String}
end

Base.@kwdef struct CategoricalColumns
    names::Vector{Symbol}
    types::Vector{DataType}
    n_missings::Vector{Integer}
    completion_rates::Vector{Real}
end

Tables.table(nc::CategoricalColumns) = Tables.table(
    hcat(nc.names, nc.types, nc.n_missings, nc.completion_rates),
    header = [:names, :types, :n_missings, :completion_rates],
)

Tables.table(nc::NumericColumns) = Tables.table(
    hcat(
        nc.names,
        nc.types,
        nc.n_missings,
        nc.completion_rates,
        nc.means,
        nc.standard_deviations,
        nc.minima,
        nc.medians,
        nc.maxima,
        nc.histograms,
    ),
    header = [
        :names,
        :types,
        :n_missings,
        :completion_rates,
        :means,
        :standard_deviations,
        :minima,
        :medians,
        :maxima,
        :histograms,
    ],
)

struct Skimmed
    summary::Summary
    numeric::NumericColumns
    categorical::CategoricalColumns
end


function skim(data)::Skimmed
    @assert Tables.istable(data) "Input must be a table"

    if Tables.rowaccess(data)
        n_rows = length(data)
    else
        n_rows = missing
    end

    data_schema = Tables.schema(data)
    if isnothing(data_schema)
        column_names = Tables.columnnames(categorical_table)
        column_types = missing
    else
        column_names = data_schema.names
        column_types = data_schema.types
    end
    n_columns = length(column_names)
    
    # Numeric columns
    numeric_column_names =    filter(n -> (Tables.columntype(data, n) <: Real), column_names) |> collect
    numeric_column_types = [Tables.columntype(data, n) for n in numeric_column_names]
    numeric_n_missings =    [sum(ismissing.(Tables.getcolumn(data, n))) for n in numeric_column_names]
    numeric_completion_rates = 1 .- (numeric_n_missings ./ n_rows)
    means = [mean(Tables.getcolumn(data, n)) for n in numeric_column_names]
    standard_deviations = [std(Tables.getcolumn(data, n)) for n in numeric_column_names]
    minima = [minimum(Tables.getcolumn(data, n)) for n in numeric_column_names]
    medians = [median(Tables.getcolumn(data, n)) for n in numeric_column_names]
    maxima = [maximum(Tables.getcolumn(data, n)) for n in numeric_column_names]
    histograms =  [unicode_histogram(Tables.getcolumn(data, n), 5) for n in numeric_column_names]
    numeric_columns = NumericColumns(
        names = numeric_column_names,
        types = numeric_column_types,
        n_missings = numeric_n_missings,
        completion_rates = numeric_completion_rates,
        means = means,
        standard_deviations = standard_deviations,
        minima = minima,
        medians = medians,
        maxima = maxima,
        histograms = histograms,
    )

    # Categorical columns
    categorical_column_names =
        filter(n -> !(Tables.columntype(data, n) <: Real), column_names) |> collect
    categorical_column_types =
        [Tables.columntype(data, n) for n in categorical_column_names]
    categorical_n_missings =
        [sum(ismissing.(Tables.getcolumn(data, n))) for n in categorical_column_names]
    categorical_completion_rates = 1 .- (categorical_n_missings ./ n_rows)

  
    categorical_columns = CategoricalColumns(
        names = categorical_column_names,
        types = categorical_column_types,
        n_missings = categorical_n_missings,
        completion_rates = categorical_completion_rates,
    )
    return Skimmed(Summary(data), numeric_columns, categorical_columns)
end

function Base.show(io::IO, skimmed::Skimmed)
    # Numeric
    numeric_table = Tables.table(skimmed.numeric)
    numeric_header = [
        "Name",
        "Type",
        "No. missings",
        "Completion rate",
        "Mean",
        "Standard deviation",
        "Minimum",
        "Median",
        "Maximum",
        "Histogram",
    ]
    numeric_rounded =
        [:completion_rates, :means, :standard_deviations, :minima, :medians, :maxima]
    numeric_formatters =
        ft_round(2, findall(n -> n in numeric_rounded, Tables.columnnames(numeric_table)))
    pretty_table(
        io,
        numeric_table,
        numeric_header;
        backend = :text,
        tf = borderless,
        formatters = numeric_formatters,
    )
    # Categorical
    categorical_table = Tables.table(skimmed.categorical)
    categorical_header = ["Name", "Type", "No. missings", "Completion rate"]
    categorical_rounded = [:completion_rates]
    categorical_formatters = ft_round(
        2,
        findall(n -> n in categorical_rounded, Tables.columnnames(categorical_table)),
    )
    pretty_table(
        io,
        categorical_table,
        categorical_header;
        backend = :text,
        tf = borderless,
        formatters = categorical_formatters,
    )
end

"""Plots a histogram using unicode characters."""
function unicode_histogram(x::Vector{T}, n_bins::Integer) where {T <: Real}
    data_min = minimum(x)
    bin_width = (maximum(x) - data_min) / n_bins
    bin_edges = [data_min + i * bin_width for i = 0:n_bins]
    weights = [length(x[bin_edges[i] .< x .<= bin_edges[i + 1]]) for i = 1:n_bins] ./ length(x)
    output = [b == 0 ? ' ' : Char(0x2581 + floor(Int, b * 8)) for b in weights]
    return join(output, "")
end

end
