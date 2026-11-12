# Identifying Recurring CPU Utilization Patterns

## Use Case

How can we determine whether high CPU utilization occurs regularly on specific weekdays or hours, and reliably distinguish recurring workload patterns from isolated, one-off CPU peaks?

This analysis helps identify whether high CPU utilization is caused by:

- scheduled batch jobs;
- recurring reporting activities;
- regular user workloads;
- maintenance processes; or
- isolated, unexpected events.

The analysis uses hourly CPU measurements from `EXA_MONITOR_HOURLY` and evaluates CPU threshold breaches across several aggregation levels. Exasol documents `CPU_AVG` as the average CPU utilization, in percent, for the database instance, and `INTERVAL_START` as the beginning of the aggregation interval ([Exasol documentation: EXA_MONITOR_HOURLY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_monitor_hourly.htm)).

## SQL Solution

```sql
WITH BASE_DATA AS (
    SELECT
        -- Normalize the weekday name to English
        TRIM(TO_CHAR(
            INTERVAL_START,
            'DAY',
            'NLS_DATE_LANGUAGE=ENG'
        )) AS DAY_NAME,

        -- Assign a chronological weekday index
        CASE TRIM(TO_CHAR(
            INTERVAL_START,
            'DAY',
            'NLS_DATE_LANGUAGE=ENG'
        ))
            WHEN 'MONDAY'    THEN 1
            WHEN 'TUESDAY'   THEN 2
            WHEN 'WEDNESDAY' THEN 3
            WHEN 'THURSDAY'  THEN 4
            WHEN 'FRIDAY'    THEN 5
            WHEN 'SATURDAY'  THEN 6
            WHEN 'SUNDAY'    THEN 7
        END AS DAY_INDEX,

        -- Extract the hour from the timestamp
        EXTRACT(HOUR FROM INTERVAL_START) AS HR,

        CPU_AVG
    FROM EXA_MONITOR_HOURLY
),

AGGREGATED_DATA AS (
    SELECT
        /*
         * Identify the aggregation level explicitly:
         *
         * WEEKDAY_HOUR:
         *     Specific weekday and hour, for example Monday at 10:00
         *
         * WEEKDAY:
         *     All hours for one weekday
         *
         * HOUR:
         *     One specific hour across all weekdays
         *
         * OVERALL:
         *     The complete monitoring period
         */
        CASE
            WHEN GROUPING(DAY_NAME) = 1
             AND GROUPING(HR) = 1
                THEN 'OVERALL'

            WHEN GROUPING(DAY_NAME) = 1
             AND GROUPING(HR) = 0
                THEN 'HOUR'

            WHEN GROUPING(DAY_NAME) = 0
             AND GROUPING(HR) = 1
                THEN 'WEEKDAY'

            ELSE 'WEEKDAY_HOUR'
        END AS ANALYSIS_LEVEL,

        DAY_NAME,
        DAY_INDEX,
        HR,

        -- Number of hourly CPU measurements in the aggregation bucket.
        -- EXA_MONITOR_HOURLY is expected to contain a CPU value for each row.
        COUNT(*) AS TOTAL_MEASUREMENTS,

        -- Average and maximum CPU utilization for the aggregation bucket
        AVG(CPU_AVG) AS AVG_CPU,
        MAX(CPU_AVG) AS MAX_CPU,

        -- Threshold breach counts
        SUM(CASE WHEN CPU_AVG > 40 THEN 1 ELSE 0 END) AS CPU_GT_40,
        SUM(CASE WHEN CPU_AVG > 50 THEN 1 ELSE 0 END) AS CPU_GT_50,
        SUM(CASE WHEN CPU_AVG > 60 THEN 1 ELSE 0 END) AS CPU_GT_60,
        SUM(CASE WHEN CPU_AVG > 70 THEN 1 ELSE 0 END) AS CPU_GT_70,
        SUM(CASE WHEN CPU_AVG > 80 THEN 1 ELSE 0 END) AS CPU_GT_80,
        SUM(CASE WHEN CPU_AVG > 90 THEN 1 ELSE 0 END) AS CPU_GT_90

    FROM BASE_DATA
    GROUP BY GROUPING SETS (
        -- Specific weekday/hour combinations
        (DAY_NAME, DAY_INDEX, HR),

        -- Weekday summaries
        (DAY_NAME, DAY_INDEX),

        -- Hour summaries across all weekdays
        (HR),

        -- Overall summary
        ()
    )
)

SELECT
    -- Identifies the type of summary represented by the row
    ANALYSIS_LEVEL,

    CASE
        WHEN ANALYSIS_LEVEL = 'OVERALL'
            THEN 'TOTAL'
        WHEN ANALYSIS_LEVEL = 'HOUR'
            THEN 'ALL_WEEKDAYS'
        ELSE DAY_NAME
    END AS WEEKDAY,

    CASE
        WHEN ANALYSIS_LEVEL IN ('WEEKDAY_HOUR', 'HOUR')
            THEN HR
        ELSE NULL
    END AS "HOUR_",

    -- Number of hourly measurements represented by this row
    TOTAL_MEASUREMENTS,

    -- Rounded descriptive CPU statistics
    ROUND(AVG_CPU, 2) AS AVG_CPU,
    MAX_CPU,

    -- Absolute number of measurements above each CPU threshold
    CPU_GT_40,
    CPU_GT_50,
    CPU_GT_60,
    CPU_GT_70,
    CPU_GT_80,
    CPU_GT_90,

    -- Percentage of measurements above each CPU threshold
    ROUND(100.0 * CPU_GT_40 / TOTAL_MEASUREMENTS, 2)
        AS PCT_GT_40,

    ROUND(100.0 * CPU_GT_50 / TOTAL_MEASUREMENTS, 2)
        AS PCT_GT_50,

    ROUND(100.0 * CPU_GT_60 / TOTAL_MEASUREMENTS, 2)
        AS PCT_GT_60,

    ROUND(100.0 * CPU_GT_70 / TOTAL_MEASUREMENTS, 2)
        AS PCT_GT_70,

    ROUND(100.0 * CPU_GT_80 / TOTAL_MEASUREMENTS, 2)
        AS PCT_GT_80,

    ROUND(100.0 * CPU_GT_90 / TOTAL_MEASUREMENTS, 2)
        AS PCT_GT_90

FROM AGGREGATED_DATA

ORDER BY
    CASE ANALYSIS_LEVEL
        WHEN 'WEEKDAY_HOUR' THEN 1
        WHEN 'WEEKDAY'      THEN 2
        WHEN 'HOUR'         THEN 3
        WHEN 'OVERALL'      THEN 4
    END,

    COALESCE(DAY_INDEX, 8),
    "HOUR_" NULLS LAST;
```

