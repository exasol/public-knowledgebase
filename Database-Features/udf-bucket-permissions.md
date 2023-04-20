# UDF Bucket Permissions

## Question
I'm able to secure and upload/download jars using bucket permissions: 

https://docs.exasol.com/database_concepts/bucketfs/file_access.htm

However, I am having trouble running a java UDF without "public" permissions on the bucket.  When it's not public, the engine says that it can't find the jar file.  Assuming the UDF port is protected, this is not an issue.   

## Answer
You can fix this by running:
```
CREATE CONNECTION my_bucket_access TO 'bucketfs:bfsdefault/bucket1'  
IDENTIFIED BY 'readpw';

GRANT CONNECTION my_bucket_access TO my_user
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 