/*
 *************************************************************************
 *
 *                   "DHRYSTONE" Benchmark Program
 *                   -----------------------------
 *
 *  Version:    C, Version 2.1
 *
 *  File:       dhry_1.c (part 2 of 3)
 *
 *  Date:       May 25, 1988
 *
 *  Author:     Reinhold P. Weicker
 *
 *************************************************************************
 */

// Must avoid including libc - there's simply no room!
// Here's my own minimal printf
#include "my_printf.h"

// Must measure microseconds myself, via the gptimer0
// I configure the 2nd HW timer inside it below, 
// using these nice types from RTEMS:

#pragma pack(8)
typedef struct
{
  volatile unsigned int value;
  volatile unsigned int reload;
  volatile unsigned int conf;
  volatile unsigned int notused;
} LEON3_Timer_SubType;
#pragma pack()

#pragma pack(8)
typedef struct
{
  volatile unsigned int scaler_value; /* common timer registers */
  volatile unsigned int scaler_reload;
  volatile unsigned int status;
  volatile unsigned int notused;
  LEON3_Timer_SubType timer[8];
} LEON3_Timer_Regs_Map;
#pragma pack()

// In my FPGA design, the gptimer0 lives in this offset
static LEON3_Timer_Regs_Map *tregs = (LEON3_Timer_Regs_Map *) 0x80000300;

// Avoid libc at all costs!
char* my_strcpy(char *dst0, const char * src0)
{
    char *s = dst0;

    /* copy the source to the destination */
    while(*dst0++ = *src0++);

    return s;
}

int my_strcmp(const char *s1, const char *s2)
{
    /* check if s1 and s2 vectors are equal */
    while(*s1 != '\0' && *s1 == *s2)
    {
        s1++;
        s2++;
    }

    /* return the difference of the last char on the string */
    return (*(unsigned char *) s1) - (*(unsigned char *) s2);
}

void *memcpy(char *d, const char *s, unsigned l)
{
    while (l--) *d++ = *s++;
}

////////////////////////////////////////////
// Back into Dhrystone original source code.
////////////////////////////////////////////

#define structassign(d, s)      d = s

typedef       enum    {Ident_1, Ident_2, Ident_3, Ident_4, Ident_5} Enumeration;

/* General definitions: */

#define Null 0 
                /* Value of a Null pointer */
#define true  1
#define false 0

typedef int     One_Thirty;
typedef int     One_Fifty;
typedef char    Capital_Letter;
typedef int     Boolean;
typedef char    Str_30 [31];
typedef int     Arr_1_Dim [25];        /* <-- changed from 50 */
typedef int     Arr_2_Dim [25] [25];   /* <-- changed from 50 */

typedef struct record 
{
    struct record *Ptr_Comp;
    Enumeration    Discr;
    union {
        struct {
            Enumeration Enum_Comp;
            int         Int_Comp;
            char        Str_Comp [31];
        } var_1;
        struct {
            Enumeration E_Comp_2;
            char        Str_2_Comp [31];
        } var_2;
        struct {
            char        Ch_1_Comp;
            char        Ch_2_Comp;
        } var_3;
    } variant;
} Rec_Type, *Rec_Pointer;

/*  Prototypes of function defined in dhry21b.c and called from dhry21a.c.  */
void Proc_6( Enumeration Enum_Val_Par, Enumeration * Enum_Ref_Par );
void Proc_7( One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val,
                                                      One_Fifty * Int_Par_Ref );
void Proc_8( Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref,
                                         int Int_1_Par_Val, int Int_2_Par_Val );
Enumeration Func_1( Capital_Letter Ch_1_Par_Val, Capital_Letter Ch_2_Par_Val );
Boolean Func_2( Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref );


/* Global Variables: */

Rec_Pointer     Ptr_Glob,
                Next_Ptr_Glob;
int             Int_Glob;
Boolean         Bool_Glob;
char            Ch_1_Glob,
                Ch_2_Glob;
int             Arr_1_Glob [25];        /* <-- changed from 50 */
int             Arr_2_Glob [25] [25];   /* <-- changed from 50 */

char Reg_Define[] = "Register option selected.";

#define REG register

/* variables for time measurement: */

#define Too_Small_Time 2000000
                /* Measurements should last at least 2 seconds */

unsigned  Begin_Time, End_Time, User_Time;

// No, can't do; my FPGA design has no FPU, and I can't afford 
// soft-float - not enough memory!
// double Microseconds, Dhrystones_Per_Second, Vax_Mips;

