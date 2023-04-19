# Apache Airflow Import Local CSV Error

## Question
I was trying this section https://docs.exasol.com/connect_exasol/workflow_management/apache_airflow.htm

With one change , I was running an import statement in sql file.

test.sql file code:
```
IMPORT INTO COUNTRY FROM LOCAL CSV FILE '/home/vagrant/airflow/data/country.csv'  
ENCODING = 'UTF-8'  
ROW SEPARATOR = 'CRLF'  
COLUMN SEPARATOR = ','  
COLUMN DELIMITER = ''''  
SKIP = 0  
REJECT LIMIT 0;  
```

My DAG Code:
```
from airflow import DAG
from datetime import datetime,timedelta
from airflow.operators.jdbc_operator import JdbcOperator
from airflow.operators.dummy_operator import DummyOperator
tmpl_search_path = '/home/vagrant/airflow/templates/' 
default_args = {'owner': 'airflow','depends_on_past': False,'start_date': datetime(2020, 1, 1) ,'retries': 1, 'retry_delay': timedelta(minutes=2)}
with DAG(dag_id='Exasol_DB_Checks',schedule_interval= '@hourly',default_args=default_args,catchup=False,template_searchpath=tmpl_search_path) as dag:
      start_task=DummyOperator(task_id='start_task',dag=dag)
      
      sql_task_1 = JdbcOperator(task_id='sql_cmd',
                                jdbc_conn_id='Exasol_db',
                                sql="test.sql",
                                autocommit=True,
                                params={"my_param":"{{ var.value.source_path }}"}
                                )
      start_task >sql_task_1
```

Error:- pype._jclass.SQLException: java.sql.SQLException: Feature not supported: IMPORT and EXPORT of local files is only supported via JDBC (except prepared statements) or EXAplus1

Why is this error and is the work around for this?

## Answer
A prepared statement is a more "protected" SQL statement where the query is parsed and compiled, and then also accepts certain variables. For example:

INSERT INTO TEST.TABLE1 VALUES (?,?,?) 

The question marks are parameters that are sent after the query is compiled.

More info: java - Difference between Statement and PreparedStatement - Stack Overflow

So it looks like Apache Airflow is executing every query as if it is a prepared statement. I'm not sure if you are able to influence it at all, but IMPORT FROM LOCAL CSV won't work with prepared statements, so that's why you go the error message