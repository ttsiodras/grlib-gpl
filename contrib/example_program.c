#include "my_printf.h"

int fib(int n)
{
    return n < 2 ? 1 : fib(n-2) + fib(n-1);
}

int MAIN()
{
    dbg_printf("ZestSC1's Leon3 computed fib(29) = %d\n", fib(29));
}
