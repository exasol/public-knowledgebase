--=================================================
-- Directions for using this SQL
--=================================================
-- User changes are required for estimation results. 
-- Without making changes, the as-is sql will
-- predict expanding by 1 node.
---------------------------------------------------
-- What to change
---------------------------------------------------
-- There are 2 lines to change. Both are identical.
-- Look for this line:
---  ==> NEWNODE as (select nodes + 1  as NEWNODE_CNT from CURRNODE)
--
-- Change the (select nodes + 1 as NEWNODE_CNT from CURRNODE)
-- to:
-- (select nodes + <additional nodes to add> as NEWNODE_CNT from CURRNODE).
--------------------------------------------------
-- Example:
--------------------------------------------------
--  Assuming we currently are using 4 nodes and 
--  wish to expand to 6, our sql changes would be
--  to increase the current node count by 2 (6 -4 = 2),
--  so our change would be:
--
--  (select nodes + 2 as NEWNODE_CNT from CURRNODE)
--
--------------------------------------------------
-- Caveat
--------------------------------------------------
-- This SQL was designed to assist adding additional
-- nodes, NOT reducing them. Please recruit
-- Exasol Support if you planning on reducing
-- the number of existing nodes.
--================================================
-- BEGIN SQL
--================================================
------------------------------------------------------------------------------
-- Step 1
------------------------------------------------------------------------------

/*snapshot execution*/ With CURRNODE as (select nodes from exa_system_events
   where measure_time = (select max(measure_time) from exa_system_events)
   limit 1
),
NEWNODE as (select nodes + 1  as NEWNODE_CNT from CURRNODE)

select
    *
from
    (
        select
            cast(sum(t0.OVERALL_SECONDS) as dec(9)) OVERALL_SECONDS,
            cast(sum(t0.DELETE_REORG_SECONDS) as dec(9)) DELETE_SECONDS,
            cast(sum(t0.DISTRIBUTE_SECONDS) as dec(9)) DISTRIBUTE_SECONDS,
            cast(sum(t0.INDEX_REBUILD_SECONDS) as dec(9)) INDEX_REBUILD_SECONDS,
            cast(sum(t0.TABLE_SECONDS) as dec(9)) TABLE_SECONDS
        from
            (
                select
                    t1.SCHEMA_NAME,
                    t1.TABLE_NAME,
                    t1.DELETE_REORG_SECONDS + t1.DISTRIBUTE_SECONDS + t1.INDEX_REBUILD_SECONDS + t1.TABLE_SECONDS as OVERALL_SECONDS,
                    t1.DELETE_REORG_SECONDS,
                    t1.DISTRIBUTE_SECONDS,
                    t1.INDEX_REBUILD_SECONDS,
                    t1.TABLE_SECONDS
                from
                    (
                        select
                            coalesce(s1.S1_SN, s2.S2_SN, s3.S3_SN, s4.S4_SN) SCHEMA_NAME,
                            coalesce(s1.S1_TN, s2.S2_TN, s3.S3_TN, s4.S4_TN) TABLE_NAME,
                            zeroifnull(s1.DELETE_REORG_SECONDS) DELETE_REORG_SECONDS,
                            zeroifnull(s2.DISTRIBUTE_SECONDS) DISTRIBUTE_SECONDS,
                            zeroifnull(s3.INDEX_REBUILD_SECONDS) INDEX_REBUILD_SECONDS,
                            zeroifnull(s4.TABLE_SECONDS) TABLE_SECONDS
                        from
                                (
                                    select
                                        obs.ROOT_NAME as S1_SN,
                                        obs.OBJECT_NAME as S1_TN,
                                        cast(
                                            zeroifnull(
                                                sum(obs.RAW_OBJECT_SIZE) / 1024 / 1024 / 50 / (select nodes from CURRNODE)
                                            ) as dec(18, 1)
                                        ) DELETE_REORG_SECONDS
                                    from
                                        EXA_DBA_OBJECT_SIZES obs
                                    where
                                        (obs.ROOT_NAME, obs.OBJECT_NAME) in (
                                            select
                                                t.TABLE_SCHEMA,
                                                t.TABLE_NAME
                                            from
                                                EXA_DBA_TABLES t
                                            where
                                            	t.DELETE_PERCENTAGE > 0.01
                                                
                                        )
                                    group by
                                        1,
                                        2
                                ) S1
                            full outer join
                                (
                                    select
                                        obs.ROOT_NAME as S2_SN,
                                        obs.OBJECT_NAME as S2_TN,
                                        cast(
                                            zeroifnull(
                                                sum(obs.RAW_OBJECT_SIZE) / 1024 / 1024 / 35 / (select NEWNODE_CNT from NEWNODE)
                                            ) as dec(18, 1)
                                        ) DISTRIBUTE_SECONDS
                                    from
                                        EXA_DBA_OBJECT_SIZES obs
                                    where
                                        obs.OBJECT_TYPE = 'TABLE'
                                        and not obs.OBJECT_IS_VIRTUAL
                                    group by
                                        1,
                                        2
                                ) S2
                            on
                                s1.S1_SN = s2.S2_SN and
                                s1.S1_TN = s2.S2_TN
                            full outer join
                                (
                                    select
                                        i.INDEX_SCHEMA as S3_SN,
                                        i.INDEX_TABLE as S3_TN,
                                        cast(
                                            zeroifnull(
                                                sum(i.RAW_OBJECT_SIZE) / 1024 / 1024 / 60 / (select NEWNODE_CNT from NEWNODE)
                                            ) as dec(18, 1)
                                        ) INDEX_REBUILD_SECONDS
                                    from
                                        "$EXA_INDICES" i
                                    group by
                                        1,
                                        2
                                ) S3
                            on
                                coalesce(s1.S1_SN, s2.S2_SN)= s3.S3_SN and
                                coalesce(s1.S1_TN, s2.S2_TN)= s3.S3_TN
                            full outer join
                                (
                                    select
                                        t.TABLE_SCHEMA as S4_SN,
                                        t.TABLE_NAME as S4_TN,
                                        1.0 TABLE_SECONDS
                                    from
                                        EXA_DBA_TABLES t
                                    where
                                    	not t.TABLE_IS_VIRTUAL
                                ) S4
                            on
                                coalesce(s1.S1_SN, s2.S2_SN, s3.S3_SN)= s4.S4_SN and
                                coalesce(s1.S1_TN, s2.S2_TN, s3.S3_TN)= s4.S4_TN
                    ) t1
            ) t0
    );
