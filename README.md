# DataSkimmer.jl

A Julia package that gives a summary of a tabular dataset in the REPL.
Based on the [skimr](https://docs.ropensci.org/skimr/) R package.

## Installation

From the Julia REPL, type `]` to enter the Pkg REPL, then run:

```text
add DataSkimmer
```

Or run from the Julia REPL:

```julia
import Pkg
Pkg.add("DataSkimmer")
```

## Example

```julia
# Load some data
using RDatasets
iris = RDatasets.dataset("datasets", "iris")

# Skim the data
using DataSkimmer
skim(iris)
```

```text
┌─────────────────────┬───────────┐
│                Type │ DataFrame │
│             N. rows │       150 │
│             N. cols │         5 │
│     N. numeric cols │         4 │
│ N. categorical cols │         1 │
│    N. datetime cols │         0 │
└─────────────────────┴───────────┘

4 numeric columns
┌─────────────┬─────────┬──────────┬──────────┬──────┬──────┬──────┬──────┬──────┬───────┐
│        Name │    Type │ Missings │ Complete │ Mean │ Std. │ Min. │ Med. │ Max. │ Hist. │
├─────────────┼─────────┼──────────┼──────────┼──────┼──────┼──────┼──────┼──────┼───────┤
│ SepalLength │ Float64 │        0 │   100.0% │ 5.84 │ 0.83 │ 4.30 │ 5.80 │ 7.90 │ ▂▃▃▂▁ │
│  SepalWidth │ Float64 │        0 │   100.0% │ 3.06 │ 0.44 │ 2.00 │ 3.00 │ 4.40 │ ▁▃▄▂▁ │
│ PetalLength │ Float64 │        0 │   100.0% │ 3.76 │ 1.77 │ 1.00 │ 4.35 │ 6.90 │ ▃▁▂▃▁ │
│  PetalWidth │ Float64 │        0 │   100.0% │ 1.20 │ 0.76 │ 0.10 │ 1.30 │ 2.50 │ ▃▁▃▂▂ │
└─────────────┴─────────┴──────────┴──────────┴──────┴──────┴──────┴──────┴──────┴───────┘

1 categorical column
┌─────────┬─────────────────────────────────┬──────────┬──────────┐
│    Name │                            Type │ Missings │ Complete │
├─────────┼─────────────────────────────────┼──────────┼──────────┤
│ Species │ CategoricalValue{String, UInt8} │        0 │   100.0% │
└─────────┴─────────────────────────────────┴──────────┴──────────┘
```
