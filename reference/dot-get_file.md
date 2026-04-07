# Get File from Model Cache

Internal function that retrieves a previously loaded file from the
model's cache.

## Usage

``` r
.get_file(mod, file)
```

## Arguments

- mod:

  Model object

- file:

  Path to file to retrieve

## Value

Data from the file cache (eg. a dataframe)

## Errors

\* \`file_not_added\`: Raised when \`file\` has not been previously
loaded into the model cache via \[\`.add_file()\`\], indicating the
caller did not add the file before attempting to retrieve it.
