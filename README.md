# grlib-gpl

Based on Jiri-Gaisler's fork of GRLIB GPL, this was an unexpectedly 
successful attempt from a dumb SW developer to create a LEON3 inside
his FPGA board (ZestSC1).

The attempt lasted one week: from the weekend of March 2nd/3rd, and
through the evenings after work up to March 7th - at which point
I proudly watched my board react to GRMON3:

[![Video of victory](contrib/image.jpg "Video of victory.")](https://drive.google.com/open?id=13J2ZKE6PlnomnE3vvsbwIWQYlRcjLYpY)

I also kept a complete log of the attempt as I was going, [here](designs/leon3-zestsc1-xc3s1000/README.md).
(*WARNING: Do not read this if you are a sane person :-)*

*(The main thing to take away: GHDL is a fantastic tool)*.

So... that's it! I "compiled" my own CPU - another "magic thing" demystified!

And since this was done by a person that begun learning the ropes 30 years ago
on a SPARCstation running at 40MHz... the emotional high of "compiling my own
SPARC" in my FPGA was... priceless.

Hats off to the Gaisler people; for making things so easy that even a complete
newbie like me can put the pieces together.

------

And here's a session on the final version of the design:

    $ cd contrib
    $ cat example_program.c

    int main()
    {
        unsigned *p = (unsigned *)0x40000000;
        *p = 0xDEADBEEF;
    }

    $ # Use whatever cross-compiler you fancy; I used an old version of BCC
    $ sparc-elf-gcc -Os example_program.c 

    $ sparc-elf-size a.out 
       text    data     bss     dec     hex filename
      13280    2796    1036   17112    42d8 a.out

The application fits in my Block-RAM based 16KB...  Barely :-)

    $ /opt/grmon-eval-3.0.15/linux/bin64/grmon -uart /dev/ttyUSB0 

        GRMON LEON debug monitor v3.0.15 64-bit eval version

        Copyright (C) 2019 Cobham Gaisler - All rights reserved.
        For latest updates, go to http://www.gaisler.com/
        Comments or bug-reports to support@gaisler.com

        This eval version will expire on 28/08/2019

        using port /dev/ttyUSB0 @ 115200 baud

        GRLIB build version: 4208
        Detected frequency:  34.0 MHz

        Component                            Vendor
        LEON3 SPARC V8 Processor             Cobham Gaisler
        AHB Debug UART                       Cobham Gaisler
        AHB/APB Bridge                       Cobham Gaisler
        LEON3 Debug Support Unit             Cobham Gaisler
        Single-port AHB SRAM module          Cobham Gaisler
        Multi-processor Interrupt Ctrl.      Cobham Gaisler
        Modular Timer Unit                   Cobham Gaisler

        Use command 'info sys' to print a detailed report of attached cores

      grmon3> load a.out 
        40000000 .text                     13.0kB /  13.0kB   [===============>] 100%
        400033E0 .data                      2.7kB /   2.7kB   [===============>] 100%
        Total size: 15.70kB (124.02kbit/s)
        Entry point 0x40000000
        Image /home/ttsiod/Github/grlib-gpl/contrib/a.out loaded

      grmon3> run
        Program exited normally.

      grmon3> mem 0x40000000
        0x40000000  deadbeef  00000000  00000000  00000000    ................

There - it works :-)
