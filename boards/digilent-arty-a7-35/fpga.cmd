setMode -bs
setCable -port auto
Identify
identifyMPM
assignFile -p 1 -file "digilent-arty-xc7a35t.bit"
Program -p 1 -defaultVersion 0
quit
