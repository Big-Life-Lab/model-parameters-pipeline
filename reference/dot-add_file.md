# Load and Add File to Model Cache

Internal function that loads a CSV file and adds it to the model's file
cache.

## Usage

``` r
.add_file(mod, file)
```

## Arguments

- mod:

  Model object

- file:

  Path to CSV file to load

## Value

Updated model object with file in cache

## Errors

- `inaccessible_file`: Raised when \`file\` does not exist, or when
  \`mod\$sandbox_path\` is set and \`file\` is not a descendant of that
  directory. In the sandbox case the error message deliberately avoids
  revealing whether the file exists, to prevent directory enumeration.

- `invalid_file_format`: Raised when \`file\` exists and is within the
  sandbox but cannot be read as a CSV by \[utils::read.csv()\].
