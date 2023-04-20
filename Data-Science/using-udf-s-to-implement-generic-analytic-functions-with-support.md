# Using UDf's to implement generic analytic functions with support for complex windowing 
## Background

#### Analytic Functions

Analytic functions allow formulating certain queries like time series analysis, cumulative sums, moving averages etc. Without analytic functions, these queries would require correlated subqueries or self joins and could be much less efficiently computed.  
An analytic function divides the input into sorted partitions. Each ouptut row is computed on a window, that can be any continuous part of the partition. Starting with Version 6.2, Exasol supports complex windowing for Analytic Functions.

#### UDFs

User-defined functions provide you the ability to program your own analyses, processing or generation functions and execute them in parallel inside Exasol's high-performance cluster.

## Prerequisites

Here I describe what must be done before I follow the next steps

## How to implement generic analytic functions with support for complex windowing

Exasol's SET EMITS UDF script is suited for generic analytic functions. A SET EMIT scripts run() method gets called once for every group, allowing you to iterate over the sorted tuples of the group. This is just what we need for the partitioning part of analytic functions.  
So all we have to do in the UDF is handling the window and compute the analytic function over the given window.

The function signature of our generic analytic function looks like this:


```
CREATE LUA SET SCRIPT af (func varchar(40), arg double, lower_bound double, upper_bound double, groupkey varchar(200), val varchar(2000))  
EMITS (res double, groupkey varchar(200), val varchar(2000)) AS
```
So the generic function gets the name of the function we want to compute, the argument of the analytic function, the bounds of the window and the group key (partition key in analytic function lingo).  
Additionally, we added another column val, that is just emitted as given in the input.  
In order to compute this analytic function call:


```
SELECT SUM(x) OVER(PARTITION BY id ORDER BY x ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), id, x FROM t; 
```
We call our generic analytic function like this


```
SELECT af('SUM', x, 2, 0, id, x order by x) FROM t GROUP BY id; 
```
The following code is the run method of our analytic function:


```
function run(ctx)

local groupKey = ctx.groupkey
local valBuffer = {}

-- 1. set up the window
local w = Window:new()
if ctx.func=='SUM' then
    w:useThisFunction(af_sum)
elseif ctx.func=='GEOMETRIC_MEAN' then
    w:useThisFunction(af_geometric_mean)
else
    error('unknown analytical function ' .. ctx.func .. ' in generic udf af')
end
w:useTheseBoundaries(ctx.lower_bound, ctx.upper_bound, ctx.size())

-- 2. init Window
local window_position = 1
if window_position <= ctx.upper_bound then
    repeat
        w:checkBoundaries(ctx.lower_bound, ctx.upper_bound)
        w:growInitial(ctx.arg)
        window_position = window_position + 1
        table.insert(valBuffer, ctx.val)
    until (not ctx.next()) or (window_position > ctx.upper_bound )
end

-- 3. compute Window
if (window_position <= ctx.size()) then
	repeat
        w:checkBoundaries(ctx.lower_bound, ctx.upper_bound)
        w:updateWindow(ctx.arg)
        table.insert(valBuffer, ctx.val)
        ctx.emit(w:computeAF(), groupKey, valBuffer[w.out_row])
    until (not ctx.next()) 
end
while(w:hasData()) do
    ctx.emit(w:computeAF(), groupKey, valBuffer[w.out_row])
end

end
```
The three steps in this function are:

## Step 1

Get and initialize a new Window object. This object does all the Window handlig for us. Of course we have to tell the window which analytic function to compute (useThisFunction).

## Step 2

Then we have to initialize the window, before we emit any results. This is because we have to store the PRECEDING rows (the lower bound).

## Step 3

Finally we compute the window. As long as there is input data, we store this data in the window (updateWindow). When there is no more input data to read, we continue to compute the analytic function, as long there is data in the window (hasData).  
Our generic analytic function emits the computed result as well as the groupkey and a generic value that we are emiting as given in the input.

## Additional Notes

### Adding your own analytic function

