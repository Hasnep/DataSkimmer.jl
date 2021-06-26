import CSV
import Random
import RDatasets
using DataFrames
using DataSkimmer
using Dates
using StructArrays: StructArray
using Test
using TimeSeries: TimeArray

iris_dataframe = RDatasets.dataset("datasets", "iris")

base_table = [
    (A = 1, B = "one", C = Dates.Date(2021, 1, 1)),
    (A = 2, B = "two", C = Dates.Date(2021, 1, 2)),
    (A = 3, B = "three", C = Dates.Date(2021, 1, 3)),
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

@testset "Test DataSkimmer.jl" begin
    @testset "Test unicode_histogram" begin
        @testset "Test unicode_histogram draws $n_bars bar(s)" for n_bars in [1, 2, 5, 10]
            output = DataSkimmer.unicode_histogram(-100:100, n_bars)
            @test output isa String
            @test length(output) == n_bars
        end
        @testset "Test unicode_histogram works when $p% is missing" for p in 0:50:100
            n_bars = 5
            input = vcat(1:(100 - p), repeat([missing], p))
            output = DataSkimmer.unicode_histogram(input, n_bars)
            @test output isa String
            @test length(output) == n_bars
        end
    end

    @testset "Test column type helper functions" begin
        column_types = Dict(
            Dates.Date => :datetime,
            Dates.DateTime => :datetime,
            Union{Dates.Date, Missing} => :datetime,
            Union{Dates.DateTime, Missing} => :datetime,
            Real => :numeric,
            Union{Real, Missing} => :numeric,
            String => :categorical,
            Union{String, Missing} => :categorical,
            Symbol => :categorical,
            Union{Symbol, Missing} => :categorical,
        )
        @testset "Test $column_type is categorised as $type_name" for (
            column_type,
            type_name,
        ) in column_types
            @test DataSkimmer.is_datetime(column_type) == (type_name == :datetime)
            @test DataSkimmer.is_numeric(column_type) == (type_name == :numeric)
            @test DataSkimmer.is_categorical(column_type) == (type_name == :categorical)
        end
    end

    @testset "Test on example datasets" begin
        @testset "Test dataset '$ds_name'" for (ds_name, data) in datasets
            @testset "Test summary functions" begin
                @testset "Test count_rows($ds_name) counts the number of rows" begin
                    @test DataSkimmer.count_rows(data) isa Integer
                end
                @testset "Test count_columns($ds_name) counts the number of columns" begin
                    @test DataSkimmer.count_columns(data) isa Integer
                end
            end
            @testset "Test skim($ds_name) produces output" begin
                @test skim(data) isa DataSkimmer.Skimmed
                @test string(skim(data)) isa String
            end
        end
    end

    @testset "Test skim() raises an error for invalid input" begin
        @test_throws ArgumentError skim("abc")
    end
end
