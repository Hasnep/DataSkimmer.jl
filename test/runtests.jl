using CSV
using DataSkimmer
using RDatasets: dataset
using Test
using DataFrames
using StructArrays

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
        @testset "unicode_histogram draws $n_bars bar(s)" for n_bars = [1,2,5,10]
            @test DataSkimmer.unicode_histogram(-100:100, n_bars) isa String
            @test length(DataSkimmer.unicode_histogram(-100:100, n_bars)) == n_bars
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
            println(skim(dataset))
        end
    end
end
