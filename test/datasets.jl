# The most basic Tables.jl table is a vector of named tuples
vector_of_named_tuples = [
    (a = 1, b = "one", c = Date(2021, 1, 1), d = Time(1, 2, 3)),
    (a = 2, b = "two", c = Date(2021, 1, 2), d = Time(2, 3, 4)),
    (a = 3, b = "three", c = Date(2021, 1, 3), d = Time(3, 4, 5)),
]

# The famous iris dataset to test DataFrames.jl dataframes
iris_dataframe = RDatasets.dataset("datasets", "iris")

# Write the dataframe as CSV and then read again to test CSV.jl File
iris_csv = CSV.File(seekstart(CSV.write(IOBuffer(), iris_dataframe)))

# Use the economics dataset from ggplot2 to test datetimes
economics_dataframe = RDatasets.dataset("ggplot2", "economics")

# Convert the economics dataset to a TimeArray
economics_timearray = TimeArray(economics_dataframe, timestamp = :Date)

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
)
