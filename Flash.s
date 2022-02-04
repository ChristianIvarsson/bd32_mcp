.include "misc/ipd.inc"
.long    Init                /* First address must contain offset to start */

.equ CMFIMCR   , 0xFFF800
.equ CMFICTL1  , 0xFFF80C
.equ CMFICTL2  , 0xFFF80E

# inefficient but easy to copy to new projects
Init:
    lea.l   Stack             , %sp
    move.l  #160              , %d7  
    adda.l  %d7               , %sp
    
    # Disable shadow
    andi.w  #0xDFFF           , (CMFIMCR)

#   Wait for a while
DelayL:    
    bsr.b   swsr
    dbra    %d7, DelayL

#   Backup Number of paramters and pointer
    move.l  %d0               , %d7
    move.l  %a0               , %a6

#   Install vector table
    lea.l   VecTab            , %a1
    lea.l   ExceptionErr      , %a2
    movec   %a1               , %vbr
    moveq.l #39               , %d0

InsVec:
    move.l  %a2               ,(%a1)+
    dbra    %d0, InsVec

    clr.l   (FILE, %a5)                 /* Clear file handle. Not really needed since skip-sections are filled with 00's */

#   Check number of parameters
    cmp.w   #2                , %d7
    beq.b   CheckOpen
    /* Failed                    */
    moveq.l #4                , %d1     /* Store status  */
PrecheckFailed:
    moveq.l #BD_QUIT          , %d0     /* Store command */
bgnd

CheckOpen:
    move.l  (4, %a6)          , %a0     /* Load pointer to filename */
    lea.l   FMODE             , %a1     /* Load pointer to mode     */
    moveq   #BD_FOPEN         , %d0     /* Store command            */
bgnd
    tst.l   %d0
    beq.b   HandleErr
    move.l  %d0               , (FILE, %a5) /* Store file handle    */
    bra.b   Main
HandleErr:
#   Received null; Exit!
    moveq.l #2                , %d1
    bra.b   PrecheckFailed

swsr:
    move.b  #0x55    ,(0xFFFA27)
    move.b  #0xAA    ,(0xFFFA27)
rts

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Main

Main:

    lea.l   ErasingFlsh       , %a0
    bsr.b   PutString

    # I'm tired of bd32's weird register usage. Off to the stack it goes!
    movem.l %a1-%a6/%d1-%d7,-(%sp)
    
    movea.l #CMFIMCR          , %a2    /* Store useful shortcuts */
    movea.l #CMFICTL1         , %a3
    movea.l #CMFICTL2         , %a4

    # Erase flash
    bsr.w   EraseCMFI
    
    lea.l   FlashMain         , %a0
    bsr.b   PutString
    
    # Write flash
    bsr.w   WriteCMFI

    movem.l (%sp)+,%a1-%a6/%d1-%d7

FlashDone:
    clr.l   %d7
    lea.l   DoneMSG           , %a0
    bsr.b   PutString
    
EndSession:
    move.l  (FILE, %a5)       , %d1
    beq.b   FileisClosed
    moveq.l #BD_FCLOSE        , %d0
bgnd
    bsr.w   swsr
FileisClosed:
    move.l  %d7               , %d1
    moveq.l #BD_QUIT          , %d0
bgnd

#   Error-handlers
ReadErr:
    moveq.l #1                , %d7
    bra.b   EndSession
ExceptionErr:
    moveq.l #3                , %d7
    bra.b   EndSession
EraseErr:
    moveq.l #5                , %d7
    bra.b   EndSession
WriteErr:
    moveq.l #6                , %d7
    bra.b   EndSession

PutString:
    moveq   #BD_PUTS          , %d0
    bgnd
    bsr.b   swsr
rts


# Notes:
# Regular partitions are 32768 bytes long
# Shadow is 256 bytes

# While writing each page is 64 bytes (And bound to it)

