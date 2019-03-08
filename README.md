# grlib-gpl

Based on Jiri-Gaisler's fork of GRLIB GPL, this was an unexpectedly 
successful attempt from a dumb SW developer to create a LEON3 inside
his FPGA board (ZestSC1).

The attempt lasted one week: from the weekend of March 2nd/3rd, and
through the evenings after work up to March 7th - at which point
I proudly watched my board react to GRMON3:

[![Video of victory](contrib/image.jpg "Video of victory.")](https://drive.google.com/open?id=13J2ZKE6PlnomnE3vvsbwIWQYlRcjLYpY)

I also kept a complete log of the attempt as I was going, [here](designs/leon3-zestsc1-xc3s1000/README.md).
(*WARNING: Do not read if you are a sane person :-)*

The main thing to take away: GHDL is a fantastic tool.

So... that's it!

I "compiled" my own CPU - another "magic thing" demystified!

And since this was done by a person that begun learning the ropes 
(of *everything*) on a SPARCstation running at 40MHz... the emotional
high of "compiling my own SPARC" in my FPGA was... priceless.

Hats off to the Gaisler people, for making things so easy that even a complete
newbie of VHDL can put the pieces together.