/* end of variables for time measurement */

void Proc_1( REG Rec_Pointer Ptr_Val_Par );
void Proc_2( One_Fifty * Int_Par_Ref );
void Proc_3( Rec_Pointer * Ptr_Ref_Par );
void Proc_4( void );
void Proc_5( void );

/* main program, corresponds to procedures        */
/* Main and Proc_0 in the Ada version             */
void dhry()
{

          One_Fifty       Int_1_Loc;
    REG   One_Fifty       Int_2_Loc;
          One_Fifty       Int_3_Loc;
    REG   char            Ch_Index;
          Enumeration     Enum_Loc;
          Str_30          Str_1_Loc;
          Str_30          Str_2_Loc;
    REG   int             Run_Index;
    REG   int             Number_Of_Runs;

    // These two were malloc-ed - but can't afford heap,
    // get them on the stack instead :-)
    Rec_Type        A_Rec_Type;
    Rec_Type        B_Rec_Type;

    /* Initializations */
    dbg_printf("Dhrystone Benchmark, Version 2.1 (Language: C)\n");

    Next_Ptr_Glob = &A_Rec_Type;
    Ptr_Glob = &B_Rec_Type;

    Ptr_Glob->Ptr_Comp                    = Next_Ptr_Glob;
    Ptr_Glob->Discr                       = Ident_1;
    Ptr_Glob->variant.var_1.Enum_Comp     = Ident_3;
    Ptr_Glob->variant.var_1.Int_Comp      = 40;
    my_strcpy (Ptr_Glob->variant.var_1.Str_Comp, "DHRYSTONE PROGRAM, SOME STRING");
    my_strcpy (Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");

    Arr_2_Glob [8][7] = 10;
    /* Was missing in published program. Without this statement,    */
    /* Arr_2_Glob [8][7] would have an undefined value.             */
    /* Warning: With 16-Bit processors and Number_Of_Runs > 32000,  */
    /* overflow may occur for this array element.                   */

    Number_Of_Runs = 300000;

    dbg_printf("Execution starts, ");
    dbg_printf("%u runs through Dhrystone\n", Number_Of_Runs);

    /***************/
    /* Start timer */
    /***************/

    End_Time = tregs->timer[1].value;

    for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index) {
        Proc_5();
        Proc_4();
        /* Ch_1_Glob == 'A', Ch_2_Glob == 'B', Bool_Glob == true */
        Int_1_Loc = 2;
        Int_2_Loc = 3;
        my_strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
        Enum_Loc = Ident_2;
        Bool_Glob = ! Func_2 (Str_1_Loc, Str_2_Loc);

        /* Bool_Glob == 1 */
        while (Int_1_Loc < Int_2_Loc)  /* loop body executed once */
        {
            Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
            /* Int_3_Loc == 7 */
            Proc_7 (Int_1_Loc, Int_2_Loc, &Int_3_Loc);
            /* Int_3_Loc == 7 */
            Int_1_Loc += 1;
        } /* while */

        /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
        Proc_8 (Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);

        /* Int_Glob == 5 */
        Proc_1 (Ptr_Glob);

        for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index)
            /* loop body executed twice */
        {
            if (Enum_Loc == Func_1 (Ch_Index, 'C'))
                /* then, not executed */
            {
                Proc_6 (Ident_1, &Enum_Loc);
                my_strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
                Int_2_Loc = Run_Index;
                Int_Glob = Run_Index;
            }
        }

        /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
        Int_2_Loc = Int_2_Loc * Int_1_Loc;
        Int_1_Loc = Int_2_Loc / Int_3_Loc;
        Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;

        /* Int_1_Loc == 1, Int_2_Loc == 13, Int_3_Loc == 7 */
        Proc_2 (&Int_1_Loc);

        /* Int_1_Loc == 5 */

    } /* loop "for Run_Index" */

    /**************/
    /* Stop timer */
    /**************/
    Begin_Time = tregs->timer[1].value;

    // Due to the way I measure time - with a HW timer going down from 0xFFFFFFFF - 
    // the Begin_Time and End_Time have to be swapped.

    dbg_printf("Execution ends\n");

    dbg_printf ("\r\n");
    dbg_printf ("Final values of the variables used in the benchmark:\r\n");
    dbg_printf ("\r\n");
    dbg_printf ("Int_Glob:            %d\r\n", Int_Glob);
    dbg_printf ("        should be:   %d\r\n", 5);
    dbg_printf ("Bool_Glob:           %d\r\n", Bool_Glob);
    dbg_printf ("        should be:   %d\r\n", 1);
    dbg_printf ("Ch_1_Glob:           %c\r\n", Ch_1_Glob);
    dbg_printf ("        should be:   %c\r\n", 'A');
    dbg_printf ("Ch_2_Glob:           %c\r\n", Ch_2_Glob);
    dbg_printf ("        should be:   %c\r\n", 'B');
    dbg_printf ("Arr_1_Glob[8]:       %d\r\n", Arr_1_Glob[8]);
    dbg_printf ("        should be:   %d\r\n", 7);
    dbg_printf ("Arr_2_Glob[8][7]:    %d\r\n", Arr_2_Glob[8][7]);
    dbg_printf ("        should be:   Number_Of_Runs + 10\r\n");
    dbg_printf ("Ptr_Glob->\r\n");
    dbg_printf ("  Ptr_Comp:          %d\r\n", (int) Ptr_Glob->Ptr_Comp);
    dbg_printf ("        should be:   (implementation-dependent)\r\n");
    dbg_printf ("  Discr:             %d\r\n", Ptr_Glob->Discr);
    dbg_printf ("        should be:   %d\r\n", 0);
    dbg_printf ("  Enum_Comp:         %d\r\n", Ptr_Glob->variant.var_1.Enum_Comp);
    dbg_printf ("        should be:   %d\r\n", 2);
    dbg_printf ("  Int_Comp:          %d\r\n", Ptr_Glob->variant.var_1.Int_Comp);
    dbg_printf ("        should be:   %d\r\n", 17);
    dbg_printf ("  Str_Comp:          %s\r\n", Ptr_Glob->variant.var_1.Str_Comp);
    dbg_printf ("        should be:   DHRYSTONE PROGRAM, SOME STRING\r\n");
    dbg_printf ("Next_Ptr_Glob->\r\n");
    dbg_printf ("  Ptr_Comp:          %d\r\n", (int) Next_Ptr_Glob->Ptr_Comp);
    dbg_printf ("        should be:   (implementation-dependent), same as above\r\n");
    dbg_printf ("  Discr:             %d\r\n", Next_Ptr_Glob->Discr);
    dbg_printf ("        should be:   %d\r\n", 0);
    dbg_printf ("  Enum_Comp:         %d\r\n", Next_Ptr_Glob->variant.var_1.Enum_Comp);
    dbg_printf ("        should be:   %d\r\n", 1);
    dbg_printf ("  Int_Comp:          %d\r\n", Next_Ptr_Glob->variant.var_1.Int_Comp);
    dbg_printf ("        should be:   %d\r\n", 18);
    dbg_printf ("  Str_Comp:          %s\r\n", Next_Ptr_Glob->variant.var_1.Str_Comp);
    dbg_printf ("        should be:   DHRYSTONE PROGRAM, SOME STRING\r\n");
    dbg_printf ("Int_1_Loc:           %d\r\n", Int_1_Loc);
    dbg_printf ("        should be:   %d\r\n", 5);
    dbg_printf ("Int_2_Loc:           %d\r\n", Int_2_Loc);
    dbg_printf ("        should be:   %d\r\n", 13);
    dbg_printf ("Int_3_Loc:           %d\r\n", Int_3_Loc);
    dbg_printf ("        should be:   %d\r\n", 7);
    dbg_printf ("Enum_Loc:            %d\r\n", Enum_Loc);
    dbg_printf ("        should be:   %d\r\n", 1);
    dbg_printf ("Str_1_Loc:           %s\r\n", Str_1_Loc);
    dbg_printf ("        should be:   DHRYSTONE PROGRAM, 1'ST STRING\r\n");
    dbg_printf ("Str_2_Loc:           %s\r\n", Str_2_Loc);
    dbg_printf ("        should be:   DHRYSTONE PROGRAM, 2'ND STRING\r\n");
    dbg_printf ("\r\n");

    User_Time = End_Time - Begin_Time;

    if (User_Time < Too_Small_Time) {
        dbg_printf("Measured time (%u) is too small to obtain meaningful results\n", User_Time);
        dbg_printf("Please increase number of runs\n");
    } else {
        dbg_printf("Took: %u milliseconds\n", User_Time/1000);
        dbg_printf("Dhrystones/sec: %u\n", (unsigned) ((1000000ULL*Number_Of_Runs) / User_Time));
        dbg_printf("VAX MIPS: %u\n", (unsigned) ((1000000ULL*Number_Of_Runs) / User_Time / 1757));
    }
}

