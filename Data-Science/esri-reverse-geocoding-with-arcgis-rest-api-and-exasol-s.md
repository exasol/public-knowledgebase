# Esri: (reverse) geocoding with ArcGIS REST API and Exasol's GEOMETRY data type 
## Background

One way to work with geocoding is to use a GIS (geographic information system) service like ArcGIS ([www.arcgis.com](http://www.arcgis.com)) from Esri.

The following website shows different use cases when such a service might be useful:  
[https://developers.arcgis.com](https://developers.arcgis.com/)

In this tutorial, we would like to show you how to use the ArcGIS REST API from Python:  
<http://resources.arcgis.com/en/help/arcgis-rest-api>

In practice, you might face the following challenges:

* Connect to a REST API from an Exasol UDF language (Python, Java, R, Lua).
* If you want to benefit from Exasol's GEOMETRY data type (e.g. in order to run geospatial functions), you need to think about converting this data to Python strings and back.

This solution uses Python and the python package [requests](https://requests.readthedocs.io/en/master/) to connect to the REST API.  
As an example, we only demonstrate geocoding and reverse geocoding.

## Prerequisites

* You should create a bucket and make sure the database has access to this bucket. You can find further information on doing this [here](https://docs.exasol.com/database_concepts/bucketfs/bucketfs.htm)
* The database must have access to the internet and have a DNS name configured ([instructions](https://docs.exasol.com/administration/on-premise/manage_network/configure_network_access.htm?Highlight=dns#SystemNetworkSettings))

## How to use ArcGIS Rest API in a UDF

## Step 1 - Install Python Package Requests (optional)

In Version 6.2, the Python package "Requests" already comes in the standard language container shipped with the database. However, if you are using a nonstandard container or an earlier version, you may need to install the Python package beforehand. You can confirm this is the case by running the examples below. If you get an error message stating "No module named Requests", then the package needs to be installed. You can find more information on how to do this [here].(https://docs.exasol.com/database_concepts/udf_scripts/expand_script_using_bucketfs.htm#PythonLibraries)

## Step 2 - Adapt arcgis_demo.sql (optional)

If you do not have the proper packages installed (see step 1) - you may need to update each UDF with code like this:


```
import sys 
import glob   
sys.path.extend(glob.glob('/path/to/bucket/*'))
```
## Step 3: Run arcgis_cities

Run the attached script "arcgis_cities.sql" to create the data that you will use in the example.

## Step 4: Run arcgis_demo

Run the attached demo to get the geo information for the cities specified!

## Additional Notes

For better performance when working with large datasets, we recommend batch geocoding (<https://developers.arcgis.com/rest/geocode/api-reference/geocoding-geocode-addresses.htm>) instead of geocoding – but in order to use this, you need to have an ArcGIS online organizational account which you might be charged for.

## Additional References

* [BucketFS](https://docs.exasol.com/database_concepts/bucketfs/bucketfs.htm)
* [Expanding Script Languages](https://docs.exasol.com/database_concepts/udf_scripts/expand_script_using_bucketfs.htm)
* [ArcGIS](https://www.arcgis.com/index.html)
