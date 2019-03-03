# Unununium
Experimental operating system written in assembly for Intel architecture

# Status: Totally unmaintained
Brought here for historical purposes.

In this repository you are going to find several different generations of the Unununium operating system.  It came close a few times to be useable for something productive but several rewrites meant the system never went mature enough to build an ecosystem on top.

Throughout those generations, you are going to see a common trend:
- No internal security protection
- One flat memory space shared by all processes/apps/*
- No "Kernel" per say, only an agglomeration of "cells" or modules together forming the basis of the system -- In our lingo we referred to this as a "VoID Kernel" since there wasn't any big or small monolithic kernel controlling everything.

Our intent back in the day was to build a system which could reload any part of itself, so if you wanted to reload a newer version of the file system drivers you could do so without rebooting.  This was proven as possible but never really implemented officially in any of the modules.

Most generations were able to allocate memory (in some capacity or another), read keyboard input keys, display stuff on the screen.  Somewhere in there you will also find some minimal 3D library, a Ext2FS implementation, some 3Com network card driver, a SoundBlaster 16 sound card driver, a minimal shell, some games, etc.

As this was a research project done by a bunch of teens, most of them without formal programming background, you can imagine the code is messy, many of the modules are buggy, style differ greatly between programmers and even by the same programmers over time.

Use any of the stuff in here are your own risk.  Don't worry there are no viruses, but replacing the boot sector of your machine with Ununium (any version) wouldn't allow you to boot back up to your original afterwards.  You'd be lucky if it even started given all the changes in BIOSes between 1999 and 2019.  If you do want to run it, the Bochs PC Emulator is probably your best bet.

Cheers and have fun!
