# connect
require(exasol)
require(randomForest)
C <- odbcConnect("ctc1")


# read data
train <- exa.readData(C, "SELECT * FROM RF.TRAIN")
test  <- exa.readData(C, "SELECT * FROM RF.TEST")

# remove imageid from test
test     <- test[order(test[1]),]
imageid  <- as.factor(test[,1])
test     <- test[,-1]

# extract labels from train
labels <- as.factor(train[,1])
train  <- train[,-1]

# random forest algorithm
rf          <- randomForest(train, labels, xtest=test, ntree=1000, keep.forest=TRUE)
predictions <- cbind(imageid ,levels(labels)[rf$test$predicted])

# print prediction
predictions

# print forest
rf

# save the model locally
save(rf, file = "<your path here>")

# reload and reuse
load("<your path here>")
predict(rf, test)