# _NO-TOUCH_ regs!
# %a2: CFIMCR
# %a3: CMFICTL1
# %a4: CMFICTL2

# Unusable regs due to FREAD, PRINTCHAR or file handle:
# %a0: Address to buffer
# %a5: Start of driver

# %d0: Read bytes
# %d1: File handle
# %d2: Bytes to read

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Write functions


# %a0: Address of databuffer
# %a1: Address to write
# %d0: Number of bytes to write
WriteBuffer:
    move.l  %a5               , %d7    /* Backup a5                      */

    # Check if page has to be written / Has been written
VerifComp:
    bsr.w   swsr
    move.l  %a0               , %a5    /* Backup where to read           */
    move.l  %a1               , %a6    /* Backup where to write          */
    moveq.l #64               , %d5    /* Number of bytes to compare     */

PageCmpL:
    cmpm.w  (%a5)+            ,(%a6)+
    bne.b   WritePage
    subq.l  #2                , %d5
    bne.b   PageCmpL
    move.l  %a5               , %a0    /* Update where to read           */
    move.l  %a6               , %a1    /* Update where to write          */
    sub.l   #64               , %d0
    bne.b   VerifComp
    movea.l %d7               , %a5    /* Restore a5                     */
rts

WritePage:
    move.l  %a1               , %d5
    move.w  #0x100            , %d1
    lsr.l   #8                , %d5    /* (Address >> 15)                */
    lsr.l   #7                , %d5
    lsl.w   %d5               , %d1    /* 0x100 << x                     */
    move.b  #0x32             , %d1
    
    # Start session
    move.w  %d1               ,(%a4)   /* CMFICTL2                       */
    move.l  %a0               , %a5    /* Backup where to read           */
    move.l  %a1               , %a6    /* Backup where to write          */
    moveq.l #64               , %d5    /* Size of page                   */

PageFill:
    move.w  (%a5)+            ,(%a6)+
    subq.w  #2                , %d5
    bne.b   PageFill
    
WritePulse:
    ori.w   #0x0001           ,(%a4)   /* Enable high voltage            */
VppActiveW:                            /* Wait for VPP to go low         */
    bsr.w   swsr
    tst.w   (%a3)
    bmi.b   VppActiveW
    andi.w  #0xFFFE           ,(%a4)   /* Disable High voltage           */

    # Perform margain read
    moveq.l #64               , %d5    /* Size of page                   */
    move.l  %a1               , %a6    /* Backup where to write          */
MargainLW:
    tst.b   (%a6)+
    bne.b   WritePulse
    subq.b  #1                , %d5
    bne.b   MargainLW
    andi.w  #0xFFFD           ,(%a4)   /* Negate session                 */
    bra.b   VerifComp                  /* Go back for verification       */

# # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # #

WriteCMFI:

    # Make sure shadow-access is off before starting!
    bsr.b   DisShadow
    
    move.l  #1024             , %d3    /* Default number of bytes to read   */
LastRestart:    
    suba.l  %a1               , %a1    /* Start from address 0              */

WriteLoop:    
    
    # Tell bd32 to fill buffer
    lea.l   Databuf           , %a0    /* Pointer to our buffer             */
    moveq.l #BD_FREAD         , %d0    /* Command                           */
    move.l  (FILE, %a5)       , %d1    /* File handle                       */
    move.l  %d3               , %d2    /* How many bytes do we want?        */
    bgnd
    bsr.w   swsr

    cmp.w   %d0               , %d3    /* Check number of read bytes        */
    bne.w   ReadErr                    /* Could not read enough data!!      */
    bsr.w   WriteBuffer

    moveq.l #BD_PUTCHAR       , %d0    /* Call printchar                    */
    moveq.l #0x2E             , %d1    /* Character to print                */
    bgnd
    bsr.w   swsr

    cmpi.w  #256              , %d3    /* Catch shadow-write                */
    beq.b   FlashReturn
    cmpa.l  #0x40000          , %a1    /* Check if last address hans been reached */
    blt.b   WriteLoop

    bsr.b   EnaShadow
    move.w  #256              , %d3    /* Write 256 bytes this time         */
    
    lea.l   FlashSHDW         , %a0
    bsr.w   PutString
    bra.b   LastRestart

