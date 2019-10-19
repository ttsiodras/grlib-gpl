//////////////////////////////////////////////////////////////////////
//
// File:      Example1.c
//
// Purpose:
//    ZestSC1 Example Programs
//    Simple card open/configure/close example
//  
// Copyright (c) 2004-2011 Orange Tree Technologies.
// May not be reproduced without permission.
//
//////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "ZestSC1.h"

//
// Declare configuration images
//
extern unsigned long Image400Length;
extern unsigned long Image400Image[];
extern unsigned long Image1000Length;
extern unsigned long Image1000Image[];

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
    printf("**** Example1 - Function %s returned an error\n        \"%s\"\n\n", Function, Msg);
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
