# How to Find Invalid Views

## Question
Hello. I would like to know how to verify if there are invalid views; in other words, how can I look for views based on non-existing objects? Thank you in advance. 

## Answer
You can figure out whether views are invalid by looking at whether there are EXA_ALL_COLUMNS rows defined for them. An invalid view will either have no columns in that table or the column's STATUS field will be "OUTDATED".  However there are 2 scenarios where EXA_ALL_COLUMNS can be inaccurate:

1. If the view was created with the FORCE keyword. In this case EXA_ALL_COLUMNS will not contain rows for the view regardless of whether the view is valid or not until it is accessed for the first time.
2. If the view was originally valid and then later a dependency was changed. In this case EXA_ALL_COLUMNS will contain rows for it even but the STATUS column will read 'OUTDATED' (regardless of whether the view is still valid or not).

To make sure EXA_ALL_COLUMNS is accurate you have to first access any view that falls under these two scenarios and then check again. So the procedure is:

1. Run: 
```SELECT view_schema, view_name  
FROM exa_all_views v  
LEFT JOIN exa_all_columns c  
  ON v.view_schema = c.column_schema  
AND v.view_name = c.column_table  
GROUP BY view_schema, view_name  
HAVING ANY( column_name IS NULL )  
    OR ANY( status = 'OUTDATED' )  
ORDER BY view_schema, view_name​  
```
2. For every view that is listed you need to access it by (for example) running DESC schema.view. If this DESC fails the view is invalid and vice versa.
3. You can either collect the list of invalid views by keeping track of which DESC commands fail or you can later run the SQL in #1 above. All views the statement now returns will be invalid (assuming no other DDL has run in the meantime).

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 