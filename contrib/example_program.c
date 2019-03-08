// The smallest possible binary in the history of the universe.
// 16KB of BlockRAM is not enough for much - let's just write
// a simple flag value and die :-)

// Compile with:
// 
// $ sparc-elf-gcc -Os example_program.c 
// 
// $ sparc-elf-size a.out 
//    text    data     bss     dec     hex filename
//   13280    2796    1036   17112    42d8 a.out
//
// We fit! Barely :-)
//
// $ /opt/grmon-eval-3.0.15/linux/bin64/grmon -uart /dev/ttyUSB0 
//
//     GRMON LEON debug monitor v3.0.15 64-bit eval version
// 
//     Copyright (C) 2019 Cobham Gaisler - All rights reserved.
//     For latest updates, go to http://www.gaisler.com/
//     Comments or bug-reports to support@gaisler.com
// 
//     This eval version will expire on 28/08/2019
// 
//     using port /dev/ttyUSB0 @ 115200 baud
//
//     GRLIB build version: 4208
//     Detected frequency:  34.0 MHz
//     
//     Component                            Vendor
//     LEON3 SPARC V8 Processor             Cobham Gaisler
//     AHB Debug UART                       Cobham Gaisler
//     AHB/APB Bridge                       Cobham Gaisler
//     LEON3 Debug Support Unit             Cobham Gaisler
//     Single-port AHB SRAM module          Cobham Gaisler
//     Multi-processor Interrupt Ctrl.      Cobham Gaisler
//     Modular Timer Unit                   Cobham Gaisler
//     
//     Use command 'info sys' to print a detailed report of attached cores
//   
//   grmon3> load a.out 
//     40000000 .text                     13.0kB /  13.0kB   [===============>] 100%
//     400033E0 .data                      2.7kB /   2.7kB   [===============>] 100%
//     Total size: 15.70kB (124.02kbit/s)
//     Entry point 0x40000000
//     Image /home/ttsiod/Github/grlib-gpl/contrib/a.out loaded
//     
//   grmon3> run
//     Program exited normally.
//     
//   grmon3> mem 0x40000000
//     0x40000000  deadbeef  00000000  00000000  00000000    ................
//
//
// Voila! It's ALIVE, it's ALIVE...
//

int main()
{
    unsigned *p = (unsigned *)0x40000000;
    *p = 0xDEADBEEF;
}
