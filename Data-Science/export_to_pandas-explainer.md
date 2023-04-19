# Export_To_Pandas Explainer

## Question
I was wondering if I am using PyExasol's export_to_pandas function wrong, or if I should be using something else. The thing I noticed is:

export_to_pandas appears to use an export to csv and reimport to transfer data into a python pandas dataframe. This leads to certain problems:

a) I had to ask special export permissions for my user type on the database from our overcompliant IT department

b) it seems to take quite a long time, mainly attributed to the spin-up time (depending on the query and table. I have some quick SQLs that now take noticeably longer on Python Exasol than they did via, for example, the teradata python driver)

c) this process gives me some issues with data types being lost. I have some columns with data that looks like decimal numbers, but is a string. I now have to painstakingly define data types (via callback parameters) for each column instead of getting them from the database directly. This also never used to be an issue in our old teradata architecture.

Is there a more elegant way to get the query results into a dataframe without an intermediate step in the background?

## Answer
You may try to use a very basic approach:
```
connection = pyexasol.connect(...)  

stmt = connection.execute('SELECT ...')  
pd = pandas.DataFrame(stmt.fetchall())
```

 

You may also use `stmt.columns()` to access information about result data types, if necessary.

https://github.com/exasol/pyexasol/blob/master/docs/REFERENCE.md#columns

.export_to_pandas() is advised for medium to large data sets with ~100k+ rows. In this case "spin-up" time becomes insignificant compared to savings on transport protocol and reduced deserialisation overhead.

 

The main problem with Exasol vs. Pandas data types is related to fundamental limitations of pandas / numpy. Pandas natively supports less data types compared to Exasol. It is especially noteable with:

- integers (pandas is limited to int64);
- decimals (no native support for pandas, only float with loss of precision);
- timestamps (Exasol goes from 0001-01-01 to 9999-12-31, pandas can only do a fraction of it);

 

So it is not possible to create a universal function to read any data from Exasol to Pandas and preserve data types. The current approach lets user to read any data at least in the form of "object" data type, and fix it later by providing data types explicitly or by transforming data frame.

On the bright side, it's rarely an issue for typical users, and it's still easy to "fix" using a few lines of code and internal knowledge about your data.