# Exasol loves Lua (part 3) - Handling modules 
**What you will learn in this blog**

* **How Lua handles modules**
* **Which modules Exasol has preinstalled and where you can get more**
* **How you bundle modules with your scripts**
* **The responsibilities of a module distributor**

Every good software developer knows that splitting complex software into modules is necessary to achieve good code quality. Lua is no exception to this rule.

Code reuse also dictates modularization. And of course you don't want to constantly have to reinvent the wheel for basic tasks like consuming a web service. There are modules made by other developers, ready and tested for that purpose.

## Lua modules and packages - what you need to know

Lua modules are Lua files that follow a simple set of rules that allow the module loader of Lua to locate and load them. First of all there are a naming conventions for the files and their paths. Lua module names are directly derived from the filename and relative path to the Lua search path.

As with most search paths, the `LUA_PATH` is actually a semicolon-separated collection of filesystem paths. Lua scans them in the order they are listed to find a module. If the module exists in multiple paths, the module found first wins and Lua stops searching.

Under Linux a typical `LUA_PATH` contains entries like these: `/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;./?.lua;[...]`and many more. You get the idea. Under MacOS and Windows the individual elements might be different, but the concept is the same. Notice that the entries can contain the "`?`" placholder and must end in "`.lua`".

A file that from the perspective of the `LUA_PATH` can be found under `exasolvs/query_renderer.lua` is treated by Lua as if you named it `exasolvs.query_renderer`

Implementation-wise a module is a Lua regular table. This means you can do *everything* with it a regular table allows. Most of the time you will call a module's functions though. Those are regular Lua functions associated with a key in the table.

The global function `require(...)` tells the module loader to locate the module, load it if it hasn't been loaded already and hand you back the table that represents the module.

Lua remembers which packages are loaded in `package.loaded`. Keep that in mind, we will come back to this later.

## Preinstalled packages

Exasol comes with the following LuaRocks packages preinstalled:

