# Temperatures on the first day of each month across years.

This is a simple shell script to download the weather Canada data available online
and calculate the average temparatures for the first day of each month aggregated 
across years.

This is for Halifax, NS, Canada. It shows the aggregates for the years 2000 to 2024 inclusive. But you can easily change it for any other location and year range. Look in the script for hints on how to do that.

The code requires the [csvq command](https://mithrandie.github.io/csvq/), which 
provides a SQL like query over CSV files.

## Example

```
Aggregated temparatures in degrees celcius of the first day of the month
for the years 2000 to 2024 inclusive.

+-------+---------+---------+----------+--------+---------+
| month | avg_min | avg_max | avg_mean | lowest | highest |
+-------+---------+---------+----------+--------+---------+
| 01    |    -6.9 |     0.9 |       -3 |    -18 |    11.3 |
| 02    |    -9.9 |    -1.4 |     -5.7 |  -17.8 |     6.5 |
| 03    |    -8.7 |     0.5 |     -4.1 |  -17.1 |       8 |
| 04    |      -1 |     7.6 |      3.3 |   -7.8 |      16 |
| 05    |     1.8 |    10.9 |      6.4 |   -2.5 |    18.8 |
| 06    |     7.5 |    19.4 |     13.5 |      3 |    33.1 |
| 07    |    13.2 |    23.9 |     18.6 |      9 |      30 |
| 08    |    14.8 |    25.8 |     20.3 |     11 |    29.6 |
| 09    |    12.5 |    22.6 |     17.5 |    7.4 |    34.2 |
| 10    |     7.6 |    17.8 |     12.7 |    3.3 |      24 |
| 11    |     3.4 |    11.9 |      7.7 |   -3.9 |    19.1 |
| 12    |    -0.9 |     7.4 |      3.2 |  -10.7 |    15.3 |
+-------+---------+---------+----------+--------+---------+
```

## Thoughts

This is a very simple script that could eaily be improved by adding
command line options. For example, to extend it to look up the
weather station ID, and to set the year ranges for the aggregates.

Instead of using bash, a more appropriate language could be used. 