# The most basic Tables.jl table is a vector of named tuples
vector_of_named_tuples = [
    (a = 1, b = "one", c = Dates.Date(2021, 1, 1)),
    (a = 2, b = "two", c = Dates.Date(2021, 1, 2)),
    (a = 3, b = "three", c = Dates.Date(2021, 1, 3)),
]

# The famous iris dataset to test DataFrames.jl dataframes
iris_dataframe = RDatasets.dataset("datasets", "iris")

# Write the dataframe as CSV and then read again to test CSV.jl File
iris_csv = CSV.File(seekstart(CSV.write(IOBuffer(), iris_dataframe)))

# Use the economics dataset from ggplot2 to test datetimes
economics_dataframe = RDatasets.dataset("ggplot2", "economics")

# Convert the economics dataset to a TimeArray
economics_timearray = TimeArray(economics_dataframe, timestamp = :Date)

# A dataset with different levels of missingness
mostly_missing = DataFrame(
    a = rand(1:5, 1000),
    b = rand([1; missing], 1000),
    c = rand([1:4; missing], 1000),
    d = repeat([missing], 1000),
)

datasets = Dict(
    "vector_of_named_tuples" => vector_of_named_tuples,
    "named_tuple_of_vectors" => Tables.columntable(vector_of_named_tuples),
    "struct_array" => StructArray(vector_of_named_tuples),
    "iris_dataframe" => iris_dataframe,
    "iris_csv" => iris_csv,
    "economics_dataframe" => economics_dataframe,
    "economics_timearray" => economics_timearray,
    "loomis_dataframe" => RDatasets.dataset("COUNT", "loomis"),
    "empty_dataframe" => DataFrame(x = [], y = Int64[], z = String[]),
    "mostly_missing" => mostly_missing,
)
