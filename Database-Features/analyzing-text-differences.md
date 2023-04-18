# Analyzing text differences 
## Background

Sometimes there are texts stored in the database and you want to find out if and where those texts differ. 

While a best practice would be to create a UDF in a language you are comfortable with, using available libraries for diff creation, this article presents a fully home-made solution written in Lua.

## How to

The solution consists of two implementation scripts (scripting scripts / stored procedures) and two example usage scripts.

### I1 - Myers' Diff Algorithm and a tokenizer


```"code-sql"
/**
	Internal diff functionality. To be used by scripts that know what to do.
*/
create or replace script diff_internal as
...
```
### I2 - Implementation returning a html-like add/del diff


```"code-sql"
/**
	Basic text diff functionality.
	Only contains one function that will return a textual representation
	of the edit path between two texts.

*/
create or replace script text_diff() as
... 
```
### E1 - Diff script taking two strings to compare


```"code-sql"
/**
	Basic diff example operating on given clear text input.
	Supported compare modes see diff_INTERNAL.

*/
create or replace script do_diff( old_text, new_text, mode )
	returns table
as
...
```
### E2 - Diff script taking two view IDs, reading view texts from the database


```"code-sql"
/**
	Example usage of TEXT_DIFF script to compare two views.
	Views must be passed as VIEW_OBJECT_ID from EXA_ALL_VIEWS.

	Supported tokenize modes see diff_INTERNAL.
*/
create or replace script view_diff( view_ID_1, view_ID_2, mode )
	returns table
as
... 
```
## Example calls

### 1 - Compare two strings on a char-by char basis


```"code-sql"
execute script do_diff( 'ABCABBA', 'CBABAC', 'char' ) WITH OUTPUT; 
```
Result:


```
<del>AB</del>C<add>B</add>AB<del>B</del>A<add>C</add> 
```
### 2 - Compare two strings on a word-by-word basis


```"code-sql"
execute script do_diff(  
 'The quick brown fox jumps over the lazy dog.',  
 'The lazy fox jumps over the quick brown dog.',  
 'word') with output; 
```
Result:


```
The
<del>quick
brown
</del><add>lazy
</add>
fox
jumps
over
the
<del>lazy
</del><add>quick
brown
</add>
dog. 
```
Yes... output formatting for mode 'word' could be much better.

### 3 - Use sql tokenizer for the brown fox example


```"code-sql"
execute script do_diff(  
 'The quick brown fox jumps over the "lazy" dog.',  
 'The lazy fox jumps over the "quick brown" dog.',  
 'sql') with output; 
```
Result:


```
The <del>quick</del><add>lazy</add> <del>brown </del>fox jumps over the <del>"lazy"</del><add>"quick brown"</add> dog. 
```
As the sql tokenizer includes whitespace in the diff, output is more likely to be formatted 'just like' the input.  
However as you can see,

* For regular tokens, the algorithm is not aware that consecutive deletions can be combined for output.
* The SQL tokenizer will treat "identifiers", 'strings' and even /**multi line comments**/ as single tokens.

### 4 - Differences in database objects (views)


```"code-sql"
select VIEW_NAME, VIEW_OBJECT_ID
from exa_all_views
where view_schema = 'SR9000';
-- ...

execute script view_diff( 80438886402, 84919013378, 'sql' ) with output; 
```
Result:


```
create or replace view <del>statement_messages</del><add>l_message</add> as<del>
	</del><add> 
	</add>select<del>
		LP.process_id,
		LF.file_id,
	
		LP.process_number</del> <del>as</del><add>*</add> <del>session_id,
...
```
