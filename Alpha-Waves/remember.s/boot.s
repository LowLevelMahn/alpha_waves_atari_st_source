***************************************************************************
*	BOOTSECTEUR pour Alpha Waves: Fondu au noir
***************************************************************************

	INCLUDE	C:\ASSEMBLR\PROJET.CUB\ST\SYSMACRO.S

	moveq	#15,d7		8 d‚calages
AuNoir1	XBIOS	37,2		Attente VBL
	moveq	#15,d6		16 couleurs
	lea	$FFFF8240.w,a0
	lea	CoTab(pc),a1
AuNoir2	move.w	(a1),d2
	lsr.w	#1,d2
	move.w	d2,(a0)+
	move.w	d2,(a1)+
	dbra	d6,AuNoir2	R‚p‚tition
	dbra	d7,AuNoir1

	XBIOS	4,2		Teste la r‚solution
	tst.w	d0
	beq.s	LoRes

	move.l	#32034,-(sp)
	GEMDOS	$48,6		MALLOC
	move.l	d0,a4
	add.l	#34,d0
	bra.s	HiRes

LoRes	XBIOS	3,2		R‚cup‚ration de l'adresse ‚cran
HiRes	move.l	d0,a6
	lea	32000(a6),a5	Fin de l'‚cran
	lea	-34(a6),a6	R‚cupŠre les couleurs

	moveq	#2,d7		Compteur de piste

Loop	move.w	#9,-(sp)		Lecture 9 secteurs
	clr.w	-(sp)		Face 0
	move.w	d7,-(sp)		Piste d7
	move.w	#1,-(sp)		A partir du secteur 1
	clr.w	-(sp)		Device=A:
	clr.l	-(sp)		Filler
	move.l	a6,-(sp)		Adresse
	XBIOS	8,20		Lecture de secteurs
	addq.w	#1,d7		Compteur de pistes
	lea	512*9(a6),a6
	cmp.l	a5,a6
	ble.s	Loop

	XBIOS	4,2
	tst.w	d0
	bne	HiResConv

	lea	-32030(a5),a5
	lea	$FFFF8242.w,a6
	moveq	#14,d0
CoLoop1	move.w	(a5)+,d2
	or.w	#$F000,d2
	moveq	#0,d1
CoLoop2	move.w	d1,(a6)
	cmp.w	d2,d1
	beq.s	CoLoopX

	addq.w	#1,d1
	bra.s	CoLoop2

CoLoopX	addq.l	#2,a6
	dbra	d0,CoLoop1

	rts

CoTab	dc.w	$FFF,$FFF,$FFF,$FFF,$FFF,$FFF,$FFF,$FFF
	dc.w	$FFF,$FFF,$FFF,$FFF,$FFF,$FFF,$FFF,$FFF

HiResConv	move.w	#0,$FFFF8240.w
	XBIOS	3,2		Adresse ‚cran
	move.l	d0,a1

	lea	34(a4),a0		Adresse buffer

	move.w	#199,d7
Main.HLin	moveq	#19,d6
	move.w	d7,-(sp)
Main.HWrd	movem.w	(a0),d0-d3	Lecture des plans BR
	addq.l	#8,a0
	moveq	#0,d4		Plans HR pr‚vus
	moveq	#0,d5
	moveq	#15,d7		Compteur de bits
Main.HBit	roxl.w	#1,d0		Conversion plan BR->HR
	roxl.l	#1,d5
	roxl.w	#1,d1
	roxl.l	#1,d5
	roxl.w	#1,d2
	roxl.l	#1,d4
	roxl.w	#1,d3
	roxl.l	#1,d4
	dbra	d7,Main.HBit
	move.l	d5,(a1)+
	move.l	d4,76(a1)
	dbra	d6,Main.HWrd
	lea	80(a1),a1
	move.w	(sp)+,d7
	dbra	d7,Main.HLin

	move.l	a4,-(sp)
	GEMDOS	$49,6
	rts
