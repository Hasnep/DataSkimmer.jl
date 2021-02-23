using Glob
import JuliaFormatter
using Test

@testset "Test codebase is formtted correctly" begin
    source_files = glob("../**/*.jl")
    @testset "Test $filepath is formtted correctly" for filepath in source_files
        file_string = read(filepath, String)
        file_string = replace(file_string, "\r\n" => "\n") # Normalise EOLs
        file_string_formatted = JuliaFormatter.format_text(
            file_string,
            margin = 120,
            always_for_in = true,
            always_use_return = true,
            annotate_untyped_fields_with_any = true,
            conditional_to_if = true,
            format_docstrings = true,
            remove_extra_newlines = true,
            whitespace_in_kwargs = true,
            whitespace_ops_in_indices = true,
            whitespace_typedefs = true,
        )
        @test file_string == file_string_formatted
    end
end
