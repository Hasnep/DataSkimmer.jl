"""
Count the number of rows of a table.
"""
function count_rows(data)::Integer
    if Tables.rowaccess(data)
        return length(Tables.rows(data))
    else
        # Because we wrapped in
        # Tables.columns earlier, the
        # output of `getcolumn(data, 1)`
        # is guaranteed to have `length`
        # defined.
        return nrows = length(Tables.getcolumn(data, 1))
    end
end

"""
Count the number of columns of a table.
"""
function count_columns(data)::Integer
    data_schema = Tables.schema(data)
    if isnothing(data_schema)
        return length(Tables.columnnames(data))
    else
        return length(data_schema.names)
    end
end

is_allmissing(x)::Bool = x <: Missing
is_datetime(x)::Bool = !is_allmissing(x) && x <: Union{Dates.Date, Dates.DateTime, Missing}
is_numeric(x)::Bool = !is_allmissing(x) && x <: Union{Real, Missing}
is_categorical(x)::Bool = !is_allmissing(x) && !is_numeric(x) && !is_datetime(x)

function formatter_numeric(data, columns_to_format; n_decimal_places::Integer)
    format_string = "%.$(n_decimal_places)f"
    column_indices = findall(n -> n in columns_to_format, Tables.columnnames(data))
    return ft_printf(format_string, column_indices)
end

function formatter_percent(data, columns_to_format; n_decimal_places::Integer)
    format_string = "%.$(n_decimal_places)f%%"
    column_indices = findall(n -> n in columns_to_format, Tables.columnnames(data))
    return (v, i, j) -> if typeof(v) <: Number && j in column_indices
        ft_printf(format_string, column_indices)(100 * v, i, j)
    else
        v
    end
end

formatter_missing(v, i, j) = ismissing(v) ? "" : v

plural(n) = n == 1 ? "" : "s"
