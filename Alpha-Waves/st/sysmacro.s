***************************************************************************
*		Macros d'accäs au systäme
***************************************************************************
GEMDOS	MACRO	Macro d'appel au GEMDOS : GEMDOS num,octets pile
	move.w	#\1,-(sp)
	trap	#1
	ifgt	\2-11
	lea	\2(sp),sp
	endc
	ifle	\2-11
	addq.l	#\2,sp
	endc
	ENDM

BIOS	MACRO	Macro d'appel au BIOS : Comme GEMDOS
	move.w	#\1,-(sp)
	trap	#13
	ifgt	\2-11
	lea	\2(sp),sp
	endc
	ifle	\2-11
	addq.l	#\2,sp
	endc
	ENDM

XBIOS	MACRO	Macro d'appel au XBIOS : Comme GEMDOS
	move.w	#\1,-(sp)
	trap	#14
	ifgt	\2-11
	lea	\2(sp),sp
	endc
	ifle	\2-11
	addq.l	#\2,sp
	endc
	ENDM
