# Exasol loves Lua (part 2) - Why remote logging matters and how to do it 
## Blog snapshot:

**This post will:**

* **Give you the pros and cons for all the ways you can log code**
* **Show you how to use remotelog in Lua with Exasol**
* **Walk through how to set it up - and show you how it will take the hassle out of remote coding**

Until you add logging, scripts running inside of a database are the proverbial black box. You know the input, you know what output you expect and in between is where dark magic happens. Or light magic. Depending on the use case obviously. 

As much as I like the "Use the *source*, young Padwan" approach combined with proper unit testing, in complex scenarios there always comes the point where you would like to keep tabs on what's going on inside your scripts. Thus turning the black box a few shades more into the grey. Pun intended — debugging can be very painful at times.

## What's the best way to log your database scripts?

It really depends on what you're trying to do. Here's a few options for you: 

### Table logging

While logging into tables has the advantage that you have out-of the box search tools for the log, it also means you have to deal with the locking mechanisms (mind the "ck") of the database. Exasol does not support row-locking, so if you start writing messages into a table in parallel — or even write and read in parallel — be prepared to deal with locks and the performance impact that comes with them.

### Console logging

Console logging is useful while unit testing your scripts. Less so when the scripts are running on a remote machine. Depending on the type of script, the console log ends up in the server log files. That is fine for analyzing problems at a later time, but very inconvenient during a debugging session. Especially if log messages from different scripts mix in the same file. Under some circumstances, console logging is not even available. Check the documentation of the script language you are using to see whether or not console logging is an option.

### Remote logging

Remote logging is the perfect choice if you want to watch the log, while your script is running. That is why our Virtual Schemas for example have built-in remote logging. Simply open a log listener on a machine that is reachable from the Exasol instance and enable remote logging. Voilà, you see the log output. It is not ideal for general logging in a production environment though, since the log stream is not fail-safe and the transport is not encrypted. It is a debugging tool and should be used as such.

## Lua remote logging

