import CSV
import Random
using DataFrames
using DataSkimmer
using RDatasets: dataset
using StructArrays
using Test

iris_dataframe = dataset("datasets", "iris")
iris_csv = CSV.File(joinpath("data", "iris.csv"))
data_structarray =
    StructArray([(A = 1, B = 2, C = 3), (A = 4, B = 5, C = 6), (A = 7, B = 8, C = 9)])
datasets = Dict(
    "iris dataframe" => iris_dataframe,
    "iris csv" => iris_csv,
    "structarray" => data_structarray,
)
@testset "DataSkimmer.jl" begin
    @testset "unicode_histogram" begin
        @testset "unicode_histogram draws $n_bars bar(s)" for n_bars in [1, 2, 5, 10]
            output = DataSkimmer.unicode_histogram(-100:100, n_bars)
            @test output isa String
            @test length(output) == n_bars
        end
        @testset "unicode_histogram draws bars for $p% missing" for p in [0, 10, 50, 100]
            input = Random.shuffle(vcat(repeat([missing], p), 1:p))
            output = DataSkimmer.unicode_histogram(input, 5)
            @test output isa String
            @test length(output) == 5
        end
    end
    @testset "$ds_name" for (ds_name, dataset) in datasets
        @testset "Summary" begin
            @testset "count_rows" begin
                @test DataSkimmer.count_rows(dataset) isa Integer
            end
            @testset "count_columns" begin
                @test DataSkimmer.count_columns(dataset) isa Integer
            end
        end
        @testset "skim($ds_name)" begin
            @test skim(dataset) isa DataSkimmer.Skimmed
            @test string(skim(dataset)) isa String
        end
    end
    include("test_formatting.jl")
end
