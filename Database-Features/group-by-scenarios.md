# Different GROUP BY Scenarios

## Question
We found an inconsistent behaviour in the group by clause. The essence of a huge SQL boils down to the following effect: In the SQL below the first GROUP BY gives the error message:

> Wrong column number. Too large value 12345 as select list column reference in GROUP BY (largest possible value is 1)

The second GROUP BY gives the correct result. This is inconsistent to my mind. The second works. Only problem is, that SQL programmers using "GROUP BY 1,2,3,4, ..."  end in HELL. We like to avoid that :winking_face: 

> SELECT 12345 AS dudu  
FROM dual  
GROUP BY LOCAL.dudu -- does not work but should do the same as second  
--GROUP BY 1 -- works but less elegant  

## Answer
I think it´s at least explainable if you think of it like this: "local" is a short-cut to allow you to reference expressions or "column definitions" that you use multiple times in the same query block - it pretty much just does "copy-and-paste" before the execution.

In your case a copy-and-paste clashes with Exasol's ability to reference columns by pos-id in a group by - if you´d have a column_name instead of a literal this wouldn´t be an issue but as it stands you end up telling Exasol to use the 12345th column in
your select list.