FlashReturn: 
rts

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Shared: Write / Erase

# Helper: Enable / disable shadow access
DisShadow:
    bsr.w   swsr
    andi.w  #0xDFFF           ,(%a2)
rts
EnaShadow:
    bsr.w   swsr
    ori.w   #0x2000           ,(%a2)
rts

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Erase functions
# %a0: Start
# %d1: Number of bytes to check. Will return 0 if everything is verified
VerifBlock:
    move.l  %a0               , %a6
VerifL:
    cmpi.w  #0xFFFF           , (%a6)+
    bne.b   VerifRet
    subq.w  #2                , %d1
    bne.b   VerifL
VerifRet:
rts

# %d0: Partition number 0 - 7 (Shadow is part of partition 0)
ErasePartition:

    move.l  %d0               , %d3    /* Work on a copy of %d0                         */
    move.w  #0x100            , %d2    /* Figure out which block to enable              */
    lsl.w   %d3               , %d2    /* Shift block enabler to the left if required   */
    mulu.l  #32768            , %d3    /* Calculate first address and store it in %a0   */
    mova.l  %d3               , %a0

    move.b  #0x36             , %d2    /* Start session                                 */
    move.w  %d2               ,(%a4)
    move.w  #0xFFFF           ,(%a0)   /* Erase interlock                               */
ErasePulse:
    ori.w   #0x0001           ,(%a4)   /* Enable high voltage                           */
VppActiveE:                            /* Wait for Vpp to go down                       */
    bsr.w   swsr
    tst.w   (%a3)
    bmi.b   VppActiveE
    andi.w  #0xFFFE           ,(%a4)   /* Disable High voltage                          */

    move.w  #32768            , %d1    /* Check regular data                            */
    bsr.b   VerifBlock
    tst.w   %d1
    bne.b   ErasePulse

    tst.b   %d0                        /* Also check shadow if this is partition 0      */
    bne.b   PartitionDone

    bsr.b   EnaShadow                  /* Check shadow area                             */
    move.w  #256              , %d1
    bsr.b   VerifBlock
    bsr.b   DisShadow
    tst.w   %d1
    bne.b   ErasePulse
    bra.b   PartitionDone

# # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # #

EraseCMFI:

    # Make sure shadow-access is off before starting!
    bsr.b   DisShadow

    clr.l   %d0                        /* Clear counter          */
    st.b    %d4                        /* Format all partitions  */

    # Configure flash for erase
    move.w  #0x223C           ,(%a3)

EmaskLoop:
    bclr.b  #0                , %d4
    bne.b   ErasePartition
    bra.b   NextPart

PartitionDone:
    andi.w  #0xFFFD           ,(%a4)   /* 0x34                       */

NextPart:
    lsr.b   #1                , %d4    /* Test next bit              */
    beq.b   ErDone                     /* Mask is 0: leave           */
    addq.w  #1                , %d0    /* Increment partition number */
    bra.b   EmaskLoop
ErDone:

    # End session
    andi.w  #0xFFF9           ,(%a4)

    # Configure flash for flashing
    move.w  #0x200B           ,(%a3)
rts

# # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # #
.align 4
ErasingFlsh: .string "Erasing CMFI\r\n"
.align 4
FlashMain:   .string "Writing main\r\n"
.align 4
FlashSHDW:   .string "\r\nWriting shadow\r\n"
.align 4
DoneMSG:     .string "\r\nDone!\r\n"
.align 4
FMODE:       .string "rb"
.align 4
FILE:        .skip       8
VecTab:      .skip  4 * 40
Stack:       .skip  4 * 40
Databuf:
