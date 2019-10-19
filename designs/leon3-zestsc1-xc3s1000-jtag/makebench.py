#!/usr/bin/env python2
import os
data=os.popen('zcat data.from.grmon.gz').read()
for c in data:
    print "txc(dsutx, 16#%s#, txp);" % ('%02x' % ord(c))
