# Geospatial Distance is Off

## Question
I've taken the city example from https://docs.exasol.com/sql_references/geospatialdata/import_geospatial_data_from_csv.htm
```
CREATE TABLE cities(name VARCHAR(200), geo GEOMETRY(4326));
INSERT INTO cities VALUES('Berlin', 'POINT (13.36963 52.52493)');
INSERT INTO cities VALUES('London', 'POINT (-0.1233 51.5309)');

-- this shows the distance in degrees:
SELECT a.name, b.name, st_distance(a.geo, b.geo) FROM cities a, cities b;
-- this shows the distance in meters:
SELECT a.name, b.name, st_distance(ST_Transform(a.geo, 2163),
     ST_Transform(b.geo, 2163)) FROM cities a, cities b;
```
The result, which shall be in meters is a bit surprising, 30 km off: Berlin	London	969387.149096201

 
I've also tried similar calculation with my home address and my working place using different SRID (EPSG) and noticed strange behaviour if I try to convert using ST_TRANSFORM. Is this kind of bug or some kind of newbie mistake?

## Answer
You are correct. Spatial functionality is all based on the OGC Simple Features Access Standard which can be found here: https://www.ogc.org/standards/sfs

Thus, for geometry types ST_DISTANCE returns the minimum 2D Cartesian (planar) distance between two geometries, in projected units (spatial ref units). We do not implement any extensions such as a GEOGRAPHY datatype, yet, that would take the spheroid into account.

The best approach would be to implement the Haversine distance as UDF in case you need it or to select a spatial reference system of choice that is most accurate for the area of investigation.

SRID: 26986 for example is a reference system that is most accurate for the area of Massachusetts, similar systems exist for Britain,... which provide high accuracy for local regions. 