"""
Create a range of equally spaced steps between two Dates or DateTimes.
"""
function Base.range(
    start::T,
    stop::T;
    length::Integer,
) where {T <: Union{Dates.Date, Dates.DateTime}}
    range_width = stop - start
    T_width = typeof(range_width)
    step_width = T_width(div(Dates.value(range_width), length - 1, RoundUp))
    stop = start + step_width * (length - 1)
    return start:step_width:stop
end

"""
Construct a histogram made of a sequence of unicode bar characters.
"""
function unicode_histogram(x, n_bins::Integer)::String
    n_nonmissing_datapoints = count(!ismissing, x)
    if n_nonmissing_datapoints == 0
        return repeat(" ", n_bins)
    end
    x = skipmissing(x)
    min_value, max_value = extrema(x)
    if max_value == min_value
        return repeat(" ", n_bins)
    end
    bin_edges = range(min_value, max_value; length = n_bins + 1)
    weights = [
        if index == 1
            count(datapoint -> edge_lower <= datapoint <= edge_upper, x)
        else
            count(datapoint -> edge_lower < datapoint <= edge_upper, x)
        end for
        (index, (edge_lower, edge_upper)) in enumerate(partition(bin_edges, 2, 1))
    ]
    weights_normalised = weights ./ n_nonmissing_datapoints
    bars = [w == 0 ? ' ' : Char(0x2581 + floor(Int, w * 8)) for w in weights]
    return join(bars, "")
end
