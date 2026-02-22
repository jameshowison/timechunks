# timechunks

> Named time periods for R — academic semesters, fiscal quarters, and any repeating domain-specific period system.

**Status:** In development — not yet on CRAN.

`timechunks` is designed for **repeating annual cycles**: period systems where
the same named periods recur every year (Fall/Spring/Summer, Q1–Q4, Michaelmas/Lent/Easter).
If your named periods do not repeat — see [Non-repeating periods](#non-repeating-periods) below.

---

## What it does

`timechunks` gives you a proper R vector type for named periods that cross calendar year boundaries:

```r
library(timechunks)

use_chunk_preset("us_semester")

# Parse any common format
time_chunk("fa26")          # code format
time_chunk("Fall 2026")     # text format
time_chunk(20268)           # YYYYM numeric (August 2026 → Fall 2026)

# Sorting works chronologically (not alphabetically)
sort(time_chunk(c("sp27", "fa26", "su27")))
# Fall 2026, Spring 2027, Summer 2027

# Survives dplyr operations intact
df |> mutate(semester = time_chunk(raw_code))

# Access metadata
x <- time_chunk("fa26")
start_date(x)   # 2026-08-23
end_date(x)     # 2027-01-14
mid_date(x)     # 2026-10-31
chunk_ay(x)     # "2026-27"
```

---

## Installation (Development)

The package is not on CRAN. Install from GitHub once published there:

```r
# Install pak if you don't have it
install.packages("pak")

pak::pak("yourgithubhandle/timechunks")
```

Or install from a local clone:

```r
install.packages("path/to/timechunks", repos = NULL, type = "source")
```

---

## Development Workflow

### Setup

```r
# Install dev tools if needed
install.packages(c("devtools", "usethis", "testthat", "roxygen2"))
```

Clone the repo and open the `.Rproj` file in RStudio, or `cd` into the directory in your terminal.

### The Core Loop

During development you **do not install the package**. Instead, use:

```r
devtools::load_all()   # Load all R/ files into your session (fast, ~1 second)
```

Run this every time you change a file in `R/`. It simulates having the package installed without actually installing it. Your changes are available immediately.

```r
# After editing R/parse.R:
devtools::load_all()
time_chunk("fa26")   # test your change
```

### Running Tests

```r
devtools::test()           # run all tests
devtools::test_file("tests/testthat/test-parse.R")  # run one file
```

Tests live in `tests/testthat/`. Each file corresponds to a file in `R/`.

### Checking Documentation

```r
devtools::document()   # regenerates NAMESPACE and man/ from roxygen2 comments
devtools::check_man()  # validates documentation
```

### Full Package Check

```r
devtools::check()              # runs R CMD check
devtools::check(cran = TRUE)   # stricter CRAN-level check
```

Run this before any pull request or release. Aim for 0 errors, 0 warnings, 0 notes.

### Test Coverage

```r
install.packages("covr")
covr::package_coverage()   # shows % coverage per file
covr::report()             # opens HTML coverage report in browser
```

---

## Quick Reference: devtools Commands

| Task | Command |
|------|---------|
| Load package for interactive use | `devtools::load_all()` |
| Run all tests | `devtools::test()` |
| Rebuild documentation | `devtools::document()` |
| Full package check | `devtools::check()` |
| Install package locally | `devtools::install()` |
| Build vignettes | `devtools::build_vignettes()` |

---

## Calendar Configuration

The package supports any domain through calendar configuration:

```r
# Use a built-in preset
use_chunk_preset("us_semester")     # Fall/Spring/Summer
use_chunk_preset("us_quarter")      # Fall/Winter/Spring/Summer
use_chunk_preset("uk_terms")        # Michaelmas/Lent/Easter
use_chunk_preset("us_federal_fy")   # US federal fiscal year
use_chunk_preset("australia_semester")

# Or define your own
set_chunk_calendar(
  periods = list(
    list(name = "Fall",   code = "fa", start_mmdd = "08-23"),
    list(name = "Spring", code = "sp", start_mmdd = "01-15"),
    list(name = "Summer", code = "su", start_mmdd = "06-01")
  ),
  year_start_period = "Fall"
)
```

---

## ggplot2 Integration

`timechunks` does **not** provide custom ggplot2 scales. Instead, use helper functions to create explicit label and date columns — this is standard tidyverse practice and more debuggable.

### Discrete (equal spacing)

```r
df |>
  mutate(sem_fct = as_chunk_factor(semester, labels = "code")) |>
  ggplot(aes(x = sem_fct, y = enrollment)) +
  geom_col()
```

### Continuous (proportional spacing)

```r
df |>
  mutate(
    mid = mid_date(semester),
    lbl = format(semester, style = "code")
  ) |>
  ggplot(aes(x = mid, y = enrollment)) +
  geom_point() +
  scale_x_date(breaks = ~.$mid, labels = ~.$lbl)
```

### Segment visualization (recommended — shows period duration)

```r
df |>
  mutate(
    x_start = start_date(semester),
    x_end   = end_date(semester),
    x_mid   = mid_date(semester),
    lbl     = format(semester, style = "code")
  ) |>
  ggplot() +
  geom_segment(
    aes(x = x_start, xend = x_end,
        y = enrollment, yend = enrollment,
        color = lbl),
    linewidth = 4
  ) +
  geom_point(aes(x = x_mid, y = enrollment)) +
  geom_line(aes(x = x_mid, y = enrollment), linetype = "dashed") +
  scale_x_date()
```

---

## YYYYM Format

Months 1–9 are 5 digits; months 10–12 are 6 digits:

| Input | Month | Maps to |
|-------|-------|---------|
| `20261` | January 2026 | Spring 2026 |
| `20268` | August 2026 | Fall 2026 |
| `202611` | November 2026 | Fall 2026 |
| `202612` | December 2026 | Fall 2026 |

Use `yyyym_strict = TRUE` in `set_chunk_calendar()` to error on ambiguous mappings.

---

## Non-repeating periods

`timechunks` requires a repeating annual cycle. For named periods that occur
only once — generational cohorts, historical eras, project phases — the same
sorting and labeling problems apply, but a plain data frame with an ordered
factor is sufficient:

```r
library(dplyr)
library(ggplot2)

generations <- data.frame(
  name  = c("Greatest", "Silent", "Boomers", "Gen X", "Millennials", "Gen Z"),
  start = as.Date(c("1901-01-01", "1928-01-01", "1946-01-01",
                    "1965-01-01", "1981-01-01", "1997-01-01")),
  end   = as.Date(c("1927-12-31", "1945-12-31", "1964-12-31",
                    "1980-12-31", "1996-12-31", "2012-12-31"))
) |>
  mutate(
    # Ordered factor preserves chronological order in plots and arrange()
    name_fct = factor(name, levels = name, ordered = TRUE),
    # Midpoint: useful for label placement on a continuous date axis
    mid      = start + (as.integer(end - start) %/% 2L)
  )

# Discrete axis (equal spacing) — sort order comes from the factor levels
generations |>
  mutate(span_years = as.integer(end - start) %/% 365L) |>
  ggplot(aes(x = name_fct, y = span_years)) +
  geom_col() +
  labs(x = NULL, y = "Years")

# Continuous axis (proportional spacing) — segments show true duration
generations |>
  ggplot() +
  geom_segment(aes(x = start, xend = end, y = name_fct, yend = name_fct),
               linewidth = 6, color = "steelblue") +
  geom_text(aes(x = mid, y = name_fct, label = name_fct), size = 3) +
  scale_x_date() +
  labs(x = NULL, y = NULL)
```

The key moves are the same as for repeating periods: define explicit
`start`/`end`/`mid` columns, use an ordered factor for the name, and let
ggplot2 handle the rest.

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Make changes, run `devtools::load_all()` and `devtools::test()`
4. Ensure `devtools::check()` is clean
5. Submit a pull request

---

## License

MIT
