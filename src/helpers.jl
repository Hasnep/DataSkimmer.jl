"""
Count the number of rows of a table.
"""
function count_rows(data)::Integer
    if Tables.rowaccess(data)
        return length(Tables.rows(data))
    else
        @error "Can't count the number of rows"
    end
end

"""
Count the number of columns of a table.
"""
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

is_datetime(x)::Bool = x == Dates.Date || x == Dates.DateTime
is_numeric(x)::Bool = x <: Union{Real, Missing}
is_categorical(x)::Bool = !is_numeric(x) && !is_datetime(x)

function formatter_numeric(data, columns_to_format; n_decimal_places::Integer)
    format_string = "%.$(n_decimal_places)f"
    column_indices = findall(n -> n in columns_to_format, Tables.columnnames(data))
    return ft_printf(format_string, column_indices)
end

function formatter_percent(data, columns_to_format; n_decimal_places::Integer)
    format_string = "%.$(n_decimal_places)f%%"
    column_indices = findall(n -> n in columns_to_format, Tables.columnnames(data))
    return (v, i, j) ->
        ft_printf(format_string, column_indices)(typeof(v) <: Number ? 100 * v : v, i, j)
end

plural(n) = n == 1 ? "" : "s"
