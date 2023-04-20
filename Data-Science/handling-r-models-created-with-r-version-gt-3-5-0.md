# Handling R models created with R Version &gt; 3.5.0 
## Scope

Serialized models that have been created with a version of R > 3.5.0 will lead to an error in Exasol, when calling unserialize within a R UDF. The error raised by the R UDF might read something like 


```"default
cannot read workspace version 3 written by R 4.0.x; need R 3.5.0 or newer
```
## Diagnosis

The workspace format changed with versions of R >= 3.5.0. You might serialize with the newer version 3 format while Exasol requires the previous format 2. 

## Explanation

Inside Exasol we are currently running a version < 3.5.0 of R which causes unserialize to fail with above error. 

## Recommendation

The serialize function in R allows you to specify the workspace version, see [here](https://www.rdocumentation.org/packages/base/versions/3.6.2/topics/serialize). Hence, if you specify version 2 accordingly then a model created in such a way will be unserialisable in Exasol without error. Here is an example:

***serialize(model1, ascii = TRUE, connection = NULL, version=2)***

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 