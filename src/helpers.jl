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

is_categorical(x)::Bool = !(x <: Real || is_datetime(x))