* [cjson](https://github.com/mpx/lua-cjson/ "cjson")
* [LuaSocket](https://github.com/diegonehab/luasocket "LuaSocket")

So if you need JSON support or TCP sockets, you don't need to install anything yourself.

## How to get packages from the Lua community

As we discussed in the [previous article of this series](https://exasol.my.site.com/s/article/Exasol-loves-Lua-part-2-Why-remote-logging-matters-and-how-to-do-it "Lua") about Exasol's remotelog module , [LuaRocks](https://luarocks.org/ "LuaRocks") is the established way to get Lua modules.

If you haven't done that yet, I recommend you [install LuaRocks](https://github.com/luarocks/luarocks/wiki/Download "Downloading").

### LuaRocks Installation under Linux

Make sure that the LuaRocks module path is in the `LUA_PATH`. The `luarocks` command line utility can help you with this task by displaying the exports that you need to set.


```java
luarocks path​
```
You probably want those path changes to be persistent, so depending on your OS you will have to set the environment variables in a place that is read at OS or user session start.

After that installing a package is a simple matter of issuing the following command:


```java
sudo luarocks install <package-name>
```
I am assuming here that you want to install the package globally. If you want it to be visible only for your user or you do not have administrative privileges, you simply add the `--local` switch.

### LuaRocks Installation on MacOS

The easiest path to a [MacOS LuaRocks installation](https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-macOS "Lua") is using [Homebrew](https://brew.sh/ "Homebrew"). Assuming you already have Homebrew installed, the setup is as simple as this:


```markup
brew update 
brew install luarocks
```
 There is also the option to install the software by hand, but that is a little bit outside the scope of this article.

### LuaRocks Installation under Windows

You can use LuaRocks under Windows too. Since the installation is more complex, please refer to the [Windows installation instructions](https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Windows "Installing") on the Lua homepage.

## How do I get my own modules into Exasol?

The world is big and available modules are numerous. But how exactly do you get new modules into Exasol that are not prepackaged with the Exasol distribution?

You might have noticed that Exasol's Lua implementation does not allow filesystem access — and it does so for a good reason: security.

If you are now asking yourself how on earth you are supposed to use modules if you can't install them, let me show you a neat trick using the clever and flexible design of the Lua language.

The best way to handle modules that your Lua script depends on is to package them directly with the script. This way you make sure that versions match and that the script is self-sufficient. That also makes installing and uninstalling packages trivial.

There is one small caveat that we will discuss at the end of the article. For now let's focus on how to make a neat all-in-one bundle.

## Bundling modules: amalg

If your are looking for ways to bundle modules with your Lua scripts, you will probably come across a tool with the somewhat strange name "[amalg](https://github.com/siffiejoe/lua-amalg/ "amalg")". While that certainly does not roll of the tough too nicely, this little gem is actually quite useful.

Amalg is a single-file script written in Lua that takes a set of modules and optionally a script and embeds them into a single script.

To do so, it makes clever use of the transparency of Lua's module loading mechanisms by wrapping the source code twice: first per module in a `do ... end` block to avoid scope collisions and then in a loader function. Afterwards amalg directly associates that loader function with the module name in the `package.preload[<module-name>]` table.

Let's look at an example below. I indented the code for better readability. Amalg does not do that.


```java
do
    local _ENV = _ENV
    package.preload["remotelog"] = function( ... )
        local arg = _G.arg;
        -- actual module implementation
    end
end
```
When you run such a script, the code of the module is stored in the loader function, assigned to a key in `package.preload` that happens to be the module name.  
When your use `require("<module-name>")`, Lua first checks if the module is already loaded in `packages.loaded`. If it is not, it next checks if a loader is registered in `package.preload`. In our case it now is. Lua calls the registered loader function, and returns the module reference to the caller of `require`.

As you can see, this variant works without extra filesystem access and is therefore perfectly suited for our Exasol scenario.

## Pre-Exasol 7.1 loader extension

That being said, there is a tweak that is necessary in all Exasol versions prior to 7.1. Unlike in regular Lua installations the loader that checks `package.preload` is not available by default, so we need to register a function for that purpose first.

That means you need to prepend all bundled Lua scripts in Exasol up to and including 7.0 with the following lines:


```java
table.insert(package.loaders,
    function (module_name)
        local loader = package.preload[module_name]
        if not loader then
            error("Module " .. module_name .. " not found in package.preload.")
        else
            return loader
        end
    end
)
```
Note that in version 5.2 `package.loaders` has been renamed to `package.searchers`. While the new name definitely is more precise, this is a breaking change. If you want to support 5.1 and 5.2+, I suggest a version switch.

## How to create an actual bundle

Now that we have all the pieces in place, let's look at how you actually use amalg in a real-world scenario.

You can find a [complete command line reference](https://github.com/siffiejoe/lua-amalg "amalg") in the project's README.

Let's focus on a typical case when creating Lua scripts. For demonstration purposes I will show a minimal example that uses Exasol's `remotelog`. You might remember that module from the previous article in this series.

1. Install the `amalg` Lua rock  

```java
sudo luarocks install amalg​
```
2. If you haven't already, install the `remotelog` package from LuaRocks.  

```java
sudo luarocks install remotelog​
```
3. Create a minimal script `main.lua` that logs the Lua version number via `remotelog`.  

```java
log = require("remotelog") 
log.connect("172.17.0.1", 3000) 
log.info(_VERSION)​
```
4. Create the bundle.  

```java
amalg.lua -o bundle.lua -s main.lua remotelog
```
 The `-o` switch defines the output file, `-s` includes a regular Lua script and the last parameter names a Lua module that should be bundled. Here you can list as many modules as you want. It is required though, that the module is in the `LUA_PATH`.  
If you installed LuaRocks currectly and remembered to add the Lua rocks to the search path, amalg will find modules downloaded as Lua rocks.

You now have a combination of the `remotelog` module and the script `main.lua` in the file `bundle.lua`.

## How to create a script from a bundled module in Exasol

The last piece of the puzzle is creating a Lua script in Exasol that uses the bundle you just created. You can find the [syntax for creating Lua scripts](https://docs.exasol.com/sql/create_script.htm "CREATE") in our doc portal.

Here is a concrete example.


```java
CREATE LUA SCRIPT "BUNDLE" () AS
    table.insert(_G.package.loaders,
        function (module_name)
            local loader = package.preload[module_name]
            if not loader then
                error("Module " .. module_name .. " not found in package.preload.")
            else
                return loader
            end
        end
    )

    -- insert the bundle here
/
```
The command starts with `CREATE LUA SCRIPT <name> AS`. Then we register the searcher function that checks `package.prepload`  after that you insert the Lua code amalg produced and finally you end the command single dash in a separate line.

## When you are bundling modules, you become the distributor

It's not all just fun and games. Let's talk about serious matters for a moment — security updates and licenses in dependencies. If you start bundling external libraries, you have to be clear that you are responsible for what ends up in the bundle.

First of all make sure you read and understand the licenses your external dependencies have. The original authors deserve that you respect those licenses and only redistribute what you are allowed to.

Some software versions don't age as well as others and you have to be prepared for security vulnerabilities being found in your dependencies. When you bundle your software with external modules, you are also responsible for reacting to security fixes in your dependencies by creating and releasing updated versions of the bundle. Even your code did not change, you still should release bundle updates as quickly as possible once a security update in one of the bundled modules is available.

## Key points

Bundling modules with your Lua scripts is easy thanks to "amalg". And it gets around the restriction that Exasol Lua scripts are not allowed to access the disk to load modules.

If you bundle modules, you become a distributor, making you responsible for checking the 3rd party module licenses and providing security updates for the bundles if vulnerabilities are found in the modules you bundle.

## What next?

In the next part of our series we will discuss unit testing Lua scripts and why that is especially valuable in the context of database scripts.

