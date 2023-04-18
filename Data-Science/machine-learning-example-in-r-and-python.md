# Machine Learning Example in R and Python 
## Background

Exasol's UDF scripts make it possible to run machine-learning algorithms directly in the database. The training of a random-forest model and using this model to make predictions on a dataset in the Exasol database can be done in three steps:

1. During a learning phase, the model is created based on a training dataset (e.g. from a table within the Exasol database) 
2. The model is put into BucketFS to make it accessible within UDF scripts
3. A UDF script is used to make predictions.

## Prerequisites

As an example, we create two tables RF.TRAIN and RF.TEST in the Exasol database and import the data from the files train.csv and test.csv. They both contain information about thousands of wines, e.g. the amount of sugar, the PH value, the acidity, and so on. The training dataset contains the taste of the wine (bad / normal / good). The goal is to train a model and classify the unknown wines in the test dataset. The SQL commands to create the table and the two CSV files are attached to this solution.  
We need an Exasol-Version 6.2 for the Python3 example.

## How to perform Machine Learning in R and Python

## Step 1: Learning Phase

### 1a. Learning Phase in R

 In R, a random-forest model can be created by firstly reading the data from the Exasol database using the Exasol R SDK. It can be directly installed from the GitHub repository:


```"code-java"
install.packages('randomForest')
install.packages('devtools')
devtools::install_github("EXASOL/r-exasol")
library(exasol)
library(randomForest)

con <- dbConnect("exa", exahost = "localhost:8563", uid = "sys", pwd = "exasol")
train <- dbGetQuery(con, "SELECT * FROM RF.TRAIN")
```
The dataframe train contains the data from the Exasol table RF.TRAIN.  head(train) shows the first rows in this table, barplot(table(train$TASTE)) shows the taste distribution as a bar chart, e.g. in R Studio. Next, the random forest model can be created and stored into a file:


```"code-java"
rf <- randomForest(as.factor(TASTE) ~ ., data = train, ntree=1000)
saveRDS(rf, "D:/rf.rds", version=2)
```
### 1b. Learning Phase in Python 3

Since Exasol Version 6.2, the language Python 3 is included with many built-in packages like pandas, scikit-learn and many more. On a local Python 3 environment, the random-forest model can be built analogously to the example above in R. First, the training data is loaded from the Exasol database as a dataframe using the Python package pyexasol:


```"code-java"
import pyexasol
import pandas as pd
import numpy as np
import pickle
from sklearn.ensemble import RandomForestClassifier
C = pyexasol.connect(dsn='localhost:8563', user='sys', password='exasol')
train = C.export_to_pandas("SELECT * FROM RF.TRAIN") 
```
The pandas dataframe train can be inspected with `train.head(5)` or `train.describe()`. Next, the labels (bad/normal/good) from the taste column need to be converted into integers (-1/0/1):


```"code-java"
train.TASTE[train.TASTE == 'bad'] = -1
train.TASTE[train.TASTE == 'normal'] = 0
train.TASTE[train.TASTE == 'good'] = 1
labels = np.array(train['TASTE'])
labels = labels.astype('int')
features = train.drop('TASTE', axis=1)
```
The array `labels` just contains the numeric labels for a all wines, e.g. [1, 0, 0, -1, 1, 1, ...]. `features` looks like the original `train` dataframe but it does not contain the taste column. Next, the random-forest model can be trained and written into a file:


```"code-java"
clf = RandomForestClassifier(n_estimators=100, max_depth=2)
clf.fit(features, labels)
pickle.dump(clf, open('D:/clf.dat', 'wb'))
```
## Step 2:Putting the model into BucketFS

The easiest way to work with Exasol's BucketFS is using the BucketFS explorer. After logging in with the Exaoperation credentials, a BucketFS service and a bucket can be created. In this new bucket, we move the model file (rf.rds for R, clf.dat for Python 3).

## Step 3: Creating a UDF script for prediction

### 3a. Creating a R UDF script for prediction

When the bucket is not publicly accessible but read-protected, a connection object has to be created in the Exasol database to provide the read password to UDF scripts:


