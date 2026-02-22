# Handling Named Periods in Excel

Excel is the most common tool analysts reach for when working with
institutional period data, and experienced spreadsheet users have developed
practical workarounds for each aspect of the named period problem. This
document describes those approaches and their trade-offs.


## Sorting

### Custom Lists

Excel provides a Custom List feature (File → Options → Advanced → Edit Custom
Lists) that lets users define an explicit sort order for named text values.
Once a list such as Fall, Spring, Summer is registered, Excel's Sort dialog
offers it as an option under the Order dropdown. This works well for a single
analyst on a single machine.

The portability story is complicated. The list itself is stored in the local
computer's registry, not in the workbook, so a colleague on another machine
will not see it in their Custom Lists panel. However, when a sort using a
custom list is applied to a workbook, that sort configuration is saved with
the file and remains visible in the Sort dialog on another machine — the
recipient can re-apply it without needing to recreate the list. The practical
risk is that anyone who sorts the table by a different column, then wants to
restore the period order, may not know to look for the saved custom list sort.
Excel for Web does not support custom lists at all, which matters for teams
using browser-based Excel.

### Numeric prefix

Some analysts prefix period names with a number — "1 Fall", "2 Spring",
"3 Summer" — so that alphabetical sort produces the right sequence. This works
for period names alone but breaks down once years are involved: "Fall 2024"
and "Fall 2025" need different prefixes, leading to constructions like
"2024-3 Fall" that are even harder to read than the raw numeric codes they
were meant to replace.

### Helper column with VLOOKUP

The most portable formula-only approach is to keep human-readable names in
one column and maintain a separate helper column containing a numeric sort
key, populated with a VLOOKUP against a small reference table (period name →
sort number) using an exact match:

```
=VLOOKUP(A2, $SortTable$A:$B, 2, FALSE)
```

The `FALSE` argument is essential — it forces an exact match regardless of
the table's sort order. Sort the data table by this helper column, then hide
it. The approach travels with the workbook and works for any recipient, at the
cost of remembering to sort by the helper column rather than the name column.

### SORTBY + MATCH (Excel 365)

In modern Excel 365, the same logic can be expressed as a dynamic formula:

```
=SORTBY(data_range, MATCH(period_column, order_list, 0))
```

This updates automatically as data changes, but produces a separate sorted
output rather than sorting the original table in place.


## Charts

### Axis order

Excel charts inherit their category axis order directly from the order of rows
in the source data. There is no independent axis-sorting control for text
categories. Analysts typically sort the table by their helper column
immediately before refreshing the chart, or keep a separate chart-ready copy
of the data. A lesser-known option is to manually specify axis labels via the
Select Data dialog (right-click chart → Select Data → Edit Horizontal Axis
Labels), which points the axis labels to an arbitrary range — useful for small
static datasets where the source table order cannot be changed.

### Date axis auto-detection

A common gotcha: if the source data contains actual date values (start dates
of each period, for example), Excel will often automatically apply a date axis
rather than a category axis. A date axis spaces data points proportionally in
time and inserts gaps for missing periods — so a summer with no data appears
as blank space between Spring and Fall. This is usually not what analysts want
for period data. The fix is to right-click the axis, choose Format Axis, and
explicitly set Axis Type to Text Axis. This must be re-applied whenever the
chart is rebuilt from scratch.

### Displaying labels separately from sort keys

When the sort key is a numeric code (202608) or a prefixed string ("1 Fall"),
the chart will display that raw value as the axis label unless the analyst
redirects it. The standard fix is a two-column approach: one column holds the
sort key, a second holds the human-readable name, and the chart's axis is
pointed at the name column via Select Data.

For individual point or bar labels — as opposed to axis tick labels — Excel
2013 and later offer a "Value from Cells" option under Format Data Labels,
which lets each label pull its text from an arbitrary cell in the spreadsheet.
This is the cleanest way to show "Fall 2026" on a data marker while the
underlying series uses a numeric date value.

### Midpoint labels on a date axis

When a continuous date axis is needed, each period must be represented by a
single date. The start date is easiest to compute but crowds the label to the
left edge of each period. The standard technique for centering a label within
a span is:

1. Add a midpoint column: `= start + (end - start) / 2`
2. Add an invisible helper series whose x-values are the midpoints; set the
   series marker to none so no dot appears
3. Attach data labels to the invisible series using "Value from Cells" to pull
   the human-readable period name

The visible chart shows only the main series; the invisible series provides
the centered labels. This is fully dynamic — as dates change, label positions
recalculate — but requires maintaining the midpoint column and the helper
series, and rebuilding both whenever the chart structure changes.


## Fiscal year assignment

Determining which fiscal or academic year a date belongs to is a common
formula task. The standard approach uses an `IF` formula that checks the month
number of the date against the year-start month:

```
=IF(MONTH(A2)>=10, YEAR(A2), YEAR(A2)-1)
```

This computes the starting year of a US federal fiscal year (which begins in
October). More complex calendars — with year-start months other than October,
or with periods whose names change across years — require more elaborate
formulas or VLOOKUP tables.


## The overall pattern

Each workaround above addresses a single aspect of the problem in isolation.
The analyst must coordinate them manually: sort the data, populate the label
column, configure the chart axes, reapply after any data update. The
maintenance burden grows with the number of periods, the complexity of the
calendar, and the number of downstream outputs that share the same data.

For users whose needs outgrow these workarounds, Power Query and the Excel
Data Model offer more systematic solutions — but those tools require a level
of technical investment that puts them out of reach for most analysts working
with institutional period data.
