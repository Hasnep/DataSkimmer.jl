using CSV
using DataSkimmer
using RDatasets: dataset
using Test

iris = dataset("datasets", "iris")
tuple_dataset = (A = [1, missing, 3], B = [1.0, 2.0, 3.0], C = ["hey", "there", "sailor"])
iris_csv = CSV.File(joinpath("data", "example.csv"))
datasets = Dict(
    "iris dataframe" => iris,
    "iris csv" => iris_csv,
    #   "tuple_dataset" => tuple_dataset
)
@testset "DataSkimmer.jl" begin
    @testset "Skims $ds_name" for (ds_name, dataset) in datasets
        @test skim(dataset) isa DataSkimmer.Skimmed
    end
    @testset "unicode_histogram" begin
        @testset "unicode_histogram draws $n_bars bars" for n_bars = 1:10
            @test DataSkimmer.unicode_histogram(iris.SepalLength, n_bars) isa String
            @test length(DataSkimmer.unicode_histogram(iris.SepalLength, n_bars)) == n_bars
        end
    end
end
