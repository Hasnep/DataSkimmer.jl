# DataSkimmer.jl

A Julia package that gives a summary of a tabular dataset in the REPL.
Based on the [skimr](https://docs.ropensci.org/skimr/) R package.

## Installation

From the Julia REPL, type `]` to enter the Pkg REPL:

```text
add https://github.com/JuliaData/DataFrames.jl
```

Or run from the Julia REPL:

```julia
import Pkg
Pkg.add("https://github.com/JuliaData/DataFrames.jl")
```

## Example

```julia
using DataSkimmer
using RDatasets

iris = dataset("datasets", "iris")

skim(iris)
```

```text
         n_rows   150
      n_columns     5
  n_categorical     1
      n_numeric     4

         Name      Type   Missings   Complete   Mean   Std.   Min.   Med.   Max.   Hist.

  SepalLength   Float64          0     100.0%   5.84   0.83    4.3    5.8    7.9   ▂▃▃▂▁
   SepalWidth   Float64          0     100.0%   3.06   0.44    2.0    3.0    4.4   ▁▃▄▂▁
  PetalLength   Float64          0     100.0%   3.76   1.77    1.0   4.35    6.9   ▃▁▂▃▁
   PetalWidth   Float64          0     100.0%    1.2   0.76    0.1    1.3    2.5   ▃▁▃▂▂

     Name                             Type   Missings   Complete

  Species   CategoricalValue{String,UInt8}          0     100.0%
```
