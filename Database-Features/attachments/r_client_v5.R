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
# upload the model to an external redis
library(rredis)
redisConnect(host="192.168.42.128", port=6379)
redisSet("fl_model", model1)