int MAIN() {
    tregs->timer[1].reload = 0xFFFFFFFF;
    tregs->timer[1].conf = 0x5;
    dhry();
}

void Proc_1( REG Rec_Pointer Ptr_Val_Par )
/******************/
    /* executed once */
{
  REG Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;  
                                        /* == Ptr_Glob_Next */
  /* Local variable, initialized with Ptr_Val_Par->Ptr_Comp,    */
  /* corresponds to "rename" in Ada, "with" in Pascal           */
  
  structassign (*Ptr_Val_Par->Ptr_Comp, *Ptr_Glob);
  Ptr_Val_Par->variant.var_1.Int_Comp = 5;
  Next_Record->variant.var_1.Int_Comp 
        = Ptr_Val_Par->variant.var_1.Int_Comp;
  Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3 (&Next_Record->Ptr_Comp);
    /* Ptr_Val_Par->Ptr_Comp->Ptr_Comp 
                        == Ptr_Glob->Ptr_Comp */
  if (Next_Record->Discr == Ident_1)
    /* then, executed */
  {
    Next_Record->variant.var_1.Int_Comp = 6;
    Proc_6 (Ptr_Val_Par->variant.var_1.Enum_Comp, 
           &Next_Record->variant.var_1.Enum_Comp);
    Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
    Proc_7 (Next_Record->variant.var_1.Int_Comp, 10, 
           &Next_Record->variant.var_1.Int_Comp);
  }
  else /* not executed */
    structassign (*Ptr_Val_Par, *Ptr_Val_Par->Ptr_Comp);
} /* Proc_1 */


