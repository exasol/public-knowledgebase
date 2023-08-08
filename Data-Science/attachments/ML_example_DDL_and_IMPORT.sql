create schema rf;

create or
replace table
	train(
		fixed_acidity DECIMAL(9,5),
		volatile_acidity DECIMAL(9,5),
		citric_acid DECIMAL(9,5),
		residual_sugar DECIMAL(9,5),
		chlorides DECIMAL(9,5),
		free_sulfur_dioxide DECIMAL(9,5),
		total_sulfur_dioxide DECIMAL(9,5),
		density DECIMAL(9,5),
		pH DECIMAL(9,5),
		sulphates DECIMAL(9,5),
		alcohol DECIMAL(9,5),
		taste VARCHAR(6)
	);

create or
replace table
	test(
		wine_id INT,
		fixed_acidity DECIMAL(9,5),
		volatile_acidity DECIMAL(9,5),
		citric_acid DECIMAL(9,5),
		residual_sugar DECIMAL(9,5),
		chlorides DECIMAL(9,5),
		free_sulfur_dioxide DECIMAL(9,5),
		total_sulfur_dioxide DECIMAL(9,5),
		density DECIMAL(9,5),
		pH DECIMAL(9,5),
		sulphates DECIMAL(9,5),
		alcohol DECIMAL(9,5)
	);

commit;

IMPORT INTO RF.TRAIN FROM LOCAL CSV FILE 'C:\ML_example_train.csv' 
ENCODING = 'UTF-8' 
COLUMN SEPARATOR = ',' 
COLUMN DELIMITER = '"'
SKIP = 1
REJECT LIMIT 0;

IMPORT INTO RF.TEST FROM LOCAL CSV FILE 'C:\ML_example_test.csv' 
ENCODING = 'UTF-8' 
COLUMN SEPARATOR = ',' 
COLUMN DELIMITER = '"' 
SKIP = 1
REJECT LIMIT 0;

select * from rf.test;
commit;