## How the Analysis Works

The query uses `GROUPING SETS` to analyze the CPU data at four different levels. The `GROUPING` function identifies whether a result row is a regular grouping row or a super-aggregate row generated by `GROUPING SETS`, `ROLLUP`, or `CUBE` ([Exasol documentation: GROUPING](https://docs.exasol.com/db/latest/sql_references/functions/alphabeticallistfunctions/grouping%5B_id%5D.htm)).

| Aggregation level | Purpose |
|---|---|
| `WEEKDAY_HOUR` | Identifies specific recurring periods, such as Mondays at 10:00 |
| `WEEKDAY` | Shows the overall CPU behavior for each weekday |
| `HOUR` | Shows whether a specific hour is highly utilized regardless of the weekday |
| `OVERALL` | Provides a baseline for the complete monitoring period |

The `WEEKDAY_HOUR` level can identify patterns such as:

- Mondays at 08:00;
- weekdays between 09:00 and 11:00;
- Fridays at 18:00; or
- weekends during scheduled maintenance.

The `WEEKDAY` and `HOUR` summaries provide context and help determine whether the pattern is specific to one combination or part of a broader trend.

## Metrics Used

### Threshold Counts

The query counts how often the average CPU utilization exceeded the following thresholds:

- 40%;
- 50%;
- 60%;
- 70%;
- 80%; and
- 90%.

For example:

```text
CPU_GT_80 = 10
```

means that ten measurements in the respective aggregation bucket had a CPU utilization greater than 80%.

### Total Measurements

`TOTAL_MEASUREMENTS` contains the number of hourly measurements represented by the aggregation bucket.

This value is used as the denominator for the percentage calculations. Because `EXA_MONITOR_HOURLY` is expected to contain a CPU value for each measurement, the threshold percentages can be calculated directly from this count.

### Average and Maximum CPU

The following columns provide additional context:

- `AVG_CPU` shows the average CPU utilization in the bucket.
- `MAX_CPU` shows the highest recorded CPU utilization in the bucket.

### Threshold Percentages

The percentage columns show how frequently a threshold was exceeded relative to the total number of hourly measurements.

For example:

```text
PCT_GT_80 = 75
```

means that 75% of the measurements in the bucket exceeded 80% CPU utilization.

## Why Percentages Are Important

Because the hourly monitoring data contains the same number of measurements for comparable weekday/hour buckets, raw threshold counts can be compared directly within the same aggregation level. In these cases, the percentages provide the same information in normalized form. They remain useful for readability and when comparing aggregation levels with different totals, such as weekday summaries, hour summaries, and the overall total.

| Bucket | CPU measurements above 80% | Total measurements | Breach rate |
|---|---:|---:|---:|
| Monday at 10:00 | 10 | 10 | 100% |
| Tuesday at 14:00 | 10 | 500 | 2% |

Both buckets contain the same number of measurements, so the higher raw count directly indicates the stronger high-CPU pattern. The percentage expresses the same difference in normalized form.

For this reason, threshold counts should always be evaluated together with:

- `TOTAL_MEASUREMENTS`;
- `PCT_GT_80` or `PCT_GT_90`;
- `AVG_CPU`; and
- `MAX_CPU`.

## Identifying Recurring Workload Patterns

A recurring workload pattern is more likely when:

- the same weekday/hour combination has a high threshold percentage;
- CPU utilization is repeatedly high across the monitoring period;
- the bucket contains a sufficient number of measurements;
- the average CPU utilization is also elevated;
- the weekday and hour summaries show a similar trend; and
- the pattern corresponds to a known scheduled activity.

### Example

A result such as the following would indicate a likely recurring pattern:

| Weekday | Hour | Measurements | CPU > 80% | Percentage |
|---|---:|---:|---:|---:|
| MONDAY | 10 | 12 | 11 | 91.67% |
| TUESDAY | 10 | 12 | 10 | 83.33% |
| WEDNESDAY | 10 | 12 | 11 | 91.67% |

This pattern suggests that the workload occurs regularly around 10:00 on weekdays.

Possible causes could include:

- scheduled ETL jobs;
- reporting workloads;
- data refreshes;
- backups;
- data exports; or
- recurring application activity.

## Identifying Isolated CPU Peaks

An isolated CPU peak is more likely when:

- the threshold count is low;
- the threshold percentage is low;
- the high utilization occurs in only one weekday/hour bucket;
- the average CPU utilization remains relatively low;
- the maximum CPU is high but the threshold count is small; and
- the weekday and hour summaries do not confirm the same pattern.

### Example

| Weekday | Hour | Measurements | CPU > 80% | Percentage |
|---|---:|---:|---:|---:|
| THURSDAY | 14 | 250 | 2 | 0.80% |

This result indicates that CPU utilization exceeded 80% only twice out of 250 measurements. It is more consistent with isolated activity than with a recurring workload.

Possible causes could include:

- an ad-hoc query;
- an unusual report;
- a temporary data load;
- a transient infrastructure problem; or
- a short-lived system event.

## Important Limitation

The query aggregates the complete monitoring period. Therefore, a threshold count alone cannot determine how the breaches were distributed over time.

For example, ten breaches could mean:

- one breach on each of ten different weeks; or
- ten breaches occurring on a single day.

These scenarios have the same threshold count but represent very different operational patterns.

To prove recurrence, the analysis should additionally group the data by:

- calendar date;
- calendar week;
- weekday/hour combination; and
- threshold status.

This makes it possible to determine how many distinct weeks contained a high-CPU event.

## Second Analysis: Validation Across Calendar Weeks

The first analysis identifies suspicious weekday/hour combinations across the complete monitoring period. A second analysis is required to determine whether the threshold breaches are distributed across several calendar weeks.

The objective is to answer:

> In how many different weeks did this weekday/hour combination exceed the selected CPU threshold?

A pattern that exceeds 80% CPU in ten different weeks is much more likely to be recurring than a pattern that exceeds 80% CPU ten times during one week.

### SQL Query

The following query first creates one row per calendar week, weekday, and hour. It then counts how many different weeks contained a CPU measurement above 80%.

`DATE_TRUNC('week', INTERVAL_START)` is used to calculate the beginning of the calendar week. In Exasol, the first day of the week is controlled by the `NLS_FIRST_DAY_OF_WEEK` session parameter ([Exasol documentation: DATE_TRUNC](https://docs.exasol.com/db/latest/sql_references/functions/alphabeticallistfunctions/date_trunc.htm)).

```sql
-- Ensure that calendar weeks start on Monday
ALTER SESSION SET NLS_FIRST_DAY_OF_WEEK = 'MONDAY';
```

```sql
WITH BASE_DATA AS (
    SELECT
        -- Calculate the start date of the calendar week
        DATE_TRUNC('week', INTERVAL_START) AS WEEK_START,

        -- Extract the weekday name for recurring-pattern comparison
        TRIM(TO_CHAR(
            INTERVAL_START,
            'DAY',
            'NLS_DATE_LANGUAGE=ENG'
        )) AS DAY_NAME,

        -- Assign a chronological weekday index for the final sorting
        CASE TRIM(TO_CHAR(
            INTERVAL_START,
            'DAY',
            'NLS_DATE_LANGUAGE=ENG'
        ))
            WHEN 'MONDAY'    THEN 1
            WHEN 'TUESDAY'   THEN 2
            WHEN 'WEDNESDAY' THEN 3
            WHEN 'THURSDAY'  THEN 4
            WHEN 'FRIDAY'    THEN 5
            WHEN 'SATURDAY'  THEN 6
            WHEN 'SUNDAY'    THEN 7
        END AS DAY_INDEX,

        -- Extract the hour of the day
        EXTRACT(HOUR FROM INTERVAL_START) AS HR,

        -- Hourly average CPU utilization
        CPU_AVG

    FROM EXA_MONITOR_HOURLY

    -- If required, restrict the analysis to one cluster:
    -- WHERE CLUSTER_NAME = 'MY_CLUSTER'
),

WEEKLY_BUCKETS AS (
    SELECT
        WEEK_START,
        DAY_NAME,
        DAY_INDEX,
        HR,

        -- Number of measurements for this weekday/hour in this week
        COUNT(*) AS MEASUREMENTS_IN_WEEK,

        -- Number of measurements above the selected 80% threshold
        SUM(CASE WHEN CPU_AVG > 80 THEN 1 ELSE 0 END)
            AS CPU_GT_80_IN_WEEK,

        -- CPU statistics for this weekday/hour in this week
        ROUND(AVG(CPU_AVG), 2) AS AVG_CPU_IN_WEEK,
        MAX(CPU_AVG) AS MAX_CPU_IN_WEEK

    FROM BASE_DATA

    /*
     * Aggregate by calendar week before counting recurring weeks.
     * This ensures that a week is counted once, even if the source
     * contains more than one measurement for the same weekday/hour.
     */
    GROUP BY
        WEEK_START,
        DAY_NAME,
        DAY_INDEX,
        HR
)

SELECT
    -- Weekday/hour combination being analyzed
    DAY_NAME AS WEEKDAY,
    HR AS "HOUR_",

    -- Number of calendar weeks containing data for this combination
    COUNT(*) AS WEEKS_OBSERVED,

    -- Number of different weeks with at least one measurement above 80%
    SUM(
        CASE
            WHEN CPU_GT_80_IN_WEEK > 0 THEN 1
            ELSE 0
        END
    ) AS WEEKS_GT_80,

    -- Percentage of observed weeks containing an above-80% measurement
    ROUND(
        100.0 * SUM(
            CASE
                WHEN CPU_GT_80_IN_WEEK > 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS PCT_WEEKS_GT_80,

    -- Total number of hourly measurements above 80%
    SUM(CPU_GT_80_IN_WEEK) AS MEASUREMENTS_GT_80,

    -- Average and maximum CPU across the weekly buckets
    ROUND(AVG(AVG_CPU_IN_WEEK), 2) AS AVG_CPU,
    MAX(MAX_CPU_IN_WEEK) AS MAX_CPU

FROM WEEKLY_BUCKETS

GROUP BY
    DAY_NAME,
    DAY_INDEX,
    HR

ORDER BY
    DAY_INDEX,
    HR;
```

### Running the Query

The query can be executed in any Exasol SQL client, for example:

- DBeaver;
- EXAplus; or
- another application using the Exasol JDBC or ODBC driver.

No additional analysis tool is required. A dashboard or charting tool can be used afterwards to visualize the recurring weekday/hour combinations.

### Interpreting the Results

| Column | Meaning |
|---|---|
| `WEEKS_OBSERVED` | Number of calendar weeks containing data for the weekday/hour combination |
| `WEEKS_GT_80` | Number of different weeks with at least one measurement above 80% CPU |
| `PCT_WEEKS_GT_80` | Percentage of observed weeks containing an above-80% measurement |
| `MEASUREMENTS_GT_80` | Total number of hourly measurements above 80% CPU |
| `AVG_CPU` | Average CPU utilization across the weekly buckets |
| `MAX_CPU` | Highest CPU utilization observed in the weekly buckets |

Example:

| Weekday | Hour | Weeks observed | Weeks above 80% | Percentage |
|---|---:|---:|---:|---:|
| MONDAY | 10 | 12 | 10 | 83.33% |
| TUESDAY | 14 | 12 | 1 | 8.33% |

`MONDAY 10:00` is likely a recurring pattern, while `TUESDAY 14:00` is more likely an isolated event.

## Related Documentation

### Exasol documentation and Knowledge Base

- [EXA_MONITOR_HOURLY – System Table](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_monitor_hourly.htm) – hourly aggregated monitoring data, including `INTERVAL_START`, `CPU_AVG`, and `CPU_MAX`.
- [EXA_MONITOR_DAILY – System Table](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_monitor_daily.htm) – daily aggregated monitoring data for broader long-term analysis.
- [GROUPING and GROUPING_ID](https://docs.exasol.com/db/latest/sql_references/functions/alphabeticallistfunctions/grouping%5B_id%5D.htm) – distinguishes detail rows from super-aggregate rows.
- [Monitoring – On Premise](https://docs.exasol.com/db/latest/administration/on-premise/monitoring.htm) – Exasol monitoring, health messages, and configurable monitoring thresholds.
- [Profiling](https://docs.exasol.com/db/7.1/database_concepts/profiling.htm) – correlates periods of high system CPU with query-level CPU, duration, memory, network, and execution-part information.
- [Verify CPU Settings](https://exasol.my.site.com/s/article/Verify-CPU-Settings?language=en_US) – Exasol Knowledge Base article related to CPU configuration verification.
- [Resource Management](https://exasol.my.site.com/s/article/Resource-Management?language=en_US) – Exasol Knowledge Base article related to controlling and investigating resource consumption.

### Related external documentation

- [Dynatrace: Seasonal baseline](https://docs.dynatrace.com/docs/dynatrace-intelligence/reference/ai-models/seasonal-baseline) – explains why recurring daily or weekly patterns should be incorporated into anomaly detection to avoid false positives.
- [Microsoft Learn: `series_decompose_anomalies()`](https://learn.microsoft.com/en-us/kusto/query/series-decompose-anomalies-function?view=microsoft-fabric) – describes a time-series approach for decomposing seasonal patterns and detecting anomalies.
- [Elementary Data: Seasonality](https://docs.elementary-data.com/data-tests/anomaly-detection-configuration/seasonality) – documents `day_of_week`, `hour_of_day`, and `hour_of_week` seasonality models, which are conceptually similar to the weekday/hour groupings used in this analysis.

These references support the following distinction:

- The SQL query provides a transparent, threshold-based descriptive analysis.
- Seasonal-baseline and anomaly-detection systems provide statistical models for automatically identifying deviations from an established recurring pattern.
- Exasol profiling can be used after a recurring time window has been identified to determine which queries or execution parts contributed to the CPU load.

## Conclusion

This analysis provides a structured way to identify recurring CPU utilization patterns.

High counts combined with high percentages and repeated occurrence across multiple weeks indicate a likely recurring workload. A small number of breaches with a low percentage and no supporting weekday/hour trend is more likely to represent an isolated CPU peak.

## Related Documentation

- [EXA_MONITOR_HOURLY – System Table](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_monitor_hourly.htm) – hourly aggregated monitoring data, including `INTERVAL_START`, `CPU_AVG`, and `CPU_MAX`.
- [EXA_MONITOR_DAILY – System Table](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_monitor_daily.htm) – daily aggregated monitoring data for broader long-term analysis.
- [GROUPING and GROUPING_ID](https://docs.exasol.com/db/latest/sql_references/functions/alphabeticallistfunctions/grouping%5B_id%5D.htm) – distinguishes detail rows from super-aggregate rows.
- [Monitoring – On Premise](https://docs.exasol.com/db/latest/administration/on-premise/monitoring.htm) – Exasol monitoring, health messages, and configurable monitoring thresholds.
- [Profiling](https://docs.exasol.com/db/7.1/database_concepts/profiling.htm) – correlates periods of high system CPU with query-level CPU, duration, memory, network, and execution-part information.
- [Verify CPU Settings](https://exasol.my.site.com/s/article/Verify-CPU-Settings?language=en_US) – Exasol Knowledge Base article related to CPU configuration verification.
- [Resource Management](https://exasol.my.site.com/s/article/Resource-Management?language=en_US) – Exasol Knowledge Base article related to controlling and investigating resource consumption.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
