# Running a grlib-gpl Leon3 inside my ZestSC1

This repo contains my (unexpectedly) successful creation of a LEON3
inside my ZestSC1 FPGA board. The work was based on the GPL version of
Gaisler's GRLIB, and was performed in one week: from the weekend of
March 2nd 2019, and all through the four evenings that followed it
(after work).

Finally, in the evening of March 7th I proudly saw my board respond to GRMON3:

[![Video of victory](contrib/image.jpg "Video of victory.")](https://youtu.be/Ylixb0AWAkQ)

I also kept a complete log of the attempt as I was going, [here](designs/leon3-zestsc1-xc3s1000/README.md).

So... I "compiled" my own CPU! Another "magic thing" demystified :-)

And since I begun learning the ropes 30 years ago on a SPARCstation running
at 40MHz... the emotional high of "compiling my own SPARC" in my FPGA was,
well, priceless :-)

Hats off to the Gaisler people; for making things so easy that even a complete
newbie (HW-wise) like me, can actually put the pieces together.

**UPDATE**: Here's the [complete log](contrib/dhrystone.txt) of the execution
of the Dhrystone 2.1 benchmark in my Leon3; a benchmark that I barely managed
to squeeze in my puny 16KB of BlockRAM :-)

**UPDATE**, many months later:  I got my hands on a Pano Logic G2, thanks
to the [magnificent Tom Verbeure](https://github.com/tomverbeure/panologic-g2).

After soldering my, erm, custom JTAG "adapter"...

![Soldering JTAG...](contrib/pano-1.jpg "Soldering JTAG...")

![Soldering other end of JTAG...](contrib/pano-2.jpg "Soldering other end of JTAG...")

...I was able to "see" the board from my Arch Linux:

![Natively seeing an LX100 under Arch Linux, with the free WebPACK](contrib/pano-3.jpg "Natively seeing an LX100 under Arch Linux, with the free WebPACK")

...and two evenings later, I bootstrapped a Leon3 again - but this time,
via JTAG *(order(s) of magnitude faster than UART)*, and since the XC6LX100
is a monster (compared to the Spartan3), with 16 times more memory!

![A Leon3 inside a Pano Logic G2](contrib/pano-4.jpg "A Leon3 inside a Pano Logic G2")

Wondering now, if I can fit more than one Leon3 here. Hmm...

In any case, I need to write a blog post about this - I've done too many things,
that must be documented.
