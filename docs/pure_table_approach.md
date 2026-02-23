# The Period Reference Table Approach

## The core idea

The sorting, labeling, and date-conversion problems all stem from the same
root cause: the period name stored in your data carries no information about
chronological position, start date, or display format. The solution in any
tool is the same — introduce a small reference table that supplies those
missing fields, then join your data against it.

This approach requires no specialized packages or language features. It works
in Excel, R, Python, SQL, or any other environment that supports a table join
or lookup.


## The reference table

The period reference table has one row per period. Every column is derived
from your institution's calendar rules and filled in once. The data never
changes unless the calendar itself changes.

| sort_key | code  | name        | ay      | start_date | end_date   | mid_date   |
|----------|-------|-------------|---------|------------|------------|------------|
| 1        | fa25  | Fall 2025   | 2025-26 | 2025-08-23 | 2026-01-14 | 2025-10-31 |
| 2        | sp26  | Spring 2026 | 2025-26 | 2026-01-15 | 2026-05-31 | 2026-03-23 |
| 3        | su26  | Summer 2026 | 2025-26 | 2026-06-01 | 2026-08-22 | 2026-07-12 |
| 4        | fa26  | Fall 2026   | 2026-27 | 2026-08-23 | 2027-01-14 | 2026-10-31 |
| 5        | sp27  | Spring 2027 | 2026-27 | 2027-01-15 | 2027-05-31 | 2027-03-23 |
| 6        | su27  | Summer 2027 | 2026-27 | 2027-06-01 | 2027-08-22 | 2027-07-12 |

The columns:

- **sort_key** — a plain integer. Sorting your data by this column produces
  chronological order in any tool without any special knowledge of period names.
- **code** — the short identifier used in your source data (`fa26`, `sp27`).
  This is typically the join key.
- **name** — the human-readable label for reports and figures (`Fall 2026`).
- **ay** — the academic or fiscal year grouping string (`2026-27`).
- **start_date / end_date** — the actual calendar dates of the period, needed
  for date-axis figures and for computing which period a given date falls in.
- **mid_date** — the midpoint between start and end, computed once and stored.
  Used for centering labels on continuous axes.


## Synonym columns

Source data rarely arrives in a single consistent format. The same period
might appear as `fa26` in one system, `Fall 2026` in another, and `202608`
in a third. The reference table can hold a column for each representation that
appears in your source systems:

| sort_key | code | name        | yyyym_start | source_system_key       |
|----------|------|-------------|-------------|-------------------------|
| 1        | fa25 | Fall 2025   | 202508      | 2025-26_1_08_Fall       |
| 4        | fa26 | Fall 2026   | 202608      | 2026-27_1_08_Fall       |
| 5        | sp27 | Spring 2027 | 202701      | 2026-27_2_01_Spring     |

When source data arrives with an unfamiliar key, you join on whichever synonym
column matches. After the join, all subsequent work uses the canonical columns
(`sort_key`, `name`, `mid_date`, etc.) regardless of what the source provided.


## The pattern in three steps

**Step 1 — Join.** Attach the reference table to your data on whatever key
the source data provides. The result is your original data with `sort_key`,
`name`, `start_date`, `end_date`, `mid_date`, and `ay` added as new columns.

**Step 2 — Sort.** Sort the combined table by `sort_key` ascending. This
produces chronological order without any tool needing to understand period
names.

**Step 3 — Use the right column for display.** When producing a report or
figure, use the `name` column for labels — never the raw code or numeric key.
For discrete axes, use `name` as the category. For continuous axes, use
`mid_date` as the position and `name` as the label.

The computation columns (`sort_key`, `start_date`, `end_date`) can be hidden
from the final output. The audience sees only `name`.


---

## In Excel

**Building the reference table.** Put the reference table on a dedicated sheet
(e.g., named `periods`). Give the table a defined name via Formulas → Define
Name, or convert it to a Table (Insert → Table) so it can be referenced as
`periods[sort_key]`, `periods[name]`, etc.

**Joining (XLOOKUP).** In your data sheet, add helper columns that pull from
the reference table using XLOOKUP (Excel 365) or VLOOKUP (older versions):

```
=XLOOKUP(A2, periods[code], periods[sort_key])
=XLOOKUP(A2, periods[code], periods[name])
=XLOOKUP(A2, periods[code], periods[mid_date])
```

With VLOOKUP, reference the column by position number and always use `FALSE`
as the fourth argument to force an exact match:

