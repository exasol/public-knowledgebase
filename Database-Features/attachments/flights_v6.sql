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
                       "dep_time", "dep_delay")					-- predictors
from FLIGHTS
group by iproc(),												-- the node no for data locality
cast(rownum/100000 as int);										-- restrict the no of rows (limit is R max. vector size)