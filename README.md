# Readme

This repo is a dumping ground/repository for random scripts for trivial stuff I was doing all the time on the command line.  I'll slowly add to it as I feel like documenting stuff.  Also, I wrote most of these something like
20 years ago, so not my finest work.  Look, its free, leave me alone.  Anyway, these make things I did all the time just a tad quicker, and maybe they will make things a tad quicker for you.

## The Utilities

### up.cmd

A simple little script that will navigate up a directory structure.  If no argument is provided, it will advance up 1 directory (equivalent to "cd ..").  If a numeric argument is provided, it will advance upwards that many directories, or until it hits the root drive.

#### usage

*\- Without a numeric argument -*

c:\user\joshbw> **up** 

c:\user>

*\- or with a numeric argument -*

c:\user\joshbw\source> **up 2**

c:\user>

---

### mdcd.cmd

How many times have you created a directory, and then *not* immediately gone into it?  So I suuuper cleverly just combined the two commands.  10x programmer, 5 star, would hire again.

#### usage

c:\user\joshbw> **mdcd source** 

c:\user\joshbw\source>

---

### refreshenv.cmd

So I just installed a new utility, want it in my path, so I go and add it via the environment variables UI, and then go to my already open command prompt, and when I try to use it naturally it can't find the path.  Because existing processes don't update when the global environment variables change.  So one day I got annoyed enough with that to probably look up on a website or something an example of how to pull the global variables out of the registry, and thus refreshenv.cmd.  It refreshes the environment variables.  I'm a brand name genius.

#### usage

C:\Users\joshbw>**set myvar**

Environment variable myvar not defined

*\- goes and globally sets an environment variable "myvar" to "myvarvalue" -*

C:\Users\joshbw>**refreshenv**

Refreshing environment variables from registry for cmd.exe. Please wait...Finished..

C:\Users\joshbw>**set myvar**

myvar=myvarvalue
