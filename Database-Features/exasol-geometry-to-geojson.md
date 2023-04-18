# Exasol GEOMETRY to GeoJSON 
## Description

Tableau doesn't yet support Exasol GEOMETRY data types or functions. A workaround is to save the data in GeoJSON format. The following script will convert GEOMETRY data for POINT and POLYGON geometry types into GeoJSON that you can copy and paste into a .json file. 


```python


CREATE OR REPLACE PYTHON SCALAR SCRIPT DASHBOARDS."UDF_GeoToJSON" ("ID" VARCHAR(1000), "Geometry" VARCHAR(2000000), "Properties" VARCHAR(10000)) RETURNS VARCHAR(2000000) AS
#==============================================
# Description:  This script converts geometry data in Exasol into GeoJSON features. A comma is added to the end o every result, which will need to be removed from the last record.
#               Copy / paste the results to a text file. Add this as a header to the file: {"type": "FeatureCollection","features": [
#               Add this as a footer to the file: ]}
#
# Usage:
#   ID = a unique ID to associate with feature
#   Geometry = a value from a GEOMETRY data type
#   Properties = a properly formatted string of properties to include with the feature (e.g. {"property1": "string1", "property2": value2})
#
# Notes: Known to work for POLYGON and POINT geometry types
#
# History:
# [05/12/2020] MJ Original Version
#==============================================
import re

def run(variables):
    geo = variables.Geometry
    header = '{ "type": "Feature", "id": "' + variables.ID + '", "geometry": '
    properties = ', "properties": {}'
    if variables.Properties != None:
        properties = ', "properties": {}'.format(variables.Properties)
    footer = '},'

    try:
        geometryType = re.search('([A-Z]+)\s',geo).group(1)
        geo = geo.replace(geometryType + ' ', geometryType).replace(', ', '], [').replace(geometryType,'{ "type": "' + geometryType.title() + '", "coordinates": ' + ('' if geometryType == 'POINT' else '[')).replace('(','[').replace(')',']') + ('' if geometryType == 'POINT' else ']') + '}'
        geo = re.sub(r'(\d)( \d)', r'\1,\2', geo)
        geojson = header + geo + properties + footer
        return(geojson)
    except:
        return('')
/
```
