StrtDemo	bclr	#1,Options1(a6)	Indique 1 seul joueur
	clr.l	TimerL(a6)

	move.l	ScreenBck(a6),a0
	movem.l	2(a0),d0-d7
	movem.l	d0-d7,CurColor(a6)
	movem.l	d0-d7,BackColor(a6)
	lea	34(a0),a0
	move.l	AdTScreen(a6),a1
	bsr	CopyScreen

	bsr	MiniInit		Initialisation des angles de vue,...
	move.w	#80,PosY(a6)
	lea	FF.NonOriented(pc),a0	Indique un remplissage non orient‚ de facettes
	move.l	a0,Filler(a6)
	lea	TheText(pc),a0		Initialisation de l'adresse du texte
	move.l	a0,TextAd(a6)

Demo.Clear:
	clr.w	TextDXYZ(a6)		Fixe le point de d‚part du texte
	clr.w	TextDXYZ+2(a6)
	move.l	TextAd(a6),a0
	move.b	(a0),d0
	and.w	#$F8,d0
	lsl.w	#5,d0
	neg.w	d0
	add.w	#6500,d0
	move.w	d0,TextDXYZ+4(a6)

	bsr	Random		Calcul de l'effet (tir‚ au hasard)
	and.w	#6,d0
	lea	EfTab(pc),a0
	move.w	0(a0,d0.w),d0
	lea	0(a0,d0.w),a0
	move.l	a0,TextEffct(a6)

	bsr	PrintLine
	move.l	TextAd(a6),d0
	beq	PlayDemo			Si on est arriv‚ … la fin du texte

	move.w	#30000,d7
Demo.WLoop:
	bsr	KeyPressed
	tst.w	d0
	dbmi	d7,Demo.WLoop
	bpl	Demo.Clear
	tst.w	d1
	bmi.s	QuitDemo

	move.w	#2,-(sp)
	BIOS	2,4		Lecture de la touche
	swap	d0
	cmp.b	#$3B,d0
	beq.s	ChangeJ1
	cmp.b	#$3C,d0
	beq.s	ChangeJ2
	swap	d0
	cmp.b	#'2',d0		CTRL-E enregistrement
	bne.s	Demo.NoRc

	bset	#1,Options1(a6)	Indique 2 Joueurs
	move.l	Other(a6),a5
	move.b	Options1(a6),Options1(a5)
	movem.l	CurColor(a6),d0-d7
	movem.l	d0-d7,CurColor(a5)
	moveq	#0,d0

Demo.NoRc	cmp.b	#17,d0		Est ce CTRL-Q ?
	bne.s	QuitDemo		Si on a appuy‚ sur CTRL-Q, on quitte le programme
	bsr.s	QuitDemo
	bra	Fin

QuitDemo	move.l	MoveMemAd(a6),EndMvMem(a6)
	rts
PlayDemo	subq.w	#4,InputDev(a6)	Indique "Mode joue automatiquement"
	bset	#0,Options1(a6)	Indique retour au centre joystick
	rts


DevNames	dc.b	'Joystick 1'
	dc.b	'Joystick 2'
	dc.b	'Clavier   '

ChangeJ1	lea	InputDev(a6),a0
	lea	Device1(pc),a1
	bra.s	ChangeJ
ChangeJ2	move.l	Other(a6),a5
	lea	InputDev(a5),a0
	lea	Device2(pc),a1

ChangeJ	move.w	(a0),d0
	addq.w	#1,d0
	cmp.w	#2,d0
	ble.s	ChangeJ.0
	moveq	#0,d0
ChangeJ.0	move.w	d0,(a0)
	muls	#10,d0
	lea	DevNames(pc,d0.w),a0
	moveq	#9,d0
ChangeJ.C	move.b	(a0)+,(a1)+
	dbra	d0,ChangeJ.C

	bsr	ClsNorm

	clr.w	Alpha(a6)
	clr.w	Beta(a6)
	clr.w	Gamma(a6)
	clr.w	TextDXYZ(a6)		Fixe le point de d‚part du texte
	move.w	#-5000,TextDXYZ+2(a6)
	move.w	#6500,TextDXYZ+4(a6)
	lea	Devices(pc),a0
	move.l	a0,TextAd(a6)

	moveq	#4,d7
ChangeJ.1	move.w	d7,-(sp)
	bsr	PL.Init
	bsr	APlat
	bsr	PL.Disp
	add.w	#1000,TextDXYZ+2(a6)
	move.w	(sp)+,d7
	dbra	d7,ChangeJ.1
	bsr	SwapScrn
	move.w	#32000,d7
ChangeJ.K	bsr.s	KeyPressed
	tst.w	d0
	dbmi	d7,ChangeJ.K

	bra	Demo.Clear