```"code-sql"
CREATE CONNECTION my_bucket_access TO 'bucketfs:bucketfs1/udf' IDENTIFIED BY '12345'; 
```
In an R UDF script, the random-forest model is read from BucketFS. After that, the input set of the UDF script is converted into a dataframe which is accepted by the predict function of the randomforest package. We load batches of 1000 rows each to make 1000 predictions in each iteration.


```"code-sql"
--/
create or replace r set script rf.predict(...) emits (wine_id INT, taste VARCHAR(6)) as
library(randomForest)

run <- function(ctx) {
rf <- readRDS("/buckets/bucketfs1/udf/rf.rds")

## load the first batch of 1000 rows in the input set
ctx$next_row(1000)
repeat {
  wine_ids <- ctx[[1]]()

  ## create a dataframe from all input columns (except the first one (wine_id))
  numCols <- exa$meta$input_column_count
  df <- data.frame(ctx[[2]]())
  for (i in 3:numCols) {
        df <- cbind(df,ctx[[i]]())
  }

  colnames(df) <- c("FIXED_ACIDITY", "VOLATILE_ACIDITY", "CITRIC_ACID",
                    "RESIDUAL_SUGAR", "CHLORIDES", "FREE_SULFUR_DIOXIDE",
                    "TOTAL_SULFUR_DIOXIDE", "DENSITY", "PH", "SULPHATES", "ALCOHOL")

  prediction <- predict(rf, newdata=df)

  ctx$emit(wine_ids, as.character(prediction))  

  ## load the next batch of 1000 rows in the input set
  if (!(ctx$next_row(1000))){break}
}
}
/
```

```"code-sql"
select rf.predict(wine_id, fixed_acidity, volatile_acidity, citric_acid, residual_sugar, 
 chlorides, free_sulfur_dioxide, total_sulfur_dioxide, density, pH, sulphates, alcohol) 
 from RF.test group by iproc(); 
```
Due to theGROUP BY iproc(), the UDF script is called once per Exasol node with the data that is locally stored on that node to enable parallel and fast predictions.

### 3b. Creating a Python UDF script for prediction

Using the scripting language PYTHON3 - which is built-in in Exasol since version 6.2 -, the input set can be accessed batch-wise as a pandas dataframe withctx.get_dataframe.


```"code-sql"
--/
CREATE OR REPLACE PYTHON3 SET SCRIPT test.predict_wine_py(...) emits (wine_id INT, taste VARCHAR(6)) as
import pickle
import pandas as pdclf = pickle.load(open('/buckets/bucketfs1/udf/clf.dat', 'rb'))
clf.n_jobs = 1def run(ctx):
	BATCH_ROWS = 1000
	while True:
		df = ctx.get_dataframe(num_rows=BATCH_ROWS)
		if df is None:
			break
	wine_ids = df['0']
	features = df.drop('0', axis=1)
	
	res_df = pd.DataFrame(columns=['WINE_ID', 'TASTE'])
	res_df['WINE_ID'] = wine_ids
	res_df['TASTE'] = clf.predict(features)
	
	res_df.TASTE[res_df.TASTE == -1] = 'bad'
	res_df.TASTE[res_df.TASTE == 0] = 'normal'
	res_df.TASTE[res_df.TASTE == 1] = 'good'
  
	ctx.emit(res_df)
/
```

```"code-sql"
select rf.predict_wine_py(wine_id, fixed_acidity, volatile_acidity, citric_acid, residual_sugar, 
 chlorides, free_sulfur_dioxide, total_sulfur_dioxide, density, pH, sulphates, alcohol) 
 from RF.test group by iproc();
```
## Additional References

* [BucketFS Explorer](https://github.com/exasol/bucketfs-explorer)
* [UDF Scripts](https://docs.exasol.com/database_concepts/udf_scripts.htm)
* [Creating a UDF](https://exasol.my.site.com/s/article/How-to-create-and-use-UDFs)

## Downloads
[test.zip](https://github.com/exasol/Public-Knowledgebase/files/9936798/test.zip)
[DDL_and_IMPORT.zip](https://github.com/exasol/Public-Knowledgebase/files/9936800/DDL_and_IMPORT.zip)
[train.zip](https://github.com/exasol/Public-Knowledgebase/files/9936801/train.zip)
