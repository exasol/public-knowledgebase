# Filter on DOUBLE columns 
## Background

Filter on DOUBLE columns returns unexpected results. 

The DOUBLE values you see in EXAplus may differ from the actual database values due to the JDBC double handling and rendering.

## Explanation

As the DOUBLE data type is only an approximative numeric type, filters on DOUBLE columns may return unexpected results, due to the approximative nature of this data type.

The datatype DOUBLE in the Exasol DB (including 6.x) is defined as an 64-Bit floating point value, which represents values with a combination of an exponent and a fraction in binary form. This means that not every existing (numeric) value can be exactly represented by this type.

We recommend to filter only on DECIMAL columns to avoid described problems.

## Additional References

The actual value range of this type can be seen in our documentation:

[Data Type Details](https://docs.exasol.com/sql_references/data_types/datatypedetails.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 