# Wrong Results for Connect by Nocycle

## Question
I'm using Exasol 7.0.7 on Windows with Docker:

> docker run --name EXASOL -p 127.0.0.1:9563:8563 --detach --privileged --stop-timeout 120 exasol/docker-db:latest

Now, run this query:

>SELECT LEVEL  
FROM dual  
CONNECT BY NOCYCLE LEVEL < 10

It produces:

|LEVEL|
|-----|
|1    |
|2    |

But I don't see why NOCYCLE should have any effect in this particular query. It should produce the same thing as Oracle:

|LEVEL|
|-----|
|1    |
|2    |
|3    |
|4    |
|5    |
|6    |
|7    |
|8    |
|9    |

In fact, without any usage of PRIOR, I think that NOCYCLE can be safely ignored?

## Answer
As per Oracle's definition a loop occurs if one row is both the parent (or grandparent or direct ancestor) and a child (or a grandchild or a direct descendant) of another row. This is independent of the PRIOR condition but just depends on the connect by condition: in your case of LEVEL < 10. The same single row of DUAL is joined repeatedly while executing the connect by. Since there is only one row this leads to a cycle because the row with level 2 has the same row as parent and as child.

I am not sure why Oracle implemented this differently. That said we are not compatible to Oracle when it comes to cycle detection (see https://community.exasol.com/t5/database-features/connect-by-cycle-detection/ta-p/1666).