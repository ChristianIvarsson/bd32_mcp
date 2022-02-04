# Simple code that dumps the CMFI array
.include "misc/ipd.inc"
.long    Init                /* First address must contain offset to start */

.equ CMFIMCR   , 0xFFF800

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













#   Code specific to this particular driver
Main:

    lea.l   DumpingMain       , %a0
    moveq   #BD_PUTS          , %d0
    bgnd
    bsr.b   swsr

    movea.l #0x40000          , %a4   /* Last address of regular flash */
    move.l  #1024             , %d6   /* Number of bytes to read       */

ZeroPointer:
    # Start dumping from address 0
    suba.l  %a0               , %a0
    
DumpLoop:
    moveq.l #BD_FWRITE        , %d0   /* Load command                  */
    move.l  (FILE, %a5)       , %d1   /* Load file handle              */
    move.l  %d6               , %d2   /* Store number of bytes to dump */
    bgnd
    bsr.b   swsr
    
    # Check written bytes
    cmp.l   %d6               , %d0
    bne.b   WriteErr

    moveq.l #BD_PUTCHAR       , %d0   /* Call printchar                */
    moveq.l #0x2E             , %d1   /* Character to print            */
    bgnd
    bsr.b   swsr
    
    adda.l  %d6               , %a0   /* Increment pointer             */
    cmpa.l  %a0               , %a4   /* Check if last address has been reached */
    bne.b   DumpLoop
    
    # Extra checks: (Dump shadow)
    cmpa.l  #0x100            , %a4   /* Check if this is the second time we're here */
    beq.b   DumpDone

    lea.l   DumpingSdw        , %a0
    moveq   #BD_PUTS          , %d0
    bgnd
    bsr.b   swsr
    
    # Enable shadow access
    ori.w   #0x2000           , (CMFIMCR)
    movea.l #0x100            , %a4   /* Set last address as 0x100  */
    move.l  %a4               , %d6   /* Read 256 bytes this time!  */
    bra.b   ZeroPointer
    

DumpDone:
    clr.l   %d7
    lea.l   DoneMSG           , %a0
    moveq   #BD_PUTS          , %d0
bgnd
    bsr.b   swsr
    
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
WriteErr:
    moveq.l #1                , %d7
    bra.b   EndSession
ExceptionErr:
    moveq.l #3                , %d7
    bra.b   EndSession

.align 4
DumpingMain: .string "Dumping main\r\n"
.align 4
DumpingSdw:  .string "\r\nDumping shadow\r\n"
.align 4
DoneMSG:    .string "\r\nDone!\r\n"
.align 4
FMODE:      .string "wb"
.align 4
FILE:       .skip       8
VecTab:     .skip  4 * 40
Stack:      .skip  4 * 40
