# Total Number of IN(...) List Elements is Too Large

## Question
Has anyone faced this type of error in Exasol? Is there any limit for IN(&lt;elements&gt;)

[0A000] Feature not supported: The total number of IN(...) list elements (200015) is too large (current IN list size: 83)

## Answer
Per default Exasol limits the number of IN list elements to 200000.
This avoids queries that run out of memory.
Note that since 6.0 the limit is not applied to a single IN list, but to the complete query.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 