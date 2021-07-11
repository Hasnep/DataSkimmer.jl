iris_dataframe = RDatasets.dataset("datasets", "iris")

base_table = [
    (A = 1, B = "one", C = Dates.Date(2021, 1, 1)),
    (A = 2, B = "two", C = Dates.Date(2021, 1, 2)),
    (A = 3, B = "three", C = missing),
]

datasets = Dict(
    "iris_dataframe" => iris_dataframe,
    "iris_csv" => CSV.File(seekstart(CSV.write(IOBuffer(), iris_dataframe))),
    "struct_array" => StructArray(base_table),
    "timearray" =>
        TimeArray(RDatasets.dataset("ggplot2", "economics"), timestamp = :Date),
    "loomis_dataframe" => RDatasets.dataset("COUNT", "loomis"),
    "empty_dataframe" => DataFrame(x = [], y = Int64[], z = String[]),
    "vector_of_nt" => base_table,
    "nt_of_vectors" => Tables.columntable(base_table),
)
