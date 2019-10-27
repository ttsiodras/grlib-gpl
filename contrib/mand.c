//2006 Copyright Michael Nidermayer (BSD license)
#include <stdio.h>
#include <stdlib.h>
main(int c,char**v)
{
    float x,y,p,r,i,t,X=c>1?atof(v[1]):-.105,Y=c>2?atof(v[2]):.928;
#pragma omp parallel for
    for(p=1; p>.003; p*=.98,printf("\033[35A"))
        for(y=-1.2; y<1.2; y+=.07)
            for(x=-1.6; x<0.5; x+=.03){
                for(r=i=0,c=6; c<256 && r*r+i*i<4; c++)
                    t=r*r - i*i + x*p+X*(1-p), i=r*i*2 + y*p+Y*(1-p), r=t;
                printf("\033[7;3%dm%c\033[0;37m", c&7, x>.47?'\n':32);
            }
}
