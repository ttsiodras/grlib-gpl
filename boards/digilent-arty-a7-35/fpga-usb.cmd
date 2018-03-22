setMode -bscan
setCable -p usb21
identify
assignfile -p 1 -file digilent-arty-xc7a35t.bit
program -p 1
quit