void Proc_2( One_Fifty * Int_Par_Ref )
/******************/
    /* executed once */
    /* *Int_Par_Ref == 1, becomes 4 */
{
  One_Fifty  Int_Loc;
  Enumeration   Enum_Loc;

  Int_Loc = *Int_Par_Ref + 10;
  do /* executed once */
    if (Ch_1_Glob == 'A')
      /* then, executed */
    {
      Int_Loc -= 1;
      *Int_Par_Ref = Int_Loc - Int_Glob;
      Enum_Loc = Ident_1;
    } /* if */
  while (Enum_Loc != Ident_1); /* true */
} /* Proc_2 */


void Proc_3( Rec_Pointer * Ptr_Ref_Par )
/******************/
    /* executed once */
    /* Ptr_Ref_Par becomes Ptr_Glob */
{
  if (Ptr_Glob != Null)
    /* then, executed */
    *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
  Proc_7 (10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
} /* Proc_3 */


void Proc_4( void ) /* without parameters */
/*******/
    /* executed once */
{
  Boolean Bool_Loc;

  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
} /* Proc_4 */


void Proc_5( void ) /* without parameters */
/*******/
    /* executed once */
{
  Ch_1_Glob = 'A';
  Bool_Glob = false;
} /* Proc_5 */


/*
 *************************************************************************
 *
 *                   "DHRYSTONE" Benchmark Program
 *                   -----------------------------
 *
 *  Version:    C, Version 2.1
 *
 *  File:       dhry_2.c (part 3 of 3)
 *
 *  Date:       May 25, 1988
 *
 *  Author:     Reinhold P. Weicker
 *
 *************************************************************************
 */


Boolean Func_3( Enumeration Enum_Par_Val );

void Proc_6( Enumeration Enum_Val_Par, Enumeration * Enum_Ref_Par )
/*********************************/
    /* executed once */
    /* Enum_Val_Par == Ident_3, Enum_Ref_Par becomes Ident_2 */
{
  *Enum_Ref_Par = Enum_Val_Par;
  if (! Func_3 (Enum_Val_Par))
    /* then, not executed */
    *Enum_Ref_Par = Ident_4;
  switch (Enum_Val_Par)
  {
    case Ident_1: 
      *Enum_Ref_Par = Ident_1;
      break;
    case Ident_2: 
      if (Int_Glob > 100)
        /* then */
      *Enum_Ref_Par = Ident_1;
      else *Enum_Ref_Par = Ident_4;
      break;
    case Ident_3: /* executed */
      *Enum_Ref_Par = Ident_2;
      break;
    case Ident_4: break;
    case Ident_5: 
      *Enum_Ref_Par = Ident_3;
      break;
  } /* switch */
} /* Proc_6 */


void Proc_7( One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val,
                                                       One_Fifty * Int_Par_Ref )
/**********************************************/
    /* executed three times                                      */
    /* first call:      Int_1_Par_Val == 2, Int_2_Par_Val == 3,  */
    /*                  Int_Par_Ref becomes 7                    */
    /* second call:     Int_1_Par_Val == 10, Int_2_Par_Val == 5, */
    /*                  Int_Par_Ref becomes 17                   */
    /* third call:      Int_1_Par_Val == 6, Int_2_Par_Val == 10, */
    /*                  Int_Par_Ref becomes 18                   */
{
  One_Fifty Int_Loc;

  Int_Loc = Int_1_Par_Val + 2;
  *Int_Par_Ref = Int_2_Par_Val + Int_Loc;
} /* Proc_7 */


void Proc_8( Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref,
                                          int Int_1_Par_Val, int Int_2_Par_Val )
/*********************************************************************/
    /* executed once      */
    /* Int_Par_Val_1 == 3 */
    /* Int_Par_Val_2 == 7 */
{
  REG One_Fifty Int_Index;
  REG One_Fifty Int_Loc;

  Int_Loc = Int_1_Par_Val + 5;
  Arr_1_Par_Ref [Int_Loc] = Int_2_Par_Val;
  Arr_1_Par_Ref [Int_Loc+1] = Arr_1_Par_Ref [Int_Loc];
  Arr_1_Par_Ref [Int_Loc+15] = Int_Loc;
  for (Int_Index = Int_Loc; Int_Index <= Int_Loc+1; ++Int_Index)
    Arr_2_Par_Ref [Int_Loc] [Int_Index] = Int_Loc;
  Arr_2_Par_Ref [Int_Loc] [Int_Loc-1] += 1;
  Arr_2_Par_Ref [Int_Loc+10] [Int_Loc] = Arr_1_Par_Ref [Int_Loc];
  Int_Glob = 5;
} /* Proc_8 */


Enumeration Func_1 ( Capital_Letter Ch_1_Par_Val, Capital_Letter Ch_2_Par_Val )
/*************************************************/
    /* executed three times                                         */
    /* first call:      Ch_1_Par_Val == 'H', Ch_2_Par_Val == 'R'    */
    /* second call:     Ch_1_Par_Val == 'A', Ch_2_Par_Val == 'C'    */
    /* third call:      Ch_1_Par_Val == 'B', Ch_2_Par_Val == 'C'    */
{
  Capital_Letter        Ch_1_Loc;
  Capital_Letter        Ch_2_Loc;

  Ch_1_Loc = Ch_1_Par_Val;
  Ch_2_Loc = Ch_1_Loc;
  if (Ch_2_Loc != Ch_2_Par_Val)
    /* then, executed */
    return (Ident_1);
  else  /* not executed */
  {
    Ch_1_Glob = Ch_1_Loc;
    return (Ident_2);
   }
} /* Func_1 */


Boolean Func_2( Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref )
/*************************************************/
    /* executed once */
    /* Str_1_Par_Ref == "DHRYSTONE PROGRAM, 1'ST STRING" */
    /* Str_2_Par_Ref == "DHRYSTONE PROGRAM, 2'ND STRING" */
{
  REG One_Thirty        Int_Loc;
      Capital_Letter    Ch_Loc;

  Int_Loc = 2;
  while (Int_Loc <= 2) /* loop body executed once */
    if (Func_1 (Str_1_Par_Ref[Int_Loc],
                Str_2_Par_Ref[Int_Loc+1]) == Ident_1)
      /* then, executed */
    {
      Ch_Loc = 'A';
      Int_Loc += 1;
    } /* if, while */
  if (Ch_Loc >= 'W' && Ch_Loc < 'Z')
    /* then, not executed */
    Int_Loc = 7;
  if (Ch_Loc == 'R')
    /* then, not executed */
    return (true);
  else /* executed */
  {
    if (my_strcmp (Str_1_Par_Ref, Str_2_Par_Ref) > 0)
      /* then, not executed */
    {
      Int_Loc += 7;
      Int_Glob = Int_Loc;
      return (true);
    }
    else /* executed */
      return (false);
  } /* if Ch_Loc */
} /* Func_2 */


Boolean Func_3( Enumeration Enum_Par_Val )
/***************************/
    /* executed once        */
    /* Enum_Par_Val == Ident_3 */
{
  Enumeration Enum_Loc;

  Enum_Loc = Enum_Par_Val;
  if (Enum_Loc == Ident_3)
    /* then, executed */
    return (true);
  else /* not executed */
    return (false);
} /* Func_3 */
