# Exasol loves Lua (part 4) - New in Lua 5.2 
If you are familiar with Exasol's Lua capabilities, you probably know that they are based on a specially adapted version of Lua 5.1. Just like our customers we felt, it was about time for an update, so we took on the endeavor to build a new embedded version based on Lua 5.4

In this article series, I am going to discuss a couple of the main changes that Lua underwent between 5.1 and 5.4. And there were a lot. There will be one article per version. In the first one, we will discuss the [changes from Lua 5.1 to 5.2](http://www.lua.org/manual/5.2/readme.html#changes "Changes"). Also, I am concentrating on the most relevant ones.

## Moved and renamed methods

The first thing that you will stumble over is that the `unpack()` the function has to be moved to `table.unpack`. If you want code to be backward compatible, you can start your script with:


```java
table.unpack = table.unpack or _G.unpack
```
This trick makes use of the fact that `table.unpack` is not set in Lua 5.1, so that the first part of the `or` evaluates to `nil` that means the second part will be used as the value for the assignment.

Also if you have read the [third part](https://exasol.my.site.com/s/article/Exasol-loves-Lua-part-3-Handling-modules "Exasol") of this series about handling modules, you already know that `package.loaders` has been renamed to `package.searchers`, a lot more fitting name, since this table contains functions that search for package loaders, not the loaders themselves.

### Other moved / renamed  methods

* Use `math.log(x, 10)` instead of `log10()`.
* Now `string.gmatch` replaces `string.gfind`
* Use `math.fmod` instead of `math.mod`
* Use `load` instead of `loadstring`

## New features

* [Bitwise operations](http://www.lua.org/manual/5.2/manual.html#6.7 "Bitwise") are now supported by a new library, from the typical suspects "and", "or", "not", setting, testings over-rotation, and shifting to extracting and replacing. All operations work on 32 bit words.  
Reminder: while Lua only supports 32 bits, Exasol's SQL bitwise operations support 64 bits.
* If you know destructors, then the concept of [garbage-collection metamethods](http://www.lua.org/manual/5.2/manual.html#2.5.1 "Garbabe-collection") (also called "*finalizers*") will probably sound familiar. You can add these metamethods to tables to clean up external resources before a table is collected.
* If you have heard of [coroutines](http://www.lua.org/manual/5.2/manual.html#2.6 "Lua"), you might be interested to learn that `pcall` and metamethods now support `yield()`. In short when calling `yield()`, you immediately return from a coroutine but can later resume the coroutine from the part after the `yield()`. This is useful to implement a collaborative form of multithreading. Here the thread has to actively give up control instead of getting the control taken away.
* You can use the `__len` metamethod on a table to control how a table calculates its length.
* Lua lets you express float literals in hexadecimal representation, so 3.1416 can for example be written as: `0xA23p-4`
* Hexadecimal numbers in strings can now be escaped by starting them with `\z`.
* [Empty statements](https://www.lua.org/manual/5.2/manual.html#3.3.1 "Lua") are now supported in form of a single semicolon ";".
* The `break` statement does not need to be at the very end of a block anymore. Up to and including 5.1 you had to explicitly wrap `break` in an extra `do ... end` if you wanted to break a block in the middle.
* You can pass additional arguments in `xpcall(<function>, <message-handler> [, <argument>, ···])`.
* The function for concatenating repeated strings `string.rep(<string>, <number-of-times> [, <separator>])` now has an additional separator so that you could create sequences like this easily: `---|---|---`
* Lua 5.2 also introduced a new optional parameter in `os.exit([code [, close])` that you can use to instruct Lua to clean up resources. Generally, you want this parameter to be true.  
The only exception from that rule is if you are absolutely sure there is nothing to clean up and want Lua to exit as quickly as possible.
* The two new metamethods `__pairs` and `__ipairs` allow you to redefine the standard functions for generating [iterators](https://www.lua.org/pil/7.1.html "Iterators") on tables.
* You can check if the garbage collector is currently running using `collectgarbage("isrunning")`.

### File handling

One word about Lua file handling in Exasol before we look at the new features. Reading from the filesystem is intentionally disabled in Exasol's Lua implementation. It's a necessary security measure. Nevertheless, lets look at what's new in Lua 5.2:

* `file:read` has a new option `*L` that allows you to [read a file line-by-line while discarding the line break](https://www.lua.org/manual/5.2/manual.html#pdf-file:read "file:read").
* `file:write` returns the file, so that you can chain calls to make code more compact and readable.
* `io.lines` can now work with a list of files and process them in a row

### Chunk and modules loading

A "chunk" in Lua terms is a piece of code. You can load it at runtime from files, strings, or provider functions. Modules are code blocks contained in packages that adhere to a set of conventions that lets Lua load them in a standardized way. Check the previous article [Exasol loves Lua (part 3) - Handling modules](https://exasol.my.site.com/s/article/Exasol-loves-Lua-part-3-Handling-modules "Exasol") from the same series for more background on this topic.

* When loading chunks you can now explicitly choose between text and binary import thanks to a new parameter: `load[file]([<filename> [, <mode> [, <environment>]]])`   
Both functions allow loading code into your running program.
* In the same functions you can optionally pick the [environment](http://www.lua.org/manual/5.2/manual.html#2.2 "Environments").
* You can use the function `package.searchpath(<package-name>, <path> [, <module-separator> [, <system-path-separator>]])` to locate packages in a given search path.  
This is useful if you want to understand how Lua locates packages internally since the same functions are used to load packages that are not preloaded yet.
* When Lua loads a module from a file, the loader function now receives the path to that file as a second parameter.  
It can come in handy for logging or in cases where you want to change the behavior of the module depending on the module name (e.g. to provide backward compatibility with older module versions).

## Deprecated features

* `table.maxn` was deprecated.
* Use `#` instead of `table.getn`.
* `setfenv` and `getfenv` were removed.
* The function `module` was deprecated, since building modules with plain Lua code works just fine.
* Use `\0` instead of the Character class `%z` in pattern matching.

## Esoteric Changes

Now, I know that this is highly subjective, but I needed an excuse to list some of the changes that I am assuming you will very seldom need without going into details.

* `os.execute` now returns `true` in case of success and `nil` plus an error otherwise. While that is certainly good to know in general, it is irrelevant for Exasol Lua scripts, since they don't allow `os.execute` anyway.
* Tables with weak references in keys and strong references in values are now supported and are called *ephemeron tables*. The garbage collector ignores weak references when deciding whether an object should be collected.
* *Light C functions* are pointers to C functions with no arguments used as an optimization when C functions are treated as closures (see [lua_pushcclosure](http://www.lua.org/manual/5.2/manual.html#lua_pushcclosure "Light")).
* `goto` was introduced. Goto is a knife that cuts very well. Unfortunately, that knife does not have a handle.
* The hook event "tail return" (needed for debugging [tail calls](https://en.wikipedia.org/wiki/Tail_call "Wikipedia:")) has been replaced by "[tail call](https://www.lua.org/manual/5.2/manual.html#lua_Hook "Lua")".  To give you some context: tail recursion — if done properly — allows deep recursion without running into the typical stack overflow problems.

## C API Changes

There are a couple of changes in the C API, but since most Exasol users will never need to use the C API in the Exasol scripting context, I won't go into detail in this article.

## What's next?

Since Exasol 7.1 will feature Lua 5.4, I will cover the relevant changes introduced in 5.3 and 5.4 in two upcoming articles.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 