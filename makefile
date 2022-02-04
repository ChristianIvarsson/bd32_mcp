CPU_VARIANT = mcpu32
LINKER_SCRIPT = misc/MCP.ld


CC    = m68k-elf-gcc
CXX   = m68k-elf-g++
AS    = m68k-elf-as
OBC   = m68k-elf-objcopy


NAME  = MCP

ASFLAGS = -mcpu32 # --register-prefix-optional
CFLAGS  = -mcpu32  -O1 $(NEW_INSTRUCTIONS) -fomit-frame-pointer
LDFLAGS = -mcpu32 -nostdlib -Wl,-s -Wl,-n -Xlinker --gc-sections -T$(LINKER_SCRIPT) -Wl,-Map=$(basename $@).map

ifeq ($(OS),Windows_NT)
   RM = del /Q
   FixPath = $(subst /,\,$1)
else
   ifeq ($(shell uname), Linux)
	  RM = rm -f
	  FixPath = $1
   endif
endif

all:  out/dump.bin out/flash.bin out/DUMPMCP.D32 out/FLASHMCP.D32

out/dump.o: dump.s
	$(AS) $(ASFLAGS)  $< -o $@
out/flash.o: flash.s
	$(AS) $(ASFLAGS)  $< -o $@


out/dump.bin:    out/dump.o
	$(CC) $(LDFLAGS) -o $@  out/dump.o
out/DUMPMCP.D32:    out/dump.o
	$(OBC) -O srec out/dump.o $@  

out/flash.bin:    out/flash.o
	$(CC) $(LDFLAGS) -o $@  out/flash.o
out/FLASHMCP.D32:    out/flash.o
	$(OBC) -O srec out/flash.o $@  

.PHONY: clean
clean:

	@$(RM) $(call FixPath,out/*)
ifeq ($(OS),Windows_NT)
	del *.bin, *.srec
endif