Since this article series focuses on developing Lua scripts for Exasol, we are going to take a look at remote logging in the Lua world. You will probably not be surprised to learn that we need remote logging for our own scripts too. And we love convenience and simplicity. This is why we wrote [`remotelog`](https://github.com/exasol/remotelog-lua "remotelog"), a Lua module that makes remote logging via a socket connection hassle-free and even allows console logging as an alternative for unit testing.

### How to access "remotelog"

`remotelog` is a single-file Lua module that only depends on Lua itself and the [LuaSocket](https://luarocks.org/modules/luasocket/luasocket "LuaSocket") module. You can either download it from our [GitHub repository](https://github.com/exasol/remotelog-lua "remotelog"), or install it from [LuaRocks](https://luarocks.org/modules/redcatbear/remotelog "remotelog").

Since LuaRocks is the established way to get Lua modules, I recommend, you try it out. As an added benefit LuaRocks automatically installs the LuaSocket dependency. Note that this dependency is preinstalled on all recent Exasol versions, so you can use it right out of the box on Exasol.


```java
luarocks install remotelog
```
Once you have `remotelog` on your machine you can use it for unit testing. There are multiple ways to use Lua modules in your Lua scripts (something I'll cover in a later blog). For now let's concentrate on getting to know `remotelog`. And for that a couple of interactive experiments on your local machine are a good first step.

### How to work with remotelog

### Step 1: console logging

If you haven't done so yet, please [install the Lua interpreter](https://www.lua.org/start.html#installing "Installing") on your machine. To follow this little tutorial, please start the Lua interpreter in interactive mode by typing the following command in a terminal.


```
lua
```
The minimum code you need is shown in the following two lines. The code is written so that you can try it out using Lua's interactive mode. In a script you would declare the log variable local.


```java
log = require("remotelog") log.info("Hello world!")
```
Alright, that's pretty unremarkable - but it's unspectacular by design!

What this does is give you a log message that looks like this:


```
2020-09-09 13:36:05 (26143.287ms) [INFO] Hello world!
```
What you see are current date and time and a high resolution time counter, that counts the time since the module was loaded. We'll go through the purpose of this one in a minute. For now, please ignore it.

Next we have the log level in square brackets followed by the actual log message.

If you now issue the following command, you will notice that no log message appears:


```java
log.debug("Wait, why don't I see this?")
```
This is less surprising when you realize the default log level is set to `INFO`.

Let's raise the detail level a bit.


```java
log.set_level("DEBUG") log.debug("There you go!") 
```
Now we get a log entry again.


```
2020-09-09 13:45:38 (598749.802ms) [DEBUG] There you go!
```
### Step 2: controlling how much you need in your logs

Control over the log level is the main feature that separates a logger from plainly print to `STDOUT` or `STDERR`. It allows you to control how much detail you need in your logs. For production level `INFO` is typically find, but when you are debugging, higher detail levels are useful that would otherwise clutter your logs.

`remotelog` offers the following log levels in ascending order of granularity and corresponding functions:

* NONE - "NONE" probably needs no explanation.
* FATAL - `fatal()`  Use this in cases where everything is lost and immediate termination of the script is the only remaining option. Think of this as the program's last words.
* ERROR - `error()`  This should be used where there is still a glimpse of hope that the calling code can deal with the problem.
* WARN - `warn()` This is for problems that are not an immediate issue, but could turn into an error soon, like low disk space.
* INFO - `info()`  This is the only non-error log level that shows up in a log by default. Use this wisely and scarcely in order to keep logs free of clutter.
* CONFIG - `config()` Use this if you want to provide information about the program's setup or environment.
* DEBUG - `debug()`This is your bread-and-butter debug output. It's detailed, but typically on a level that an experienced admin would still be able to make sense of.
* TRACE - `trace()` This is where all the internal details go that only the selected few initiates into the code can figure out. Memory maps, function traces and alike go here.

### Step 3: Timestamps and the high-resolution timer

Okay, back to the timestamps and the strange looking timer. Recording date and time down to the second level are a product of Lua's built-in `os.date()` function. If you want to change the format, take a look at the [documentation of `os.date()`](https://www.lua.org/manual/5.1/manual.html#pdf-os.date "os.date()") and check the available format strings.

Since you normally set the format before you start logging, you need to use the `init()` function of `remotelog`. This function takes two parameters, the timestamp format and a boolean value that decides whether or not the high-resolution timer should be used. The function returns the module reference, so you can directly chain it to the `require()` function.


```java
log = require("remotelog").init("%d.%m.%y", true) 
log.info("New time format.")
```
yields:


```
09.09.20 (1977022.523ms) [INFO] New time format.
```
Now let's switch off the high-res timer and see how that looks.


```java
log.init("%Y-%d-%m", false) 
log.info("Another time format.")
```
 As you can see, you can safely call `init()` again later even if that is seldom required.


```
2020-09-09 [INFO] Another time format.
```
### Using the timer for performance monitoring

You can see now that the high-res timer is gone. The reason why it exists is, that Lua does not offer sub-second time resolution. Instead we need another time source to get better precision. While being precise, this time source is not synchronized in any way with the real-time clock. That is the reason why you see milliseconds since the module was loaded instead of the milliseconds fraction of the current time. That means this timer is useful for performance monitoring by looking at differences between timer values. It is less useful as a timestamp though.

### Remote logging

So far so good. But you were being promised remote logging and all we've done so far is console logging. Let's change that, shall we?

### Step 1

First of all you need a socket log receiver, i.e. a program that can attach listen on a TCP port, wait for incoming connections and then spit out the log message you throw at it. If you are a Linux, BSD or Mac user, you are already set. All modern unix-style environments come with some variant of netcat pre-installed. The Windows fraction on the other hand has to find a suitable application and install that. The team behind Nmap provide a [portable version of netcat](https://nmap.org/ncat/ "Windows") that works nicely.

Open a new terminal and start netcat in listen mode on your machine on port 3000 and tell it to remain open after EOF signals, so that you don't have to reopen it everytime.


```
nc -lkp 3000
```
Windows users don't have the `-k` switch though. You can work around this by wrapping netcat in a batch script with a forever-loop.

### Step 2 - setting up a TCP connection

Now we tell `remotelog` to establish a TCP connection to the listening log receiver.


```java
log.connect("localhost", 3000) 
log.info("Hello netcat!") 
```
This is called a reverse connection and has the advantage of better chances in most network setups for the Exasol instance to reach the outside world instead of the other way round.

The result of this exercise should now appear on the terminal where netcat is running.


```
2020-09-09 [INFO] Connected to log receiver listening on localhost:3000 with log level DEBUG. Time zone is UTC+0200.  
2020-09-09 [INFO] Hello netcat!
```
#### What this tells us

There are a couple of interesting things to unpack here.

 First of all you see a kind of a greeting message that tells you important details about how the subsequent log messages came to exist. They come from a remote machine to the listener. The debug level is displayed and the time zone is given as reference point in case you need to compare the timestamps with logs from other time zones.

After that greeting, the log messages look just like on the console.

### Step 3

You can further improve the greeting by supplying the name of the client (i.e. your script) that is using the logger. I recommend to additionally mention the version number of your script. This helps in the field when you want to figure out, which version of your script was running when a problem surfaced.

Let's disconnect, provide a proper client name and reconnect.


```java
log.disconnect() 
log.set_client_name("remotelog-tutorial 1.0.0") 
log.connect() 
```
Now the greeting looks like this:


```
2020-09-09 [INFO] remotelog-tutorial 1.0.0: Connected to log receiver listening on localhost:3000 with log level DEBUG. Time zone is UTC+0200.
```
That's all the context you need to properly interpret the message after that point.

### Message formatting

You can either concatenate the message strings, or if you want a little bit more convenience, you can use message formatting. `remotelog` uses the same format strings as Lua's `string.format()` if you provide **two or more** parameters in a log function.


```java
log.info("%s: %d pound sugar, %d pound butter, %d pound flour, %d pound eggs. %3.0f%% awesome.",     
 "Pound cake", 1, 1, 1, 1, 100)
```
And the result of this is:


```
2020-09-09 [INFO] Pound cake: 1 pound sugar, 1 pound butter, 1 pound flour, 1 pound eggs. 100% awesome.
```
## Key points

`remotelog` is a compact Lua module with only a single external dependency. And that dependency is preinstalled on all recent Exasol versions. `remotelog` provides console and socket logging. You can change the time format, use a high-resolution timer, get a lot context through a greeting message, format message and all of that with little to no effort.

## What next?

In my next blog I will demonstrate how to bundle existing modules directly into a single script using a tool called `amalg`

