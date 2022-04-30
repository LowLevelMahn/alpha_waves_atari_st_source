	INCLUDE	C:\ASSEMBLR\PROJET.CUB\ST\SYSMACRO.S

	move.l	sp,a5
	lea	Pile(pc),sp

	move.l	4(a5),a5		Initialisation classique
	move.l	$C(a5),d0
	add.l	$14(a5),d0
	add.l	$1c(a5),d0
	add.l	#$100,d0
	move.l	d0,-(sp)
	move.l	a5,-(sp)
	move.w	#0,-(sp)
	GEMDOS	$4A,12		SetBlock
	tst.w	d0
	bne	FinProg

	pea	Null(pc)		Environnement
	pea	Null(pc)		Chaine de paramätres
	pea	Nom(pc)		Nom du fichier
	clr.w	-(sp)
	GEMDOS	$4B,14

FinProg	clr.w	-(sp)
	trap	#1

Nom	dc.b	"A:\CUBE.PRG"
Null	dc.b	0,0

	ds.b	100
Pile	dc.w	0
