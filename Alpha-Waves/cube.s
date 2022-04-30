****************************************************************************
*
*		Alpha - Waves version 1.0
*		Projet "Cube", Christophe de Dinechin 1990
*
***************************************************************************

*	Opt	D+

NTABS	EQU	256		Nombre de tableaux
CHEAT	EQU	0		Mode CHEAT
DEMO_REC	EQU	0		Enregistrement de Demo
VERSION_ST	EQU	1
VERSION_AM	EQU	1-VERSION_ST
PROTECTED	EQU	0	1: Protection Notice; 2: Protection feuille

SoundPtr	EQU	$24	Adresse du son en cours=TRACE vector $24
MusicPtr	EQU	$8C	Adresse de la musique en cours

	IFNE	VERSION_ST
	INCLUDE	ST\SYSMACRO.S
	ENDC
***************************************************************************
*		Debut du programme
***************************************************************************
Start	bra	Init



***************************************************************************
*		Boucle de la demo du debut
***************************************************************************
Main	bsr	Intro

	bra	MainGame



***************************************************************************
*	Affichage du nombre d'images par seconde en CHEAT
***************************************************************************
	IFNE	CHEAT
TimeCheck	move.w	Timer(a4),d0
	and.w	#$F,d0
	bne.s	NoTimeCheck
	move.l	$4BA.w,d0
	sub.l	LastTime(a4),d0
	moveq	#0,d1
	move.w	#32000,d1
	divu	d0,d1

	lea	TimeCheckMsg(pc),a0
	and.l	#$FFFF,d1
	divu	#100,d1
	add.w	#'0',d1
	move.b	d1,(a0)+
	clr.w	d1
	swap	d1
	divu	#10,d1
	add.w	#'0',d1
	move.b	d1,(a0)+
	move.b	#'.',(a0)+
	swap	d1
	add.w	#'0',d1
	move.b	d1,(a0)+

	move.l	$4BA.w,LastTime(a4)

NoTimeCheck:
	lea	TimeCheckMsg(pc),a0
	move.l	LogScreen(a4),a1
	lea	160*16+4*12(a1),a1
	bsr	FastPrt
	rts

TimeCheckMsg:
	dc.b	'00.0 Images/s',0
	ENDC

***************************************************************************
*	L'endroit ou on va quand la partie est finie
***************************************************************************
Finished	neg.w	DoLoad(a4)	Si =1 (charge sur disque), indique -1 (A charger) pour la demo
	move.w	#2,-(sp)
	BIOS	1,4
	tst.w	d0
	bpl.s	Finish.1
	move.w	#2,-(sp)
	BIOS	2,4
	bra.s	Finished

Finish.1	tst	Joueur(a4)
	beq.s	Finish.2
	bsr	SwapVars

Finish.2	bsr	OnePlayer
	bsr	ModifieScore

MainGame	tst.w	InputDev(a4)
	bpl.s	Main.NoDemo
	addq.w	#4,InputDev(a4)

Main.NoDemo:
	bsr	SelectOptions
	bsr	ClrMusic

Main.Load	move.l	Other(a4),a5
	move.b	Options2(a5),Options2(a4)	Restaure le retour au centre du joystick a l'etat initial
	bsr	MiniInit		Initialisation de partie
	or.w	#$100,Tableau(a4)	Tableau 0, mais <>0 pour InitOL => pas de copie
	bsr	SwapVars
	bsr	MiniInit
	bsr	InitOL
	bsr	SwapVars

	tst.w	DoLoad(a4)	Si il faut charger le jeu
	bmi	EndDiskOp		Charge le jeu (stocke dans la zone de save)

	move.w	#-25,Sortie(a4)		Pour que l'on ne trouve pas de sortie
*	bsr	DessineIcons
NouvTab	and.w	#NTABS-1,Tableau(a4)	Ramene au nombre de tableaux
	clr.w	Alpha(a4)			Vibrations parasite si pas remis a 0 de force
	clr.w	BetaSpeed(a4)

	bsr	NewTablo			Initialisation de tableau

MainLoop	addq.l	#1,TimerL(a4)
	move.l	Other(a4),a5
	addq.l	#1,TimerL(a5)

	bsr	Cls

MainLoop2	bsr	TrigInit
	bsr	DessineCube		Trace de l'arene,
	bsr	DessineMonde		Se charge alors de Dessiner l'ombre et le vaisseau

	tst.w	JSuisMort(a4)
	bmi	TheEnd
	bne.s	PasDeplace
	bsr	Deplace
	bra.s	PasChTab
PasDeplace:
	subq.w	#1,JSuisMort(a4)
	bne.s	PasChTab

	move.l	TabVisitAd(a4),a0
	move.w	Tableau(a4),d0
	and.w	#NTABS-1,d0
	tst.b	0(a0,d0.w)		Teste si on a deja vu le tableau en question
	bne	NouvTab
	move.w	#30,ExtraTime(a4)
	add.l	#200*60,SysTime0(a4)	Si non, on a 3 mn d'exploration en plus
	move.l	Other(a4),a5
	add.l	#200*60,SysTime0(a5)
	bra	NouvTab

PasChTab:
	btst	#1,Options1(a4)		Si 2 joueurs
	beq.s	Only1P
	bsr	SwapVars			On passe alternativement l'un et l'autre
	tst.w	Joueur(a4)
	bne	MainLoop2

Only1P	bsr	MkScore
	IFNE	CHEAT
	bsr	TimeCheck
	ENDC

	bsr	SwapScrn		et permutation d'ecran
	cmp.w	#-1,WhichDiamond(a4)	Teste si on a gagne
	beq	GameWon

	move.w	#2,-(sp)
	BIOS	1,4		Caractere clavier ?
	tst.w	d0
	bpl	MainLoop		Non

	move.w	#2,-(sp)
	BIOS	2,4		Lecture du caractere
	tst.w	InputDev(a4)
	bmi	Finished

	bclr	#5,d0		Passe en majuscules
	cmp.b	#'P',d0
	bne.s	KR.Pause
	move.l	SysTime0(a4),d7
	sub.l	$4BA.w,d7		D7= Temps restant

KR.Pause1	bsr	ClrKey

KR.Pause2	bsr	KeyPressed
	tst.w	d0
	bpl.s	KR.Pause2

	add.l	$4BA.w,d7
	move.l	d7,SysTime0(a4)
	bra	MainLoop

KR.Pause	cmp.b	#'M',d0
	bne.s	KR.NoMap
	move.l	SysTime0(a4),d7
	sub.l	$4BA.w,d7		D7= Temps restant
	move.l	d7,-(sp)
	bra	KR.DoMap

KR.NoMap:
	IFNE	DEMO_REC
	cmp.b	#'S',d0
	bne.s	KR.NoSaveDemo
	bsr	SaveDemo
KR.NoSaveDemo:
	ENDC

	cmp.b	#27,d0		Presse-t-on la touche ESC ?
	IFNE	CHEAT
	beq.s	AfficheMenuOptions	Non ? On lit les touches
	jmp	Verrue
	ENDC
	IFEQ	CHEAT
	bne	MainLoop
	ENDC


***************************************************************************
*	Affichage du menu d'options
***************************************************************************
AfficheMenuOptions:
	move.l	SysTime0(a4),d7
	sub.l	$4BA.w,d7		D7= Temps restant
	move.l	d7,-(sp)

	lea	DF.Norm(pc),a0	Affichage d'une image statique
	lea	DessineFond(pc),a1
	move.l	a0,2(a1)

	move.l	PhyScreen(a4),a0
	move.l	Screen2Ad(a4),a1
	bsr	CopyScreen

	moveq	#'1',d0		Menu 1: Choix d'options
	lea	Options.Menu(pc),a0	Liste des valeurs du menu
	bsr	MakeMenu

***************************************************************************
*	Teste des differentes selections du menu
***************************************************************************
OM.RetourPartie	equ	0
OM.Oops		equ	1
OM.Sauvegarde	equ	2
OM.Bruitages	equ	3
OM.Plancher	equ	4
OM.Remplissage	equ	5
OM.CentrageH	equ	6
OM.CentrageV	equ	7
OM.Inclinaison	equ	8
OM.PositionVue	equ	9
OM.VType		equ	10
OM.Carte		equ	11
OM.Quitter	equ	12


	bsr	LitOptionsDuMenu
* Maintenant les tests de D0
	tst.w	d0
	beq	KR.End		Retour partie en cours

	cmp.w	#OM.Quitter,d0	Teste si on a demande "Quitter"
	bne	KR.NoEnd
	addq.l	#4,sp
	bra	Finished

KR.NoEnd	cmp.w	#OM.Oops,d0	Recuperation ancienne version
	bne.s	KR.ReLoad
	addq.l	#4,sp
	neg.w	DoLoad(a4)	Indique "Recharger la derniere partie"
	bra	Main.Load

KR.ReLoad	cmp.w	#OM.Sauvegarde,d0
	beq	SaveCurGame

KR.ChoixVaiss:
	cmp.w	#OM.VType,d0
	bne.s	KR.Map
	bsr	ChoixVaiss

	IFNE	DEMO_REC
	btst	#1,Options1(a4)	Ecriture du type de vaisseau pour demo
	bne.s	KR.Demo
	move.l	EndMvMem(a4),a0	Enregistrement du changement de vaisseau
	move.l	a0,d2
	sub.l	MoveMemAd(a4),d2
	cmp.w	#TScreen-MoveMemry,d2
	bgt.s	KR.Demo
	move.w	VaissNum(a4),d1
	or.w	#64,d1
	move.b	d1,(a0)+
	move.l	a0,EndMvMem(a4)
KR.Demo:
	ENDC	Test de DEMO_REC

	bra	KR.End

KR.Map	cmp.w	#OM.Carte,d0	Teste si on demande l'affichage de la carte
	bne	KR.End

KR.DoMap	movem.l	BackColor(a4),d0-d7	Sauvegarde de la palette de couleurs
	movem.l	d0-d7,-(sp)
	move.l	Other(a4),a5
	movem.l	BackColor(a5),d0-d7
	movem.l	d0-d7,-(sp)
	move.w	ClipB(a4),-(sp)
	move.w	Options1(a4),-(sp)
	move.l	TimerL(a4),-(sp)

	move.w	#199,ClipB(a4)
	bclr	#1,Options1(a4)

	bsr	FonduAuNoir
	movem.l	LogScreen(a4),a0-a1
	exg.l	a0,a1
	movem.l	a0-a1,LogScreen(a4)
	movem.l	a0-a1,LogScreen(a5)

	bsr	ClsNorm
	movem.l	MapColors(pc),d0-d7
	movem.l	d0-d7,BackColor(a4)
	move.l	Other(a4),a5
	movem.l	d0-d7,BackColor(a5)
	bsr	FonduAuBlanc

	bsr	AfficheCarte	Affiche la carte
	bsr	AC.Clear		Efface l'ecran texte
	move.w	Tableau(a4),d0
	lea	MapList(pc),a5	Teste que l'on reste bien dans
	and.w	#NTABS-1,d0
	move.b	0(a5,d0.w),d1
	ext.w	d1
	subq.w	#1,d1
	moveq	#'1',d0
	bsr	FindText
	bsr	AfficheLigneCentree
	bsr	Text2Scr
	bsr	SwapScrn

	move.l	PhyScreen(a4),a0
	move.l	Screen2Ad(a4),a1
	bsr	CopyScreen
	clr.w	NStars(a4)

KR.Map1	move.w	d7,-(sp)
	move.l	Screen2Ad(a4),a0
	move.l	LogScreen(a4),a1
	bsr	CopyScreen
	move.w	#3,Couleur(a4)
	bsr	Stars
	bsr	SwapScrn
	addq.l	#1,TimerL(a4)

	move.w	(sp)+,d7

	XBIOS	37,2
	bsr	KeyPressed
	tst.w	d0
	bpl	KR.Map1

	bsr	FonduAuNoir
	bsr	Cls
	bsr	SwapScrn

	move.l	(sp)+,TimerL(a4)
	move.w	(sp)+,Options1(a4)
	move.w	(sp)+,ClipB(a4)
	move.l	Other(a4),a5	Restauration de la palette de couleurs
	movem.l	(sp)+,d0-d7
	movem.l	d0-d7,BackColor(a5)
	movem.l	(sp)+,d0-d7
	movem.l	d0-d7,BackColor(a4)
	bsr	FonduAuBlanc

KR.End	move.l	(sp)+,d7
	add.l	$4BA.w,d7		Remet a jour le timer
	move.l	d7,SysTime0(a4)
	bra	MainLoop

* Liste des bits de Options2 correspondant au menu
OM.BitPos	dc.w	6,0,1,2,3,4,5
* Lecture des options du menu pour integration dans Options2 et VaissNum
LitOptionsDuMenu:
	lea	OM.BitsAd(pc),a0	Lecture des options
	lea	OM.BitPos(pc),a1	Lecture des bits correspondant
	moveq	#6,d7		Nombre de bits a lire
	moveq	#0,d6		Valeur des bits
OM.BitLoop:
	move.w	(a1)+,d5
	tst.w	(a0)+		Teste si option selectionnee
	beq.s	OM.BitClr
	bset	d5,d6
OM.BitClr	dbra	d7,OM.BitLoop

	move.b	d6,Options2(a4)	Ecritue des options ainsi lues
	move.l	Other(a4),a5
	move.b	d6,Options2(a5)	Y compris chez le joueur 2

	rts

MapColors	dc.w	$000,$050,$F27,$0E6,$CF0,$500,$08F,$BBC,$FB0,$FF0,$0FF,$F54,$C0F,$0F0,$F00,$300

* Valeurs par defaut du menu d'options:
Options.Menu:
	dc.w	0		Numero de l'Item de depart
	dc.w	-1,-1,-1
OM.BitsAd	dc.w	0,0,0,0,0,0,0	Options Oui/No
	dc.w	-1,-1,-1,-1


************************************************************************
*		Choix du vaisseau a utiliser
************************************************************************
ChV.Colors:
	dc.w	$000,$070,$700,$000,$333,$444,$555,$666
	dc.w	$050,$F27,$0E6,$CF0,$500,$FC3,$113,$710

ChV.Pos	dc.w	5,105,5,97
	dc.w	110,210,5,97
	dc.w	215,315,5,97
	dc.w	5,105,103,195
	dc.w	110,210,103,195
	dc.w	215,315,103,195


ChoixVaiss:
	lea	JoyStick2(pc),a0
	move.b	(a0)+,d0
	or.b	(a0)+,d0
	btst	#JOY_FIRE,d0
	bne.s	ChoixVaiss

	move.l	Other(a4),a5		Sauvegarde les couleurs dans la pile
	movem.l	BackColor(a4),d0-d7
	movem.l	d0-d7,-(sp)
	movem.l	BackColor(a5),d0-d7
	movem.l	d0-d7,-(sp)
	move.w	Options1(a4),-(sp)
	bclr	#5,Options2(a4)
	move.w	BetaSpeed(a4),-(sp)
	movem.w	ClipG(a4),d0-d3
	movem.w	d0-d3,-(sp)
	movem.w	PosX(a4),d0-d2
	movem.w	d0-d2,-(sp)
	move.l	TimerL(a4),-(sp)
	move.w	Alpha(a4),-(sp)

	bsr	FonduAuNoir		Utilise les couleurs standard

	bsr	Cls
	bsr	SwapScrn

	movem.l	ChV.Colors(pc),d0-d7
	movem.l	d0-d7,BackColor(a4)
	movem.l	d0-d7,BackColor(a5)
	bsr	FonduAuBlanc

	clr.w	NStars(a4)

ChV.2	move.w	VaissNum(a4),-(sp)
	clr.w	VaissNum(a4)
	bsr	Cls

ChV.1	lea	ChV.Pos(pc),a0
	move.w	VaissNum(a4),d0
	lsl.w	#3,d0
	add.w	d0,a0

	movem.w	(a0),d0-d3
	movem.w	d0-d3,ClipG(a4)
	add.w	d0,d1
	asr.w	#1,d1
	move.w	d1,PosX(a4)
	add.w	d2,d3
	asr.w	#1,d3
	add.w	#10,d3
	move.w	d3,PosY(a4)

	clr.w	Couleur(a4)
	move.w	(sp),d0
	cmp.w	VaissNum(a4),d0
	beq.s	ChV.NV1

	move.w	#14,Couleur(a4)

ChV.NV1	movem.w	(a0),d0-d3
	lea	PolySomm(a4),a0
	move.w	d0,(a0)+
	move.w	d2,(a0)+
	move.w	d1,(a0)+
	move.w	d2,(a0)+
	move.w	d1,(a0)+
	move.w	d3,(a0)+
	move.w	d0,(a0)+
	move.w	d3,(a0)+
	moveq	#4,d3
	moveq	#0,d1
	moveq	#0,d2
	lea	PolySomm(a4),a0

	lea	ChV.NV1(pc),a6
	add.l	#FillPoly-ChV.NV1,a6
	jsr	(a6)		FillPoly

	subq.w	#3,BetaSpeed(a4)
	move.w	Timer(a4),d1
	move.w	#80,d0
	bsr	XSinY
	move.w	d2,Alpha(a4)
	bsr	DessineVaiss

	move.w	(sp),d0
	cmp.w	VaissNum(a4),d0
	bne.s	ChV.NV2

	move.w	#13,Couleur(a4)
	bsr	Stars

ChV.NV2	addq.w	#1,VaissNum(a4)
	cmp.w	#6,VaissNum(a4)
	bne	ChV.1

	bsr	SwapScrn
	addq.l	#1,TimerL(a4)
	move.w	(sp)+,d7

	lea	JoyStick2(pc),a0
	move.b	(a0)+,d0
	or.b	(a0)+,d0
	clr.b	-(a0)
	clr.b	-(a0)
	btst	#JOY_FIRE,d0
	bne.s	ChV.End

	btst	#JOY_UP,d0
	bne.s	ChV.UpDn
	btst	#JOY_DN,d0
	beq.s	ChV.NoUpDn
ChV.UpDn	addq.w	#3,d7		Changement de ligne
	cmp.w	#6,d7
	blt.s	ChV.NoUpDn
	subq.w	#6,d7
ChV.NoUpDn:
	btst	#JOY_LF,d0
	beq.s	ChV.NoLf
	subq.w	#1,d7
	bge.s	ChV.NoLf
	moveq	#5,d7

ChV.NoLf	btst	#JOY_RT,d0
	beq.s	ChV.NoRt
	addq.w	#1,d7
	cmp.w	#6,d7
	bne.s	ChV.NoRt
	moveq	#0,d7

ChV.NoRt	move.w	d7,VaissNum(a4)
	bra	ChV.2

ChV.End	move.w	d7,VaissNum(a4)
	move.l	Other(a4),a5
	move.w	d7,VaissNum(a5)

	bsr	FonduAuNoir

	move.w	(sp)+,Alpha(a4)
	move.l	(sp)+,TimerL(a4)
	movem.w	(sp)+,d0-d2
	movem.w	d0-d2,PosX(a4)
	movem.w	(sp)+,d0-d3
	movem.w	d0-d3,ClipG(a4)
	move.w	(sp)+,BetaSpeed(a4)		Recupere les valeurs sauvegardees
	move.w	(sp)+,Options1(a4)

	movem.l	(sp)+,d0-d7		Restaure les couleurs
	move.l	Other(a4),a5
	movem.l	d0-d7,BackColor(a5)
	movem.l	(sp)+,d0-d7
	movem.l	d0-d7,BackColor(a4)
	move.l	Screen2Ad(a4),a0
	move.l	LogScreen(a4),a1
	bsr	CopyScreen

	bsr	SwapScrn
	bsr	FonduAuBlanc

	rts


************************************************************************
*		Table des zones a sauvegarder
************************************************************************
ASauver	dc.w	TabVisit-Vars,TabVisitAd
	dc.w	ExtraTime,CosA
	dc.w	Seed,FastFill
	dc.w	BackColor,TextAd
	dc.w	OList,AO.FerTab

	dc.w	DataLen,DataLen+TabVisitAd
	dc.w	DataLen+ExtraTime,DataLen+CosA
	dc.w	DataLen+Seed,DataLen+FastFill
	dc.w	DataLen+BackColor,DataLen+TextAd
	dc.w	DataLen+OList,DataLen+AO.FerTab

	dc.w	0

************************************************************************
*		Recherche d'un texte dans la liste
************************************************************************
* Entree: D0: Nom du texte
*	D1: Ligne du texte
* Sortie: A1: Adresse du texte
FindMenu	moveq	#'M',d2
	bra.s	FT.Entry

FindText	moveq	#'D',d2
FT.Entry	move.l	AdTexts(a4),a1	Cherche le debut du menu
FT.Find1	cmp.b	#'#',(a1)+
	bne.s	FT.Find1

	cmp.b	(a1)+,d2	Teste si un 'Display'
	bne.s	FT.Find1
FT.Find2	cmp.b	#9,(a1)+		Recherche une tabulation
	bne.s	FT.Find2
	cmp.b	(a1)+,d0		Lit le nom du menu
	bne.s	FT.Find1		Si pas le bon menu

FT.Find3	cmp.b	#10,(a1)+		Cherche la ligne suivante
	bne.s	FT.Find3

	tst.w	d1		Decompte ensuite de la bonne ligne
	beq.s	FT.Quit
FT.Find4	cmp.b	#10,(a1)+
	bne.s	FT.Find4
	subq.w	#1,d1
	bne.s	FT.Find4
FT.Quit	rts


************************************************************************
*		Affichage d'un texte complet
************************************************************************
* Entree: D0 pointe sur le nom du texte
AfficheTexteRsc:
	moveq	#0,d1
	bsr	FindText

	move.l	a1,-(sp)
	move.b	#12,d0
	bsr	AfficheCarD0		Efface l'ecran
	move.w	#21*320,TextPos(a4)	Ligne 21
	clr.w	TextCol(a4)

	movem.l	(sp)+,a1
	moveq	#0,d7		D7: Compteur de ligne

ATR.Line	move.b	(a1),d0
	cmp.b	#"#",d0		Teste si #E ou #T
	bne.s	ATR.NorLn
	cmp.b	#"E",1(a1)	Si en fin du texte
	beq	ATR.End1

ATR.NorLn	bsr	AfficheLigneCentree
	addq.w	#1,d7		Incremente compteur de lignes

ATR.Find6	cmp.b	#10,(a1)+
	bne.s	ATR.Find6
	bra	ATR.Line

* Le message est affiche
ATR.End1	move.w	TextCol(a4),d4
	move.w	TextPos(a4),d3
	move.w	d7,d5		Nombre total de lignes du menu
	sub.w	#20,d5
	neg.w	d5
	asr.w	#1,d5
ATR.LiDisp	tst.w	d5		Saute le nombre de lig pour centrer
	beq.s	ATR.End2
	moveq	#13,d0
	bsr	AfficheCarD0
	sub.w	#320,d3
	subq.w	#1,d5
	bne.s	ATR.LiDisp

ATR.End2	move.w	d3,TextPos(a4)
	move.w	d4,TextCol(a4)
	rts

* Affichage d'une ligne centree
* Entree: A1 pointe sur la ligne
AfficheLigneCentree:
	movem.w	d6/d7,-(sp)	Compteur de lignes/ Premier menu
	move.l	a1,d5		Sauvegarde de l'adresse de ligne
ALC.LnLen	cmp.b	#13,(a1)+
	bne.s	ALC.LnLen
	exg	d5,a1		a1=debut du texte, d5=fin
	sub.l	a1,d5		d5=longueur du texte
	sub.w	#41,d5		d5=-longueur des 2 marges
	neg.w	d5
	asr.w	#1,d5		Longueur d'une marge
	move.l	a0,-(sp)
	move.l	a1,-(sp)

ALC.Blank	tst.w	d5		Saute le nombre de blancs pour centrer
	ble.s	ALC.Msg
	moveq	#' ',d0
	bsr	AfficheCarD0
	subq.w	#1,d5
	bra.s	ALC.Blank

ALC.Msg	move.l	(sp)+,a1		Affichage de la ligne
	move.b	(a1)+,d0
	move.l	a1,-(sp)
	cmp.b	#13,d0
	beq.s	ALC.NLine
	bsr	AfficheCarD0
	bra.s	ALC.Msg

ALC.NLine	bsr	AfficheCarD0
	move.l	(sp)+,a1
	move.l	(sp)+,a0

	movem.w	(sp)+,d6/d7	Recuperation des compteurs
	rts


***************************************************************************
*	Sauvegarde des donnees sur disque
***************************************************************************
* Copie des donnees dans la zone de sauvegarde
SaveCurGame:
	move.l	Other(a4),a5		Sauvegarde du temps
	move.l	SysTime0(a4),d0
	sub.l	$4ba.w,d0

	move.l	d0,SysTime0(a4)
	move.l	d0,SysTime0(a5)

	IFEQ	DEMO_REC
	lea	Score(pc),a0		Sauvegarde du score
	move.l	TabVisitAd(a4),a1
	movem.l	(a0),d0-d1
	movem.l	d0-d1,NTABS(a1)
	lea	Score2(pc),a0
	movem.l	(a0),d0-d1
	movem.l	d0-d1,NTABS+8(a1)
	ENDC	DEMO_REC

	IFNE	DEMO_REC			Si Demo_Rec, enregistre position
	move.l	TabVisitAd(a4),a1
	move.l	EndMvMem(a4),d0
	sub.l	MoveMemAd(a4),d0
	move.l	d0,NTABS(a1)
	ENDC	DEMO_REC

	lea	DataSave-Vars2(a5),a0	Position de sauvegarde
	lea	ASauver(pc),a1		Adresse des objets a sauver
SaveData	move.w	(a1)+,d0
	beq.s	ErDiskOp
	lea	0(a4,d0.w),a2
	move.w	(a1)+,d0
	lea	0(a4,d0.w),a3
SaveD.1	move.w	(a2)+,(a0)+
	cmp.l	a3,a2
	blt.s	SaveD.1
	bra.s	SaveData

* Demande du nom de fichier
ErDiskOp	move.w	#-1,DoLoad(a4)	indique "Chargement depuis memoire"

	moveq	#'S',d0
	bsr	AfficheTexteRsc
	lea	Query(pc),a0
	bsr	AfficheTexteSansAttente

	lea	FileName(pc),a1	Lecture du nom de fichier

	bsr	MS.WaitK
	clr.b	(a1)+
	cmp.w	#2,TextCol(a4)	Si nom de fichier vide
	bne.s	SaveGame

* Fin des operations sur disque: Recuperation de la zone de save
EndDiskOp	move.l	Other(a4),a5

	lea	DataSave-Vars2(a5),a0	Position de sauvegarde
	lea	ASauver(pc),a1		Adresse des objets a sauver
LoadData	move.w	(a1)+,d0
	beq.s	QtDiskOp
	lea	0(a4,d0.w),a2
	move.w	(a1)+,d0
	lea	0(a4,d0.w),a3
LoadD.1	move.w	(a0)+,(a2)+
	cmp.l	a3,a2
	blt.s	LoadD.1
	bra.s	LoadData

QtDiskOp	move.l	Other(a4),a5		Recupere le temps
	move.l	SysTime0(a4),d0
	add.l	$4ba.w,d0

	cmp.w	#-2,DoLoad(a4)
	bne.s	QDO.1
	sub.l	#200*60,d0		Retrait une minute sur rappel memoire

QDO.1	move.l	d0,SysTime0(a4)
	move.l	d0,SysTime0(a5)

	IFEQ	DEMO_REC
	lea	Score(pc),a0		Enregistre le score
	move.l	TabVisitAd(a4),a1
	movem.l	NTABS(a1),d0-d1
	movem.l	d0-d1,(a0)
	lea	Score2(pc),a0
	movem.l	NTABS+8(a1),d0-d1
	movem.l	d0-d1,(a0)
	ENDC	DEMO_REC

	IFNE	DEMO_REC			Si Demo_Rec, enregistre position
	move.l	TabVisitAd(a4),a1
	move.l	NTABS(a1),d0
	add.l	MoveMemAd(a4),d0
	move.l	d0,EndMvMem(a4)
	ENDC	DEMO_REC

*	bsr	DessineIcons
	move.w	#2,DoLoad(a4)	Indique "Charge depuis memoire"
	bra	MainLoop

* Operation de sauvegarde sur disque
SaveGame	lea	FileName(pc),a0	Ajoute l'extension
	moveq	#7,d7
SVG.Ext	move.b	(a0)+,d0
	cmp.b	#'0',d0
	blt.s	SVG.AExt
	cmp.b	#'z',d0
	bgt.s	SVG.AExt
	dbra	d7,SVG.Ext
	addq.l	#1,a0

SVG.AExt	lea	FileExtension(pc),a1
	subq.l	#1,a0
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	clr.b	(a0)+

	clr.w	-(sp)		Fichier Lecture / Ecriture
	pea	FileName(pc)	
	GEMDOS	$3C,8		CREATE
	tst.l	d0
	bmi	SaveErr

	move.w	d0,-(sp)		Sauvegarde du Handle
	move.l	Other(a4),a5
	pea	DataSave-Vars2(a5)	Tampon des donnees
	pea	DataSaveEnd-DataSave+0.w
	move.w	d0,-(sp)		Handle
	GEMDOS	$40,12		WRITE
	tst.l	d0
	bmi.s	SaveErr
	GEMDOS	$3E,4		CLOSE (le handle est deja dans la pile)

	bra	EndDiskOp


* Chargement d'un fichier depuis le disque
LoadGame	clr.w	-(sp)		Accessible en lecture seule
	pea	FileName(pc)	Nom du fichier
	GEMDOS	$3D,8		OPEN
	tst.l	d0		Teste si le fichier existe
	bmi	LoadErr		Non

	move.w	d0,d7		Stockage du Handle
	move.l	Other(a4),a5
	pea	DataSave-Vars2(a5)	Tampon des donnees
	pea	DataSaveEnd-DataSave+0.w
	move.w	d7,-(sp)		Handle
	GEMDOS	$3F,12		READ
	tst.l	d0
	bmi.s	LoadErr
	move.w	d7,-(sp)
	GEMDOS	$3E,4

	rts

* Recuperation d'une erreur sur le disque
SaveErr	moveq	#'S',d0
	lea	LoadSave.Menu(pc),a0
	bsr	MakeMenu
	tst.w	d0
	beq	ErDiskOp
	bra	EndDiskOp

LoadErr	moveq	#'C',d0
	lea	LoadSave.Menu(pc),a0
	bsr	MakeMenu
	tst.w	d0
	beq	LoadGame
	bra	MainGame

CriticalErrorHandler:
	moveq	#-1,d0
	rts


***************************************************************************
*	Preparation du nom de fichier pour LOAD
***************************************************************************
ChargeJeu	moveq	#'L',d0
	moveq	#3,d1
	bsr	FindMenu

	move.l	a1,a5
	GEMDOS	$2F,2		GET DTA
	move.l	d0,a6

	clr.w	-(sp)
	pea	FileMask(pc)
	GEMDOS	$4E,8		SFIRST

	moveq	#15,d7		Au maximum 16 fichiers
CJ.2	tst.w	d0
	bne.s	CJ.AFF		Tous les fichiers trouves	
	lea	30(a6),a0
	moveq	#7,d6
CJ.21	move.b	(a0)+,d0
	beq.s	CJ.21E
	cmp.b	#".",d0
	beq.s	CJ.21E
	move.b	d0,(a5)+
	dbra	d6,CJ.21

CJ.21E	move.b	#13,(a5)+
	move.b	#10,(a5)+
	GEMDOS	$4F,2		SNEXT

	dbra	d7,CJ.2

CJ.AFF	move.b	#'#',(a5)+
	move.b	#'E',(a5)+
	
	moveq	#'L',d0
	lea	FileChoice.Menu(pc),a0
	clr.w	(a0)
	bsr	MakeMenu		Affiche le menu et trouve le fichier

	move.w	d0,d1
	beq	MM.Wait

	addq.w	#2,d1
	moveq	#'L',d0
	bsr	FindMenu

	lea	FileName(pc),a0
CJ.3	move.b	(a1)+,d0
	move.b	d0,(a0)+
	cmp.b	#13,d0
	bne.s	CJ.3

	subq.l	#1,a0
	lea	FileExtension(pc),a1
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	move.b	(a1)+,(a0)+
	clr.b	(a0)+

	move.w	#-1,DoLoad(a4)	Indique "Chargement sans perte"
	bsr	LoadGame
OldLoad	bra	MM.Wait


FileName	ds.b	64

FileMask	dc.b	"*"
FileExtension:
	dc.b	".QSV",0

Query	dc.b	"> ",0
	EVEN
LoadSave.Menu:
	dc.w	0,-1,-1
FileChoice.Menu
	dc.w	0,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1


***********************************************************************
*		Introduction (avant la boucle principale)	*
***********************************************************************

Intro	moveq	#100,d7
	bsr	PlayMusic

	bclr	#1,Options1(a4)
	bclr	#1,Options2(a4)		Passe en mode remplissage de polys
	bsr	OnePlayer

	tst.w	Resol(a4)			Si haute resolution, sauter l'intro
	bne	Intro.HiRes

	bsr	FonduAuNoir
	bsr	ClsNorm
	move.l	BckScreen(a4),a0
	movem.l	2(a0),d0-d7
	movem.l	d0-d7,BackColor(a4)
	move.l	Other(a4),a5
	movem.l	d0-d7,BackColor(a5)
	bsr	FonduAuBlanc

	moveq	#99,d7
	move.w	#9,Couleur(a4)

* Montee lente du "Alpha Waves" sur fond d'etoiles
Intro.S1	move.w	d7,-(sp)
	bsr	ClsNorm
	move.w	(sp),d0
	mulu	#320,d0
	move.l	LogScreen(a4),a1
	add.w	d0,a1
	move.l	BckScreen(a4),a0
	lea	34(a0),a0
	moveq	#99,d0
	sub.w	(sp),d0
	bsr	CS.Loop

	bsr	Stars
	bsr	SwapScrn
	addq.l	#1,TimerL(a4)
	move.w	(sp)+,d7
	dbra	d7,Intro.S1

	move.w	#$F00,d0
	move.l	Other(a4),a5

	move.w	d0,CurColor+2(a4)
	move.w	d0,CurColor+2(a5)
	move.w	d0,BackColor+2(a4)
	move.w	d0,BackColor+2(a5)

Intro.F1	XBIOS	37,2		VSYNC
	move.l	BckScreen(a4),a0
	move.l	LogScreen(a4),a1
	add.w	#34,a0
	bsr	CopyScreen
	bsr	Stars
	addq.l	#1,TimerL(a4)
	bsr	SwapScrn
	move.w	CurColor+16(a4),d0
	lsr.w	#1,d0
	move.w	d0,CurColor+16(a4)
	move.w	d0,CurColor+16(a5)
	move.w	d0,BackColor+16(a4)
	move.w	d0,BackColor+16(a4)
	bne.s	Intro.F1

Intro.F2	XBIOS	37,2		VSYNC
	move.l	BckScreen(a4),a0
	move.l	LogScreen(a4),a1
	add.w	#34,a0
	bsr	CopyScreen
	bsr	Stars
	addq.l	#1,TimerL(a4)
	bsr	SwapScrn
	move.w	CurColor+14(a4),d0
	lsr.w	#1,d0
	move.w	d0,CurColor+14(a4)
	move.w	d0,CurColor+14(a5)
	move.w	d0,BackColor+14(a4)
	move.w	d0,BackColor+14(a4)
	bne.s	Intro.F2


Intro.HiRes	move.l	BckScreen(a4),a0
	lea	34(a0),a0
	move.w	#20*200-1,d7		20 mots par ligne, 200 lignes

Intro.EffT	movem.w	(a0),d0-d3		On cherche la couleur 12
	not.w	d0
	not.w	d2
	and.w	d1,d0
	and.w	d2,d0
	and.w	d3,d0			D0 contient 1 pour les bits ou couleur = 12

	move.w	d0,(a0)+
 	clr.w	(a0)+			et on la transforme en rouge (2)
	clr.l	(a0)+
	dbra	d7,Intro.EffT

	tst.w	Resol(a4)			Si basse resolution, copie le resultat dans BckScreen
	beq.s	Intro.Lo2

	move.w	#0,$FFFF8240.w
	move.l	LogScreen(a4),a1
	move.l	BckScreen(a4),a0
	lea	34(a0),a0
	move.w	#199,d7
Intro.HLin	moveq	#19,d6
	move.w	d7,-(sp)
Intro.HWrd	move.w	(a0),d0		Lecture des plans BR
	move.w	d0,d1
	move.w	d0,d2
	move.w	d0,d3
	addq.l	#8,a0
	moveq	#0,d4		Plans HR prevus
	moveq	#0,d5
	moveq	#15,d7		Compteur de bits
Intro.HBit	roxl.w	#1,d0		Conversion plan BR->HR
	roxl.l	#1,d5
	roxl.w	#1,d1
	roxl.l	#1,d5
	roxl.w	#1,d2
	roxl.l	#1,d4
	roxl.w	#1,d3
	roxl.l	#1,d4
	dbra	d7,Intro.HBit
	move.l	d5,(a1)+
	move.l	d4,76(a1)
	dbra	d6,Intro.HWrd
	lea	80(a1),a1
	move.w	(sp)+,d7
	dbra	d7,Intro.HLin

	move.l	LogScreen(a4),a0
	move.l	BckScreen(a4),a1	Et copie du resultat dans le BckScreen
	lea	34(a1),a1
	bsr	CopyScreen
	bra.s	Intro.Hi2


Intro.Lo2	move.l	BckScreen(a4),a0
	move.l	LogScreen(a4),a1
	lea	34(a0),a0
	bsr	CopyScreen
	bsr	Stars
	bsr	SwapScrn

	move.l	BckScreen(a4),a1
	move.l	2+14(a1),d0
	move.l	d0,CurColor+14(a4)
	move.l	d0,BackColor+14(a4)
	move.l	Other(a4),a5
	move.l	d0,CurColor+14(a5)
	move.l	d0,BackColor+14(a5)

Intro.Hi2	moveq	#39,d7

Intro.S2	move.w	d7,-(sp)
	bsr	ClsNorm
	move.l	BckScreen(a4),a0
	moveq	#39,d0
	sub.w	(sp),d0
	mulu	#320,d0
	lea	34(a0,d0.w),a0
	move.l	LogScreen(a4),a1
	moveq	#59,d0
	bsr	CS.Loop
	tst.w	(sp)
	bne.s	Intro.S2.1
	move.l	LogScreen(a4),a0
	move.l	BckScreen(a4),a1
	add.w	#034,a1
	bsr	CopyScreen

Intro.S2.1	bsr	Stars
	addq.l	#1,TimerL(a4)
	bsr	SwapScrn

	move.w	(sp)+,d7
	dbra	d7,Intro.S2

Intro.F3	XBIOS	37,2		VSYNC
	move.l	BckScreen(a4),a0
	move.l	LogScreen(a4),a1
	add.w	#34,a0
	bsr	CopyScreen
	bsr	Stars
	addq.l	#1,TimerL(a4)
	bsr	SwapScrn
	move.w	CurColor+18(a4),d0

	move.w	d0,d1
	and.w	#$F00,d1
	beq.s	Intro.F3R
	sub.w	#$100,d0
Intro.F3R	move.w	d0,d1
	and.w	#$0F0,d1
	beq.s	Intro.F3V
	sub.w	#$010,d0
Intro.F3V	move.w	d0,d1
	and.w	#$00F,d1
	beq.s	Intro.F3B
	sub.w	#$001,d0
Intro.F3B:

	move.w	d0,CurColor+18(a4)
	move.w	d0,CurColor+18(a5)
	move.w	d0,BackColor+18(a4)
	move.w	d0,BackColor+18(a4)
	bne.s	Intro.F3


	lea	DF.HighTechBrain(pc),a0
	lea	DessineFond(pc),a1
	move.l	a0,2(a1)

	lea	OList(a4),a0	Initialisation du monde de Demo
	lea	IntroWorld(pc),a1
	move.w	(a1)+,d0		Nombre d'objets
	move.w	d0,ObjNum(a4)
	subq.w	#1,d0		Adaptation DBRA
Intro.1	move.w	(a1)+,(a0)
	move.l	(a1)+,4(a0)
	move.w	(a1)+,8(a0)
	lea	32(a0),a0
	dbra	d0,Intro.1

	move.w	#7000,PosZ(a4)
	move.w	#2048,KFactor(a4)
	move.w	#7,LFactor(a4)
	clr.w	CurX(a4)
	clr.w	CurY(a4)
	clr.w	CurZ(a4)

	add.l	#DemoOTab-ObjTab,AdObjTab(a4)		Passe sur la table des objets locaux
	sub.w	#15,PosY(a4)

	move.l	AdIntroTxt(a4),a0
	move.l	Other(a4),a5
	move.l	a0,TextAd(a5)
	clr.w	TextWait0(a5)
	bsr	InstalTScroll

* Lance la demo avec ObjTab
	lea	Langage.Menu(pc),a0
	move.l	a0,AdTexts(a4)
	moveq	#'0',d0
	lea	Langue.Menu.Items(pc),a0
	bsr	MakeMenu

	lea	TheListOfFiles(pc),a0
	mulu	#13,d0
	add.w	d0,a0

	move.l	a0,-(sp)
	bsr	LoadFile
	move.l	a0,AdTexts(a4)
	move.l	Other(a4),a5
	move.l	a0,AdTexts(a5)

	move.l	(sp)+,a0
	move.b	#'N',11(a0)
	bsr	LoadFile
	move.l	a0,TabNames(a4)

*****************************************************************************
*		Protection du programme
*****************************************************************************
	IFEQ	PROTECTED-1
Protect	move.w	$4BC.w,Seed(a4)
	bsr	Random
	move.w	d0,d7
	bsr	Random
	eor.w	d7,d0
	and.w	#63,d0
	mulu	#5,d0
	lea	ProtectCodes(pc),a0
	add.w	d0,a0		A0 pointe sur le code en cours
	move.l	a0,-(sp)

	moveq	#'X',d0
	moveq	#0,d1
	bsr	FindText
	move.l	(sp),a0

Code.FPag	move.b	(a1)+,d0		Recherche le numero de page
	cmp.b	#'.',d0
	bne.s	Code.FPag

	moveq	#0,d0		recupere le numero de page et remplace
	move.b	(a0)+,d0
	divu	#10,d0
	add.b	#'0',d0
	move.b	d0,-1(a1)
	swap	d0
	add.b	#'0',d0
	move.b	d0,(a1)+

Code.FPar	move.b	(a1)+,d0		Recherche le numero de paragraphe
	cmp.b	#'.',d0
	bne.s	Code.FPar

	moveq	#0,d0		recupere le numero de paragraphe et remplace
	move.b	(a0)+,d0
	add.b	#'0',d0
	move.b	d0,-1(a1)

Code.FMot	move.b	(a1)+,d0		Recherche le numero de page
	cmp.b	#'.',d0
	bne.s	Code.FMot

	moveq	#0,d0		recupere le numero de paragraphe et remplace
	move.b	(a0)+,d0
	add.b	#'0',d0
	move.b	d0,-1(a1)

	moveq	#'X',d0		Affiche le texte de protection
	bsr	AfficheTexteRsc
	lea	Query(pc),a0
	bsr	AfficheTexteSansAttente

Code.0	lea	CodeVal(pc),a1	Lecture du nom de fichier
	move.w	#-1,InvertLine(a4)
	bsr	MS.WaitK
	clr.b	(a1)+

	move.l	(sp)+,a0
	move.b	3(a0),(a1)+
	move.b	4(a0),(a1)+
	ENDC

* Protection Feuille imposee de force par Infogrames
	IFEQ	PROTECTED-2
Protect	move.w	$4BC.w,Seed(a4)		Reinitialise le generateur aleatoire (Valeur effectivement aleatoire vue qu'il y a eu une interaction avec l'utilisateur)
	lea	CodePos(pc),a0	Selectionne la position A0 a Z9
	moveq	#'A',d1
	moveq	#'J',d2
	bsr	RandomN
	move.b	d0,(a0)+

	moveq	#'1',d1
	moveq	#'8',d2
	bsr	RandomN
	move.b	d0,(a0)+

	lea	Code.Display(pc),a0		Affiche la demande de protection
	move.l	a0,AdTexts(a4)
	moveq	#'0',d0
	bsr	AfficheTexteRsc
	lea	QueryCode(pc),a0
	bsr	AfficheTexteSansAttente

	move.w	#-1,InvertLine(a4)
	moveq	#3,d0		4 chiffres a entrer
	lea	CodeVal(pc),a0	Endroit ou les stocker

Code.Chr	move.w	d0,-(sp)
	move.l	a0,-(sp)
Code.WK	bsr	DessineFond
	bsr	KeyPressed
	move.w	d2,d0		D0= Code ASCII de la touche
	cmp.b	#'0',d0
	blt.s	Code.WK
	cmp.b	#'9',d0
	bgt.s	Code.WK

	move.w	d0,-(sp)
	bsr	AfficheCarD0	Affiche le code et suivant
	move.w	(sp)+,d1
	move.l	(sp)+,a0
	move.w	(sp)+,d0
	move.b	d1,(a0)+
	dbra	d0,Code.Chr

	move.l	Other(a4),a5
	move.l	AdTexts(a5),AdTexts(a4)
	ENDC

*****************************************************************************
*		Quitter la demonstration
*****************************************************************************

	sub.l	#DemoOTab-ObjTab,AdObjTab(a4)		Repasse sur la table principale d'objets
	add.w	#15,PosY(a4)
	bsr	DeinstalTScroll

	moveq	#'M',d0
	moveq	#0,d1
	bsr	FindText
	move.l	a1,AdIntroTxt(a4)
	move.l	a1,TextAd(a4)
	move.l	Other(a4),a5
	move.l	a1,AdIntroTxt(a5)
	move.l	a1,TextAd(a5)
Intro.RNL	move.b	(a1)+,d0
	cmp.b	#'#',d0
	beq.s	Intro.End
	cmp.b	#13,d0
	bne.s	Intro.RNL
	move.b	#' ',-1(a1)
	move.b	#' ',(a1)
	bra.s	Intro.RNL

Intro.End	lea	Main.Menu+280(pc),a2

	IFEQ	PROTECTED-1
	lea	CodeVal(pc),a1
	moveq	#0,d0
	moveq	#0,d1
Code.T1	move.b	(a1)+,d2
	beq.s	Code.TE
	bset	#5,d2
	add.b	d2,d0
	eor.b	d2,d1
	bra.s	Code.T1

Code.TE	lsl.w	#8,d0
	add.w	d1,d0
	move.b	(a1)+,d7
	lsl.w	#8,d7
	move.b	(a1)+,d7

	eor.w	d7,d0
	and.w	#$7FFF,d0
	subq.w	#1,d0
	ENDC

	IFEQ	PROTECTED-2
	lea	CodePos(pc),a0	Test de la protection et invalidation des menus
	lea	CodeVal(pc),a1
 	lea	Main.Menu+280(pc),a2
	lea	ProtectCodes(pc),a3
	moveq	#0,d0
	moveq	#0,d1
	move.b	(a0)+,d0		Lecture de la colonne
	move.b	(a0)+,d1		Lecture de la ligne
	sub.w	#'A',d0
	sub.w	#'1',d1
	mulu	#10,d1
	add.w	d1,d0
	add.w	d0,d0		Pointeur sur la table des codes
	move.w	0(a3,d0.w),d0	Valeur du code reel

	moveq	#0,d7		Valeur du code entre par l'utilisateur
	moveq	#3,d6
Code.4	moveq	#0,d1
	move.b	(a1)+,d1
	sub.b	#'0',d1
	mulu	#10,d7
	add.w	d1,d7
	dbra	d6,Code.4
	eor.w	d7,d0
	and.w	#$7FFF,d0
	subq.w	#1,d0
	ENDC
	IFEQ	PROTECTED
	moveq	#-1,d0
	ENDC

	move.w	d0,-278(a2)
	move.w	d0,-276(a2)
	move.w	d0,-274(a2)
	move.w	d0,-268(a2)
	rts

TheListOfFiles:
	dc.b	"FRANCAIS.QBM",0
	dc.b	"ANGLAIS_.QBM",0
	dc.b	"ALLEMAND.QBM",0
	dc.b	"ESPAGNOL.QBM",0
	dc.b	"ITALIEN_.QBM",0

	EVEN

Langage.Menu:
	dc.b	"#MENU	0",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10
	dc.b	"#TITLE	 ",13,10

	dc.b	"FRANCAIS",13,10
	dc.b	"ENGLISH",13,10
	dc.b	"DEUTSCH",13,10
	dc.b	"CASTELLANO",13,10
	dc.b	"ITALIANO",13,10
	dc.b	"#END",13,10

	EVEN

Langue.Menu.Items:
	dc.w	0,-1,-1,-1,-1,-1


	IFEQ	PROTECTED-1
CodeVal	ds.b	40
ProtectCodes	INCBIN	\PROJET.CUB\PROTECT.BIN
	ENDC

	IFEQ	PROTECTED-2
Code.Display:
	dc.b	"#DISPLAY	0",13,10
	dc.b	"Code "
CodePos	dc.b	"A0",13,10
	dc.b	" ",13,10
	dc.b	" ",13,10
	dc.b	"#END",13,10,0

QueryCode	dc.b	1,17,17,"[____]",13,1,18,17,0

CodeVal	ds.b	4

RandomN	bsr	Random
	and.l	#$0000FFFF,d0
	sub.w	d1,d2
	addq.w	#1,d2
	divu	d2,d0
	swap	d0
	add.w	d1,d0
	rts


ProtectCodes	INCBIN	\PROJET.CUB\ALPHAPRO.BIN

	ENDC

	
* Definition du "High Tech Brain"
HTB.Y	equ	-800
IntroWorld:
	dc.w	26		Nombre d'objets
	dc.w	16,-300,HTB.Y-200,600	Les 8 gros cubes
	dc.w	16,-300,HTB.Y+400,600
	dc.w	16,300,HTB.Y-200,600
	dc.w	16,300,HTB.Y+400,600
	dc.w	16,300,HTB.Y+300,-700
	dc.w	16,-300,HTB.Y-300,-700
	dc.w	16,300,HTB.Y-300,-700
	dc.w	16,-300,HTB.Y+300,-700
	dc.w	16,-300,HTB.Y-300,0
	dc.w	16,-300,HTB.Y+300,0
	dc.w	16,300,HTB.Y-300,0
	dc.w	16,300,HTB.Y+300,0

	dc.w	0,-800,HTB.Y-100,500
	dc.w	0,-800,HTB.Y-200,-600
	dc.w	0,-800,HTB.Y+300,500
	dc.w	0,-800,HTB.Y+200,-600
	dc.w	0,800,HTB.Y-100,500
	dc.w	0,800,HTB.Y-200,-600
	dc.w	0,800,HTB.Y+300,500
	dc.w	0,800,HTB.Y+200,-600
	dc.w	0,-800,HTB.Y-200,0
	dc.w	0,-800,HTB.Y+200,0
	dc.w	0,800,HTB.Y-200,0
	dc.w	0,800,HTB.Y+200,0

	dc.w	32,0,0,-1000		Front
	dc.w	48,0,0,1000		Nuque

	
* Routines .I du High Tech Brain
PtiCube.I	clr.w	DefColor(a4)
	bsr	Random
	and.w	#$F,d0
	bne.s	PtiCube.R
	addq.w	#8,DefColor(a4)
PtiCube.R	rts

* Scrolling en bas de l'ecran de textesInstalTScroll:
InstalTScroll:
	lea	TScroll(pc),a1

InstallVBL:
	move.w	#$2700,SR
	move.w	$454.w,d0
	move.l	$456.w,a0
ITS.1	tst.l	(a0)+
	dbeq	d0,ITS.1
	move.l	a1,-(a0)
	move.w	#$2000,SR
	rts

DeinstalTScroll:
	lea	TScroll(pc),a1

FreeVBL	move.w	#$2700,SR
	move.w	$454.w,d0
	move.l	$456.w,a0
ITS.2	move.l	(a0)+,d1
	cmp.l	d1,a1
	dbeq	d0,ITS.2
	clr.l	-(a0)
	move.w	#$2000,SR
	rts

TScroll	lea	TScroll(pc),a4
	add.l	#Vars2-TScroll,a4
	moveq	#1,d6
TSC.1	move.l	AdTScreen(a4),a0	Scroll 1 Pixel Ga. du Texte
	lea	24*320(a0),a0
	moveq	#79,d7
PtiC.SLf	move.l	-(a0),d0
	roxl.l	#1,d0
	move.l	d0,(a0)
	dbra	d7,PtiC.SLf
	dbra	d6,TSC.1

	addq.w	#2,TextWait0(a4)	Nouveau caractere ?
	cmp.w	#8,TextWait0(a4)
	blt.s	PtiC.NoP
	clr.w	TextWait0(a4)	Oui: Reaffichage

	move.l	TextAd(a4),a5
	cmp.b	#'#',(a5)+
	bne.s	PtiC.Ok
	move.l	AdIntroTxt(a4),a5
	addq.l	#1,a5
PtiC.Ok	move.l	a5,TextAd(a4)
	subq.l	#1,a5

	moveq	#36,d3			Affichage de 37 caracteres
	add.l	#23*320,AdTScreen(a4)	Offset 23 lignes
	clr.w	TextPos(a4)
	clr.w	TextCol(a4)
PtiC.1	move.b	(a5)+,d0
	cmp.b	#'#',d0
	bne.s	PtiC.C
	move.l	AdIntroTxt(a4),a5
	move.b	(a5)+,d0
PtiC.C	bsr	AfficheCarD0
	dbra	d3,PtiC.1
	sub.l	#23*320,AdTScreen(a4)	Restaure ancien TScreen

PtiC.NoP	tst.w	Resol(a4)
	bne.s	PtiCH.NoP

	move.l	AdTScreen(a4),a0
	lea	23*320(a0),a0
	move.l	PhyScreen(a4),a1
	lea	160*191+8(a1),a1
	moveq	#0,d3
	moveq	#7,d7
PtiC.3	moveq	#17,d6
PtiC.2	move.w	(a0)+,d0
	move.w	d3,(a1)+
	move.w	d0,(a1)+
	move.w	d3,(a1)+
	move.w	d3,(a1)+
	dbra	d6,PtiC.2
	lea	16(a1),a1
	addq.l	#4,a0
	dbra	d7,PtiC.3

	rts

PtiCH.NoP	move.l	AdTScreen(a4),a0
	lea	23*320(a0),a0
	move.l	PhyScreen(a4),a1
	lea	160*191+22(a1),a1
	moveq	#0,d3
	moveq	#7,d7
PtiCH.3	moveq	#17,d6
PtiCH.2	move.w	(a0)+,d0
	move.w	d0,(a1)+
	move.w	d0,78(a1)
	dbra	d6,PtiCH.2
	lea	44+80(a1),a1
	addq.l	#4,a0
	dbra	d7,PtiCH.3

	rts



Front.I	pea	HTB.Nuque(pc)
	pea	HTB.Front(pc)
	bra.s	HTB.Lines
Nuque.I	pea	HTB.FinTete(pc)
	pea	HTB.Nuque(pc)
HTB.Lines	move.l	#-1,-(sp)
	move.w	#7,Couleur(a4)

HTB.Line	movem.l	(sp)+,d7/a0/a1
	cmp.l	a1,a0
	bge.s	HTB.Exit

	move.w	(a0)+,d2
	move.w	(a0)+,d1
	movem.l	d7/a0/a1,-(sp)
	sub.w	#165,d2
	sub.w	#100,d1
	muls.w	#20,d2
	muls	#20,d1
	moveq	#0,d0
	clr.w	ObjX(a4)
	clr.l	ObjY(a4)
	bsr	TransXYZ
	bsr	Perspect
	movem.w	(sp)+,d2-d3
	movem.w	d0-d1,-(sp)
	tst.w	d3
	bmi.s	HTB.Line
	bsr	Line
	bra.s	HTB.Line

HTB.Exit	rts

* Description de la tete du High Tech Brain
HTB.Front	dc.w	158,0
	dc.w	144,0
	dc.w	116,3
	dc.w	100,12
	dc.w	94,21
	dc.w	89,48
	dc.w	96,60
	dc.w	78,88
	dc.w	85,91
	dc.w	96,92
	dc.w	93,106
	dc.w	99,110
	dc.w	94,117
	dc.w	98,123
	dc.w	95,139
	dc.w	97,144
	dc.w	111,150
	dc.w	141,148
	dc.w	156,141
	dc.w	151,184
HTB.Nuque	dc.w	200,184
	dc.w	209,112
	dc.w	219,60
	dc.w	213,23
	dc.w	196,6
	dc.w	184,1
	dc.w	173,0
	dc.w	158,0
HTB.FinTete:
	dc.w	0


ClrMusic	tst.w	STisSTE(a4)
	bne.s	CM.STE

	moveq	#0,d6
	moveq	#-1,d7
	bra	PlaySound

CM.STE	tst.l	MusicAd(a4)
	beq.s	CM.NoMusic
	lea	MusicVBL(pc),a1
	bsr	FreeVBL
	clr.w	$FFFF8900.w
CM.NoMusic:
	clr.l	MusicPtr+0.w
	rts


***************************************************************************
*	Affichage des instructions de la demonstration
****************************************************************************
AfficheInstructions:

	move.l	BckScreen(a4),a0
	lea	34(a0),a0
	move.l	LogScreen(a4),a1
	lea	160*160(a1),a1
	clr.w	(a1)+
	move.w	#799,d7
AI.1	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbra	d7,AI.1

	move.l	LogScreen(a4),a0
	tst.w	Resol(a4)
	bne.s	AI.Hi

	lea	80(a0),a0
	move.w	#159,d7
AI.2	REPT	20
	clr.l	(a0)+
	ENDR
	lea	80(a0),a0
	dbra	d7,AI.2
	bra.s	AI.Lo

AI.Hi	lea	40(a0),a0
	move.w	#319,d7
AI.3	REPT	10
	clr.l	(a0)+
	ENDR
	lea	40(a0),a0
	dbra	d7,AI.3

AI.Lo	move.w	#160,d0
	add.w	d0,ClipG(a4)
	add.w	d0,ClipD(a4)
	add.w	#130,PosX(a4)
	sub.w	#20,PosY(a4)
	add.w	#500,PosZ(a4)
	movem.w	Alpha(a4),d0-d2		Sauvegarde de l'ancien regard
	movem.w	d0-d2,-(sp)

	move.w	#25,Alpha(a4)
	add.w	#200,Beta(a4)
	clr.w	Gamma(a4)
	bsr	TrigInit
	lea	Cadre.D(pc),a0
	clr.w	UseLocAng(a4)
	clr.w	ModObjX(a4)		Position dans l'espace relatif
	move.w	#250,ModObjY(a4)
	move.w	PosZ(a4),ModObjZ(a4)
	bsr	AffObj

	st	UseLocAng(a4)
	move.w	#200,Beta(a4)
	clr.w	BetaL(a4)
	move.w	(sp),AlphaL(a4)
	neg.w	AlphaL(a4)
	clr.w	GammaL(a4)
	clr.w	ModObjY(a4)
	lea	Camera.D(pc),a0
	bsr	AffObj

	move.w	BetaSpeed(a4),BetaL(a4)
	clr.w	AlphaL(a4)
	bsr	DV.Demo

	movem.w	(sp)+,d0-d2
	movem.w	d0-d2,Alpha(a4)	Restauration des angles de vue
	move.w	#160,d0
	sub.w	d0,ClipG(a4)
	sub.w	d0,ClipD(a4)
	sub.w	#130,PosX(a4)
	add.w	#20,PosY(a4)
	sub.w	#500,PosZ(a4)

DessineIcon	MACRO	PosX,PosY,AdIcon0,AdIcon1,Bit
	move.l	LogScreen(a4),a0
	tst.w	Resol(a4)
	bne.s	AI\@.Hi

	lea	96+160*(120+\2*16)+\1*8(a0),a0
	lea	\3-Fire0.X(a5),a1
	move.w	InputDev(a4),d0
	lea	Joystick1(pc),a2
	btst	#\5,0(a2,d0.w)
	beq.s	AI\@.Zer
	lea	\4-Fire0.X(a5),a1
AI\@.Zer	moveq	#15,d7
AI\@.1	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	lea	152(a0),a0
	dbra	d7,AI\@.1
	bra.s	AI\@.Lo

AI\@.Hi	lea	48+160*(120+\2*16)+\1*2(a0),a0
	lea	\3-Fire0.X(a5),a1
	move.w	InputDev(a4),d0
	lea	JoyStick1(pc),a2
	btst	#\5,0(a2,d0.w)
	beq.s	AI\@H.Zer
	lea	\4-Fire0.X(a5),a1
AI\@H.Zer	moveq	#15,d7
AI\@H.1	movem.w	(a1),d0-d3
	move.w	d0,(a0)
	move.w	d2,80(a0)
	lea	160(a0),a0
	addq.l	#8,a1
	dbra	d7,AI\@H.1

AI\@.Lo:
	ENDM

	IFNE	0
	lea	Cadre.D(pc),a5
	add.l	#Fire0.X-Cadre.D,a5

	DessineIcon	0,0,Fire0.X,Fire1.X,7
	DessineIcon	0,-1,Up0.X,Up1.X,0
	DessineIcon	0,1,Dn0.X,Dn1.X,1
	DessineIcon	-1,0,Lf0.X,Lf1.X,2
	DessineIcon	1,0,Rt0.X,Rt1.X,3
	ENDC


ConstantTime:
	move.l	$4BA.w,d0			Supprime le decomptage de temps
	add.l	#$32000,d0
	move.l	d0,SysTime0(a4)
	rts

Cadre.D	dc.b	XM5,ZM5,XP10,ZP10,XM10,END
	dc.b	1
	dc.b	3,4,$F1
	dc.b	4,5,$F1
	dc.b	5,6,$F1
	dc.b	6,3,$F1
	dc.b	END,END

Camera.D	dc.b	ZM10,XM1,YM1,XP3,YP3,XM3,ZM2,XP3,YM3,XM3	objectif
	dc.b	YP1,XP1,XP1,YP1,XM1,ZM1,XP1,YM1,XM1	tube
	dc.b	XM1,YM1,XP3,YP4,XM3,ZM3,YM2,YM2	boitier
	dc.b	ZP1,XP3,ZM1,YP2,YP2,END

	dc.b	1

	dc.b	5,4,7,6,$F1
	dc.b	5,6,$F7
	dc.b	6,7,$F7
	dc.b	7,8,9,6,$F7
	dc.b	11,10,9,8,$F4

	dc.b	23,22,25,24,$F4
	dc.b	23,30,29,22,$F6
	dc.b	25,26,33,24,$F7
	dc.b	29,30,32,27,$F5
	dc.b	27,32,33,26,$F4
	dc.b	14,19,20,13,$F5
	dc.b	13,20,17,16,$F6
	dc.b	16,17,18,15,$F7

	dc.b	4,11,8,7,$F5
	dc.b	5,10,11,4,$F6
	dc.b	22,29,27,26,25,$F5
	dc.b	END,END

	EVEN



****************************************************************************
*	Transformation de la valeur contenue dans D0 en chiffres
****************************************************************************
* Entree : D0 : Donnee (entre +-9999)
*	 A0 : Adresse ou stocker le resultat
Num2Str	move.b	#"+",(a0)
	tst.w	d0
	bpl.s	N2S.Pos
	neg.w	d0
	move.b	#"-",(a0)
N2S.Pos	addq.l	#5,a0
	moveq	#3,d1
N2S.Loop	divu	#10,d0
	swap	d0
	add.b	#'0',d0
	move.b	d0,-(a0)
	clr.w	d0
	swap	d0
	dbra	d1,N2S.Loop
	rts

PrNum	lea	N2S.Buf(pc),a0
	bsr.s	Num2Str
	lea	N2S.Buf(pc),a0
	tst.w	Resol(a4)
	beq	FastPrt
	bra	HiFPrt
	
N2S.Buf	dc.b	'+0000',0

****************************************************************************
*		Fin du programme : On quitte proprement
****************************************************************************
Fin	bsr	ClrMusic
	tst.w	Resol(a4)
	bne.s	Fin.HAM
	bsr	ClearHAM		Supprime les interruptions de changement de palette

Fin.HAM	move.w	#$FFF,$FFFF8240.w
	clr.l	$FFFF8242.w
	clr.l	$FFFF8246.w
	clr.w	$FFFF825E.w
	pea	RestMouse(pc)
	move.w	#2,-(sp)
	XBIOS	25,8

	move.b	#6,$484.w
	move.w	OldResol(a4),-(sp)
	move.l	DefScreen(a4),-(sp)
	move.l	DefScreen(a4),-(sp)
	XBIOS	5,12

	XBIOS	34,2		KBDVBASE
	move.l	d0,a0
	move.l	OldMsVec(a4),16(a0)	Restaure l'ancienne routine souris
	move.l	OldJoyst(a4),24(a0)
	dc.w	$a009		Montre la souris

	move.l	OldEtvCritic(a4),$404.w
	move.l	$98.w,$118.w	Restauration de l'interruption a partir de TRAP #6

	move.l	TabNames(a4),-(sp)
	GEMDOS	$49,6		MFREE
	move.l	Tableaux(a4),-(sp)
	GEMDOS	$49,6
	move.l	BckScreen(a4),-(sp)
	GEMDOS	$49,6
	move.l	AdScores(a4),-(sp)
	GEMDOS	$49,6
	move.l	AdTexts(a4),-(sp)
	GEMDOS	$49,6

	move.l	MusicAd(a4),-(sp)
	GEMDOS	$49,6

	move.l	SpareUSP(a4),-(sp)
	GEMDOS	$20,6

FinProg	clr.w	-(sp)
	trap	#1

RestMouse	dc.b	$15,$08


	IFNE	DEMO_REC
SaveDemo	clr.w	-(sp)		Fichier Lecture / Ecriture
	pea	DemoName(pc)	
	GEMDOS	$3C,8		CREATE
	move.w	d0,-(sp)		Sauvegarde du Handle
	move.l	MoveMemAd(a4),-(sp)	Tampon des donnees
	move.l	EndMvMem(a4),a6
	sub.l	(sp),a6		Longueur de sauvegarde
	move.l	a6,-(sp)		Longueur de sauvegarde
	move.w	d0,-(sp)		Handle
	GEMDOS	$40,12		WRITE
	GEMDOS	$3E,4		CLOSE (le handle est deja dans la pile)
	bclr	#2,Options1(a4)
	rts
DemoName	dc.b	'DEMO.INC',0
	ENDC


	IFEQ	DEMO_REC
SaveDemo	pea	DemoName(pc)
	GEMDOS	9,6		Print Text
	GEMDOS	1,2
	rts
DemoName	dc.b	'Sauvegarde de demo debranchee',13,10,0
	ENDC


***************************************************************************
*		Demarrage d'un tableau
***************************************************************************
NewTablo	tst.w	Sortie(a4)	Si premiere entree
	bmi.s	NewT.Strt		Alors pas de degrade extinction

	moveq	#15,d7
NewT.1	moveq	#15,d6
	lea	CurColor(a4),a0
	move.l	Other(a4),a5

NewT.1C	move.w	(a0),d0
	and.w	#$777,d0
	lsr.w	#1,d0
	move.w	d0,(a0)+
	dbra	d6,NewT.1C

	move.w	d7,-(sp)

	btst	#1,Options1(a4)	Si un seul joueur
	bne.s	NewT.OneP
	movem.l	CurColor(a4),d0-d7	Alors copie des couleurs
	movem.l	d0-d7,CurColor(a5)

NewT.OneP	XBIOS	37,2
	move.w	(sp)+,d7
	dbra	d7,NewT.1

NewT.Strt	bsr	InitOL

	lea	TabName(pc),a0
	move.l	TabNames(a4),a1
	move.l	TabVisitAd(a4),a2
	move.w	Tableau(a4),d0
	move.w	Joueur(a4),d1
	addq.w	#1,d1
	move.b	d1,0(a2,d0.w)

	subq.w	#1,d0		Lecture du nom du tableau
	bmi.s	NewT.EntN		Cas ou le tableau est 0
NewT.LkNm	tst.b	(a1)+		Sinon cherche le bon
	bne.s	NewT.LkNm
	dbra	d0,NewT.LkNm

NewT.EntN	moveq	#-1,d0
	move.l	a1,a2
	moveq	#38,d1
NewT.Leng	addq.w	#1,d0
	tst.b	(a2)+
	dbeq	d1,NewT.Leng		D0= Longueur du nom du tableau

	moveq	#40,d1
	tst.w	Resol(a4)
	beq.s	NewT.LoR
	moveq	#80,d1
NewT.LoR	sub.w	d0,d1
	asr.w	#1,d1
	
NewT.Spcs	move.b	#' ',(a0)+
	dbra	d1,NewT.Spcs

NewT.Copy	move.b	(a1)+,(a0)+
	bne.s	NewT.Copy
*	bsr	DessineIcons		Affichage du panneau d'icones

	lea	OList(a4),a1	Recherche de la porte complementaire eventuelle
	move.w	ObjNum(a4),d7
	subq.w	#1,d7
	move.w	Sortie(a4),d6
	and.w	#$FFF0,d6		Elimination de la couleur
	bmi.s	NewT.Door
	sub.w	#$20,d6		Decalage de 180 degres
	and.w	#$30,d6		Recupere un numero de porte de 0-3
	add.w	#$40,d6		Numero de la premiere porte

NewT.Door	movem.w	(a1),d0-d4
	lea	32(a1),a1
	and.w	#$FFF0,d0
	cmp.w	d6,d0
	dbeq	d7,NewT.Door
	bne.s	NewT.NoDr
	movem.w	d2-d4,CurX(a4)
	sub.w	#1000,CurY(a4)
	move.w	#250,d5
	move.w	#-1000,d6
	move.w	Beta(a4),d7
	neg.w	d7
	bsr	Rotate
	sub.w	d0,CurX(a4)
	sub.w	d1,CurZ(a4)

NewT.NoDr	clr.w	SpeedX(a4)
	clr.w	SpeedY(a4)
	clr.w	SpeedZ(a4)

	bsr	DessTout
	moveq	#3,d7
	moveq	#0,d2
NewT.2	moveq	#15,d6
	lea	CurColor(a4),a0
	lea	BackColor(a4),a1
NewT.2C	move.w	(a1)+,d0
	lsr.w	d7,d0
	and.w	d2,d0
	move.w	d0,(a0)+

	dbra	d6,NewT.2C
	add.w	d2,d2
	or.w	#$111,d2
	movem.w	d2/d7,-(sp)
	btst	#1,Options1(a4)
	beq.s	NewT.1P2
	tst.w	Sortie(a4)
	bpl.s	NewT.2ndF
NewT.1P2	move.l	Other(a4),a5
	movem.l	CurColor(a4),d0-d7
	movem.l	d0-d7,CurColor(a5)

NewT.2ndF	XBIOS	37,2
	movem.w	(sp)+,d7/d2
	dbra	d7,NewT.2

	movem.l	BackColor(a4),d0-d7		Retablit les couleurs compatibles STE
	movem.l	d0-d7,CurColor(a4)

	rts


***************************************************************************
*		Programme d'affichage des scores
***************************************************************************
* Teste si on entre dans le tableau des scores
MS.Check	move.l	AdScores(a4),a1
	lea	30(a1),a1
	moveq	#13,d7		Nombre de scores a tester
MS.Chk1	moveq	#7,d6		8 caracteres
	move.l	a0,a2
	move.l	a1,a3
MS.Chk2	move.b	(a2)+,d0
	cmp.b	(a3)+,d0
	bgt.s	MS.Enter
	blt.s	MS.Next
	dbra	d6,MS.Chk2

MS.Next	lea	40(a1),a1
	dbra	d7,MS.Chk1
	rts

* Entre quelqu'un dans le tableau des scores
MS.Enter	lea	-30(a1),a1
	move.l	a1,-(sp)

	move.l	AdScores(a4),a3
	lea	40*14(a3),a3
	lea	-40(a3),a2
MS.CopyT	cmp.l	a1,a2
	ble.s	MS.CpyTE
	move.b	-(a2),-(a3)
	bra.s	MS.CopyT

MS.CpyTE	move.l	a1,a2		Effacement de l'ancien nom
	moveq	#29,d7
MS.Clear	move.b	#' ',(a2)+
	dbra	d7,MS.Clear

	moveq	#7,d7
MS.CpySc	move.b	(a0)+,(a2)+
	dbra	d7,MS.CpySc

	moveq	#'I',d0
	lea	Score+8(pc),a2
	cmp.l	a0,a2
	beq.s	MS.P1
	moveq	#'J',d0
MS.P1	bsr	AfficheTexteRsc
	lea	Query(pc),a0
	bsr	AfficheTexteSansAttente

	move.l	(sp)+,a1		Recupere l'adresse ou stocker le nom
	bsr	MS.WaitK

	clr.w	-(sp)		Creation d'un fichier normal
	pea	ScoresFileName(pc)
	GEMDOS	$3C,8		CREATE
	move.w	d0,d7
	bmi.s	MS.Quit2

	move.l	AdScores(a4),-(sp)
	pea	600.w
	move.w	d7,-(sp)
	GEMDOS	$40,12		WRITE

	move.w	d7,-(sp)
	GEMDOS	$3F,4		CLOSE

MS.Quit2	rts

* Lecture de touches
MS.WaitK	move.l	a1,-(sp)
	bsr	DessineFond
	bsr	KeyPressed
	move.l	(sp)+,a1

	move.w	d2,d0
	beq.s	MS.WaitK
	cmp.b	#13,d0
	beq.s	MS.QuitE

	cmp.b	#8,d0
	bne.s	MS.NoBSp
	cmp.w	#2,TextCol(a4)
	beq.s	MS.WaitK

	move.l	AdTScreen(a4),a2
	move.w	TextPos(a4),d1
	lea	0(a2,d1.w),a2
	clr.b	240(a2)
	clr.b	280(a2)
	subq.w	#1,TextCol(a4)
	subq.w	#1,TextPos(a4)
	move.b	#' ',-(a1)
	clr.b	-1(a2)
	clr.b	39(a2)
	clr.b	79(a2)
	clr.b	119(a2)
	clr.b	159(a2)
	clr.b	199(a2)
	st	239(a2)
	st	279(a2)
	bra.s	MS.WaitK
	
MS.NoBSp	cmp.w	#29,TextCol(a4)
	bge.s	MS.WaitK

	cmp.b	#32,d0
	bcs.s	MS.WaitK
	move.b	d0,(a1)+

	move.l	a1,-(sp)
	bsr	AfficheCarD0
	move.l	(sp)+,a1

	bra	MS.WaitK

* Sauvegarde du tableau des scores quand une modification a ete faite
MS.QuitE	rts
	
AfficheScores:
	bclr	#1,Options1(a4)
	bsr	InitDessineFond
	bsr	MS.NoUpdate
	bra	MainMenu

ModifieScore:
	bsr	InitDessineFond
	tst.w	InputDev(a4)
	bmi.s	MS.NoUpdate
	btst	#0,Options1(a4)
	bne.s	MS.NoUpdate

	tst.w	Joueur(a4)
	beq.s	MS.Plyr1
	bsr	SwapVars

MS.Plyr1	bclr	#1,Options1(a4)
	beq.s	MS.OnlyOnePlayer

	lea	Score2(pc),a0
	bsr	MS.Check
MS.OnlyOnePlayer:
	lea	Score(pc),a0	A0 pointe sur le score en cours
	bsr	MS.Check

* Affichage sans modification du score
MS.NoUpdate:
	bsr	InstalTScroll
	moveq	#'H',d0
	bsr	AfficheTexteRsc

	move.l	AdScores(a4),a1
	moveq	#13,d7
MS.OneLine:
	bsr	AfficheLigneCentree
	addq.l	#1,a1
	dbra	d7,MS.OneLine

	bsr	ClrKey
MS.Wait	bsr	DessineFond
	bsr	KeyPressed
	bpl.s	MS.Wait

	bra	DeInstalTScroll


************************************************************************
*	Routines de changements doux de couleurs...
************************************************************************
FonduAuNoir:
	moveq	#15,d7
FAN.1	moveq	#15,d6
	lea	CurColor(a4),a0
	move.l	Other(a4),a5
	lea	CurColor(a5),a1

FAN.1C	move.w	(a0),d0
	and.w	#$777,d0
	lsr.w	#1,d0
	move.w	d0,(a0)+
	move.w	(a1),d0
	and.w	#$777,d0
	lsr.w	#1,d0
	move.w	d0,(a1)+

	dbra	d6,FAN.1C

	move.w	d7,-(sp)
	XBIOS	37,2
	XBIOS	37,2
	move.w	(sp)+,d7
	dbra	d7,FAN.1
	rts


* Effectue un fondu au blanc en fonction des couleurs dans BackColor
FonduAuBlanc:
	move.l	Other(a4),a5
	moveq	#3,d7
	moveq	#0,d2
FAB.2	moveq	#15,d6
	lea	CurColor(a4),a0
	lea	BackColor(a4),a1
	lea	CurColor(a5),a2
	lea	BackColor(a5),a3
FAB.2C	move.w	(a1)+,d0
	lsr.w	d7,d0
	and.w	d2,d0
	move.w	d0,(a0)+
	move.w	(a3)+,d0
	lsr.w	d7,d0
	and.w	d2,d0
	move.w	d0,(a2)+

	dbra	d6,FAB.2C
	add.w	d2,d2
	or.w	#$111,d2
	movem.w	d2/d7,-(sp)

	XBIOS	37,2
	movem.w	(sp)+,d7/d2
	dbra	d7,FAB.2

	movem.l	BackColor(a4),d0-d7		Retablit les couleurs compatibles STE
	movem.l	d0-d7,CurColor(a4)

	movem.l	BackColor(a5),d0-d7
	movem.l	d0-d7,CurColor(a5)

	rts

***************************************************************************
*		Affichage des menus sur fond d'objets tournants
***************************************************************************
*
* Initialisation
*
InitDessineFond:
	moveq	#100,d7
	bsr	PlayMusic

	bsr	FonduAuNoir

	clr.w	NStars(a4)	Pas d'etoiles au debut
	lea	DF.BackInv(pc),a0
	lea	DessineFond(pc),a1
	move.l	a0,2(a1)

	clr.w	PosZ(a4)
	move.w	#256,KFactor(a4)
	move.w	#9,LFactor(a4)
	clr.w	CurX(a4)
	clr.w	CurY(a4)
	clr.w	CurZ(a4)

	bsr	AC.Clear
	bsr	ClsNorm
	bsr	SwapScrn
	
	movem.l	CouleursDessineFond(pc),d0-d7
	move.l	Other(a4),a5
	movem.l	d0-d7,BackColor(a4)
	movem.l	d0-d7,BackColor(a5)
	bsr	FonduAuBlanc

	clr.l	TimerL(a4)	Remet le Timer dans un etat determine
	clr.l	OList(a4)		Indique objet "Null" couleur 0
	move.w	#$007,12+OList(a4)	Indique que la couleur courante est la blanche
	move.w	#0,14+OList(a4)	Garde la couleur blanche un temps
	rts

CouleursDessineFond:
	dc.w	$000,$700,$007,$070,$444,$555,$666,$777,$077,$707,$770,$740,$047,$310,$642,$770

*-----------------------------------------------------------------------
*		 Affichage proprement dit
*-----------------------------------------------------------------------
* OList est utilise de la fa�on suivante:
* 0 : Numero de l'objet qui avance ou qui tourne (0-63)
* 2 : Couleur de l'objet qui avance ou qui tourne (0-15)
* 4 : Numero de l'objet qui fuit
* 6 : Couleur de l'objet qui fuit
* 8 : Vitesse X de l'objet qui fuit
* 10: Vitesse Y de l'objet qui fuit
* 12: Numero de la couleur de depart ($000-$777)
* 14: Ce qu'il faut ajouter a la couleur de depart


DessineFond	jmp	0
DF.Back	lea	Text2ScrI(pc),a0
	bra.s	DF.Patch
* La meme chose que DF.Back, mais avec un fond inverse
DF.BackInv:
	lea	Text2Scr(pc),a0
DF.Patch	lea	DF.ToPatch+2(pc),a1		Patcher le Text2Scr
	move.l	a0,(a1)

	move.l	BckScreen(a4),a0
	lea	34(a0),a0
	move.l	LogScreen(a4),a1
	bsr	CopyScreen		Recuperation de l'ecran de fond

	addq.w	#8,Beta(a4)		Rotations des objets sur eux memes
	move.w	Timer(a4),d1
	lsl.w	#3,d1
	move.w	#50,d0
	bsr	XCosY
	move.w	d2,Alpha(a4)
	clr.w	Gamma(a4)
	bsr	TrigInit			Et initialisation des directions

	lea	OList(a4),a5		A5 pointe sur la table d'objets

	move.w	Timer(a4),d0		Lecture du timer
	addq.l	#1,TimerL(a4)
	and.w	#63,d0			Base de temps d'environ 3 secondes
	beq.s	DF.Choix			Si 0, choisit un objet pour le fond

	cmp.w	#32,d0			Si les deux premieres secondes
	blt.s	DF.DeuxObjets

* Ici, il n'y a qu'un objet, qui tourne sur lui meme
	clr.w	ModObjX(a4)
	clr.w	ModObjY(a4)
	move.w	#4000,ModObjZ(a4)

	move.w	2(a5),DefColor(a4)

	move.w	(a5),d0
	lsl.w	#2,d0
	move.l	AdObjTab(a4),a1
	add.l	#TurnOTab-ObjTab,a1

	move.l	0(a1,d0.w),d0
	lea	0(a1,d0.l),a0
	bsr	AffObj

	bra	DF.ToPatch

* Choisit un objet pour le fond et une destination pour l'objet fuyant
DF.Choix	move.l	(a5),4(a5)	Copie l'objet tournant sur l'objet fuyant
	bsr	Random
	and.w	#63,d0		Selection d'un objet
	move.w	d0,(a5)		Numero d'objet tournant
	bsr	Random
	and.w	#15,d0
	move.w	d0,2(a5)		Couleur de l'objet tournant

	bsr	Random		Determination des positions X et Y
	move.w	d0,d1		Angle de rotation
	move.w	#256,d0
	move.w	d1,-(sp)
	bsr	XCosY
	move.w	d2,8(a5)
	move.w	(sp)+,d1
	bsr	XSinY
	move.w	d2,10(a5)	

	moveq	#0,d0		Indique TimerL=0
* Quand il y a deux objets a afficher simultanement

DF.DeuxObjets:
	clr.w	ModObjX(a4)	Affichage de l'objet du fond
	clr.w	ModObjY(a4)
	move.w	d0,-(sp)
	lsl.w	#8,d0
	neg.w	d0
	add.w	#8192+4000,d0
	move.w	d0,ModObjZ(a4)
	move.w	2(a5),DefColor(a4)

	move.w	(a5),d0
	lsl.w	#2,d0
	move.l	AdObjTab(a4),a1
	add.l	#TurnOTab-ObjTab,a1

	move.l	0(a1,d0.w),d0
	lea	0(a1,d0.l),a0
	bsr	AffObj

	lea	OList(a4),a5
	move.w	#4000,ModObjZ(a4)
	move.w	(sp)+,d0
	move.w	8(a5),d1		Vitesse X de l'objet de devant
	muls	d0,d1
	move.w	d1,ModObjX(a4)
	move.w	10(a5),d1
	muls	d0,d1
	move.w	d1,ModObjY(a4)

	move.w	6(a5),DefColor(a4)
	move.w	4(a5),d0
	lsl.w	#2,d0
	move.l	AdObjTab(a4),a1
	add.l	#TurnOTab-ObjTab,a1

	move.l	0(a1,d0.w),d0
	lea	0(a1,d0.l),a0
	bsr	AffObj

DF.ToPatch:
	jsr	0		Patche selon le cas en Text2Scr ou Text2ScrI

* Choix de la rotation de couleurs d'affichage des objets
	move.w	Timer(a4),d0
	and.w	#7,d0
	bne.s	DF.NeChoisitPasCouleur

DF.ChCol	bsr	Random		Choix de la couleur a changer
	lsr.w	#4,d0
	and.w	#3,d0
	beq.s	DF.ChCol
	subq.w	#1,d0
	lsl.w	#2,d0
	moveq	#7,d1
	lsl.w	d0,d1
	moveq	#1,d2
	lsl.w	d0,d2
	and.w	12+OList(a4),d1	Teste si cette composante est a 7 ou 0
	beq.s	DF.Is0
	neg.w	d2
DF.Is0	move.w	d2,14+OList(a4)	Stocke ce qu'il faut additionner
	muls	#7,d2		Teste si on tombe sur la couleur 0
	add.w	12+OList(a4),d2
	beq.s	DF.ChCol

	move.w	#6,Couleur(a4)
	bsr	Stars
	bra	SwapScrn
DF.NeChoisitPasCouleur:

	move.w	14+OList(a4),d1
	add.w	12+OList(a4),d1
	move.w	d1,12+OList(a4)	d1=Couleur saturee

	move.l	Other(a4),a5
	move.w	d1,BackColor+30(a4)	Pointeurs sur les registres de couleurs
	move.w	d1,BackColor+30(a5)
	move.w	d1,CurColor+30(a4)
	move.w	d1,CurColor+30(a5)

	move.w	#6,Couleur(a4)
	bsr	Stars
	bra	SwapScrn


* Pour l'affichage du High Tech Brain
DF.HighTechBrain:
	move.l	BckScreen(a4),a0
	lea	34(a0),a0
	move.l	LogScreen(a4),a1
	bsr	CopyScreen

	cmp.w	#2000,PosZ(a4)
	ble.s	DF.HTB.1
	sub.w	#100,PosZ(a4)

DF.HTB.1	addq.w	#8,Beta(a4)
	bsr	TrigInit

	move.w	#-1,JSuisMort(a4)	Supprime l'affichage de l'ombre et du vaisseau
	bsr	DessineMonde
	bsr	Text2Scr
	bra	SwapScrn


* Pour l'affichage du menu de jeu, se contente de copier l'ecran memorise
DF.Norm	move.l	Screen2Ad(a4),a0
	move.l	LogScreen(a4),a1
	bsr	CopyScreen

	bsr	Text2ScrI
	bra	SwapScrn


***************************************************************************
*	Selection de la zone de depart en mode emotion
***************************************************************************
LanceEmotion:
	bset	#0,Options1(a4)	On est en mode emotion
	clr.w	DoLoad(a4)

	clr.w	-(sp)		Zone de depart: 0
	clr.w	NStars(a4)

LE.Loop	move.l	TabVisitAd(a4),a0	Effacement de TabVisit
	moveq	#63,d7
LE.1	clr.l	(a0)+
	dbra	d7,LE.1

	bsr	ClsNorm

	move.w	(sp),d7
	moveq	#0,d0
	lea	TabDebutEmotion(pc),a0
	move.b	0(a0,d7.w),d0
	move.l	Other(a4),a5
	move.w	d0,Tableau(a4)	Pointe sur le tableau correct
	move.w	d0,Tableau(a5)
	move.l	TabVisitAd(a4),a0
	move.b	#1,0(a0,d0.w)	Fait afficher en blanc le point de depart

	bsr	AfficheCarte

	bsr	AC.Clear		Efface l'ecran texte
	move.w	(sp),d1
	moveq	#'1',d0
	bsr	FindText
	bsr	AfficheLigneCentree
	bsr	Text2Scr
	bsr	SwapScrn

	move.l	PhyScreen(a4),a0
	move.l	Screen2Ad(a4),a1
	bsr	CopyScreen

	move.w	(sp),d7
	addq.w	#1,d7
	lea	MapColors(pc),a0
	moveq	#0,d6
	move.l	Other(a4),a5
	lea	CurColor(a4),a1
	lea	BackColor(a4),a2
	lea	CurColor(a5),a3
	lea	BackColor(a5),a6

LE.Coulrs	move.w	(a0)+,d5
	cmp.w	d7,d6
	beq.s	LE.CoulOk
	and.w	#%011001100110,d5
	asr.w	#1,d5
LE.CoulOk	move.w	d5,(a1)+
	move.w	d5,(a2)+
	move.w	d5,(a3)+
	move.w	d5,(a6)+

	addq.w	#1,d6
	cmp.w	#15,d6
	bne.s	LE.Coulrs

	move.w	(a0)+,d5
	move.w	d5,(a1)+
	move.w	d5,(a2)+
	move.w	d5,(a3)+
	move.w	d5,(a6)+

LE.WKey	move.l	Screen2Ad(a4),a0
	move.l	LogScreen(a4),a1
	bsr	CopyScreen
	move.w	#3,Couleur(a4)
	bsr	Stars
	bsr	SwapScrn
	addq.l	#1,TimerL(a4)

	bsr	KeyPressed
	tst.w	d1
	bmi.s	LE.Fini
	move.w	d1,d2

	and.w	#%1010,d1
	beq.s	LE.NoPrev
	move.w	(sp)+,d7
	subq.w	#1,d7
	bpl.s	LE.PrevOk
	moveq	#11,d7
LE.PrevOk	move.w	d7,-(sp)
	bra	LE.Loop

LE.NoPrev	and.w	#%0101,d2
	beq.s	LE.WKey
	move.w	(sp)+,d7
	addq.w	#1,d7
	cmp.w	#12,d7
	bne.s	LE.NextOk
	moveq	#0,d7
LE.NextOK	move.w	d7,-(sp)
	bra	LE.Loop

LE.Fini	addq.l	#2,sp
	rts

TabDebutEmotion:
	dc.b	0,199,21,103,131,180,98,158,95,170,249,75


***************************************************************************
*		Selection des options pour les joueurs
***************************************************************************
SelectOptions:
	move.l	Other(a4),a5
	bclr	#1,Options2(a4)		Passe en mode remplissage de polys
	bclr	#1,Options2(a5)		Passe en mode remplissage de polys

	subq.w	#4,InputDev(a4)
	bsr	OnePlayer
	addq.w	#4,InputDev(a4)
	bsr	InitDessineFond

***************************************************************************
*		Menu principal
***************************************************************************
MainMenu	bsr	InstalTScroll

	move.l	Other(a4),a5
	clr.b	Options1(a4)
	clr.b	Options1(a5)

	moveq	#'0',d0		Menu principal
	lea	Main.Menu(pc),a0	Suite des numeros d'options
	move.l	#1000,d7		1000 images au maximum
	moveq	#3,d6		au bout de 1000 images, selectionne 3
	bsr	MakeMenuWait
	move.w	d0,-(sp)
	bsr	DeinstalTScroll
	move.w	(sp)+,d0
	cmp.w	#6,d0		Menu QUIT
	beq	Fin

	move.l	Other(a4),a5
	move.w	MM.Jou1(pc),InputDev(a4)
	move.w	MM.Jou2(pc),InputDev(a5)

	cmp.w	#5,d0		Chargement de partie
	beq	ChargeJeu

	move.w	d0,-(sp)
	bsr	FonduAuNoir
	move.w	(sp)+,d0

	cmp.w	#4,d0		Affichage des scores
	beq	AfficheScores

	cmp.w	#2,D0
	beq	LanceEmotion
	cmp.w	#3,d0
	beq	MM.LanceDemo

	clr.w	DoLoad(a4)	Indique pas de LOAD
	cmp.w	#1,d0		Connection simultanee
	bne.s	MM.Wait
	bset	#1,Options1(a4)
	move.l	Other(a4),a5
	move.b	Options1(a4),Options1(a5)	Utilise le mode Bicolore eventuelement

MM.Wait	bsr	ClrKey
	rts

MM.LanceDemo:
	subq.w	#4,InputDev(a4)
	clr.w	DoLoad(a4)
	rts

Main.Menu	dc.w	0		Numero d'item selectionne
	dc.w	1,2,3,-1,-1,2,-1
MM.Jou1	dc.w	1
MM.Jou2	dc.w	2

***************************************************************************
*		Selection d'un menu
***************************************************************************
* Entree
* D0: le nom du menu ('0', '1',...)
* A0: Pointeur sur table de menu
*	- Un mot qui indique la derniere selection
*	- Un mot par entree qui indique la valeur de l'entree
* D6: Pour MakeMenuWait, selection par defaut
* D7: Pour MakeMenuWait, nombre d'images avant selection par defaut
*
* Sortie:
* D0: Indique la ligne qui a ete utilisee. Ce ne peut etre une ligne
* multiple
	
MakeMenu	moveq	#-1,d7
	moveq	#0,d6
MakeMenuWait:
	move.l	d7,MM.MaxImages(a4)
	move.w	d6,MM.Default(a4)

	lea	JoyStick1(pc),a1
	clr.l	(a1)		Efface la souris eventuellement

	moveq	#0,d1
	bsr	FindMenu

* Ici, A1 pointe sur le debut du texte du menu
* A0 sur la liste de parametres
MM.Again	movem.l	a0/a1,-(sp)
	move.b	#12,d0
	bsr	AfficheCarD0		Efface l'ecran
	move.w	#21*320,TextPos(a4)	Ligne 21
	clr.w	TextCol(a4)

	movem.l	(sp),a0/a1
	addq.l	#2,a0
	moveq	#0,d7		D7: Compteur de ligne
	moveq	#0,d6		D6: Offset de la premiere ligne non titre

MM.Line	move.l	a1,a2
	move.b	(a1),d0
	cmp.b	#"#",d0		Teste si #E ou #T
	bne.s	MM.NorLn
	addq.l	#1,a1
	move.b	(a1)+,d0
	cmp.b	#"E",d0		Si fin du menu
	beq	MM.End1
MM.Find4	cmp.b	#9,(a1)+
	bne.s	MM.Find4
	addq.w	#1,d6		Indique qu'une ligne de plus est un titre
	bra.s	MM.Title

MM.NorLn	move.w	(a0)+,d0		Si pas le premier element
	bmi.s	MM.Title		Si n'est pas variable
	beq.s	MM.Title
MM.Find5	cmp.b	#10,(a1)+		Recherche une ligne
	bne.s	MM.Find5
	cmp.b	#9,(a1)+		Si un tab ne suit pas: trop grand
	bne.s	MM.TooBig
	subq.w	#1,d0
	bne.s	MM.Find5		Autant de fois que necessaire
	bra.s	MM.Title
MM.TooBig	move.l	a2,a1
	clr.w	-2(a0)		Et corrige a0

* Ici, A1 pointe sur l'item a afficher
MM.Title	bsr	AfficheLigneCentree
	addq.w	#1,d7		Incremente compteur de lignes

MM.Find6	cmp.b	#10,(a1)+
	bne.s	MM.Find6
	cmp.b	#9,(a1)		Si ligne suivante = TAB: Alternative
	beq.s	MM.Find6
	bra	MM.Line

* Le message est affiche
MM.End1	move.w	d7,d5		Nombre total de lignes du menu
	move.w	d7,d4
	sub.w	#20,d5
	neg.w	d5
	asr.w	#1,d5
	movem.w	d6/d7,-(sp)
MM.LiDisp	tst.w	d5		Saute le nombre de lig pour centrer
	beq.s	MM.End2
	moveq	#13,d0
	bsr	AfficheCarD0
	subq.w	#1,d5
	addq.w	#1,d4
	bra.s	MM.LiDisp

MM.End2	movem.w	(sp)+,d6/d7
	sub.w	d6,d7
	add.w	#21,d6		premiere position du menu
	sub.w	d4,d6		Nombre total de lignes affichees
	add.w	d6,d7		Derniere position du menu
	subq.w	#1,d7

	movem.l	(sp)+,a0/a1	Recupere le texte du menu
	move.w	(a0),d0		Indication du premier element de menu
	add.w	d6,d0
	movem.l	a0/a1,-(sp)	Liste des valeurs d'item
	movem.w	d0/d6-d7,-(sp)
	movem.w	(sp)+,d0-d2
	move.w	d0,InvertLine(a4)

MM.Boucle	movem.w	d0-d2,-(sp)	Stocke le no de ligne courant
	bsr	DessineFond

	lea	JoyStick2(pc),a1
	movem.w	(sp)+,d0-d2	Recupere le no de la ligne courante et les extremes
	move.b	(a1)+,d6
	or.b	(a1)+,d6
	move.b	d6,d7
	and.b	#%00000011,d7
	bne.s	MM.UpDn
	move.b	d6,d7
	and.b	#%10001100,d7
	bne.s	MM.Exit

	subq.l	#1,MM.MaxImages(a4)
	bne.s	MM.UpDn
	move.w	#128,d6
	move.w	d6,d7
	move.w	MM.Default(a4),d0	
	add.w	d1,d0
	bra.s	MM.Exit

MM.UpDn	btst	#JOY_UP,d6		Deplacement vers le haut
	beq.s	MM.NoUp
	subq.w	#1,d0
	cmp.w	d1,d0
	bge.s	MM.OkUp
	move.w	d2,d0
MM.OkUp	move.w	d0,InvertLine(a4)

MM.Clear	movem.w	d0-d2,-(sp)
	bsr	DessineFond
	movem.w	(sp)+,d0-d2

	lea	Joystick2(pc),a1	Attend que relache
	move.b	(a1)+,d6
	or.b	(a1)+,d6
	and.w	#3,d6
	bne.s	MM.Clear
	bra.s	MM.Boucle

MM.NoUp	btst	#JOY_DN,d6
	beq.s	MM.Boucle
	addq.w	#1,d0
	cmp.w	d2,d0
	ble.s	MM.OkDn
	move.w	d1,d0
MM.OkDn	move.w	d0,InvertLine(a4)
	bra.s	MM.Clear

MM.Exit	sub.w	d1,d0		En fonction du premier element
	movem.w	d0/d7,-(sp)

MM.WaitUp	bsr	ClrKey
	bsr	DessineFond	Attend que l'on ait relache

	movem.w	(sp)+,d0/d2	Numero d'element
	move.w	d0,d7
	add.w	d7,d7
	movem.l	(sp)+,a0/a1	Recupere la liste d'item
	move.w	d0,(a0)
	move.w	2(a0,d7.w),d1	Si item negatif
	bmi.s	MM.Fin

	btst	#JOY_RT,d2		Si vers la gauche
	beq.s	MM.NoLeft
	subq.w	#1,2(a0,d7.w)
	bpl	MM.Again
	clr.w	2(a0,d7.w)
	bra	MM.Again

MM.NoLeft	addq.w	#1,2(a0,d7.w)
	bra	MM.Again

MM.Fin	tst.b	d2
	bpl	MM.Again

	move.w	#-1,InvertLine(a4)
	rts



***************************************************************************
*		Affichages "Directs" d'un texte
***************************************************************************
* Affichage d'un texte complet
AfficheTexteSansAttente:
	bsr	AfficheTexteSurFond
ATSA.Boucle	tst.w	d0
	bpl.s	ATSA.Retour
	bsr	ATSF.1
	bra.s	ATSA.Boucle
ATSA.Retour	rts


***************************************************************************
*		Affichage de texte sur fond tournant
*	Entree avec a0 pointant sur le texte a afficher.
*	Retourne avec d0=0 si Out of Time, D0=-1 si KeyPressed
***************************************************************************
AfficheTexteSurFond:
	tst.w	Joueur(a4)
	beq.s	ATSF.J1
	bsr	SwapVars

ATSF.J1	clr.w	TextWait(a4)
	clr.w	TextWait0(a4)
	move.l	a0,TextAd(a4)

ATSF.1	tst.w	TextWait(a4)	Teste si fin du texte
	bpl.s	ATSF.C
	moveq	#0,d0		Retour avec d0=0
ATSF.R	rts

ATSF.C	bsr	KeyPressed	Si Fire presse
	tst.w	d0
	bmi.s	ATSF.R		Retour avec d0<>0

	moveq	#63,d7
ATSF.2	move.w	d7,-(sp)
	bsr	AfficheCaractereSuivant
	move.w	(sp)+,d7
	dbra	d7,ATSF.2

	bsr	DessineFond
	bra	ATSF.1


***************************************************************************
*		Superposition de l'ecran texte sur l'ecran
***************************************************************************
Text2Scr	tst.w	Resol(a4)
	bne	T2SH
	move.l	AdTScreen(a4),a0
	move.l	LogScreen(a4),a1
	lea	1600(a1),a1
	move.w	#3599,d0
T2S.1	move.w	(a0)+,d2
	or.w	d2,(a1)+
	or.w	d2,(a1)+
	or.w	d2,(a1)+
	or.w	d2,(a1)+
	dbra	d0,T2S.1
	bra.s	T2SI.Com

Text2ScrI	tst.w	Resol(a4)
	bne	T2SHI
	move.l	AdTScreen(a4),a0
	move.l	LogScreen(a4),a1
	lea	1600(a1),a1
	move.w	#3599,d0
T2SI.1	move.w	(a0)+,d2
	not.w	d2
	and.w	d2,(a1)+
	and.w	d2,(a1)+		Couleur utilisee no 0
	and.w	d2,(a1)+
	and.w	d2,(a1)+
	dbra	d0,T2SI.1

T2SI.Com	move.w	InvertLine(a4),d7
	bmi.s	T2S.Ok

	move.w	d7,d6
	mulu	#320,d6		d6: Offset dans TextScreen
	mulu	#8*160,d7		d7: Offset dans l'ecran

	move.l	AdTScreen(a4),a0
	lea	0(a0,d6.w),a0
	move.l	LogScreen(a4),a1
	lea	0(a1,d7.w),a1
	lea	1600(a1),a1
	move.w	#159,d7
	moveq	#0,d0
	moveq	#-1,d1

T2SI.2	move.w	(a0)+,d2
	move.w	d2,(a1)+
	move.w	d1,(a1)+
	move.l	d0,(a1)+
	dbra	d7,T2SI.2

T2S.Ok	rts

T2SH	move.l	AdTScreen(a4),a0
	move.l	LogScreen(a4),a1

	move.w	#179,d0
	lea	1620(a1),a1
T2S.H1	moveq	#19,d1
	move.l	a1,a2
T2S.H2	move.w	(a0)+,d2
	or.w	d2,(a2)+
	or.w	d2,78(a2)
	dbra	d1,T2S.H2
	lea	160(a1),a1
	dbra	d0,T2S.H1
	moveq	#-1,d0

	bra.s	T2SH.Com


T2SHI	move.l	AdTScreen(a4),a0
	move.l	LogScreen(a4),a1
	move.w	#179,d0
	lea	1620(a1),a1
T2S.IH1	moveq	#19,d1
	move.l	a1,a2
T2S.IH2	move.w	(a0)+,d2
	not.w	d2
	and.w	d2,(a2)+
	and.w	d2,78(a2)
	dbra	d1,T2S.IH2
	lea	160(a1),a1
	dbra	d0,T2S.IH1
	moveq	#0,d0
	
T2SH.Com	move.w	InvertLine(a4),d7
	bmi.s	T2SH.Ok

	mulu	#160*8,d7
	move.l	LogScreen(a4),a0
	lea	1600(a0),a0
	lea	0(a0,d7.w),a0
	moveq	#19,d7
T2SH.C1	move.l	d0,(a0)+
	dbra	d7,T2SH.C1
	lea	7*160(a0),a0
	moveq	#19,d7
T2SH.C2	move.l	d0,(a0)+
	dbra	d7,T2SH.C2

T2SH.Ok	rts


***************************************************************************
*		Affichage d'un caractere
***************************************************************************
AC.WaitUp	bsr	ClrKey
AC.Loop2	bsr	DessineFond		Attend qu'on relache
	bsr	KeyPressed
	tst.w	d0
	bmi.s	AC.Loop2
	rts

AC.At	move.b	(a0)+,d0		Position
	moveq	#0,d1
	move.b	(a0)+,d1
	move.l	a0,TextAd(a4)
	mulu	#320,d1
	add.w	d0,d1
	move.w	d0,TextCol(a4)
	move.w	d1,TextPos(a4)
	rts

AC.Clear	move.l	AdTScreen(a4),a0	Effacement de l'ecran texte
	move.w	#1999,d0
AC.Clear1	clr.l	(a0)+
	dbra	d0,AC.Clear1
	clr.w	TextPos(a4)
	clr.w	TextCol(a4)
	rts

AC.DoWait	tst.w	TextWait(a4)	Si Attente en cours...
	bmi.s	AC.Return
	subq.w	#1,TextWait(a4)
AC.Return	rts

AC.TextEnd:
	move.w	#-1,TextWait(a4)	Fin du texte : TextWait = -1
	rts

AC.NewLine:
	move.l	AdTScreen(a4),a1
	move.w	TextPos(a4),d1
	lea	0(a1,d1.w),a1
	clr.b	240(a1)
	clr.b	280(a1)
	sub.w	TextCol(a4),d1	Passage en debut de ligne
	add.w	#320,d1		Debut de la ligne suivante
	move.w	d1,TextPos(a4)
	clr.w	TextCol(a4)

AC.TstScr	move.l	AdTScreen(a4),a1
	move.w	TextPos(a4),d1
	cmp.w	#7040,d1		Si en bas d'ecran, Scrolle
	blt.s	AC.NoScroll

	lea	320(a1),a2
	move.l	a1,a3
	move.w	#1759,d7
AC.Scroll	move.l	(a2)+,(a3)+	Boucle principale du scroll
	dbra	d7,AC.Scroll

	moveq	#79,d7		Boucle d'effacement de la ligne du bas
	moveq	#0,d6
AC.Scrol2	move.l	d6,(a3)+
	dbra	d7,AC.Scrol2

	sub.w	#320,d1		Remet a jour la position ecran
	move.w	d1,TextPos(a4)

	bra.s	AC.TstScr		Autre passsage a la ligne ?

AC.NoScroll:
	rts

AC.Wait	move.b	(a0)+,d0		Temps d'attente
	move.w	d0,TextWait0(a4)
	move.l	a0,TextAd(a4)
	rts

* Entree dans la routine proprement dite
AfficheCaractereSuivant:
	tst.w	TextWait(a4)	Teste si une attente en cours
	bne.s	AC.DoWait

	move.l	TextAd(a4),a0	Adresse du texte courant
	moveq	#0,d0
	move.b	(a0)+,d0

	beq.s	AC.TextEnd

	move.l	a0,TextAd(a4)
AfficheCarD0:
	and.w	#$FF,d0
	cmp.b	#32,d0
	bge.s	AC.Print

	cmp.b	#11,d0
	beq	AC.WaitUp
	cmp.b	#12,d0
	beq	AC.Clear
	cmp.b	#13,d0
	beq	AC.NewLine
	cmp.b	#27,d0
	beq.s	AC.Wait
	cmp.b	#26,d0
	beq.s	AC.Skip
	cmp.b	#1,d0
	beq	AC.At

AC.Print	lsl.w	#3,d0		Adresse du caractere dans D0
	lea	CharSet(pc),a0
	lea	0(a0,d0.w),a0
	bsr	AC.TstScr

	lea	0(a1,d1.w),a1
	move.b	(a0)+,(a1)
	move.b	(a0)+,40(a1)
	move.b	(a0)+,80(a1)
	move.b	(a0)+,120(a1)
	move.b	(a0)+,160(a1)
	move.b	(a0)+,200(a1)
	move.b	(a0)+,240(a1)
	move.b	(a0)+,280(a1)
	st	241(a1)
	st	281(a1)

	addq.w	#1,TextPos(a4)	Passage au caractere suivant
	addq.w	#1,TextCol(a4)	Mise a jour de la colonne
AC.Skip	move.w	TextWait0(a4),TextWait(a4)	Temps d'attente

	cmp.w	#40,TextCol(a4)
	bge	AC.NewLine

	rts


***************************************************************************
*		Teste si on a appuye sur une touche
***************************************************************************
KeyPressed:
	move.w	#2,-(sp)
	BIOS	1,4

	move.w	d0,d2		Stocke le resultat pour les touches seules
	beq.s	KP.NoKey
	move.w	#2,-(sp)
	BIOS	2,4
	move.w	d0,d2		Stocke la touche dans D2
	moveq	#-1,d0		Et indique "Touche pressee"

KP.NoKey	lea	Joystick2(pc),a1
	moveq	#0,d1
	move.b	(a1)+,d1
	or.b	(a1)+,d1
	ext.w	d1

	or.w	d1,d0
	
	rts

ClrKey	lea	Joystick1(pc),a1
	clr.b	(a1)+
	clr.b	(a1)+
	clr.b	(a1)+
ClrKey.1	move.w	#2,-(sp)
	BIOS	1,4
	tst.w	d0
	beq.s	ClrKey.N

	move.w	#2,-(sp)
	BIOS	2,4
	bra.s	ClrKey.1

ClrKey.N	rts

***************************************************************************
*		Copie d'un ecran sur un autre
***************************************************************************
* Entree : A0 : Ecran source ; A1 : Ecran destination
* Modifie quasiment tous les registres
CopyScreen:
	moveq	#99,d0	Copie de 320 octets par boucle
CS.Loop	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,(a1)
	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,40(a1)
	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,80(a1)
	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,120(a1)
	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,160(a1)
	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,200(a1)
	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,240(a1)
	movem.l	(a0)+,d1-d7/a2/a3/a6
	movem.l	d1-d7/a2/a3/a6,280(a1)
	lea	320(a1),a1
	dbra	d0,CS.Loop
	rts



***************************************************************************
*		Affichage de la carte
***************************************************************************
AfficheCarte:
	btst	#1,Options1(a4)	Si un seul joueur, coherence tableaux
	bne.s	AC.2Plr
	move.l	Other(a4),a5
	move.w	Tableau(a4),Tableau(a5)

AC.2Plr	move.w	#15,Couleur(a4)	Affichage du polygone du fond
	lea	PolyNord(pc),a0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#5,d3
	bsr	FillPoly

	moveq	#-120,d7		Position du tableau en cours
	moveq	#15,d6		Nombre de lignes
AC.Ligne	moveq	#15,d5		Nombre de colonnes
AC.Col	lea	MapList(pc),a0
	and.w	#$FF,d7
	moveq	#0,d0
	move.b	0(a0,d7.w),d0
	move.w	d0,Couleur(a4)	Lecture de la couleur dans la table

	lea	PolyRemp(pc),a0
	moveq	#5,d3		Nombre de sommets
	move.w	d6,d1		Calcul de l'offset X
	sub.w	d5,d1
	muls	#10,d1
	add.w	#160,d1
	move.w	d6,d2		Calcul de l'offset Y
	add.w	d5,d2
	mulu	#5,d2
	sub.w	#180,d2
	neg.w	d2
	movem.w	d1-d2,-(sp)
	bsr	FillPoly
	movem.w	(sp)+,d1-d2

	move.l	TabVisitAd(a4),a1	Petit polygone interne
	moveq	#0,d0
	move.b	0(a1,d7.w),d0
	beq.s	AC.NoPlr
	add.w	#12,d0

	cmp.w	Tableau(a4),d7
	bne.s	AC.NoP1
	moveq	#15,d0
AC.NoP1	move.l	Other(a4),a5
	cmp.w	Tableau(a5),d7
	bne.s	AC.NoP2
	moveq	#15,d0

AC.NoP2	move.w	d0,Couleur(a4)
	lea	PolyHere(pc),a0
	moveq	#5,d3
	bsr	FillPoly
	
AC.NoPlr	add.w	#16,d7
	dbra	d5,AC.Col
 	subq.w	#1,d7
	dbra	d6,AC.Ligne


	rts

PolyRemp	dc.w	0,1,9,5,0,9,-9,5,0,1
PolyHere	dc.w	0,2,6,5,0,8,-6,5,0,3
PolyNord	dc.w	160,30,240+10,70-5,321,110,160,190,0,110

MapList	dc.b	1,1,1,1,3,3,3,3,3
	dc.b	11,11,11,1,1,1,1,1,1,1,1,3,3,3,3,3
	dc.b	11,11,1,1,1,1,1,1,1,1,1,3,3,3,4,4
	dc.b	1,1,1,1,1,1,1,9,1,1,1,3,3,3,4,4
	dc.b	12,12,12,12,9,9,9,9,7,7,7,4,4,4,4,4
	dc.b	12,12,12,12,9,9,9,9,7,7,7,4,4,4,4,4
	dc.b	12,12,12,12,9,9,9,9,7,7,7,4,4,4,4,4
	dc.b	12,12,12,12,9,9,9,9,7,7,7,4,4,4,4,4

	dc.b	10,10,10,8,8,8,8,8,5,5,5,5,5,2,2,2
	dc.b	10,10,10,8,8,8,8,8,5,5,5,5,5,2,2,2
	dc.b	10,10,10,8,8,8,8,8,6,6,6,6,6,2,2,2
	dc.b	10,10,10,8,8,8,8,8,6,6,6,6,6,6,2,2
	dc.b	10,10,10,8,8,8,8,8,6,6,6,6,6,6,2,2
	dc.b	10,10,10,1,1,1,1,1,1,1,1,3,6,6,2,3
	dc.b	11,11,1,1,1,1,1,1,1,1,1,3,6,6,2,3
	dc.b	11,11,11,1,1,1,1,1,1,1,1,3,3,3,2,3
	dc.b	11,11,11,1,1,1,1
	


***************************************************************************
*		Boucle de deplacement si Gagne
***************************************************************************
GameWon	moveq	#'0',d0		Trouve le message "Gagne"
	moveq	#3,d1
	bsr	FindText

	lea	TabName(pc),a0
	moveq	#-1,d0
	move.l	a1,a2

	moveq	#38,d1
GW.Leng	addq.w	#1,d0
	cmp.b	#13,(a2)+
	dbeq	d1,GW.Leng	D0= Longueur du nom du tableau

	moveq	#40,d1
	tst.w	Resol(a4)
	beq.s	GW.LoR
	moveq	#80,d1
GW.LoR	sub.w	d0,d1
	asr.w	#1,d1
	
GW.Spcs	move.b	#' ',(a0)+
	dbra	d1,GW.Spcs

GW.Copy	move.b	(a1)+,d1		Copie du message "Gagne"
	move.b	d1,(a0)+
	cmp.b	#13,d1
	bne.s	GW.Copy
	clr.b	-1(a0)

* Boucle de montee lente avec incrementation du score
	move.w	#99,d7
GW.1	move.w	d7,-(sp)
	bsr	GW.Dessine
	lea	Score+3(pc),a1
	bsr	AddOne
	lea	Score2+3(pc),a1
	bsr	AddOne

	sub.w	#100,CurY(a4)
	addq.w	#4,Beta(a4)
	move.l	Other(a4),a5
	sub.w	#100,CurY(a5)
	subq.w	#4,Beta(a5)

	move.w	(sp)+,d7
	dbra	d7,GW.1

* Suite de la montee jusqu'a l'altitude de -12000
GW.2	bsr	GW.Dessine

	sub.w	#100,CurY(a4)
	addq.w	#4,Beta(a4)
	move.l	Other(a4),a5
	sub.w	#100,CurY(a5)
	subq.w	#4,Beta(a5)
	cmp.w	#-12000,CurY(a4)
	bge.s	GW.2

* Remontee par en dessous
	move.w	#12000,CurY(a4)
GW.2B	bsr	GW.Dessine

	sub.w	#100,CurY(a4)
	addq.w	#4,Beta(a4)
	move.l	Other(a4),a5
	sub.w	#100,CurY(a5)
	subq.w	#4,Beta(a5)
	tst.w	CurY(a4)
	bge.s	GW.2B

* Boucle de choix du tableau
GW.3	bsr	GW.Dessine

GW3.Posit	sub.l	#200,SysTime0(a4)		Acceleration des secondes
	cmp.w	#12000,CurX(a4)		Teste les changement de tableau
	ble.s	GW3.XPOk
	move.w	#-11000,CurX(a4)
	add.w	#16,Tableau(a4)
	and.w	#NTABS-1,Tableau(a4)
	bsr	InitOL

GW3.XPOk	cmp.w	#-12000,CurX(a4)
	bge.s	GW3.XMOk
	move.w	#11000,CurX(a4)
	sub.w	#16,Tableau(a4)
	and.w	#NTABS-1,Tableau(a4)
	bsr	InitOL

GW3.XMOk	cmp.w	#12000,CurZ(a4)
	ble.s	GW3.ZPOk
	move.w	#-11000,CurZ(a4)
	addq.w	#1,Tableau(a4)
	and.w	#NTABS-1,Tableau(a4)
	bsr	InitOL

GW3.ZPOk	cmp.w	#-12000,CurZ(a4)
	bge.s	GW3.ZMOk
	move.w	#11000,CurZ(a4)
	subq.w	#1,Tableau(a4)
	and.w	#NTABS-1,Tableau(a4)
	bsr	InitOL

GW3.ZMOk	cmp.w	#12000,CurY(a4)
	ble.s	GW3.YPOk
	move.w	#-11000,CurY(a4)

GW3.YPOk	cmp.w	#-12000,CurY(a4)
	bge.s	GW3.YMOk
	move.w	#11000,CurY(a4)

GW3.YMOk	lea	JoyStick1(pc),a0
	move.w	InputDev(a4),d0
	btst	#JOY_FIRE,0(a0,d0.w)
	beq.s	GW3.NoFire

	move.w	#8000,d0		Calcule le deplacement du joueur
	move.w	Beta(a4),d1
	sub.w	BetaSpeed(a4),d1
	move.w	d1,-(sp)
	bsr	XSinY
	asr.w	#3,d2
	add.w	d2,CurX(a4)

	move.w	(sp)+,d1
	move.w	#8000,d0
	bsr	XCosY
	asr.w	#3,d2
	add.w	d2,CurZ(a4)

	move.w	#4000,d0
	move.w	Alpha(a4),d1
	bsr	XSinY
	asr.w	#3,d2
	add.w	d2,CurY(a4)

GW3.NoFire:
	btst	#1,Options1(a4)
	beq.s	GW3.1P
	bsr	SwapVars
	tst.w	Joueur(a4)
	bne	GW3.Posit

GW3.1P	move.l	$4BA.w,d0
	cmp.l	SysTime0(a4),d0		Tant qu'il reste du temps
	ble	GW.3

* Recentrage
	movem.w	CurX(a4),d0-d2
	bsr	InCube
	movem.w	d0-d2,CurX(a4)
	move.l	Other(a4),a5
	movem.w	CurX(a5),d0-d2
	bsr	InCube
	movem.w	d0-d2,CurX(a5)

	bsr	GW.Dessine

	move.l	Other(a4),a5
	add.l	#200*3*60,SysTime0(a4)
	add.l	#200*3*60,SysTime0(a5)

	clr.w	WhichDiamond(a4)
	clr.w	WhichDiamond(a5)
	clr.w	JSuisMort(a4)
	clr.w	JSuisMort(a5)

	bra	MainLoop

* Affichage des (eventuellement 2) joueurs sans deplacement
GW.Dessine:
	addq.l	#1,TimerL(a4)
	move.l	Other(a4),a5
	addq.l	#1,TimerL(a5)
	bsr	Cls


* Boucle des 2 joueurs
GWD.Playr	movem.w	CurX(a4),d0-d2		Teste si on est assez loin pour le noir
	tst.w	d0
	bpl.s	GWD.XPos
	neg.w	d0
GWD.XPos	tst.w	d1
	bpl.s	GWD.YPos
	neg.w	d1
GWD.YPos	tst.w	d2
	bpl.s	GWD.ZPos
	neg.w	d2
GWD.ZPos	cmp.w	d1,d0
	bge.s	GWD.XgeY
	move.w	d1,d0
GWD.XgeY	cmp.w	d2,d0
	bge.s	GWD.XgeZ
	move.w	d2,d0
GWD.XgeZ	cmp.w	#8000,d0		Si dans le cube
	ble.s	GWD.NChCol

	move.w	d0,d7
	sub.w	#8000,d7		Changement de couleur en fonction d'un nombre entre 8000 et 16000
	moveq	#9,d0
	lsr.w	d0,d7

	lea	BackColor(a4),a0
	lea	CurColor(a4),a1
	moveq	#15,d6

GWD.ChC1	move.w	(a0),d0
	and.w	#$700,d0
	move.w	d7,d5
GWD.Red	tst.w	d0
	beq.s	GWD.Red0
	sub.w	#$100,d0
	dbra	d5,GWD.Red

GWD.Red0	move.w	(a0),d1
	and.w	#$070,d1
	move.w	d7,d5
GWD.Blu	tst.w	d1
	beq.s	GWD.Blu0
	sub.w	#$010,d1
	dbra	d5,GWD.Blu

GWD.Blu0	move.w	(a0)+,d2
	and.w	#$007,d2
	move.w	d7,d5
GWD.Grn	tst.w	d2
	beq.s	GWD.Grn0
	subq.w	#$001,d2
	dbra	d5,GWD.Grn

GWD.Grn0	or.w	d1,d0
	or.w	d2,d0
	move.w	d0,(a1)+
	dbra	d6,GWD.ChC1
	bra.s	GWD.ChC

GWD.NChCol:
	movem.l	BackColor(a4),d0-d7
	movem.l	d0-d7,CurColor(a4)

GWD.ChC	btst	#1,Options1(a4)
	bne.s	GWD.Col1P
	movem.l	CurColor(a4),d0-d7
	move.l	Other(a4),a5
	movem.l	d0-d7,CurColor(a5)

GWD.Col1P	bsr	TrigInit
	bsr	DessineCube		Trace de l'arene,
	bsr	DessineMonde		Se charge alors de Dessiner l'ombre et le vaisseau

	move.w	CurY(a4),-(sp)
	move.w	#8000,CurY(a4)		Retour vers le centre
	bsr	TstJoyst
	move.w	(sp)+,CurY(a4)

	btst	#1,Options1(a4)		Si 2 joueurs
	beq.s	GWD.1P
	bsr	SwapVars			On passe alternativement l'un et l'autre
	tst.w	Joueur(a4)
	bne	GWD.Playr

GWD.1P	bsr	MkScore
	move.l	Other(a4),a5	Pas initialise  dans SWS.NoCol
	bra	SwS.NoCol		et permutation d'ecran (Sans couleur)



***************************************************************************
*		Boucle de deplacement si perdu
***************************************************************************
TheEnd	move.w	#32,d6
	bsr	ClrKey

	moveq	#100,d7
	bsr	PlayMusic

DnLoop.MkExp:
	lea	OList(a4),a1
	move.w	ObjNum(a4),d7
	cmp.w	#120,d7
	bgt.s	DnLoop.E
	lsl.w	#5,d7
	lea	0(a1,d7.w),a1

	bsr	Random		Insere un nouvel element d'explosion
	and.w	#$F,d0
	add.w	#$220,d0
	move.w	d0,(a1)+		Explosion
	clr.w	(a1)+		Timer
	move.l	CurX(a4),(a1)+	Copie des coordonnees
	move.w	CurZ(a4),(a1)+

	bsr	Random		Ajout de 3 angles Al,Be,Ga
	move.w	d0,(a1)+
	bsr	Random
	move.w	d0,(a1)+
	bsr	Random
	move.w	d0,(a1)+

	addq.l	#6,a1		Pointe sur 3 vitesses
	bsr	Random		Met 3 coordonnees
	and.w	#1023,d0
	sub.w	#512,d0
	move.w	d0,(a1)+
	bsr	Random
	and.w	#1023,d0
	sub.w	#512,d0
	move.w	d0,(a1)+
	bsr	Random
	and.w	#1023,d0
	sub.w	#512,d0
	move.w	d0,(a1)+

	addq.w	#1,ObjNum(a4)
	btst	#1,Options1(a4)
	beq.s	DnLoop.1P
	bsr	SwapVars

DnLoop.1P	dbra	D6,DnLoop.MkExp

	tst	Joueur(a4)
	beq.s	DnLoop.E
	bsr	SwapVars

DnLoop.E	lea	JoyStick1(pc),a1
	clr.l	(a1)
	moveq	#0,d7

DnLoop	move.l	SysTime0(a4),d0
	add.l	#200*10,d0
	cmp.l	$4BA.w,d0
	blt	DnLoop.Fin

DnLoop.KN	moveq	#-1,d7

	move.w	#1,Timer(a4)
	move.w	d7,-(sp)
	move.w	#128,BetaSpeed(a4)	Rotation du mort
	move.l	Other(a4),a5
	move.w	#-128,BetaSpeed(a5)
	bsr.s	DessTout
	move.w	(sp)+,d7
	bra	DnLoop

DnLoop.Fin:
	bra	Finished


UpLoop	subq.w	#1,JSuisMort(a4)
	beq.s	UpLoop2
	rts

UpLoop2	move.l	TabVisitAd(a4),a0
	move.w	Tableau(a4),d0
	and.w	#NTABS-1,d0
	tst.b	0(a0,d0.w)		Teste si on a deja vu le tableau en question
	bne	NouvTab
	move.w	#30,ExtraTime(a4)
	add.l	#200*60,SysTime0(a4)	Si non, on a 3 mn d'exploration en plus
	move.l	Other(a4),a5
	add.l	#200*60,SysTime0(a5)
	bra	NouvTab

****************************************************************************
*		Description du vaisseau et de l'ombre
****************************************************************************

DessTout	addq.l	#1,TimerL(a4)
	bsr	Cls
	move.l	a4,-(sp)		Indique si 1er ou 2e affichage

DessTout2	bsr	TrigInit
	bsr	DessineCube		Trace de l'arene,
	bsr	DessineMonde
	bsr	TstJoyst
	btst	#1,Options1(a4)		Si 2 joueurs
	beq.s	DessT.1P
	bsr	SwapVars			On passe alternativement l'un et l'autre
	cmp.l	(sp),a4
	bne.s	DessTout2

DessT.1P	move.l	(sp)+,a4
	bsr	MkScore

	bra	SwapScrn		et permutation d'ecran


****************************************************************************
*		Description du vaisseau et de l'ombre
****************************************************************************

DessineOmbre:
	move.w	#-1,NumOmb(a4)		Indique 'Ombre tracee'
	tst.w	JSuisMort(a4)
	bmi.s	DV.Ret

	st	UseLocAng(a4)
	move.w	BetaSpeed(a4),d0
	sub.w	Beta(a4),d0
	move.w	d0,BetaL(a4)
	clr.w	GammaL(a4)
	clr.w	AlphaL(a4)

	movem.w	CurX(a4),d0-d2
	move.w	AltiOmb(a4),d1
	movem.w	d0-d2,ObjX(a4)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ			Rotation du centre du cube
	movem.w	d0-d2,ModObjX(a4)		Et stockage

	move.w	VaissNum(a4),d7
	lsl.w	#2,d7
	lea	OmbreDess(pc),a0
	move.l	0(a0,d7.w),d7
	add.l	d7,a0
	bra	AffObj

OmbreDess	dc.l	Ombre1.D-OmbreDess
	dc.l	Ombre2.D-OmbreDess
	dc.l	Ombre3.D-OmbreDess
	dc.l	Ombre4.D-OmbreDess
	dc.l	Ombre5.D-OmbreDess
	dc.l	Ombre6.D-OmbreDess

*
*		Trace du vaisseau
*
DessineVaiss:
	move.w	#-2,NumOmb(a4)	Indique 'Vaisseau trace'

	tst.w	JSuisMort(a4)
	bmi.s	DV.Ret

	btst	#5,Options2(a4)
	beq.s	DV.DoIt
	move.w	#400,PosZ(a4)
DV.Ret	rts

DV.DoIt	move.w	#900,PosZ(a4)

	move.w	BetaSpeed(a4),d0
	sub.w	Beta(a4),d0
	move.w	d0,BetaL(a4)
	clr.w	GammaL(a4)
	st	UseLocAng(a4)
	btst	#4,Options2(a4)
	beq.s	DV.PaPen
	move.w	BetaSpeed(a4),d0
	neg.w	d0
	asr.w	#1,d0
	move.w	d0,GammaL(a4)
DV.PaPen	clr.w	AlphaL(a4)

DV.Demo	clr.l	ModObjX(a4)		Position dans l'espace relatif
	move.w	PosZ(a4),ModObjZ(a4)

	move.w	Contract(a4),d0
	sub.w	#15,d0
	bpl.s	DV.CPos
	moveq	#0,d0
DV.CPos	cmp.w	#150,d0
	ble.s	DV.CNeg
	move.w	#150,d0
DV.CNeg	move.w	d0,Contract(a4)

	move.w	VaissNum(a4),d0
	lsl.w	#2,d0
	jmp	DV.Vaisseaux(pc,d0.w)
DV.Vaisseaux:
	bra	DV.Tetra
	bra	DV.Mickey
	bra	DV.Speedy
	bra	DV.Flieg
	bra	DV.Jomps

* La fusee
DV.Rocket	lea	V5.D(pc),a0		Modification des couleurs
	move.w	Joueur(a4),d0
	add.b	#$F1,d0
	move.b	d0,V5.Top-V5.D(a0)

	move.b	#$F6,V5.Rea-V5.D(a0)
	move.w	InputDev(a4),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	DV5.NoJoy
	move.b	#$F2,V5.Rea-V5.D(a0)
	
DV5.NoJoy	bra	AffObj

DV.Mickey	move.w	Timer(a4),d1		Rotation des boules
	lsl.w	#6,d1
	move.w	#250,d0
	move.w	d1,d7
	bsr	XSinY
	move.w	d2,CPoint1(a4)

	move.w	d7,d1
	move.w	#250,d0
	bsr	XCosY
	move.w	d2,CPoint1+4(a4)

	move.w	Timer(a4),d1
	lsl.w	#2,d1
	add.w	Timer(a4),d1
	move.w	#250,d0
	bsr	XSinY
	move.w	d2,CPoint1+2(a4)

	movem.w	CPoint1(a4),d0-d2
	neg.w	d0
	neg.w	d1
	neg.w	d2
	movem.w	d0-d2,CPoint2(a4)

	movem.w	OldX(a4),d0-d2
	movem.w	CurX(a4),d3-d5
	sub.w	d3,d0
	sub.w	d4,d1
	sub.w	d5,d2
	add.w	d0,d0
	add.w	d1,d1
	add.w	d2,d2
	add.w	d0,CPoint1(a4)
	add.w	d1,CPoint1+2(a4)
	add.w	d2,CPoint1+4(a4)
	add.w	d0,CPoint2(a4)
	add.w	d1,CPoint2+2(a4)
	add.w	d2,CPoint2+4(a4)
	clr.w	UseLocAng(a4)

	lea	V1.D(pc),a0		Modification des couleurs
	move.w	Joueur(a4),d0
	add.b	#$F1,d0
	move.b	d0,V1.Top-V1.D(a0)


	move.b	#$F3,V1.R1-V1.D(a0)
	move.b	#$F3,V1.R2-V1.D(a0)

	move.w	InputDev(a4),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	DV1.NoJoy
	move.b	#$F2,V1.R1-V1.D(a0)
	move.b	#$F2,V1.R2-V1.D(a0)

DV1.NoJoy	bra	AffObj

DV.Jomps:
	move.w	#-50,CPoint1(a4)		Position du point intermediaire
	move.w	Contract(a4),d1
	sub.w	#150,d0
	move.w	d0,CPoint1+2(a4)
	move.w	#200,CPoint1+4(a4)
	clr.w	CPoint2(a4)		Position de la tete
	add.w	d1,d1
	sub.w	#300,d1
	move.w	d1,CPoint2+2(a4)
	clr.w	CPoint2+4(a4)

	lea	V4.D(pc),a0		Modification des couleurs
	move.w	Joueur(a4),d0
	add.b	#$F1,d0
	move.b	d0,V4.Top-V4.D(a0)

	move.b	#$F6,V4.Rea-V4.D(a0)
	move.w	InputDev(a4),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	DV4.NoJoy
	move.b	#$F2,V4.Rea-V4.D(a0)
	
DV4.NoJoy	bra	AffObj

DV.Speedy	lea	V2.D(pc),a0

	move.w	Joueur(a4),d0
	add.b	#$F1,d0
	move.b	d0,V2.Top-V2.D(a0)

	move.b	#$F5,V2.Rea-V2.D(a0)
	move.w	InputDev(a4),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	DV2.NoJoy
	move.b	#$F2,V2.Rea-V2.D(a0)
	
DV2.NoJoy	bra	AffObj

DV.Flieg	lea	V3.D(pc),a0
	move.w	Joueur(a4),d0
	add.b	#$F1,d0
	move.b	d0,V3.Top-V3.D(a0)

	clr.w	CPoint1(a4)
	move.w	#-200,d0
	add.w	Contract(a4),d0
	move.w	d0,CPoint1+2(a4)
	move.w	#-100,CPoint1+4(a4)

	move.b	#$F6,V3.Col1-V3.D(a0)
	move.b	#$F6,V3.Col2-V3.D(a0)
	move.w	InputDev(a4),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	DV3.NoJoy
	move.b	#$F2,V3.Col1-V3.D(a0)
	move.b	#$F2,V3.Col2-V3.D(a0)
DV3.NoJoy	bra	AffObj


* Affichage de la petite pyramide bete
DV.Tetra	lea	V0.D(pc),a0		Modification des couleurs
	move.w	Joueur(a4),d0
	add.b	#$F1,d0
	move.b	d0,V0.Top-V0.D(a0)

	move.b	#$F6,V0.Rea-V0.D(a0)
	move.w	InputDev(a4),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	DV0.NoJoy
	move.b	#$F2,V0.Rea-V0.D(a0)
	
DV0.NoJoy	bra	AffObj


****************************************************************************
*	Description du vaisseau et de l'ombre du deuxieme joueur
****************************************************************************
VaissOther.I:
	move.l	Other(a4),a5
	move.w	Tableau(a4),d0		Teste si les deux dans le meme tableau
	cmp.w	Tableau(a5),d0
	bne 	VOI.NSeen		Sinon, NotSeen
	move.w	JSuisMort(a4),d0
	move.b	d0,-1(a3)
	move.b	d0,-2(a3)

	move.w	VaissNum(a4),d0
	lsl.w	#2,d0
	jsr	VOI.Vaisseaux(pc,d0.w)
	bra	VOI.Commun
VOI.Vaisseaux:
	bra	VOI.Tetra
	bra	VOI.Mickey
	bra	VOI.Speedy
	bra	VOI.Flieg
	bra	VOI.Jomps

VOI.Rocket:
	lea	V5.D(pc),a0		Pointe sur la bonne description
	move.b	#$F2,d0
	sub.w	Joueur(a4),d0
	move.b	d0,V5.Top-V5.D(a0)		Couleur rouge

	move.b	#$F6,V5.Rea-V5.D(a0)
	move.w	InputDev(a5),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	VOI4.NJoy
	move.b	#$F2,V5.Rea-V5.D(a0)
VOI4.NJoy	rts

VOI.Jomps:
	lea	V4.D(pc),a0		Pointe sur la bonne description
	move.b	#$F2,d0
	sub.w	Joueur(a4),d0
	move.b	d0,V4.Top-V4.D(a0)		Couleur rouge

	move.b	#$F6,V4.Rea-V4.D(a0)
	move.w	InputDev(a5),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	VOI5.NJoy
	move.b	#$F2,V4.Rea-V4.D(a0)

VOI5.NJoy	move.w	#-50,CPoint1(a4)		Position du point intermediaire
	move.w	Contract(a4),d0
	move.w	d0,d1
	sub.w	#150,d0
	move.w	d0,CPoint1+2(a4)
	move.w	#200,CPoint1+4(a4)
	clr.w	CPoint2(a4)		Position de la tete
	add.w	d1,d1
	sub.w	#300,d1
	move.w	d1,CPoint2+2(a4)
	clr.w	CPoint2+4(a4)
	rts

VOI.Mickey:
	move.w	Timer(a4),d1		Rotation des boules
	lsl.w	#6,d1
	move.w	#250,d0
	move.w	d1,d7
	bsr	XSinY
	move.w	d2,CPoint1(a4)

	move.w	d7,d1
	move.w	#250,d0
	bsr	XCosY
	move.w	d2,CPoint1+4(a4)

	move.w	Timer(a4),d1
	lsl.w	#2,d1
	add.w	Timer(a4),d1
	move.w	#250,d0
	bsr	XSinY
	move.w	d2,CPoint1+2(a4)

	movem.w	CPoint1(a4),d0-d2
	neg.w	d0
	neg.w	d1
	neg.w	d2
	movem.w	d0-d2,CPoint2(a4)

	movem.w	OldX(a4),d0-d2
	movem.w	CurX(a4),d3-d5
	sub.w	d3,d0
	sub.w	d4,d1
	sub.w	d5,d2
	add.w	d0,d0
	add.w	d1,d1
	add.w	d2,d2
	add.w	d0,CPoint1(a4)
	add.w	d1,CPoint1+2(a4)
	add.w	d2,CPoint1+4(a4)
	add.w	d0,CPoint2(a4)
	add.w	d1,CPoint2+2(a4)
	add.w	d2,CPoint2+4(a4)
	clr.w	UseLocAng(a4)

	move.l	Other(a4),a5
	lea	V1.D(pc),a0		Modification des couleurs
	move.b	#$F2,d0
	sub.w	Joueur(a4),d0
	move.b	d0,V1.Top-V1.D(a0)

	move.b	#$F3,V1.R1-V1.D(a0)
	move.b	#$F3,V1.R2-V1.D(a0)
	move.w	InputDev(a5),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	VOI1.NoJoy
	move.b	#$F2,V1.R1-V1.D(a0)
	move.b	#$F2,V1.R2-V1.D(a0)
	
VOI1.NoJoy
	rts

VOI.Speedy:
	lea	V2.D(pc),a0

	move.b	#$F2,d0
	sub.w	Joueur(a4),d0
	move.b	d0,V2.Top-V2.D(a0)		Couleur rouge

	move.b	#$F5,V2.Rea-V2.D(a0)
	move.l	Other(a4),a5
	move.w	InputDev(a5),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	VOI2.NoJoy
	move.b	#$F2,V2.Rea-V2.D(a0)
	
VOI2.NoJoy:
	rts

VOI.Flieg	lea	V3.D(pc),a0
	move.b	#$F2,d0
	sub.w	Joueur(a4),d0
	move.b	d0,V3.Top-V3.D(a0)

	clr.w	CPoint1(a4)
	move.w	#-200,d0
	add.w	Contract(a5),d0
	move.w	d0,CPoint1+2(a4)
	move.w	#-100,CPoint1+4(a4)

	move.b	#$F6,V3.Col1-V3.D(a0)
	move.b	#$F6,V3.Col2-V3.D(a0)
	move.w	InputDev(a5),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	VO3.NoJoy
	move.b	#$F2,V3.Col1-V3.D(a0)
	move.b	#$F2,V3.Col2-V3.D(a0)
VO3.NoJoy	rts

* Pour la pyramide standard.
VOI.Tetra:
	lea	V0.D(pc),a0		Pointe sur la bonne description
	move.b	#$F2,d0
	sub.w	Joueur(a4),d0
	move.b	d0,V0.Top-V0.D(a0)		Couleur rouge

	move.b	#$F6,V0.Rea-V0.D(a0)
	move.w	InputDev(a5),d0
	lea	Joystick1(pc),a1
	btst	#JOY_FIRE,0(a1,d0.w)	Joystick	
	beq.s	VOI0.NJoy
	move.b	#$F2,V0.Rea-V0.D(a0)

VOI0.NJoy	rts

VOI.Commun:
	move.l	a0,8(sp)			Modifie la forme de l'objet
	move.w	BetaSpeed(a5),d0
	sub.w	Beta(a5),d0
	move.w	d0,BetaL(a4)
	clr.w	AlphaL(a4)
	clr.w	GammaL(a4)
	movem.w	CurX(a5),d0-d2
	movem.w	d0-d2,(a3)
	movem.w	d0-d2,ObjX(a4)

	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bgt.s	VOI.Ret
	movem.w	CurX(a4),d0-d2
	movem.w	CurX(a5),d3-d5
	sub.w	d3,d0
	sub.w	d4,d1
	sub.w	d5,d2
	movem.w	d0-d2,SpeedX(a4)
	neg.w	d0
	neg.w	d1
	neg.w	d2
	movem.w	d0-d2,SpeedX(a5)
	moveq	#ChocVaiss.S,d6
	moveq	#110,d7
	bsr	PlaySound

VOI.Ret	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	st	UseLocAng(a4)
	bsr	TransXYZ		Recalcule les coordonnees modifiees
	movem.w	d0-d2,ModObjX(a4)
	move.w	d2,20(a3)		Stocke la profondeur
	rts

VOI.NSeen	move.w	#$F0F0,-2(a3)	Alors, pas vu
	rts


*
* Trace de l'ombre du deuxieme joueur
*
OmbreOther.I:
	move.w	JSuisMort(a4),d0
	move.b	d0,-1(a3)
	move.b	d0,-2(a3)
	move.l	Other(a4),a5	Si les deux pas dans le meme tableau, pas vus
	move.w	Tableau(a4),d0
	cmp.w	Tableau(a5),d0
	bne.s	VOI.NSeen

	st	UseLocAng(a4)
	move.w	BetaSpeed(a5),d0
	sub.w	Beta(a5),d0
	move.w	d0,BetaL(a4)
	clr.w	AlphaL(a4)
	clr.w	GammaL(a4)
	movem.w	CurX(a5),d0-d2
	move.w	AltiOmb(a5),d1
	movem.w	d0-d2,(a3)
	movem.w	d0-d2,ObjX(a4)

	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ		Recalcule les coordonnees modifiees
	movem.w	d0-d2,ModObjX(a4)
	move.w	d2,20(a3)

	move.w	VaissNum(a4),d7
	lsl.w	#2,d7
	lea	OmbreDess(pc),a0
	move.l	0(a0,d7.w),d7
	add.l	d7,a0
	move.l	a0,8(sp)
	rts


***************************************************************************
*		Dessin des differents types de joueurs
***************************************************************************
Ombre1.D	dc.b	ZP4,ZM5,XM2,XP4,END

	dc.b	1
	dc.b	5,4,2,$F3
	dc.b	0,0

Ombre2.D	dc.b	ZP3
	dc.b	XM2,ZM1
	dc.b	XM1,ZM2
	dc.b	XP1,ZM2
	dc.b	XP2,ZM1
	dc.b	XP2,ZP1
	dc.b	XP1,ZP2
	dc.b	XM1,ZP2
	dc.b	XM2,ZP1
	dc.b	END

	dc.b	1
	dc.b	18,16,14,12,10,8,6,4,2,$F3
	dc.b	0,0

Ombre3.D	dc.b	ZP4,ZM5,XM2,XP4,END
	dc.b	1
	dc.b	2,5,4,$F3
	dc.b	END,END


Ombre4.D	dc.b	XM2,XP4,ORIG,ZM1,ZP5,END
	dc.b	1
	dc.b	2,6,3,5,$F3
	dc.b	END


Ombre5.D	dc.b	ZP3,ZM4,XM2,XP4,END
	dc.b	1,2,5,4,$F3,END,END


Ombre6.D	dc.b	ZP5,ZM4,XM2,ZM1,XP4,ZP1,END
	dc.b	1,2,7,6,5,4,$F3,END,END

* Vaisseau "Tetra": Pyramide simple la tete en bas
V0.D	dc.b	XM2,YM3,ZM1
	dc.b	XP4,XM2,YP2,ZP5,END

	dc.b	1
	dc.b	1,4,5
V0.Rea	dc.b	$F6
	dc.b	1,8,4,$F5
	dc.b	1,5,8,$F4
	dc.b	4,8,5
V0.Top	dc.b	$F1
	dc.b	0,0


* Vaisseau "Mickey"
V1.D	dc.b	YM2,GO1,GO2,END
	dc.b	2
	dc.b	2
V1.Top	dc.b	$F0
	dc.b	22
	dc.b	END
	dc.b	3
	dc.b	3
V1.R1	dc.b	$F0,5
	dc.b	END
	dc.b	4
	dc.b	4
V1.R2	dc.b	$F0,5
	dc.b	END,END

* Vaisseau "Speedy"
V2.D	dc.b	ZP4,ZM5
	dc.b	XM2,XP4
	dc.b	YM2,ZP1,XM1,XM2,END

	dc.b	1
	dc.b	9,8,5,4
V2.Rea	dc.b	$F0
	dc.b	2,4,5,$F3
	dc.b	2,8,9
V2.Top	dc.b	$F0
	dc.b	2,5,8,$F4
	dc.b	2,9,4,$F4

	dc.b	END,END

* Vaisseau "Robby"
V3.D	dc.b	XM2,XP4,GO1
	dc.b	YM1,YP1,ZP5,END
	dc.b	1
	dc.b	4,7,2,$F5
	dc.b	7,4,3,$F6
	dc.b	7,5,2,$F5
	dc.b	5,7,3,$F4
	dc.b	7,5
V3.Top	dc.b	$F0
	dc.b	2,5,4
V3.Col1	dc.b	$F0
	dc.b	3,4,5
V3.Col2	dc.b	$F0
	dc.b	END,END

* Vaisseau "THE LAMP": Le plus beau, le plus rapide, le plus grand...
V4.D	dc.b	XM1,XP2,ORIG,ZP5,ZM4,YM1	Pied
	dc.b	GO1,ZM1,XP1,ZP1		Milieu
	dc.b	GO2,YM1,ZM1,XM2,XP4		Arriere tete
	dc.b	XM2,YM1,ZP2,ZP4,YP2		Avant de la tete
	dc.b	END

	dc.b	1
* Ce qu'on voit depuis le haut (classe)
	dc.b	2,5,7,$F4			Pied (cache par le reste)
	dc.b	3,7,5,$F5
	dc.b	7,3,2
V4.Rea	dc.b	$F0

	dc.b	21,15,12,$F5
	dc.b	12,16,21,$F6

	dc.b	8,9,7,$F4			Colonne (cotes)
	dc.b	12,9,8,$F4
	dc.b	10,11,7,$F4
	dc.b	12,11,10,$F4

	dc.b	7,9,10,$F5		Colonne (avant/arriere)
	dc.b	12,10,9,$F6
	dc.b	11,8,7,$F5
	dc.b	8,11,12,$F6

	dc.b	12,15,16,$F4
	dc.b	21,19,15,$F4		Tete
	dc.b	19,21,16,$F5
	dc.b	19,16,15			Pan arriere
V4.Top	dc.b	$F0
	dc.b	5,2,3,$F3			Dessous

	dc.b	0,0

* Vaisseau "Rocket type"
V5.D	dc.b	XM1,XP2,ORIG
	dc.b	YM2,ZM1,XM2,XP4,ORIG
	dc.b	YM3,YP1,ZP5
	dc.b	END

	dc.b	1
	dc.b	10,8,7
V5.Top	dc.b	0
	dc.b	7,8,3,2
V5.Rea	dc.b	0
	dc.b	12,10,7,$F4
	dc.b	12,8,10,$F4
	dc.b	12,2,3,$F6
	dc.b	12,7,2,$F5
	dc.b	12,3,8,$F5
	dc.b	END,END

***************************************************************************
*		Initialise la liste d'objets pour chaque tableau
***************************************************************************
InitOL	move.w	Tableau(a4),d0	Pointe sur la description de tableau
	btst	#1,Options1(a4)
	beq.s	InitOL.TabDiff

	move.l	Other(a4),a5
	cmp.w	Tableau(a5),d0	Si on arrive dans le tableau occupe par l'autre
	bne.s	InitOL.TabDiff

	move.w	MaxVSpeed(a5),MaxVSpeed(a4)	Sinon, copie les variables
	move.w	Gravite(a5),Gravite(a4)
	movem.l	BackColor(a5),d0-d7		Copie des couleurs
	movem.l	d0-d7,BackColor(a4)

	move.w	ObjNum(a5),d0
	move.w	d0,ObjNum(a4)
	lea	OList(a5),a0
	lea	OList(a4),a1
	subq.w	#1,d0
InitOL.Cpy:
	movem.l	(a0)+,d1-d7/a2
	movem.l	d1-d7/a2,(a1)
	lea	32(a1),a1
	dbra	d0,InitOL.Cpy
	rts


InitOL.TabDiff:
	move.l	Tableaux(a4),a0
	subq.w	#1,d0		Adaptation DBRA
	bmi.s	InitOL.A0		Si tableau 0 : On ne lit pas la liste

InitOL.FT	move.w	2(a0),d1		Nombre d'objets
	muls	#10,d1		*10
	lea	44(a0,d1.w),a0	+4 = Debut du tableau suivant
	dbra	d0,InitOL.FT

InitOL.A0	move.w	36(a0),MaxVSpeed(a4)

	move.w	(a0)+,Gravite(a4)	Acceleration verticale dans le tableau
	move.w	(a0)+,d0

	move.w	d0,ObjNum(a4)
	subq.w	#1,d0
	lea	OList(a4),a1

InitOL.1	movem.l	(a0)+,d1-d7/a2	Ecriture palette
	movem.l	d1-d7/a2,BackColor(a4)

	addq.l	#8,a0

InitOL.2	movem.w	(a0)+,d1-d5
	movem.w	d1-d5,(a1)
	clr.w	10(a1)		Intialisation des timers
	clr.l	12(a1)
	clr.l	22(a1)
	clr.l	26(a1)
	move.w	d0,30(a1)		Initialise le compteur
	lea	32(a1),a1
	dbra	d0,InitOL.2

* Ajout du vaisseau no 2 et de l'ombre
	btst	#1,Options1(a4)
	beq.s	InitOL.1P
	move.w	#$10,(a1)
	move.w	#$30,32(a1)
	addq.w	#2,ObjNum(a4)

InitOL.1P	clr.w	MissilN(a4)	Indique que pas de missile dans le tableau
	clr.w	TrajSize(a4)	Indique pas d'objet suivant une trajectoire
	rts


****************************************************************************
*		Affichage du Timer et du score
****************************************************************************
* Ajout et soustraction de 1 (entree : A1 pointe sur la fin du compteur)
AddOne	move.b	(a1),d0
	cmp.b	#':',d0
	beq.s	AddSub.Ov
	addq.b	#1,d0
	move.b	d0,(a1)
	cmp.b	#'9',d0
	ble.s	AddSub.R
	move.b	#'0',(a1)
	subq.l	#1,a1
	bra.s	AddOne
AddSub.Ov	moveq	#-1,d0
	rts
AddSub.R	moveq	#0,d0
	rts

SubOne	move.b	(a1),d0
	cmp.b	#':',d0
	beq.s	AddSub.Ov
	subq.b	#1,d0
	move.b	d0,(a1)
	cmp.b	#'0',d0
	bge.s	AddSub.R
	move.b	#'9',(a1)
	subq.l	#1,a1
	bra.s	SubOne

MkScore	lea	JoyStick1(pc),a6
	move.w	InputDev(a4),d0
	btst	#JOY_FIRE,0(a6,d0.w)
	beq.s	MkS.1PVS
	move.w	#8000,d0		Vitesse : 0->255
	sub.w	CurY(a4),d0
	asr.w	#8,d0		Ajout 0->15 au score
	asr.w	#1,d0
	bmi.s	MkS.1PVS
	add.w	d0,ToScore(a4)
MkS.1PVS	move.l	Score(pc),d6
	move.w	ToScore(a4),d7
	ble.s	MkS.1PQ
	lea	Score+7(pc),a1
	bsr	AddOne
	subq.w	#1,d7

	cmp.w	#10,d7
	ble.s	MkS.1PQ
	lea	Score+6(pc),a1
	bsr	AddOne
	sub.w	#10,d7

	cmp.w	#100,d7
	ble.s	MkS.1PQ
	lea	Score+5(pc),a1
	bsr	AddOne
	sub.w	#100,d7

MkS.1PQ	move.w	d7,ToScore(a4)
	cmp.l	Score(pc),d6
	beq.s	MkS.1PNET

	add.l	#200*60,SysTime0(a4)
	move.w	#30,ExtraTime(a4)
	move.l	Other(a4),a5
	add.l	#200*60,SysTime0(a5)


MkS.1PNET	btst	#1,Options1(a4)	teste si on joue a 2 joueurs
	beq.s	MkS.2PNET

	move.l	Other(a4),a5
	move.w	InputDev(a5),d0
	btst	#JOY_FIRE,0(a6,d0.w)
	beq.s	MkS.2PVS
	move.w	#8000,d0		Vitesse : 0->255
	sub.w	CurY(a5),d0
	asr.w	#8,d0		Ajout 0->15 au score
	asr.w	#1,d0
	bmi.s	MkS.2PVS
	add.w	d0,ToScore(a5)
MkS.2PVS	move.l	Score2(pc),d6
	move.w	ToScore(a5),d7
	ble.s	MkS.2PQ
	lea	Score2+7(pc),a1
	bsr	AddOne
	subq.w	#1,d7

	cmp.w	#10,d7
	ble.s	MkS.2PQ
	lea	Score2+6(pc),a1
	bsr	AddOne
	sub.w	#10,d7

	cmp.w	#100,d7
	ble.s	MkS.2PQ
	lea	Score2+5(pc),a1
	bsr	AddOne
	sub.w	#100,d7

MkS.2PQ	move.w	d7,ToScore(a5)
	cmp.l	Score2(pc),d6
	beq.s	MkS.2PNET

	add.l	#200*60,SysTime0(a4)
	move.w	#30,ExtraTime(a4)
	add.l	#200*60,SysTime0(a5)

MkS.2PNET	move.l	SysTime0(a4),d6
	sub.l	$4BA,d6
	bpl.s	MkS.TimIn
	move.w	#-40,JSuisMort(a4)
	move.l	Other(a4),a5
	move.w	#-40,JSuisMort(a5)
	moveq	#0,d6
MkS.TimIn	divu	#200,d6		Timer 200 Hz
	moveq	#0,d0
	move.w	d6,d0		S'assure que mot (<65536 s, soit 18h et quelques)
	lea	Remains+2(pc),a0
	divu	#3600,d0		Obtention du nombre d'heures
	swap	d0
	move.w	d0,d7		Sauve le reste (nombre de minutes)
	clr.w	d0
	swap	d0		S'assure que le mot haut est nul
	moveq	#1,d1
	bsr	N2S.Loop

	moveq	#0,d0
	move.w	d7,d0		Traitement des minutes
	divu	#60,d0
	swap	d0
	move.w	d0,d7
	clr.w	d0
	swap	d0
	lea	Remains+5(pc),a0
	moveq	#1,d1
	bsr	N2S.Loop

	moveq	#0,d0
	move.w	d7,d0
	moveq	#1,d1
	lea	Remains+8(pc),a0
	bsr	N2S.Loop

PrScore	tst.w	InputDev(a4)
	bmi	AfficheInstructions
	btst	#0,Options1(a4)
	bne	PrSc.Emotion

	tst.w	Resol(a4)
	bne	PrSc.Hi

	tst.w	ExtraTime(a4)
	beq.s	PrS.NExT
	subq.w	#1,ExtraTime(a4)
	lea	ExtraTxt(pc),a0
	move.l	LogScreen(a4),a1
	lea	96*160+40(a1),a1
	bsr	FastPrt

PrS.NexT	lea	Remains(pc),a0	Affichage du temps
	move.l	LogScreen(a4),a1
	lea	160+160-40(a1),a1
	bsr.s	FastPrt

	lea	ScoreT(pc),a0	Affichage du score
	move.l	LogScreen(a4),a1
	lea	160+8(a1),a1
	bsr.s	FastPrt

	move.l	LogScreen(a4),a1
	lea	160*191(a1),a1
	lea	TabName(pc),a0
	btst	#1,Options1(a4)
	beq.s	FastPrt

	addq.l	#8,a1
	lea	ScoreT2(pc),a0	Affiche score no2

FastPrt	moveq	#0,d0
	move.b	(a0)+,d0
	beq	AddSub.R
	cmp.b	#32,d0
	beq.s	FastPrt.N

	lsl.w	#3,d0
	lea	CharSet(pc,d0.w),a2

	moveq	#7,d7
FastPrt.L	move.b	(a2)+,d0
	not.w	d0
	and.b	d0,(a1)
	and.b	d0,2(a1)
	and.b	d0,4(a1)
	and.b	d0,6(a1)
	lea	160(a1),a1
	dbra	d7,FastPrt.L
	lea	-160*8(a1),a1
FastPrt.N	move.w	a1,d0
	and.w	#7,d0
	beq.s	FastPrt.2
	addq.l	#7,a1
	bra.s	FastPrt
FastPrt.2	addq.l	#1,a1
	bra.s	FastPrt

CharSet	INCBIN	\PROJET.CUB\CUBE.CHR

PrSc.Hi	tst.w	ExtraTime(a4)
	beq.s	PrSH.NExT
	subq.w	#1,ExtraTime(a4)
	lea	ExtraTxt(pc),a0
	move.l	LogScreen(a4),a1
	lea	96*160+30(a1),a1
	bsr	HiFPrt

PrSH.NexT	lea	Remains(pc),a0	Affichage du temps
	move.l	LogScreen(a4),a1
	lea	160+70(a1),a1
	bsr.s	HiFPrt

	lea	ScoreT(pc),a0	Affichage du score
	move.l	LogScreen(a4),a1
	lea	160+2(a1),a1
	bsr.s	HiFPrt

	move.l	LogScreen(a4),a1
	lea	160*191(a1),a1
	lea	TabName(pc),a0

	btst	#1,Options1(a4)
	beq.s	HiFPrt
	addq.l	#2,a1
	lea	ScoreT2(pc),a0

HiFPrt	moveq	#0,d0
	move.b	(a0)+,d0
	beq	AddSub.R
	cmp.b	#32,d0
	beq.s	HiFPrt.N

	lsl.w	#3,d0
	lea	CharSet(pc),a2
	lea	0(a2,d0.w),a2

	moveq	#7,d7
HiFPrt.L	move.b	(a2)+,d0
	not.b	d0
	and.b	d0,(a1)
	and.b	d0,80(a1)
	lea	160(a1),a1
	dbra	d7,HiFPrt.L
	lea	1-160*8(a1),a1
	bra.s	HiFPrt
HiFPrt.N	addq.l	#1,a1
	bra.s	HiFPrt

PrSc.Emotion:
	bsr	ConstantTime
	move.l	LogScreen(a4),a1
	lea	160*191(a1),a1
	lea	TabName(pc),a0
	bra	FastPrt


ExtraTxt	dc.b	'Extra Time 1 minute'
	even
	dc.b	0,0
ScoreT	dc.b	'Score 1:'
Score	dc.b	'00000000',0,0
ScoreT2	dc.b	'Score 2:'
Score2	dc.b	'00000000',0,0
Remains	dc.b	'00:00:00',0,0
TabName	ds.b	82

****************************************************************************
*		Lecture des touches et deplacement
****************************************************************************
* Deplacement proprement dit

* Premiere partie : La recherche des objets sur lesquels on rebondit
* eventuellement...
Deplace	movem.w	SpeedX(a4),d0-d2
	movem.w	CurX(a4),d3-d5
	movem.w	d3-d5,OldX(a4)
	add.w	d0,d3		Calcul des deplacements
	add.w	d1,d4
	add.w	d2,d5

	move.w	Gravite(a4),d7
	asr.w	#1,d7
	add.w	d7,d1		Acceleration verticale
	add.w	SpeedX0(a4),d0	Calcul de la moyenne entre vitesse th. et reelle
	add.w	SpeedZ0(a4),d2

	moveq	#0,d7		Indique pas de heurt de mur

	asr.w	#1,d0		Force le passage a 0 si necessaire (<0)
	bpl.s	Dep.dxp
	addq.w	#1,d0
Dep.dxp	asr.w	#1,d2
	bpl.s	Dep.dyp
	addq.w	#1,d2

Dep.dyp	cmp.w	#8000,d3		Rebond sur les bords du cube
	blt.s	Dep.XPOk
	moveq	#-1,d7		Indique que l'on a heurte un mur
	move.w	#8000,d3
	asr.w	#1,d0
	bmi.s	Dep.XPOk
	neg.w	d0

Dep.XPOk	cmp.w	#-8000,d3
	bgt.s	Dep.XNOk
	moveq	#-1,d7
	move.w	#-8000,d3
	asr.w	#1,d0
	bpl.s	Dep.XNOk
	neg.w	d0

Dep.XNOk	cmp.w	#-8000,d4
	bgt.s	Dep.YNOk
	moveq	#-1,d7
	move.w	#-7900,d4
	asr.w	#1,d1
	bpl.s	Dep.YNOk
	neg.w	d1

Dep.YNOk	cmp.w	#8000,d5		Rebond en Z
	blt.s	Dep.ZPOk
	moveq	#-1,d7
	move.w	#8000,d5
	asr.w	#1,d2
	bmi.s	Dep.ZPOk
	neg.w	d2

Dep.ZPOk	cmp.w	#-8000,d5
	bgt.s	Dep.ZNOk
	moveq	#-1,d7
	move.w	#-8000,d5
	asr.w	#1,d2
	bpl.s	Dep.ZNOk
	neg.w	d2

Dep.ZNOk	tst.w	d7
	beq.s	Dep.PasToucheMur
	movem.w	d0-d5,-(sp)	Si on a touche un mur, joue un spl
	moveq	#SurMurs.S,d6
	moveq	#100,d7
	bsr	PlaySound
	movem.w	(sp)+,d0-d5

Dep.PasToucheMur:
	cmp.w	#8000,d4		Rebond en Y
	blt.s	Dep.YPOk
	movem.w	d0-d5,-(sp)
	asr.w	#1,d1
	cmp.w	Gravite(a4),d1
	blt.s	Dep.YNoS
	asr.w	#1,d1
	neg.w	d1
	add.w	#170,d1
	cmp.w	#150,d1
	blt.s	Dep.SOk
	move.w	#150,d1

* Ici une routine de traitement du son a faire en cas de rebond
Dep.SOk	move.w	#150,d2
	sub.w	d1,d2
	move.w	d2,Contract(a4)
	moveq	#ParTerre.S,d6
	move.b	d1,d7
	bsr	PlaySound
	bra.s	Dep.YDoS

Dep.YNoS	clr.w	2(sp)
Dep.YDoS	movem.w	(sp)+,d0-d5
	move.w	#8000,d4
	asr.w	#1,d1
	bmi.s	Dep.YPOk
	neg.w	d1

Dep.YPOk	movem.w	d0-d2,SpeedX(a4)	Stockage des nouvelles vitesses et deplacement
	movem.w	d3-d5,CurX(a4)

TstJoyst	lea	Joystick1(pc),a0
	move.w	InputDev(a4),d1
	bpl.s	Dep.Plyr		Teste si en mode jeu automatique
	move.l	MovePtr(a4),a1	Si oui, rejoue la sequence enregistree
Dep.VNum1	move.b	(a1)+,d0
	move.w	d0,d7
	and.w	#64,d7
	beq.s	Dep.VNum2
	and.w	#$F,d0		Si on a change de vaisseau en cours de route
	move.w	d0,VaissNum(a4)
	bra.s	Dep.VNum1
Dep.VNum2	move.b	d0,0(a0,d1.w)
	move.l	a1,MovePtr(a4)
	cmp.l	EndMvMem(a4),a1	Teste si on a atteint la fin de l'enregistrement
	ble.s	Dep.Demo
	addq.l	#4,sp		Oui : Retour court-circuite
	bra	MainGame

Dep.Plyr	move.b	0(a0,d1.w),d0	Lecture d'une donnee sur Joy
	move.w	d0,d1
* Teste les retours au centre automatique
	btst	#3,Options2(a4)	Teste si retour au bas auto
	bne.s	Dep.NoRB		Sinon pas de retour au bas
	and.w	#3,d1		Isole les bits HB
	bne.s	Dep.NoRB		Si on touche au Joy

	move.w	#$20,d1		Direction choisie
	cmp.w	#8000,CurY(a4)
	beq.s	Dep.Bot
	move.w	#$80,d1
Dep.Bot	cmp.w	Alpha(a4),d1	Comparaison avec la position
	beq.s	Dep.NoRB
	blt.s	Dep.ADn
	bset	#0,d0
	bra.s	Dep.NoRB
Dep.ADn	bset	#1,d0

Dep.NoRB	btst	#2,Options2(a4)	Teste si retour au centre auto
	bne.s	Dep.NoCe
	move.w	d0,d1
	and.w	#$C,d1		Isole les bits GB
	bne.s	Dep.NoCe		Si on touche au Joy

	tst.w	BetaSpeed(a4)		Comparaison avec la position
	beq.s	Dep.NoCe
	blt.s	Dep.AGa
	bset	#3,d0
	bra.s	Dep.NoCe
Dep.AGa	bset	#2,d0

Dep.NoCe:
	IFNE	DEMO_REC
	btst	#1,Options1(a4)	Si 2 joueurs, n'enregistre pas
	bne.s	Dep.Demo

	move.l	EndMvMem(a4),a0	Enregistrement du deplacement du joueur
	move.l	a0,d1
	sub.l	MoveMemAd(a4),d1
	cmp.w	#TScreen-MoveMemry,d1
	bgt.s	Dep.Demo
	move.b	d0,(a0)+
	move.l	a0,EndMvMem(a4)
	ENDC	DEMO_REC

Dep.Demo	lea	VaissSpeeds(pc),a5
	move.w	VaissNum(a4),d1
	lsl.w	#3,d1
	lea	0(a5,d1.w),a5
	movem.w	(a5),d1-d4	d1=DepSpd, d2=RotSpd, d3=LimGD, d4=LimHB
	move.w	d2,d5
	subq.w	#1,d5
	not.w	d5

	move.w	Alpha(a4),d6
	and.w	d5,d6

JOY_UP	equ	0
JOY_DN	equ	1
JOY_LF	equ	2
JOY_RT	equ	3
JOY_FIRE	equ	7

	btst	#JOY_UP,d0	Test des 4 directions, avec depassement de
	beq.s	Dep.NoUp		capacite fixe a $90 (50 degres)
	add.w	d2,d6
	cmp.w	d6,d4
	bge.s	Dep.NoUp
	move.w	d4,d6

Dep.NoUp	btst	#JOY_DN,d0
	beq.s	Dep.NoDn
	sub.w	d2,d6
	neg.w	d4
	cmp.w	d6,d4
	ble.s	Dep.NoDn
	move.w	d4,d6

Dep.NoDn	move.w	d6,Alpha(a4)

	move.w	BetaSpeed(a4),d6
	and.w	d5,d6

	btst	#JOY_LF,d0
	beq.s	Dep.NoRt
	add.w	d2,d6
	cmp.w	d6,d3
	bge.s	Dep.NoRt
	move.w	d3,d6

Dep.NoRt	neg.w	d3
	btst	#JOY_RT,d0
	beq.s	Dep.NoDi
	sub.w	d2,d6
	cmp.w	d6,d3
	ble.s	Dep.NoDi
	move.w	d3,d6

* Teste les options de deplacement
Dep.NoDi	move.w	d6,BetaSpeed(a4)

	clr.w	Gamma(a4)
	btst	#4,Options2(a4)
	bne.s	Dep.Gamma
	move.w	BetaSpeed(a4),Gamma(a4)

Dep.Gamma	move.w	BetaSpeed(a4),d1
	asr.w	#3,d1
	sub.w	d1,Beta(a4)

	btst	#JOY_FIRE,d0		Reacteur en marche ?
	beq.s	Dep.NoBut

	move.w	VaissNum(a4),d0
	lsl.w	#3,d0
	lea	VaissSpeeds(pc),a0
	move.w	0(a0,d0.w),d0
	move.w	d0,-(sp)
	move.w	Beta(a4),d1
	sub.w	BetaSpeed(a4),d1
	move.w	d1,-(sp)
	bsr	XSinY
	asr.w	#3,d2
	move.w	d2,SpeedX0(a4)	Fixe la vitesse ideale

	move.w	(sp)+,d1
	move.w	(sp)+,d0
	bsr	XCosY
	asr.w	#3,d2
	move.w	d2,SpeedZ0(a4)

	rts

Dep.NoBut	clr.w	SpeedX0(a4)
	clr.w	SpeedZ0(a4)
	rts

VaissSpeeds:
	dc.w	1000,4,128,128	Tetra
	dc.w	1400,16,224,256	Mickey
	dc.w	3500,2,56,56	Speedy
	dc.w	1800,8,168,128	Flieg
	dc.w	2000,8,208,208	Jomps
	dc.w	2200,8,112,112	Fiisii


***************************************************************************
*	Verifie que les coordonnees dans D0-2 sont dans le cube
***************************************************************************
InCube	cmp.w	#7800,d0
	ble.s	InCube.1
	move.w	#7800,d0
InCube.1	cmp.w	#-7800,d0
	bge.s	InCube.2
	move.w	#-7800,d0
InCube.2	cmp.w	#7500,d1
	ble.s	InCube.3
	move.w	#7600,d1
InCube.3	cmp.w	#-7800,d1
	bge.s	InCube.4
	move.w	#-7800,d1
InCube.4	cmp.w	#7800,d2
	ble.s	InCube.5
	move.w	#7800,d2
InCube.5	cmp.w	#-7800,d2
	bge.s	InCube.6
	move.w	#-7800,d2
InCube.6	rts

***************************************************************************
*	Verifie que les coordonnees dans D0-2 sont dans le cube, Sinon 0
***************************************************************************
InCube2	cmp.w	#7800,d0
	ble.s	InCube2.1
	move.w	#6000,d0
InCube2.1	cmp.w	#-7800,d0
	bge.s	InCube2.2
	move.w	#-6000,d0
InCube2.2	cmp.w	#7500,d1
	ble.s	InCube2.3
	move.w	#6000,d1
InCube2.3	cmp.w	#-7800,d1
	bge.s	InCube2.4
	move.w	#-6000,d1
InCube2.4	cmp.w	#7800,d2
	ble.s	InCube2.5
	move.w	#6000,d2
InCube2.5	cmp.w	#-7800,d2
	bge.s	InCube2.6
	move.w	#-6000,d2
InCube2.6	rts

***************************************************************************
*		Fonction donnant un resultat "aleatoire" dans d0
***************************************************************************
Random	move.w	Seed(a4),d0
	muls	#997,d0
	addq.w	#1,d0
	move.w	d0,Seed(a4)
	rts

***************************************************************************
*		Recherche de l'azimut visant une cible
***************************************************************************
* Methode utilisee :
*  TriRotation du vecteur (0,-128,0) (vertical) -> D0-D1-D2
*  L'equation du plan d'azimut est alors
*  D0*(X-X0)+D1*(Y-Y0)+D2*(Z-Z0)=0
* Selon le signe de l'expression, on est au dessus ou en dessous de l'azimut
*
* Entree : Comme pour les .I, avec 6(a3) pointant sur Alpha et Beta
*	 d0-d2 indiquent le point a viser
* Sortie : A0 et A3 preserves
*	 D0 = 0,+1,-1 a ajouter a Alpha

AzimPolar	movem.l	d0-d2/a0/a3,-(sp)
	moveq	#0,d0
	moveq	#-128,d1
	moveq	#0,d2
	movem.w	6(a3),d5-d6
	moveq	#0,d7
	movem.w	d5-d7,AlphaL(a4)	Fixe les angles locaux en fonction des angles actuels
	bsr	TriRotateL	Triple rotation

	movem.l	(sp)+,d5-d7/a0/a3	Recupere les coordonnees du point a viser
	sub.w	(a3),d5		Calcule le vecteur difference
	sub.w	2(a3),d6
	sub.w	4(a3),d7
	muls	d5,d0
	muls	d6,d1
	muls	d7,d2
	add.l	d0,d1
	add.l	d2,d1
SignD1	moveq	#0,d0
	tst.l	d1
	beq.s	AP.Nul
	bmi.s	AP.Neg
	moveq	#1,d0
AP.Nul	rts
AP.Neg	moveq	#-1,d0
	rts
	
***************************************************************************
*		Recherche du cap visant une cible
***************************************************************************
* Methode utilisee :
*  Rotation dans le plan OXZ du vecteur (0,1000) (droit devant) selon le Cap (Beta)
*  Produit vectoriel avec le vecteur differences
*  Le signe de la composante Y indique la direction a choisir
* Entree : D0-D2 indiquent le point a viser
*          A0-A3 fixes comme pour .I, avec 6(a3)=Alpha, 8(a3)=Beta
* Sortie : A0 et A3 preserves
*	 D0 contient 0,+1 ou -1, valeur a ajouter a Beta
*
CapPolar	moveq	#0,d5
	moveq	#100,d6
	move.w	8(a3),d7
	movem.l	d0-d2/a0/a3,-(sp)
	bsr	Rotate		Rotation selon l'angle voulu
	movem.l	(sp)+,d5-d7/a0/a3
	sub.w	(a3),d5		Calcul de DX et DZ
	sub.w	4(a3),d7
	muls	d5,d1		Produits croises
	muls	d7,d0
	sub.l	d0,d1
	neg.l	d1
	bra.s	SignD1		Et recherche du signe


***************************************************************************
*	Recherche d'intersection de cubes :
*	Determine si au prochain tour on sera dans X+DX,X-DX...
***************************************************************************
* Entree :
*  D0-D2 : Coordonnees de l'objet
*  A1 : Pointeur sur une table OFFX-, OFFX+,OFFY-, OFFY+, OFFZ-, OFFZ+
* Sortie :
*  D7 a les bits a 0 dans l'ordre 0 : X-,... 5 : Z+
*  Le mot haut a les memes bits avant deplacement
* Un EOR entre la partie haute et la partie basse permet donc de savoir
* Quelles parois ont ete traversees
Touching	moveq	#-1,d7
	movem.w	CurX(a4),d3-d5
	bsr.s	TC.0
	swap	d7
	add.w	SpeedX(a4),d3
	add.w	SpeedY(a4),d4
	add.w	SpeedZ(a4),d5

TC.0	move.w	(a1)+,d6
	add.w	d0,d6
	cmp.w	d3,d6
	bgt.s	TC.1
	and.w	#~1,d7
TC.1	move.w	(a1)+,d6
	add.w	d0,d6
	cmp.w	d3,d6
	blt.s	TC.2
	and.w	#~2,d7
TC.2	move.w	(a1)+,d6
	add.w	d1,d6
	cmp.w	d4,d6
	bgt.s	TC.3
	and.w	#~4,d7
TC.3	move.w	(a1)+,d6
	add.w	d1,d6
	cmp.w	d4,d6
	blt.s	TC.4
	and.w	#~8,d7
TC.4	move.w	(a1)+,d6
	add.w	d2,d6
	cmp.w	d5,d6
	bgt.s	TC.5
	and.w	#~16,d7
TC.5	move.w	(a1)+,d6
	add.w	d2,d6
	cmp.w	d5,d6
	blt.s	TC.6
	and.w	#~32,d7
TC.6	lea	-12(a1),a1
	rts	
	

***************************************************************************
*		Gestion de l'altitude de l'ombre
* Entree : A1 pointe sur une table volumique
***************************************************************************
GereOmbre	bsr	Touching		Calcul des intersections
	move.w	d7,d6
	and.w	#%110011,d6	Isole les composantes X/Z
	bne.s	GO.Ret
	move.w	CurY(a4),d6
	cmp.w	d6,d1		Il ne faut pas que je sois plus bas que la dalle
	blt.s	GO.Ret
	move.w	NxAOmb(a4),d6
	cmp.w	d6,d1		Il ne faut pas que l'ancienne altitude soit plus haute que moi
	bgt.s	GO.Ret
	move.w	d1,NxAOmb(a4)
	move.w	26(a3),NxNOmb(a4)	Indique le numero d'objet
	moveq	#0,d6
	rts
GO.Ret	moveq	#-1,d6
	rts



***************************************************************************
*		Instructions pour chaque objet
***************************************************************************
* En entree, A3 pointe sur les coordonnees (qui sont aussi dans D0-D2)
* Offsets/a3:
* -4: Numero de l'objet
* -2: Compteur d'affichage
*  0: X,Y,Z
*  6: Alpha,Beta
* 10: Divers
* 12: Coordonnees modifiees
* 20: Divers...
* 26: Numero de l'objet (pour identification)
* A0 pointe sur la description de l'objet

* KeyWord #I
ObjPrgs	rts

* Objet qui se dirige selon une trajectoire fixe (Traject)
* L'objet commence sa trajectoire en se dirigeant vers Traject[0]
* et suit tous les elements jusqu'a TrajSize. Alors, retour
* a Traject[0]
PoseTraj.I:
	move.w	-4(a3),d7		Lit la couleur (determine la position)
	and.w	#$F,d7
	move.w	d7,d6
	add.w	d7,d7
	add.w	d6,d7
	add.w	d7,d7		Passe au mot
	lea	Traject(a4),a0
	movem.w	d0-d2,0(a0,d7.w)	Et stocke la position de l'objet dans la traj.
	addq.w	#1,TrajSize(a4)	Un point de trajectoire de plus
	bra	ObjClr		

* Entree de Traject.I:
* Vitesse : D6 (translation), D7 (rotation)
* 10(a3) contient le numero de l'element de trajectoire a suivre
* 20(a3) contient le precedent decalage X
* 22(a3) contient le precedent decalage Y
Traject.I	move.w	d6,-(sp)		Vitesse de translation

	move.w	d7,-(sp)
	move.w	10(a3),d7
	move.w	d7,d6
	add.w	d7,d7
	add.w	d6,d7
	add.w	d7,d7
	lea	Traject(a4),a5
	movem.w	0(a5,d7.w),d0-d2

	movem.w	d0-d2,-(sp)
	bsr	CapPolar		Teste du Cap
	move.w	d0,d5
	movem.w	(sp)+,d0-d2

	move.w	(sp),d7
	move.w	20(a3),d6		Lecture decalage actuel+Signe prec
	move.w	d5,d4
	eor.w	d6,d4		Si dans des directions opposees
	bpl.s	Traject.1
	moveq	#0,d6		Pas de decalage
Traject.1	addq.b	#1,d6		Augmentation du decalage precedent
	cmp.b	d7,d6		Si plus grand que le decalage limite
	ble.s	Traject.2
	move.w	d7,d6		Limite le decalage
Traject.2	move.w	d6,20(a3)		Stocke le decalage actuel
	lsl.w	d6,d5		Effectue le decalage
	smi	20(a3)		Stocke le signe du resultat
	add.w	d5,8(a3)		Modification du cap

	bsr	AzimPolar
	move.w	d0,d5
	move.w	(sp)+,d7
	move.w	22(a3),d6
	move.w	d5,d4
	eor.w	d6,d4		Si dans des directions opposees
	bpl.s	Traject.3
	moveq	#0,d6		Pas de decalage
Traject.3	addq.b	#1,d6		Augmentation du decalage precedent
	cmp.b	d7,d6		Si plus grand que le decalage limite
	ble.s	Traject.4
	move.w	d7,d6		Limite le decalage
Traject.4	move.w	d6,22(a3)		Stocke le decalage actuel
	lsl.w	d6,d0
	smi	22(a3)
	add.w	d0,6(a3)		Modification de l'azimut
	st	UseLocAng(a4)	Indique l'utilisation d'angle locaux

	moveq	#0,d0
	moveq	#0,d1
	move.w	(sp)+,d2
	move.l	a3,-(sp)
	bsr	TriRotateL
	move.l	(sp)+,a3
	movem.w	(a3),d3-d5
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	movem.w	d0-d2,(a3)

	move.w	10(a3),d7
	move.w	d7,d6
	add.w	d7,d7
	add.w	d6,d7
	add.w	d7,d7
	lea	Traject(a4),a5
	movem.w	0(a5,d7.w),d3-d5
	bsr	Distance		Teste si on a atteint l'element vise
	cmp.w	#1000,d0
	bge.s	Traject.R
	move.w	10(a3),d0		Si oui, on passe au suivant
	addq.w	#1,d0
	cmp.w	TrajSize(a4),d0
	blt.s	Traject.S
	moveq	#0,d0
Traject.S	move.w	d0,10(a3)

Traject.R	rts

* Objet Traject qui, si il est touche, provoque un son et decale
* D3: Couleur du bord
* D4: Distance avant contact
* D5: Numero du son en cas de rebond
* D6: Vitesse lineaire
* D7: Vitesse de rotation
Speeder.I	move.w	#$FF0,d3
	move.w	#1200,d4
	moveq	#Chasseur.S,d5
	move.w	#250,d6
	moveq	#4,d7
	bra.s	TrajTch.I

BigOne.I	move.w	#$F53,d3
	move.w	#2500,d4
	moveq	#BigOne.S,d5
	moveq	#50,d6
	moveq	#2,d7
	bra.s	TrajTch.I

StarWar.I	move.w	#$F3F,d3
	move.w	#1200,d4
	moveq	#Chasseur.S,d5
	moveq	#127,d6
	moveq	#4,d7
	bra.s	TrajTch.I

Explor.I	move.w	#$03F,d3
	move.w	#2000,d4
	moveq	#Explor.S,d5
	move.w	#500,d6
	moveq	#6,d7

TrajTch.I	movem.w	d3-d7,-(sp)
	bsr	Traject.I

	movem.w	(a3),d0-d2
	movem.w	CurX(a4),d3-d5
	bsr	Distance
	movem.w	(sp)+,d3-d7
	cmp.w	d4,d0
	bge.s	Explor.R

	move.w	d5,-(sp)
	move.w	d3,CurColor(a4)	Si on est touche par le vaisseau
	movem.w	(a3),d0-d2
	movem.w	CurX(a4),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
	add.w	d3,SpeedX(a4)
	add.w	d4,SpeedY(a4)
	add.w	d5,SpeedZ(a4)
	move.w	(sp)+,d6
	moveq	#100,d7
	bsr	PlaySound
Explor.R	rts


* Horrible alien qui vient vers vous en zigzagant
* 20(a3) contient la vitesse de l'alien
Alien.I	movem.w	CurX(a4),d3-d5
	bsr	Distance
	move.w	d0,d7
	movem.w	(a3),d0-d2
	cmp.w	#500,d7
	ble	Collis.Co
	bsr	TesteMissile		Teste si touche par un missile
	tst.w	d7
	bpl.s	Alien.Contact

	moveq	#Missile.S,d6	Si l'objet est touche par un missile
	moveq	#127,d7		On fait un son de missile
	bsr	PlaySound
	add.w	#3000,ToScore(a4)
	moveq	#2,d7
Alien.1	bsr	Random		Position aleatoire
	and.w	#16383,d0
	add.w	#8192,d0
	move.w	d0,(a3)+
	dbra	d7,Alien.1
	subq.l	#6,a3
	bra	ObjClr

Alien.Contact:
	movem.w	(a3),d0-d2
	movem.w	CurX(a4),d3-d5	Effectue le calcul du deplacement
	sub.w	d0,d3
	smi	d0
	sub.w	d1,d4
	smi	d1
	sub.w	d2,d5		Calcule le vecteur deplacement
	smi	d2
	ext.w	d0		Passe d0-d2 en longueur mot.
	ext.w	d1
	ext.w	d2
	lsl.w	#4,d0		(-1 ou 0) *2+1 = signe de X, Y, Z
	lsl.w	#4,d1
	lsl.w	#4,d2
	addq.w	#8,d0
	addq.w	#8,d1
	addq.w	#8,d2
	movem.w	20(a3),d3-d5	Recupere les vitesses
	add.w	d0,d3		Calcule la nouvelle vitesse
	add.w	d1,d4
	add.w	d2,d5
	movem.w	d3-d5,20(a3)	Stocke les nouvelles vitesses
	movem.w	(a3),d0-d2
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	bsr	InCube
	movem.w	d0-d2,(a3)

	move.w	8(a3),d0		Effectue une rotation locale de l'objet
	move.w	d0,BetaL(a4)
	add.w	#21,d0
	move.w	d0,8(a3)
	clr.w	AlphaL(a4)	Pas d'angles en Gamma et Alpha
	clr.w	GammaL(a4)
	st	UseLocAng(a4)

	rts
	
* Cube qui protege un endroit
Protect.I	move.w	-4(a3),d7
	move.w	WhichProtect(a4),d6
	and.w	#$F,d7
	btst	d7,d6
	bne.s	Protect.No
	
	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#3000,d0
	bge.s	Protect.0

	movem.w	(a3),d0-d2
	movem.w	CurX(a4),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
	asr	#2,d3
	asr	#2,d4
	asr	#2,d5
	movem.w	d3-d5,SpeedX(a4)
	move.w	#$F53,CurColor(a4)

	moveq	#Protect.S,d6
	moveq	#100,d7
	bsr	PlaySound

Protect.0	movem.w	6(a3),d0-d2
	addq.w	#1,d0
	addq.w	#2,d1
	addq.w	#3,d2
	movem.w	d0-d2,6(a3)
	movem.w	d0-d2,AlphaL(a4)
	st	UseLocAng(a4)

	rts

* Si le protecteur en question est debranche
Protect.No
	move.w	#$F0F0,-2(a3)
	rts

ProtKey.I	move.w	-4(a3),d7
	move.w	WhichProtect(a4),d6
	and.w	#$F,d7
	bset	d7,d6
	bne.s	Protect.No
	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bge.s	Protect.0

	move.w	d6,WhichProtect(a4)
	move.l	Other(a4),a5
	move.w	d6,WhichProtect(a5)		Assure la coherence entre les 2 joueurs
	moveq	#ProtKey.S,d6
	moveq	#100,d7
	bsr	PlaySound

	bra.s	Protect.0


* Dalles allongees
LongX2.I	move.w	#1500,d7
	lea	LongX2.V(pc),a1
	bra.s	LongX.X
LongX3.I	lea	LongX3.V(pc),a1
	move.w	#2500,d7
	bra.s	LongX.X
LongX4.I	lea	LongX4.V(pc),a1
	move.w	#3500,d7
	bra.s	LongX.X
LongX5.I	lea	LongX5.V(pc),a1
	move.w	#4500,d7
LongX.X	move.w	d7,CPoint1(a4)
	clr.w	CPoint1+2(a4)
	move.w	#500,CPoint1+4(a4)
	moveq	#Plaque.S,d6
	bra	Plaque2.X

LongY2.I	move.w	#1500,d7
	lea	LongY2.V(pc),a1
	bra.s	LongY.X
LongY3.I	lea	LongY3.V(pc),a1
	move.w	#2500,d7
	bra.s	LongY.X
LongY4.I	lea	LongY4.V(pc),a1
	move.w	#3500,d7
	bra.s	LongY.X
LongY5.I	lea	LongY5.V(pc),a1
	move.w	#4500,d7
LongY.X	move.w	#500,CPoint1(a4)
	clr.w	CPoint1+2(a4)
	move.w	d7,CPoint1+4(a4)
	moveq	#Plaque.S,d6
	bra	Plaque2.X


LongX2.V	dc.w	-500,1500,-20,200,-500,500
LongX3.V	dc.w	-500,2500,-20,200,-500,500
LongX4.V	dc.w	-500,3500,-20,200,-500,500
LongX5.V	dc.w	-500,4500,-20,200,-500,500
LongY2.V	dc.w	-500,500,-20,200,-500,1500
LongY3.V	dc.w	-500,500,-20,200,-500,2500
LongY4.V	dc.w	-500,500,-20,200,-500,3500
LongY5.V	dc.w	-500,500,-20,200,-500,4500


* Dalle tombant depuis sa position initiale
* A chaque rebond, elle descend de 200 points
* jusqu'a 7000
* Si l'utilisateur est en dessous de 7500,
* elle remonte alors toute seule jusqu'a l'altitude initiale
* 6(a3)= Altitude initiale
* 8(a3)= Drapeau: 1=Tombant, -1= Remontant
Falling.I	tst.w	8(a3)
	beq.s	Falling.Init	Initialisation
	bmi.s	Falling.Back
	cmp.w	#7500,CurY(a4)	Si la plaque doit remonter
	bge.s	Falling.SetBack

	moveq	#Falling.S,d6
	bsr	Plaque.X		Teste si plaque touchee
	tst.w	d7
	beq.s	Falling.R

	cmp.w	#7000,2(a3)
	bge.s	Falling.R
	add.w	#600,2(a3)

Falling.R	rts

Falling.SetBack:
	move.w	#-1,8(a3)
Falling.Back:
	cmp.w	6(a3),d1		Teste si on est arrive
	ble.s	Falling.Init	On recommence a descendre
	sub.w	#200,2(a3)	Sinon on remonte
	moveq	#Falling.S,d6
	bra	Plaque.X

Falling.Init
	move.w	#1,8(a3)		Prete a tomber
	move.w	2(a3),6(a3)	Stocke l'altitude initiale
	moveq	#Falling.S,d6
	bra	Plaque.X

* Dalle clignotante
* 10(a3) contient le nombre de fois ou l'on a rebondit dessus
Clign.I	tst.b	-2(a3)		Si pas affichee, abs
	bmi.s	Clign.Abs
	cmp.w	#4,10(a3)	Si affichee depuis longtps
	bge.s	Clign.Eff
	moveq	#Clign.S,d6
	bsr	Plaque.X		Sinon normale
	sub.w	d7,10(a3)		Si rebond, inc compteur de rebond
	bra.s	Clign.Abs

Clign.Eff	move.b	#-50,-2(a3)
	clr.w	10(a3)		Remet a zero le compteur de rebond

Clign.Abs	rts

* Rayon attrappant
* Ne doit pas etre place en (0,0,0)
Catcher.I	movem.w	(a3),d0-d5	Difference de position
	tst.w	d3		Si pas premier appel
	bne.s	Catcher.A
	tst.w	d4
	bne.s	Catcher.A
	tst.w	d5
	bne.s	Catcher.A

	movem.w	d0-d2,6(a3)	Premier appel: Permute la pointe et la position
	movem.w	d3-d5,(a3)
	movem.w	(a3),d0-d5

Catcher.A	movem.w	(a3),d0-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
	asr.w	#3,d3		1/8e du vecteur
	asr.w	#3,d4
	asr.w	#3,d5

	moveq	#6,d7
	lea	CPoint1(a4),a0	Initialisation des CPOINTs
	move.w	d3,d0		Reference au centre de l'objet
	move.w	d4,d1
	move.w	d5,d2
Catcher.1	movem.w	d0-d2,(a0)
	move.w	d0,-(sp)
	bsr	Random		Petit decalage aleatoire
	and.w	#255,d0
	sub.w	#128,d0
	add.w	d0,(a0)+
	bsr	Random
	and.w	#255,d0
	sub.w	#128,d0
	add.w	d0,(a0)+
	bsr	Random
	and.w	#255,d0
	sub.w	#128,d0
	add.w	d0,(a0)+
	move.w	(sp)+,d0
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	dbra	d7,Catcher.1
	movem.w	d0-d2,(a0)	Le dernier point en position

	movem.w	d3-d5,-(sp)	Stocke le deplacement

	movem.w	(a3),d0-d2	Deplacement de la pointe
	movem.w	CurX(a4),d3-d5
	sub.w	d0,d3		Vecteur Visee-CurX
	sub.w	d1,d4
	sub.w	d2,d5
	asr.w	#3,d3		V/8
	asr.w	#3,d4
	asr.w	#3,d5

	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	movem.w	d0-d2,(a3)

	movem.w	CurX(a4),d3-d5	Distance pointe-observ.
	bsr	Distance
	cmp.w	#500,d0
	bge.s	Catcher.R

	movem.w	(a3),d0-d5
	bsr	Distance
	move.w	-4(a3),d1		Couleur du catcher
	and.w	#15,d1
	lsl.w	#8,d1
	lsl.w	#3,d1		Multiplication par 2048: 2048-32000
	cmp.w	d1,d0
	bge.s	Catcher.R

	movem.w	(sp),d3-d5	Recupere deplacement
	asr.w	#5,d3
	asr.w	#5,d4
	asr.w	#5,d5
	add.w	d3,SpeedX(a4)
	add.w	d4,SpeedY(a4)
	add.w	d5,SpeedZ(a4)
	moveq	#Catcher.S,d6
	moveq	#100,d7
	bsr	PlaySound

Catcher.R	addq.l	#6,sp
	rts


* Plaque automatique (qui suit un deplacement donne)

Auto1.I	moveq	#15,d6
	bra.s	AutoPlq.I
Auto2.I	moveq	#30,d6
	bra.s	AutoPlq.I
Auto3.I	moveq	#45,d6
	bra.s	AutoPlq.I
Auto4.I	moveq	#60,d6
	bra.s	AutoPlq.I
Auto5.I	moveq	#75,d6
	bra.s	AutoPlq.I
Auto6.I	moveq	#90,d6
	bra.s	AutoPlq.I
Auto7.I	move.w	#105,d6
	bra.s	AutoPlq.I
Auto8.I	move.w	#120,d6
	bra.s	AutoPlq.I
Auto9.I	move.w	#135,d6
	bra.s	AutoPlq.I
Auto10.I	move.w	#150,d6
AutoPlq.I	moveq	#4,d7
	bsr	Traject.I
	moveq	#Auto.S,d6
	movem.w	(a3),d0-d2
	clr.w	AlphaL(a4)
	bra	Plaque.X
	
* Plaque qui n'apparait que si a une distance suffisament faible
* de l'observateur (Pour labyrinthe)
LabP.I	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#4000,d0
	ble.s	LabP.Seen
	move.w	Joueur(a4),d1
	move.b	#-5,-2(a3,d1.w)
LabP.Seen	movem.w	(a3),d0-d2
	moveq	#Void.S,d6	Pas de son
	bra	Plaque.X


* Plaque qui teleporte 2000 plus haut
PTeleV.I	moveq	#Transpor.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PTeleV.NT
	sub.w	#2000,CurY(a4)
PTeleV.NT	rts

* Bulles vides
BulleV.I	bchg	#1,Options2(a4)	Passe en filaire
	bsr.s	BulleP.I
	bchg	#1,Options2(a4)
Bulle.R	rts
* Bulles pleines
* Ici, on Dessine un cercle directement sur l'ecran, sans changement
* de coordonnees de points
BulleP.I	tst.w	6(a3)		Teste l'indicateur d'efficacite
	bpl.s	BulleP.D

	move.w	Joueur(a4),d0	Si on a touche la bulle :
	move.b	#-10,-2(a3,d0.w)	elle est invisible

	cmp.w	#-300,6(a3)
	blt.s	Bulle.R
	bne.s	Bulle.N
	add.w	#10,Gravite(a4)	Si on a fini le temps
	sub.w	#$123,BackColor(a4)

Bulle.N	subq.w	#1,6(a3)
	bra.s	Bulle.R
	
BulleP.D	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bgt.s	BulleP.T

	moveq	#Bulle.S,d6
	moveq	#100,d7
	bsr	PlaySound

	move.w	#-1,6(a3)
	sub.w	#10,Gravite(a4)	Cas ou l'on touche la bulle
	add.w	#$123,BackColor(a4)
	add.w	#1500,ToScore(a4)
	bra.s	Bulle.R

BulleP.T	moveq	#7,d7		Calcul du petit reflet
	move.w	#128,d6
	lea	PolySomm(a4),a1
	move.w	#50,d0
	move.w	#80,d1
	bsr	DoCircle

	moveq	#7,d7		Transformation de coordonnees
	lea	PolySomm(a4),a0
	lea	CPoint1(a4),a1
Bulle.1	movem.w	(a0)+,d0-d1	Calcule les CPoints 1-8
	move.w	d0,(a1)+
	sub.w	#180,d1
	move.w	d1,(a1)+
	add.w	#360,d1
	neg.w	d1
	move.w	d1,(a1)+
	dbra	d7,Bulle.1

	move.w	Joueur(a4),d0	Teste si un affichage est demande
	tst.b	-2(a3,d0.w)
	bmi	Bulle.R

	bsr	Random		Modification des diametres X et Y
	and.w	#63,d0
	add.w	#300,d0
	move.w	d0,-(sp)
	bsr	Random
	and.w	#63,d0
	add.w	#300,d0
	move.w	(sp)+,d1

	moveq	#31,d7		Pour 32 points
	moveq	#32,d6		Multiplier par 32
	lea	PolySomm(a4),a1
	bsr	DoCircle

	tst.w	20-4(a3)		Teste si on peut afficher la bulle
	bmi	Bulle.R

	moveq	#31,d7		Calcul de perspective
	lea	PolySomm(a4),a0
Bulle.2	movem.w	(a0),d0-d1
	movem.w	16-4(a3),d3-d5	Recupere les coordonnees du centre
	move.w	d5,d2
	add.w	d3,d0
	add.w	d4,d1
	bsr	Perspect
	move.w	d0,(a0)+
	move.w	d1,(a0)+
	dbra	d7,Bulle.2

	move.w	-4(a3),d0		Calcul de la couleur
	and.w	#$F,d0
	move.w	d0,Couleur(a4)
	moveq	#32,d3
	lea	PolySomm(a4),a0
	move.l	a0,-(sp)

	bra	FacFill.NonOr


* Explosion finale du vaisseau
Explode.I	movem.w	18(a3),d3-d5
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	movem.w	d0-d2,(a3)
	asr.w	#1,d3
	asr.w	#1,d4
	asr.w	#1,d5
	movem.w	d3-d5,18(a3)
	movem.w	6(a3),d0-d2
	addq.w	#8,d0
	sub.w	#34,d1
	add.w	#69,d2
	movem.w	d0-d2,6(a3)
	movem.w	d0-d2,AlphaL(a4)
	st	UseLocAng(a4)
	rts

Oizo.I	move.l	a0,-(sp)
	move.l	a3,-(sp)
	move.w	Timer(a4),d1
	lsl.w	#6,d1
	move.w	#200,d0
	bsr	XSinY
	sub.w	#400,d2
	move.w	d2,CPoint1+2(a4)
	move.w	d2,CPoint2+2(a4)
	move.w	#600,CPoint1(a4)
	move.w	#-600,CPoint2(a4)
	move.w	#-200,CPoint1+4(a4)
	move.w	#-200,CPoint2+4(a4)

	move.l	(sp)+,a3
	move.l	(sp)+,a0
OizoMove.I:
	movem.w	18(a3),d0-d2
	or.w	d1,d0
	or.w	d2,d0
	beq.s	Oizo.ReDir
	bsr	Random
	and.w	#255,d0
	bne.s	Oizo.Nrm

Oizo.ReDir:
	moveq	#DirOizo.S,d6
	moveq	#100,d7
	bsr	PlaySound

	bsr	Random
	and	#16383,d0
	sub.w	#8192,d0
	move.w	d0,18(a3)
	bsr	Random
	and	#8191,d0
	move.w	d0,20(a3)
	bsr	Random
	and.w	#16383,d0
	sub.w	#8192,d0
	move.w	d0,22(a3)

Oizo.Nrm	movem.w	18(a3),d0-d2
	bsr	CapPolar
	lsl.w	#2,d0
	add.w	d0,8(a3)		Modification du cap
	movem.w	18(a3),d0-d2
	bsr	AzimPolar
	lsl.w	#2,d0
	move.w	6(a3),d1		Recupere l'ancien azimuth
	add.w	d0,d1		Modification de l'azimuth

	cmp.w	#100,d1		Verifie que l'oiseau ne se penche pas trop
	ble.s	Oizo.Az1
	moveq	#100,d1
Oizo.Az1	cmp.w	#-100,d1
	bge.s	Oizo.SAz
	moveq	#-100,d1

Oizo.SAz	move.w	d1,6(a3)		Stocke l'azimuth
	st	UseLocAng(a4)	Indique l'utilisation d'angle locaux

	moveq	#0,d0
	moveq	#0,d1
	moveq	#100,d2
	move.l	a3,-(sp)
	bsr	TriRotateL
	move.l	(sp)+,a3
	movem.w	(a3),d3-d5
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	bsr	InCube
	movem.w	d0-d2,(a3)

	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#800,d0
	bge.s	Oizo.NoReb

	move.w	#$F3F,CurColor(a4)	Si on est touche par l'oiseau
	movem.w	(a3),d0-d2
	movem.w	CurX(a4),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
*	asr.w	#2,d3
*	asr.w	#2,d4
*	asr.w	#2,d5
	add.w	d3,SpeedX(a4)
	add.w	d4,SpeedY(a4)
	add.w	d5,SpeedZ(a4)
	moveq	#ChocOizo.S,d6
	moveq	#100,d7
	bsr	PlaySound
	add.w	#1000,ToScore(a4)

Oizo.NoReb:
	rts

* Bonus de temps (ajoute environ une minute)
Bonus.I	move.l	WhichBonus(a4),d6	Teste si Bonus deja utilise
	move.w	-4(a3),d7
	bset	d7,d6
	bne.s	Bonus.R

	tst.w	6(a3)
	bpl.s	Bonus.M

Bonus.T	cmp.w	#-60,6(a3)
	beq.s	Bonus.S
	subq.w	#1,6(a3)
	add.l	#200,SysTime0(a4)	Ajoute un 10e de seconde par image
Bonus.R	move.w	#$F0F0,-2(a3)
Bonus.R2	rts
Bonus.S	move.l	d6,WhichBonus(a4)
	move.l	Other(a4),a5
	move.l	d6,WhichBonus(a5)
	rts

Bonus.M	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bge.s	Bonus.R2
	add.w	#1000,ToScore(a4)
	moveq	#TimeBonus.S,d6
	moveq	#100,d7
	bsr	PlaySound
	bra.s	Bonus.T



* Diamant (Il faut trouver les 16 pour gagner)
Diamond.I	move.w	WhichDiamond(a4),d6	Teste si Bonus deja utilise
	move.w	-4(a3),d7
	and.w	#$F,d7
	bset	d7,d6
	beq.s	Diamond.M

	move.w	#$F0F0,-2(a3)
Diamond.R	rts
Diamond.M	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bge.s	Diamond.R

	move.w	d6,WhichDiamond(a4)
	move.l	Other(a4),a5
	move.w	d6,WhichDiamond(a5)

	add.w	#10000,ToScore(a4)
	moveq	#Diamond.S,d6
	moveq	#100,d7
	bsr	PlaySound

	move.w	ObjNum(a4),d7
	lsl.w	#5,d7
	lea	OList(a4),a1
	add.w	d7,a1
	movem.w	(a3),d0-d2
	move.w	#DiamP.N,d6
	moveq	#5,d7

Diamond.1	move.w	d6,(a1)+
	add.w	#16,d6
	move.w	#0,(a1)+
	movem.w	d0-d2,(a1)
	add.w	#28,a1
	dbra	d7,Diamond.1

	addq.w	#6,ObjNum(a4)

	rts


* Les pointes du diamant
DiamPN.I	cmp.w	#8000,4(a3)
	bge.s	DiamPN.R
	addq.w	#3,4(a3)
	rts
DiamPN.R	move.w	#$F0F0,-2(a3)
	rts
DiamPS.I	cmp.w	#-8000,4(a3)
	ble.s	DiamPS.R
	subq.w	#3,4(a3)
	rts
DiamPS.R	move.w	#$F0F0,-2(a3)
	rts
DiamPE.I	cmp.w	#8000,(a3)
	bge.s	DiamPE.R
	addq.w	#3,(a3)
	rts
DiamPE.R	move.w	#$F0F0,-2(a3)
	rts
DiamPW.I	cmp.w	#-8000,(a3)
	ble.s	DiamPW.R
	subq.w	#3,(a3)
	rts
DiamPW.R	move.w	#$F0F0,-2(a3)
	rts
DiamPH.I	cmp.w	#-8000,2(a3)
	ble.s	DiamPH.R
	subq.w	#3,2(a3)
	rts
DiamPH.R	move.w	#$F0F0,-2(a3)
	rts
DiamPB.I	cmp.w	#8000,2(a3)
	bge.s	DiamPB.R
	addq.w	#3,2(a3)
	rts
DiamPB.R	move.w	#$F0F0,-2(a3)
	rts

* Les differentes sorties
Sortie2.I	moveq	#16,d6
	move.w	#-256,d0
	lea	Sortie2.V(pc),a1
	bra.s	Porte.I
Sortie3.I	moveq	#-1,d6
	move.w	#512,d0
	lea	Sortie3.V(pc),a1
	bra.s	Porte.I
Sortie4.I	moveq	#-16,d6
	move.w	#256,d0
	lea	Sortie4.V(pc),a1
	bra.s	Porte.I
Sortie1.I	moveq	#1,d6
	moveq	#0,d0
	lea	Sortie1.V(pc),a1

Porte.I	clr.l	CPoint1+2(a4)
	clr.l	CPoint2+2(a4)
	move.w	#250,CPoint1(a4)	Initialisation des CPoints
	move.w	#250,CPoint2(a4)

	move.w	d0,BetaL(a4)
	clr.w	AlphaL(a4)
	clr.w	GammaL(a4)
	st	UseLocAng(a4)

	tst.w	JSuisMort(a4)
	bne.s	Porte.O
	move.w	d6,-(sp)
	movem.w	(a3),d0-d2
	moveq	#Sortie.S,d6
	bsr	Plaque2.X
	move.w	(sp)+,d6

	tst.w	d7
	beq.s	Porte.R

	btst	#0,Options1(a4)
	beq.s	Porte.ModeJeu

	lea	MapList(pc),a5	Teste que l'on reste bien dans
	move.w	Tableau(a4),d1	la meme zone
	and.w	#NTABS-1,d1
	move.w	d1,d2
	add.w	d6,d2
	and.w	#NTABS-1,d2
	move.b	0(a5,d1.w),d1
	move.b	0(a5,d2.w),d2
	cmp.b	d1,d2
	bne.s	Porte.R		Couleurs differentes: On ne change pas de salle

Porte.ModeJeu:	
	move.w	#30,JSuisMort(a4)
	move.w	-4(a3),Sortie(a4)	Indique quelle sortie est la bonne
	add.w	d6,Tableau(a4)
	clr.l	SpeedX(a4)
	clr.w	SpeedZ(a4)

Porte.R	rts

Porte.O	move.w	JSuisMort(a4),d4	Porte ouverte si positif
	bmi.s	Porte.R

	move.w	-4(a3),d0
	cmp.w	Sortie(a4),d0
	bne.s	Porte.R
	move.w	2(a3),NxAOmb(a4)	Met l'altitude de l'ombre a la bonne valeur
	move.w	26(a3),NxNOmb(a4)

	lsl.w	#3,d4
	move.w	#500,d0
	sub.w	d4,d0
	move.w	d0,CPoint1(a4)
	move.w	d4,CPoint2(a4)

	move.w	#250,d0
	moveq	#-10,d1
	move.w	#500,d2
	lsl.w	#2,d4
	sub.w	d4,d2

	move.l	a3,-(sp)
	bsr	TriRotateL
	move.l	(sp)+,a3
	add.w	(a3),d0
	add.w	2(a3),d1
	add.w	4(a3),d2

	movem.w	CurX(a4),d3-d5
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	asr.w	#1,d3
	asr.w	#1,d4
	asr.w	#1,d5
	movem.w	d3-d5,CurX(a4)

	movem.w	Alpha(a4),d3-d5
	asr.w	#3,d3
	asr.w	#3,d5
	sub.w	d3,Alpha(a4)
	cmp.w	#7,Alpha(a4)
	bhi.s	Porte.1
	clr.w	Alpha(a4)
Porte.1	sub.w	d5,Gamma(a4)
	cmp.w	#7,Gamma(a4)
	bhi.s	Porte.2
	clr.w	Gamma(a4)

Porte.2	add.w	BetaL(a4),d4
	add.w	#512,d4
	and.w	#1023,d4
	sub.w	#512,d4
	asr.w	#2,d4
	neg.w	d4
	add.w	Beta(a4),d4
	bpl.s	Porte.3
	addq.w	#1,d4
Porte.3	move.w	d4,Beta(a4)
	clr.w	BetaSpeed(a4)
	rts

Sortie1.V	dc.w	0,500,-20,20,-500,200
Sortie2.V	dc.w	-500,200,-20,20,-500,0
Sortie3.V	dc.w	-500,0,-20,20,-200,500
Sortie4.V	dc.w	-200,500,-20,20,0,500

TransN.I	add.w	#100,4(a3)		Deplacement
	cmp.w	#7500,4(a3)	On est au mur
	blt.s	TransN.1
	add.w	#32,-4(a3)		Oui: Passe en TransS
TransN.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a4)
	rts
TransE.I	add.w	#100,(a3)		Deplacement
	cmp.w	#7500,(a3)	On est au mur
	blt.s	TransE.1
	add.w	#32,-4(a3)		Oui: Passe en TransS
TransE.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a4)
	rts
TransS.I	sub.w	#100,4(a3)		Deplacement
	cmp.w	#-7500,4(a3)	On est au mur
	bgt.s	TransS.1
	sub.w	#32,-4(a3)		Oui: Passe en TransS
TransS.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a4)
	rts
TransW.I	sub.w	#100,(a3)		Deplacement
	cmp.w	#-7500,(a3)	On est au mur
	bgt.s	TransW.1
	sub.w	#32,-4(a3)		Oui: Passe en TransS
TransW.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a4)
	rts

Rotate.V	dc.w	-500,500,-20,20,-500,500
RotateG.I	lea	Rotate.V(pc),a1
	moveq	#Rotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateG.R
	add.w	#99,ToScore(a4)
	add.w	#96,BetaSpeed(a4)
RotateG.R	st	UseLocAng(a4)
	move.w	Timer(a4),d0
	lsl.w	#3,d0
	move.w	d0,BetaL(a4)
	clr.w	AlphaL(a4)
	clr.w	GammaL(a4)
	rts

RotateD.I	lea	Rotate.V(pc),a1
	moveq	#Rotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateD.R
	add.w	#99,ToScore(a4)
	sub.w	#96,BetaSpeed(a4)
RotateD.R	st	UseLocAng(a4)
	move.w	Timer(a4),d0
	lsl.w	#3,d0
	neg.w	d0
	move.w	d0,BetaL(a4)
	clr.w	AlphaL(a4)
	clr.w	GammaL(a4)
	rts

RotAG.I	lea	Rotate.V(pc),a1
	moveq	#Rotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateG.R
	add.w	#49,ToScore(a4)
	add.w	#64,BetaSpeed(a4)
	add.w	#$10,-4(a3)
	bra.s	RotateG.R

RotaD.I	lea	Rotate.V(pc),a1
	moveq	#Rotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateD.R
	add.w	#49,ToScore(a4)
	sub.w	#64,BetaSpeed(a4)
	sub.w	#$10,-4(a3)
	bra.s	RotateD.R



PlaqueN.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueN.R
	add.w	#77,ToScore(a4)
	add.w	#300,SpeedZ(a4)
PlaqueN.R	st	UseLocAng(a4)
	move.w	#-$40,AlphaL(a4)
	clr.w	BetaL(a4)
	clr.w	GammaL(a4)
	rts

PlaqueE.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueE.R
	add.w	#77,ToScore(a4)
	add.w	#300,SpeedX(a4)
PlaqueE.R	st	UseLocAng(a4)
	move.w	#-$40,AlphaL(a4)
	move.w	#-$100,BetaL(a4)
	clr.w	GammaL(a4)
	rts

PlaqueS.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueS.R
	add.w	#77,ToScore(a4)
	sub.w	#300,SpeedZ(a4)
PlaqueS.R	st	UseLocAng(a4)
	move.w	#-$40,AlphaL(a4)
	move.w	#$200,BetaL(a4)
	clr.w	GammaL(a4)
	rts

PlaqueW.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueW.R
	add.w	#77,ToScore(a4)
	sub.w	#300,SpeedX(a4)
PlaqueW.R	st	UseLocAng(a4)
	move.w	#-$40,AlphaL(a4)
	move.w	#$100,BetaL(a4)
	clr.w	GammaL(a4)
	rts

SmlPlaq.I	lea	SmlPlaq.V(pc),a1
	moveq	#Petite.S,d6
	bsr	Plaque2.X
	and.w	#66,d7
	add.w	d7,ToScore(a4)
	rts

Teleport.I:
	moveq	#7,d7		8 points
	lea	CPoint1(a4),a1
Teleport.1:
	move.w	Timer(a4),d1
	lsl.w	#2,d1
	add.w	d7,d1
	lsl.w	#6,d1
	move.w	d1,d6
	move.w	#500,d0
	bsr	XCosY
	move.w	d2,(a1)+

	bsr	Random
	and.w	#511,d0
	sub.w	#512,d0
	move.w	d0,(a1)+

	move.w	d6,d1
	move.w	#500,d0
	bsr	XSinY
	move.w	d2,(a1)+

	dbra	d7,Teleport.1

	moveq	#Teleport.S,d6
	movem.w	(a3),d0-d3
	tst.w	d3
	bpl.s	Teleport.Inact
	lea	Plaque.V(pc),a1
	bsr	Touching

	move.w	d7,d6
	and.w	#%110011,d7	Teste si on est dehors X et Z
	bne.s	Teleport.R
	and.w	#%001100,d6	Teste si on est dedans
	beq.s	Teleport.In
	swap	d7
	eor	d6,d7
	and.w	#%001100,d7	Teste si on traverse en Y
	beq.s	Teleport.R

Teleport.In:
	movem.w	(a3),d0-d2
	sub.w	d0,CurX(a4)	Decalage par rapport a la position
	sub.w	d1,CurY(a4)
	sub.w	d2,CurZ(a4)
	lea	OList(a4),a0
	move.w	ObjNum(a4),d0
	lsl.w	#5,d0
	lea	0(a0,d0.w),a1	A0= Debut de OList, A1=Fin
	subq.l	#4,a3
	move.w	(a3),d0

Teleport.2:
	lea	32(a3),a3		Boucle de recherche de l'autre tele
	cmp.l	a1,a3
	bne.s	Teleport.No
	move.l	a0,a3
Teleport.No:
	cmp.w	(a3),d0
	bne.s	Teleport.2
	movem.w	4(a3),d0-d2
	add.w	d0,CurX(a4)
	add.w	d1,CurY(a4)
	add.w	d2,CurZ(a4)
	move.w	#10,10(a3)	Indique que ne teleporte plus

	moveq	#Teleport.S,d6
	moveq	#100,d7
	bsr	PlaySound
Teleport.R:
	rts
Teleport.Inact:
	subq.w	#1,6(a3)		Inactif pendant un certain temps
	rts


* Rebond sur une plaque.
* Peut etre appele de l'exterieur par Plaque.X
* en fixant le bruit dans D6
* et (pour Plaque2.X) a1 pointant sur l'encombrement
Plaque.I	moveq	#Plaque.S,d6
Plaque.X	lea	Plaque.V(pc),a1	Encombrement de la plaque
Plaque2.X	move.w	d6,-(sp)		Stocke le numero du son
	bsr	GereOmbre

	move.w	d7,d6
	and.w	#%110011,d7	Teste si on est dehors X et Z
	bne.s	Plaque.IR
	and.w	#%001100,d6	Teste si on est dedans
	beq.s	Plaque.IJ
	swap	d7
	eor	d6,d7
	and.w	#%001100,d7	Teste si on traverse en Y
	beq.s	Plaque.IR

Plaque.IJ	move.w	SpeedY(a4),d0
	neg.w	d0
	sub.w	Gravite(a4),d0
	cmp.w	MaxVSpeed(a4),d0
	bgt.s	Plaque.I0
	move.w	MaxVSpeed(a4),d0
Plaque.I0	move.w	d0,SpeedY(a4)

	asr.w	#2,d0
	sub.w	d0,Contract(a4)
	move.w	(sp)+,d6
	moveq	#127,d7
	tst.w	Joueur(a4)
	beq.s	Plaque.S1
	moveq	#100,d7
Plaque.S1	move.w	AltiOmb(a4),d0
	asr	#8,d0
	add.w	d0,d7
	bsr	PlaySound
	moveq	#-1,d7		D7 indique que l'on a touche quelquechose
	rts
Plaque.IR	moveq	#0,d7		Cas ou l'on retourne dehors
	addq.l	#2,sp		Recupere D6
	rts

Plaque.V	dc.w	-500,500,-20,200,-500,500
SmlPlaq.V	dc.w	0,500,-20,20,0,500


MurNS.V	dc.w	-100,100,-1100,100,-100,1100
MurEW.V	dc.w	-100,1100,-1100,100,-100,100

MurNS.I	lea	MurNS.V(pc),a1
	bra.s	Collis.I
MurEW.I	lea	MurEW.V(pc),a1
	bra.s	Collis.I

Cube1000.I:
	lea	Cube1000.V(pc),a1
	bra.s	Collis.I
Cube500.I	lea	Cube500.V(pc),a1
	bra.s	Collis.I
Cube400.I	lea	Cube400.V(pc),a1
	bra.s	Collis.I
Cube300.I	lea	Cube300.V(pc),a1
	bra.s	Collis.I
Cube200.I	lea	Cube200.V(pc),a1
	bra.s	Collis.I
Cube100.I	lea	Cube100.V(pc),a1
Collis.I	bsr	GereOmbre		L'ombre se place au dessus
	tst.w	d6
	bne.s	Collis.NO
	move.w	4(a1),d6
	add.w	d6,NxAOmb(a4)

Collis.NO	and.w	#%111111,d7
	bne.s	Collis.R
Collis.Co	movem.w	CurX(a4),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
	asr	#2,d3
	asr	#2,d4
	asr	#2,d5
	movem.w	d3-d5,SpeedX(a4)
	move.w	#$F34,CurColor(a4)

	moveq	#Pyram.S,d6
	moveq	#100,d7
	bsr	PlaySound

Collis.R	rts

Cube1000.V:
	dc.w	-100,1100,-1100,100,-100,1100
Cube500.V	dc.w	-100,600,-600,100,-100,600
Cube400.V	dc.w	-100,500,-500,100,-100,500
Cube300.V	dc.w	-100,400,-400,100,-100,400
Cube200.V	dc.w	-100,300,-300,100,-100,300
Cube100.V	dc.w	-100,200,-200,100,-100,200

* Objet rebondissant sur les murs
Rebond.I	st	UseLocAng(a4)
	movem.w	(a3),d0-d5
	add.w	Gravite(a4),d4
	add.w	d3,d0		Ajout de la vitesse
	add.w	d4,d1
	add.w	d5,d2

	move.w	d0,d7
	bsr	Random		Calcule un nombre aleatoire pour les vitesses
	and.w	#2047,d0
	move.w	d0,d6		Stocke une vitesse en d6
	sub.w	#1024,d6		d6= vitesse signee

	bsr	Random
	and.w	#1023,d0
	sub.w	#511,d0
	exg.l	d0,d7		Recupere l'ancien X

	cmp.w	#8000,d0		Rebond sur les bords du cube
	ble.s	Reb.XPOk
	move.w	#7900,d0
	neg.w	d3
	move.w	d6,d4		Stocke une vitesse de rebond aleatoire
	move.w	d7,d5

Reb.XPOk	cmp.w	#-8000,d0
	bge.s	Reb.XNOk
	move.w	#-7900,d0
	neg.w	d3
	move.w	d6,d4
	move.w	d7,d5

Reb.XNOk	cmp.w	#8000,d1		Rebond vertical
	ble.s	Reb.YPOk
	move.w	#7900,d1
	neg.w	d4
	move.w	d6,d3		Stocke une vitesse horizontale aleatoire
	move.w	d7,d5

Reb.YPOk	cmp.w	#-8000,d1
	bge.s	Reb.YNOk
	move.w	#-7900,d1
	neg.w	d4
	move.w	d6,d3
	move.w	d7,d5

Reb.YNOk	cmp.w	#8000,d2		Rebond en Z
	ble.s	Reb.ZPOk
	move.w	#7900,d2
	neg.w	d5
	move.w	d6,d3
	move.w	d7,d4

Reb.ZPOk	cmp.w	#-8000,d2
	bge.s	Reb.ZNOk
	move.w	#-7900,d2
	neg.w	d5
	move.w	d6,d3
	move.w	d7,d4

Reb.ZNOk	movem.w	d0-d5,(a3)	Stocke position et vitesse

	move.w	Timer(a4),d0
	lsl.w	#4,d0
	move.w	d0,AlphaL(a4)
	add.w	d0,d0
	move.w	d0,BetaL(a4)
	add.w	d0,d0
	move.w	d0,GammaL(a4)

	movem.w	(a3),d0-d2	Verifie si on le touche
	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#1000,d0
	bgt.s	Reb.DOK
	move.w	#$F50,CurColor(a4)
	move.w	AlphaL(a4),Alpha(a4)
	and.w	#$7F,Alpha(a4)
	move.w	BetaL(a4),Beta(a4)		Notre cap devient aleatoire

	movem.w	6(a3),d0-d2
	add.w	d0,SpeedX(a4)
	add.w	d1,SpeedY(a4)
	add.w	d2,SpeedZ(a4)

	bsr	Random
	and.w	#$3FF,d0
	sub.w	#511,d0
	move.w	d0,6(a3)
	bsr	Random
	and.w	#$3FF,d0
	sub.w	#511,d0
	move.w	d0,8(a3)
	bsr	Random			Et sa direction aussi
	and.w	#$3FF,d0
	sub.w	#511,d0
	move.w	d0,10(a3)

	moveq	#ChocOizo.S,d6		Bruit du choc
	moveq	#127,d7
	bsr	PlaySound

Reb.DOK	rts

* Chenille qui poursuit le joueur
QChenille.I
MChenille.I
	st	UseLocAng(a4)
	move.w	#$0101,-2(a3)
	move.l	6(a3),AlphaL(a4)	Angle Alpha/Beta
	clr.w	GammaL(a4)
	subq.w	#1,10(a3)		Compteur de duree de vie
	bne.s	MChenille.N
	add.w	#$10,-4(a3)	Affiche la queue
MChenille.N
	cmp.w	#-1,10(a3)
	blt	ObjClr		Si negatif, disparait

	bra	Chassr.Contact

* Tete de la chenille
TChenille.I
	tst.w	24(a3)
	bne.s	TChenille.NoInit
	movem.w	d0-d2,18(a3)	Si premier lancement de la chenille
	subq.w	#8,20(a3)		Destination = point de placement actuel
	not.w	24(a3)		Et gardiennage
TChenille.NoInit
	lea	OList(a4),a5
	move.w	ObjNum(a4),d7
	cmp.w	#120,d7
	bgt.s	TChenille.NoRoom
	lsl.w	#5,d7
	lea	0(a5,d7.w),a5
	
	move.w	-4(a3),d7		Milieu de chenille
	add.w	#$10,d7
	move.w	d7,(a5)+
	clr.w	(a5)+
	move.l	(a3)+,(a5)+	Copie des coordonnees (avec angles)
	move.l	(a3)+,(a5)+
	move.w	(a3)+,(a5)+
	lea	-10(a3),a3

	move.w	-4(a3),d7		Longueur de la chenille
	and.w	#$F,d7
	addq.w	#2,d7
	move.w	d7,(a5)+		Longueur de la chenille

	addq.w	#1,ObjNum(a4)

TChenille.NoRoom
	movem.w	18(a3),d0-d2
	bsr	CapPolar
	lsl.w	#5,d0
	add.w	d0,8(a3)		Modification du cap
	movem.w	18(a3),d0-d2
	bsr	AzimPolar
	lsl.w	#3,d0
	move.w	6(a3),d1		Recupere l'ancien azimuth
	add.w	d0,d1		Modification de l'azimuth

	move.w	d1,6(a3)		Stocke l'azimuth
	st	UseLocAng(a4)	Indique l'utilisation d'angle locaux

	moveq	#0,d0
	moveq	#0,d1
	move.w	#400,d2
	move.l	a3,-(sp)
	bsr	TriRotateL
	move.l	(sp)+,a3
	movem.w	(a3),d3-d5
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	bsr	InCube
	movem.w	d0-d2,(a3)

	movem.w	CurX(a4),d3-d5	Teste si la chenille nous a vu
	bsr	Distance
	move.w	d0,d1
	bsr	Random
	and.w	#127,d0
	beq.s	TChenille.PasDeChance

	cmp.w	#800,d1
	ble.s	Chassr.DoC	Si contact chasseur
	cmp.w	#4000,d1		Un quart du tableau
	bge.s	TChenille.PasVu

TChenille.PasDeChance
	movem.w	d3-d5,18(a3)
	movem.w	18(a3),d0-d2
	bsr	InCube2
	movem.w	d0-d2,18(a3)

TChenille.PasVu
	bsr	TesteMissile		Teste si touche par un missile
	tst.w	d7
	bpl.s	TChenille.Contact

	moveq	#Missile.S,d6	Si l'objet est touche par un missile
	moveq	#127,d7		On fait un son de missile
	bsr	PlaySound
	add.w	#5000,ToScore(a4)
	bra	ObjClr

TChenille.Contact:
	rts

* Chasseur qui vous poursuit
Chassr.I	moveq	#127,d6
	moveq	#3,d7
	bsr.s	Suiveur.I
	bsr	TesteMissile		Teste si touche par un missile
	tst.w	d7
	bpl.s	Chassr.Contact

	moveq	#Missile.S,d6	Si l'objet est touche par un missile
	moveq	#127,d7		On fait un son de missile
	bsr	PlaySound
	add.w	#3000,ToScore(a4)
	bra	ObjClr

Chassr.Contact
	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#800,d0
	bge.s	Chassr.R

Chassr.DoC
	move.w	#$F31,CurColor(a4)	Si on est touche par le vaisseau
	movem.w	(a3),d0-d2
	movem.w	CurX(a4),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
*	asr.w	#2,d3
*	asr.w	#2,d4
*	asr.w	#2,d5
	add.w	d3,SpeedX(a4)
	add.w	d4,SpeedY(a4)
	add.w	d5,SpeedZ(a4)
	moveq	#Chasseur.S,d6
	moveq	#100,d7
	bsr	PlaySound
Chassr.R	rts
	

* Objet se precipitant sur l'utilisateur
* Vitesse : D6 (translation), D7 (rotation)
Suiveur.I	move.w	d6,-(sp)		Vitesse de translation
	bsr.s	Follow.I
	moveq	#0,d0
	moveq	#0,d1
	move.w	(sp)+,d2
	move.l	a3,-(sp)
	bsr	TriRotateL
	move.l	(sp)+,a3
	movem.w	(a3),d3-d5
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	bsr	InCube
	movem.w	d0-d2,(a3)

	rts

* Objet suivant l'utilisateur dans ses deplacements
* D7 : Multiplicateur de vitesse de rotation
Follow.I	move.w	d7,-(sp)
	movem.w	CurX(a4),d0-d2
	bsr	InCube2
	bsr	CapPolar
	move.w	(sp),d7
	lsl.w	d7,d0
	add.w	d0,8(a3)		Modification du cap
	movem.w	CurX(a4),d0-d2
	bsr	InCube2
	bsr	AzimPolar

	move.w	(sp)+,d7
	lsl.w	d7,d0
	add.w	d0,6(a3)		Modification de l'azimut
	st	UseLocAng(a4)	Indique l'utilisation d'angle locaux
	rts			(Qui ont ete fixes par AzimPolar)

* Canon suivant l'utilisateur en tirant
Canon.I	moveq	#1,d7
	bsr	Follow.I		Suivi du joueur
	bsr	Random
	cmp.w	#30000,d0
	blt.s	C.I.Ret

	lea	OList(a4),a1
	move.w	ObjNum(a4),d7
	cmp.w	#120,d7
	bgt.s	C.I.Ret
	lsl.w	#5,d7
	lea	0(a1,d7.w),a1
	
	move.w	-4(a3),d0
	add.w	#$10,d0
	move.w	d0,(a1)+		Missile
	clr.w	(a1)+
	move.l	(a3)+,(a1)+	Copie des coordonnees
	move.l	(a3)+,(a1)+
	move.w	(a3)+,(a1)+

	addq.w	#1,ObjNum(a4)
	addq.w	#1,MissilN(a4)	Indique un missile de plus
C.I.Ret	rts

* Teste si on est touche par un missile
TesteMissile:
	move.w	#Missile.N,d6
	move.w	MissilN(a4),d7
	lea	OList(a4),a1
TM.1	tst.w	d7
	beq.s	C.I.Ret
	movem.w	(a1),d1-d5	Charge les coordonnees de l'objet
	and.w	#$FFF0,d1
	cmp.w	d6,d1		Est-ce un missile
	bne.s	TM.2
	movem.w	(a3),d0-d2
	bsr	Distance		Si c'est un missile, teste la distance
	cmp.w	#800,d0
	ble.s	TM.Touch
	subq.w	#1,d7
TM.2	lea	32(a1),a1		Objet suivant
	bra.s	TM.1
TM.Touch	moveq	#-1,d7		Indique touche par le missile
	rts

* Plaque qui nous permet de tirer
FireP.I	moveq	#FireP.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	FireP.R

	move.w	MaxVSpeed(a4),d0
	asr.w	#1,d0
	cmp.w	SpeedY(a4),d0
	ble.s	FireP.1
	move.w	d0,SpeedY(a4)
FireP.1	lea	OList(a4),a1
	move.w	ObjNum(a4),d7
	cmp.w	#120,d7
	bgt.s	FireP.R
	lsl.w	#5,d7
	lea	0(a1,d7.w),a1
	
	move.w	-4(a3),d0
	sub.w	#$30,d0
	move.w	d0,(a1)+		Missile
	clr.w	(a1)+
	move.l	CurX(a4),(a1)+	Copie des coordonnees
	move.w	CurZ(a4),(a1)+
	move.l	Alpha(a4),(a1)
	neg.w	(a1)+
	neg.w	(a1)+

	addq.w	#1,ObjNum(a4)
	addq.w	#1,MissilN(a4)	Ajoute un missile
FireP.R	rts



* Missile
Missile.I	moveq	#1,d7
	move.w	#200,d6
	move.w	d6,-(sp)		Vitesse de translation
	bsr	Follow.I
	moveq	#0,d0
	moveq	#0,d1
	move.w	(sp)+,d2
	move.l	a3,-(sp)
	bsr	TriRotateL
	move.l	(sp)+,a3
	movem.w	(a3),d3-d5
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	movem.w	d0-d2,(a3)
	subq.w	#1,MissilN(a4)
	cmp.w	#8000,d0
	bgt.s	ObjClr
	cmp.w	#-8000,d0
	blt.s	ObjClr
	cmp.w	#8000,d1
	bgt.s	ObjClr
	cmp.w	#-8000,d1
	blt.s	ObjClr
	cmp.w	#8000,d2
	bgt.s	ObjClr
	cmp.w	#-8000,d2
	blt.s	ObjClr

	addq.w	#1,MissilN(a4)
	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	#200,d0
	bgt.s	Mis.Ret
	move.w	#$FF0,CurColor(a4)
	add.w	#400,SpeedY(a4)

	moveq	#Missile.S,d6
	moveq	#127,d7
	bsr	PlaySound

Mis.Ret	rts

ObjClr	subq.l	#4,a3
	lea	AO.FerTab(a4),a0	Fin de la table
ObjClr.Co	move.l	32(a3),(a3)+	Copie les objets plus proches
	cmp.l	a0,a3
	blt.s	ObjClr.Co
	subq.w	#1,ObjNum(a4)
	movem.l	(sp)+,d0/d7/a0/a3	Recuperation des registres de DessineMonde (d0= Adresse de retour)
	subq.l	#4,a3		a3 pointe sur l'objet courant (ex suivant)
	bra	DM.ObjClr


****************************************************************************
*		Calcul de la distance d'ordre 1 entre 2 points
****************************************************************************
* Entree : D0-2 : X1-Z1
* 	 D3-5 : X2-Z2
* Resultat dans D0
Distance	sub.w	d3,d0
	bpl.s	Dist.X
	neg.w	d0
Dist.X	sub.w	d4,d1
	bpl.s	Dist.Y
	neg.w	d1
Dist.Y	sub.w	d5,d2
	bpl.s	Dist.Z
	neg.w	d2
Dist.Z	add.w	d1,d0
	bvs.s	Dist.Ov
	add.w	d2,d0
	bvc.s	Dist.NOv
Dist.Ov	move.w	#32000,d0
Dist.NOv	rts



***************************************************************************
*		Affichage du cube (arene de jeu)
***************************************************************************
DessineCube	move.w	#-8000,d0
	move.w	d0,CPoint1(a4)		Initialise le CPoint 1 et les autres
	move.w	d0,CPoint1+2(a4)
	move.w	d0,CPoint1+4(a4)
	move.w	d0,CPoint2+2(a4)
	move.w	d0,CPoint2+4(a4)
	move.w	d0,CPoint3+4(a4)
	move.w	d0,CPoint4(a4)
	move.w	d0,CPoint4+4(a4)
	move.w	d0,CPoint5(a4)
	move.w	d0,CPoint5+2(a4)
	move.w	d0,CPoint6+2(a4)
	move.w	d0,CPoint8(a4)

	neg.w	d0			Stockage des coordonnees negatives
	move.w	d0,CPoint2(a4)
	move.w	d0,CPoint3(a4)
	move.w	d0,CPoint3+2(a4)
	move.w	d0,CPoint4+2(a4)
	move.w	d0,CPoint5+4(a4)
	move.w	d0,CPoint6(a4)
	move.w	d0,CPoint6+4(a4)
	move.w	d0,CPoint7(a4)
	move.w	d0,CPoint7+2(a4)
	move.w	d0,CPoint7+4(a4)
	move.w	d0,CPoint8+2(a4)
	move.w	d0,CPoint8+4(a4)

	clr.l	ObjX(a4)			Calcul des coordonnees transformees pour ModObjX
	clr.w	ObjZ(a4)
	clr.w	UseLocAng(a4)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ			Rotation du centre du cube
	movem.w	d0-d2,ModObjX(a4)		Et stockage
	
	lea	Cube1(pc),a0
	btst	#0,Options2(a4)		Trace de fond ?
	beq.s	TC.Fond
	lea	Cube2(pc),a0
TC.Fond	clr.w	UseLocAng(a4)
	st	FastFill(a4)
	bsr	AffObj
	clr.w	FastFill(a4)
	rts

Cube1	dc.b	GO1,GO2,GO3,GO4,GO5,GO6,GO7,GO8,END
	dc.b	1
	dc.b	4,5,9,8,$F0
	dc.b	2,3,$F1
	dc.b	3,4,$F1
	dc.b	4,5,$F1
	dc.b	5,2,$F1
	dc.b	6,7,$F2
	dc.b	7,8,$F2
	dc.b	8,9,$F2
	dc.b	9,6,$F2
	dc.b	2,6,$F1
	dc.b	3,7,$F1
	dc.b	4,8,$F1
	dc.b	5,9,$F1
	dc.b	0,0


Cube2	dc.b	GO1,GO2,GO3,GO4,GO5,GO6,GO7,GO8,END
	dc.b	1
	dc.b	2,3,$F1
	dc.b	3,4,$F1
	dc.b	4,5,$F1
	dc.b	5,2,$F1
	dc.b	6,7,$F2
	dc.b	7,8,$F2
	dc.b	8,9,$F2
	dc.b	9,6,$F2
	dc.b	2,6,$F1
	dc.b	3,7,$F1
	dc.b	4,8,$F1
	dc.b	5,9,$F1
	dc.b	0,0

DessineOCub	move.w	d0,CPoint1(a4)		Initialise le CPoint 1 et les autres
	move.w	d0,CPoint1+2(a4)
	move.w	d0,CPoint1+4(a4)
	move.w	d0,CPoint2+2(a4)
		move.w	d0,CPoint2+4(a4)
	move.w	d0,CPoint3+4(a4)
	move.w	d0,CPoint4(a4)
	move.w	d0,CPoint4+4(a4)
	move.w	d0,CPoint5(a4)
	move.w	d0,CPoint5+2(a4)
	move.w	d0,CPoint6+2(a4)
	move.w	d0,CPoint8(a4)

	neg.w	d0			Stockage des coordonnees negatives
	move.w	d0,CPoint2(a4)
	move.w	d0,CPoint3(a4)
	move.w	d0,CPoint3+2(a4)
	move.w	d0,CPoint4+2(a4)
	move.w	d0,CPoint5+4(a4)
	move.w	d0,CPoint6(a4)
	move.w	d0,CPoint6+4(a4)
	move.w	d0,CPoint7(a4)
	move.w	d0,CPoint7+2(a4)
	move.w	d0,CPoint7+4(a4)
	move.w	d0,CPoint8+2(a4)
	move.w	d0,CPoint8+4(a4)

	clr.l	ObjX(a4)			Calcul des coordonnees transformees pour ModObjX
	clr.w	ObjZ(a4)
	clr.w	UseLocAng(a4)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ			Rotation du centre du cube
	movem.w	d0-d2,ModObjX(a4)		Et stockage
	lea	DemoCube(pc),a0
	clr.w	UseLocAng(a4)
	bra	AffObj

DemoCube	dc.b	GO1,GO2,GO3,GO4,GO5,GO6,GO7,GO8,END
	dc.b	1
	dc.b	2,3,4,5,$F5
	dc.b	9,8,7,6,$F2
	dc.b	5,4,8,9,$F3
	dc.b	6,7,3,2,$F4
	dc.b	3,7,8,4,$F5
	dc.b	5,9,6,2,$F6
	dc.b	0,0


***************************************************************************
*		Permutation des variables joueur 1 & 2
***************************************************************************
SwapVars	move.l	a4,a5
	move.l	Other(a4),a4	Permutation
* Si le deuxieme joueur est dans le meme tableau que le premier,
* alors on n'utilise qu'une seule liste d'objets.
	tst.w	Joueur(a4)
	beq.s	SW.Return
	move.w	Tableau(a4),d0
	cmp.w	Tableau(a5),d0
	bne.s	SW.Return
	tst.w	JSuisMort(a5)
	bne.s	SW.Return

	lea	OList(a4),a0
	lea	OList(a5),a1	Copie de la liste des objets
	move.w	ObjNum(a5),d0
	subq.w	#1,d0

SW.Copy	movem.l	(a1)+,d1-d7/a2
	movem.l	d1-d7/a2,(a0)
	lea	32(a0),a0
	dbra	d0,SW.Copy

SW.Return	rts

***************************************************************************
*		Affichage de la liste des objets
***************************************************************************
* Liste d'objets de la forme
* W : Numero d'objet dans la table ObjTab
* W : Timer (si negatif, l'objet n'est pas calcule)
* 3W: X,Y,Z de l'objet
* 3W: Donnees pour l'objet (Utilise par les .I)

* Tri a bulle selon les Z decroissants
* D5 est a -1 si il y a eu une permutation,0 sinon
DessineMonde:
	cmp.w	#-$30,Alpha(a4)
	bpl.s	DM.Bas
	move.w	#-1,NumOmb(a4)
	bra.s	DM.OEA
DM.Bas	cmp.w	#8001,AltiOmb(a4)
	bne.s	DM.OEA
	bsr	DessineOmbre	Si l'ombre est au sol, on Dessine
DM.OEA	clr.w	UseLocAng(a4)	Pas d'angles locaux dans les calculs de rotations
	move.w	#8001,NxAOmb(a4)	Prochaine altitude de l'ombre
	clr.w	NxNOmb(a4)	Indique pas d'objet sur lequel l'ombre est posee

	move.w	ObjNum(a4),d7
	subq.w	#1,d7		Adaptation DBRA, plus un objet lu
	bmi	DM.End		Si 0 objet

	move.w	d7,-(sp)
	clr.w	ObjX(a4)		Effacement pour la routine de coordonnees
	clr.l	ObjY(a4)
* Rotation des differents sommets
	lea	OList(a4),a0
DM.Somm	movem.w	4(a0),d0-d2
	movem.l	d7/a0,-(sp)
	bsr	TransXYZ
	movem.l	(sp)+,d7/a0
	cmp.w	#-3000,d2		Si le Z modifie est negatif, on indique que l'objet ne doit pas etre affiche
	bpl.s	DM.BuBul
	move.w	6(a0),d3		Teste si objet sous ombre
	cmp.w	AltiOmb(a4),d3	si oui
	beq.s	DM.BuBul		Alors ne pas effacer
	move.w	Joueur(a4),d3
	move.b	#-3,2(a0,d3.w)
DM.BuBul	movem.w	d0-d2,16(a0)	Stockage des coordonnees modifiees
	lea	32(a0),a0
	dbra	d7,DM.Somm

DM.DoBul	move.w	(sp),d7
	lea	OList(a4),a0
	moveq	#0,d5		D5: Indicateur de permutation <>0 si une permutation a ete effectuee
	move.w	#$50,-32(a0)
	move.w	#$FFFF,-32+2(a0)	Indique objet non visible
	move.w	#$7FFF,-32+20(a0)	Indique un Z modifie pour le premier point qui ne provoquera pas de permutation

DM.Bulle	move.w	20(a0),d2		Lecture du Z modifie
	move.w	-32+20(a0),d1	Lecture du Z modifie de l'objet precedent

	cmp.w	d1,d2		L'objet actuel est-il plus proche que celui d'avant
	ble.s	DM.BulOk		Si oui, pas de permutation

	moveq	#-1,d5		Indique qu'une permutation a ete effectuee
	movem.l	-32(a0),d1-d4	lecture des 32 octets
	movem.l	(a0),a1-a3/a6
	movem.l	d1-d4,(a0)	Ecriture permutee
	movem.l	a1-a3/a6,-32(a0)
	movem.l	-16(a0),d1-d4	lecture des 32 octets
	movem.l	16(a0),a1-a3/a6
	movem.l	d1-d4,16(a0)	Ecriture permutee
	movem.l	a1-a3/a6,-16(a0)


DM.BulOk	lea	32(a0),a0		Passage a l'objet suivant
	dbra	d7,DM.Bulle
	tst.w	d5		Teste si au moins une permutation a ete faite
	bne	DM.DoBul		Si oui, on recommence jusqu'au classement final


* On a maintenant une liste triee dans l'ordre des Z decroissants
* Deuxieme partie : l'affichage par AffObj
* On commence par lire les coordonnees, que l'on stocke dans ObjX
* Ensuite on appelle la routine associee a l'objet
* Enfin on Dessine l'objet si le Timer est Ok

	lea	OList(a4),a3
	move.w	(sp)+,d7		Recuperation du nombre d'objets

DM.DLoop	move.w	#-1,ObjetVu(a4)	Indique qu'a priori, l'objet est invisible
	movem.w	(a3)+,d5		Lecture de l'index et du timer
	addq.l	#2,a3
	move.w	d5,d6
	and.w	#$F,d6
	move.w	d6,DefColor(a4)
	
	and.w	#$FFF0,d5		Pointe avec index/16 sur une table
	lsr.w	#1,d5		de 2Longs.

	movem.w	12(a3),d0-d2	Lecture des coordonnees transformees
	movem.w	d0-d2,ModObjX(a4)	Et stockage
	movem.w	(a3),d0-d2
	movem.w	d0-d2,ObjX(a4)	Stockage des coordonnees
	move.l	AdObjTab(a4),a0
	movem.l	0(a0,d5.w),a1/a5
	lea	ObjPrgs(pc),a2
	lea	0(a2,a5.l),a5	Recupere l'adresse du programme .I
	lea	0(a0,a1.l),a0	Et l'adresse de l'objet a afficher
	movem.l	d7/a0/a3,-(sp)

	clr.w	UseLocAng(a4)
	jsr	(a5)		Appel de la routine .I associee
	movem.l	(sp),d7/a0/a3

	cmp.w	#-1,NumOmb(a4)	Teste si l'ombre a ete affichee
	bne.s	DM.VNoDisp	Sinon, n'essaie pas d'afficher le vaisseau

	move.w	16(a3),d0		Teste si l'objet est encore devant le vaisseau
	bmi.s	DM.VNoDisp
	cmp.w	PosZ(a4),d0
	bge.s	DM.VNoDisp
	bsr	DessineVaiss	Sinon, affiche le vaisseau
	movem.l	(sp)+,d7/a0/a3
	subq.l	#4,a3
	bra.s	DM.DLoop
DM.VNoDisp:
	move.w	Joueur(a4),d0
	addq.b	#1,-2(a3,d0.w)		Incrementation du timer
	bvs.s	DM.TimOut		teste si pas de depassement de capacite
	ble.s	DM.NoDisp		Si negatif ou nul: on laisse tomber

DM.DoDisp	bsr	AffObj		Sinon, on affiche l'objet
	tst.w	ObjetVu(a4)
	beq.s	DM.NoDisp
	movem.l	(sp),d7/a0/a3	Indique que l'objet n'a pas ete affiche
	move.w	NumOmb(a4),d0	Sauf si l'ombre est posee dessus
	cmp.w	26(a3),d0
	beq.s	DM.NoDisp
	move.w	Joueur(a4),d0
	move.b	#-4,-2(a3,d0.w)

DM.NoDisp	movem.l	(sp),d7/a0/a3
	move.w	NumOmb(a4),d0	Si l'objet sur lequel est pose l'ombre
	cmp.w	26(a3),d0
	bne.s	DM.ANeg
	bsr	DessineOmbre	Affiche l'ombre

DM.ANeg	movem.l	(sp)+,d7/a0/a3
	lea	28(a3),a3
DM.ObjClr	dbra	d7,DM.DLoop

DM.End	cmp.w	#-1,NumOmb(a4)
	bne.s	DM.VNoDisp2
	bsr	DessineVaiss
DM.VNoDisp2:
	move.w	NxAOmb(a4),AltiOmb(a4)
	move.w	NxNOmb(a4),NumOmb(a4)
	rts
DM.TimOut	clr.b	-2(a3,d0)		En cas de depassement du timer, remise a 0
	bra.s	DM.DoDisp		Et affichage

***************************************************************************
*		Affichage d'un objet pointe par A0
***************************************************************************
* Entree : A0 pointant sur l'objet
*  Cet objet est de la forme suivante :
*   dec.B : Decalage d'un sommet par rapport au precedent (voir table)
*  0
*   ref : Index de sommet de reference pour sous-objets
*    n1 n2 ... : Liste des facettes (numero < 127)
*    $xC ou x>8 : fin de liste de sommets -> Couleur de la facette
*    0 : Fin de definition de sous-objet
*   0 : fin de definition d'objet
*
* Definition des decalages  de passage d'un sommet a l'autre
*
	RSRESET
END	rs.b	1	Fin de la liste de sommets

XP1	rs.b	1	Ajout de 100 a l'axe X
XM1	rs.b	1	Soustraction de 100
YP1	rs.b	1
YM1	rs.b	1
ZP1	rs.b	1
ZM1	rs.b	1
XP2	rs.b	1	Ajout de 200 a l'axe X
XM2	rs.b	1	Soustraction de 200
YP2	rs.b	1
YM2	rs.b	1
ZP2	rs.b	1
ZM2	rs.b	1
XP3	rs.b	1	Ajout de 300 a l'axe X
XM3	rs.b	1	Soustraction de 300
YP3	rs.b	1
YM3	rs.b	1
ZP3	rs.b	1
ZM3	rs.b	1
XP4	rs.b	1	Ajout de 400 a l'axe X
XM4	rs.b	1	Soustraction de 400
YP4	rs.b	1
YM4	rs.b	1
ZP4	rs.b	1
ZM4	rs.b	1
XP5	rs.b	1	Ajout de 500 a l'axe X
XM5	rs.b	1	Soustraction de 500
YP5	rs.b	1
YM5	rs.b	1
ZP5	rs.b	1
ZM5	rs.b	1
XP10	rs.b	1	Ajout de 1000 a l'axe X
XM10	rs.b	1	Soustraction de 1000
YP10	rs.b	1
YM10	rs.b	1
ZP10	rs.b	1
ZM10	rs.b	1

ORIG	rs.b	1	Passage au point origine
GO1	rs.b	1	Sommet absolu 1 (rotation effectuee sur le moment)
GO2	rs.b	1
GO3	rs.b	1
GO4	rs.b	1
GO5	rs.b	1
GO6	rs.b	1
GO7	rs.b	1
GO8	rs.b	1
GO9	rs.b	1
GO10	rs.b	1


DirTab	dc.w	0			Fin de la liste
	dc.w	XP1.Dir-DirTab,XM1.Dir-DirTab,YP1.Dir-DirTab,YM1.Dir-DirTab,ZP1.Dir-DirTab,ZM1.Dir-DirTab
	dc.w	XP2.Dir-DirTab,XM2.Dir-DirTab,YP2.Dir-DirTab,YM2.Dir-DirTab,ZP2.Dir-DirTab,ZM2.Dir-DirTab
	dc.w	XP3.Dir-DirTab,XM3.Dir-DirTab,YP3.Dir-DirTab,YM3.Dir-DirTab,ZP3.Dir-DirTab,ZM3.Dir-DirTab
	dc.w	XP4.Dir-DirTab,XM4.Dir-DirTab,YP4.Dir-DirTab,YM4.Dir-DirTab,ZP4.Dir-DirTab,ZM4.Dir-DirTab
	dc.w	XP5.Dir-DirTab,XM5.Dir-DirTab,YP5.Dir-DirTab,YM5.Dir-DirTab,ZP5.Dir-DirTab,ZM5.Dir-DirTab
	dc.w	XP10.Dir-DirTab,XM10.Dir-DirTab,YP10.Dir-DirTab,YM10.Dir-DirTab,ZP10.Dir-DirTab,ZM10.Dir-DirTab
	dc.w	Origin.Dir-DirTab
	dc.w	Point1.Dir-DirTab
	dc.w	Point2.Dir-DirTab
	dc.w	Point3.Dir-DirTab
	dc.w	Point4.Dir-DirTab
	dc.w	Point5.Dir-DirTab
	dc.w	Point6.Dir-DirTab
	dc.w	Point7.Dir-DirTab
	dc.w	Point8.Dir-DirTab
	dc.w	Point9.Dir-DirTab
	dc.w	Point10.Dir-DirTab

XP1.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP1.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP1.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts

XP2.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP2.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP2.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP3.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP3.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP3.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP4.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP4.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP4.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP5.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP5.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP5.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP10.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP10.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP10.Dir	add.w	#0,d0		Valeurs Patchees par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts


XM1.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM1.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM1.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts

XM2.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM2.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM2.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM3.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM3.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM3.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM4.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM4.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM4.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM5.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM5.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM5.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM10.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM10.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM10.Dir	sub.w	#0,d0		Valeurs Patchees par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts


Origin.Dir:
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	rts
Point1.Dir:
	movem.w	CPoint1(a4),d0-d2
	bra	TriRotate
Point2.Dir:
	movem.w	CPoint2(a4),d0-d2
	bra	TriRotate
Point3.Dir:
	movem.w	CPoint3(a4),d0-d2
	bra	TriRotate
Point4.Dir:
	movem.w	CPoint4(a4),d0-d2
	bra	TriRotate
Point5.Dir:
	movem.w	CPoint5(a4),d0-d2
	bra	TriRotate
Point6.Dir:
	movem.w	CPoint6(a4),d0-d2
	bra	TriRotate
Point7.Dir:
	movem.w	CPoint7(a4),d0-d2
	bra	TriRotate
Point8.Dir:
	movem.w	CPoint8(a4),d0-d2
	bra	TriRotate
Point9.Dir:
	movem.w	CPoint9(a4),d0-d2
	bra	TriRotate
Point10.Dir:
	movem.w	CPoint10(a4),d0-d2
	bra	TriRotate


* En cas de rotation locales pour les objets
LDirTab	dc.w	0			Fin de la liste
	dc.w	XP1.LDir-LDirTab,XM1.LDir-LDirTab,YP1.LDir-LDirTab,YM1.LDir-LDirTab,ZP1.LDir-LDirTab,ZM1.LDir-LDirTab
	dc.w	XP2.LDir-LDirTab,XM2.LDir-LDirTab,YP2.LDir-LDirTab,YM2.LDir-LDirTab,ZP2.LDir-LDirTab,ZM2.LDir-LDirTab
	dc.w	XP3.LDir-LDirTab,XM3.LDir-LDirTab,YP3.LDir-LDirTab,YM3.LDir-LDirTab,ZP3.LDir-LDirTab,ZM3.LDir-LDirTab
	dc.w	XP4.LDir-LDirTab,XM4.LDir-LDirTab,YP4.LDir-LDirTab,YM4.LDir-LDirTab,ZP4.LDir-LDirTab,ZM4.LDir-LDirTab
	dc.w	XP5.LDir-LDirTab,XM5.LDir-LDirTab,YP5.LDir-LDirTab,YM5.LDir-LDirTab,ZP5.LDir-LDirTab,ZM5.LDir-LDirTab
	dc.w	XP10.LDir-LDirTab,XM10.LDir-LDirTab,YP10.LDir-LDirTab,YM10.LDir-LDirTab,ZP10.LDir-LDirTab,ZM10.LDir-LDirTab
	dc.w	Origin.LDir-LDirTab
	dc.w	Point1.LDir-LDirTab
	dc.w	Point2.LDir-LDirTab
	dc.w	Point3.LDir-LDirTab
	dc.w	Point4.LDir-LDirTab
	dc.w	Point5.LDir-LDirTab
	dc.w	Point6.LDir-LDirTab
	dc.w	Point7.LDir-LDirTab
	dc.w	Point8.LDir-LDirTab
	dc.w	Point9.LDir-LDirTab
	dc.w	Point10.LDir-LDirTab

XP1.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP1.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP1.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts

XP2.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP2.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP2.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP3.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP3.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP3.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP4.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP4.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP4.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP5.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP5.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP5.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP10.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP10.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP10.LDir	add.w	#0,d0		Valeurs Patchees par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts


XM1.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM1.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM1.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts

XM2.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM2.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM2.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM3.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM3.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM3.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM4.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM4.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM4.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM5.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM5.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM5.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM10.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM10.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM10.LDir	sub.w	#0,d0		Valeurs Patchees par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts


Origin.LDir:
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	rts
Point1.LDir:
	movem.w	CPoint1(a4),d0-d2
	bra.s	Point.LDir
Point2.LDir:
	movem.w	CPoint2(a4),d0-d2
	bra.s	Point.LDir
Point3.LDir:
	movem.w	CPoint3(a4),d0-d2
	bra.s	Point.LDir
Point4.LDir:
	movem.w	CPoint4(a4),d0-d2
	bra.s	Point.LDir
Point5.LDir:
	movem.w	CPoint5(a4),d0-d2
	bra.s	Point.LDir
Point6.LDir:
	movem.w	CPoint6(a4),d0-d2
	bra.s	Point.LDir
Point7.LDir:
	movem.w	CPoint7(a4),d0-d2
	bra.s	Point.LDir
Point8.LDir:
	movem.w	CPoint8(a4),d0-d2
	bra.s	Point.LDir
Point9.LDir:
	movem.w	CPoint9(a4),d0-d2
	bra.s	Point.LDir
Point10.LDir:
	movem.w	CPoint10(a4),d0-d2

Point.LDir	bsr	TriRotateL
	bra	TriRotate


AffObj	lea	Sommets(a4),a5
	moveq	#0,d6		d6: Compteur de >0 et <0
	moveq	#0,d7		Zero sommets pour l'instant
	moveq	#0,d0		Coordonnees de depart
	moveq	#0,d1
	moveq	#0,d2

	lea	DirTab(pc),a1
	tst.w	UseLocAng(a4)
	beq.s	AO.Somm

* Utilisation des registres :
* D0-2 : X Y Z courants par rapport a X
* D3-D5: Usages divers
* d6 : Indicateur avant/arriere
* 	Si d6=-NbSommets, tout est derriere : On ne Dessine rien
* 	Si d6=0, tout est devant > l'inverse
* D7 : Nombre de sommets ainsi transformes
* A0 : Pointeur sur la liste de descriptions de sommets
* A5 : Pointeur sur la table de sommets

* Transformation de coordonnees pour tous les sommets

	movem.l	d0-d2/d6/d7/a0/a5,-(sp)
	bsr	LTrigInit			Init. lignes Trigo Locale
	movem.l	(sp)+,d0-d2/d6/d7/a0/a5
	lea	LDirTab(pc),a1

AO.Somm	movem.w	ModObjX(a4),d3-d5		Lecture de la position du centre
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	movem.w	d3-d5,(a5)		Stockage du point obtenu
	addq.l	#8,a5			Acces rapide (8 octets / sommet)

	add.w	d5,d5			Ajoute 1 uniquement si negatif
	moveq	#0,d4
	addx.w	d4,d6
	addq.w	#1,d7			Compte les sommets devant pendant ce temps

	moveq	#0,d3
	move.b	(a0)+,d3			Lit le sommet suivant
	beq.s	AO.EndSom			Fin d'affichage
	add.w	d3,d3
	move.w	0(a1,d3.w),d3		Lecture de l'offset
	movem.l	d6-d7/a0/a1/a5,-(sp)
	jsr	0(a1,d3.w)		Et appel de la routine qui doit modifier d0-d2
	movem.l	(sp)+,a0/a1/a5/d6-d7

	bra.s	AO.Somm

AO.EndSom	move.w	d7,d5		Sauvegarde du nombre de sommets pour transformation globale de Pers si D6=0
	cmp.w	d6,d7		d6=d7 ?
	beq	AO.Quit		Si oui, on ne Dessine rien.

	tst.w	d6		d6 est-il nul (tout devant)
	bne.s	AO.Cheval		On est a cheval dessus

* Transformation globale de perspective quand l'objet est entierement devant
	lea	Sommets(a4),a5
	subq.w	#1,d5		Adaptation DBRA
AO.DoPer1	movem.w	(a5),d0-d2	lecture des coordonnees
	bsr	Perspect
	movem.w	d0-d1,(a5)
	addq.l	#8,a5
	dbra	d5,AO.DoPer1

* Macro de recherche d'adresse et de Z de sous objet
AOSSOBJ	MACRO	(numero de registre)
	move.l	a0,a\1		a1 : Pointeur de sous objet 1
	lsl.w	#3,d0		d0 pointe dans la liste de sommets
	move.w	4(a5,d0.w),d\1	d1 : Z du sous-objet
	moveq	#0,d0
AO.SSOB\@	move.b	(a0)+,d0
	bne.s	AO.SSOB\@		Recherche du sous-objet suivant
	ENDM

* Test des sous-objets eventuels
AO.Cheval	lea	Sommets-8(a4),a5	a5 pointeur de sommets
	moveq	#0,d0
	move.b	(a0)+,d0		Lecture de la facette de reference
	beq	AO.Quit		rien a Dessiner
	AOSSOBJ	1		A1=SsObj 1, D1=Z

	move.b	(a0)+,d0
	bne.s	AO.Mini2		au minimum deux sous-objets
	move.l	a1,a0
	bra.s	AO.Concav

AO.Mini2	AOSSOBJ	2		Stockage objet 2 dans A2
	move.b	(a0)+,d0
	bne.s	AO.Mini3
	cmp.w	d1,d2		Compare l'ordre d'affichage
	blt.s	AO.1puis2
	exg.l	a1,a2

AO.1puis2	move.l	a2,-(sp)
	move.l	a1,a0
	bsr.s	AO.Concav
	move.l	(sp)+,a0
	bra.s	AO.Concav

AO.Mini3	AOSSOBJ	3		Il y a au moins 3 ss objets !
	move.b	(a0)+,d0
	bne	AO.Quit		Jamais plus de 3, non mais !
* On essaie ici de retrouver l'ordre 1 puis 2 puis 3
* Ordre de comparaison : 1-2 puis 2-3 puis 1-3
	cmp.w	d2,d3
	ble.s	AO.Ok12
	exg.l	a2,a3
	exg.l	d2,d3
AO.Ok12	cmp.w	d1,d2
	ble.s	AO.Ok23
	exg.l	a1,a2
	exg.l	d1,d2
AO.Ok23	cmp.w	d1,d3
	ble.s	AO.Ok13
	exg.l	a1,a3

AO.Ok13	movem.l	a2/a3,-(sp)

	move.l	a1,a0
	bsr.s	AO.Concav
	move.l	(sp)+,a0
	bsr.s	AO.Concav
	move.l	(sp)+,a0


* Affichage d'un sous-objet concave pointe par a0
* d6 contient 0 si tout est devant, auquel cas les perspectives sont faites
AO.Concav	move.w	d6,-(sp)		Sauvegarde l'indicateur ZClip
	beq	AO.Good

	tst.b	1(a0)
	bmi	AO.BSphere	Mauvaise sphere

* Avant le ZClipping, on ferme le polygone
	lea	FacFill(pc),a2
	move.l	a2,Filler(a4)
AO.Bad	lea	AO.FerTab(a4),a2
	move.l	a2,a1
	moveq	#0,d0
	moveq	#0,d3
AO.Ferme	move.b	(a0)+,d0
	beq	AO.End
	bmi.s	AO.FrEnd
	move.b	d0,(a2)+
	addq.w	#1,d3
	bra.s	AO.Ferme
AO.FrEnd	move.b	(a1),(a2)+
	move.b	d0,(a2)+
	clr.b	(a2)+
	move.l	a0,a3		Sauve pour rappel
	move.l	a1,a0

	cmp.w	#2,d3
	beq	AO.Line

* Ici on effectue un clip Z sur les polygones traces
* Methode :
* Deux boucles: l'une si le dernier point lu est positif
* auquel cas on l'entre et on lit le deuxieme point
* l'autre pour les points negatifs, que l'on n'entre pas
* Quand on passe de l'une a l'autre, on fait un calcul d'intersection
* qui rajoute un point au polygone.
*
* Formule d'intersection: x0 = x2-(x1-x2)*z2/(z1-z2)
	lea	PolySomm(a4),a6	Liste des sommets du polygone
	lea	Sommets-8(a4),a5	Pointeur sur les sommets
	moveq	#0,d3		Compteur d'angles du Polygone

	moveq	#0,d0		Pour Byte -> Word Unsigned
	move.b	(a0)+,d0
	beq	AO.End		Si lecture de la fin
	bmi	AO.BEnd		Si lecture de la couleur

	lsl.w	#3,d0		Pointe sur les sommets
	movem.w	0(a5,d0.w),d0-d2	Lecture de X,Y,Z
	tst.w	d2
	bmi.s	AO.BNeg		Passage dans la boucle des negatifs

* Boucle : le dernier point lu etait positif (-> D0-D2)
AO.BPos	movem.w	d0-d2,(a6)
	movem.w	(a6),d4-d6
	addq.l	#6,a6
	addq.w	#1,d3		Incremente le compteur d'angles

	moveq	#0,d0
	move.b	(a0)+,d0		Lecture du point suivant
	beq	AO.End
	bmi	AO.BEnd
	lsl.w	#3,d0
	movem.w	0(a5,d0.w),d0-d2
	tst.w	d2		Si positif, on l'entre et on recommence
	bpl.s	AO.BPos

* Ici, on a un point negatif dans D0-2 et positif dans D4-6
	movem.w	d0-d2,-(sp)	Stockage des anciens (negatif)

	move.w	d0,d7		X1
	sub.w	d4,d7		X1-X2
	muls	d2,d7		D7=(X1-X2)*Z1
	sub.w	d2,d6		D6=Z2-Z1
	divs	d6,d7		d7=-(X1-X2)*Z1/(Z1-Z2)
	add.w	d7,d0		D0=X0

	move.w	d1,d7
	sub.w	d5,d7
	muls	d2,d7
	divs	d6,d7
	add.w	d7,d1		D1=Y0
	moveq	#0,d2		Z=Z0=0

	movem.w	d0-d2,(a6)
	addq.l	#6,a6
	addq.w	#1,d3		Un sommet de plus

	movem.w	(sp)+,d0-d2	Recuperation du sommet devant

* Boucle ou le dernier point est negatif (dans D0-2)
* On ne stocke donc pas de point
AO.BNeg	move.w	d0,d4		Dernier point lu -> D4-6
	move.w	d1,d5
	move.w	d2,d6

	moveq	#0,d0
	move.b	(a0)+,d0		Lecture du point suivant
	beq	AO.End
	bmi.s	AO.BEnd
	lsl.w	#3,d0
	movem.w	0(a5,d0.w),d0-d2
	tst.w	d2		Si negatif, on en relit un
	bmi.s	AO.BNeg

* Ici, on a un point positif dans D0-2 et negatif dans D4-6
	movem.w	d0-d2,-(sp)	On stocke le positif (on ne peut le mettre dans le tableau sans croiser)

* On met ensuite le sommet d'intersection dans D0-2
	move.w	d0,d7		X1
	sub.w	d4,d7		X1-X2
	muls	d2,d7		D7=(X1-X2)*Z1
	sub.w	d2,d6		D6=Z2-Z1
	divs	d6,d7		d7=-(X1-X2)*Z1/(Z1-Z2)
	add.w	d7,d0		D0=X0

	move.w	d1,d7
	sub.w	d5,d7
	muls	d2,d7
	divs	d6,d7
	add.w	d7,d1		D1=Y0
	moveq	#0,d2		Z=Z0=0

	movem.w	d0-d2,(a6)	On stocke le point d'intersection
	addq.l	#6,a6
	addq.w	#1,d3

	movem.w	(sp)+,d0-d2	Et on recupere le point suivant
	bra	AO.BPos		et on retourne dans les positifs (stockage)

AO.BEnd	cmp.b	#$F0,d0
	bhs.s	AO.BEnd2
	add.w	DefColor(a4),d0
AO.BEnd2	and.w	#$F,d0		Fin de lecture d'une facette
	move.w	d0,Couleur(a4)	Stockage de la couleur
	cmp.w	#2,d3
	blt	AO.ReBad		Si oui, on ne plante pas la routine de remplissage

* On a maintenant dans PolySomm des sommets a trois points sans perspective
* On effectue donc la perspective
	move.w	d3,d7
	move.w	d7,d6		Sauvegarde du nombre de points dans D6
	subq.w	#1,d7		Adaptation DBRA
	lea	PolySomm(a4),a6	A4 : pointeur de lecture
	move.l	a6,a5		A5 : Pointeur d'ecriture

* On va lire dans le tableau 3 coordonnees et en ecrire 2: le pointeur
* A5 avancera moins vite que A4, donc ce n'est pas genant
AO.BPers	movem.w	(a6)+,d0-d2
	bsr	Perspect
	move.w	d0,(a5)+
	move.w	d1,(a5)+
	dbra	d7,AO.BPers
	move.w	d6,d3		Recuperation du nombre de points
	move.l	a3,-(sp)
	move.l	Filler(a4),a3
	jsr	(a3)		Remplissage de facette (selon le cas uniquement positive ou non)
	move.l	(sp)+,a3
AO.ReBad	move.l	a3,a0
	bra	AO.Bad

* Affichage d'un sous objet sans Z-Clipping (tous les sommets sont devant)
AO.Good	lea	PolySomm(a4),a6	Liste des sommets du polygone
	lea	Sommets-8(a4),a5	Pointeur sur les sommets
	moveq	#0,d3		Compteur d'angles du Polygone

AO.GLoop	moveq	#0,d0		Pour Byte -> Word Unsigned
	move.b	(a0)+,d0
	beq.s	AO.End		Si lecture de la fin
	bmi.s	AO.GEnd		Si lecture de la couleur

	lsl.w	#3,d0		Pointe sur les sommets
	movem.w	0(a5,d0.w),d0-d2	Lecture de X et Y. Z est lu pour usage par DoCircle
	move.w	d0,(a6)+
	move.w	d1,(a6)+
	addq.w	#1,d3		Incremente le compteur d'angles

	bra.s	AO.GLoop

AO.GEnd	cmp.b	#$F0,d0		Teste les codes couleurs en E
	bhs.s	AO.GEnd2
	add.w	DefColor(a4),d0
AO.GEnd2	and.w	#$F,d0		Fin de lecture d'une facette
	move.w	d0,Couleur(a4)	Stockage de la couleur

	cmp.w	#1,d3		Teste si un seul point (definition d'une sphere)
	beq.s	AO.Sphere

	bsr	FacFill		Remplissage de facette positive
	bra.s	AO.Good

AO.End	move.w	(sp)+,d6
AO.Quit	rts			Fin de l'affichage d'objet

* Cas particulier de la 'mauvaise' sphere
AO.BSphere:
	moveq	#0,d0
	move.b	(a0)+,d0
	lsl.w	#3,d0

	lea	Sommets(a4),a6	Effectue la perspective
	movem.w	-8(a6,d0.w),d0-d2
	bsr	Perspect
	movem.w	d0-d1,PolySomm(a4)

	moveq	#1,d3
	moveq	#0,d0
	move.b	(a0)+,d0
	bra.s	AO.GEnd		Et on reprend la boucle classique

* Cas particulier de la sphere. D2=Z du centre
AO.Sphere	moveq	#0,d0
	move.b	(a0)+,d0		Lecture du rayon
	mulu.w	#10,d0		Multiplication par 10

	move.w	LFactor(a4),d3	Calcul de la perspective
	ext.l	d0
	asl.l	d3,d0
	move.w	KFactor(a4),d3
	add.w	d2,d3
	divs	d3,d0
	move.w	d0,d1

	moveq	#32,d6
	moveq	#31,d7		32 points pour un cercle

	lea	PolySomm(a4),a1
	move.l	(a1),-(sp)	Sauvegarde les coordonnees
	move.l	a0,-(sp)
	bsr	DoCircle
	move.l	(sp)+,a0

	movem.w	(sp)+,d0-d1
	lea	PolySomm(a4),a1
	moveq	#31,d7
AO.SphOf	add.w	d0,(a1)+		Calcule le decalage ecran
	add.w	d1,(a1)+
	dbra	d7,AO.SphOf

	moveq	#32,d3		Effectue le remplissage
	pea	AO.Good(pc)		Pour que le RTS envoie sur AO.Good
	move.l	a0,-(sp)
	lea	PolySomm(a4),a0

	bra	FacFill.NonOr

* DoCircle :  Dessine une ellipse dans une zone memoire
* Entree: A1 : Zone ou ecrire
*	D0,D1 : rayons X et Y
*	D5: Angle de l'axe X avec l'horizontale
*	D6: Decalage angulaire entre deux points successifs
*	D7: Nombre de points
DoCircle	move.w	d0,-(sp)
	move.w	d1,-(sp)
DoCirc.1	move.w	d5,d1		Determine 300 CosY et 300 SinY
	move.w	(sp),d0
	bsr	XSinY
	move.w	d2,-(sp)
	move.w	d5,d1
	move.w	4(sp),d0
	bsr	XCosY
	move.w	(sp)+,(a1)+	Stockage des coordonnees
	move.w	d2,(a1)+
	add.w	d6,d5		Angle suivant

	dbra	d7,DoCirc.1
	addq.l	#4,sp		Recupere D1 et D2
	rts


* Cas particulier de la ligne
AO.Line	moveq	#0,d7		Pour Byte -> Word Unsigne
	move.b	(a0)+,d7

	lea	Sommets-8(a4),a5
	lsl.w	#3,d7		Pointe sur les sommets
	movem.w	0(a5,d7.w),d0-d2	Lecture de X,Y,Z
	move.b	(a0)+,d7
	lsl.w	#3,d7
	movem.w	0(a5,d7.w),d3-d5
	move.b	1(a0),d7
	cmp.b	#$F0,d7
	bhs.s	AO.LiCol		Couleur par defaut
	add.w	DefColor(a4),d7
AO.LiCol	and.w	#$F,d7
	move.w	d7,Couleur(a4)

	cmp.w	d2,d5		D2 est le fond
	blt.s	AO.ZClsd
	exg	d0,d3
	exg	d1,d4
	exg	d2,d5

AO.ZClsd	tst.w	d2		Si toute la ligne est derriere
	bmi	AO.ReBad
	tst.w	d5
	bpl.s	AO.IsPos		Il y a quelquechose derriere

	movem.w	d0-d2,-(sp)
	move.w	d0,d7		X1
	sub.w	d3,d7		X1-X2
	muls	d2,d7		D7=(X1-X2)*Z1
	sub.w	d2,d5		D6=Z2-Z1
	divs	d5,d7		d7=-(X1-X2)*Z1/(Z1-Z2)
	add.w	d7,d0		D0=X0

	move.w	d1,d7
	sub.w	d4,d7
	muls	d2,d7
	divs	d5,d7
	add.w	d7,d1		D1=Y0
	moveq	#0,d2		Z=Z0=0
	movem.w	(sp)+,d3-d5

AO.IsPos	movem.w	d3-d5,-(sp)	Trace d'une ligne toute devant
	bsr	Perspect
	move.w	d0,d6
	move.w	d1,d7
	movem.w	(sp)+,d0-d2
	bsr	Perspect
	move.w	d6,d2
	move.w	d7,d3
	move.l	a3,-(sp)
	bsr	Line
	move.l	(sp)+,a3
	bra	AO.ReBad



***************************************************************************
*		Routine de remplissage de facette positive
***************************************************************************
* Entree : D3 : Nombre de sommets
* PolySomm(a4) rempli par les dits sommets

FacFill	move.l	a0,-(sp)
	cmp.w	#2,d3		Trace d'une ligne
	blt.s	FF.End
	beq.s	FF.Line

	lea	PolySomm(a4),a0
	move.w	4(a0),d0		Calcule (12^23)z (produit vect.)
	sub.w	(a0),d0		Ax
	move.w	2(a0),d1
	sub.w	10(a0),d1		By
	muls	d1,d0		D0=Ax*By

	move.w	6(a0),d1
	sub.w	2(a0),d1		Ay
	move.w	(a0),d2
	sub.w	8(a0),d2		Bx
	muls	d2,d1		D1=Ay*Bx

	sub.l	d1,d0
	bgt.s	FF.End		Retour si facette "a l'envers"

FacFill.NonOr:
	btst	#1,Options2(a4)
	bne.s	FF.Lines

	moveq	#0,d1
	moveq	#0,d2		OffSet ecran

	bsr	FillPoly
FF.End	move.l	(sp)+,a0
	rts

* Remplissage avec facettes non orientees
FF.NonOriented:
	move.w	TextColor(a4),Couleur(a4)
	lea	PolySomm(a4),a0
	moveq	#0,d1
	moveq	#0,d2		OffSet ecran
	bra	FillPoly

FF.Line	movem.w	PolySomm(a4),d0-d3
	bsr	Line
	bra.s	FF.End

FF.Lines	lea	PolySomm(a4),a0
	subq.w	#2,d3
	move.w	d3,d7
FF.Lines1	movem.l	a0/d7,-(sp)
	movem.w	(a0),d0-d3
	bsr	Line
	movem.l	(sp)+,a0/d7
	addq.l	#4,a0
	dbra	d7,FF.Lines1
	movem.w	(a0),d0-d1
	movem.w	PolySomm(a4),d2-d3
	bsr	Line
	bra.s	FF.End

***************************************************************************
*		Routine de transformation de coordonnees 
***************************************************************************
* Entree : D0, D1 et D2 contiennent les coordonnees
* Sortie : les memes, en fonction de :
*  Alpha, Beta, Gamma : angles de vision
*  CurX, CurY, CurZ : Positions de l'observateur
*  ObjX, ObjY, ObjZ : Positions de l'objet
*	PAS DE CALCUL DE PERSPECTIVE ICI !
***************************************************************************


TransXYZ	tst.w	UseLocAng(a4)
	beq.s	TXYZ.NoL
	bsr	TriRotateL

TXYZ.NoL	sub.w	CurX(a4),d0	Position relative / observateur
	sub.w	CurY(a4),d1
	sub.w	CurZ(a4),d2
	add.w	ObjX(a4),d0
	add.w	ObjY(a4),d1
	add.w	ObjZ(a4),d2

	bsr.s	TriRotate
	add.w	PosZ(a4),d2
	rts

****************************************************************************
*		Calculs de perspective en fonction des facteurs...
****************************************************************************
* Verifier si pas plus rapide pour les perspectives (2*&2/ Ayayay)
Perspect	move.w	LFactor(a4),d3	Calcul de la perspective
	ext.l	d0
	asl.l	d3,d0
	ext.l	d1
	asl.l	d3,d1
	move.w	KFactor(a4),d3
	add.w	d2,d3
	divs	d3,d0
	divs	d3,d1	

	add.w	PosX(a4),d0	Effectue les decalages ecran
	add.w	PosY(a4),d1
	rts


****************************************************************************
* Triple rotation de d0-d2 selon Alpha, Beta et Gamma (trigo premachee)
****************************************************************************
TriRotate:
	move.w	d0,d6		Rotation autour de OY
	move.w	d2,d7		Sauvegarde X & Z

	muls	CosB(a4),d0	X cos B
	muls	SinB(a4),d2	Z sin B
	sub.l	d2,d0		-
	swap	d0
	add.w	d0,d0		=X

	muls	SinB(a4),d6
	muls	CosB(a4),d7
	add.l	d6,d7
	swap	d7
	add.w	d7,d7
	move.w	d7,d2		=Z

	move.w	d1,d6		Rotation autour de OX
	move.w	d2,d7		Sauvegarde Y & Z

	muls	CosA(a4),d1
	muls	SinA(a4),d2
	sub.l	d2,d1
	swap	d1
	add.w	d1,d1		=Y

	muls	SinA(a4),d6
	muls	CosA(a4),d7
	add.l	d6,d7
	swap	d7
	add.w	d7,d7
	move.w	d7,d2		=Z

	move.w	d0,d6		Rotation autour de OZ
	move.w	d1,d7		Sauvegarde X & Y

	muls	CosC(a4),d0
	muls	SinC(a4),d1
	sub.l	d1,d0
	swap	d0
	add.w	d0,d0		=X

	muls	SinC(a4),d6
	muls	CosC(a4),d7
	add.l	d6,d7
	swap	d7
	add.w	d7,d7
	move.w	d7,d1		=Y

	rts

****************************************************************************
* Triple rotation de d0-d2 selon AlphaL, BetaL et GammaL valeurs locales
****************************************************************************

TriRotateL:
	movem.w	d0-d2,-(sp)	Stocke dans la pile les coords.

	move.w	d0,d5		D5=X1
	move.w	d1,d6		D6=Y1
	move.w	GammaL(a4),d7
	bsr.s	Rotate		Rotation autour de Oz
	move.w	d0,(sp)		Stockage de X2

	move.w	d1,d5		d5=Y2
	move.w	4(sp),d6		D6=Z2=Z1
	move.w	AlphaL(a4),d7
	bsr.s	Rotate		Rotation autour de Ox
	move.w	d0,2(sp)		Stockage de Y3

	move.w	(sp),d5		d5=X3=X2
	move.w	d1,d6		d6=Z3
	move.w	BetaL(a4),d7
	bsr.s	Rotate		Rotation autour de Oy
	move.w	d1,d2		D2=Z
	move.w	2(sp),d1		D1=Y

	addq.l	#6,sp		Restauration pointeur de pile
	rts
	

***************************************************************************
*		Routine de rotation 
***************************************************************************
* Rotation autour d'un axe :
* Entree : D5.w = X,  D6.w = Y
*	 D7.w = Angle de rotation
* Sortie : D0.w = X', D1.w = Y'
*
* Formules utilisees :
* X'= X Cos T - Y Sin T
* Y'= X Sin T + Y Cos T
***************************************************************************

Rotate	move.w	D5,D0	D0=X
	move.w	D6,D1	D1=Y (retour rapide)
	tst.w	d7
	beq.s	Rot.End

	move.w	D7,D1	D1=Alpha
	bsr.s	XCosY	Calcul de X cos T
	move.w	d2,d4

	move.w	d6,d0
	move.w	d7,d1
	bsr.s	XSinY	Calcul de Y sin T
	sub.w	d2,d4	et calcul de la difference
	move.w	d4,-(sp)

	move.w	d5,d0
	move.w	d7,d1
	bsr.s	XSinY	Calcul de X sin T
	move.w	d2,d4

	move.w	d6,d0
	move.w	d7,d1
	bsr.s	XCosY	Calcul de Y cos T
	add.w	d2,d4

	move.w	d4,d1	Stocke Y'
	move.w	(sp)+,d0	et X'

Rot.End	rts



***************************************************************************
*		Routines X*Trig(Y) 
***************************************************************************
* Routine X*COS(Y)
* Entree : D0.W=X, D1.W=Y
* Sortie : D2.W=X*COS(Y)

XCosY	add.w	#256,d1	cos X=sin(X+PI/2)

* Routine X*SIN(Y)
* Entree : D0.W=X, D1.W=Y
* Sortie : D2.W=X*SIN(Y)

XSinY	and.w	#$3FF,d1	Ramene Y modulo 2*PI
	add.w	d1,d1
	lea	SinTab(pc),a0
	move.w	0(a0,d1.w),d2
	muls	d0,d2
	add.l	d2,d2
	swap	d2
	rts


***************************************************************************
*		Initialisation de CosA, SinA, CosB,...
*		et patching des routines .DIR associees
***************************************************************************
* Definition des Macros utilisees dans TrigInit
PatchDir	MACRO	
	lea	\1(pc),a0
	move.w	d3,2(a0)
	move.w	d4,6(a0)
	move.w	d5,10(a0)
	ENDM

TI_Macro	MACRO	
	moveq	#\1,d0
	moveq	#\2,d1
	moveq	#\3,d2
	bsr	TriRotate
	movem.w	d0-d2,-(sp)
	movem.w	(sp)+,d3-d5
	PatchDir	\4P1.Dir
	PatchDir	\4M1.Dir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P2.Dir
	PatchDir	\4M2.Dir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P3.Dir
	PatchDir	\4M3.Dir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P4.Dir
	PatchDir	\4M4.Dir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P5.Dir
	PatchDir	\4M5.Dir
	add.w	d3,d3
	add.w	d4,d4
	add.w	d5,d5
	PatchDir	\4P10.Dir
	PatchDir	\4M10.Dir
	ENDM


LTI_Macro	MACRO	DirX,DirY,DirZ,Name
	moveq	#\1,d0
	moveq	#\2,d1
	moveq	#\3,d2
	bsr	TriRotateL
	bsr	TriRotate
	movem.w	d0-d2,-(sp)
	movem.w	(sp)+,d3-d5
	PatchDir	\4P1.LDir
	PatchDir	\4M1.LDir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P2.LDir
	PatchDir	\4M2.LDir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P3.LDir
	PatchDir	\4M3.LDir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P4.LDir
	PatchDir	\4M4.LDir
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	PatchDir	\4P5.LDir
	PatchDir	\4M5.LDir
	add.w	d3,d3
	add.w	d4,d4
	add.w	d5,d5
	PatchDir	\4P10.LDir
	PatchDir	\4M10.LDir
	ENDM

* Version 'Normale' de l'initialisation
TrigInit	lea	SinTab(pc),a0
	move.w	Alpha(a4),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinA(a4)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosA(a4)

	move.w	Beta(a4),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinB(a4)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosB(a4)

	move.w	Gamma(a4),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinC(a4)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosC(a4)

	TI_Macro	100,0,0,X
	TI_Macro	0,100,0,Y
	TI_Macro	0,0,100,Z

	rts

* Version "Locale" de TrigInit
LTrigInit	lea	SinTab(pc),a0
	move.w	Alpha(a4),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinA(a4)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosA(a4)

	move.w	Beta(a4),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinB(a4)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosB(a4)

	move.w	Gamma(a4),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinC(a4)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosC(a4)

	LTI_Macro	100,0,0,X
	LTI_Macro	0,100,0,Y
	LTI_Macro	0,0,100,Z

	rts


***************************************************************************
*		Routine d'effacement de l'ecran
***************************************************************************
ClsNorm	moveq	#0,d0
	bra.s	Cls2
Cls	moveq	#-1,d0
Cls2	move.l	a4,-(sp)
	move.l	LogScreen(a4),a0
	move.l	d0,d1	Initialisation des differents registres
	move.l	d0,d2
	move.l	d0,d3
	move.l	d0,d4
	move.l	d0,d5
	move.l	d0,d6
	move.l	d0,d7
	movem.l	d1-d6,-(sp)
	movem.l	(sp)+,a1-a6

	lea	32000(a0),a0
	REPT	571
	movem.l	d0-d7/a1-a6,-(a0)	Effacement de 56 octets
	ENDR
	movem.l	d0-d5,-(a0)
	move.l	(sp)+,a4

	btst	#1,Options1(a4)
	beq.s	Cls.1P

	move.l	LogScreen(a4),a0
	lea	160*99(a0),a0
	moveq	#39,d7
Cls.01	move.l	#-1,(a0)+
	clr.l	(a0)+
	dbra	d7,Cls.01

Cls.1P	rts

***************************************************************************
*		Affichage d'etoiles tournoyante
***************************************************************************
NB_STARS	equ	100

Stars	move.w	Couleur(a4),d0
	bsr	PlotColor

	move.w	NStars(a4),d7
	cmp.w	#NB_STARS,d7
	bge.s	Stars.NOk

	lsl.w	#2,d7
	lea	StarsXY(a4),a0
	add.w	d7,a0
	bsr	Random
	move.w	d0,(a0)+		Angle de l'etoile avec l'horizontale
	move.w	Timer(a4),(a0)+	Timer courant
	addq.w	#1,NStars(a4)

Stars.NOk	move.w	NStars(a4),d6
	subq.w	#1,d6
	lea	StarsXY(a4),a6

Stars.1	move.w	Timer(a4),d1	Angle de l'etoile= Sin(T)+A
	move.w	#300,d0
	bsr	XCosY
	add.w	(a6)+,d2
	move.w	d2,d3		Angle actuel de l'etoile

	move.w	Timer(a4),d4
	sub.w	(a6)+,d4
	add.w	d4,d4

	move.w	d3,d1
	move.w	d4,d0
	bsr	XSinY
	move.w	d2,d5

	move.w	d3,d1
	move.w	d4,d0
	bsr	XCosY
	move.w	d2,d0
	move.w	d5,d1

	add.w	PosX(a4),d0
	add.w	PosY(a4),d1

	move.l	a6,-(sp)
	bsr	Plot
	move.l	(sp)+,a6
	beq.s	Stars.2

	bsr	Random
	move.w	d0,-4(a6)		Angle de l'etoile avec l'horizontale
	move.w	Timer(a4),-2(a6)	Timer courant

Stars.2	dbra	d6,Stars.1
	rts



***************************************************************************
*		Trace d'un point seul sur l'ecran
***************************************************************************
* Entree : d0,d1 : Position du point
* Sortie : Si trace, D7=0. Sinon D7=0

Plot	cmp.w	ClipG(a4),d0	Teste le Clipping du point
	blt.s	Plot.Out
	cmp.w	ClipD(a4),d0
	bgt.s	Plot.Out
	cmp.w	ClipH(a4),d1
	blt.s	Plot.Out
	cmp.w	ClipB(a4),d1
	bgt.s	Plot.Out

	tst.w	Resol(a4)
	bne.s	PlotHI

	move.l	LogScreen(a4),a6
	mulu	#160,d1
	add.w	d1,a6
	move.w	d0,d7
	not.w	d7
	and.w	#$F,d7
	asr.w	#1,d0
	and.w	#$FFF8,d0
	add.w	d0,a6
	movem.w	(a6),d0-d3

Plot.Pt	bset	d7,d0
	bne.s	Plot.Col
	bset	d7,d1
	bne.s	Plot.Col
	bset	d7,d2
	bne.s	Plot.Col
	bset	d7,d3
	bne.s	Plot.Col

	movem.w	d0-d3,(a6)
Plot.Col	moveq	#0,d7
	rts

Plot.Out	moveq	#-1,d7
	rts

PlotHI	move.l	LogScreen(a4),a6
	mulu	#160,d1
	add.w	d1,a6
	move.w	d0,d1
	not.w	d1
	and.w	#3,d1
	add.w	d1,d1
	asr.w	#2,d0		4 points -> 1 octet
	add.w	d0,a6

PlotHI.Pt	bset	d1,(a6)

	moveq	#0,d7
	rts

* Fixe la couleur du point
* Entree: d0= Couleur
PlotColor	lea	Plot.Pt(pc),a0
	move.w	#$F80,(a0)		= BCLR D7,D0
	btst	#0,d0
	beq.s	PC.0
	move.w	#$FC0,(a0)		= BSET D7,D0

PC.0	move.w	#$F81,4(a0)
	btst	#1,d0
	beq.s	PC.1
	move.w	#$FC1,4(a0)

PC.1	move.w	#$F82,8(a0)
	btst	#2,d0
	beq.s	PC.2
	move.w	#$FC2,8(a0)
 	
PC.2	move.w	#$F83,12(a0)
	btst	#3,d0
	beq.s	PC.3
	move.w	#$FC3,12(a0)

PC.3	rts


***************************************************************************
*		Trace d'une ligne sur l'ecran
***************************************************************************
* Entree : d0,d1 : Position de depart de la ligne
*	 d2,d3 : Position d'arrivee de la ligne


	
Line	movem.l	d4-d7/a2-a6,-(sp)
	clr.w	ObjetVu(a4)

	cmp.w	d0,d2
	bge.s	Li.AffLNH
	exg	d0,d2
	exg	d1,d3

Li.AffLNH:
	moveq	#0,d4	; c0 = 0	SetCodeClip(x0,y0)
	cmp	ClipG(a4),d0	; x0
	bge.s	Li.c00
	moveq	#1,d4	; c0 = 1
Li.c00	cmp	ClipD(a4),d0	; x0
	ble.s	Li.c01
	or	#2,d4	; c0 |= 2
Li.c01	cmp	ClipH(a4),d1	; y0
	bge.s	Li.c02
	or	#4,d4	; c0 |= 4
Li.c02	cmp	ClipB(a4),d1	; y0
	ble.s	Li.c03
	or	#8,d4	; c0 |= 8
Li.c03	moveq	#0,d5	; c1 = 0	SetCodeClip(x1,y1)
	cmp	ClipG(a4),d2	; x1
	bge.s	Li.c10
	moveq	#1,d5	; c1 = 1
Li.c10	cmp	ClipD(a4),d2	; x1
	ble.s	Li.c11
	or	#2,d5	; c1 |= 2
Li.c11	cmp	ClipH(a4),d3	; y1
	bge.s	Li.c12
	or	#4,d5	; c1 |= 4
Li.c12	cmp	ClipB(a4),d3	; y1
	ble.s	Li.c13
	or	#8,d5	; c1 |= 8
Li.c13	move	d4,d7
	or	d5,d7	; c0 OR c1
	beq	Li.okDessine

Li.cli3	moveq	#3,d6	; bound = 3
	move	d4,d7
	and	d5,d7	; c0 AND c1
	bne	Li.AffLinFin

	move	d4,d7	; c = c0
	bne.s	Li.cli0
	move	d5,d7	; c = c1
Li.cli0	move	ClipB(a4),a3
	btst	d6,d7
	bne.s	Li.inter

	move	ClipH(a4),a3
	subq	#1,d6
	btst	d6,d7
	bne.s	Li.inter

	move	ClipD(a4),a3
	subq	#1,d6
	btst	d6,d7
	bne.s	Li.inter

	move	ClipG(a4),a3
	subq	#1,d6
Li.inter
	movem	d2-d6,-(a7)
	sub	d0,d2	; d2 = x1 - x0
	sub	d1,d3	; d3 = y1 - y0
	btst	#1,d6	; up-down ou left-right
	beq.s	Li.lefrig	; ----------------------------

	move	a3,a1	; Yi = ClipH ou ClipB
	move	a3,d5
	move	a3,d4
	sub	d1,d4	; (frontiere-y0)
	muls	d2,d4	; l = (x1-x0)*(frontiere-y0)
	divs	d3,d4
	add	d0,d4	; Xi = x0 + l / (y1-y0)
	move	d4,a0	; Xi
	bra.s	Li.finint	; -----------------------------

Li.lefrig	move	a3,a0	; Xi = ClipG ou ClipBPoly
	move	a3,d4
	move	a3,d5
	sub	d0,d5	; (frontiere-x0)
	muls	d3,d5	; l = (y1-y0)*(frontiere-x0)
	divs	d2,d5
	add	d1,d5	; Yi = y0 + l/(x1-x0)
	move	d5,a1	; Yi
;		; -----------------------------
Li.finint	moveq	#0,d6	; ci = 0	SetCodeClip(xi,yi)
	cmp	ClipG(a4),d4	; xi
	bge.s	Li.ci0
	moveq	#1,d6	; ci = 1
Li.ci0	cmp	ClipD(a4),d4	; xi
	ble.s	Li.ci1
	or	#2,d6	; ci |= 2
Li.ci1	cmp	ClipH(a4),d5	; yi
	bge.s	Li.ci2
	or	#4,d6	; ci |= 4
Li.ci2	cmp	ClipB(a4),d5	; yi
	ble.s	Li.ci3
	or	#8,d6	; ci |= 8
Li.ci3	move	d6,a6	; ci
	movem	(a7)+,d2-d6	; -----------------------------
	cmp	d7,d4
	bne.s	Li.cli1
	move	a0,d0	; x0 = xi
	move	a1,d1	; y0 = yi
	move	a6,d4	; c0 = ci
	bra.s	Li.cli2

Li.cli1	move	a0,d2	; x1 = xi
	move	a1,d3	; y1 = yi
	move	a6,d5	; c1 = ci
Li.cli2	move	d4,d7
	or	d5,d7
	bne	Li.cli3

Li.okDessine
	tst.w	Resol(a4)
	bne	LineHI
	move	d3,a3	; Y2
	move	d2,a2	; X2
	moveq	#0,d3
	moveq	#0,d2
	move	d1,d3	; Y1
	move	d0,d2	; X1

	move	Couleur(a4),d0	; couleur

	move	#$6,d5	; cte pour accroissement ecran
	move	#160,d6	; cte pour passage a la ligne

	lea	Li.TabProg(pc),a5
	and	#$F,d0
	lsl	#4,d0
	add	d0,a5	; pointe sur instructions F(couleur)

	move	a2,d0
	sub	d2,d0	; ex = x2 - x1
	bge.s	Li.absolux

	neg	d0	; ex = abs(ex)
	exg	d2,a2	; echange x1, x2
	exg	d3,a3	; echange y1, y2

Li.absolux:
	moveq	#1,d4	; pasy positif
	move	a3,d1
	sub	d3,d1	; ey = y2 - y1
	bge.s	Li.absoluy

	neg	d1	; ey = abs(ey)
	neg	d4	; pasy negatif

Li.absoluy:
	move	d0,a0	; a0 = abs(ex)
	move	d1,a1	; a1 = abs(ey)

	move.l	LogScreen(a4),a6

	move	d3,d0
	add	d0,d0	; x 2
	add	d0,d0	; x 4
	add	d3,d0	; x 5
	lsl	#5,d0	; x 160

	move	d2,d1
	and	#$FFF0,d1
	lsr	#1,d1
	add	d1,d0
	add	d0,a6	; pointe sur adresse ecran (gauche)

	moveq	#7,d7
	move	d7,d1
	move	d2,d0	; d0 = x1
	and	d1,d0	; d0 = x1 % 8
	sub	d0,d1	; 1er bit a traiter: 7 - (x1 % 8)

	btst	#3,d2
	beq	Li.pasajust

	moveq	#1,d7
	addq	#1,a6

Li.pasajust
	move	a0,d0	; charge cpt avec ex
	beq	Li.OptiVertical

	cmp	d0,a1	; ex < ey ?
	blt	Li.AffLin3	; en AffLin3 si ex >= ey

	lsr	#1,d0

* ------------------------------------------------------------
* occupation des registres
*	d0: compteur	a0: abs(ex)
*	d1: 1er bit	a1: abs(ey)
*	d2: x1	a2: x2
*	d3: y1	a3: y2
*	d4: dy	a6: libre
*	d5: cte pour toggle	a5: -> programme
*	d6: cte 160	a6: ecran
*	d7: toggle ecran
* ------------------------------------------------------------

	tst	d4
	bpl	Li.AffLin2YpF

*	X = F(Y)

Li.AffLin2YmF:
	lea	Li.AffLin2YmE(pc),a4
	move	(a5)+,(a4)+	; programme
	move.l	(a5)+,(a4)+
	move.l	(a5)+,(a4)+	; programme
	move.l	(a5)+,(a4)+

	sub	a3,d3
	bra	Li.AffLin2YmE

Li.AffLin2Ym:
	sub	d6,a6	; adresse ecran

	add	a0,d0	; cpt += ex
	cmp	a1,d0	; if (cpt < ey)	encore
	blt.s	Li.AffLin2YmE

	sub	a1,d0	; cpt -= ey

	dbra	d1,Li.AffLin2YmE

	moveq	#$7,d1	; recharge
	eor.b	d5,d7
	add	d7,a6

Li.AffLin2YmE:
	bset	d1,(a6)
	bset	d1,2(a6)
	bset	d1,4(a6)
	bset	d1,6(a6)
	dbra	d3,Li.AffLin2Ym

	bra	Li.AffLinFin

; --------------------------------------

Li.AffLin2YpF:
	lea	Li.AffLin2YpE(pc),a4
	move	(a5)+,(a4)+	; programme
	move.l	(a5)+,(a4)+
	move.l	(a5)+,(a4)+	; programme
	move.l	(a5),(a4)

	exg	d3,a3
	sub	a3,d3
	bra	Li.AffLin2YpE

Li.AffLin2Yp:
	add	d6,a6

	add	a0,d0	; cpt += ex
	cmp	a1,d0	; if (cpt < ey)	encore
	blt.s	Li.AffLin2YpE

	sub	a1,d0	; cpt -= ey

	dbra	d1,Li.AffLin2YpE

	moveq	#$7,d1	; recharge
	eor.b	d5,d7
	add	d7,a6

Li.AffLin2YpE:
	bset	d1,(a6)
	bset	d1,2(a6)
	bset	d1,4(a6)
	bset	d1,6(a6)
	dbra	d3,Li.AffLin2Yp	; egal -> on sort

	bra	Li.AffLinFin

* ---------------------------------------
*	Y = F(X)
* ---------------------------------------

Li.AffLin3:
	move	a1,d0	; charge cpt avec ey
	lsr	#1,d0

	tst	d4
	bpl	Li.AffLin3YpF

* ---------------------------------------

	lea	Li.AffLin3YmE(pc),a4
	move	(a5)+,(a4)+	; programme
	move.l	(a5)+,(a4)+
	move.l	(a5)+,(a4)+
	move.l	(a5),(a4)

	exg	d2,a2
	sub	a2,d2
	bra	Li.AffLin3YmE

Li.AffLin3Ym:
	dbra	d1,Li.AffLin3Ym1

	moveq	#$7,d1	; recharge
	eor.b	d5,d7
	add	d7,a6	; add #1/#7

Li.AffLin3Ym1:
	add	a1,d0	; cpt += ey
	cmp	a0,d0	; if (cpt < ex)
	blt.s	Li.AffLin3YmE

	sub	a0,d0	; cpt -= ex
	sub	d6,a6	; ecran -= 160

Li.AffLin3YmE:
	bset	d1,(a6)
	bset	d1,2(a6)
	bset	d1,4(a6)
	bset	d1,6(a6)
	dbra	d2,Li.AffLin3Ym

	bra	Li.AffLinFin

; --------------------------------------

Li.AffLin3YpF:
	lea	Li.AffLin3YpE(pc),a4
	move	(a5)+,(a4)+	; programme
	move.l	(a5)+,(a4)+
	move.l	(a5)+,(a4)+	; programme
	move.l	(a5),(a4)

	exg	d2,a2
	sub	a2,d2
	bra	Li.AffLin3YpE

Li.AffLin3Yp:
	dbra	d1,Li.AffLin3Yp1

	moveq	#$7,d1	; recharge
	eor.b	d5,d7
	add	d7,a6

Li.AffLin3Yp1:
	add	a1,d0	; cpt += ey
	cmp	a0,d0	; if (cpt < ex)
	blt.s	Li.AffLin3YpE

	sub	a0,d0	; cpt -= ex
	add	d6,a6

Li.AffLin3YpE:
	bset	d1,(a6)
	bset	d1,2(a6)
	bset	d1,4(a6)
	bset	d1,6(a6)
	dbra	d2,Li.AffLin3Yp

Li.AffLinFin:
	movem.l (sp)+,d4-d7/a2-a6
	rts

; --------------------------------------

Li.OptiVertical:
	move	#-160,d6

	tst	d4
	bmi.s	Li.OptiVMoins

	neg	d6
	exg	d3,a3

Li.OptiVMoins
	lea	Li.AffLinVert(pc),a4
	move	(a5)+,(a4)+	; programme
	move.l	(a5)+,(a4)+
	move.l	(a5)+,(a4)+
	move.l	(a5)+,(a4)+

	sub	a3,d3

Li.AffLinVert:
	bset	d1,(a6)
	bset	d1,2(a6)
	bset	d1,4(a6)
	bset	d1,6(a6)
	add	d6,a6
	dbra	d3,Li.AffLinVert
	bra	Li.AffLinFin



Li.TabProg:
        bclr    d1,(a6)                 ; plan 0
        bclr    d1,2(a6)                ; plan 1
        bclr    d1,4(a6)                ; plan 2
        bclr    d1,6(a6)                ; plan 3
        nop

        bset    d1,(a6)
        bclr    d1,2(a6)
        bclr    d1,4(a6)
        bclr    d1,6(a6)
        nop

        bclr    d1,(a6)
        bset    d1,2(a6)
        bclr    d1,4(a6)
        bclr    d1,6(a6)
        nop

        bset    d1,(a6)
        bset    d1,2(a6)
        bclr    d1,4(a6)
        bclr    d1,6(a6)
        nop

        bclr    d1,(a6)
        bclr    d1,2(a6)
        bset    d1,4(a6)
        bclr    d1,6(a6)
        nop

        bset    d1,(a6)
        bclr    d1,2(a6)
        bset    d1,4(a6)
        bclr    d1,6(a6)
        nop

        bclr    d1,(a6)
        bset    d1,2(a6)
        bset    d1,4(a6)
        bclr    d1,6(a6)
        nop

        bset    d1,(a6)
        bset    d1,2(a6)
        bset    d1,4(a6)
        bclr    d1,6(a6)
        nop

        bclr    d1,(a6)
        bclr    d1,2(a6)
        bclr    d1,4(a6)
        bset    d1,6(a6)
        nop

        bset    d1,(a6)
        bclr    d1,2(a6)
        bclr    d1,4(a6)
        bset    d1,6(a6)
        nop

        bclr    d1,(a6)
        bset    d1,2(a6)
        bclr    d1,4(a6)
        bset    d1,6(a6)
        nop

        bset    d1,(a6)
        bset    d1,2(a6)
        bclr    d1,4(a6)
        bset    d1,6(a6)
        nop

        bclr    d1,(a6)
        bclr    d1,2(a6)
        bset    d1,4(a6)
        bset    d1,6(a6)
        nop

        bset    d1,(a6)
        bclr    d1,2(a6)
        bset    d1,4(a6)
        bset    d1,6(a6)
        nop

        bclr    d1,(a6)
        bset    d1,2(a6)
        bset    d1,4(a6)
        bset    d1,6(a6)
        nop

        bset    d1,(a6)
        bset    d1,2(a6)
        bset    d1,4(a6)
        bset    d1,6(a6)
        nop
	

***************************************************************************
*		Trace d'une ligne en haute resolution
*			Utilise LineA
***************************************************************************
LineHI	move.l	LineA(a4),a0

	add.w	d0,d0			Adaptation coordonnees
	add.w	d1,d1
	add.w	d2,d2
	add.w	d3,d3
	movem.w	d0-d3,$26(a0)		Composantes X1 Y1 X2 Y2
	move.w	#-1,$18(a0)			Couleur 1 (couleur 1 pour le fond)
	lea	LiHI.Cols(pc),a1		Index du type de ligne
	move.w	Couleur(a4),d0
	add.w	d0,d0
	move.w	0(a1,d0.w),$22(a0)		Ecriture du type de ligne
	not.w	$22(a0)
	clr.w	$24(a0)			Mode REPLACE
	movem.w	ClipG(a4),d0-d3		Recuperation des clips
	add.w	d0,d0
	add.w	d1,d1
	add.w	d2,d2
	add.w	d3,d3
	move.w	d0,$38(a0)
	move.w	d2,$3A(a0)
	move.w	d1,$3C(a0)
	move.w	d3,$3E(a0)
	move.w	#-1,$36(a0)		Indique un clipping
	move.w	#-1,$20(a0)		LastLine (quoi ce etre ?)

	dc.w	$A003			opCode Line
	movem.l	(sp)+,d4-d7/a2-a6
	rts

LiHI.Cols	dc.w	$FFFF,$FFFE,$FFFC,$FFF8
	dc.w	$7777,$7776,$7774,$7772
	dc.w	$AAAA,$A5A5,$A55A,$AAA5
	dc.w	$1F1F,$1A1A,$5F5F,$1010



***************************************************************************
*		Permutation d'ecran
***************************************************************************
SwapScrn	move.l	Other(a4),a5
	btst	#1,Options1(a4)
	bne.s	SwS.Mono
	move.l	BackColor(a4),BackColor(a5)
	movem.l	CurColor(a4),d0-d7
	movem.l	d0-d7,CurColor(a5)

SwS.Mono	move.w	Timer(a4),d0
	and.w	#3,d0
	bne.s	SwS.NoCol
	move.l	BackColor(a4),CurColor(a4)
	move.l	BackColor(a5),CurColor(a5)
SwS.NoCol	movem.l	LogScreen(a4),a0-a1
	exg	a0,a1
	movem.l	a0-a1,LogScreen(a4)
	movem.l	a0-a1,LogScreen(a5)
	move.l	a0,$44E.w

	move.l	a1,d1
	asr.l	#8,d1		Effectue le stockage ecran
	lea	$FFFF8201.w,a1
	movep.w	d1,(a1)
	
	XBIOS	37,2

	rts


***************************************************************************
*		Initialisation
***************************************************************************
* Keyword #INIT
Init	move.l	a7,a5		Recupere l'adresse de la pile
	move.l	#Vars-Start,d0
	lea	Start(pc),a4
	add.l	d0,a4		a4 pointe sur VARS
	lea	TabVisit-Vars(a4),a6
	move.l	a6,TabVisitAd(a4)	Initialisation de l'adresse de TabVisit

	lea	Pile-Vars(a4),sp	SP pointe sur la pile

	move.l	#Screen-Vars,d0	Initialisation des adresses pointeurs
	lea	0(a4,d0.l),a0
	lea	TScreen-Screen(a0),a1
	add.l	#256,a0
	move.l	a0,d0
	and.l	#$FFFFFF00,d0
	move.l	d0,PhyScreen(a4)
	add.l	#32000,d0
	move.l	d0,Screen2Ad(a4)
	move.l	a1,AdTScreen(a4)
	move.l	#IntroTxt-Vars,d0
	lea	0(a4,d0.l),a0
	move.l	a0,AdIntroTxt(a4)

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

	clr.l	-(sp)
	GEMDOS	$20,6		Super : Passage en superviseur
	move.l	d0,SpareUSP(a4)

	XBIOS	3,2
	move.l	d0,LogScreen(a4)	et physique
	move.l	d0,DefScreen(a4)

	XBIOS	4,2
	move.w	d0,OldResol(a4)
	cmp.w	#1,d0
	bne.s	Init.NoMed
	clr.w	-(sp)
	pea	-1.w
	pea	-1.w
	XBIOS	5,12
	moveq	#0,d0
Init.NoMed:
	move.w	d0,Resol(a4)

* Initialisation des joysticks et suppression de la souris
	dc.w	$a00a		Cache la souris

	pea	InitMouse(pc)
	move.w	#2,-(sp)
	XBIOS	25,8

	XBIOS	34,2		KBD vbase
	move.l	d0,a0
	move.l	16(a0),OldMsVec(a4)	Stocke l'ancien vecteur
	lea	MyMsVec(pc),a1
	move.l	a1,16(a0)		Stocke le nouveau vecteur

	move.l	24(a0),OldJoyst(a4)
	lea	MyJoyVec(pc),a1
	move.l	a1,24(a0)

	move.l	$118.w,$98.w	Ecriture de la vieille interruption comme TRAP #6
	lea	IKInt(pc),a1
	move.l	a1,$118.w

	move.w	#1,InputDev(a4)	Choisit le clavier comme entree

	move.l	$404.w,OldEtvCritic(a4)	Critical Error Handler pour disques
	lea	CriticalErrorHandler(pc),a0
	move.l	a0,$404.w

	dc.w	$A000		Initialisation LineA
	move.l	a0,LineA(a4)

ObjTabRef	move.l	#0+ObjTab-ObjTabRef,a0	Initialisation de l'adresse des tableaux
	lea	ObjTabRef(pc,a0.l),a0
	move.l	a0,AdObjTab(a4)

	and.b	#$FC,$484.w		Suppression du click clavier et du Repeat
	clr.w	Joueur(a4)		Indique que les sprites sont actifs (1 joueur)
	clr.w	FastFill(a4)	Remplissage normal
	clr.w	Options1(a4)	Retour au centre automatique et jeu a 2

	clr.l	SoundPtr+0.w		Pas de sauvegarde des registres pour le prochain son
	move.l	#MoveMemry-Vars,d0
	lea	0(a4,d0.l),a0
	move.l	a0,MoveMemAd(a4)
	lea	FinMvMemry-MoveMemry(a0),a0
	move.l	a0,EndMvMem(a4)

	lea	TabFileName(pc),a0
	bsr	LoadFile
	move.l	a0,Tableaux(a4)
	lea	ScreenFileName(pc),a0
	bsr	LoadFile
	move.l	a0,BckScreen(a4)
	lea	ScoresFileName(pc),a0
	bsr	LoadFile
	move.l	a0,AdScores(a4)

	clr.l	MusicAd(a4)	Pas de musique a priori
	clr.l	MusicPtr+0.w	Indique "On ne joue pas de musique"

	pea	-1.w		teste la memoire disponible
	GEMDOS	$48,6
	cmp.l	#300*1024,d0	Si plus de 300K, on a au moins un 1040
	ble.s	Init.NoMusic
	move.l	#200*1024,-(sp)
	GEMDOS	$48,6
	move.l	d0,MusicAd(a4)

	move.l	d0,a6		Adresse de depart du tampon
	moveq	#1,d7		Piste de depart
Init.LoadMusic:
	move.w	#9,-(sp)		Lire 9 secteurs
	move.w	#1,-(sp)		Face 1
	move.w	d7,-(sp)		Piste d7
	move.w	#1,-(sp)		A partir du secteur 1
	clr.w	-(sp)		Unite A:
	clr.l	-(sp)		Mot de remplissage
	move.l	a6,-(sp)		Pointeur sur le tampon
	move.w	#8,-(sp)
	trap	#14		Floppy Read
	lea	20(sp),sp

	lea	9*512(a6),a6
	addq.w	#1,d7
	cmp.w	#44,d7
	bne.s	Init.LoadMusic

Init.NoMusic:
	clr.w	STisSTE(a4)	A priori pas un STE
	cmp.w	#$E0,$400.w	Sauf si vecteurs pointent en E0
	seq	STisSTe(a4)

	tst.w	Resol(a4)		Si en haute resolution, convertit l'image
	bne.s	Init.HiRes

	movem.l	$FFFF8240.w,d0-d7
	movem.l	d0-d7,CurColor(a4)
	movem.l	d0-d7,BackColor(a4)
	move.l	Other(a4),a5
	movem.l	d0-d7,CurColor(a5)
	movem.l	d0-d7,BackColor(a5)
	bsr	SetHAM

Init.HiRes:
* Initialisation des variables joueur2
	lea	DataLen(a4),a5	Pointe sur Vars2
	move.l	a4,a0
	move.l	a5,a1
Init.CpVars:
	move.w	(a0)+,(a1)+	Copie les variables initialisees
	cmp.l	a5,a0
	blt.s	Init.CpVars

	move.l	a4,Other(a5)	Chaque Other pointe sur l'autre groupe de variables
	move.l	a5,Other(a4)
	move.w	#1,Joueur(a5)	Indique no de joueur
	move.w	#2,InputDev(a5)

* Effacement des Joysticks
	lea	Joystick1(pc),a0
	clr.w	(a0)+
	clr.w	(a0)+

	bra	Main


TabFileName:
	dc.b	"TABLIB.QB",0
ScreenFileName:
	dc.b	"CUBE.PI1",0
ScoresFileName:
	dc.b	"HISCORES.QB",0

****************************************************************************
*	Chargement de fichier sur disque
****************************************************************************
* Entree : A0= Pointeur sur le nom du fichier
* Sortie : A0= Pointeur sur le fichier charge
* Il y a pas interet a ce qu'il y ait une erreur
LoadFile	move.l	a0,a5	Sauvegarde a0
	clr.w	-(sp)	Acces normal
	move.l	a0,-(sp)	Indique le nom du fichier
	GEMDOS	$4E,8	SEEK FIRST

	GEMDOS	$2F,2	Recupere l'adresse de DTA
	move.l	d0,a0
	move.l	26(a0),d5	Recupere la longueur du fichier

	move.l	d5,-(sp)	Indique que l'on veut recuperer ces octets
	GEMDOS	$48,6	MALLOC
	move.l	d0,a6	Recupere l'adresse de transfert

	clr.w	-(sp)	En lecture seulement
	move.l	a5,-(sp)	Adresse du nom de fichier
	GEMDOS	$3D,8	OPEN

	move.w	d0,-(sp)
	move.l	a6,-(sp)	Adresse du chargement
	move.l	d5,-(sp)	Longueur a lire
	move.w	d0,-(sp)
	GEMDOS	$3F,12	READ

	GEMDOS	$3E,4	CLOSE (le handle est dans la pile)

	move.l	a6,a0	Adresse de la zone ou le fichier a ete charge
	rts


****************************************************************************
*		Initialisation partielle en debut de partie
****************************************************************************
* Keyword #MINI
MiniInit	clr.w	Alpha(a4)		Initialisation des registres de position
	clr.w	Beta(a4)
	clr.w	Gamma(a4)
	clr.w	BetaSpeed(a4)	Pas de rotation automatique

	clr.w	CurX(a4)
	btst	#1,Options1(a4)
	beq.s	MI.Only1P
	move.w	Joueur(a4),d0
	lsl.w	#8,d0
	lsl.w	#5,d0
	sub.w	#4096,d0
	move.w	d0,CurX(a4)	Initialisation des positions
MI.Only1P	move.w	#-7900,CurY(a4)
	clr.w	CurZ(a4)
	clr.w	SpeedX(a4)
	clr.l	SpeedY(a4)
	clr.l	SpeedX0(a4)

	clr.w	Seed(a4)		Initialisation du generateur aleatoire
	clr.l	TimerL(a4)	Indispensable pour la reproductibilite des parties

	move.l	$4BA,d0
	add.l	#3*200*60,d0	Temps de jeu: 5 mn au debut
	move.l	d0,SysTime0(a4)
	clr.w	ExtraTime(a4)

	clr.l	WhichBonus(a4)	Pas de Bonus ni de diamants
	clr.w	WhichDiamond(a4)
	clr.w	WhichProtect(a4)

	move.l	MoveMemAd(a4),a0	Initialise le pointeur de lecture
	move.l	a0,MovePtr(a4)
	IFNE	DEMO_REC
	tst.w	InputDev(a4)
	bmi.s	MI.KeepMvMem
	move.l	a0,EndMvMem(a4)
MI.KeepMvMem:
	ENDC

	clr.w	VaissNum(a4)	Vaisseau
	tst.w	Joueur(a4)
	bne.s	MI.NoLODM

	clr.b	Options2(a4)	Option par defaut pour la demo

	tst.w	InputDev(a4)
	bmi.s	MI.NoLODM

	bsr	LitOptionsDuMenu	Coherence entre options du menu et lecture

MI.NoLODM	move.l	TabVisitAd(a4),a0
	move.w	#NTABS/4-1,d0
MI.ClrTab	clr.l	(a0)+
	dbra	d0,MI.ClrTab

	lea	Score(pc),a0
	move.l	#'0000',(a0)+
	move.l	#'0000',(a0)+
	clr.w	ToScore(a4)

	lea	Score2(pc),a0
	move.l	#'0000',(a0)+
	move.l	#'0000',(a0)+

	clr.w	JSuisMort(a4)

	clr.w	Inact(a4)
	btst	#0,Options1(a4)	Teste si on est en mode emotion
	bne.s	MI.TabInitialise
	clr.w	Tableau(a4)
	cmp.l	#$05121968,$202.w
	bne.s	MI.TabInitialise
	move.w	$200.w,Tableau(a4)
	and.w	#NTABS-1,Tableau(a4)
MI.TabInitialise:
	move.w	#-1,InvertLine(a4)

PlayerSet	tst.w	Joueur(a4)
	bne.s	PSet.End
	tst.w	InputDev(a4)
	bmi	ClipForDemo

	btst	#1,Options1(a4)	Teste si jeu a 2
	bne.s	TwoPlayrs

OnePlayer	move.w	#160,PosX(a4)
	move.w	#100,PosY(a4)
	move.w	#900,PosZ(a4)
	move.w	#0,ClipH(a4)
	move.w	#199,ClipB(a4)
	move.w	#0,ClipG(a4)
	move.w	#319,ClipD(a4)

	move.w	#500,KFactor(a4)
	move.w	#7,LFactor(a4)

PSet.End	rts

TwoPlayrs	move.w	#160,PosX(a4)
	move.w	#50,PosY(a4)
	move.w	#900,PosZ(a4)
	move.w	#0,ClipH(a4)
	move.w	#98,ClipB(a4)
	move.w	#0,ClipG(a4)
	move.w	#319,ClipD(a4)

	move.w	#1000,KFactor(a4)
	move.w	#7,LFactor(a4)
	
	move.l	Other(a4),a5
	move.w	#160,PosX(a5)
	move.w	#150,PosY(a5)
	move.w	#900,PosZ(a5)
	move.w	#101,ClipH(a5)
	move.w	#199,ClipB(a5)
	move.w	#0,ClipG(a5)
	move.w	#319,ClipD(a5)

	move.w	#1000,KFactor(a5)
	move.w	#7,LFactor(a5)
	rts

ClipForDemo:
	move.w	#80,PosX(a4)
	move.w	#80,PosY(a4)
	move.w	#900,PosZ(a4)
	move.w	#0,ClipH(a4)
	move.w	#160,ClipB(a4)
	move.w	#0,ClipG(a4)
	move.w	#160,ClipD(a4)

	move.w	#1000,KFactor(a4)
	move.w	#7,LFactor(a4)

	move.l	Other(a4),a5		Specification de clip demo
	move.w	#240,PosX(a5)
	move.w	#80,PosY(a5)
	move.w	#900,PosZ(a5)
	move.w	#0,ClipH(a5)
	move.w	#160,ClipB(a5)
	move.w	#161,ClipG(a5)
	move.w	#319,ClipD(a5)
	move.w	#1000,KFactor(a5)
	move.w	#7,LFactor(a5)

	rts

InitMouse	dc.b	$14,$12
***************************************************************************
*	Interruption de lecture du clavier et des Joysticks
***************************************************************************
IKInt	trap	#6
	movem.l	d0-d2/a0-a1,-(sp)

* Routine appellee au retour de l'interruption clavier
IK.Ret	move.b	$FFFFFC02.w,d0
	cmp.b	#$F6,d0		Si c'est un code de controle
	bhi.s	IK.TheEnd
	move.b	d0,d1
	and.w	#$7F,d1

	lea	Touches(pc),a0	sinon, trouver l'index correspondant
	moveq	#7,d2
IKInt.2	cmp.b	(a0)+,d1
	beq.s	IKInt.F
	dbra	d2,IKInt.2

	bra.s	IK.TheEnd

IKInt.F	lea	Keyboard(pc),a1	Et mettre le bit correspondant
	tst.b	d0
	bmi.s	IK.Rel		soit a 0
	bset	d2,(a1)		soit a 1
	bra.s	IK.TheEnd
IK.Rel	bclr	d2,(a1)

IK.TheEnd	movem.l	(sp)+,d0-d2/a0-a1
	rte

Touches	dc.b	$39,$00,0,0,$4D,$4b,$50,$48

	dc.l	0
	dc.l	0	Stockage des valeurs pour l'automatique
Joystick1	dc.b	0
Joystick2	dc.b	0
Keyboard	dc.w	0
MouseK	dc.w	0
MouseX	dc.w	0
MouseY	dc.w	0
JoyM1	dc.b	0,0
JoyM2	dc.b	0,0

MouseM	dc.l	0,0,0,0

****************************************************************************
*		Routines d'interruption souris/clavier
****************************************************************************
MyJoyVec	lea	Joystick1(pc),a1
	addq.l	#1,a0
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+

MJV.end	rts

MyMsVec	lea	MouseK(pc),a1
	move.b	(a0)+,d0
	and.w	#$3,d0
	move.w	d0,(a1)+

	move.b	(a0)+,d0		Lecture des Dx et Dy
	move.b	(a0)+,d1
	ext.w	d0
	ext.w	d1		Mise au format mot

	add.w	(a1),d0		Verification que sur l'ecran    
	bpl.s	MS.XPos
	moveq	#0,d0
MS.XPos	cmp.w	#319-16,d0
	ble.s	MS.XNeg
	move.w	#319-16,d0
MS.XNeg	move.w	d0,(a1)+

	add.w	(a1),d1
	bpl.s	MS.YPos
	moveq	#0,d1
MS.YPos	cmp.w	#199-16,d1
	ble.s	MS.YNeg
	move.w	#199-16,d1
MS.YNeg	move.w	d1,(a1)+

	rts

****************************************************************************
*		Routines de trace de la souris
****************************************************************************
DessineMouse	lea	MouseX(pc),a0
	move.w	(a0)+,d4		Lecture des coordonnee
	move.w	(a0)+,d0

	move.w	d0,d2
	add.w	d0,d0		*2
	add.w	d0,d0		*4
	add.w	d2,d0		*5
	lsl.w	#5,d0		*160	Offset de ligne

	move.w	d4,d2
	and.w	#$FFF0,d2		Numero du mot
	asr.w	#1,d2		Position en octets
	add.w	d2,d0		Ajoute a l'offset

	move.l	LogScreen(a4),a0
	lea	0(a0,d0.w),a0
	lea	Souris.Des(pc),a1
	moveq	#15,d7

	neg.w	d4
	and.w	#$000F,d4
	beq.s	DM.FullWrd

DM.Ligne	moveq	#-1,d6
	move.w	(a1)+,d6		Lecture du masque
	rol.l	d4,d6
	swap	d6

	moveq	#0,d5		Lecture de la donnee
	move.w	(a1)+,d5
	lsl.l	d4,d5
	swap	d5

	and.w	d6,(a0)
	or.w	d5,(a0)+
	and.w	d6,(a0)+
	and.w	d6,(a0)+
	and.w	d6,(a0)+

	swap	d6
	swap	d5
	and.w	d6,(a0)
	or.w	d5,(a0)+
	and.w	d6,(a0)+
	and.w	d6,(a0)+
	and.w	d6,(a0)+
	lea	160-16(a0),a0
	dbra	d7,DM.Ligne

	rts

DM.FullWrd:
	movem.w	(a1)+,d5-d6
	and.w	d5,(a0)
	or.w	d6,(a0)+
	and.w	d5,(a0)+
	and.w	d5,(a0)+
	and.w	d5,(a0)+
	lea	160-8(a0),a0
	dbra	d7,DM.FullWrd

	rts

Souris.Des:
	dc.w	%0011111111111111,%0000000000000000	0
	dc.w	%0001111111111111,%0100000000000000	1
	dc.w	%0000111111111111,%0110000000000000	2
	dc.w	%0000011111111111,%0101000000000000	3
	dc.w	%0000001111111111,%0100100000000000	4
	dc.w	%0000000111111111,%0100010000000000	5
	dc.w	%0000000011111111,%0100001000000000	6
	dc.w	%0000000001111111,%0100000100000000	7
	dc.w	%0000000000111111,%0100000010000000	8
	dc.w	%0000000000011111,%0100000001000000	9
	dc.w	%0000000000001111,%0100000000100000	A
	dc.w	%0000000000000111,%0111100111110000	B
	dc.w	%0000000000000111,%0000100100000000	C
	dc.w	%1110000001111111,%0000010010000000	D
	dc.w	%1111000000111111,%0000011110000000	E
	dc.w	%1111000000111111,%0000000000000000	F


****************************************************************************
*		Routines de trace des icones
****************************************************************************
* Entree: D0: Numero de l'icone
*	D1: Position horizontale de l'icone
* Pour DessineCIcon seulement
*	D2: Taux de compression de l'icone (1,2,4 ou 8)
*	D3: Position de l'icone sur l'ecran (0,4,6,7)
* Variantes:
*  DessineDIcon: Icone qui se ferme
*  DessineIIcon: Icone qui s'ouvre
	IFEQ	1
DessineIC	MACRO
	XBIOS	37,2
	movem.w	(sp),d0-d1
	moveq	#\1,d2
	moveq	#\2,d3
	bsr	DessineCIcon
	ENDM

DessineDIcon	movem.w	d0-d1,-(sp)
	DessineIC	1,0
	DessineIC	2,4
	DessineIC	4,6
	DessineIC	8,7
	movem.w	(sp)+,d0-d1
	rts

DessineIIcon	movem.w	d0-d1,-(sp)
	DessineIC	8,7
	DessineIC	4,6
	DessineIC	2,4
	DessineIC	1,0
	movem.w	(sp)+,d0-d1
	rts

DessineIcon	moveq	#1,d2
	moveq	#0,d3
DessineCIcon	move.l	LogScreen(a4),a0	Calcule la position ecran d'affichage
	move.w	d1,d7
	lsl.w	#3,d7
	lea	0(a0,d7.w),a0
	lea	29440(a0),a0

	lea	DessineCIcon(pc),a1	Calcule l'adresse de l'icone
	add.l	#TheIcons-DessineCIcon,a1
	lsl.w	#7,d0
	lea	0(a1,d0.w),a1

	tst.w	d3		Teste si position sur l'ecran non nulle
	beq.s	DCI.NoCp		Pas de compression

	mulu	#160,d3		Position sur ecran du point de depart
	lea	0(a0,d3.w),a2

	moveq	#15,d7		Effacement du fond
DCI.1	clr.l	(a0)+
	clr.l	(a0)+
	lea	160-8(a0),a0
	dbra	d7,DCI.1
	move.l	a2,a0		Recupere le point de depart sur ecran

DCI.NoCp	moveq	#15,d7		Compteur de lignes Icone
	move.w	d2,d6		Calcul du decalage
	lsl.w	#3,d6
DCI.2	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	lea	160-8(a0),a0	Pointe sur la position ecran suivante
	lea	-8(a1,d6.w),a1	Pointe sur la position icone suivante
	sub.w	d2,d7
	bpl.s	DCI.2		Bouclage

	move.l	LogScreen(a4),a0	Assure la coherence entre les ecrans
	move.l	PhyScreen(a4),a1
	lea	29440(a0),a0
	lea	29440(a1),a1
	move.w	#639,d7
DCI.3	move.l	(a0)+,(a1)+
	dbra	d7,DCI.3

	rts

****************************************************************************
*		Affichage de tous les icones
****************************************************************************
DessineIcons	moveq	#6,d7		Compteur de bits
DIS.1	move.w	d7,-(sp)
	move.w	d7,d1
	move.w	d7,d0
	add.w	d0,d0
	btst	d7,Options2(a4)
	beq.s	DIS.Zero
	addq.w	#1,d0
DIS.Zero	bsr	DessineIcon
	move.w	(sp)+,d7
	dbra	d7,DIS.1

	moveq	#10,d7
	moveq	#7,d1
DIS.2	moveq	#Null.X,d0
	movem.w	d1/d7,-(sp)
	bsr	DessineIcon
	movem.w	(sp)+,d7/d1
	addq.w	#1,d1
	dbra	d7,DIS.2

	moveq	#Death.X,d0
	moveq	#18,d1
	bsr	DessineIcon
	moveq	#NMap.X,d0
	moveq	#17,d1
	bsr	DessineIcon
	moveq	#NWait.X,d0
	moveq	#16,d1
	bsr	DessineIcon

	moveq	#YNull.X,d0
	moveq	#15,d1
	bsr	DessineIcon
	moveq	#NNull.X,d0
	moveq	#7,d1
	bsr	DessineIcon

	lea	TabName(pc),a0	Affichage du nom du tableau
	move.l	LogScreen(a4),a1
	lea	160*188+56(a1),a1
	bsr	FastPrt
	moveq	#Disk.X,d0
	moveq	#19,d1
	bra	DessineIcon

	ENDC

****************************************************************************
*		Routines de gestion du son sous interruption
****************************************************************************
* SoundPtr+0 (INT1) est utilise comme adresse des sons a jouer
* La routine de reproduction est patchee pour determiner la fin du son a jouer
*		ROUTINES AIMABLEMENT FOURNIES PAR
*			ST-REPLAY (C) 2-Bits Systems

* Entree :
* A0 : Adresse du son a jouer
* D0 : Fin du son

MFP	EQU	$FFFFFA00
IERA	EQU	MFP+$07
IERB	EQU	MFP+$09
IPRA	EQU	MFP+$0B
ISRA	EQU	MFP+$0F
IMRA	EQU	MFP+$13
IMRB	EQU	MFP+$15
VECTOR	EQU	MFP+$17
TACR	EQU	MFP+$19
TBCR	EQU	MFP+$1B
TADR	EQU	MFP+$1F
TBDR	EQU	MFP+$21

ISRVEC	EQU	$134
TBVEC	EQU	$100+8*4
*
*	THE SOUND CHIP
*
SCREG	EQU	$FFFF8800	CHIP REGISTER SELECT
SCDATA	EQU	$FFFF8802	REGISTER DATA


*******************************************************************************
*
*	Routine de gestion des interruptions couleur
*
*******************************************************************************
SetHAM	lea	HBLInter1(pc),a0	fixe le vecteur pour Tmr B
	move.l	TBVEC+0.w,TBVEC.Old(a4)
	move.l	a0,TBVEC+0.w

	lea	HBLInter1(pc),a0	fixe le vecteur pour Tmr B
	move.l	a0,TBVEC+0.w

	lea	VBLInter(pc),a0	Fixe l'interruption de retour ecran
	move.l	$70.w,VBLJump+2-VBLInter(a0)
	move.l	a0,$70.w

	move.b	TBCR+0.w,TBCR.Old(a4)
	move.b	TBDR+0.w,TBDR.Old(a4)
	move.b	#8,TBCR+0.w	Event count mode sur B
	move.b	#130,TBDR+0.w	Toutes les 20 lignes

	move.b	IERA+0.w,IERA.Old(a4)
	move.b	IMRA+0.w,IMRA.Old(a4)
	move.b	VECTOR+0.w,VECTOR.Old(a4)
	bset	#0,IERA+0.w	Autorise les interruptions sur le Tmr B
	bset	#0,IMRA+0.w
	bclr.b	#3,VECTOR+0.w	Auto End of Int

	rts

* Supprime le changement de palette en lignes
ClearHAM	move.b	VECTOR.Old(a4),VECTOR+0.w
	move.b	IMRA.Old(a4),IMRA+0.w
	move.b	IERA.Old(a4),IERA+0.w
	move.b	TBDR.Old(a4),TBDR+0.w
	move.b	TBCR.Old(a4),TBCR+0.w
	move.l	TBVEC.Old(a4),TBVEC+0.w

	lea	VBLInter(pc),a0	Restaure la VBL
	move.l	VBLJump+2-VBLInter(a0),$70.w

	rts


HBLInter1	movem.l	d0-d7/a4,-(sp)
	lea	HBLInter1(pc),a4
	add.l	#Vars2-HBLInter1,a4

	movem.l	CurColor(a4),d0-d7
	lea	$FFFF8240.w,a4
	movem.l	d0-d7,(a4)
	movem.l	(sp)+,d0-d7/a4
	rte


VBLInter	move.b	#0,TBCR+0.w
	move.b	#100,TBDR+0.w
	move.b	#8,TBCR+0.w

	movem.l	d0-d7/a4,-(sp)
	lea	VBLInter(pc),a4
	add.l	#Vars-VBLInter,a4
	movem.l	CurColor(a4),d0-d7
	lea	$FFFF8240.w,a4
	movem.l	d0-d7,(a4)

	movem.l	(sp)+,d0-d7/a4

VBLJump	jmp	0

*******************************************************************************
* Routine PlaySound
* Entree:
*  D6: Sample a jouer
*  D7: Vitesse a laquelle le jouer
*******************************************************************************

MusicScore:
	dc.w	0,1,0,2,0,1,3,4,5,4,5,0,1,0,2,6,7,8,0,1,0,2,4,5,4,5,2,-1
InstallMusic:
	move.w	#$80,$FFFF8920.w
	lea	MusicVBL(pc),a1
	bra	InstallVBL

MusicVBL	btst	#0,$FFFF8901.w
	bne.s	MVBL.Rte

	move.l	MusicPtr+0.w,a0
	move.w	(a0)+,d0
	bpl.s	MVBL.Rep
	lea	MusicScore(pc),a0
	move.w	(a0)+,d0

MVBL.Rep	move.l	a0,MusicPtr+0.w	Stocke le pointeur sur les musiques
	lsl.w	#2,d0
	lea	PS.PatchS(pc),a0
	add.l	#Vars+MusicAd-PS.PatchS,a0
	move.l	(a0),a0		Recupere le pointeur sur les musiques

	move.l	0(a0,d0.w),d0	Et pret pour la musique suivante
	lea	0(a0,d0.l),a0
	move.l	(a0)+,d0		On a trouve le bon son
	add.l	a0,d0
	subq.l	#6,d0		On arrete un peu avant si le fichier a une longueur impaire

	move.b	d0,$FFFF8913.w
	asr.l	#8,d0
	move.b	d0,$FFFF8911.w
	asr.l	#8,d0
	move.b	d0,$FFFF890F.w

	move.l	a0,d0
	move.b	d0,$FFFF8907.w
	asr.l	#8,d0
	move.b	d0,$FFFF8905.w
	asr.l	#8,d0
	move.b	d0,$FFFF8903.w

	move.w	#1,$FFFF8900.w

MVBL.Rte	rts

PlayMusic	tst.l	MusicPtr+0.w	Si on joue deja la musique...
	bne.s	PS.PasSon

	move.l	MusicAd(a4),a6
	move.l	a6,d0
	beq.s	PS.PasSon		Si la musique n'a pas pu etre chargee

	lea	MusicScore(pc),a0
	move.l	a0,MusicPtr+0.w
	tst.w	STisSTE(a4)
	bne	InstallMusic
	move.w	(a0)+,d6
	move.l	a0,MusicPtr+0.w

	lea	PS.PatchJ+1(pc),a0
	move.b	#PS.PatchS-PS.Repeat,(a0)

	bra.s	PS.Entry

PlaySound	lea	TheSounds(pc),a6
	lea	PS.PatchJ+1(pc),a0		Patche le code pour EXIT
	move.b	#PS.ExitN-PS.Repeat,(a0)
	clr.l	MusicPtr+0.w

PS.Entry	btst	#6,Options2(a4)
	bne.s	PS.PasSon
	tst.w	d6
	bmi.s	PS.PasSon

	tst.w	Joueur(a4)
	beq.s	PS.Playr1
	move.l	Other(a4),a4	Si jamais sur le mauvais joueur
	bsr.s	PS.Playr1
	move.l	Other(a4),a4
PS.PasSon	rts

PS.Playr1	tst.l	SoundPtr+0.w
	beq.s	PS.RienEnCours
	move.w	#$2700,SR
	move.l	a4,a0
	bsr	OLDMFP		Restaure les anciens MFP

PS.RienEnCours:
	move.l	a6,a0	Recherche du bon son
	lsl.w	#2,d6
	move.l	0(a0,d6.w),d6
	lea	0(a0,d6.l),a0

	move.l	(a0)+,d0		On a trouve le bon son
	move.l	a0,SoundPtr+0.w	Stocke l'adresse du son a jouer

	add.l	a0,d0
	subq.l	#6,d0		On arrete un peu avant si le fichier a une longueur impaire
	lea	PS.PatchE+2(pc),a0	Patche l'adresse de fin (W)
	move.l	d0,(a0)

	BSR	SAVEMFP		SAVE NATURAL MFP CONDITIONS
	MOVE.W	#$2700,SR
	BSR	SETFREQ
	lea	PS.Inter(pc),a0
	bsr	SETINT
	BSR	SETSND		SET UP SOUND REGISTERS
	BSR	ENABMFP		SET THE MFP RUNNING
	MOVE.W	#$2300,SR		ENABLE THE INTERRUPTS
PS.Ret	rts



*****************************************
*	THE SYSTEM SUB-ROUTINES	 *
*****************************************
*****************************************
*	PRESERVE THE MFP REGISTERS	*
*****************************************

SAVEMFP	MOVE.B	IERA+0.w,MFPMEM(a4)	PUSH CURRENT MFP DATA
	MOVE.B	IERB+0.w,MFPMEM+1(a4)
	MOVE.B	IMRA+0.w,MFPMEM+2(a4)
	MOVE.B	IMRB+0.w,MFPMEM+3(a4)
	MOVE.B	TADR+0.w,MFPMEM+4(a4)
	MOVE.B	TACR+0.w,MFPMEM+5(a4)
	MOVE.B	VECTOR+0.w,MFPMEM+6(a4)
	RTS

*****************************************
*	REPLACE NATURAL RUNNING MFP VALUES	*
*****************************************



OLDMFP	MOVE.B	MFPMEM+6(a0),VECTOR+0.w	RESTORE OLD MFP VALS
	MOVE.B	MFPMEM+5(a0),TACR+0.w
	MOVE.B	MFPMEM+4(a0),TADR+0.w
	MOVE.B	MFPMEM+3(a0),IMRB+0.w
	MOVE.B	MFPMEM+2(a0),IMRA+0.w
	MOVE.B	MFPMEM+1(a0),IERB+0.w
	MOVE.B	MFPMEM(a0),IERA+0.w
	RTS

*****************************************
*	CHOOSE INTERRUPT VECTOR	 *
*****************************************
*
*	 SET UP SELECTED INTERRUPT WITH A0.L
*   CONTAINING THE NEW ROUTINE VECTOR.
*
SETINT	MOVE.W	SR,D0		SAVE SYSTEM STATUS
	MOVE.W	#$2700,SR		INTERRUPTS OFF

	MOVE.L	A0,ISRVEC+0.w	INSTALL NEW ROUTINE

	MOVE.W	D0,SR		RE-ASSERT OLD STATUS
	RTS

*****************************************
*	Reglage de la frequence
*****************************************
* Entree : D7= Valeur de TADR
* Predivision selectionnee : 10

SETFREQ	MOVE.B	#1,TACR+0.w		DISABLE TIMER
	move.b	d7,TADR+0.w
	rts

***********************************
*	ENABLE THE MFP	*
***********************************

ENABMFP	bset	#5,IERA+0.w
	bset	#5,IMRA+0.w
	BCLR.B	#3,VECTOR+0.w
	RTS

*****************************************
*	SET UP THE SOUND CHIP CHANNELS	*
*****************************************

SETSND	lea	SndITbl(pc),a0
	lea	SCREG+0.w,a1
	moveq	#8,d1
SetSnd.1	move.w	(a0)+,d0
	movep.w	d0,0(a1)
	dbra	d1,SetSnd.1
	rts

SndITbl	dc.b	0,0,1,0,2,0,3,0
	dc.b	4,0,5,0,7,$FF
	dc.b	8,$D,9,$0,10,$0	Valeurs correspondant a $80 dans la table
	dc.w	0,0,0,0,0


****************************************************************************
*		La routine qui joue sous interruptions
****************************************************************************


* Exit avec reprise du son (pour les sons repetes)
PS.PatchS	move.l	MusicPtr+0.w,a0
	move.w	(a0)+,d0
	bpl.s	PS.Replay
	lea	MusicScore(pc),a0
	move.w	(a0)+,d0

PS.Replay	move.l	a0,MusicPtr+0.w	Stocke le pointeur sur les musiques
	lsl.w	#2,d0
	lea	PS.PatchS(pc),a0
	add.l	#Vars+MusicAd-PS.PatchS,a0
	move.l	(a0),a0		Recupere le pointeur sur les musiques

	move.l	0(a0,d0.w),d0	Et pret pour la musique suivante
	lea	0(a0,d0.l),a0
	move.l	(a0)+,d0		On a trouve le bon son
	move.l	a0,SoundPtr+0.w	Stocke l'adresse du son a jouer
	add.l	a0,d0
	subq.l	#6,d0		On arrete un peu avant si le fichier a une longueur impaire
	lea	PS.PatchE+2(pc),a0	Patche l'adresse de fin (W)
	move.l	d0,(a0)
	move.l	SoundPtr+0.w,a0

	bra.s	PS.Repeat

* Interruption nulle quand fini
PS.INull	rte

PS.Inter	movem.l	d0-d1/a0,-(sp)

	move.l	SoundPtr+0.w,a0		Lecture de l'adresse en cours
PS.PatchE	cmp.l	#0,a0		Verifie si on a fini (patche)
PS.PatchJ	bhi.s	PS.ExitN		Si oui, on s'en va (patche)

PS.Repeat	moveq	#0,d0		Retour si son en boucle
	Move.b	(a0)+,d0		Lit la donnee digitalisee
	move.l	a0,SoundPtr+0.w

	lsl.w	#3,d0		DOUBLE LONG WORD OFFSET
	lea	PS.Table(PC,D0.W),a0
	move.l	(a0)+,d0
	move.w	(a0)+,d1
	lea	SCREG+0.w,a0
	movep.l	d0,(a0)
	movep.w	d1,(a0)

	movem.l	(sp)+,d0-d1/a0
	RTE

* Exit normal (pour les sons non repetes)
PS.ExitN	MOVE.W	#$2700,SR		DISABLE INTS.
	lea	PS.INull(pc),a0
	bsr	SETINT		Installe une interruption vide

	move.l	#Vars-PS.ExitN,a0
	lea	PS.ExitN(pc,a0.l),a0	a0=VARS
	BSR	OLDMFP		RESTORE ORIGINAL MFP DATA
	move.w	#$2300,SR		Remet les interruptions
	clr.l	SoundPtr+0.w	Indique "Son termine"
	movem.l	(sp)+,d0-d1/a0	Et restaure les registres
	rte


PS.Table	INCLUDE	\PROJET.CUB\SNDTBL.S

* Valeurs d'initialisation pour les registres speciaux du STE
STE.Registers:
	dc.b	0,0,0,0,5,12,19,68
	dc.b	144,137,69,77,106,125,107,111
	dc.b	82,76,142,163,79,148,150,148
	dc.b	168,168,85,154,156,88,172,155
	dc.b	91,159,172,172,162,165,177,182
	dc.b	172,179,179,116,103,148,170,106
	dc.b	193,177,191,193,184,191,191,114
	dc.b	148,200,182,200,192,120,172,174
	dc.b	123,189,125,195,211,197,129,199
	dc.b	198,214,206,218,204,136,217,203
	dc.b	221,140,176,214,225,217,228,230
	dc.b	226,228,221,219,151,220,222,154
	dc.b	191,197,203,195,194,200,202,208

	EVEN
****************************************************************************
*		Programme	de remplissage de polygones
*			Fourni par INFOGRAMES
****************************************************************************
	IFNE	VERSION_ST
	INCLUDE	ST\FILL.S
	ENDC


	SECTION	DATA
IntroTxt	dc.b	"                                              "
	dc.b	"Alpha Waves  (C) 1990 C. de Dinechin et INFOGRAMES                              "

	dc.b	"*** CAUTION ***   Do not use copies of Alpha Waves, "
	dc.b	"as this may destroy the GLUE chip of the ST.                "
	dc.b	"*** ATTENTION ***   Ne pas utiliser de copies d'Alpha Waves, "
	dc.b	"car cela pourrait detruire le circuit GLUE du ST.               "
	dc.b	"*** WARNUNG ***   Keine Kopie des Programmes benuetzen, "
	dc.b	"als es das GLUE Chip zerstoeren koennte.         "

	dc.b	"Remerciements a "
	dc.b	"Frederick RAYNAL pour l'adaptation IBM PC, "
	dc.b	"Philippe PONTICELLI pour les couleurs, "
	dc.b	"Frederic MENTZEN pour la musique, "
	dc.b	"Christian DEVILLE-CAVELLIN pour l'envie de faire le programme, "
	dc.b	"Michel IAGOLNITZER pour la tolerance dont il a fait preuve, "
	dc.b	"Eric MOTTET pour ses idees et son calme, "
	dc.b	"Carole ARACHTINGUI pour son sourire et son soutien, "
	dc.b	"Michel ROYER et Richard BOTTET pour la 'Librairie'.             "
	dc.b	"Salutations speciales a "
	dc.b	"Marina VEZZOLI (Beta-testeuse de choc), "
	dc.b	"Fran�ois PARIS (1 million de franc lourds), "
	dc.b	"Christophe et Xavier HURBIN (8 nanas ?), "
	dc.b	"Christophe ROCHET (deux mains et le Jazz), "
	dc.b	"Baltazar MARTINS-DIAZ (Vive la bidouille), "
	dc.b	"Laurent FINAS (quand est ce que tu me rends mes disques ?), "
	dc.b	"Laurent DAVERIO (toujours le bienvenu, et vive la musique bretonne), "
	dc.b	"Richard MEYER (mon ma�tre, avec toutes mes excuses pour l'ACM), "
	dc.b	"Christian DEVILLE-CAVELLIN (Tant pis pour Car Wars sur Sun, c'est Alpha Waves sur ST), "
	dc.b	"Michel IAGOLNITZER (Tanata Gore, fais gaffe au ST la prochaine fois que tu me tues), "
	dc.b	"Raphael MANFREDI (ram@emse.fr, received Jun-06-89 from 88dupont@ensmp.fr, how do you do ?), "
	dc.b	"Thibaud DUBOUX (l'homme invisible ?), " 
	dc.b	"Olivier NAVARRO (Carbosalycilate d'ethyl phenil dimetyl dimetylaminopyrazolone, a l'orthographe pres.), "
	dc.b	"et tous ceux que j'aurais pu oublier...."

	dc.b	"#",0

***************************************************************************
*		Zone de stockage de donnees
***************************************************************************

	SECTION	DATA
SinTab	INCBIN	\PROJET.CUB\SINTAB.INC	Lecture de la table de sinus

	IFNE	0
Fire0.X	INCBIN	\ASSEMBLR\PROJET.CUB\FIRE0.ICN
Fire1.X	INCBIN	\ASSEMBLR\PROJET.CUB\FIRE1.ICN
Up0.X	INCBIN	\ASSEMBLR\PROJET.CUB\Up0.ICN
Up1.X	INCBIN	\ASSEMBLR\PROJET.CUB\Up1.ICN
Dn0.X	INCBIN	\ASSEMBLR\PROJET.CUB\Dn0.ICN
Dn1.X	INCBIN	\ASSEMBLR\PROJET.CUB\Dn1.ICN
Lf0.X	INCBIN	\ASSEMBLR\PROJET.CUB\Lf0.ICN
Lf1.X	INCBIN	\ASSEMBLR\PROJET.CUB\Lf1.ICN
Rt0.X	INCBIN	\ASSEMBLR\PROJET.CUB\Rt0.ICN
Rt1.X	INCBIN	\ASSEMBLR\PROJET.CUB\Rt1.ICN
	ENDC


****************************************************************************
*		Table de description des tableaux
* Format :
*  W: Taille totale du tableau (passage au tableau suivant)
*  W: Acceleration verticale
*  W: Nombre d'objets dans la salle
****************************************************************************


****************************************************************************
*			 Table des objets
* 	L: Offset / Objtab de la description de forme
* 	L: Offset / ObjPrgs du programme d'affichage
****************************************************************************
* KeyWord	#OTAB
ObjTab	dc.l	Ombre1.D-ObjTab,0
	dc.l	Ombre1.D-ObjTab,OmbreOther.I-ObjPrgs
	dc.l	V4.D-ObjTab,0
	dc.l	V4.D-ObjTab,VaissOther.I-ObjPrgs

	dc.l	Porte.D-ObjTab,Sortie1.I-ObjPrgs
	dc.l	Porte.D-ObjTab,Sortie2.I-ObjPrgs
	dc.l	Porte.D-ObjTab,Sortie3.I-ObjPrgs
	dc.l	Porte.D-ObjTab,Sortie4.I-ObjPrgs

	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs
	dc.l	SmlPlaq.D-ObjTab,SmlPlaq.I-ObjPrgs
	dc.l	MurEW.D-ObjTab,MurEW.I-ObjPrgs
	dc.l	MurNS.D-ObjTab,MurNS.I-ObjPrgs

	dc.l	EnPent.D-ObjTab,PlaqueN.I-ObjPrgs
	dc.l	EnPent.D-ObjTab,PlaqueE.I-ObjPrgs
	dc.l	EnPent.D-ObjTab,PlaqueS.I-ObjPrgs
	dc.l	EnPent.D-ObjTab,PlaqueW.I-ObjPrgs
	dc.l	RotateG.D-ObjTab,RotateG.I-ObjPrgs
	dc.l	TransN.D-ObjTab,TransN.I-ObjPrgs
	dc.l	TransE.D-ObjTab,TransE.I-ObjPrgs
	dc.l	TransS.D-ObjTab,TransS.I-ObjPrgs
	dc.l	TransW.D-ObjTab,TransW.I-ObjPrgs

	dc.l	Pyr1000.D-ObjTab,Cube1000.I-ObjPrgs
	dc.l	Pyr400.D-ObjTab,Cube400.I-ObjPrgs
	dc.l	Pyr200.D-ObjTab,Cube200.I-ObjPrgs

Cube500.N	equ	(*-ObjTab)*2
	dc.l	Cube500.D-ObjTab,Cube500.I-ObjPrgs
	dc.l	Cube400.D-ObjTab,Cube400.I-ObjPrgs
	dc.l	Cube300.D-ObjTab,Cube300.I-ObjPrgs
	dc.l	Cube200.D-ObjTab,Cube200.I-ObjPrgs
	dc.l	Cube100.D-ObjTab,Cube100.I-ObjPrgs
	dc.l	Plaque.D-ObjTab,0
	dc.l	Chassr.D-ObjTab,Chassr.I-ObjPrgs
Diamond.N	equ	(*-ObjTab)*2
	dc.l	Diamond.D-ObjTab,Diamond.I-ObjPrgs
	dc.l	Oizo.D-ObjTab,Oizo.I-ObjPrgs
	dc.l	PlaqueP.D-ObjTab,Plaque.I-ObjPrgs
	dc.l	Explode.D-ObjTab,Explode.I-ObjPrgs	Explosion : No $220-$22F
	dc.l	Bulle.D-ObjTab,BulleP.I-ObjPrgs	Bulle de legerete = $230
	dc.l	Bulle.D-ObjTab,BulleV.I-ObjPrgs
	dc.l	Plaque.D-ObjTab,LabP.I-ObjPrgs	Plaque qui n'est vue que de pres
	dc.l	PTeleV.D-ObjTab,PTeleV.I-ObjPrgs	Plaque de teleportation verticale
	dc.l	RotateD.D-ObjTab,RotateD.I-ObjPrgs
	dc.l	RotateG.D-ObjTab,RotaG.I-ObjPrgs
	dc.l	RotateD.D-ObjTab,RotaD.I-ObjPrgs

	dc.l	Teleport.D-ObjTab,Teleport.I-ObjPrgs
	dc.l	Teleport.D-ObjTab,Catcher.I-ObjPrgs
	dc.l	Clign.D-ObjTab,Clign.I-ObjPrgs
	dc.l	Falling.D-ObjTab,Falling.I-ObjPrgs

	dc.l	LongX.D-ObjTab,LongX2.I-ObjPrgs
	dc.l	LongX.D-ObjTab,LongX3.I-ObjPrgs
	dc.l	LongX.D-ObjTab,LongX4.I-ObjPrgs
	dc.l	LongX.D-ObjTab,LongX5.I-ObjPrgs

	dc.l	LongY.D-ObjTab,LongY2.I-ObjPrgs
	dc.l	LongY.D-ObjTab,LongY3.I-ObjPrgs
	dc.l	LongY.D-ObjTab,LongY4.I-ObjPrgs
	dc.l	LongY.D-ObjTab,LongY5.I-ObjPrgs

Bonus.N	equ	(*-ObjTab)*2
	dc.l	Bonus.D-ObjTab,Bonus.I-ObjPrgs	32 bonuses de temps
	dc.l	Bonus.D-ObjTab,Bonus.I-ObjPrgs

	dc.l	Rebond.D-ObjTab,Rebond.I-ObjPrgs	Objet rebondissant dans tous les sens

	dc.l	TChenille.D-ObjTab,TChenille.I-ObjPrgs	Description de la chenille
	dc.l	MChenille.D-ObjTab,MChenille.I-ObjPrgs
	dc.l	QChenille.D-ObjTab,QChenille.I-ObjPrgs

	dc.l	Canon.D-ObjTab,Canon.I-ObjPrgs	Canon et missile
Missile.N	equ	(*-ObjTab)*2
	dc.l	Missile.D-ObjTab,Missile.I-ObjPrgs

	dc.l	Protect.D-ObjTab,Protect.I-ObjPrgs	Cube de protection
	dc.l	ProtKey.D-ObjTab,ProtKey.I-ObjPrgs

	dc.l	FireP.D-ObjTab,FireP.I-ObjPrgs	Plaque de tir
	dc.l	Alien.D-ObjTab,Alien.I-ObjPrgs	Alien rotatif
	dc.l	Rebond2.D-ObjTab,Rebond.I-ObjPrgs	Objet rebondissant dans tous les sens
	dc.l	Rebond3.D-ObjTab,Rebond.I-ObjPrgs	Objet rebondissant dans tous les sens

	dc.l	TChenille.D-ObjTab,TChenille.I-ObjPrgs	Description de la 2e chenille (boules)
	dc.l	Chen2.D-ObjTab,MChenille.I-ObjPrgs
	dc.l	QChen2.D-ObjTab,QChenille.I-ObjPrgs
	dc.l	Chassr2.D-ObjTab,Chassr.I-ObjPrgs	Et deuxieme chasseur

	dc.l	NullObj.D-ObjTab,PoseTraj.I-ObjPrgs	Point de trajectoire et explorateur
	dc.l	Explor.D-ObjTab,Explor.I-ObjPrgs
	dc.l	StarWar.D-ObjTab,StarWar.I-ObjPrgs
	dc.l	BigOne.D-ObjTab,BigOne.I-ObjPrgs
	dc.l	Speeder.D-ObjTab,Speeder.I-ObjPrgs

	dc.l	AutoPlq.D-ObjTab,Auto1.I-ObjPrgs	Plaques a deplacement auto.
	dc.l	AutoPlq.D-ObjTab,Auto2.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto3.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto4.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto5.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto6.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto7.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto8.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto9.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto10.I-ObjPrgs

DiamP.N	equ	(*-ObjTab)*2
	dc.l	DiamPN.D-ObjTab,DiamPN.I-ObjPrgs
	dc.l	DiamPE.D-ObjTab,DiamPE.I-ObjPrgs
	dc.l	DiamPS.D-ObjTab,DiamPS.I-ObjPrgs
	dc.l	DiamPW.D-ObjTab,DiamPW.I-ObjPrgs
	dc.l	DiamPH.D-ObjTab,DiamPH.I-ObjPrgs
	dc.l	DiamPB.D-ObjTab,DiamPB.I-ObjPrgs

	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs	4 Dunmmies (extensions)
	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs
	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs
	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs


EndObjTab	dc.w	0

MAXOBJ	equ	(EndObjTab-ObjTab)*2-1

***************************************************************************
*		Table d'objets de demonstration
***************************************************************************
DemoOTab:
	dc.l	PtiCube.D-DemoOTab,PtiCube.I-ObjPrgs
	dc.l	GroCube.D-DemoOTab,PtiCube.I-ObjPrgs
	dc.l	NullObj.D-DemoOTab,Front.I-ObjPrgs
	dc.l	NullObj.D-DemoOTab,Nuque.I-ObjPrgs

TurnOTab:
	dc.l	NullObj.D-TurnOTab
	dc.l	Plaque.D-TurnOTab
	dc.l	Plaque.D-TurnOTab
	dc.l	SmlPlaq.D-TurnOTab
	dc.l	MurEW.D-TurnOTab
	dc.l	MurNS.D-TurnOTab
	dc.l	EnPent.D-TurnOTab
	dc.l	RotateG.D-TurnOTab
	dc.l	TransN.D-TurnOTab
	dc.l	Pyr1000.D-TurnOTab
	dc.l	Plaque.D-TurnOTab
	dc.l	Chassr.D-TurnOTab
	dc.l	Chassr.D-TurnOTab
	dc.l	Diamond.D-TurnOTab
	dc.l	Diamond.D-TurnOTab
	dc.l	Diamond.D-TurnOTab
	dc.l	Diamond.D-TurnOTab
	dc.l	PlaqueP.D-TurnOTab
	dc.l	PlaqueP.D-TurnOTab
	dc.l	PlaqueP.D-TurnOTab
	dc.l	PTeleV.D-TurnOTab
	dc.l	PTeleV.D-TurnOTab
	dc.l	PTeleV.D-TurnOTab
	dc.l	RotateD.D-TurnOTab
	dc.l	RotateD.D-TurnOTab
	dc.l	Clign.D-TurnOTab
	dc.l	Clign.D-TurnOTab
	dc.l	Bonus.D-TurnOTab
	dc.l	Bonus.D-TurnOTab
	dc.l	Falling.D-TurnOTab
	dc.l	AutoPlq.D-TurnOTab
	dc.l	TChenille.D-TurnOTab
	dc.l	TChenille.D-TurnOTab
	dc.l	MChenille.D-TurnOTab
	dc.l	MChenille.D-TurnOTab
	dc.l	Canon.D-TurnOTab
	dc.l	Canon.D-TurnOTab
	dc.l	Missile.D-TurnOTab
	dc.l	QChen2.D-TurnOTab
	dc.l	Rebond.D-TurnOTab
	dc.l	ProtKey.D-TurnOTab
	dc.l	ProtKey.D-TurnOTab
	dc.l	ProtKey.D-TurnOTab
	dc.l	ProtKey.D-TurnOTab
	dc.l	Chen2.D-TurnOTab
	dc.l	Chen2.D-TurnOTab
	dc.l	FireP.D-TurnOTab
	dc.l	Rebond2.D-TurnOTab
	dc.l	Rebond2.D-TurnOTab
	dc.l	Chassr2.D-TurnOTab
	dc.l	Chassr2.D-TurnOTab
	dc.l	QChenille.D-TurnOTab
	dc.l	Alien.D-TurnOTab
	dc.l	Alien.D-TurnOTab
	dc.l	Explor.D-TurnOTab
	dc.l	Explor.D-TurnOTab
	dc.l	StarWar.D-TurnOTab
	dc.l	StarWar.D-TurnOTab
	dc.l	BigOne.D-TurnOTab
	dc.l	BigOne.D-TurnOTab
	dc.l	Rebond3.D-TurnOTab
	dc.l	Rebond3.D-TurnOTab
	dc.l	Speeder.D-TurnOTab
	dc.l	Speeder.D-TurnOTab
	dc.l	Rebond3.D-TurnOTab
	dc.l	Rebond3.D-TurnOTab

* Il y a exactement 64 objets en possibles pour la demonstration

****************************************************************************
*		Descriptions d'objets
* Format d'un objet
*    Decalage de sommets
*  B: Sommet de reference de sous objet (0 pour indiquer la fin)
*    B...B : 0: fin du sous-objet
*	   (1-127) Liste d'index de sommets indiquant la composition d'une
*	facette du sous objet
*	   (>127) Indique la couleur de la facette precedente
****************************************************************************

* KeyWord #OBJ

PtiCube.D	dc.b	ZM1,XM1,YM2,XP2,YP2,ZP2,XM2,YM2,XP2,END
	dc.b	1
	dc.b	3,4,5,6,$E4
	dc.b	10,9,8,7,$E4
	dc.b	5,4,9,10,$E5
	dc.b	6,7,8,3,$E5
	dc.b	6,5,10,7,$E6
	dc.b	8,9,4,3,$E6
	dc.b	END,END

GroCube.D	dc.b	ZM2,XM2,YM4,XP4,YP4,ZP4,XM4,YM4,XP4,END
	dc.b	1
	dc.b	3,4,5,6,$E4
	dc.b	10,9,8,7,$E4
	dc.b	5,4,9,10,$E5
	dc.b	6,7,8,3,$E5
	dc.b	6,5,10,7,$E6
	dc.b	8,9,4,3,$E6
	dc.b	END,END

StarWar.D	dc.b	ZM1,XP2,YM2,ZP3,YP2,ZP2
	DC.B	XM4,ZM2,YM2,ZM3,YP2,ZM1
	DC.B	XP4,XP3,YP1,ZP1
	DC.B	ZP3,XM10,ZM3
	DC.B	END
	dc.b	1
	dc.b	20,13,8,19,$F5
	dc.b	17,18,7,14,$f5
	dc.b	7,8,13,14,$F6

	dc.b	14,13,11,4,$F5
	dc.b	4,5,18,17,$F5
	dc.b	10,8,7,5,$F5
	dc.b	10,11,20,19,$F5
	dc.b	8,10,19,$F4
	dc.b	18,5,7,$F4
	dc.b	11,10,5,4,$F6

	dc.b	17,14,4,$E0
	dc.b	11,13,20,$E0
	dc.b	0,0


BigOne.D	dc.b	ZP10,XM5,XP10,YM3,XM2,ZP5,XM3,XM3,ZM5,XM2
	DC.B	YM10,XP10,ZM10,ZM5,XM10,ZM3,YP3,XP10
	DC.B	YP10,ZP5,XM10,END
	DC.B	1
	DC.B	13,12,9,7,$F6
	DC.B	12,3,9,$F4
	DC.B	4,7,9,3,$F5
	DC.B	13,7,4,$F4

	DC.B	12,16,18,22,3,$F5
	DC.B	15,13,4,21,19,$F5
	DC.B	12,13,15,16,$F4
	DC.B	4,3,22,21,$F6
	DC.B	16,15,19,18,$F5
	DC.B	18,19,21,22,$E0
	DC.B	0,0


Speeder.D	dc.b	YP1,XM2,YM4,XP4,YP4,ZM1,YM1,XP2
	DC.B	XM4,XM4,ORIG
	DC.B	ZP10,XM1,XP2,ZM10,ZM3,XM2
	DC.B	END

	DC.B	1
	DC.B	4,18,11,$F5
	DC.B	4,5,17,18,$F4
	DC.B	5,9,17,$F5
	DC.B	9,6,17,$E0
	DC.B	6,3,18,17,$F5
	DC.B	3,11,18,$E0

	DC.B	4,11,14,$F4
	DC.B	14,15,5,4,$F5
	DC.B	15,9,5,$F4
	DC.B	15,6,9,$F5
	DC.B	15,14,3,6,$F6
	DC.B	14,11,3,$F5

	DC.B	0,0

Explor.D	dc.b	ZM2,YP1,ZP1,XM1
	dc.b	ZP1,ZP1,ZP1,ZP3
	DC.B	XP1,XP1
	DC.B	ZM3,ZM1,ZM1,ZM1
	DC.B	YM2,ZP1,ZP1,ZP1
	dc.b	XM2,ZM1,ZM1,ZM1
	dc.b	END

	dc.b	1
	dc.b	8,20,19,12,$E0
	dc.b	7,21,18,13,$E0
	dc.b	6,22,17,14,$E0
	dc.b	5,23,2,$F5
	dc.b	23,16,2,$F4
	dc.b	16,15,2,$F5
	dc.b	15,5,2,$F6

	dc.b	23,5,15,16,$E0
	dc.b	14,17,22,6,$E0
	dc.b	13,18,21,7,$E0
	dc.b	10,19,20,$F4
	dc.b	10,20,8,$F5
	dc.b	10,8,12,$F6
	dc.b	10,12,19,$F5

	dc.b	0,0

Alien.D	dc.b	YM4,XM1,ZP1
	dc.b	XP2,ZM2,XM2
	dc.b	XM4,ZP2,ZP4,XP4,XP2,XP4,ZM4,ZM2,ZM4,XM4,XM2,XM4
	dc.b	YM5,ZP4,XP4,ZP2,XP2,ZM2
	dc.b	END
	dc.b	1
	dc.b	18,17,15,14,12,11,9,8,$E0
	dc.b	1,7,6,$F4
	dc.b	1,4,7,$F5
	dc.b	1,5,4,$F6
	dc.b	1,6,5,$F5
	dc.b	0,22
	dc.b	8,9,11,12,14,15,17,18,$E0
	dc.b	7,8,22,$F4
	dc.b	9,4,23,$F5
	dc.b	4,11,23,$F4
	dc.b	18,7,22,$F5
	dc.b	5,24,12,$F5
	dc.b	25,6,17,$F4
	dc.b	15,6,25,$F5
	dc.b	14,24,5,$F4
	dc.b	11,12,24,23,$F6
	dc.b	8,9,23,22,$F6
	dc.b	18,22,25,17,$F6
	dc.b	14,15,25,24,$F6
	dc.b	22,23,24,25,$F1
	dc.b	0,0

Protect.D	dc.b	YM10,XM10,ZP10
	dc.b	XP10,XP10,YP10,YP10,XM10,XM10
	dc.b	ZM10,ZM10
	dc.b	XP10,XP10,YM10,YM10,XM10,XM10,END

	dc.b	1
	dc.b	4,6,$E0
	dc.b	8,6,$E0
	dc.b	8,10,$E0
	dc.b	4,10,$E0
	dc.b	4,18,$E0
	dc.b	16,18,$E0
	dc.b	16,14,$E0
	dc.b	12,14,$E0
	dc.b	12,18,$E0
	dc.b	12,10,$E0
	dc.b	8,14,$E0
	dc.b	6,16,$E0
	dc.b	0,0

ProtKey.D	dc.b	YM2,XM2,ZP2
	dc.b	XP4,YP4,XM4,ZM4
	dc.b	XP4,YM4,XM4,END
	dc.b	1
	dc.b	4,5,$E0
	dc.b	5,6,$E0
	dc.b	6,7,$E0
	dc.b	7,4,$E0
	dc.b	8,9,$E0
	dc.b	9,10,$E0
	dc.b	10,11,$E0
	dc.b	11,8,$E0
	dc.b	4,11,$E0
	dc.b	5,10,$E0
	dc.b	6,9,$E0
	dc.b	7,8,$E0
	dc.b	0,0


Canon.D	dc.b	XM5,YM5,XP10,YP10,XM10
	dc.b	ZM2,YM10,XP10,YP10
	dc.b	XM3,YM3,ZM2,XM4,YM4,XP4,ZP5,YP4,XM4,YM4
	dc.b	XP1,YP1,XP2,YP2,XM2,YM1,XP1,ZP5,END

	dc.b	1
	dc.b	6,5,10,7,$F8	Cote interieur de la couronne
	dc.b	4,3,8,9,$F8
	dc.b	3,6,7,8,$F9
	dc.b	5,4,9,10,$F9

	dc.b	13,14,15,16,$F9	Cotes avant et arriere du cube
	dc.b	20,19,18,17,$F9

	dc.b	24,23,28,$E0	Fusee du canon
	dc.b	25,24,28,$E1
	dc.b	22,25,28,$E0
	dc.b	23,22,28,$E1

	dc.b	13,18,19,14,$FA	Cote exterieurs du cube interieur
	dc.b	20,17,16,15,$FA
	dc.b	15,14,19,20,$FB
	dc.b	13,16,17,18,$FB

	dc.b	7,10,5,6,$F1	Cote exterieur de la couronne
	dc.b	9,8,3,4,$F1
	dc.b	8,7,6,3,$F2
	dc.b	10,9,4,5,$F2

	dc.b	0,0

Missile.D	dc.b	END
	dc.b	1
	dc.b	1,$E0,20
	dc.b	0,0

Chen2.D	dc.b	END
	dc.b	1
	dc.b	1,$E0,30
	dc.b	0,0
QChen2.D	dc.b	END
	dc.b	1
	dc.b	1,$E0,10
	dc.b	0,0

Chassr2.D	dc.b	YP2,YM4,ORIG
	dc.b	XP5,XM10,XP4
	dc.b	ZP10,XM2,ZM10
	dc.b	ZM3,XP2,END
	dc.b	1
	dc.b	5,2,12,$E0
	dc.b	12,2,11,$F2
	dc.b	11,2,6,$E0
	dc.b	5,8,2,$E1
	dc.b	8,9,2,$E0
	dc.b	9,6,2,$E1

	dc.b	5,12,3,$E1
	dc.b	11,3,12,$F2
	dc.b	11,6,3,$E1
	dc.b	5,3,8,$E0
	dc.b	8,3,9,$E1
	dc.b	9,3,6,$E0

	dc.b	0,0


TChenille.D
	dc.b	ZM2,XM2,YM2,XP4,YP3,XM4,XP1,YM1,ZP5,XP2,END
	dc.b	1
	dc.b	4,5,6,7,$F6
	dc.b	6,11,10,7,$F5
	dc.b	7,10,4,$F4
	dc.b	5,11,6,$F4
	dc.b	5,4,10,11,$E0
	dc.b	0,0

MChenille.D
	dc.b	YM2,YP4,ORIG,ZP2,ZM4,ORIG,XM2,XP4,END
	dc.b	1
	dc.b	5,2,8,$F4
	dc.b	5,9,2,$F5
	dc.b	5,3,9,$F6
	dc.b	5,8,3,$F5
	dc.b	6,8,2,$F5
	dc.b	6,2,9,$F6
	dc.b	6,9,3,$F5
	dc.b	6,3,8,$F4
	dc.b	0,0

QChenille.D
	dc.b	ZM1,ZP3,XM1,YM1,XP2,YP2,XM2,END
	dc.b	1
	dc.b	8,7,6,5,$F6
	dc.b	7,2,6,$F4
	dc.b	5,2,8,$F4
	dc.b	5,6,2,$E0
	dc.b	8,2,7,$E0
	dc.b	0,0


Rebond2.D	dc.b	XM5,XP5,XP5,END
	dc.b	1
	dc.b	1,$E0,30,0
	dc.b	2
	dc.b	2,$F5,20,0
	dc.b	4
	dc.b	4,$F5,20,0
	dc.b	0

Rebond3.D	dc.b	XM5,XP5,XP5,END
	dc.b	1
	dc.b	1,$F5,30,0
	dc.b	2
	dc.b	2,$E0,20,0
	dc.b	4
	dc.b	4,$E0,20,0
	dc.b	0

Rebond.D	dc.b	XM3,ZP3,XP3,XP3,ZM3,ZM3,XM3,XM3
	dc.b	ZP2,XP2,YM2
	dc.b	ZP2,XP2,ZM2,YP4,XM2,ZP2,XP2,END
	dc.b	1
	dc.b	12,13,14,15,$E0	Deux facettes sup et inf
	dc.b	19,18,17,16,$E0

	dc.b	9,12,15,7,$F4
	dc.b	3,13,12,9,$F5
	dc.b	5,14,13,3,$F6
	dc.b	7,15,14,5,$F5
	dc.b	13,4,14,$E1

	dc.b	18,19,5,3,$F5
	dc.b	17,18,3,9,$F4
	dc.b	7,16,17,9,$F5
	dc.b	5,19,16,7,$F6
	dc.b	16,17,8,$E2

	dc.b	0,0


Clign.D	dc.b	ZP5,XP5,ZM5,ZM5,XM5,XM5,ZP5,ZP5,ORIG,YP5,END
	dc.b	1
	dc.b	11,5,3,$F4
	dc.b	11,7,5,$F5
	dc.b	11,9,7,$F6
	dc.b	11,3,9,$F5
	dc.b	3,5,7,9,$E0
	dc.b	9,3,4,$F2
	dc.b	5,7,8,$F2
	dc.b	0,0

Falling.D	dc.b	ZP5,XP5,ZM5,ZM5,XM5,XM5,ZP5,ZP5,ORIG,YP5,END
	dc.b	1
	dc.b	11,5,3,$F4
	dc.b	11,7,5,$F5
	dc.b	11,9,7,$F6
	dc.b	11,3,9,$F5
	dc.b	3,5,7,9,$E0
	dc.b	9,3,1,$F2
	dc.b	5,7,1,$F2
	dc.b	0,0

EnPent.D	dc.b	ZP5,XP5,ZM5,ZM5,XM5,XM5,ZP5,ZP5,ORIG,YP5,END
	dc.b	1
	dc.b	11,5,3,$F4
	dc.b	11,7,5,$F5
	dc.b	11,9,7,$F6
	dc.b	11,3,9,$F5

	dc.b	3,5,7,9,$E0

	dc.b	7,2,1,$F2
	dc.b	1,2,5,$F2
	dc.b	0,0


RotateG.D	dc.b	ZP5,XP5,ZM5,ZM5,XM5,XM5,ZP5,ZP5,ORIG,YP5,END
	dc.b	1
	dc.b	11,5,3,$F4
	dc.b	11,7,5,$F5
	dc.b	11,9,7,$F6
	dc.b	11,3,9,$F5

	dc.b	3,5,7,9,$E0

	dc.b	1,2,3,$F2
	dc.b	1,4,5,$F2
	dc.b	1,6,7,$F2
	dc.b	1,8,9,$F2

	dc.b	0,0

RotateD.D	dc.b	ZP5,XP5,ZM5,ZM5,XM5,XM5,ZP5,ZP5,ORIG,YP5,END
	dc.b	1
	dc.b	11,5,3,$F4
	dc.b	11,7,5,$F5
	dc.b	11,9,7,$F6
	dc.b	11,3,9,$F5

	dc.b	3,5,7,9,$E0

	dc.b	1,3,4,$F2
	dc.b	1,5,6,$F2
	dc.b	1,7,8,$F2
	dc.b	1,9,2,$F2

	dc.b	0,0

AutoPlq.D	dc.b	ZP5,XP5,ZM5,ZM5,XM5,XM5,ZP5,ZP5,ORIG,YP5,END
	dc.b	1
	dc.b	11,5,3,$F4
	dc.b	11,7,5,$F5
	dc.b	11,9,7,$F6
	dc.b	11,3,9,$F5

	dc.b	3,5,7,9,$E0

	dc.b	2,4,8,$F2
	dc.b	1,5,7,$F2

	dc.b	0,0


Bulle.D	dc.b	GO1,GO2,GO3,GO4,GO5,GO6,GO7,GO8,END
	dc.b	1
	dc.b	2,3,4,5,6,7,8,9,$F6
	dc.b	9,8,7,6,5,4,3,2,$F4
	dc.b	0,0

NullObj.D	dc.b	END
	dc.b	1,0,0

Explode.D	dc.b	XP1,YP1,END
	dc.b	1
	dc.b	1,2,3,$E0
	dc.b	0,0

Oizo.D	dc.b	ZP2,ZP5,ZM10,YM1,YM1,XP1,XM2,ZP4,YM1,XM1,XP4,GO1,ZP2,XP2,YP1,ZM3,GO2,ZP2,XM2,YP1,ZM3,END
	dc.b	1
	dc.b	19,22,18,$F8	Inferieur extremite aile g
	dc.b	17,14,13,$F8
	dc.b	8,18,19,11,$FC	Sup centre aile g
	dc.b	7,12,14,13,$FC
	dc.b	7,12,1,$F6	Corps 1 d
	dc.b	11,8,1,$F6
	dc.b	5,7,1,$F4		Corps 2 d
	dc.b	8,5,1,$F4
	dc.b	1,12,3,$F5	Corps 3 d
	dc.b	3,11,1,$F5

	dc.b	7,8,11,12,$E0	Dessus du corps
	dc.b	8,7,5,$F4
	dc.b	12,11,3,$F4

	dc.b	13,14,12,7,$FA	Inf centre aile d
	dc.b	11,19,18,8,$FA
	dc.b	13,14,17,$FD	Sup ext aile g
	dc.b	18,22,19,$FD
	dc.b	0,0

Bonus.D	dc.b	XM1,ZP1,XP2,ZM2,XM2,ORIG,YM2,YP4,END
	dc.b	1
	dc.b	3,8,6,$F4
	dc.b	3,6,9,$F5
	dc.b	4,5,8,$F5
	dc.b	9,5,4,$F6
	dc.b	6,8,5,$F6
	dc.b	9,6,5,$F5
	dc.b	4,8,3,$F5
	dc.b	4,3,9,$F4
	dc.b	0,0

DiamPN.D	dc.b	ZP5,ZM4,XM1
	dc.b	YM1,XP2,YP2,XM2,END
	dc.b	1
	dc.b	2,6,5,$F4
	dc.b	2,7,6,$F5
	dc.b	2,8,7,$F6
	dc.b	2,5,8,$F5
	dc.b	5,6,7,8,$F3
	dc.b	0,0

DiamPS.D	dc.b	ZM5,ZP4,XP1
	dc.b	YM1,XM2,YP2,XP2,END
	dc.b	1
	dc.b	2,6,5,$F4
	dc.b	2,7,6,$F5
	dc.b	2,8,7,$F6
	dc.b	2,5,8,$F5
	dc.b	5,6,7,8,$F3
	dc.b	0,0

DiamPE.D	dc.b	XP5,XM4,ZP1
	dc.b	YM1,ZM2,YP2,ZP2,END
	dc.b	1
	dc.b	2,6,5,$F4
	dc.b	2,7,6,$F5
	dc.b	2,8,7,$F6
	dc.b	2,5,8,$F5
	dc.b	5,6,7,8,$F3
	dc.b	0,0

DiamPW.D	dc.b	XM5,XP4,ZM1
	dc.b	YM1,ZP2,YP2,ZM2,END
	dc.b	1
	dc.b	2,6,5,$F4
	dc.b	2,7,6,$F5
	dc.b	2,8,7,$F6
	dc.b	2,5,8,$F5
	dc.b	5,6,7,8,$F3
	dc.b	0,0

DiamPH.D	dc.b	YM5,YP4,ZM1
	dc.b	XP1,ZP2,XM2,ZM2,END
	dc.b	1
	dc.b	2,6,5,$F4
	dc.b	2,7,6,$F5
	dc.b	2,8,7,$F6
	dc.b	2,5,8,$F5
	dc.b	5,6,7,8,$F3
	dc.b	0,0

DiamPB.D	dc.b	YP5,YM4,ZM1
	dc.b	XM1,ZP2,XP2,ZM2,END
	dc.b	1
	dc.b	2,6,5,$F4
	dc.b	2,7,6,$F5
	dc.b	2,8,7,$F6
	dc.b	2,5,8,$F5
	dc.b	5,6,7,8,$F3
	dc.b	0,0


Diamond.D	dc.b	XM5,YM5,XP5,YP10,ZM5,YM5,ZP10,XP5,ZM5
	dc.b	ORIG,XP1,YP1,ZP1
	dc.b	YM2,ZM2,YP2,XM2,YM2,ZP2,YP2
	dc.b	END
	dc.b	3
	dc.b	19,20,4,$F4
	dc.b	20,19,2,$F5
	dc.b	16,19,4,$F5
	dc.b	15,16,4,$F6
	dc.b	20,15,4,$F5
	dc.b	19,18,2,$F6
	dc.b	18,21,2,$F5
	dc.b	21,20,2,$F4
	dc.b	0,6
	dc.b	17,18,7,$F4
	dc.b	18,17,5,$F5
	dc.b	17,14,5,$F5
	dc.b	14,21,5,$F6
	dc.b	21,18,5,$F5
	dc.b	18,19,7,$F6
	dc.b	19,16,7,$F5
	dc.b	16,17,7,$F4
	dc.b	0,9
	dc.b	14,15,8,$F4
	dc.b	15,14,10,$F5
	dc.b	15,10,16,$F5
	dc.b	16,10,17,$F6
	dc.b	17,10,14,$F5
	dc.b	15,20,8,$F6
	dc.b	20,21,8,$F5
	dc.b	21,14,8,$F4
	dc.b	0,0




Diams.D	dc.b	XM2,ZP2,XP4,ZM4,XM4,ORIG,YM5,YP10,END
	dc.b	1
	dc.b	3,8,6,$F8
	dc.b	3,6,9,$F9
	dc.b	4,5,8,$F9
	dc.b	9,5,4,$FA
	dc.b	6,8,5,$FA
	dc.b	9,6,5,$F9
	dc.b	4,8,3,$F9
	dc.b	4,3,9,$F8
	dc.b	0,0

Chassr.D	dc.b	XP3,ZP2,YM1,XP1,XM5,YP2,XP5,ZP4,XM1,YM1,XM3,ZP2,XP3,END
	dc.b	1
	dc.b	6,13,12,$F8
	dc.b	7,12,13,$F8
	dc.b	5,11,14,$F8
	dc.b	8,14,11,$F8
	dc.b	6,12,11,5,$FB
	dc.b	8,11,12,7,$FA
	dc.b	6,7,13,$F9
	dc.b	8,5,14,$F9
	dc.b	1,6,5,2,$FA
	dc.b	1,2,8,7,$FB
	dc.b	1,7,6,$E0
	dc.b	2,5,8,$E0
	dc.b	0,0

MurNS.D	dc.b	ZP10,YM10,ZM10,END
	dc.b	1
	dc.b	1,2,3,4,$E0
	dc.b	4,3,2,1,$E1
	dc.b	0,0

MurEW.D	dc.b	YM10,XP10,YP10,END
	dc.b	1
	dc.b	1,2,3,4,$E0
	dc.b	4,3,2,1,$E1
	dc.b	0,0

Plaque.D	dc.b	ZP5,XP5,ZM10,XM10,ZP10,ORIG,YP5,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	8,4,3,$F4
	dc.b	8,5,4,$F5
	dc.b	8,6,5,$F6
	dc.b	8,3,6,$F5
	dc.b	0,0

FireP.D	dc.b	ZP5,XP5,ZM10,XM10,ZP10,ORIG,YP5,ORIG,XM2,XP4,ORIG,ZM2,ZP4,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	8,4,3,$F4
	dc.b	8,5,4,$F5
	dc.b	8,6,5,$F6
	dc.b	8,3,6,$F5
	dc.b	10,14,11,13,$F2
	dc.b	0,0

TransN.D	dc.b	ZP5,XP5,ZM10,XM10,ZP10,ORIG,YP5,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	2,4,5,$F2
	dc.b	8,4,3,$F4
	dc.b	8,5,4,$F5
	dc.b	8,6,5,$F6
	dc.b	8,3,6,$F5
	dc.b	0,0

TransE.D	dc.b	XP5,ZM5,XM10,ZP10,XP10,ORIG,YP5,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	2,4,5,$F2
	dc.b	8,4,3,$F4
	dc.b	8,5,4,$F5
	dc.b	8,6,5,$F6
	dc.b	8,3,6,$F5
	dc.b	0,0

TransS.D	dc.b	ZM5,XM5,ZP10,XP10,ZM10,ORIG,YP5,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	2,4,5,$F2
	dc.b	8,4,3,$F4
	dc.b	8,5,4,$F5
	dc.b	8,6,5,$F6
	dc.b	8,3,6,$F5
	dc.b	0,0

TransW.D	dc.b	XM5,ZP5,XP10,ZM10,XM10,ORIG,YP5,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	2,4,5,$F2
	dc.b	8,4,3,$F4
	dc.b	8,5,4,$F5
	dc.b	8,6,5,$F6
	dc.b	8,3,6,$F5
	dc.b	0,0

PlaqueP.D	dc.b	ZP5,XP5,ZM10,XM10,ZP10,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	6,5,4,3,$F7
	dc.b	0,0

PTeleV.D	dc.b	ZP5,XP5,ZM10,XM10,ZP10,END
	dc.b	1
	dc.b	3,4,1,$E0
	dc.b	4,5,1,$E1
	dc.b	5,6,1,$E2
	dc.b	6,3,1,$E3
	dc.b	6,5,4,3,$F7
	dc.b	0,0

Porte.D	dc.b	ZM5,XP5,ZP5,YM5,XM5,YP5,XM1,ZM1,YM5,XP1,YM1,XP5,YP1,XP1,YP5,GO1,YM5,GO2,YM5,END
	dc.b	1
	dc.b	4,3,2,1,$F5
	dc.b	6,7,9,10,$F6
	dc.b	6,10,12,$F5
	dc.b	5,6,12,13,$F6
	dc.b	5,13,15,$F5
	dc.b	4,5,15,16,$F4
	dc.b	7,6,5,4,$F3
	dc.b	5,4,17,18,$E0
	dc.b	7,6,20,19,$E0
	dc.b	1,2,3,4,$F2
	dc.b	4,5,6,7,$F3
	dc.b	0,0


SmlPlaq.D	dc.b	ZP5,XP5,ZM5,END
	dc.b	1
	dc.b	1,2,3,4,$E0
	dc.b	4,3,2,1,$F7
	dc.b	0,0



Pyr400.D	dc.b	ZP4,XP4,ZM4,YM4,XM2,ZP2,END
	dc.b	1
	dc.b	1,7,4,$E1
	dc.b	2,7,1,$E2
	dc.b	3,7,2,$E3
	dc.b	4,7,3,$E2
	dc.b	4,3,2,1,$F7
	dc.b	0,0

Pyr200.D	dc.b	ZP2,XP2,ZM2,YM2,XM1,ZP1,END
	dc.b	1
	dc.b	1,7,4,$E1
	dc.b	2,7,1,$E2
	dc.b	3,7,2,$E3
	dc.b	4,7,3,$E2
	dc.b	4,3,2,1,$F7
	dc.b	0,0

Pyr1000.D	dc.b	ZP10,XP10,ZM10,YM10,XM5,ZP5,END
	dc.b	1
	dc.b	1,7,4,$E1
	dc.b	2,7,1,$E2
	dc.b	3,7,2,$E3
	dc.b	4,7,3,$E2
	dc.b	4,3,2,1,$F7
	dc.b	0,0


Cube500.D	dc.b	ZP5,XP5,ZM5,YM5,XM5,ZP5,XP5,END
	dc.b	1
	dc.b	4,3,2,1,$E0
	dc.b	5,6,7,8,$E0
	dc.b	6,5,4,1,$E1
	dc.b	2,3,8,7,$E1
	dc.b	1,2,7,6,$E2
	dc.b	3,4,5,8,$E2
	dc.b	0,0

Cube400.D	dc.b	ZP4,XP4,ZM4,YM4,XM4,ZP4,XP4,END
	dc.b	1
	dc.b	4,3,2,1,$E0
	dc.b	5,6,7,8,$E0
	dc.b	6,5,4,1,$E1
	dc.b	2,3,8,7,$E1
	dc.b	1,2,7,6,$E2
	dc.b	3,4,5,8,$E2
	dc.b	0,0

Cube300.D	dc.b	ZP3,XP3,ZM3,YM3,XM3,ZP3,XP3,END
	dc.b	1
	dc.b	4,3,2,1,$E0
	dc.b	5,6,7,8,$E0
	dc.b	6,5,4,1,$E1
	dc.b	2,3,8,7,$E1
	dc.b	1,2,7,6,$E2
	dc.b	3,4,5,8,$E2
	dc.b	0,0

Cube200.D	dc.b	ZP2,XP2,ZM2,YM2,XM2,ZP2,XP2,END
	dc.b	1
	dc.b	4,3,2,1,$E0
	dc.b	5,6,7,8,$E0
	dc.b	6,5,4,1,$E1
	dc.b	2,3,8,7,$E1
	dc.b	1,2,7,6,$E2
	dc.b	3,4,5,8,$E2
	dc.b	0,0

Cube100.D	dc.b	ZP1,XP1,ZM1,YM1,XM1,ZP1,XP1,END
	dc.b	1
	dc.b	4,3,2,1,$E0
	dc.b	5,6,7,8,$E0
	dc.b	6,5,4,1,$E1
	dc.b	2,3,8,7,$E1
	dc.b	1,2,7,6,$E2
	dc.b	3,4,5,8,$E2
	dc.b	0,0

Teleport.D:
	dc.b	GO1,GO2,GO3,GO4,GO5,GO6,GO7,GO8,END
	dc.b	1
	dc.b	2,3,$E0
	dc.b	3,4,$E0
	dc.b	4,5,$E0
	dc.b	5,6,$E0
	dc.b	6,7,$E0
	dc.b	7,8,$E0
	dc.b	8,9,$E0
	dc.b	0,0

LongX.D	dc.b	ZM5,XM5,ZP10,GO1,ZM10,END
	dc.b	1
	dc.b	3,4,5,6,$E0
	dc.b	6,5,4,3,$F7
	dc.b	0,0

LongY.D	dc.b	XM5,ZM5,XP10,GO1,XM10,END
	dc.b	1
	dc.b	6,5,4,3,$E0
	dc.b	3,4,5,6,$F7
	dc.b	0,0



***************************************************************************
*		Liste des sons echantillones
***************************************************************************


Void.S	equ	-1
NoSound.S	equ	0
TheSounds	dc.l	NoSound.SD-TheSounds
	dc.l	ChocVaiss.SD-TheSounds
	dc.l	ParTerre.SD-TheSounds
	dc.l	SurMurs.SD-TheSounds
	dc.l	Plaque.SD-TheSounds
	dc.l	Chasseur.SD-TheSounds
	dc.l	Sortie.SD-TheSounds
	dc.l	Trans.SD-TheSounds
	dc.l	Rotat.SD-TheSounds
	dc.l	EnPente.SD-TheSounds
	dc.l	Petite.SD-TheSounds
	dc.l	ChocOizo.SD-TheSounds
	dc.l	DirOizo.SD-TheSounds
	dc.l	Transpor.SD-TheSounds
	dc.l	TimeBonus.SD-TheSounds
	dc.l	Diamond.SD-TheSounds
	dc.l	Bulle.SD-TheSounds
	dc.l	Pyram.SD-TheSounds
	dc.l	Teleport.SD-TheSounds
	dc.l	Catcher.SD-TheSounds
	dc.l	Clign.SD-TheSounds
	dc.l	Falling.SD-TheSounds
	dc.l	ProtKey.SD-TheSounds
	dc.l	Protect.SD-TheSounds
	dc.l	Missile.SD-TheSounds
	dc.l	FireP.SD-TheSounds
	dc.l	Explor.SD-TheSounds
	dc.l	BigOne.SD-TheSounds
	dc.l	Auto.SD-TheSounds

NoSound.SD:
	dc.l	10
	dc.w	$8080,$8080,$8080


*********************************************************************************
* Macro chargeant un son dans la memoire.
* CtrSons est le compteur de sons.
* Appel par INCSND Label,Fichier
* Associe au label indique le son contenu dans \ASSEMBLR\PROJET.CUB\FICHIER.CSP

CtrSnd	set	1
INCSND	MACRO
\1	equ	CtrSnd	Compte le nombre d'appels
CtrSnd	set	CtrSnd+1
\1D	dc.l	\1F-\1D
	INCBIN	\\PROJET.CUB\\SVX\\\2.CSP
\1F
	ENDM
*********************************************************************************


	INCSND	ChocVaiss.S,CHOCVAIS
	INCSND	ParTerre.S,PARTERRE
	INCSND	SurMurs.S,SURMURS
	INCSND	Plaque.S,PLAQUE
	INCSND	Chasseur.S,CHASSR
	INCSND	Sortie.S,SORTIE
	INCSND	Trans.S,TRANS
	INCSND	Rotat.S,ROTAT
	INCSND	EnPente.S,ENPENT
	INCSND	Petite.S,PETITE
	INCSND	ChocOizo.S,CHOCOIZO
	INCSND	DirOizo.S,DIROIZO
	INCSND	Transpor.S,TRANSPOR
	INCSND	TimeBonus.S,TIMEBONS
	INCSND	Diamond.S,DIAMOND
	INCSND	Bulle.S,BULLE
	INCSND	Pyram.S,PYRAM
	INCSND	Teleport.S,TELEPORT
	INCSND	Catcher.S,CATCHER
	INCSND	Clign.S,CLIGN
	INCSND	Falling.S,FALLING
	INCSND	ProtKey.S,PROT_KEY
	INCSND	Protect.S,PROTECT
	INCSND	Missile.S,MISSIL
	INCSND	FireP.S,FIREP
	INCSND	Explor.S,EXPLOR
	INCSND	BigOne.S,BIGONE
	INCSND	Auto.S,AUTO

	dc.b	'W5PZ7F'	(FRANCE=W5PZ8F ANGLETERRE=W5PZ7F ALLEMAGNE=W5PZ6F)

****************************************************************************
*		Verrue de creation de tableaux
* Mode d'emploi :
*  Activer le mode CHEAT par le mot de passe (TRICHEUR en majuscules)
*  Commandes ensuite :
*  (J)ump : Donne une impulsion verticale de 300
*  SPACE  : Meme effet que Jump
*  (H)alt : Supprime la vitesse verticale (arret de la montee/descente)
*  (G)rav : Passe la gravite en alternance entre 0 et 20.Si a 0, fait un Halt
*  (+)(-) : Decale l'index d'objet actuel et l'utilise comme vaisseau
*  RETURN : Entre un nouvel objet a la position actuelle
*  DELETE : Efface l'objet le plus proche de moi (le numero d'objet devient celui actuel)
*  (S)ave : Sauvegarde le resultat obtenu sous le nom TABLO.TAB
*  UNDO   : Restaure le tableau par defaut
*  ESC    : Sort du mode CHEAT (et brouille le mot de passe)
*  CAPS   : Alternance du mode Pas-a-Pas et du mode rapide
*	  (En mode pas a pas, on attend une touche avant chaque rafraichissement d'image)
*  (X)it	: Passage au point POI, qui rentre dans la boucle sans deplacement et en 
*	  mettant LogScreen a l'ecran (pour debuggage MONST)
*
*
* Remarque : En mode CHEAT, on ne peut pas changer de tableau (toucher une
* dalle de changement de tableau ferait perdre le travail en cours)
* Parcontre, le rebond sur les dalles de sortie est perturbe comme sur les
* dalles en pente dans la direction de la sortie
****************************************************************************
	IFNE	CHEAT

QuitteVerrue:
	jmp	MainLoop

Verrue	lea	PassWd(a4),a0
	lea	1(a0),a1
	moveq	#6,d1
V.Copie	move.b	(a1)+,(a0)+	Decalage du mot de passe
	dbra	d1,V.Copie
	move.b	d0,(a0)		Et stockage de la derniere lettre

	cmp.l	#'TRIC',PassWd(a4)	Test du mot de passe
	bne	QuitteVerrue
	cmp.l	#'HEUR',PassWd+4(a4)
	bne	QuitteVerrue

	clr.w	StepStep(a4)
	move.w	#4,CurObj(a4)
	or.b	#6,$484.w
	clr.w	Joueur(a4)		Indique que l'on est en mode inactif

V.Loop	addq.l	#1,TimerL(a4)
	bsr	Deplace
	clr.w	JSuisMort(a4)	Au moment du ESC, il faut que ce soit nul
	move.w	SpeedX0(a4),SpeedX(a4)
	move.w	SpeedZ0(a4),SpeedZ(a4)

	bsr	Cls

	bsr	TrigInit		Initialisation des Sin et Cos
	bsr	DessineCube		Trace de l'arene,

	bsr	DessineMonde		du reste du monde

	move.l	AdObjTab(a4),a0
	move.w	CurObj(a4),d0
	lsr.w	#1,d0
	and.w	#$FFF8,d0
	move.l	0(a0,d0.w),d0
	lea	0(a0,d0.l),a0
	movem.w	CurX(a4),d0-d2
	movem.w	d0-d2,ObjX(a4)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	add.w	#2000,PosZ(a4)
	clr.w	UseLocAng(a4)
	bsr	TransXYZ
	movem.w	d0-d2,ModObjX(a4)
	move.w	CurObj(a4),DefColor(a4)	Fixe correctement la couleur par defaut
	lea	CPoint1(a4),a3
	moveq	#29,d7
V.ClrPnt	clr.w	(a3)+
	dbra	d7,V.ClrPnt
	bsr	AffObj
	sub.w	#2000,PosZ(a4)

	and.w	#15,TextColor(a4)
	move.w	TextColor(a4),Couleur(a4)	Couleur en cours affichee en haut a gauche
	move.l	#$00000000,PolySomm(a4)
	move.l	#$00300000,PolySomm+4(a4)
	move.l	#$00300050,PolySomm+8(a4)
	move.l	#$00000050,PolySomm+12(a4)
	moveq	#4,d3
	moveq	#0,d1
	moveq	#0,d2
	lea	PolySomm(a4),a0

	moveq	#0,d0
	move.w	CurX(a4),d0	Affichage des 3 coordonnees
	move.l	LogScreen(a4),a1
	bsr	PrNum
	move.w	CurY(a4),d0
	move.l	LogScreen(a4),a1
	lea	160*16(a1),a1
	bsr	PrNum
	move.w	CurZ(a4),d0
	move.l	LogScreen(a4),a1
	lea	160*32(a1),a1
	bsr	PrNum

	move.w	Beta(a4),d0	Affichage du cap
	and.w	#$3FF,d0
	move.l	LogScreen(a4),a1
	lea	160*48(a1),a1
	bsr	PrNum

V.Suite	tst.w	StepStep(a4)
	beq.s	V.SameScr
	move.w	#-1,-(sp)
	move.l	LogScreen(a4),-(sp)
	move.l	LogScreen(a4),-(sp)
	XBIOS	5,12
	XBIOS	37,2
	bra.s	V.OneScr

V.SameScr	bsr	SwapScrn		et permutation d'ecran

	move.w	#2,-(sp)		Test du clavier (sauf StepStep)
	BIOS	1,4		Caractere clavier ?
	tst.w	d0
	bpl	V.Loop		Non

V.OneScr	move.w	#2,-(sp)
	BIOS	2,4		Lecture du caractere
	cmp.b	#27,d0		Presse-t-on la touche ESC ?
	bne.s	V.NoQuit	
	clr.w	Inact(a4)
	add.l	#60*200*60,SysTime0(a4)
	bra	QuitteVerrue

* Test sur le pave numerique des 3 coordonnees et de la gravite
V.NoQuit	moveq	#1,d1
	tst.w	StepStep(a4)
	bne.s	V.NoSt
	moveq	#100,d1
V.NoSt	cmp.b	#19,d0
	bne.s	V.NoSvDemo
	bsr	SaveDemo
V.NoSvDemo:
	cmp.b	#'8',d0
	bne.s	V.NoZP
	add.w	d1,CurZ(a4)
	bra	V.Loop
V.NoZP	cmp.b	#'2',d0
	bne.s	V.NoZM
	sub.w	d1,CurZ(a4)
	bra	V.Loop
V.NoZM	cmp.b	#'3',d0
	bne.s	V.NoYP
	add.w	d1,CurY(a4)
	bra	V.Loop
V.NoYP	cmp.b	#'9',d0
	bne.s	V.NoYM
	sub.w	d1,CurY(a4)
	bra	V.Loop
V.NoYM	cmp.b	#'6',d0
	bne.s	V.NoXP
	add.w	d1,CurX(a4)
	bra	V.Loop
V.NoXP	cmp.b	#'4',d0
	bne.s	V.NoXM
	sub.w	d1,CurX(a4)
	bra	V.Loop
V.NoXM	cmp.w	#'/',d0
	bne.s	V.NoGP
	addq.w	#1,Gravite(a4)
	bra	V.Loop
V.NoGP	cmp.w	#'*',d0
	bne.s	V.NoGM
	subq.w	#1,Gravite(a4)
	bra	V.Loop
	
V.NoGM	cmp.w	#'(',d0
	bne.s	V.NoBM
	sub.w	#16,CurObj(a4)
	cmp.w	#4,CurObj(a4)
	bge	V.Loop
	move.w	#MAXOBJ,CurObj(a4)
	bra	V.Loop


	bra	V.Loop
V.NoBM	cmp.w	#')',d0
	bne.s	V.NoBP
	add.w	#16,CurObj(a4)
	cmp.w	#MAXOBJ,CurObj(a4)
	ble	V.Loop
	move.w	#4,CurObj(a4)
	bra	V.Loop

V.NoBP	swap	d0
	cmp.w	#$3B,d0		F1 : Un tableau de moins
	bne.s	V.NoTM
	subq.w	#1,Tableau(a4)
V.TM	and.w	#$1F,Tableau(a4)
	bsr	InitOL
	bra	V.Loop
V.NoTM	cmp.w	#$3C,d0
	bne.s	V.NoTP
	addq.w	#1,Tableau(a4)
	bra.s	V.TM

V.NoTP	cmp.w	#$17,d0		'I'
	bne.s	V.NoI
	not.w	Inact(a4)
	bra	V.Loop

V.NoI	cmp.w	#$3D,d0		Changement de couleur
	bne.s	V.NoCM		Couleur
	subq.w	#1,TextColor(a4)
	bra	V.Loop
V.NoCM	cmp.w	#$3E,d0
	bne.s	V.NoCP
	addq.w	#1,TextColor(a4)
	bra	V.Loop

V.NoCP	move.w	TextColor(a4),d1	Changement de palette
	add.w	d1,d1
	lea	$FFFF8240.w,a0
	cmp.w	#4,d1
	bge.s	V.NoTrick
	lea	BackColor(a4),a0
V.NoTrick	lea	0(a0,d1.w),a0
	cmp.w	#$3F,d0
	bne.s	V.NoRM
	sub.w	#$100,(a0)
	bra	V.Loop
V.NoRM	cmp.w	#$40,d0
	bne.s	V.NoRP
	add.w	#$100,(a0)
	bra	V.Loop
V.NoRP	cmp.w	#$41,d0
	bne.s	V.NoVM
	sub.w	#$010,(a0)
	bra	V.Loop
V.NoVM	cmp.w	#$42,d0
	bne.s	V.NoVP
	add.w	#$010,(a0)
	bra	V.Loop
V.NoVP	cmp.w	#$43,d0
	bne.s	V.NoBlM
	subq.w	#$001,(a0)
	bra	V.Loop
V.NoBlM	cmp.w	#$44,d0
	bne.s	V.NoBlP
	addq.w	#1,(a0)
	bra	V.Loop

V.NoBlP	cmp.w	#$2D,d0		'X'
	bne.s	V.NoPOI
POI	bra	V.Loop		Test point d'arret

V.NoPOI	cmp.w	#$24,d0		'J' ?
	beq.s	V.Jmp
	cmp.w	#$39,d0		SPACE ?
	bne.s	V.NoJmp

V.Jmp	move.w	#-300,SpeedY(a4)
	bra	V.Loop

V.NoJmp	cmp.w	#$23,d0		'H' ?
	bne.s	V.NoHlt
	clr.w	SpeedY(a4)
	bra	V.Loop

V.NoHlt	cmp.w	#$22,d0		'G' ?
	bne.s	V.NoGrav
	tst.w	Gravite(a4)
	beq.s	V.DepY
	clr.w	Gravite(a4)
	clr.w	SpeedY(a4)
	bra	V.Loop
V.DepY	move.w	#20,Gravite(a4)
	bra	V.Loop

V.NoGrav	cmp.w	#$4A,d0		'-'
	bne.s	V.NoMoins
	subq.w	#1,CurObj(a4)
	cmp.w	#4,CurObj(a4)
	bge	V.Loop
	move.w	#MAXOBJ,CurObj(a4)
	bra	V.Loop

V.NoMoins	cmp.w	#$4E,d0		'+'
	bne.s	V.NoPlus
	addq.w	#1,CurObj(a4)
	cmp.w	#MAXOBJ,CurObj(a4)
	ble	V.Loop
	move.w	#4,CurObj(a4)
	bra	V.Loop

V.NoPlus	cmp.w	#$1C,d0
	bne.s	V.NoRet
	move.w	ObjNum(a4),d0
	lsl.w	#5,d0
	lea	OList(a4),a0
	lea	0(a0,d0.w),a0
	move.w	CurObj(a4),(a0)+
	clr.w	(a0)+
	movem.w	CurX(a4),d0-d2

	movem.w	d0-d2,(a0)
	addq.w	#1,ObjNum(a4)
	bra	V.Loop

V.NoRet	cmp.w	#$61,d0
	bne.s	V.NoUndo
	bsr	InitOL
	bra	V.Loop

V.NoUndo	cmp.w	#$21,d0		'F'ast
	bne.s	V.NoFast
	not.w	StepStep(a4)
	bra	V.Loop

V.NoFast	cmp.w	#$53,d0		Delete
	bne.s	V.NoDel
	move.w	ObjNum(a4),d6
	subq.w	#1,d6
	ble	V.Loop
	move.w	#32000,d7		Distance par defaut
	lea	OList(a4),a0	Pointeur sur liste d'objets
	sub.l	a1,a1
V.DelLp	cmp.w	#$30,(a0)
	ble.s	V.CantDel
	movem.w	4(a0),d0-d2
	movem.w	CurX(a4),d3-d5
	bsr	Distance
	cmp.w	d7,d0
	bge.s	V.CantDel
	move.w	d0,d7
	move.l	a0,a1
V.CantDel	lea	32(a0),a0
	dbra	d6,V.DelLp
	move.l	a1,d0
	beq	V.Loop		Si rien a effacer d'autre que les vaisseaux
	move.w	(a1),d0
	move.w	d0,CurObj(a4)
	mulu	#6,d0
	movem.w	4(a1),d0-d2
	movem.w	d0-d2,CurX(a4)
	lea	AO.FerTab(a4),a2
V.Delete	move.l	32(a1),(a1)+
	cmp.l	a2,a1
	blt.s	V.Delete
	subq.w	#1,ObjNum(a4)

	bra	V.Loop

V.NoDel	cmp.w	#$1F,d0		'S'ave
	bne	V.NoSv

* Sauvegarde sur disque du tableau obtenu
	move.w	#-1,-(sp)
	move.l	PhyScreen(a4),-(sp)
	move.l	PhyScreen(a4),-(sp)
	XBIOS	5,12		Met l'ecran sur "PhyScreen"

	pea	FileText(pc)	Affiche "Nom de fichier :"
	GEMDOS	9,6
	pea	FileNLen(pc)	Lecture du nom de fichier
	GEMDOS	10,6
	lea	FileNLen(pc),a0
	clr.b	2(a0,d0.w)	Met un 0 a la fin du nom

	move.l	PhyScreen(a4),a6
	move.l	a6,a5
	move.w	Gravite(a4),(a6)+	Stocke l'acceleration verticale
	move.w	ObjNum(a4),d0
	move.w	d0,(a6)+		Stocke le nombre d'objets
	subq.w	#1,d0

	movem.l	$FFFF8240.w,d1-d7/a3
	movem.l	d1-d7/a3,(a6)	Stockage des couleurs
	lea	40(a6),a6

	moveq	#0,d7		Nombre d'objets sauves
	lea	OList(a4),a1
V.SaveLp	movem.w	(a1)+,d1-d5
	lea	22(a1),a1
	cmp.w	#$30,d1
	ble.s	V.NoSave
V.Save	movem.w	d1-d5,(a6)
	lea	10(a6),a6
	addq.w	#1,d7
V.NoSave	dbra	d0,V.SaveLp
	move.w	d7,2(a5)		Stocke le nombre d'objets
	sub.l	a5,a6		a6 : Longueur a sauver

	clr.w	-(sp)		Fichier Lecture / Ecriture
	pea	FileName(pc)	
	GEMDOS	$3C,8		CREATE
	move.w	d0,-(sp)		Sauvegarde du Handle
	move.l	PhyScreen(a4),-(sp)	Tampon des donnees
	move.l	a6,-(sp)		Longueur de sauvegarde
	move.w	d0,-(sp)		Handle
	GEMDOS	$40,12		WRITE
	GEMDOS	$3E,4		CLOSE (le handle est deja dans la pile)

	bra	V.Loop

V.NoSv	cmp.w	#$26,d0		'L'oad
	bne	V.NoLd

	move.w	#-1,-(sp)
	move.l	PhyScreen(a4),-(sp)
	move.l	PhyScreen(a4),-(sp)
	XBIOS	5,12		Met l'ecran sur "PhyScreen"

	pea	FileText(pc)	Affiche "Nom de fichier :"
	GEMDOS	9,6
	pea	FileNLen(pc)	Lecture du nom de fichier
	GEMDOS	10,6
	lea	FileNLen(pc),a0
	clr.b	2(a0,d0.w)	Met un 0 a la fin du nom

	clr.w	-(sp)		Accessible en lecture seule
	pea	FileName(pc)	Nom du fichier
	GEMDOS	$3D,8		OPEN
	tst.w	d0		Teste si le fichier existe
	bmi	V.Loop		Non

	move.w	d0,d7		Stockage du Handle
	move.l	PhyScreen(a4),-(sp)	Tampon de lecture
	pea	44.w		Lecture longueur tableau et gravite
	move.w	d7,-(sp)		Handle
	GEMDOS	$3F,12		READ

	move.l	PhyScreen(a4),a0
	move.w	2(a0),d0		Longueur du tableau
	mulu	#10,d0		Longueur totale du tableau
	pea	44(a0)		Lecture de la suite
	move.l	d0,-(sp)		Longueur
	move.w	d7,-(sp)		Handle
	GEMDOS	$3F,12		READ

	move.w	d7,-(sp)		Handle
	GEMDOS	$3E,4		CLOSE
	move.l	PhyScreen(a4),a0
	bsr	InitOL.a0		Initialisation liste d'objets
	bra	V.Loop

V.NoLd	cmp.w	#$62,d0		Touche HELP
	bne	V.Loop

	move.w	#-1,-(sp)
	move.l	PhyScreen(a4),-(sp)
	move.l	PhyScreen(a4),-(sp)
	XBIOS	5,12		Met l'ecran sur "PhyScreen"

	pea	HelpText(pc)
	GEMDOS	9,6		Affiche le texte d'aide

	GEMDOS	1,2		Attend une touche
	bra	V.Loop

FileNLen	dc.b	16,0
FileText	dc.b	27,"Y",40,32,27,"eNom du fichier (.TAB) :",0

HelpText	dc.b      27,"E",27,"p"
	dc.b	"    RESUME DES COMMANDES MODE CHEAT   ",27,"q",13,10
	dc.b	"+,-: Selection d'objet",13,10
	dc.b	"(,): Selection grossiere d'objets",13,10
	dc.b	"*,/: Variation de la gravite",13,10
	dc.b	"F1,F2: Tableau suivant/precedent",13,10
	dc.b	"F3,F4: Changement de la couleur",13,10
	dc.b	"F5-F10: Changement R/V/B",13,10
	dc.b	"RETURN: Pose d'objet",13,10
	dc.b	"DELETE: Suppression du plus proche",13,10
	dc.b	"F: Mode FAST/SLOW",13,10
	dc.b	"G: Gravite ES/HS",13,10
	dc.b	"H: Arret vertical",13,10
	dc.b	"I: Objets Inactifs/actifs",13,10
	dc.b	"J/SPACE: Saut",13,10
	dc.b	"L: Chargement de tableau",13,10
	dc.b	"S: Sauvegarde de tableau",13,10
	dc.b	"CTRL-S: Sauvegarde de la demo",13,10
	dc.b	"UNDO: Restaure le tableau initial",13,10
	dc.b	"ESC: Sortie du mode CHEAT",13,10
	dc.b	0

	ENDC

*********************************************************************************
* Macro chargeant un icone dans la memoire.
* CtrIcons est le compteur de sons.
* Appel par ICONE Label,Fichier
* Associe au label indique le son contenu dans \ASSEMBLR\PROJET.CUB\FICHIER.ICN

	IFNE	0

CtrIcons	set	0
ICONE	MACRO
\1.X	equ	CtrIcons		Compte le nombre d'appels
CtrIcons	set	CtrIcons+1
	INCBIN	\\ASSEMBLR\\PROJET.CUB\\\1.ICN
	ENDM
*********************************************************************************

TheIcons	ICONE	YFond
	ICONE	NFond
	ICONE	YFill
	ICONE	NFill
	ICONE	NautoH
	ICONE	YautoH
	ICONE	NautoV
	ICONE	YautoV
	ICONE	NBasc
	ICONE	YBasc
	ICONE	NPyram
	ICONE	YPyram
	ICONE	NSound
	ICONE	YSound
	ICONE	NNull
	ICONE	YNull

	ICONE	NWait
	ICONE	YWait
	ICONE	NMap
	ICONE	YMap

	ICONE	Death
	ICONE	Disk
	ICONE	Null

	ENDC

***************************************************************************
*		Zone de reservation des variables
***************************************************************************
MoveMemry	INCBIN	\PROJET.CUB\DEMO.INC

	IFNE	DEMO_REC
	ds.b	10000
	ENDC	DEMO_REC
FinMvMemry	dc.w	0

	SECTION	BSS
TScreen	ds.b	8000
Screen	ds.b	32256
Screen2	ds.b	32000


***************************************************************************
*		Variables du programme (pointees par a4)
***************************************************************************
	RSRESET

* Variables personnelles de joueur
ToScore	rs.w	1
ClipG	rs.w	1	Valeurs de clipping
ClipD	rs.w	1
ClipH	rs.w	1
ClipB	rs.w	1
CurX	rs.w	1	Position actuelle
CurY	rs.w	1
CurZ	rs.w	1
OldX	rs.w	1	Ancienne position
OldY	rs.w	1
OldZ	rs.w	1
PosX	rs.w	1	Position sur l'ecran
PosY	rs.w	1
PosZ	rs.w	1
Alpha	rs.w	1	Angle de visee
Beta	rs.w	1
Gamma	rs.w	1
BetaSpeed	rs.w	1	Vitesse de rotation
Contract	rs.w	1	Contraction du pied
VaissNum	rs.w	1	Numero de vaisseau
KFactor	rs.w	1	Facteurs de grandissement / Reduction
LFactor	rs.w	1

AltiOmb	rs.w	1	Altitude de l'ombre
NxAOmb	rs.w	1	Altitude au prochain tour
NumOmb	rs.w	1	Numero de l'objet de l'ombre; -1= Ombre deja affichee; -2= Vaisseau affiche
NxNOmb	rs.w	1	Pour le prochain tour

SpeedX	rs.w	1	Vitesse selon les trois axes
SpeedY	rs.w	1
SpeedZ	rs.w	1
SpeedX0	rs.w	1	Vitesse a atteindre
SpeedZ0	rs.w	1
Joueur	rs.w	1	0: Joueur 0/Sprites actifs  1: Joueur 1/Sprites inactifs
Tableau	rs.w	1	Numero du tableau actuel
Options1	rs.b	1
*	0: Mode Emotion
*	1: Deux joueurs
Options2	rs.b	1
*	0: Fond de cube creux
*	1: Mode lignes
*	2: Retour au centre automatique horizontal
*	3: Retour au bas automatique
*	4: Utilisation de gamma dans les rotations
*	5: Affichage de la pyramide
*	6: Son/ Pas de son
*	7: Musique/Pas de musique (inutilise sur ST)

* Variables d'adresses de zones systeme
TabVisitAd	rs.l	1	Pointeur sur TabVisit
Other	rs.l	1	Adresse de l'autre jeu de variables

MusicAd	rs.l	1	Adresse de la musique si elle est chargee
AdTScreen	rs.l	1
AdObjTab	rs.l	1
LogScreen	rs.l	1	Adresses d'ecran
PhyScreen	rs.l	1
DefScreen	rs.l	1
BckScreen	rs.l	1	Ecran de fond
AdTexts	rs.l	1	Adresse des differents textes affiches
AdScores	rs.l	1	Adresse du tableau des scores
AdIntroTxt	rs.l	1	Texte d'intro
Screen2Ad	rs.l	1	Copie de l'ecran

TabNames	rs.l	1	Adresse des tableaux et des noms de tableaux
Tableaux	rs.l	1
OldJoyst	rs.l	1	Ancien vecteur de traitement du joystick
OldMsVec	rs.l	1	Ancien vecteur de traitement de la souris
OldEtvCritic	rs.l	1	Ancien vecteur erreur disque
BSSStart	rs.l	1	Debut de la zone BSS
SpareUSP	rs.l	1	Stockage de USP pour retour au GEM
LineA	rs.l	1	Adresse des variables LineA
TBVEC.Old	rs.l	1	Ancien vecteur du TimerB
Filler	rs.l	1	Indique la routine de remplissage

* Variables communes aux deux joueurs
ExtraTime	rs.w	1
JSuisMort	rs.w	1	>0: Tab suivant  <0: Mort
Sortie	rs.w	1	Sortie utilisee
MaxVSpeed	rs.w	1	Vitesse verticale maxi autorisee dans le tableau
Gravite	rs.w	1	Acceleration verticale
CosA	rs.w	1	Memorisation des valeurs de SIN, COS de A B C
SinA	rs.w	1
CosB	rs.w	1
SinB	rs.w	1
CosC	rs.w	1
SinC	rs.w	1
ObjX	rs.w	1	Position de l'objet regarde
ObjY	rs.w	1
ObjZ	rs.w	1
ModObjX	rs.w	1	Position relative du centre de l'objet apres rotation
ModObjY	rs.w	1
ModObjZ	rs.w	1
AlphaL	rs.w	1	Angles de rotations locales
BetaL	rs.w	1
GammaL	rs.w	1
UseLocAng	rs.w	1	Utilisation des angles locaux precedants
Resol	rs.w	1	Resolution d'ecran
OldResol	rs.w	1	Resolution a l'appel du programme
ObjetVu	rs.w	1	Objet affiche sur l'ecran ?
Couleur	rs.w	1	Couleur d'affichage
DefColor	rs.w	1	Couleur determinee par le numero d'objet
InputDev	rs.w	1	0 : Joy 1  1: Joy 2   2: Kbd
DoLoad	rs.w	1	-1: Indique qu'il faut faire un LOAD,
*			 1 que la derniere partie debuta par un LOAD,
*			 0 que la derniere partie etait normale

Seed	rs.w	1	Base du generateur de nombres aleatoires
ObjNum	rs.w	1	Nombre d'objets dans la base de donnees
MissilN	rs.w	1	Nombre de Missiles dans la base en cours
Traject	rs.w	3*16	Points de la trajectoire des monstres
TrajSize	rs.w	1	Nombre de points de cette trajectoire

TimerL	rs.w	1	Timer 32 bits
Timer	rs.w	1
SysTime0	rs.l	1	Timer Systeme 200Hz au debut
LastTime	rs.l	1	Dernier temps systeme pour calcul de la vitesse

WhichBonus	rs.l	1	Liste des Bonus de temps
WhichDiamond	rs.w	1	Liste des diamants
WhichProtect	rs.w	1	Liste des Cubes de protection


FastFill	rs.w	1	Indique un remplissage rapide monoplan
FP.Tri	rs.w	1	Tri dans fichier POLY.S
FP.Max	rs.w	1
MM.MaxImages	rs.l	1
MM.Default	rs.w	1

NumReb	rs.w	1	Numero du rebond
MFPMEM	rs.b	8	Stockage des valeurs normales du MFP
VECTOR.Old	rs.b	1
IMRA.Old	rs.b	1
IERA.Old	rs.b	1
TBDR.Old	rs.b	1
TBCR.Old	rs.b	1
BackColor	rs.w	16	Couleurs de fond d'ecran, utilisee par les interruptions VBL
CurColor	rs.w	16	Couleur effectivement affichee

* Variables de la presentation
TextAd	rs.l	1	Adresse du texte en cours
TextPos	rs.w	1	Position sur l'ecran
TextWait0	rs.w	1	>0: Attendre pour affichage; <0: Fin du texte atteinte
TextWait	rs.w	1	Le TextWait en cours
TextCol	rs.w	1	Colonne en cours
TextColor	rs.w	1
InvertLine	rs.w	1	Ligne a inverser sur l'ecran

* Variables du mode CHEAT
PassWd	rs.b	8	Lettres du mot de passe tape
CurObj	rs.w	1	Objet en cours d'edition
StepStep	rs.w	1	Indique si on est en mode pas a pas
Inact	rs.w	1	indique que les sprites sont inactifs
MovePtr	rs.l	1	Pointeur sur le compteur de deplacements
EndMvMem	rs.l	1	Pointeur de fin de memorisation
MoveMemAd	rs.l	1	Pointeur sur la zone de demo

CPoint1	rs.w	3		Stockage des points particuliers calcules
CPoint2	rs.w	3
CPoint3	rs.w	3
CPoint4	rs.w	3
CPoint5	rs.w	3
CPoint6	rs.w	3
CPoint7	rs.w	3
CPoint8	rs.w	3
CPoint9	rs.w	3
CPoint10	rs.w	3


* Zones de stockage de donnees
Sommets	rs.w	4*128	Maxi 128 sommets
OList	rs.w	16*128	Liste des objets
AO.FerTab	rs.b	128	Fermeture du polygone en ZClipping
PolySomm	rs.w	3*128	128 sommets eventuellement 3D

* Indique si on est sur un STE
STisSTE	rs.w	1

* Pour les etoiles tournant
NStars	rs.w	1
StarsXY	rs.w	2*NB_STARS+10

DataLen	rs.w	1	Longueur totale des variables

********************************************************************
*		Stockage effectif des donnees
********************************************************************

TabVisit	ds.b	NTABS		Indique si le tableau a ete visite
CpyScores	ds.b	16

Vars	ds.b	DataLen		Reserve l'espace pour les variables
Vars2	ds.b	DataLen		Variables joueur 2

DataSave	ds.b	10240		Reserve l'espace de sauvegarde
DataSaveEnd:
	ds.b	4096		Reserve l'espace pile
Pile	ds.w	1
