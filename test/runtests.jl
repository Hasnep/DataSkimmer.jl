import CSV
import Random
import RDatasets
using DataFrames
using DataSkimmer
using Dates: Date
using StructArrays: StructArray
using Test
using TimeSeries: TimeArray

datasets = Dict(
    # "iris_dataframe" => RDatasets.dataset("datasets", "iris"),
    # "iris_csv" => CSV.File(seekstart(CSV.write(IOBuffer(), iris_dataframe))),
    "structarray" => StructArray([
        (A = 1, B = "one", C = Date(2021, 1, 1)),
        (A = 2, B = "two", C = Date(2021, 1, 2)),
        (A = 3, B = "three", C = Date(2021, 1, 3)),
    ]),
    # "timearray" =>
    #     TimeArray(RDatasets.dataset("ggplot2", "economics"), timestamp = :Date),
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
    include("test_formatting.jl")
end
