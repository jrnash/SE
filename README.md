Simulated Evolution

This program demonstrates the concept of computer evolution. It is an example of an automated system attempting to solve a problem by trial and error, making minor adjustment towards an acceptable solution, so, effectively an early implementation of Machine Learning.
 
This particular implementation is based on a similar program first written by Michael Palmiter, Temple City, CA., as described by the
article Simulated Evolution: wherein bugs learn to hunt bacteria by A.K. Dewdney in Scientific American (Computer Recreations), May 1989.

I started this project in 1991. The program is written in Borland Turbo Pascal 5.5 which is now freely available (ironically, as Antique Software). The bugs are stored in a circular double-linked list. The bugs and bacteria are stored directly in VGA video memory and when a bug checks for bacteria the program has to access each pixel of video memory surrounding a bug. It was written during the time of legacy Windows Operating systems, so it does NOT run natively on current Windows O/S (Windows 7 or Windows 10).  To run the program, you must utilize a legacy Windows Operating system (Windows XP or earlier) or, an emulator such as DOSBox that runs on Apple OSX
