# Bing maps and QuadTree calculation 
## Background

The following is an implementation of the processes and formula described at Microsoft help page [Bing Maps Tile System](https://msdn.microsoft.com/en-us/library/bb259689.aspx).

The functions can be used to

* Transform **global GPS coordinates** (WGS 84 / lat+long) into **bing maps pixel coordinates**
* Transform pixel coordinates into **map tile coordinates**
* Transform map tile coordinates into **quadtree tile identifiers**

We chose to implement all functions using builtin (free of extra charge) functionality:

* regular user-defined functions (aka pl/SQL) instead of Lua/Python/Java UDF.
* No GEOSPATIAL functions (ST_TRANSFORM etc.)

However, this forces us to either

* Use multiple functions when multiple values (X and Y coordinates) are required
* or use string-encoding where this happens.

We use the latter approach (formatting coordinates as "X/Y") for more compact code (less functions), and for easier migration towards geospatial data types.

## How to implement Bing maps and QuadTree calculation

## Step 1

### WGS-84 to Pixels

This is a straightforward implementation of the given Mercator-like projection onto a pixel grid of the given detail level (width/height = 256 * 2^detail).  
Like in the original article, latitude, and longitude are clipped at ~85 (resp. 180) degrees in both directions.


```sql
create function coords2pixel(latitude double, longitude double, detail int)
	returns varchar(100)
is
	sinLatitude double;
	pixelX decimal(36,0);
	pixelY decimal(36,0);
begin
	latitude := greatest( -85.05112878, least( 85.05112878, latitude ) );
	longitude := greatest(-180, least( 180, longitude ) );
	sinLatitude := sin(latitude * pi() / 180);

	pixelX := ((longitude + 180) / 360) * 256 * power(2,detail);
	pixelY := (0.5 - log((1 + sinLatitude) / (1- sinLatitude)) / (4 * pi())) * 256 * power(2,detail);

	return pixelX || '/' || pixelY;
end;
/
```
Please note that this will perform a virtual transposition of coordinate ordering: input is LAT/LONG (or vertical/horizontal when looking at a map) while the output is X/Y (horizontal/vertical).

## Step 2

### Pixels to Map Tile

As we know that each map tile has a size of 256x256 pixels, transforming pixel coordinates into tile coordinates is quite easy.  
We use **regular expressions** with lookahead and look behind qualifiers for **string parsing** and divide each coordinate by 256:


```sql
create function pixel2tile(pixel varchar(100))
	returns varchar(100)
is
begin
	return 
		floor( regexp_substr(pixel, '.*(?=/)') / 256 )
		|| '/' ||
		floor( regexp_substr(pixel, '(?<=/).*') / 256 );
end;
/
```
**REGEXP_SUBSTR** is used as a replacement for **ST_X** and **ST_Y**, which are part of the GEOSPATIAL license package.

## Step 3

### Map Tile to QuadTree Identifier

The overall process of interleaving coordinates using three different number systems sounds quite complicated, however, it boils down to:

* Interpret your input coordinates as binary data (examining single bits using **BIT_CHECK**)
* Putting these binary streams side-by-side, each cross-stream pair of bits creates one digit of your output coordinate/string.

This makes the conversion routine itself rather short:


```sql
create or replace function tile2quad(tile varchar(100), detail int)
	returns varchar(30)
is
	xCoord int;
	yCoord int;
	quadkey varchar(30);
	lod int;
begin
	xCoord := regexp_substr(tile, '.*(?=/)');
	yCoord := regexp_substr(tile, '(?<=/).*');
	quadkey := '';
	for lod := 1 to detail do
		quadkey := quadkey || ( bit_check(xCoord,detail-lod) + 2* bit_check(yCoord,detail-lod) );
	end for;

	return quadkey;
end;
/
```
## Step 4

We now have a set of cascading functions that can transform GPS coordinates into Bing map tile identifiers. Let us check out Nuremberg (49.45N, 11.08E) at detail level 3:


```sql
select coords2pixel(49.45, 11.08, 3);
--> '1087/699'

select pixel2tile('1087/699');
--> '4/2'

select tile2quad('4/2', 3);
--> '120'
```
And indeed, according to the [image](https://msdn.microsoft.com/dynimg/IC96238.jpg) on the link given above, Nuremberg should be inside mapped tile "120" (which is fully contained in the larger map tiles "12" and "1").

Short version for a smaller map tile with more details:


```sql
select tile2quad(pixel2tile(coords2pixel(49.45, 11.08, 10)), 10); 
--> '1202033313' 
```
## Additional Notes

* Obviously, it makes sense to inline the implementation of cascades, simplifying usage and eliminating the need for string conversion/parsing.
* When inlining functions, input can and should be specified as separate coordinates (lat/long, X/Y) or as a GEOMETRY type (if available).
* When combining functions is not preferred, but performance becomes an issue, split functions into X and Y versions, allowing to trade string coding&parsing for two more function calls. You will end up with something like quad(tile(pixelX(longitude, detail)), tile(pixelY(latitude, detail)), detail).
* None of the functions above perform special error checking. Limitations are inferred from the used data types: QuadTree max detail: 30; Pixel max: 10^36; ...
* coords2pixel calculates values using the **DOUBLE** data type. Do not expect sub-millimeter accuracy...

## Additional References

[Use Google Maps API with EXASOL](https://exasol.my.site.com/s/article/Use-Google-Maps-API-with-EXASOL)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 