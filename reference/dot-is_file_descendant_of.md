# Check if a file is a descendant of a directory, and that both the file and directory exist.

Symbolic links and ".." will be followed and expanded.

## Usage

``` r
.is_file_descendant_of(file, top_level_directory)
```

## Arguments

- file:

  Character. The path to the file to check.

- top_level_directory:

  Character. The path to the directory that \`file\` should be a
  descendant of.

## Value

Logical. \`TRUE\` if \`file\` is a descendant of
\`top_level_directory\`, \`FALSE\` otherwise. Returns \`FALSE\` if
either \`file\` or \`top_level_directory\` do not exist on the file
system.
