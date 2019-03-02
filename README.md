# grlib-gpl

Based on Jiri-Gaisler's fork of GRLIB GPL, this is an extremely optimistic
attempt from a SW developer to create a LEON3 inside his FPGA board (ZestSC1).

Previous (successful) attempts at programming said board are [here](https://github.com/ttsiodras/MandelbrotInVHDL/).

**UPDATE**: Attempt failed - the design can't fit in my FPGA board :-(

```
  The Slice Logic Distribution report is not meaningful if the design is
  over-mapped for a non-slice resource or if Placement fails.

  Number of bonded IOBs:                192 out of     173  110% (OVERMAPPED)
    IOB Flip Flops:                      85
  Number of RAMB16s:                     17 out of      24   70%
  Number of MULT18X18s:                   1 out of      24    4%
  Number of BUFGMUXs:                     5 out of       8   62%
  Number of DCMs:                         4 out of       4  100%
  Number of BSCANs:                       1 out of       1  100%

  Average Fanout of Non-Clock Nets:                3.57
```

(sigh)

I guess I'll try again at some point in the future, with a Leon2 - or a RISC-V Lite.
