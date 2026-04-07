# Format the file path to be relative to relative_to_path

This is generally for informational purposes to report to the user. It
is meant to hide the full paths of files on the system from a user so
that attackers cannot gather information about the system's directory
structure. Usually, the relative_to_path parameter would be the sandbox
path.

## Usage

``` r
.file_relative_to_path(file, relative_to_path)
```

## Arguments

- file:

  The file path to format.

- relative_to_path:

  The path that we want the file to be relative to.

## Value

The formatted file path. If either \`file\` or \`relative_to_path\` do
not exist, or if \`file\` is not a descendant of \`relative_to_path\`
then simply the basename of \`file\` is returned.

## Details

The returned value should not be used for actual file access.
