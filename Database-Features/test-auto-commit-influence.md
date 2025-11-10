# Test Auto-commit Influence

** Problem

```sql
select
 
        to_char(start_time, 'yyyy-mm-dd hh24') as dtime
        , next_COMMAND_ID
        , count(*) as stmt_count
        --, sum(DURATION) SUM_DURATION
        , round(avg(DURATION),1) AVG_DURATION
        , MEDIAN(DURATION) MEDIAN_DURATION
        , min(DURATION) MIN_DURATION
        , max(DURATION) MAx_DURATION

from

    (SELECT a1.start_time, SECONDS_BETWEEN(a1.stop_time,a1.start_time) as duration,
     CASE WHEN a2.COMMAND_ID = 44 THEN 'COMMIT'
          WHEN a2.COMMAND_ID = 21 THEN 'CREATE VIEW'
          ELSE 'OTHER'
      END
     as next_COMMAND_ID--a1.SESSION_ID, a1.stmt_id, a2.SESSION_ID, a2.stmt_id
     FROM "$EXA_STATS_AUDIT_SQL" a1 JOIN "$EXA_STATS_AUDIT_SQL" a2
     ON
      a1.SESSION_ID = a2.SESSION_ID
      AND a1.stmt_id = a2.stmt_id-1
    WHERE 1=1
     AND    a1.COMMAND_ID  = 21        

        --AND COMMAND_NAME='DROP VIEW'
     --   AND COMMAND_NAME='CREATE VIEW'
        --AND instr(upper(sql_text), '<-...>') >0
     -- AND instr(upper(sql_text), 'FORCE') >0
     -- AND instr(upper(a1.sql_text), 'FORCE VIEW <..>'
) >0
      
       )
      
     
      --AND START_TIME > '2025-03-01 00:00:00'
      group by to_char(start_time, 'yyyy-mm-dd hh24'), 2
      ORDER BY 1,2;
      --'yyyy-mm-dd hh24'
        ) a
order by
        --5 desc;
```
        2;
