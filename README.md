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

**UPDATE**: Setting `CFG_GRGPIO_ENABLE` to 0 (disabling Leon's GPIO) dropped the IOBs
to 174. I am just over the limit of 173 - ARGH.

**UPDATE**: I get it now - the IOBs are exhausted because of "ghost" IO entries for
the 'data' bus. Me=idiot - all this time I thought the leon3mp component's 
memory-related signals were something the 'daddy' component would connect;
instead, these are meant to be connected over the UCF file. Kind of violating
the SW engineer's principles here - "global" (.ucf-based) connections instead of
letting the user of `leon3mp` decide how to connect things.

That's my excuse, anyway :-)

Time to properly connect my SRAM. Feeling optimistic.
