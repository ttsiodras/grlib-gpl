# Running a grlib-gpl Leon3 inside my ZestSC1

This repo contains my (unexpectedly) successful creation of a LEON3
inside my ZestSC1 FPGA board. The work was based on the GPL version of
Gaisler's GRLIB, and was performed in one week: from the weekend of
March 2nd 2019, and all through the four evenings that followed it
(after work).

Finally, in the evening of March 7th I proudly saw my board respond to GRMON3:

[![Video of victory](contrib/image.jpg "Video of victory.")](https://drive.google.com/open?id=13J2ZKE6PlnomnE3vvsbwIWQYlRcjLYpY)

I also kept a complete log of the attempt as I was going, [here](designs/leon3-zestsc1-xc3s1000/README.md).

So... I "compiled" my own CPU! Another "magic thing" demystified :-)

And since I begun learning the ropes 30 years ago on a SPARCstation running
at 40MHz... the emotional high of "compiling my own SPARC" in my FPGA was,
well, priceless :-)

Hats off to the Gaisler people; for making things so easy that even a complete
newbie (HW-wise) like me, can actually put the pieces together.

------

The following is a session on the final version of the design running on the
ZestSC1:

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
