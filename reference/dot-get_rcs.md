# Calculate restricted cubic spline basis functions

Computes restricted cubic spline (RCS) basis functions for a given
vector and knot positions. This implementation follows the algorithm
from Hmisc::rcspline.eval.

## Usage

``` r
.get_rcs(x, knots)
```

## Arguments

- x:

  Numeric vector of values to transform

- knots:

  Numeric vector of knot positions

## Value

Matrix with RCS basis functions as columns

## Errors

- `insufficient_knots`: Raised when fewer than 3 knots are provided; at
  least 3 are required for RCS calculations.
