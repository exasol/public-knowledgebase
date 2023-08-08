# Skyline Tutorial: Energymap 
## Background

This article contains a basic tutorial for Exasol's Skyline feature.

## Task description and pre-requisites

As an analytical task for this tutorial, we assume finding "the most interesting" set of power stations among a large number of candidates. "Interesting" in our context shall be defined as "has high nominal output" and "is close to my location".

The data used here is derived from data publicly available at [http://www.energymap.info](http://www.energymap.info/)  
It contains information about power stations in Germany with a focus on renewable energy. The original data contains many attributes. For the sake of clarity, we removed columns that we considered not interesting for our purposes here.

Before starting, please download the accompanying file `"energymap.csv"` found at the the end of the article.

Let's begin by starting up EXAplus (or any SQL editor), connecting to some test database (maybe the Community Edition) and preparing the data for this tutorial.


```sql
create schema energymap_tutorial;

CREATE TABLE ENERGYMAP (
    CONSTRUCTION_DATE           DATE,
    ZIP                         DECIMAL(18,0),
    LOCATION                    VARCHAR(100) UTF8,
    ASSET_KEY                   VARCHAR(50) UTF8,
    GENERATOR_TYPE              VARCHAR(50) UTF8,
    NOMINAL_OUTPUT              DECIMAL(18,0),
    DSO                         VARCHAR(100) UTF8,
    GPSCOORD                    GEOMETRY
);
```

```sql
import into energymap from local csv file '[Path to where you put]/energymap.csv';
```
Before experimenting it is usually a good idea to turn off the query cache, as otherwise, performance may appear too good sometimes.


```sql
alter session set query_cache='off';
```
## Common approaches in SQL to achieve the task

As our location is roughly at GPS coordinates (49,10), as a first shot in the dark, we could try to check, if there is a power station at this position.


```sql
select * from energymap where st_x(gpscoord) = 49 and st_y(gpscoord) = 10; 
```
Well, it is no big surprise that we didn't get an answer. Let's consider all stations within a certain distance to the location of interest:


```sql
select asset_key,generator_type,location,nominal_output, st_distance('POINT(49 10)', gpscoord) as dist 
from energymap em where gpscoord is not null and local.dist < 3 
order by nominal_output desc; 
```
This is a lot of results to consider. When browsing the result set, we soon find power stations which are obviously not very interesting. For instance, the power station with the key E2026001HRA0GROM000000E0000100001 is farther away and less powerful than the power station with the key E3117701SCHAETZUNGSOLPROGNOSE2013. Furthermore, we cannot be sure whether or not we are missing a very powerful power station that is just beyond the distance of 3.

Probably we could somehow model the trade-off between nominal output and distance using some clever scoring function. Basically, low distance should give a high score as should high nominal output.  
Let's give it a try:


```sql
select asset_key,generator_type,location,nominal_output, st_distance('POINT(49 10)', em.gpscoord) as dist 
from energymap em where gpscoord is not null 
order by nominal_output + 100000/(1+10*local.dist) desc limit 10; 
```
Hint: In the result set viewer, you can choose to order the table by the column "NOMINAL_OUTPUT". Then you see that the above scoring function only selected power stations that either are very weak and very close or very powerful but far away.

Let's tune the scoring function to also include some power stations that are a little closer (and maybe not so powerful):


```sql
select asset_key,generator_type,location,nominal_output, st_distance('POINT(49 10)', em.gpscoord) as dist 
from energymap em  where gpscoord is not null 
order by nominal_output * 10000/(1+10*local.dist) desc limit 10; 
```
When ordering by "DIST" column, we see that we actually managed to get some power stations that are closer and have quite large output. But still, there are stations which are obviously not very interesting like the one with the key E2104101S160000000000020224700001, which is less powerful and farther away than other stations in the result set.  
Even worse, by arbitrarily limiting the result set to 10 elements, we cannot be sure that we haven't missed some other very interesting stations. On the other hand, if we do not somehow limit the size of the result set, we get all the elements of the energymap table which clearly is too much to consider manually.

...and so on

## Using Skyline to achieve the task

All the problems mentioned before can be avoided by considering only the Pareto Optimal power stations (see <http://en.wikipedia.org/wiki/Multi-objective_optimization>): We would like to only see those stations for which no other station exists that is closer and more powerful.

Exasol's Skyline feature implements this kind of query semantics. Via the SQL clause `PREFERRING` we can specify the trade-off between distance and nominal output. By connecting these attributes with PLUS we specify that both are of equal importance for us.


```sql
select asset_key,generator_type,location,nominal_output, st_distance('POINT(49 10)', gpscoord) as dist 
from energymap where gpscoord is not null  
PREFERRING LOW local.dist PLUS HIGH nominal_output; 
```
Now, we get a result set of only 17 elements. Please note that this is the complete and exact article. We did not have to specify a LIMIT clause and order by some scoring function. These 17 elements are all elements that are interesting for our task as we defined it above. This means that for every station not in the result set, there exists a station in the result set that is either closer or more powerful and no worse in any way.

By ordering the result set according to the column DIST or the column NOMINAL_OUTPUT the trade-off between distance and nominal output can easily be verified: The farther way a stations the higher its output. Please note that – theoretically – we could also use standard SQL to achieve the same result. But when trying to evaluate the "translation" of the Skyline query to standard SQL, you will find that it takes an enormous amount of time even for this very small data set:


```sql
select asset_key,generator_type,location,nominal_output, st_distance('POINT(49 10)', gpscoord) as dist_o from energymap em_o
where em_o.gpscoord is not null
and not exists(
        select nominal_output, st_distance('POINT(49 10)', GPSCOORD) as dist_i from energymap em_i
        where em_i.gpscoord is not null and ((local.dist_i < local.dist_o and em_i.nominal_output >= em_o.nominal_output) or
                                             (local.dist_i <= local.dist_o and em_i.nominal_output > em_o.nominal_output))); 
```
Note: If you lose patience, you can kill the query

## Looking further: Partitions

In addition to finding the "globally" optimal articles, Skyline supports the computations of "locally" optimal articles. Here, users can specify partitions (similar to `GROUP BY` groups in standard SQL). Then, the optima are computed on a per partition basis. Hence, a tuple is only removed from the result set, if there is a better alternative*in its partition*. For instance:


```sql
select asset_key,generator_type,location,nominal_output, st_distance('POINT(49 10)', gpscoord) as dist 
from energymap where gpscoord is not null 
PREFERRING HIGH local.dist PLUS LOW nominal_output 
PARTITION BY generator_type; 
```
## In a nutshell

### Skyline provides:

1. An efficient implementation for computing "the best" articles according to the specified multi-attribute ordering
2. A convenient syntax for defining orderings which among other things supports using arbitrary scalar expressions inside definitions of complex multi-attribute orderings
3. The specification of partitions for finding best articles "locally"

## Additional References

* [IMPORT](https://docs.exasol.com/sql/import.htm)
* [Skyline](https://docs.exasol.com/advanced_analytics/skyline.htm)
* [Analytic Functions](https://docs.exasol.com/sql_references/functions/analyticfunctions.htm)
* [Import Geospatial Data from CSV and GeoJSON File](https://docs.exasol.com/sql_references/geospatialdata/import_geospatial_data_from_csv.htm)
* [Geocoding with UDFs](https://docs.exasol.com/advanced_analytics/geocoding_with_udfs.htm)

## Downloads
[energymap.zip](https://github.com/exasol/Public-Knowledgebase/files/9937292/energymap.zip)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 