```
=VLOOKUP(A2, periods, 2, FALSE)   ' returns sort_key (column 2)
=VLOOKUP(A2, periods, 3, FALSE)   ' returns name (column 3)
```

**Sorting.** Sort the data sheet by the `sort_key` helper column (Data → Sort,
choose the sort_key column, Smallest to Largest). The `name` column will then
appear in chronological order.

**Human-readable labels in charts.** After sorting by `sort_key`, create the
chart from the data. In the chart's Select Data dialog, point the horizontal
axis labels at the `name` column rather than the `code` or `sort_key` column.
The chart will display "Fall 2026", "Spring 2027", etc. in the correct order.

For continuous date axes, use the `mid_date` column as the x-values of the
data series, then use the "Value from Cells" option under Format Data Labels
to pull display text from the `name` column.


---

## In R (base or dplyr)

**The join.**

```r
# With dplyr
library(dplyr)

data |>
  left_join(periods, by = "code")

# Base R
merge(data, periods, by = "code", all.x = TRUE)
```

After the join, `sort_key`, `name`, `mid_date`, etc. are available as
regular columns.

**Sorting.**

```r
data |>
  left_join(periods, by = "code") |>
  arrange(sort_key)
```

**Human-readable labels in ggplot2.** For a discrete axis, convert `name`
to an ordered factor whose levels follow `sort_key` order — this locks in
the correct axis sequence regardless of data order.

Base R:

```r
data |>
  left_join(periods, by = "code") |>
  arrange(sort_key) |>
  mutate(name_fct = factor(name, levels = unique(name), ordered = TRUE)) |>
  ggplot(aes(x = name_fct, y = value)) +
  geom_col()
```

With `forcats` (tidyverse): `fct_reorder()` sets factor levels by the values
of a second variable, so the levels of `name` are ordered by `sort_key`
without an explicit `arrange()` first:

```r
library(forcats)

data |>
  left_join(periods, by = "code") |>
  mutate(name_fct = fct_reorder(name, sort_key)) |>
  ggplot(aes(x = name_fct, y = value)) +
  geom_col()
```

For a continuous date axis, use `mid_date` as the x position and `name` as
the label:

```r
data |>
  left_join(periods, by = "code") |>
  ggplot(aes(x = mid_date, y = value)) +
  geom_line() +
  geom_text(aes(label = name), vjust = -0.5) +
  scale_x_date()
```


---

## In Python (pandas)

**The join.**

```python
import pandas as pd

data.merge(periods, on="code", how="left")
```

**Sorting.**

```python
(data
  .merge(periods, on="code", how="left")
  .sort_values("sort_key")
)
```

**Human-readable labels in matplotlib / seaborn.** Convert `name` to a
Categorical with the correct order, which controls axis order in all
pandas-aware plotting libraries:

```python
df = data.merge(periods, on="code", how="left").sort_values("sort_key")

df["name"] = pd.Categorical(
    df["name"],
    categories=df["name"].unique(),  # already in sort_key order
    ordered=True
)

import seaborn as sns
sns.barplot(data=df, x="name", y="value")
```

For a continuous date axis, use `mid_date` as the x position:

```python
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

fig, ax = plt.subplots()
ax.plot(df["mid_date"], df["value"])
for _, row in df.iterrows():
    ax.text(row["mid_date"], row["value"], row["name"],
            ha="center", va="bottom", fontsize=8)
ax.xaxis.set_major_formatter(mdates.DateFormatter("%b %Y"))
```


---

## In SQL

**The join.**

```sql
SELECT
    d.*,
    p.sort_key,
    p.name,
    p.start_date,
    p.end_date,
    p.mid_date,
    p.ay
FROM data d
LEFT JOIN periods p ON d.code = p.code
ORDER BY p.sort_key;
```

In SQL the sort and join happen in the same query. Results arrive in
chronological order with the `name` column ready for display. Downstream
tools (reporting software, BI dashboards) that consume the query output
receive the data pre-sorted with human-readable labels already attached.


---

## What this approach does not solve

The reference table approach requires the table to be built and maintained.
Someone must define the period dates, compute the midpoints, and extend the
table when new periods are added. It also does not prevent a colleague from
accidentally sorting by period name instead of sort_key, or from creating a
chart before the join has been applied.

These are coordination problems, not technical ones. The table approach makes
correct behavior straightforward; it cannot make incorrect behavior impossible.
