* Quick and very dirty MCP script for BD32.
* Made by Christian Ivarsson.
* v0.00
*
* Reset MCU.
reset
* Stop MCU.
stop
*
*
*
* Configure DPTRAM @ address 0x10 0000.
mm 0xfffb04
0x0010.
mm 0xfffb06
0x0000.
mm 0xfffb00
0x0800.
*
* CFIMCR Stop.
mm 0xfff800
0x9800.
*
* Configure CMFI @ address 0x00 0000.
mm 0xfff808
0x0000.
mm 0xfff80a
0x0000.
*
* CFIMCR Enable.
mm 0xfff800
0x1800.
*
* Configure clock @ 28 MHz.
mm 0xfffa04
0xD084.
*
* Tell bd32 where the driver is/should be located.
driver $100000
*
cls
* MCP is ready.
