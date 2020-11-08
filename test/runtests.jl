import CSV
import Random
import RDatasets
using DataFrames
using DataSkimmer
using StructArrays: StructArray
using Test
using TimeSeries: TimeArray

iris_dataframe = RDatasets.dataset("datasets", "iris")
iris_csv = CSV.File(joinpath("data", "iris.csv"))
data_structarray = StructArray([(A = 1, B = 2, C = 3), (A = 4, B = 5, C = 6), (A = 7, B = 8, C = 9)])
timearray = TimeArray(RDatasets.dataset("ggplot2", "economics"), timestamp = :Date)
datasets = Dict(
    "iris_dataframe" => iris_dataframe,
    "iris_csv" => iris_csv,
    "structarray" => data_structarray,
    "timearray" => timearray,
)

@testset "Test DataSkimmer.jl" begin
    @testset "Test unicode_histogram" begin
        @testset "Test unicode_histogram draws $n_bars bar(s)" for n_bars in [1, 2, 5, 10]
            output = DataSkimmer.unicode_histogram(-100:100, n_bars)
            @test output isa String
            @test length(output) == n_bars
        end
        @testset "Test unicode_histogram draws bars when $p% of the data is missing" for p in [0, 10, 50, 100]
            input = Random.shuffle(vcat(repeat([missing], p), 1:p))
            output = DataSkimmer.unicode_histogram(input, 5)
            @test output isa String
            @test length(output) == 5
        end
    end
    @testset "Test dataset '$ds_name'" for (ds_name, dataset) in datasets
        @testset "Test summary functions" begin
            @testset "Test count_rows($ds_name) counts the number of rows" begin
                @test DataSkimmer.count_rows(dataset) isa Integer
            end
            @testset "Test count_columns($ds_name) counts the number of columns" begin
                @test DataSkimmer.count_columns(dataset) isa Integer
            end
        end
        @testset "Test skim($ds_name) produces output" begin
            @test skim(dataset) isa DataSkimmer.Skimmed
            @test string(skim(dataset)) isa String
        end
    end
    include("test_formatting.jl")
end
