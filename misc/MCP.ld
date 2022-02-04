OUTPUT_FORMAT("binary")
OUTPUT_ARCH(m68k)

/* DPTRAM Definitions */
MEMORY {
	ram : ORIGIN = 0x0, LENGTH = 0x800
}

SECTIONS{
	.text  0x0  : {
	
		__s_text = . ;	
		*     (.text) 
		CONSTRUCTORS
		__e_text = . ; 
	} > ram	

	.data : {

		__s_data = . ; /* Symbols, to know where to */
		*(.data)
		__e_data = . ; /* copy the data.            */
	} > ram

	.bss : {
	
		__s_bss = . ;
		*(.bss)
		*(COMMON)
		__e_bss = . ;
	} > ram
}