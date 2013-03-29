<!-- Use your favorite Markdown tool to convert this and paste the HTML into the plist's extendedDescription. -->

## Overview

This plugin interacts with applications and the "Running Applications & Processes" catalog entries. Most actions can be run directly on an application (i.e. search for an application as usual, then tab and select an action).

Make sure to enable the actions you want, under Preferences > Actions > by Plugin > Process Manipulation.

If you want to be able to control background/hidden applications, go to Catalog > Applications > Running Applications & Processes > Info ("i" button in the lower right) > Source Options > Check "Include background applications". Then make sure "Running Applications & Processes" is selected. Now, you can search for "Running Applications Processes" in the Quicksilver command window and right-arrow to get a full list of processes.

IMPORTANT NOTE: Some applications have a lot of helper process. For example, iTunes has an "iTunes Helper" process, and Google Chrome has a process for each tab. If you're getting unexpected results, try opening `Activity Monitor.app` and making sure you're not missing something.

## Actions

### Lauching/Terminating

- Force Quit (Kill)
- Launch a Copy
- Launch as Root

Quicksilver also has the following actions, even if you don't install this plugin:

- Open
- Relaunch
- Open at Login
- Do Not Open at Login

### Information

- Sample Process
- List Open Files
- Get Process Identifier (PID)
    - Note that if an application has helper processes, the returned PID may not always be what you want. For example, iTunes.app will return the PID of `iTunesHelper`, and some applications may be a light frontend with a heavy kernel (which may be the process you're actually interested in).

### Signals

The operating system can interact with a process by sending it a signal.

See `man signal` or <https://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man3/signal.3.html> for a full list of signals in OSX.

- Pause Application (SIGTSTP)
    - `SIGTSTP` is useful because it completely halts the operation of a process (without quitting it) and can be resumed later. It corresponds to `Ctrl-Z` in a terminal/shell.
- Resume Application (SIGCONT)
    - Resumes an application halted with `SIGTSTP`. Note that when the program resumes, the unexpected pause might cause it to have issues with timeouts, file handles, etc. However, short pauses are usually harmless.
- Send Signal...

### Priority

What this plugin calls priority corresponds more to "niceness". This ranges from -20 (least nice, highest priority) to 20 (nicest, lowest priority). Nicer processes will more easily give up CPU time. See `man nice` and `man setpriority`.

It can be useful to lower the priority of a process to make sure the operating system stays responsive. Increasing priority isn't very useful unless you have multiple programs vying for cycles.

- Lower Priority
- Raise Priority
- Maximize Priority
- Minimize Priority
- Set Priority...