------------------------------------------------------------------------------
-- Step 3
------------------------------------------------------------------------------
/*snapshot execution*/ With CURRNODE as (select nodes  from exa_system_events
   where measure_time = (select max(measure_time) from exa_system_events)
   limit 1
),
NEWNODE as (select nodes + 1  as NEWNODE_CNT from CURRNODE)
select
    REORGANIZE_SQL  || '     -- stream "' || STREAM || '": table estimate ' || trunc(OVERALL_SECONDS*1.5) || ' sec, stream time estimate ' || trunc(STREAM_TIME*1.5) || ' sec'
from
    (
        select
            T0.*,
            cast(
                sum(t0.OVERALL_SECONDS) over(
                    partition by
                        t0.STREAM
                    order by
                        t0.INDEX_REBUILD_SECONDS + t0.OVERALL_SECONDS asc
                ) as dec(9)
            ) as STREAM_TIME
        from
            (
                select
                    T1.*,
                    case
                        when
                            t1.PART_OVERALL / NULLIFZERO(t1.SUM_OVERALL) < 0.37
                        then
                            'small tables'
                        when
                            t1.PART_OVERALL / NULLIFZERO(t1.SUM_OVERALL) > 0.66
                        then
                            'indices'
                        else
                            'big tables'
                    end as STREAM
                from
                    (
                        select
                            T2.*,
                            cast(
                                sum(t2.OVERALL_SECONDS) over(
                                    order by
                                        t2.INDEX_REBUILD_SECONDS + t2.OVERALL_SECONDS asc
                                ) as dec(10, 1)
                            ) as PART_OVERALL,
                            cast(sum(t2.OVERALL_SECONDS) over() as dec(10, 1)) as SUM_OVERALL
                        from
                            (
                                select
                                    schema_name,
                                    table_name,
                                    'REORGANIZE TABLE "' || schema_name || '"."' || table_name || '";' as REORGANIZE_SQL,
                                    cast(sum(OVERALL_SECONDS) as dec(10, 1))       OVERALL_SECONDS,
                                    cast(sum(DELETE_REORG_SECONDS) as dec(10, 1))  DELETE_SECONDS,
                                    cast(sum(DISTRIBUTE_SECONDS) as dec(10, 1))    DISTRIBUTE_SECONDS,
                                    cast(sum(INDEX_REBUILD_SECONDS) as dec(10, 1)) INDEX_REBUILD_SECONDS,
                                    cast(sum(TABLE_SECONDS) as dec(10, 1))         TABLE_SECONDS
                                from
                                    (
                                        select
                                            SCHEMA_NAME,
                                            TABLE_NAME,
                                            DELETE_REORG_SECONDS + DISTRIBUTE_SECONDS + INDEX_REBUILD_SECONDS + TABLE_SECONDS as OVERALL_SECONDS,
                                            DELETE_REORG_SECONDS,
                                            DISTRIBUTE_SECONDS,
                                            INDEX_REBUILD_SECONDS,
                                            TABLE_SECONDS
                                        from
                                            (
                                                select
                                                    coalesce(s1.S1_SN, s2.S2_SN, s3.S3_SN, s4.S4_SN) SCHEMA_NAME,
                                                    coalesce(s1.S1_TN, s2.S2_TN, s3.S3_TN, s4.S4_TN) TABLE_NAME,
                                                    zeroifnull(s1.DELETE_REORG_SECONDS)     DELETE_REORG_SECONDS,
                                                    zeroifnull(s2.DISTRIBUTE_SECONDS)       DISTRIBUTE_SECONDS,
                                                    zeroifnull(s3.INDEX_REBUILD_SECONDS)    INDEX_REBUILD_SECONDS,
                                                    zeroifnull(s4.TABLE_SECONDS)            TABLE_SECONDS
                                                from
                                                        (
                                                            select
                                                                obs.ROOT_NAME as S1_SN,
                                                                obs.OBJECT_NAME as S1_TN,
                                                                cast(
                                                                    zeroifnull(
                                                                        sum(obs.RAW_OBJECT_SIZE) / 1024 / 1024 / 50 / (select nodes from CURRNODE)
                                                                    ) as dec(18, 1)
                                                                ) DELETE_REORG_SECONDS
                                                            from
                                                                EXA_DBA_OBJECT_SIZES obs
                                                            where
                                                                (obs.ROOT_NAME, obs.OBJECT_NAME) in (
                                                                    select
                                                                        t.TABLE_SCHEMA,
                                                                        t.TABLE_NAME
                                                                    from
                                                                        EXA_DBA_TABLES t
                                                                    where
                                                                        t.DELETE_PERCENTAGE > 0.01
                                                                )
                                                            group by
                                                                1,
                                                                2
                                                        ) S1
                                                    full outer join
                                                        (
                                                            select
                                                                obs.ROOT_NAME as S2_SN,
                                                                obs.OBJECT_NAME as S2_TN,
                                                                cast(
                                                                    zeroifnull(
                                                                        sum(obs.RAW_OBJECT_SIZE) / 1024 / 1024 / 35 / (select NEWNODE_CNT from NEWNODE)
                                                                    ) as dec(18, 1)
                                                                ) DISTRIBUTE_SECONDS
                                                            from
                                                                EXA_DBA_OBJECT_SIZES obs
                                                            where 
                                                                obs.OBJECT_TYPE = 'TABLE'
                                                                and not obs.OBJECT_IS_VIRTUAL
                                                            group by
                                                                1,
                                                                2
                                                        ) S2
                                                    on
                                                        s1.S1_SN = s2.S2_SN and
                                                        s1.S1_TN = s2.S2_TN
                                                    full outer join
                                                        (
                                                            select
                                                                i.INDEX_SCHEMA as S3_SN,
                                                                i.INDEX_TABLE as S3_TN,
                                                                cast(
                                                                    zeroifnull(
                                                                        sum(i.RAW_OBJECT_SIZE) / 1024 / 1024 / 60 / (select NEWNODE_CNT from NEWNODE)
                                                                    ) as dec(18, 1)
                                                                ) INDEX_REBUILD_SECONDS
                                                            from
                                                                "$EXA_INDICES" i
                                                            group by
                                                                1,
                                                                2
                                                        ) S3
                                                    on
                                                        coalesce(s1.S1_SN, s2.S2_SN)= s3.S3_SN and
                                                        coalesce(s1.S1_TN, s2.S2_TN)= s3.S3_TN
                                                    full outer join
                                                        (
                                                            select
                                                                t.TABLE_SCHEMA as S4_SN,
                                                                t.TABLE_NAME as S4_TN,
                                                                1.0 as TABLE_SECONDS
                                                            from
                                                                EXA_DBA_TABLES t
                                                            where
                                                            	not t.TABLE_IS_VIRTUAL
                                                        ) S4
                                                    on
                                                        coalesce(s1.S1_SN, s2.S2_SN, s3.S3_SN)= s4.S4_SN and
                                                        coalesce(s1.S1_TN, s2.S2_TN, s3.S3_TN)= s4.S4_TN
                                            )
                                    )
                                group by
                                    1,
                                    2,
                                    3
                            ) T2
                    ) T1
            ) T0
    )
order by
    STREAM,
    STREAM_TIME;