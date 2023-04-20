# Exasol loves Lua (part 5) - New in Lua 5.3 
This article picks up where [part 4 of the series](exasol-loves-lua-part-4-new-in-lua-5-2.md "Exasol") left off. We covered the changes from 5.1 to 5.2 already, so today we are going to look at what [changed with 5.3](http://www.lua.org/manual/5.3/readme.html "Lua") and as last time we will focus on the changes relevant in the context of [Exasol Lua scripts](https://docs.exasol.com/database_concepts/scripting/general_script_language.htm "General").

## New features

### Basic UTF-8 Support

Where 5.2 and earlier only handled strings with 8 bits per character, 5.3 introduced basic UTF-8 support. "Basic" meaning that the [standard library only handles the UTF-8 encoding](http://www.lua.org/manual/5.3/manual.html#6.5 "UTF-8"), but has no clue about character classes or what characters mean. So unlike recent Java libraries Lua does not support for example things like checking if a UTF-8 character is any kind of white space. 

### Integers

Lua 5.3 supports *actual* integer numbers with a width of 64 bit. While you might think that integers existed before already, that is not completely true. Until 5.2 the standard Lua interpreter emulated them with double precision floating point numbers. While you can express integers without loss using floating point numbers, they can only be as big as the mantissa of those numbers. This reduces the effective value range.

The following code demonstrates the new capability:


```lua
local the_integer = 2^62 
print(string.format("%d", the_integer))
```
You can try this out directly in the [Lua online interpreter](https://www.lua.org/cgi-bin/demo). Please don't forget that we are still talking about signed integers, so the MSB (most significant bit) is reserved for the sign.

While this generally gives you better results, it can cause incompatibilities with previous versions in cases where the values overflow.

When you have rctual integers, you also need to deal with the situation that a division leaves a rest. While regular division always returns a float, no matter the parameters, the new [floor division](https://www.lua.org/manual/5.3/manual.html#3.4.1 "Arithmetic") (`//`) rounds the result downward to the next lower integer, as show in the following example:


```lua
print(7  /  3) -- ->  2.3333333333333 
print(7  // 3) -- ->  2 
print(-7 // 3) -- -> -3 
```
### Bitwise Functions

With the advent of actual integers, [bitwise functions](https://www.lua.org/manual/5.3/manual.html#3.4.2 "Bitwise") also became a reality. The example above can alternatively be implemented with a left shift:


```lua
print(string.format("%d", 1 << 62))
```
The selection of bitwise functions is the same as in C:

* **`&`:** bitwise AND
* **`|`:** bitwise OR
* **`~`:** bitwise exclusive OR
* **`>>`:** right shift
* **`<<`:** left shift
* **`~`:** unary bitwise NOT

### Userdata changes

[Userdata](http://www.lua.org/manual/5.3/manual.html#2.1 "Values") is a Lua type that represents C data. It comes in two flavors: as pointer (light) or as object with memory managed by Lua (full).

In real-world Exasol Lua scripts you will likely only come into contact with user data if you use functions from the Lua libraries prepackaged by Exasol. [LuaSocket](https://w3.impa.br/~diego/software/luasocket/home.html "LuaSocket") for example is partially written in C.

Lua uses a virtual stack to exchange values with C. If you want to call a C function for example you put the parameters on the stack so that C can take them from there. But what if you want to have an object defined in C that you want to extend with an arbitrary Lua value? One that is not defined explicitly in the C code?

You can use the [`lua_setuservalue`](http://www.lua.org/manual/5.3/manual.html#lua_setuservalue "lua_setuservalue") and [`lua_getuservalue`](http://www.lua.org/manual/5.3/manual.html#lua_getuservalue "lua_getuservalue") functions to pop and push Lua values on the stack. If you want to see this in action, you can watch the ["Embedding Lua in C++ #14 - User Values"](https://www.youtube.com/watch?v=bZOlPANDaSM "Embedding") video. A word of warning though: you might want to refresh your memory on [Stack Machines](https://en.wikipedia.org/wiki/Stack_machine "Stack") to make it more digestible.

If you want to learn more about userdata, I recommend reading [IER2016, 31 "User Defined Types in C"].

Will you ever need this in an Exasol Lua script? Unlikely. But it is still good to know the feature exists.

### `ipairs` Changes

The [`ipairs`](https://www.lua.org/manual/5.3/manual.html#pdf-ipairs "ipairs") function is a popular function used to loop over tables with integer indices. Prior to version 5.3 customizing the behavior of this function was possible via the now deprecated `__ipairs` metamethod. While that approach still exists, there is a better way now, thanks to `ipairs` respecting regular metamethods.

### Excursion: Metamethods

As a little reminder of what metamethods are, please take a look at the following script, which allows indexing an array via Roman numerals.


```lua
local numerals = {I = 1, II = 2, III = 3, IV = 4, V = 5}

local names = {"one", "two", "three", "four", "five"}

local metatable = {
    __index = function(tbl, key)
        local index = numerals[key]
        return index and tbl[index]
    end
}

setmetatable(names, metatable)

print(names[3])
print(names.IV)
```
First we define a mapping of Roman numerals to regular numbers. Then we create an array of names. Note that  in this array (which in Lua is also a table) there is no connection between the Roman numerals and the array items. Then we override the index calculation by defining an `__index` metamethod, and assigning the table that contains that metamethod as metatable to the array. After we did this Lua now checks that metatable, realizes that the `__index` method is defined and uses it in case of index access attempts.

### `ipairs` and Metamethods

In the following script you can see that `ipairs` now takes metamethods into account. If you ran the same script with 5.2 or earlier, the outcome would be completely different, because the metamethods were simply ignored.


```lua
local weekdays = {short = "MonTueWedThuFriSatSun"}

local metatable = {
    __len = function(tbl)
        return 7
    end,
    __index = function(tbl, key)
        if(key <= #tbl) then
            local start = (key - 1) * 3 + 1
            local stop = start + 2
            return string.sub(tbl.short, start, stop)
        else
            return nil
        end
    end
}

setmetatable(weekdays, metatable)

for k, v in ipairs(weekdays) do
    print("key: " .. k .. ", value: " .. v)
end
```
You could of course argue that the script is a very complicated way to do something that could be more easily done with an array of short names. And you would be right. Nonetheless this demonstrates the power of iterating over data hidden in a user type.

## New String Features

* The `[string.dump](https://www.lua.org/manual/5.3/manual.html#pdf-string.dump "string.dump")` function exports the binary representation of a function. With 5.3 it gained a new `strip` parameter that when set to `true` removes the debug information.
* [`string.pack`](https://www.lua.org/manual/5.3/manual.html#pdf-string.pack "string.pack") is a function that turns its arguments 2 … n into a binary representation defined by the format in argument 1. An obvious use of this is if you have to implement a binary protocol.
* The matching counterpart is consequently called [`string.unpack`](https://www.lua.org/manual/5.3/manual.html#pdf-string.unpack "string.unpack") and lets you extract the components of a binary string. The first parameter is the format followed by the string to be scanned and an optional start position in the string. If you omit the start position the whole string is scanned.
* If you want to predict how long a packed string will be, use [`string.packsize`](https://www.lua.org/manual/5.3/manual.html#pdf-string.packsize "string.packsize"). Obviously this only works with fixed-length components in the format.

## Working With Table Slices

I don't know about you, but one of the features I missed most in Lua compared to other script languages like Perl was working with table slices. Luckily for us `[table.move](http://www.lua.org/manual/5.3/manual.html#pdf-table.move "table.move")` now fills that gap.

The `table.move` function takes the following parameters:

1. Table to copy from
2. Start index
3. End index
4. Target start index
5. Optional target table (defaults to the original table)

This function is quite versatile as it lets you copy a whole table, parts of tables and overwrite contents, even in the original table.

Let's look at a typical example where we start with a table that contains all days of the week and want to extract the workdays.


```lua
local week = {"mon", "tue", "wed", "thu", "fri", "sat", "sun"} 
local workdays = {} 
table.move(week, 1, 5, 1, workdays) 
print(table.concat(workdays, ", "))
```
## Other Changes

There are other changes in 5.3, but they are not relevant in the context of Exasol like changes in the standalone interpreter and the C API.

## What's Next?

In an upcoming article of the "Exasol loves Lua" series we will take a look at the changes Lua 5.4 has in store for us. That's the point were we caught up to the latest Lua version available in Exasol 7.1.

Other articles will cover unit testing, mocking and LDoc. Stay tuned!

## Bibliography

* [IER2016], "Programming in Lua, Forth Edition", *Roberto Ierusalimschy,* Lua.Org ISBN [978-85-903798-6-7](https://isbnsearch.org/isbn/9788590379867)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 