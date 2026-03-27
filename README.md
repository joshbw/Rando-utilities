# Readme

This repo is a dumping ground/repository for random scripts for trivial stuff I was doing all the time on the command line.  I'll slowly add to it as I feel like documenting stuff.  Also, I wrote most of these something like
20 years ago, so not my finest work.  Look, its free, leave me alone.  Anyway, these make things I did all the time just a tad quicker, and maybe they will make things a tad quicker for you.

## Shell Scripts

Most utilities come as cross-platform triplets (`.cmd`, `.ps1`, `.sh`) so they work on Windows, PowerShell, and Unix-like systems.

### up

A simple little script that will navigate up a directory structure.  If no argument is provided, it will advance up 1 directory (equivalent to "cd ..").  If a numeric argument is provided, it will advance upwards that many directories, or until it hits the root drive.

*Available as: `.cmd` `.ps1` `.sh`*

#### usage

*\- Without a numeric argument -*

c:\user\joshbw> **up** 

c:\user>

*\- or with a numeric argument -*

c:\user\joshbw\source> **up 2**

c:\user>

---

### mdcd

How many times have you created a directory, and then *not* immediately gone into it?  So I suuuper cleverly just combined the two commands.  10x programmer, 5 star, would hire again.

*Available as: `.cmd` `.ps1` `.sh`*

#### usage

c:\user\joshbw> **mdcd source** 

c:\user\joshbw\source>

---

### refreshenv.cmd

So I just installed a new utility, want it in my path, so I go and add it via the environment variables UI, and then go to my already open command prompt, and when I try to use it naturally it can't find the path.  Because existing processes don't update when the global environment variables change.  So one day I got annoyed enough with that to probably look up on a website or something an example of how to pull the global variables out of the registry, and thus refreshenv.cmd.  It refreshes the environment variables.  I'm a brand name genius.

*Windows only*

#### usage

C:\Users\joshbw>**set myvar**

Environment variable myvar not defined

*\- goes and globally sets an environment variable "myvar" to "myvarvalue" -*

C:\Users\joshbw>**refreshenv**

Refreshing environment variables from registry for cmd.exe. Please wait...Finished..

C:\Users\joshbw>**set myvar**

myvar=myvarvalue

---

### setup_machine.ps1

A Windows machine provisioning script (requires admin).  Configures system settings (disable widgets, show file extensions, dark mode, left-aligned taskbar), adds the script directory to PATH, and installs common apps via winget (Git, Node.js, VS Code, etc.).  Optionally installs work tools (Slack, Docker) or gaming apps (Steam, Discord) based on the `-work` flag.

*Windows only*

#### usage

\# *Run as administrator*

PS> **.\setup_machine.ps1**

\# *Include work tools*

PS> **.\setup_machine.ps1 -work**

## External Tools

### rscalc

A cross-platform CLI calculator powered by arbitrary-precision rational arithmetic.  It's a Rust port of the Microsoft Windows Calculator engine, with an interactive REPL mode and non-interactive scripting support.  Includes three calculator modes (Standard, Scientific, Programmer) and 40+ mathematical functions.

See the [rscalc repository](https://github.com/joshbw/rscalc) for full documentation and usage.
