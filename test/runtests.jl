import Aqua
import CSV
import Random
import RDatasets
using DataFrames
using DataSkimmer
using Dates
using StructArrays: StructArray
using Test
using TimeSeries: TimeArray

include("datasets.jl")

@testset "Test DataSkimmer.jl" begin
    @testset "Run Aqua.jl" begin
        Aqua.test_all(DataSkimmer)
    end
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
        @testset "Test unicode_histogram works with dates" begin
            n_bars = 5
            output = DataSkimmer.unicode_histogram(
                range(Date(2000, 1, 1), Date(2048, 1, 1); length = 10),
                n_bars,
            )
            @test output isa String
            @test length(output) == n_bars
        end
        @testset "Test unicode_histogram works with times" begin
            n_bars = 5
            output = DataSkimmer.unicode_histogram(
                range(Time(0, 0, 0), Time(23, 59, 59); step = Minute(7)),
                n_bars,
            )
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