So if you want to write a new analytic function, all you have to do is to specify how to compute the function on a given window.  
An analytic function to compute the geometric mean (n-th root of a product) looks like this:


```
local af_geometric_mean = function(window)
    local root = 0
    local product = 1
    for i, v in ipairs(window.data) do
        if v ~= null then
            root = root + 1
            product = product * v
        end
    end
    return math.pow(product, 1/root)
end 
```
Furthermore you have to make sure the right function is called, when setting up the window:


```
... 
elseif ctx.func=='GEOMETRIC_MEAN' then     
 w:useThisFunction(af_geometric_mean) 
... 
```
Now lets use our new function:  
We want to compute a moving average over the GDP groth rate of Germany since 1991. We have a table with the GDP for every year and use LAG to compute the growth rate year by year:


```
WITH country_growth AS (
  SELECT "year", 
         "gdp" / lag("gdp") OVER(PARTITION BY "country" ORDER BY "year") AS "growth", 
         "country" 
  FROM "gdp"
)
SELECT * 
FROM country_growth 
WHERE "year" > 1990;
```
Result:


```
1991	1.054905232194977	Germany
1992	1.140319371768007	Germany
1993	0.974294882744948	Germany
1994	1.066428223261708	Germany
1995	1.174315865819944	Germany
1996	0.965671413758055	Germany
1997	0.885817681513419	Germany
1998	1.010819807961675	Germany
1999	0.980701596840183	Germany
2000	0.886429790583485	Germany
2001	1.000369764838694	Germany
2002	1.065903343438301	Germany
2003	1.205177317356884	Germany
2004	1.125146897108509	Germany
2005	1.014974077449293	Germany
2006	1.049338216214689	Germany
2007	1.145754714885035	Germany
2008	1.090588582870329	Germany
2009	0.910875832414312	Germany
2010	0.999776175945123	Germany
2011	1.099543829980124	Germany
2012	0.941726733644324	Germany
2013	1.055761276515299	Germany
2014	1.032784733387949	Germany
... 
```
Since the growth rate is a relative value, we need to use the geometric mean. We calculate the geometric mean for every year including the five previous years:


```
WITH country_growth AS (
  SELECT "year", 
         "gdp" / lag("gdp") OVER(PARTITION BY "country" ORDER BY "year") AS "growth", 
         "country" 
  FROM "gdp"
)
SELECT  af('GEOMETRIC_MEAN', "growth", 5, 0, "country", "year" order by "year") 
FROM country_growth 
WHERE "year" > 1990 
GROUP BY "country" 
HAVING "country" = 'Germany';
```
Result:


```
1.054905232194977	Germany	1991
1.096781141181485	Germany	1992
1.054330548374133	Germany	1993
1.057342039893684	Germany	1994
1.079765347668721	Germany	1995
1.059854018283794	Germany	1996
1.029440382198913	Germany	1997
1.00896416240446	Germany	1998
1.010066926534827	Germany	1999
0.979419928234997	Germany	2000
0.953596996350473	Germany	2001
0.969422173990413	Germany	2002
1.020463283592773	Germany	2003
1.038851083816084	Germany	2004
1.044815584378044	Germany	2005
1.074611539071236	Germany	2006
1.099191468724178	Germany	2007
1.103393791709613	Germany	2008
1.05308939936964	Germany	2009
1.032557313745349	Germany	2010
1.046422573655142	Germany	2011
1.027721245823034	Germany	2012
1.013804809756734	Germany	2013
1.004644685244181	Germany	2014
```
### Integrating our UDF

As you can see UDFs are a powerful tool, that can help to implement arbitrary analytic functions. Furthermore you can transparently integrate the generic analytic function with the SQL preprocessor. For an example how to use the preprocessor see [our documentation](https://docs.exasol.com/database_concepts/sql_preprocessor.htm).  
The code of the generic analytic UDF with a small example is attached.

## Additional References

* [Analytic Functions](https://docs.exasol.com/sql_references/functions/analyticfunctions.htm)
* [UDF Scripts](https://docs.exasol.com/database_concepts/udf_scripts.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 