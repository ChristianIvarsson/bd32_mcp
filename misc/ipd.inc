.equ BD_QUIT       ,  0   /* quit - return to BD32                             */
.equ BD_PUTS       ,  1   /* puts - put string to console                      */
.equ BD_PUTCHAR    ,  2   /* putchar - print character on console              */
.equ BD_GETS       ,  3   /* gets - get string from user                       */
.equ BD_GETCHAR    ,  4   /* getchar - get single character from user          */
.equ BD_GETSTAT    ,  5   /* getstat - return 1 if character waiting from user */
.equ BD_FOPEN      ,  6   /* fopen - open disk file with specified mode        */
.equ BD_FCLOSE     ,  7   /* fclose - close disk file                          */
.equ BD_FREAD      ,  8   /* fread - read from disk file                       */
.equ BD_FWRITE     ,  9   /* fwrite - write to disk file                       */
.equ BD_FTELL      , 10   /* ftell - report current pointer position           */
.equ BD_FSEEK      , 11   /* fseek - seek disk file to given position          */
.equ BD_FGETS      , 12   /* fgets - read string from file                     */
.equ BD_FPUTS      , 13   /* fputs - write string to file                      */
.equ BD_EVAL       , 14   /* eval - evaluate arithmetic expression             */
.equ BD_FREADSREC  , 15   /* read s-record                                     */

