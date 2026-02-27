# Get a file path safe to include in user-facing error messages

If \`mod\$sandbox_path\` is set, returns the path of \`file\` relative
to \`sandbox_path\`, or just the filename if \`file\` is not inside
\`sandbox_path\` or if it does not exist. If \`mod\$sandbox_path\` is
not set, returns \`file\` unchanged.

## Usage

``` r
.reportable_file(mod, file)
```

## Arguments

- mod:

  The model object, optionally containing \`sandbox_path\`.

- file:

  The file path to make reportable.

## Value

A file path safe to display in user-facing error messages.

## Details

The returned path avoids exposing the underlying directory structure of
the system to the user, which is useful for displaying error messages on
a website or other public-facing context.
