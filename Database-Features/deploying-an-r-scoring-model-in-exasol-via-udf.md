# Deploying an R scoring model in EXASOL via UDF 
## Background

Below is an UDF script in R that executes a scoring model inside EXASOL. While example is using the flights dataset from R and applying a randomForest model, it may be used as a template for R models.

It has already proven in a real case where a Neural Network-based scoring process on a multi-bilion dataset was transferred from an R Server into EXASOL, reducing the amount of time needed from approx. 1h to a few mins.

## How to deploy an R scoring model in EXASOL via UDF

Typical points for adaptation are:

## *Step 1*

the library needed for scoring must be present (here: library(randomForest)

## *Step 2*

the column names in the data.frame used in the UDF must resemble those of the data frame used for building the model. Typically these can be extracted from the model, but for other kinds of models the location needs to be adapted:


```markup
if (length(m) == 0) {
	...
	# get the predictors names
	colnames <<- names(m$forest$xlevels)
}
```
Here the model is loaded from EXABucket (Redis in EXASOL 5) if not already present in the environment. Depending on the model size, the model loading is the main factor influencing the time needed for the scoring process. The character vector 'colnames' is later used to construct the data.frame; it must contain the column names.

## *Step 3*

Later when the InDB scoring is started by the SELECT, the columns need to be referenced in the same order as in the model building data frame (due to pt 2). The GROUP BY parameter ROWNUM / 100 000 may be a lever for performance fine tuning: the more rows per UDF, the faster the scoring, but if an instance gets too many rows, it runs out of memory.

R (Client side) - download code for:

* EXASOL 6:[r_client_v6.R](https://www.exasol.com/support/secure/attachment/50966/50966_r_client_v6.R "r_client_v6.R")   (as shown here)
* EXASOL 5:[r_client_v5.R](https://www.exasol.com/support/secure/attachment/50968/50968_r_client_v5.R "r_client_v5.R")

**r_client_v6.R**
```"code-java"
# build a model for testing

# see www.github.com/exasol/r-exasol
library(exasol)
library(nycflights13)

con <- dbConnect("exa", dsn="exa")
dbWriteTable(con, "R.FLIGHTS", flights)
df <- dbGetQuery(con, "select * from R.FLIGHTS limit 10000")
dbDisconnect(con)

library(randomForest)
set.seed(852)
df <- df[complete.cases(df),]
model1 <- randomForest(as.factor(carrier) ~ dep_time + dep_delay, data=head(df, n=1000))
# like this, you could do prediction on the client-side:
#predict(model1, df[,c("dep_time","dep_delay")])

# but instead, we want to predict in-database, thus we have to
# upload the model to an EXABucket via httr
library(httr)
PUT(
	# EXABucket URL
	url = "http://192.168.42.129:2101/bucket1/model1",
	body = serialize(model1, ascii = FALSE, connection = NULL),
	# EXABucket: authenticate with write_user__name / write_user__password
	config = authenticate("w", "writepw")
)
```
EXASOL (Server side) - download code for:

* EXASOL 6:[flights_v6.sql](https://www.exasol.com/support/secure/attachment/50967/50967_flights_v6.sql "flights_v6.sql")   (as shown here)
* EXASOL 5:[flights_v5.sql](https://www.exasol.com/support/secure/attachment/50969/50969_flights_v5.sql "flights_v5.sql")

**flights_v6.sql**
```"code-sql"
-- deploying the model

open schema R;

create or replace r set script pred_randomForest(...) emits (predict varchar(200000)) as
	library(randomForest)
	m <- list()
	colnames <- vector(mode="character")

	run <- function(ctx) {
		if (length(m) == 0) {
	    	# only load the model if not already present. Must be done in run() as ctx is needed.
			f <- file(ctx[[1]](), open="rb", raw=TRUE)
			m <<- unserialize(f) 
			# get the predictors names
			colnames <<- names(m$forest$xlevels)
		}
		# load entire chunk
		ctx$next_row(NA)
		n <- exa$meta$input_column_count
		s <- paste0("model_key", "=ctx[[1]]()")
	    for (i in 2:n) {
			# construct a data.frame from the chunk & colnames
			name <- colnames[i - 1]
			s <- paste0(s, ", ", name, "=ctx[[", i, "]]()")
		}
		eval(parse(text = paste0("inp_df <- data.frame(", s, ")")))
		# predict & emit
		ctx$emit(predict(m, inp_df[, 2:n]))
	}
/
create connection sys_bucketfs to 'bucketfs:bfsdefault/bucket1' identified by 'readpw';
select pred_randomForest('/buckets/bfsdefault/bucket1/model1',	-- EXABucketFS path
                       "dep_time", "dep_delay")			-- predictors
from FLIGHTS
group by iproc(),						-- the node no for data locality
		cast(rownum/100000 as int);			-- restrict the no of rows (limit is R max. vector size)
```
### Additional references:

<https://exasol.my.site.com/s/article/How-to-use-EXASolution-R-SDK>

<https://exasol.my.site.com/s/article/How-to-create-an-EXABucketFS-service-and-bucket>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 