# Do Virtual Schemas Write Local Files?

## Question
Can virtual schema write local files (temp files?)

What are the limitations in terms of size?

Would they be wiped out with every invocation (new container)?

## Answer
Virtual Schema have no direct access to the local file system. You can however use HTTP to r/w from BucketFS.

Alternatively you could in theory write the content to tables. Be aware of locking in that case. Also the size of an Exasol VARCHAR is limited to 2 million characters. 30% less if you Base64 encode binaries.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 