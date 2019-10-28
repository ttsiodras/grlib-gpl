// This programs the FPGA with our LEON3 bitfile.
//
// It is only necessary if ZestSC1 is programmed over USB; if JTAG is used,
// this program is not necessary.
//
// In the 1st working version (ZestSC1 / USB-TTL / DSU-UART), this performed
// one more task: it allowed the reset of the LEON3 after writing to a specific
// address.  This is no longer necessary, since the introduction of a simple
// state machine that resets the LEON3 in the first second (see reset_once
// signal inside TheBigLeonski.vhd for details) 

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "ZestSC1.h"

//
// Error handler function
//
void ErrorHandler(const char *Function, 
                  ZESTSC1_HANDLE Handle,
                  ZESTSC1_STATUS Status,
                  const char *Msg)
{
    (void) Handle;
    (void) Status;
    printf("**** Function %s returned an error\n        \"%s\"\n\n", Function, Msg);
    exit(1);
}

//
// Main program
//
int main(int argc, char **argv)
{
    unsigned long Count;
    unsigned long NumCards;
    unsigned long CardIDs[256];
    unsigned long SerialNumbers[256];
    ZESTSC1_FPGA_TYPE FPGATypes[256];
    ZESTSC1_HANDLE Handle;

    (void) argc;
    (void) argv;
    //
    // Install an error handler
    //
    ZestSC1RegisterErrorHandler(ErrorHandler);

    //
    // Request information about the system
    //
    ZestSC1CountCards(&NumCards, CardIDs, SerialNumbers, FPGATypes);
    printf("%ld available cards in the system\n\n\n", NumCards);
    if (NumCards==0)
    {
        printf("No cards in the system\n");
        exit(1);
    }

    for (Count=0; Count<NumCards; Count++)
    {
        printf("%ld : CardID = 0x%08lx, SerialNum = 0x%08lx, FPGAType = %d\n",
            Count, CardIDs[Count], SerialNumbers[Count], FPGATypes[Count]);
    }

    //
    // Open the first card
    //
    ZestSC1OpenCard(CardIDs[0], &Handle);

    //
    // Method 1: Configure the FPGA directly from a file
    //
    ZestSC1ConfigureFromFile(Handle, "TheBigLeonski.bit");
    puts("Programmed!");
    while(1) {
        puts("Press Enter to send a reset (q to quit)\n");
        if (getchar()=='q')
            break;
        ZestSC1WriteRegister(Handle, 0x2000, 0xFF);
        sleep(1);
        ZestSC1WriteRegister(Handle, 0x2001, 0xFF);
    }

    //
    // Close the card
    //
    ZestSC1CloseCard(Handle);

    return 0;
}
