****************************************************************************
*
*		Matrix-NeuroMancien
*
***************************************************************************

	Opt	D+,M+

NTABS	EQU	256		Nombre de tableaux
CHEAT	EQU	1		Mode CHEAT
	INCLUDE	SYSMACRO.S

***************************************************************************
*		D‚but du programme
***************************************************************************
Start	bra	Init
***************************************************************************
*		Boucle de la d‚mo du d‚but
***************************************************************************
Main	bra	MainGame

Finished	neg.w	DoLoad(a6)	Si =1 (charg‚ sur disque), indique -1 (A charger) pour la d‚mo
	move.w	#2,-(sp)
	BIOS	1,4
	tst.w	d0
	bpl.s	Finish.1
	move.w	#2,-(sp)
	BIOS	2,4
	bra.s	Finished

Finish.1	tst	Joueur(a6)
	beq.s	Finish.2
	bsr	SwapVars

Finish.2	bsr	OnePlayer
	bsr	ViewScore

MainGame	tst.w	InputDev(a6)
	bpl.s	Main.NoDemo
	addq.w	#4,InputDev(a6)
	move.l	Other(a6),a5
	move.b	Options1(a5),Options1(a6)	Restaure le retour au centre du joystick a l'etat initial

Main.NoDemo:
	bsr	SelectOptions
Main.Load	bsr	MiniInit		Initialisation de partie
	or.w	#$100,Tableau(a6)	Tableau 0, mais <>0 pour InitOL => pas de copie
	bsr	SwapVars
	bsr	MiniInit
	bsr	InitOL
	bsr	SwapVars

	tst.w	DoLoad(a6)	Si il faut charger le jeu
	bmi	EndDiskOp		Charge le jeu (stock‚ dans la zone de save)

	move.w	#-25,Sortie(a6)		Pour que l'on ne trouve pas de sortie
*	bsr	DrawIcons
NouvTab	and.w	#NTABS-1,Tableau(a6)	RamŠne au nombre de tableaux
	clr.w	Alpha(a6)			Vibrations parasite si pas remis … 0 de force
	clr.w	BetaSpeed(a6)

	bsr	NewTablo			Initialisation de tableau

MainLoop	addq.l	#1,TimerL(a6)
	bsr	Cls

MainLoop2	bsr	TrigInit
	bsr	TraceCube		Trac‚ de l'arŠne,
	bsr	DrawWorld		Se charge alors de tracer l'ombre et le vaisseau

	tst.w	JSuisMort(a6)
	bmi	TheEnd
	bne.s	PasDeplace
	bsr	Deplace
	bra.s	PasChTab
PasDeplace:
	subq.w	#1,JSuisMort(a6)
	bne.s	PasChTab

	move.l	TabVisitAd(a6),a0
	move.w	Tableau(a6),d0
	and.w	#NTABS-1,d0
	tst.b	0(a0,d0.w)		Teste si on a d‚j… vu le tableau en question
	bne	NouvTab
	move.w	#30,ExtraTime(a6)
	add.l	#200*60,SysTime0(a6)	Si non, on a 3 mn d'exploration en plus
	move.l	Other(a6),a5
	add.l	#200*60,SysTime0(a5)
	bra	NouvTab

PasChTab:
	btst	#1,Options1(a6)		Si 2 joueurs
	beq.s	Only1P
	bsr	SwapVars			On passe alternativement l'un et l'autre
	tst.w	Joueur(a6)
	bne	MainLoop2

Only1P	bsr	MkScore

	bsr	SwapScrn		et permutation d'‚cran
	move.w	#2,-(sp)
	BIOS	1,4		CaractŠre clavier ?
	tst.w	d0
	bpl	MainLoop		Non

	move.w	#2,-(sp)
	BIOS	2,4		Lecture du caractŠre
	cmp.b	#27,d0		Presse-t-on la touche ESC ?
	bne	KR.NoKey		Non ? On lit les touches

	move.l	SysTime0(a6),d7
	sub.l	$4BA.w,d7		D7= Temps restant
	move.l	d7,-(sp)

	lea	DF.Norm(pc),a0
	lea	DrawFond(pc),a1
	move.l	a0,2(a1)

	move.l	PhyScreen(a6),a0
	move.l	Screen2Ad(a6),a1
	bsr	CopyScreen

	lea	CmdText(pc),a0
	moveq	#6,d0
	bsr	MakeMenu
	cmp.w	#16,d0		Teste si on a demand‚ "Quitter"
	bne	KR.NoEnd
	addq.l	#4,sp
	bra	Finished


*		 0123456789012345678901234567890123456789
CmdText	dc.b	6,16,27,0,1,0,24,13,13,13
	dc.b	"         SELECTION DES OPTIONS",13,13
	dc.b	"  Reprendre la derniŠre partie sauv‚e",13
	dc.b	"  Sauvegarde sur disquette",13
	dc.b	"  Trac‚ du fond du cube   :"
CmdYesNo	dc.b	" OUI",13
	dc.b	"  Trac‚ en formes pleines : OUI",13
	dc.b	"  Centrage automatique    : OUI",13
	dc.b	"  Position verticale auto.: OUI",13
	dc.b	"  Basculement sur l'‚cran : OUI",13
	dc.b	"  Affichage du vaisseau   : OUI",13
	dc.b	"  Sonorisation            : OUI",13
	dc.b	"  Affichage de la carte",13
	dc.b	"  Quitter cette partie",13
	dc.b	13,13,13,13,0
	


************************************************************************
*		Op‚rations sur disque
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


SaveText	dc.b	27,0
	dc.b	13,13,13,13,13,13,13,13,13,13
	dc.b	"SAUVER LA PARTIE EN COURS",13,13,13
	dc.b	"Mettez une disquette format‚e",13
	dc.b	"dans le lecteur, puis entrez le nom",13
	dc.b	"du fichier de sauvegarde",13
	dc.b	13,13,13,13,13,1,0,17,"> "
	dc.b	0

	EVEN

KR.NoEnd	cmp.w	#6,d0		R‚cup‚ration ancienne version
	bne.s	KR.ReLoad
	addq.l	#4,sp
	neg.w	DoLoad(a6)	Indique "Recharger la derniŠre partie"
	bra	Main.Load

KR.ReLoad	cmp.w	#7,d0
	bne	KR.NoSave

*	moveq	#Disk.X,d0
*	moveq	#19,d1
*	bsr	DrawDIcon
*	bsr	DrawIIcon

* Copie des donn‚es dans la zone de sauvegarde
	move.l	Other(a6),a5		Sauvegarde du temps
	move.l	SysTime0(a6),d0
	sub.l	$4ba.w,d0
	move.l	d0,SysTime0(a6)
	move.l	d0,SysTime0(a5)

	lea	Score(pc),a0		Sauvegarde du score
	move.l	TabVisitAd(a6),a1
	movem.l	(a0),d0-d1
	movem.l	d0-d1,NTABS(a1)
	lea	Score2(pc),a0
	movem.l	(a0),d0-d1
	movem.l	d0-d1,NTABS+8(a1)

	lea	DataSave-Vars2(a5),a0	Position de sauvegarde
	lea	ASauver(pc),a1		Adresse des objets … sauver
SaveData	move.w	(a1)+,d0
	beq.s	ErDiskOp
	lea	0(a6,d0.w),a2
	move.w	(a1)+,d0
	lea	0(a6,d0.w),a3
SaveD.1	move.w	(a2)+,(a0)+
	cmp.l	a3,a2
	blt.s	SaveD.1
	bra.s	SaveData

* Demande du nom de fichier
ErDiskOp	lea	SaveText(pc),a0
	bsr	PrintItAll
	lea	FileName(pc),a1	Lecture du nom de fichier

	bsr	VS.WaitK
	clr.b	(a1)+
	cmp.w	#2,TextCol(a6)	Si nom de fichier vide
	bne.s	SaveGame
	bra.s	NoSvDone

EndDiskOp	move.w	#1,DoLoad(a6)	Indique un chargement depuis la m‚moire effectu‚
* Fin des op‚rations sur disque: R‚cup‚ration de la zone de save
NoSvDone	move.l	Other(a6),a5

	lea	DataSave-Vars2(a5),a0	Position de sauvegarde
	lea	ASauver(pc),a1		Adresse des objets … sauver
LoadData	move.w	(a1)+,d0
	beq.s	QtDiskOp
	lea	0(a6,d0.w),a2
	move.w	(a1)+,d0
	lea	0(a6,d0.w),a3
LoadD.1	move.w	(a0)+,(a2)+
	cmp.l	a3,a2
	blt.s	LoadD.1
	bra.s	LoadData

QtDiskOp	move.l	Other(a6),a5		R‚cupŠre le temps
	move.l	SysTime0(a6),d0
	add.l	$4ba.w,d0
	move.l	d0,SysTime0(a6)
	move.l	d0,SysTime0(a5)

	lea	Score(pc),a0		Enregistre le score
	move.l	TabVisitAd(a6),a1
	movem.l	NTABS(a1),d0-d1
	movem.l	d0-d1,(a0)
	lea	Score2(pc),a0
	movem.l	NTABS+8(a1),d0-d1
	movem.l	d0-d1,(a0)

*	bsr	DrawIcons
	bra	MainLoop

* Operation de sauvegarde sur disque
SaveGame	clr.w	-(sp)		Fichier Lecture / Ecriture
	pea	FileName(pc)	
	GEMDOS	$3C,8		CREATE
	tst.l	d0
	bmi.s	DiskErr

	move.w	d0,-(sp)		Sauvegarde du Handle
	move.l	Other(a6),a5
	pea	DataSave-Vars2(a5)	Tampon des donn‚es
	pea	DataSaveEnd-DataSave+0.w
	move.w	d0,-(sp)		Handle
	GEMDOS	$40,12		WRITE
	tst.l	d0
	bmi.s	DiskErr
	GEMDOS	$3E,4		CLOSE (le handle est d‚j… dans la pile)

	move.l	MoveMemAd(a6),EndMvMem(a6)	Indique que la partie reprend l…
	bra	EndDiskOp


* Chargement d'un fichier depuis le disque
LoadGame	clr.w	-(sp)		Accessible en lecture seule
	pea	FileName(pc)	Nom du fichier
	GEMDOS	$3D,8		OPEN
	tst.l	d0		Teste si le fichier existe
	bmi	DiskErr		Non

	move.w	d0,d7		Stockage du Handle
	move.l	Other(a6),a5
	pea	DataSave-Vars2(a5)	Tampon des donn‚es
	pea	DataSaveEnd-DataSave+0.w
	move.w	d7,-(sp)		Handle
	GEMDOS	$3F,12		READ
	tst.l	d0
	bmi.s	DiskErr
	move.w	d7,-(sp)
	GEMDOS	$3E,4

	rts

* R‚cup‚ration d'une erreur sur le disque
DiskErr	lea	DiskErr.M(pc),a0
	bsr	PrintItAll
DiskErr.W	bsr	DrawFond
	move.w	#2,-(sp)
	BIOS	1,4
	tst.w	d0
	bpl.s	DiskErr.W
	move.w	#2,-(sp)
	BIOS	2,4
	cmp.b	#27,d0
	beq	MainGame
	tst.w	DoLoad(a6)
	bne.s	LoadGame

	bra	ErDiskOp

DiskErr.M	dc.b	27,0,13,13,13,13,13,13,13,13,13
	dc.b	"ERREUR DE LECTURE DU DISQUE",13,13,13,13
	dc.b	"Les informations lues ou ecrites sont",13
	dc.b	"sans doute inexactes.",13
	dc.b	"Veuillez appuyer sur une touche pour",13
	dc.b	"Reprendre l'op‚ration",13
	dc.b	"ESC pour retourner au menu principal",13
	dc.b	13,13,13,13,13
	dc.b	0
	EVEN

KR.NoSave	cmp.w	#15,d0		Teste si on demande l'affichage de la carte
	bne.s	KR.Func
KR.Map1	move.l	Screen2Ad(a6),a0
	move.l	LogScreen(a6),a1
	bsr	CopyScreen
	bsr	PrintMap		Affiche la carte
	bsr	SwapScrn
	bsr	KeyPressed
	tst.w	d0
	bpl.s	KR.Map1
	bra.s	KR.End

KR.Func	subq.w	#8,d0
	move.w	d0,d1
	lsl.w	#5,d1
	lea	CmdYesNo(pc),a0
	lea	0(a0,d1.w),a0
	bchg	d0,Options2(a6)
	beq.s	KR.FYes
	move.l	#" OUI",(a0)
	bra.s	KR.FEnd
KR.FYes	move.l	#" NON",(a0)
KR.FEnd	move.l	Other(a6),a5
	move.b	Options2(a6),Options2(a5)

KR.End	move.l	(sp)+,d7
	add.l	$4BA.w,d7		Remet … jour le timer
	move.l	d7,SysTime0(a6)
	bra	MainLoop

KR.NoKey:
	IFEQ	CHEAT
	bra	MainLoop
	ENDC

****************************************************************************
*		Verrue de cr‚ation de tableaux
* Mode d'emploi :
*  Activer le mode CHEAT par le mot de passe (TRICHEUR en majuscules)
*  Commandes ensuite :
*  (J)ump : Donne une impulsion verticale de 300
*  SPACE  : Meme effet que Jump
*  (H)alt : Supprime la vitesse verticale (arret de la mont‚e/descente)
*  (G)rav : Passe la gravit‚ en alternance entre 0 et 20.Si … 0, fait un Halt
*  (+)(-) : D‚cale l'index d'objet actuel et l'utilise comme vaisseau
*  RETURN : Entre un nouvel objet … la position actuelle
*  DELETE : Efface l'objet le plus proche de moi (le num‚ro d'objet devient celui actuel)
*  (S)ave : Sauvegarde le r‚sultat obtenu sous le nom TABLO.TAB
*  UNDO   : Restaure le tableau par d‚faut
*  ESC    : Sort du mode CHEAT (et brouille le mot de passe)
*  CAPS   : Alternance du mode Pas-…-Pas et du mode rapide
*	  (En mode pas … pas, on attend une touche avant chaque rafraichissement d'image)
*  (X)it	: Passage au point POI, qui rentre dans la boucle sans d‚placement et en 
*	  mettant LogScreen … l'‚cran (pour d‚buggage MONST)
*
*
* Remarque : En mode CHEAT, on ne peut pas changer de tableau (toucher une
* dalle de changement de tableau ferait perdre le travail en cours)
* Parcontre, le rebond sur les dalles de sortie est perturb‚ comme sur les
* dalles en pente dans la direction de la sortie
****************************************************************************


	IFNE	CHEAT

Verrue	lea	PassWd(a6),a0
	lea	1(a0),a1
	moveq	#6,d1
V.Copie	move.b	(a1)+,(a0)+	D‚calage du mot de passe
	dbra	d1,V.Copie
	move.b	d0,(a0)		Et stockage de la derniŠre lettre

	cmp.l	#'tric',PassWd(a6)	Test du mot de passe
	bne	MainLoop
	cmp.l	#'heur',PassWd+4(a6)
	bne	MainLoop

	clr.w	StepStep(a6)
	move.w	#4,CurObj(a6)
	or.b	#6,$484.w
	clr.w	Joueur(a6)		Indique que l'on est en mode inactif

V.Loop	addq.l	#1,TimerL(a6)
	bsr	Deplace
	clr.w	JSuisMort(a6)	Au moment du ESC, il faut que ce soit nul
	move.w	SpeedX0(a6),SpeedX(a6)
	move.w	SpeedZ0(a6),SpeedZ(a6)

	bsr	Cls

	bsr	TrigInit		Initialisation des Sin et Cos
	bsr	TraceCube		Trac‚ de l'arŠne,

	bsr	DrawWorld		du reste du monde

	move.l	AdObjTab(a6),a0
	move.w	CurObj(a6),d0
	lsr.w	#1,d0
	and.w	#$FFF8,d0
	move.l	0(a0,d0.w),d0
	lea	0(a0,d0.l),a0
	movem.w	CurX(a6),d0-d2
	movem.w	d0-d2,ObjX(a6)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	add.w	#2000,PosZ(a6)
	clr.w	UseLocAng(a6)
	bsr	TransXYZ
	movem.w	d0-d2,ModObjX(a6)
	move.w	CurObj(a6),DefColor(a6)	Fixe correctement la couleur par d‚faut
	lea	CPoint1(a6),a3
	moveq	#29,d7
V.ClrPnt	clr.w	(a3)+
	dbra	d7,V.ClrPnt
	bsr	AffObj
	sub.w	#2000,PosZ(a6)

	and.w	#15,TextColor(a6)
	move.w	TextColor(a6),Couleur(a6)	Couleur en cours affich‚e en haut … gauche
	move.l	#$00000000,PolySomm(a6)
	move.l	#$00300000,PolySomm+4(a6)
	move.l	#$00300050,PolySomm+8(a6)
	move.l	#$00000050,PolySomm+12(a6)
	moveq	#4,d3
	moveq	#0,d1
	moveq	#0,d2
	lea	PolySomm(a6),a0
	bsr	FillPoly

	moveq	#0,d0
	move.w	CurX(a6),d0	Affichage des 3 coordonn‚es
	move.l	LogScreen(a6),a1
	bsr	PrNum
	move.w	CurY(a6),d0
	move.l	LogScreen(a6),a1
	lea	160*16(a1),a1
	bsr	PrNum
	move.w	CurZ(a6),d0
	move.l	LogScreen(a6),a1
	lea	160*32(a1),a1
	bsr	PrNum

	move.w	Beta(a6),d0	Affichage du cap
	and.w	#$3FF,d0
	move.l	LogScreen(a6),a1
	lea	160*48(a1),a1
	bsr	PrNum

V.Suite	tst.w	StepStep(a6)
	beq.s	V.SameScr
	move.w	#-1,-(sp)
	move.l	LogScreen(a6),-(sp)
	move.l	LogScreen(a6),-(sp)
	XBIOS	5,12
	XBIOS	37,2
	bra.s	V.OneScr

V.SameScr	bsr	SwapScrn		et permutation d'‚cran

	move.w	#2,-(sp)		Test du clavier (sauf StepStep)
	BIOS	1,4		CaractŠre clavier ?
	tst.w	d0
	bpl	V.Loop		Non

V.OneScr	move.w	#2,-(sp)
	BIOS	2,4		Lecture du caractŠre
	cmp.b	#27,d0		Presse-t-on la touche ESC ?
	bne.s	V.NoQuit	
	clr.w	Inact(a6)
	add.l	#60*200*60,SysTime0(a6)
	bra	MainLoop

* Test sur le pav‚ num‚rique des 3 coordonn‚es et de la gravit‚
V.NoQuit	moveq	#1,d1
	tst.w	StepStep(a6)
	bne.s	V.NoSt
	moveq	#100,d1
V.NoSt	cmp.b	#19,d0
	bne.s	V.NoSvDemo
	bsr	SaveDemo
V.NoSvDemo:
	cmp.b	#'8',d0
	bne.s	V.NoZP
	add.w	d1,CurZ(a6)
	bra	V.Loop
V.NoZP	cmp.b	#'2',d0
	bne.s	V.NoZM
	sub.w	d1,CurZ(a6)
	bra	V.Loop
V.NoZM	cmp.b	#'3',d0
	bne.s	V.NoYP
	add.w	d1,CurY(a6)
	bra	V.Loop
V.NoYP	cmp.b	#'9',d0
	bne.s	V.NoYM
	sub.w	d1,CurY(a6)
	bra	V.Loop
V.NoYM	cmp.b	#'6',d0
	bne.s	V.NoXP
	add.w	d1,CurX(a6)
	bra	V.Loop
V.NoXP	cmp.b	#'4',d0
	bne.s	V.NoXM
	sub.w	d1,CurX(a6)
	bra	V.Loop
V.NoXM	cmp.w	#'/',d0
	bne.s	V.NoGP
	addq.w	#1,Gravite(a6)
	bra	V.Loop
V.NoGP	cmp.w	#'*',d0
	bne.s	V.NoGM
	subq.w	#1,Gravite(a6)
	bra	V.Loop
	
V.NoGM	cmp.w	#'(',d0
	bne.s	V.NoBM
	sub.w	#16,CurObj(a6)
	cmp.w	#4,CurObj(a6)
	bge	V.Loop
	move.w	#MAXOBJ,CurObj(a6)
	bra	V.Loop


	bra	V.Loop
V.NoBM	cmp.w	#')',d0
	bne.s	V.NoBP
	add.w	#16,CurObj(a6)
	cmp.w	#MAXOBJ,CurObj(a6)
	ble	V.Loop
	move.w	#4,CurObj(a6)
	bra	V.Loop

V.NoBP	swap	d0
	cmp.w	#$3B,d0		F1 : Un tableau de moins
	bne.s	V.NoTM
	subq.w	#1,Tableau(a6)
V.TM	and.w	#$1F,Tableau(a6)
	bsr	InitOL
	bra	V.Loop
V.NoTM	cmp.w	#$3C,d0
	bne.s	V.NoTP
	addq.w	#1,Tableau(a6)
	bra.s	V.TM

V.NoTP	cmp.w	#$17,d0		'I'
	bne.s	V.NoI
	not.w	Inact(a6)
	bra	V.Loop

V.NoI	cmp.w	#$3D,d0		Changement de couleur
	bne.s	V.NoCM		Couleur
	subq.w	#1,TextColor(a6)
	bra	V.Loop
V.NoCM	cmp.w	#$3E,d0
	bne.s	V.NoCP
	addq.w	#1,TextColor(a6)
	bra	V.Loop

V.NoCP	move.w	TextColor(a6),d1	Changement de palette
	add.w	d1,d1
	lea	$FFFF8240.w,a0
	cmp.w	#4,d1
	bge.s	V.NoTrick
	lea	BackColor(a6),a0
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

V.Jmp	move.w	#-300,SpeedY(a6)
	bra	V.Loop

V.NoJmp	cmp.w	#$23,d0		'H' ?
	bne.s	V.NoHlt
	clr.w	SpeedY(a6)
	bra	V.Loop

V.NoHlt	cmp.w	#$22,d0		'G' ?
	bne.s	V.NoGrav
	tst.w	Gravite(a6)
	beq.s	V.DepY
	clr.w	Gravite(a6)
	clr.w	SpeedY(a6)
	bra	V.Loop
V.DepY	move.w	#20,Gravite(a6)
	bra	V.Loop

V.NoGrav	cmp.w	#$4A,d0		'-'
	bne.s	V.NoMoins
	subq.w	#1,CurObj(a6)
	cmp.w	#4,CurObj(a6)
	bge	V.Loop
	move.w	#MAXOBJ,CurObj(a6)
	bra	V.Loop

V.NoMoins	cmp.w	#$4E,d0		'+'
	bne.s	V.NoPlus
	addq.w	#1,CurObj(a6)
	cmp.w	#MAXOBJ,CurObj(a6)
	ble	V.Loop
	move.w	#4,CurObj(a6)
	bra	V.Loop

V.NoPlus	cmp.w	#$1C,d0
	bne.s	V.NoRet
	move.w	ObjNum(a6),d0
	lsl.w	#5,d0
	lea	OList(a6),a0
	lea	0(a0,d0.w),a0
	move.w	CurObj(a6),(a0)+
	clr.w	(a0)+
	movem.w	CurX(a6),d0-d2

	movem.w	d0-d2,(a0)
	addq.w	#1,ObjNum(a6)
	bra	V.Loop

V.NoRet	cmp.w	#$61,d0
	bne.s	V.NoUndo
	bsr	InitOL
	bra	V.Loop

V.NoUndo	cmp.w	#$21,d0		'F'ast
	bne.s	V.NoFast
	not.w	StepStep(a6)
	bra	V.Loop

V.NoFast	cmp.w	#$53,d0		Delete
	bne.s	V.NoDel
	move.w	ObjNum(a6),d6
	subq.w	#1,d6
	ble	V.Loop
	move.w	#32000,d7		Distance par d‚faut
	lea	OList(a6),a0	Pointeur sur liste d'objets
	sub.l	a1,a1
V.DelLp	cmp.w	#$30,(a0)
	ble.s	V.CantDel
	movem.w	4(a0),d0-d2
	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	d7,d0
	bge.s	V.CantDel
	move.w	d0,d7
	move.l	a0,a1
V.CantDel	lea	32(a0),a0
	dbra	d6,V.DelLp
	move.l	a1,d0
	beq	V.Loop		Si rien … effacer d'autre que les vaisseaux
	move.w	(a1),d0
	move.w	d0,CurObj(a6)
	mulu	#6,d0
	movem.w	4(a1),d0-d2
	movem.w	d0-d2,CurX(a6)
	lea	AO.FerTab(a6),a2
V.Delete	move.l	32(a1),(a1)+
	cmp.l	a2,a1
	blt.s	V.Delete
	subq.w	#1,ObjNum(a6)

	bra	V.Loop

V.NoDel	cmp.w	#$1F,d0		'S'ave
	bne	V.NoSv

* Sauvegarde sur disque du tableau obtenu
	move.w	#-1,-(sp)
	move.l	PhyScreen(a6),-(sp)
	move.l	PhyScreen(a6),-(sp)
	XBIOS	5,12		Met l'‚cran sur "PhyScreen"

	pea	FileText(pc)	Affiche "Nom de fichier :"
	GEMDOS	9,6
	pea	FileNLen(pc)	Lecture du nom de fichier
	GEMDOS	10,6
	lea	FileNLen(pc),a0
	clr.b	2(a0,d0.w)	Met un 0 … la fin du nom

	move.l	PhyScreen(a6),a4
	move.l	a4,a5
	move.w	Gravite(a6),(a4)+	Stocke l'acc‚l‚ration verticale
	move.w	ObjNum(a6),d0
	move.w	d0,(a4)+		Stocke le nombre d'objets
	subq.w	#1,d0

	movem.l	$FFFF8240.w,d1-d7/a3
	movem.l	d1-d7/a3,(a4)	Stockage des couleurs
	lea	40(a4),a4

	moveq	#0,d7		Nombre d'objets sauv‚s
	lea	OList(a6),a1
V.SaveLp	movem.w	(a1)+,d1-d5
	lea	22(a1),a1
	cmp.w	#$30,d1
	ble.s	V.NoSave
V.Save	movem.w	d1-d5,(a4)
	lea	10(a4),a4
	addq.w	#1,d7
V.NoSave	dbra	d0,V.SaveLp
	move.w	d7,2(a5)		Stocke le nombre d'objets
	sub.l	a5,a4		a4 : Longueur … sauver

	clr.w	-(sp)		Fichier Lecture / Ecriture
	pea	FileName(pc)	
	GEMDOS	$3C,8		CREATE
	move.w	d0,-(sp)		Sauvegarde du Handle
	move.l	PhyScreen(a6),-(sp)	Tampon des donn‚es
	move.l	a4,-(sp)		Longueur de sauvegarde
	move.w	d0,-(sp)		Handle
	GEMDOS	$40,12		WRITE
	GEMDOS	$3E,4		CLOSE (le handle est d‚j… dans la pile)

	bra	V.Loop

V.NoSv	cmp.w	#$26,d0		'L'oad
	bne	V.NoLd

	move.w	#-1,-(sp)
	move.l	PhyScreen(a6),-(sp)
	move.l	PhyScreen(a6),-(sp)
	XBIOS	5,12		Met l'‚cran sur "PhyScreen"

	pea	FileText(pc)	Affiche "Nom de fichier :"
	GEMDOS	9,6
	pea	FileNLen(pc)	Lecture du nom de fichier
	GEMDOS	10,6
	lea	FileNLen(pc),a0
	clr.b	2(a0,d0.w)	Met un 0 … la fin du nom

	clr.w	-(sp)		Accessible en lecture seule
	pea	FileName(pc)	Nom du fichier
	GEMDOS	$3D,8		OPEN
	tst.w	d0		Teste si le fichier existe
	bmi	V.Loop		Non

	move.w	d0,d7		Stockage du Handle
	move.l	PhyScreen(a6),-(sp)	Tampon de lecture
	pea	44.w		Lecture longueur tableau et gravit‚
	move.w	d7,-(sp)		Handle
	GEMDOS	$3F,12		READ

	move.l	PhyScreen(a6),a0
	move.w	2(a0),d0		Longueur du tableau
	mulu	#10,d0		Longueur totale du tableau
	pea	44(a0)		Lecture de la suite
	move.l	d0,-(sp)		Longueur
	move.w	d7,-(sp)		Handle
	GEMDOS	$3F,12		READ

	move.w	d7,-(sp)		Handle
	GEMDOS	$3E,4		CLOSE
	move.l	PhyScreen(a6),a0
	bsr	InitOL.a0		Initialisation liste d'objets
	bra	V.Loop

V.NoLd	cmp.w	#$62,d0		Touche HELP
	bne	V.Loop

	move.w	#-1,-(sp)
	move.l	PhyScreen(a6),-(sp)
	move.l	PhyScreen(a6),-(sp)
	XBIOS	5,12		Met l'‚cran sur "PhyScreen"

	pea	HelpText(pc)
	GEMDOS	9,6		Affiche le texte d'aide

	GEMDOS	1,2		Attend une touche
	bra	V.Loop

FileNLen	dc.b	16,0
FileText	dc.b	27,"Y",40,32,27,"eNom du fichier (.TAB) :",0

HelpText	dc.b      27,"E",27,"p"
	dc.b	"    RESUME DES COMMANDES MODE CHEAT   ",27,"q",13,10
	dc.b	"+,-: S‚lection d'objet",13,10
	dc.b	"(,): S‚lection grossiŠre d'objets",13,10
	dc.b	"*,/: Variation de la gravit‚",13,10
	dc.b	"F1,F2: Tableau suivant/pr‚c‚dent",13,10
	dc.b	"F3,F4: Changement de la couleur",13,10
	dc.b	"F5-F10: Changement R/V/B",13,10
	dc.b	"RETURN: Pose d'objet",13,10
	dc.b	"DELETE: Suppression du plus proche",13,10
	dc.b	"F: Mode FAST/SLOW",13,10
	dc.b	"G: Gravit‚ ES/HS",13,10
	dc.b	"H: Arret vertical",13,10
	dc.b	"I: Objets Inactifs/actifs",13,10
	dc.b	"J/SPACE: Saut",13,10
	dc.b	"L: Chargement de tableau",13,10
	dc.b	"S: Sauvegarde de tableau",13,10
	dc.b	"CTRL-S: Sauvegarde de la d‚mo",13,10
	dc.b	"UNDO: Restaure le tableau initial",13,10
	dc.b	"ESC: Sortie du mode CHEAT",13,10
	dc.b	0

	ENDC




****************************************************************************
*	Transformation de la valeur contenue dans D0 en chiffres
****************************************************************************
* Entr‚e : D0 : Donn‚e (entre +-9999)
*	 A0 : Adresse o— stocker le r‚sultat
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
	tst.w	Resol(a6)
	beq	FastPrt
	bra	HiFPrt
	
N2S.Buf	dc.b	'+0000',0

****************************************************************************
*		Fin du programme : On quitte proprement
****************************************************************************
Fin	tst.w	Resol(a6)
	bne.s	Fin.HAM
	bsr	ClearHAM		Supprime les interruptions de changement de palette

Fin.HAM	pea	RestMouse(pc)
	move.w	#2,-(sp)
	XBIOS	25,8

	move.b	#6,$484.w
	move.w	OldResol(a6),-(sp)
	move.l	DefScreen(a6),-(sp)
	move.l	DefScreen(a6),-(sp)
	XBIOS	5,12

	XBIOS	34,2		KBDVBASE
	move.l	d0,a0
	move.l	OldMsVec(a6),16(a0)	Restaure l'ancienne routine souris
	move.l	OldJoyst(a6),24(a0)
	dc.w	$a009		Montre la souris

	move.l	IK.Patch+2(pc),$118.w	Restauration de l'interruption

	move.l	TabNames(a6),-(sp)
	GEMDOS	$49,6		MFREE
	move.l	Tableaux(a6),-(sp)
	GEMDOS	$49,6
	move.l	BckScreen(a6),-(sp)
	GEMDOS	$49,6

	move.l	SpareUSP(a6),-(sp)
	GEMDOS	$20,6

FinProg	clr.w	-(sp)
	trap	#1

RestMouse	dc.b	$15,$08


SaveDemo	clr.w	-(sp)		Fichier Lecture / Ecriture
	pea	DemoName(pc)	
	GEMDOS	$3C,8		CREATE
	move.w	d0,-(sp)		Sauvegarde du Handle
	move.l	MoveMemAd(a6),-(sp)	Tampon des donn‚es
	move.l	EndMvMem(a6),a4
	sub.l	(sp),a4		Longueur de sauvegarde
	move.l	a4,-(sp)		Longueur de sauvegarde
	move.w	d0,-(sp)		Handle
	GEMDOS	$40,12		WRITE
	GEMDOS	$3E,4		CLOSE (le handle est d‚j… dans la pile)
	bclr	#2,Options1(a6)
	rts

DemoName	dc.b	'DEMO.INC',0


***************************************************************************
*		D‚marrage d'un tableau
***************************************************************************
NewTablo	tst.w	Sortie(a6)	Si premiere entr‚e
	bmi.s	NewT.Strt		Alors pas de d‚grad‚ extinction

	moveq	#15,d7
NewT.1	moveq	#15,d6
	lea	CurColor(a6),a0
	move.l	Other(a6),a5

NewT.1C	move.w	(a0),d0
	and.w	#$777,d0
	lsr.w	#1,d0
	move.w	d0,(a0)+
	dbra	d6,NewT.1C

	move.w	d7,-(sp)

	btst	#1,Options1(a6)	Si un seul joueur
	bne.s	NewT.OneP
	movem.l	CurColor(a6),d0-d7	Alors copie des couleurs
	movem.l	d0-d7,CurColor(a5)

NewT.OneP	XBIOS	37,2
	move.w	(sp)+,d7
	dbra	d7,NewT.1

NewT.Strt	bsr	InitOL

	lea	TabName(pc),a0
	move.l	TabNames(a6),a1
	move.l	TabVisitAd(a6),a2
	move.w	Tableau(a6),d0
	move.w	Joueur(a6),d1
	addq.w	#1,d1
	move.b	d1,0(a2,d0.w)

	subq.w	#1,d0		Lecture du nom du tableau
	bmi.s	NewT.EntN		Cas ou le tableau est 0
NewT.LkNm	tst.b	(a1)+		Sinon cherche le bon
	bne.s	NewT.LkNm
	dbra	d0,NewT.LkNm

NewT.EntN	moveq	#-1,d0
	move.l	a1,a2
	moveq	#15,d1
NewT.Leng	addq.w	#1,d0
	tst.b	(a2)+
	dbeq	d1,NewT.Leng		D0= Longueur du nom du tableau

	moveq	#40,d1
	tst.w	Resol(a6)
	beq.s	NewT.LoR
	moveq	#80,d1
NewT.LoR	sub.w	d0,d1
	asr.w	#1,d1
	
NewT.Spcs	move.b	#' ',(a0)+
	dbra	d1,NewT.Spcs

NewT.Copy	move.b	(a1)+,(a0)+
	bne.s	NewT.Copy
*	bsr	DrawIcons		Affichage du panneau d'icones

	lea	OList(a6),a1	Recherche de la porte compl‚mentaire ‚ventuelle
	move.w	ObjNum(a6),d7
	subq.w	#1,d7
	move.w	Sortie(a6),d6
	and.w	#$FFF0,d6		Elimination de la couleur
	bmi.s	NewT.Door
	sub.w	#$20,d6		D‚calage de 180 degr‚s
	and.w	#$30,d6		R‚cupŠre un num‚ro de porte de 0-3
	add.w	#$40,d6		Num‚ro de la premiŠre porte

NewT.Door	movem.w	(a1),d0-d4
	lea	32(a1),a1
	and.w	#$FFF0,d0
	cmp.w	d6,d0
	dbeq	d7,NewT.Door
	bne.s	NewT.NoDr
	movem.w	d2-d4,CurX(a6)
	sub.w	#1000,CurY(a6)
	move.w	#250,d5
	move.w	#-1000,d6
	move.w	Beta(a6),d7
	neg.w	d7
	bsr	Rotate
	sub.w	d0,CurX(a6)
	sub.w	d1,CurZ(a6)

NewT.NoDr	clr.w	SpeedX(a6)
	clr.w	SpeedY(a6)
	clr.w	SpeedZ(a6)

	bsr	DessTout
	moveq	#3,d7
	moveq	#0,d2
NewT.2	moveq	#15,d6
	lea	CurColor(a6),a0
	lea	BackColor(a6),a1
NewT.2C	move.w	(a1)+,d0
	lsr.w	d7,d0
	and.w	d2,d0
	move.w	d0,(a0)+

	dbra	d6,NewT.2C
	add.w	d2,d2
	or.w	#$111,d2
	movem.w	d2/d7,-(sp)
	btst	#1,Options1(a6)
	beq.s	NewT.1P2
	tst.w	Sortie(a6)
	bpl.s	NewT.2ndF
NewT.1P2	move.l	Other(a6),a5
	movem.l	CurColor(a6),d0-d7
	movem.l	d0-d7,CurColor(a5)

NewT.2ndF	XBIOS	37,2
	movem.w	(sp)+,d7/d2
	dbra	d7,NewT.2

	movem.l	BackColor(a6),d0-d7		R‚tablit les couleurs compatibles STE
	movem.l	d0-d7,CurColor(a6)

	rts


***************************************************************************
*		Programme d'affichage des scores
***************************************************************************
VS.Text	dc.b	27,0,13,13,13,13,13,13,13,13
*	dc.b	"012345678901234567890123456789012345678"
	dc.b	"FELICITATIONS",13,13,13,13,13
	dc.b	"Joueur "
VS.Joueur	dc.b	"1, vous ˆtes un des meilleurs",13
	dc.b	"joueurs aujourd'hui.",13
	dc.b	"Votre score total est de:"
VS.Score	dc.b	"00000000.",13,13
	dc.b	"Entrez votre nom:"
	dc.b	13,13,13,13,13,1,0,17,"> ",0
	EVEN

* Teste si on entre dans le tableau des scores
VS.Check	lea	TheScores+31(pc),a1
	moveq	#13,d7		Nombre de scores … tester
VS.Chk1	moveq	#7,d6		8 caractŠres
	move.l	a0,a2
	move.l	a1,a3
VS.Chk2	move.b	(a2)+,d0
	cmp.b	(a3)+,d0
	bgt.s	VS.Enter
	blt.s	VS.Next
	dbra	d6,VS.Chk2

VS.Next	lea	39(a1),a1
	dbra	d7,VS.Chk1
	rts

* Entre quelqu'un dans le tableau des scores
VS.Enter	lea	-31(a1),a1
	move.l	a1,-(sp)

	lea	TheScores.End(pc),a3
	lea	-39(a3),a2
VS.CopyT	cmp.l	a1,a2
	ble.s	VS.CpyTE
	move.b	-(a2),-(a3)
	bra.s	VS.CopyT

VS.CpyTE	move.l	a1,a2		Effacement de l'ancien nom
	moveq	#30,d7
VS.Clear	move.b	#' ',(a2)+
	dbra	d7,VS.Clear

	lea	31(a1),a2
	lea	VS.Score(pc),a1
	moveq	#7,d0
VS.CopyS	move.b	(a0)+,d1
	move.b	d1,(a1)+
	move.b	d1,(a2)+
	dbra	d0,VS.CopyS

	lea	VS.Text(pc),a0
	bsr	PrintItAll
	move.l	(sp)+,a1		R‚cupŠre l'adresse o— stocker le nom

VS.WaitK	move.l	a1,-(sp)
	bsr	DrawFond
	bsr	KeyPressed
	move.l	(sp)+,a1

	move.w	d2,d0
	beq.s	VS.WaitK
	cmp.b	#13,d0
	beq.s	VS.QuitE

	cmp.b	#8,d0
	bne.s	VS.NoBSp
	cmp.w	#2,TextCol(a6)
	beq.s	VS.WaitK

	move.l	AdTScreen(a6),a2
	move.w	TextPos(a6),d1
	lea	0(a2,d1.w),a2
	clr.b	240(a2)
	clr.b	280(a2)
	subq.w	#1,TextCol(a6)
	subq.w	#1,TextPos(a6)
	move.b	#' ',-(a1)
	clr.b	-1(a2)
	clr.b	39(a2)
	clr.b	79(a2)
	clr.b	119(a2)
	clr.b	159(a2)
	clr.b	199(a2)
	st	239(a2)
	st	279(a2)
	bra.s	VS.WaitK
	
VS.NoBSp	cmp.w	#30,TextCol(a6)
	bge.s	VS.WaitK

	cmp.b	#32,d0
	bcs.s	VS.WaitK
	move.b	d0,(a1)+
	and.w	#$FF,d0

	move.l	a1,-(sp)
	bsr	PC.Print
	move.l	(sp)+,a1

	bra	VS.WaitK
VS.QuitE	rts
	
DispScores:
	bsr	VS.NoUpdate
	bra	MainMenu

ViewScore	bsr	InitDrawFond
	bsr	DrawFond
	bsr	KeyPressed
	tst.w	d0
	bmi.s	ViewScore

	tst.w	InputDev(a6)
	bmi.s	VS.NoUpdate

	tst.w	Joueur(a6)
	beq.s	VS.Plyr1
	bsr	SwapVars

VS.Plyr1	lea	Score(pc),a0	A0 pointe sur le score en cours
	lea	VS.Joueur(pc),a1	Ecrit Joueur 1
	move.b	#'1',(a1)
	bsr	VS.Check

	btst	#1,Options1(a6)
	beq.s	VS.NoUpdate
	bsr	SwapVars
	lea	Score2(pc),a0
	lea	VS.Joueur(pc),a1
	move.b	#'2',(a1)
	bsr	VS.Check
	bsr	SwapVars

* Affichage sans modification du score
VS.NoUpdate:
	lea	ScoreTable(pc),a0
	bra	PrintText


ScoreTable:
*	dc.b	"012345678901234567890123456789012345678"
	dc.b	27,0,13,13,13,13,13
	dc.b	"           TABLEAU DES SCORES",13
	dc.b	13
	dc.b	"Aujourd'hui, les meilleurs joueurs ont",13
	dc.b	"obtenu les r‚sultats suivants:",13
	dc.b	13
	dc.b	13
TheScores	dc.b	"Christophe de DINECHIN         12345678"
	dc.b	"Fred l'adapteur fou            00200000"
	dc.b	"Fran‡ois PARIS                 00100000"
	dc.b	"Christophe HURBIN              00090000"
	dc.b	"Christophe ROCHET              00080000"
	dc.b	"Baltazar MARTINS-DIAZ          00070000"
	dc.b	"Laurent DAVERIO                00060000"
	dc.b	"Richard MEYER                  00050000"
	dc.b	"Christian DEVILLE-CAVELLIN     00040000"
	dc.b	"Michel IAGOLNITZER             00030000"
	dc.b	"Raphael MANFREDI               00020000"
	dc.b	"Thibaud DUBOUX                 00010000"
	dc.b	"Les joyeux mineurs             00007500" 
	dc.b	"L'‚quipe d'Infogrames          00005000"
TheScores.End:
	dc.b	11,0
	EVEN


***************************************************************************
*		Mon petit d‚lire personnel
***************************************************************************
ChargeJeu	lea	LoadText(pc),a0
	bsr	PrintItAll
	lea	FileName(pc),a1	Lecture du nom de fichier

	bsr	VS.WaitK
	clr.b	(a1)+
	cmp.w	#2,TextCol(a6)	Si nom de fichier vide
	beq.s	OldLoad
	move.w	#-1,DoLoad(a6)
	bsr	LoadGame
OldLoad	bra	MM.Wait

FileName	ds.b	64
LoadText	dc.b	27,0,13,13,13,13,13,13,13,13,13,13
*	dc.b	"012345678901234567890123456789012345678"
	dc.b	"CHARGEMENT D'UN FICHIER DISQUE",13
	dc.b	13
	dc.b	"Introduisez la disquette de sauvegarde",13
	dc.b	"dans le lecteur et donnez le nom du",13
	dc.b	"fichier de sauvegarde. Un nom vide",13
	dc.b	"indique la derniŠre partie charg‚e.",13
	dc.b	13,13,13,13,13,1,0,17,"> ",0
	EVEN


*
* Initialisation des objets du fond tournant pendant la demo
*
InitDrawFond:
	move.l	BckScreen(a6),a1
	movem.l	2(a1),d0-d7
	movem.l	d0-d7,BackColor(a6)
	movem.l	d0-d7,CurColor(a6)
	move.l	Other(a6),a5
	movem.l	d0-d7,BackColor(a5)
	movem.l	d0-d7,CurColor(a5)

	lea	DF.Back(pc),a0
	lea	DrawFond(pc),a1
	move.l	a0,2(a1)

	lea	OList(a6),a0	Initialisation du monde de Demo
	lea	DemoWorld(pc),a1
	moveq	#5,d0
IDF.1	move.w	(a1)+,(a0)
	move.l	(a1)+,4(a0)
	move.w	(a1)+,8(a0)
	lea	32(a0),a0
	dbra	d0,IDF.1
	move.w	#6,ObjNum(a6)

	move.w	#7000,PosZ(a6)
	move.w	#2048,KFactor(a6)
	move.w	#7,LFactor(a6)
	clr.w	CurX(a6)
	clr.w	CurY(a6)
	move.w	#2000,CurZ(a6)
	rts

DemoWorld	dc.w	Bonus.N+1,-6000,0,0
	dc.w	Bonus.N+2,+6000,0,0
	dc.w	Cube500.N+1,0,-6000,0
	dc.w	Cube500.N+2,0,+6000,0
	dc.w	Diamond.N+1,0,0,-6000
	dc.w	Diamond.N+2,0,0,+6000

***************************************************************************
*		S‚lection des options pour les joueurs
***************************************************************************
SelectOptions:
	bclr	#1,Options1(a6)
	bclr	#1,Options2(a6)		Passe en mode remplissage de polys

	subq.w	#4,InputDev(a6)
	bsr	OnePlayer
	addq.w	#4,InputDev(a6)

	bsr	InitDrawFond
	bsr	PrintTit
	tst	InputDev(a6)
	bmi.s	SO.Demo
	bsr	MainMenu
SO.Demo	bsr	LetsGo
	rts

***************************************************************************
*		Menu principal
***************************************************************************
MainMenu	lea	MainMenuText(pc),a0
	move.w	Main.MID(a6),d0
	bsr	MakeMenu
	move.w	d0,Main.MID(a6)
	cmp.w	#13,d0		Menu QUIT
	beq	Fin

	cmp.w	#9,d0
	beq.s	MM.ChangeJ1	Change joueur 1
	cmp.w	#10,d0
	beq.s	MM.ChangeJ2
	cmp.w	#12,d0		Informations g‚n‚rales
	beq	ChargeJeu
	cmp.w	#11,d0
	beq	DispScores

	clr.w	DoLoad(a6)	Indique pas de LOAD
	bclr	#1,Options1(a6)
	cmp.w	#8,d0		Connection simultan‚e
	bne.s	MM.Wait
	bset	#1,Options1(a6)
	move.l	Other(a6),a5
	move.b	Options1(a6),Options1(a5)	Utilise le mode Bicolore eventuelement

MM.Wait	bsr	KeyPressed
	tst.w	d0
	bmi.s	MM.Wait
	rts

* Changement des controleurs pour les joueurs 1 et 2
MM.ChangeJ2:
	lea	Joueur2.C(pc),a0	A0= Texte de description
	move.l	Other(a6),a5
	lea	InputDev(a5),a1	A1= InputDev
	bra.s	MM.ChangeC
MM.ChangeJ1:
	lea	Joueur1.C(pc),a0
	lea	InputDev(a6),a1
MM.ChangeC:
	move.w	(a1),d0
	addq.w	#1,d0
	cmp.w	#3,d0
	blt.s	MM.ChC1
	moveq	#0,d0
MM.ChC1	move.w	d0,(a1)
	mulu	#10,d0
	lea	MM.CtrlNames(pc,d0.w),a1
	REPT	10
	move.b	(a1)+,(a0)+
	ENDR
	bra	MainMenu

MM.CtrlNames:
	dc.b	"Joystick 1"
	dc.b	"Joystick 2"
	dc.b	"Clavier   "

MainMenuText:
*	dc.b	"012345678901234567890123456789012345678"
	dc.b	7,13,27,0,1,0,24
	dc.b	13
	dc.b	13,13,13,13,13,13
	dc.b	"          Partie … un joueur",13
	dc.b	"         Partie … deux joueurs",13
	dc.b	"   Contr“le du Joueur 1: "
Joueur1.C	dc.b	"Joystick 2",13
	dc.b	"   Contr“le du Joueur 2: "
Joueur2.C	dc.b	"Clavier   ",13
	dc.b	"           Tableau des scores",13
	dc.b	"     Chargement d'une partie sauv‚e",13
	dc.b	"          Quitter ALPHA WAVES",13
	dc.b	13,13,13,13,13,13,13
	dc.b	0

***************************************************************************
*		S‚lection d'un menu
* Entr‚e: A0 pointe sur le texte du menu, qui commence par deux octets
* qui indiquent les lignes extrˆmes du menu
*	D0 indique sur quelle ligne commence le menu
* Sortie: D0 indique la ligne s‚lectionn‚e
***************************************************************************
MakeMenu	lea	JoyStick1(pc),a1
	clr.l	(a1)		Efface la souris ‚ventuellement

	moveq	#0,d6		R‚cupŠre la position du menu
	move.b	(a0)+,d6
	moveq	#0,d7
	move.b	(a0)+,d7
	movem.w	d0/d6-d7,-(sp)

	bsr	PrintItAll	Affiche le message du menu

	movem.w	(sp)+,d0-d2
	move.w	d0,d7
	bsr	InvertLine

MM.Boucle	movem.w	d0-d2,-(sp)	Stocke le no de ligne courant
	bsr	DrawFond
	lea	JoyStick2(pc),a1
	movem.w	(sp)+,d0-d2	R‚cupŠre le no de la ligne courante et les extremes
	move.b	(a1)+,d6
	or.b	(a1)+,d6
	bmi.s	MM.Exit

	btst	#0,d6		D‚placement vers le haut
	beq.s	MM.NoUp
	move.w	d0,d7
	bsr.s	InvertLine
	subq.w	#1,d0
	cmp.w	d1,d0
	bge.s	MM.OkUp
	move.w	d2,d0
MM.OkUp	move.w	d0,d7
	bsr	InvertLine

MM.Clear	movem.w	d0-d2,-(sp)
	bsr	DrawFond
	movem.w	(sp)+,d0-d2

	lea	Joystick2(pc),a1	Attend que relach‚
	move.b	(a1)+,d6
	or.b	(a1)+,d6
	and.w	#3,d6
	bne.s	MM.Clear
	bra.s	MM.Boucle

MM.NoUp	btst	#1,d6
	beq.s	MM.Boucle
	move.w	d0,d7
	bsr	InvertLine
	addq.w	#1,d0
	cmp.w	d2,d0
	ble.s	MM.OkDn
	move.w	d1,d0
MM.OkDn	move.w	d0,d7
	bsr	InvertLine
	bra.s	MM.Clear

MM.Exit	move.w	d0,-(sp)

MM.WaitUp	bsr	DrawFond		Attend que l'on ait relach‚
	bsr	KeyPressed
	tst.w	d0
	bmi.s	MM.WaitUp

	move.w	(sp)+,d0

	rts


* Inverse une ligne … l'‚cran.
InvertLine:
	move.l	AdTScreen(a6),a0
	mulu	#320,d7
	lea	0(a0,d7.w),a0
	moveq	#79,d7
IL.Boucle	not.l	(a0)+
	dbra	d7,IL.Boucle
	rts

***************************************************************************
*		Affichage de la page de titre
***************************************************************************

PrintTit	lea	TitleText(pc),a0
	bsr	PrintText

PT.Releas	bsr	DrawFond
	bsr	KeyPressed
	tst.w	d0
	bmi.s	PT.Releas

	clr.w	-(sp)
PT.Boucle	addq.w	#1,(sp)
	cmp.w	#100,(sp)		Attente de 10 s
	bge.s	PT.Demo

	bsr	DrawFond
	bsr	KeyPressed
	tst.w	d0
	bpl.s	PT.Boucle

	addq.l	#2,sp
	rts

PT.Demo	subq.w	#4,InputDev(a6)	Passage en mode d‚monstration
	addq.l	#2,sp
	rts


***************************************************************************
*		D‚part proprement dit
***************************************************************************
LetsGo	lea	StrtText(pc),a0	Ici, affichage du texte de d‚part
	bra	PrintText

PrintItAll:
	bsr	PrintText
LG.Boucle	tst.w	d0
	bpl.s	LG.Retour
	bsr	PrText.1
	bra.s	LG.Boucle
LG.Retour	rts

***************************************************************************
*		Texte de la page de titre
***************************************************************************
TitleText	dc.b	27,0,13,13,13,13,13,13,13
*	dc.b	"012345678901234567890123456789012345678"
	dc.b	"              ALPHA WAVES",13
	dc.b	13
	dc.b	"          (C) 1990 Infogrames",13
	dc.b	"           et C. de DINECHIN",13
	dc.b	13
	dc.b	"          Entrez dans le",13
	dc.b	"        monde des ondes Alpha",13
	dc.b	"      … la recherche de vos rˆves",13
	dc.b	13,13,13
	dc.b	"         Version Bˆta No 001",13
	dc.b	13,13
	dc.b	0

***************************************************************************
*		Texte au moment du d‚part du jeu
***************************************************************************

StrtText	dc.b	13,13,13,13,13,13,27,60
*	dc.b	"012345678901234567890123456789012345678"
	dc.b	"Dans quelques instants, vous allez",13
	dc.b	"entrer dans le monde du rˆve, au plus",13
	dc.b	"profond de votre cerveau.",13
	dc.b	"D‚tendez vous, relaxez vous, et",13
	dc.b	"accrochez vous … votre Joystick...",13
	dc.b	13,13,13,13
	dc.b	"***************************************"
	dc.b	"* Vous souffrez de trouble du sommeil?*"
	dc.b	"* Alpha Dreams Corp. vous apporte la  *"
	dc.b	"* solution … vos problŠmes.           *"
	dc.b	"* Alpha-Waves  est  un  dispositif    *"
	dc.b	"* r‚volutionnaire, qui ‚met des ondes *"
	dc.b	"* alpha, g‚n‚ratrices d'un sommeil    *"
	dc.b	"* r‚parateur et agr‚able.             *"
	dc.b	"***************************************",13,13,13
	dc.b	"             ALPHA WAVES",13
	dc.b	"et retrouvez les rˆves de vos rˆves !"
	dc.b	13,13,13,13
	dc.b	"NOTE IMPORTANTE:",13
	dc.b	"En l'‚tat actuel de la technique,",13
	dc.b	"il est impossible de rep‚rer de fa‡on",13
	dc.b	"automatique la position dans le cerveau"
	dc.b	"des 16 centres r‚ceptifs aux ondes",13
	dc.b	"alpha.",13,13
	dc.b	"C'est pourquoi, la premiŠre fois que",13
	dc.b	"vous brancherez Alpha Waves, un petit",13
	dc.b	"programme vous permettra d'explorer",13
	dc.b	"le contenu de votre propre cerveau",13
	dc.b	"… la recherche de ces centres.",13,13
	dc.b	"Ces centres seront repr‚sent‚s par le",13
	dc.b	"programme sous la forme d'‚toiles …",13
	dc.b	"6 branches.",13,13
	dc.b	"Pour ‚viter de nuire … votre sant‚",13
	dc.b	"le programme se d‚branche de votre",13
	dc.b	"cerveau si vous restez trop longtemps",13
	dc.b	"au mˆme endroit.",13
	dc.b	"Vous ˆtes donc parfaitement en s‚curit‚",13,13
	dc.b	"Les diff‚rentes options du programme",13
	dc.b	"sont accessibles grƒce … la touche ESC",13
	dc.b	27,128,13,32,13,32,13,32,13,32,13,32
	dc.b	13,32,13,32,13,32,13,32,13,32,13,32,0


***************************************************************************
*		Affichage de texte sur fond tournant
*	Entr‚e avec a0 pointant sur le texte … afficher.
*	Retourne avec d0=0 si Out of Time, D0=-1 si KeyPressed
***************************************************************************
PrintText	tst.w	Joueur(a6)
	beq.s	PrText.J1
	bsr	SwapVars

PrText.J1	clr.w	TextWait(a6)
	clr.w	TextWait0(a6)
	move.l	a0,TextAd(a6)


PrText.1	tst.w	TextWait(a6)	Teste si fin du texte
	bpl.s	PrText.C
	moveq	#0,d0		Retour avec d0=0
PrText.R	rts

PrText.C	bsr	KeyPressed	Si Fire press‚
	tst.w	d0
	bmi.s	PrText.R		Retour avec d0<>0

	moveq	#63,d7
PrText.2	move.w	d7,-(sp)
	bsr	PrintChar
	move.w	(sp)+,d7
	dbra	d7,PrText.2

	bsr	DrawFond
	bra	PrText.1


***************************************************************************
*		Superposition de l'‚cran texte sur l'‚cran
***************************************************************************
Text2ScrN	move.l	AdTScreen(a6),a0
	move.l	LogScreen(a6),a1
	tst.w	Resol(a6)
	bne.s	T2S.NH
	lea	1600(a1),a1
	move.w	#3599,d0
T2S.1	move.w	(a0)+,d1
	or.w	d1,(a1)+		Couleur utilis‚e no 15
	or.w	d1,(a1)+
	or.w	d1,(a1)+
	or.w	d1,(a1)+
	dbra	d0,T2S.1
	rts

Text2ScrI	move.l	AdTScreen(a6),a0
	move.l	LogScreen(a6),a1
	tst.w	Resol(a6)
	bne.s	T2S.IH
	lea	1600(a1),a1
	move.w	#3599,d0
T2SI.1	move.w	(a0)+,d1
	not.w	d1
	and.w	d1,(a1)+		Couleur utilis‚e no 0
	and.w	d1,(a1)+
	and.w	d1,(a1)+
	and.w	d1,(a1)+
	dbra	d0,T2SI.1
	rts

T2S.NH	move.w	#199,d0
	lea	1620(a1),a1
T2S.NH1	moveq	#19,d1
	move.l	a1,a2
T2S.NH2	move.w	(a0)+,d2
	or.w	d2,(a2)+
	or.w	d2,78(a2)
	dbra	d1,T2S.NH2
	lea	160(a1),a1
	dbra	d0,T2S.NH1
	rts

T2S.IH	move.w	#199,d0
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
	rts


***************************************************************************
*		Affichage d'un caractŠre
***************************************************************************
PC.WaitUp	move.w	#200,d7
PC.Loop	move.w	d7,-(sp)	Attend qu'on appuie
	bsr	DrawFond
	move.w	(sp)+,d7
	bsr	KeyPressed
	tst.w	d0
	dbmi	d7,PC.Loop
PC.Loop2	bsr	DrawFond		Attend qu'on relache
	bsr	KeyPressed
	tst.w	d0
	bmi.s	PC.Loop2
	rts

PC.At	move.b	(a0)+,d0		Position
	moveq	#0,d1
	move.b	(a0)+,d1
	move.l	a0,TextAd(a6)
	mulu	#320,d1
	add.w	d0,d1
	move.w	d0,TextCol(a6)
	move.w	d1,TextPos(a6)
	rts

PC.Clear	move.l	AdTScreen(a6),a0	Effacement de l'‚cran texte
	move.w	#1999,d0
PC.Clear1	clr.l	(a0)+
	dbra	d0,PC.Clear1
	clr.w	TextPos(a6)
	clr.w	TextCol(a6)
	rts

PC.DoWait	tst.w	TextWait(a6)	Si Attente en cours...
	bmi.s	PC.Return
	subq.w	#1,TextWait(a6)
PC.Return	rts

PC.TextEnd:
	move.w	#-1,TextWait(a6)	Fin du texte : TextWait = -1
	rts

PC.NewLine:
	move.l	AdTScreen(a6),a1
	move.w	TextPos(a6),d1
	lea	0(a1,d1.w),a1
	clr.b	240(a1)
	clr.b	280(a1)
	sub.w	TextCol(a6),d1	Passage en d‚but de ligne
	add.w	#320,d1		D‚but de la ligne suivante
	move.w	d1,TextPos(a6)
	clr.w	TextCol(a6)

PC.TstScr	move.l	AdTScreen(a6),a1
	move.w	TextPos(a6),d1
	cmp.w	#7040,d1		Si en bas d'‚cran, Scrolle
	blt.s	PC.NoScroll

	lea	320(a1),a2
	move.l	a1,a3
	move.w	#1759,d7
PC.Scroll	move.l	(a2)+,(a3)+	Boucle principale du scroll
	dbra	d7,PC.Scroll

	moveq	#79,d7		Boucle d'effacement de la ligne du bas
	moveq	#0,d6
PC.Scrol2	move.l	d6,(a3)+
	dbra	d7,PC.Scrol2

	sub.w	#320,d1		Remet … jour la position ‚cran
	move.w	d1,TextPos(a6)

	bra.s	PC.TstScr		Autre passsage … la ligne ?

PC.NoScroll:
	rts

PC.Wait	move.b	(a0)+,d0		Temps d'attente
	move.w	d0,TextWait0(a6)
	move.l	a0,TextAd(a6)
	rts

* Entr‚e dans la routine proprement dite
PrintChar	tst.w	TextWait(a6)	Teste si une attente en cours
	bne.s	PC.DoWait

	move.l	TextAd(a6),a0	Adresse du texte courant
	moveq	#0,d0
	move.b	(a0)+,d0

	beq.s	PC.TextEnd

	move.l	a0,TextAd(a6)
	cmp.b	#32,d0
	bge.s	PC.Print

	cmp.b	#11,d0
	beq	PC.WaitUp
	cmp.b	#12,d0
	beq	PC.Clear
	cmp.b	#13,d0
	beq	PC.NewLine
	cmp.b	#27,d0
	beq.s	PC.Wait
	cmp.b	#26,d0
	beq.s	PC.Skip
	cmp.b	#1,d0
	beq	PC.At

PC.Print	lsl.w	#3,d0		Adresse du caractŠre dans D0
	lea	CharSet(pc),a0
	lea	0(a0,d0.w),a0
	bsr	PC.TstScr

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

	addq.w	#1,TextPos(a6)	Passage au caractŠre suivant
	addq.w	#1,TextCol(a6)	Mise … jour de la colonne
PC.Skip	move.w	TextWait0(a6),TextWait(a6)	Temps d'attente

	cmp.w	#39,TextCol(a6)
	bge	PC.NewLine

	rts


***************************************************************************
*		Teste si on a appuy‚ sur une touche
***************************************************************************
KeyPressed:
	move.w	#2,-(sp)
	BIOS	1,4

	move.w	d0,d2		Stocke le r‚sultat pour les touches seules
	beq.s	KP.NoKey
	move.w	#2,-(sp)
	BIOS	2,4
	move.w	d0,d2		Stocke la touche dans D2
	moveq	#-1,d0		Et indique "Touche press‚e"

KP.NoKey	lea	Joystick2(pc),a1
	moveq	#0,d1
	move.b	(a1)+,d1
	or.b	(a1)+,d1
	ext.w	d1

	or.w	d1,d0
	
	rts


***************************************************************************
*		Copie d'un ‚cran sur un autre
***************************************************************************
* Entr‚e : A0 : Ecran source ; A1 : Ecran destination
* Modifie quasiment tous les registres
CopyScreen:
	moveq	#99,d0	Copie de 320 octets par boucle
CS.Loop	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,(a1)
	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,40(a1)
	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,80(a1)
	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,120(a1)
	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,160(a1)
	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,200(a1)
	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,240(a1)
	movem.l	(a0)+,d1-d7/a2-a4
	movem.l	d1-d7/a2-a4,280(a1)
	lea	320(a1),a1
	dbra	d0,CS.Loop
	rts



***************************************************************************
*		Superposition de l'‚cran texte sur l'‚cran
***************************************************************************
DrawFond	jmp	0
DF.Back	move.l	BckScreen(a6),a0
	lea	34(a0),a0
	move.l	LogScreen(a6),a1
	bsr	CopyScreen

	addq.w	#8,Alpha(a6)
	addq.w	#3,Beta(a6)
	subq.w	#5,Gamma(a6)

	bsr	TrigInit

	move.w	#-1,JSuisMort(a6)
	bsr	DrawWorld
	bsr	Text2ScrI
	bra	SwapScrn


DF.Norm	move.l	Screen2Ad(a6),a0
	move.l	LogScreen(a6),a1
	bsr	CopyScreen

	bsr	Text2ScrI
	bra	SwapScrn



***************************************************************************
*		Affichage de la carte
***************************************************************************
PrintMap	tst.w	Resol(a6)
	bne	PM.HiRes
	move.l	LogScreen(a6),a0
	lea	5808(a0),a0	Commence par effacer le fond de la carte
	moveq	#127,d3
	moveq	#-1,d7
PM.LLp	move.l	a0,a1
	moveq	#15,d2
PM.CLp	move.l	d7,(a1)+
	dbra	d2,PM.CLp
	lea	160(a0),a0
	dbra	d3,PM.LLp

	move.l	LogScreen(a6),a0
	lea	5808(a0),a0
	moveq	#-120,d0		Index du tableau en cours
	moveq	#15,d1		Nombre de lignes

PM.Line	moveq	#15,d2		Nombre de colonnes
PM.Row	and.w	#$FF,d0		num‚ro de tableau<256

	move.l	a0,a1
	btst	#0,d2		Teste si sur colonne impaire
	bne.s	PM.OddR
	addq.l	#8,a0		Colonne impaire: Lit mot suivant
	move.l	#$7F007F00,d6	Masque des couleurs
	move.l	#$80FF8080,d5	Masque couleur verte
	bra.s	PM.EvenR

PM.OddR	move.l	#$007F007F,d6	Masque des couleurs
	move.l	#$FF808080,d5	Couleur verte par d‚faut
PM.EvenR	btst	#6,$4BD.w
	beq.s	PM.NoClgn
	cmp.w	Tableau(a6),d0
	beq.s	PM.Clign
	btst	#1,Options1(a6)
	beq.s	PM.NoClgn
	move.l	Other(a6),a5
	cmp.w	Tableau(a5),d0
	beq.s	PM.Clign

PM.NoClgn	move.l	TabVisitAd(a6),a2	Lecture du contenu de TabVisit
	move.b	0(a2,d0.w),d4	Lecture de la couleur
	bne.s	PM.Color		0: Affiche les lignes
PM.Clign	move.l	#$7F7F7F7F,d6	Masque des couleurs
	move.l	#$80808080,d5	Masque=Noir
	bra.s	PM.DoDisp

PM.Color	cmp.b	#1,d4
	beq.s	PM.DoDisp
	swap	d5		Couleur rouge pour le 2e joueur

PM.DoDisp	move.l	#-1,(a1)		Cr‚e une ligne noire en haut
	clr.l	4(a1)
	lea	160(a1),a1
	moveq	#6,d4
	
PM.SLine	move.l	(a1),d7		Affichage d'une colonne
	and.l	d6,d7
	or.l	d5,d7
	move.l	d7,(a1)
	and.l	d6,4(a1)
	lea	160(a1),a1
	dbra	d4,PM.SLine

	move.l	#-1,(a1)		Cr‚e une ligne noire en bas
	clr.l	4(a1)
	lea	160(a1),a1
	add.w	#16,d0		Passe au tableau suivant
	dbra	d2,PM.Row		Passe … la colonne suivante

	move.l	#$80008000,d6	Construit la ligne verticale … droite
	move.l	#$7FFF7FFF,d7
	move.l	a0,a1
	moveq	#7,d4
PM.SLine2	or.l	d6,(a1)		Boucle des pixels … droite (noirs)
	and.l	d7,4(a1)
	lea	160(a1),a1
	dbra	d4,PM.SLine2
	
	lea	1216(a0),a0
	subq.w	#1,d0		Passe au tableau pr‚c‚dent
	dbra	d1,PM.Line
	rts

PM.HiRes	move.l	LogScreen(a6),a0
	lea	5784(a0),a0

	moveq	#-120,d0
	moveq	#15,d7		Nombre de lignes
PMH.Lig	move.l	a0,a1
	moveq	#15,d6		Nombre de colonnes
PMH.Col	move.l	TabVisitAd(a6),a2
	and.w	#$FF,d0
	move.b	0(a2,d0.w),d1
	btst	#6,$4BD.w
	beq.s	PMH.Norm
	cmp.w	Tableau(a6),d0
	beq.s	PMH.Clr
	btst	#1,Options1(a6)
	beq.s	PMH.Norm
	move.l	Other(a6),a5
	cmp.w	Tableau(a5),d0
	bne.s	PMH.Norm
PMH.Clr	moveq	#0,d1
PMH.Norm	ext.w	d1
	lsl.w	#5,d1
	lea	MapIcons(pc),a2
	lea	0(a2,d1.w),a2
	moveq	#15,d5
PMH.Word	move.w	(a2)+,(a1)
	lea	80(a1),a1
	dbra	d5,PMH.Word
	lea	-1278(a1),a1
	add.w	#16,d0
	dbra	d6,PMH.Col
	lea	1280(a0),a0
	subq.w	#1,d0
	dbra	d7,PMH.Lig
	rts

MapIcons	dc.w	%0000000000000000
	dc.w	%0100000000000010
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0110000000000100
	dc.w	%0111111111111100
	dc.w	%0111111111111110

	dc.w	%0000000000000000
	dc.w	%0100000001000010
	dc.w	%0110000011000100
	dc.w	%0110000101000100
	dc.w	%0110001001000100
	dc.w	%0110011101000100
	dc.w	%0110000101000100
	dc.w	%0110000101000100
	dc.w	%0110000101000100
	dc.w	%0110000101000100
	dc.w	%0110000101000100
	dc.w	%0110011101110100
	dc.w	%0110011111110100
	dc.w	%0110000000000100
	dc.w	%0111111111111100
	dc.w	%0111111111111110

	dc.w	%0000000000000000
	dc.w	%0100000000000010
	dc.w	%0110011111000100
	dc.w	%0110110001100100
	dc.w	%0110110000110100
	dc.w	%0110000000110100
	dc.w	%0110000001100100
	dc.w	%0110000011000100
	dc.w	%0110000110000100
	dc.w	%0110001100000100
	dc.w	%0110011000000100
	dc.w	%0110111111110100
	dc.w	%0110111111110100
	dc.w	%0110000000000100
	dc.w	%0111111111111100
	dc.w	%0111111111111110

	
***************************************************************************
*		Boucle de d‚placement si gagn‚ ou perdu
***************************************************************************
TheEnd	move.w	#32,d6
DnLoop.MkExp:
	lea	OList(a6),a1
	move.w	ObjNum(a6),d7
	cmp.w	#120,d7
	bgt.s	DnLoop.E
	lsl.w	#5,d7
	lea	0(a1,d7.w),a1

	bsr	Random		InsŠre un nouvel ‚l‚ment d'explosion
	and.w	#$F,d0
	add.w	#$220,d0
	move.w	d0,(a1)+		Explosion
	clr.w	(a1)+		Timer
	move.l	CurX(a6),(a1)+	Copie des coordonn‚es
	move.w	CurZ(a6),(a1)+

	bsr	Random		Ajout de 3 angles Al,Be,Ga
	move.w	d0,(a1)+
	bsr	Random
	move.w	d0,(a1)+
	bsr	Random
	move.w	d0,(a1)+

	addq.l	#6,a1		Pointe sur 3 vitesses
	bsr	Random		Met 3 coordonn‚es
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

	addq.w	#1,ObjNum(a6)
	btst	#1,Options1(a6)
	beq.s	DnLoop.1P
	bsr	SwapVars

DnLoop.1P	dbra	D6,DnLoop.MkExp

	tst	Joueur(a6)
	beq.s	DnLoop.E
	bsr	SwapVars

DnLoop.E	lea	JoyStick1(pc),a1
	clr.l	(a1)
	moveq	#0,d7

DnLoop	move.l	SysTime0(a6),d0
	add.l	#200*20,d0
	cmp.l	$4BA.w,d0
	blt	Finished

	tst.l	SoundPtr+0.w		Teste si un son en cours
	bne.s	DnLoop.Son
	move.l	d7,-(sp)
	bsr	Random		Sinon, joue le son Mort.S
	and.w	#31,d0
	move.w	#160,d7
	add.w	d0,d7
	moveq	#Mort.S,d6
	bsr	PlaySound
	move.l	(sp)+,d7

DnLoop.Son:
	bsr	KeyPressed
	tst.w	d0
	bpl.s	DnLoop.KN
	tst.w	d7
	bmi	Finished

DnLoop.KN	moveq	#-1,d7

	move.w	#1,Timer(a6)
	move.w	d7,-(sp)
	move.w	#128,BetaSpeed(a6)	Rotation du mort
	move.l	Other(a6),a5
	move.w	#-128,BetaSpeed(a5)
	bsr.s	DessTout
	move.w	(sp)+,d7
	bra	DnLoop

UpLoop	subq.w	#1,JSuisMort(a6)
	beq.s	UpLoop2
	rts

UpLoop2	move.l	TabVisitAd(a6),a0
	move.w	Tableau(a6),d0
	and.w	#NTABS-1,d0
	tst.b	0(a0,d0.w)		Teste si on a d‚j… vu le tableau en question
	bne	NouvTab
	move.w	#30,ExtraTime(a6)
	add.l	#200*60,SysTime0(a6)	Si non, on a 3 mn d'exploration en plus
	move.l	Other(a6),a5
	add.l	#200*60,SysTime0(a5)
	bra	NouvTab

****************************************************************************
*		Description du vaisseau et de l'ombre
****************************************************************************

DessTout	addq.l	#1,TimerL(a6)
	bsr	Cls
	move.l	a6,-(sp)		Indique si 1er ou 2e affichage

DessTout2	bsr	TrigInit
	bsr	TraceCube		Trac‚ de l'arŠne,
	bsr	DrawWorld
	bsr	TstJoyst
	btst	#1,Options1(a6)		Si 2 joueurs
	beq.s	DessT.1P
	bsr	SwapVars			On passe alternativement l'un et l'autre
	cmp.l	(sp),a6
	bne.s	DessTout2

DessT.1P	move.l	(sp)+,a6
	bsr	MkScore

	bra	SwapScrn		et permutation d'‚cran


****************************************************************************
*		Description du vaisseau et de l'ombre
****************************************************************************
TraceOmbre:
	move.w	#-1,NumOmb(a6)		Indique 'Ombre trac‚e'
	tst.w	JSuisMort(a6)
	bmi.s	TV.Ret

	st	UseLocAng(a6)
	move.w	BetaSpeed(a6),d0
	sub.w	Beta(a6),d0
	move.w	d0,BetaL(a6)
	clr.w	GammaL(a6)
	clr.w	AlphaL(a6)

	movem.w	CurX(a6),d0-d2
	move.w	AltiOmb(a6),d1
	movem.w	d0-d2,ObjX(a6)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ			Rotation du centre du cube
	movem.w	d0-d2,ModObjX(a6)		Et stockage
	
	lea	Ombre.D(pc),a0
	bra	AffObj

TraceVaiss:
	move.w	#-2,NumOmb(a6)	Indique 'Vaisseau trac‚'

	tst.w	JSuisMort(a6)
	bmi.s	TV.Ret

	btst	#5,Options2(a6)
	beq.s	TV.DoIt
	clr.w	PosZ(a6)
TV.Ret	rts

TV.DoIt	move.w	#900,PosZ(a6)

	st	UseLocAng(a6)
	move.w	BetaSpeed(a6),d0
	sub.w	Beta(a6),d0
	move.w	d0,BetaL(a6)
	clr.w	GammaL(a6)
	btst	#4,Options2(a6)
	beq.s	TV.PaPen
	move.w	BetaSpeed(a6),d0
	neg.w	d0
	asr.w	#1,d0
	move.w	d0,GammaL(a6)
TV.PaPen	clr.w	AlphaL(a6)

	move.w	#-50,CPoint1(a6)		Position du point interm‚diaire
	move.w	Contract(a6),d0
	bpl.s	TV.CPos
	moveq	#0,d0
TV.CPos	cmp.w	#150,Contract(a6)
	ble.s	TV.CNeg
	move.w	#150,Contract(a6)

TV.CNeg	move.w	d0,Contract(a6)
	move.w	d0,d1
	sub.w	#150,d0
	move.w	d0,CPoint1+2(a6)
	move.w	#200,CPoint1+4(a6)
	clr.w	CPoint2(a6)		Position de la tete
	add.w	d1,d1
	sub.w	#300,d1
	move.w	d1,CPoint2+2(a6)
	clr.w	CPoint2+4(a6)

	tst.w	Contract(a6)
	bmi.s	TV.OkCon
	sub.w	#15,Contract(a6)

TV.OkCon	clr.l	ModObjX(a6)		Position dans l'espace relatif
	move.w	PosZ(a6),ModObjZ(a6)

	lea	Vaiss.D(pc),a0		Modification des couleurs
	move.w	Joueur(a6),d0
	add.b	#$F1,d0
	move.b	d0,Vaiss.Top-Vaiss.D(a0)
	move.b	#$F6,Vaiss.Rea-Vaiss.D(a0)

	move.w	InputDev(a6),d0
	lea	Joystick1(pc),a1
	btst	#7,0(a1,d0.w)	Joystick	
	beq.s	TV.NoReac
	move.b	#$F2,Vaiss.Rea-Vaiss.D(a0)
	
TV.NoReac	bra	AffObj



* La routine qui gere l'affichage du vaisseau
* de l'autre joueur
VaissOther.I:
	move.w	JSuisMort(a6),d0
	move.b	d0,-1(a3)
	move.b	d0,-2(a3)
	
	move.b	#$F2,d0
	sub.w	Joueur(a6),d0
	move.b	d0,Vaiss.Top-Vaiss.D(a0)		Couleur rouge

	move.l	Other(a6),a5
	move.w	Tableau(a6),d0		Teste si les deux dans le mˆme tableau
	cmp.w	Tableau(a5),d0
	bne 	Vaiss2.I.NS		Sinon, NotSeen

	move.b	#$F6,Vaiss.Rea-Vaiss.D(a0)
	move.w	InputDev(a5),d0
	lea	Joystick1(pc),a1
	btst	#7,0(a1,d0.w)	Joystick	
	beq.s	Vaiss2.i.Z
	move.b	#$F2,Vaiss.Rea-Vaiss.D(a0)
Vaiss2.I.Z:
	st	UseLocAng(a6)

	move.w	#-50,CPoint1(a6)		Position du point interm‚diaire
	move.w	Contract(a6),d0
	move.w	d0,d1
	sub.w	#150,d0
	move.w	d0,CPoint1+2(a6)
	move.w	#200,CPoint1+4(a6)
	clr.w	CPoint2(a6)		Position de la tete
	add.w	d1,d1
	sub.w	#300,d1
	move.w	d1,CPoint2+2(a6)
	clr.w	CPoint2+4(a6)

	move.w	BetaSpeed(a5),d0
	sub.w	Beta(a5),d0
	move.w	d0,BetaL(a6)
	clr.w	AlphaL(a6)
	clr.w	GammaL(a6)
	movem.w	CurX(a5),d0-d2
	movem.w	d0-d2,(a3)
	movem.w	d0-d2,ObjX(a6)

	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bgt	Vaiss2.IR
	movem.w	CurX(a6),d0-d2
	movem.w	CurX(a5),d3-d5
	sub.w	d3,d0
	sub.w	d4,d1
	sub.w	d5,d2
	movem.w	d0-d2,SpeedX(a6)
	neg.w	d0
	neg.w	d1
	neg.w	d2
	movem.w	d0-d2,SpeedX(a5)
	moveq	#ChocVaiss.S,d6
	moveq	#100,d7
	bsr	PlaySound

Vaiss2.IR	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ		Recalcule les coordonn‚es modifi‚es
	movem.w	d0-d2,ModObjX(a6)
	move.w	d2,20(a3)		Stocke la profondeur
	rts

Vaiss2.I.NS:
	move.w	#$F0F0,-2(a3)	Alors, pas vu
	rts

OmbreOther.I:
	move.w	JSuisMort(a6),d0
	move.b	d0,-1(a3)
	move.b	d0,-2(a3)
	move.l	Other(a6),a5	Si les deux pas dans le mˆme tableau, pas vus
	move.w	Tableau(a6),d0
	cmp.w	Tableau(a5),d0
	bne.s	Vaiss2.I.NS

	st	UseLocAng(a6)
	move.w	BetaSpeed(a5),d0
	sub.w	Beta(a5),d0
	move.w	d0,BetaL(a6)
	clr.w	AlphaL(a6)
	clr.w	GammaL(a6)
	movem.w	CurX(a5),d0-d2
	move.w	AltiOmb(a5),d1
	movem.w	d0-d2,(a3)
	movem.w	d0-d2,ObjX(a6)

	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ		Recalcule les coordonn‚es modifi‚es
	movem.w	d0-d2,ModObjX(a6)
	move.w	d2,20(a3)
	rts

	IFEQ	1
Vaiss.D	dc.b	XM1,YM2,ZM1
	dc.b	XP2,XM1,YP1,ZP3,END

	dc.b	1
	dc.b	1,4,5
Vaiss.Rea	dc.b	$F4
	dc.b	1,8,4,$F5
	dc.b	1,5,8,$F6
	dc.b	4,8,5
Vaiss.Top	dc.b	$F1
	dc.b	0,0
	ENDC

Ombre.D	dc.b	ZP5,ZM5,XM2,XP4,END

	dc.b	1
	dc.b	5,4,2,$F3
	dc.b	0,0

Vaiss.D	dc.b	XM1,XP2,ORIG,ZP5,ZM4,YM1	Pied
	dc.b	GO1,ZM1,XP1,ZP1		Milieu
	dc.b	GO2,YM1,ZM1,XM2,XP4		Arriere tete
	dc.b	XM2,YM1,ZP2,ZP4,YP2		Avant de la tete
	dc.b	END

	dc.b	1
* Ce qu'on voit depuis le haut (class‚)
	dc.b	2,5,7,$F4			Pied (cach‚ par le reste)
	dc.b	3,7,5,$F5
	dc.b	7,3,2
Vaiss.Rea	dc.b	$F0

	dc.b	21,15,12,$F5
	dc.b	12,16,21,$F6

	dc.b	8,9,7,$F4			Colonne (cot‚s)
	dc.b	12,9,8,$F4
	dc.b	10,11,7,$F4
	dc.b	12,11,10,$F4

	dc.b	7,9,10,$F5		Colonne (avant/arriŠre)
	dc.b	12,10,9,$F6
	dc.b	11,8,7,$F5
	dc.b	8,11,12,$F6

	dc.b	12,15,16,$F4
	dc.b	21,19,15,$F4		Tete
	dc.b	19,21,16,$F5
	dc.b	19,16,15			Pan arriere
Vaiss.Top	dc.b	$F0
	dc.b	5,2,3,$F3			Dessous

	dc.b	0,0


***************************************************************************
*		Initialise la liste d'objets pour chaque tableau
***************************************************************************
InitOL	move.w	Tableau(a6),d0	Pointe sur la description de tableau
	btst	#1,Options1(a6)
	beq.s	InitOL.TabDiff

	move.l	Other(a6),a5
	cmp.w	Tableau(a5),d0	Si on arrive dans le tableau occup‚ par l'autre
	bne.s	InitOL.TabDiff

	move.w	MaxVSpeed(a5),MaxVSpeed(a6)	Sinon, copie les variables
	move.w	Gravite(a5),Gravite(a6)
	movem.l	BackColor(a5),d0-d7		Copie des couleurs
	movem.l	d0-d7,BackColor(a6)

	move.w	ObjNum(a5),d0
	move.w	d0,ObjNum(a6)
	lea	OList(a5),a0
	lea	OList(a6),a1
	subq.w	#1,d0
InitOL.Cpy:
	movem.l	(a0)+,d1-d7/a2
	movem.l	d1-d7/a2,(a1)
	lea	32(a1),a1
	dbra	d0,InitOL.Cpy
	rts


InitOL.TabDiff:
	move.l	Tableaux(a6),a0
	subq.w	#1,d0		Adaptation DBRA
	bmi.s	InitOL.A0		Si tableau 0 : On ne lit pas la liste

InitOL.FT	move.w	2(a0),d1		Nombre d'objets
	muls	#10,d1		*10
	lea	44(a0,d1.w),a0	+4 = D‚but du tableau suivant
	dbra	d0,InitOL.FT

InitOL.A0	move.w	36(a0),MaxVSpeed(a6)

	move.w	(a0)+,Gravite(a6)	Acc‚l‚ration verticale dans le tableau
	move.w	(a0)+,d0

	move.w	d0,ObjNum(a6)
	subq.w	#1,d0
	lea	OList(a6),a1

InitOL.1	movem.l	(a0)+,d1-d7/a2	Ecriture palette
	movem.l	d1-d7/a2,BackColor(a6)

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
	btst	#1,Options1(a6)
	beq.s	InitOL.1P
	move.w	#$10,(a1)
	move.w	#$30,32(a1)
	addq.w	#2,ObjNum(a6)

InitOL.1P	clr.w	MissilN(a6)	Indique que pas de missile dans le tableau
	clr.w	TrajSize(a6)	Indique pas d'objet suivant une trajectoire
	rts


****************************************************************************
*		Affichage du Timer et du score
****************************************************************************
* Ajout et soustraction de 1 (entr‚e : A1 pointe sur la fin du compteur)
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

MkScore	moveq	#49,d7		Compteur pour les Scores
	lea	JoyStick1(pc),a4
	move.w	InputDev(a6),d0
	btst	#7,0(a4,d0.w)
	beq.s	MkS.1PVS
	move.w	#8000,d0		Vitesse : 0->255
	sub.w	CurY(a6),d0
	asr.w	#8,d0		Ajout 0->15 au score
	asr.w	#1,d0
	bmi.s	MkS.1PVS
	add.w	d0,ToScore(a6)
MkS.1PVS	tst.w	ToScore(a6)
	beq.s	MkS.1PS
	lea	Score+7(pc),a1
	bsr	AddOne
	lea	Score+4(pc),a0
	cmp.l	a0,a1
	bge.s	MkS.NexT1
	add.l	#200*60,SysTime0(a6)
	move.w	#30,ExtraTime(a6)
	move.l	Other(a6),a5
	add.l	#200*60,SysTime0(a5)

MkS.NexT1	subq.w	#1,ToScore(a6)
	dbra	d7,Mks.1PVS

MkS.1PS	btst	#1,Options1(a6)	teste si on joue … 2 joueurs
	beq.s	MkS.2PS

	move.l	Other(a6),a5
	moveq	#49,d7		Jusqu'… 50 … la fois
	move.w	InputDev(a5),d0
	btst	#7,0(a4,d0.w)
	beq.s	MkS.2PVS
	move.w	#8000,d0		Vitesse : 0->255
	sub.w	CurY(a5),d0
	bmi.s	MkS.2PVS
	asr.w	#8,d0		Ajout 0->15 au score
	asr.w	#1,d0
	bmi.s	MkS.2PVS
	add.w	d0,ToScore(a5)
MkS.2PVS	tst.w	ToScore(a5)
	beq.s	MkS.2PS
	lea	Score2+7(pc),a1
	bsr	AddOne
	lea	Score2+4(pc),a0
	cmp.l	a0,a1
	bge.s	MkS.NexT2
	add.l	#200*60,SysTime0(a6)
	move.w	#30,ExtraTime(a6)
	move.l	Other(a6),a5
	add.l	#200*60,SysTime0(a5)


MkS.Next2	subq.w	#1,ToScore(a5)
	dbra	d7,MkS.2PVS

MkS.2PS	move.l	SysTime0(a6),d6
	sub.l	$4BA,d6
	bpl.s	MkS.TimIn
	move.w	#-40,JSuisMort(a6)
	move.l	Other(a6),a5
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

PrScore	tst.w	Resol(a6)
	bne	PrSc.Hi

	tst.w	ExtraTime(a6)
	beq.s	PrS.NExT
	subq.w	#1,ExtraTime(a6)
	lea	ExtraTxt(pc),a0
	move.l	LogScreen(a6),a1
	lea	96*160+40(a1),a1
	bsr	FastPrt

PrS.NexT	lea	Remains(pc),a0	Affichage du temps
	move.l	LogScreen(a6),a1
	lea	160+160-40(a1),a1
	bsr.s	FastPrt

	lea	ScoreT(pc),a0	Affichage du score
	move.l	LogScreen(a6),a1
	lea	160+8(a1),a1
	bsr.s	FastPrt

	move.l	LogScreen(a6),a1
	lea	160*191(a1),a1
	lea	TabName(pc),a0
	btst	#1,Options1(a6)
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

CharSet	INCBIN	\ASSEMBLR\PROJET.CUB\CUBE.CHR

PrSc.Hi	tst.w	ExtraTime(a6)
	beq.s	PrSH.NExT
	subq.w	#1,ExtraTime(a6)
	lea	ExtraTxt(pc),a0
	move.l	LogScreen(a6),a1
	lea	96*160+30(a1),a1
	bsr	HiFPrt

PrSH.NexT	lea	Remains(pc),a0	Affichage du temps
	move.l	LogScreen(a6),a1
	lea	160+70(a1),a1
	bsr.s	HiFPrt

	lea	ScoreT(pc),a0	Affichage du score
	move.l	LogScreen(a6),a1
	lea	160+2(a1),a1
	bsr.s	HiFPrt

	move.l	LogScreen(a6),a1
	lea	160*191(a1),a1
	lea	TabName(pc),a0

	btst	#1,Options1(a6)
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
*		Lecture des touches et d‚placement
****************************************************************************
* D‚placement proprement dit

* PremiŠre partie : La recherche des objets sur lesquels on rebondit
* ‚ventuellement...
Deplace	movem.w	SpeedX(a6),d0-d2
	movem.w	CurX(a6),d3-d5
	add.w	d0,d3		Calcul des d‚placements
	add.w	d1,d4
	add.w	d2,d5

	move.w	Gravite(a6),d7
	asr.w	#1,d7
	add.w	d7,d1		Acc‚l‚ration verticale
	add.w	SpeedX0(a6),d0	Calcul de la moyenne entre vitesse th. et r‚elle
	add.w	SpeedZ0(a6),d2

	moveq	#0,d7		Indique pas de heurt de mur

	asr.w	#1,d0		Force le passage … 0 si n‚c‚ssaire (<0)
	bpl.s	Dep.dxp
	addq.w	#1,d0
Dep.dxp	asr.w	#1,d2
	bpl.s	Dep.dyp
	addq.w	#1,d2

Dep.dyp	cmp.w	#8000,d3		Rebond sur les bords du cube
	blt.s	Dep.XPOk
	moveq	#-1,d7		Indique que l'on a heurt‚ un mur
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
	movem.w	d0-d5,-(sp)	Si on a touch‚ un mur, joue un spl
	moveq	#SurMurs.S,d6
	moveq	#100,d7
	bsr	PlaySound
	movem.w	(sp)+,d0-d5

Dep.PasToucheMur:
	cmp.w	#8000,d4		Rebond en Y
	blt.s	Dep.YPOk
	movem.w	d0-d5,-(sp)
	asr.w	#1,d1
	cmp.w	Gravite(a6),d1
	blt.s	Dep.YNoS
	asr.w	#1,d1
	neg.w	d1
	add.w	#170,d1
	cmp.w	#150,d1
	blt.s	Dep.SOk
	move.w	#150,d1

* Ici une routine de traitement du son … faire en cas de rebond
Dep.SOk	move.w	#150,d2
	sub.w	d1,d2
	move.w	d2,Contract(a6)
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

Dep.YPOk	movem.w	d0-d2,SpeedX(a6)	Stockage des nouvelles vitesses et d‚placement
	movem.w	d3-d5,CurX(a6)

TstJoyst	lea	Joystick1(pc),a0
	move.w	InputDev(a6),d1
	bpl.s	Dep.Plyr		Teste si en mode jeu automatique
	move.l	MovePtr(a6),a1	Si oui, rejoue la s‚quence enregistr‚e
	move.b	(a1)+,d0
	move.b	d0,0(a0,d1.w)
	move.l	a1,MovePtr(a6)
	cmp.l	EndMvMem(a6),a1	Teste si on a atteint la fin de l'enregistrement
	ble.s	Dep.Demo
	addq.l	#4,sp		Oui : Retour court-circuit‚
	bra	MainGame

Dep.Plyr	move.b	0(a0,d1.w),d0	Lecture d'une donn‚e sur Joy
	move.w	d0,d1
* Teste les retours au centre automatique
	btst	#3,Options2(a6)	Teste si retour au bas auto
	bne.s	Dep.NoRB		Sinon pas de retour au bas
	and.w	#3,d1		Isole les bits HB
	bne.s	Dep.NoRB		Si on touche au Joy

	move.w	#$20,d1		Direction choisie
	cmp.w	#8000,CurY(a6)
	beq.s	Dep.Bot
	move.w	#$80,d1
Dep.Bot	cmp.w	Alpha(a6),d1	Comparaison avec la position
	beq.s	Dep.NoRB
	blt.s	Dep.ADn
	bset	#0,d0
	bra.s	Dep.NoRB
Dep.ADn	bset	#1,d0

Dep.NoRB	btst	#2,Options2(a6)	Teste si retour au centre auto
	bne.s	Dep.NoCe
	move.w	d0,d1
	and.w	#$C,d1		Isole les bits GB
	bne.s	Dep.NoCe		Si on touche au Joy

	tst.w	BetaSpeed(a6)		Comparaison avec la position
	beq.s	Dep.NoCe
	blt.s	Dep.AGa
	bset	#3,d0
	bra.s	Dep.NoCe
Dep.AGa	bset	#2,d0

Dep.NoCe	btst	#1,Options1(a6)	Si 2 joueurs, n'enregistre pas
	bne.s	Dep.Demo

	move.l	EndMvMem(a6),a0
	move.l	a0,d1
	sub.l	MoveMemAd(a6),d1
	cmp.w	#TScreen-MoveMemry,d1
	bgt.s	Dep.Demo
	move.b	d0,(a0)+
	move.l	a0,EndMvMem(a6)

Dep.Demo	btst	#0,d0		Test des 4 directions, avec d‚passement de
	beq.s	Dep.NoUp		capacit‚ fix‚ … $90 (50 degr‚s)
	add.w	#$8,Alpha(a6)
	cmp.w	#$D0,Alpha(a6)
	ble.s	Dep.NoUp
	move.w	#$D0,Alpha(a6)

Dep.NoUp	btst	#1,d0
	beq.s	Dep.NoDn
	sub.w	#$8,Alpha(a6)
	cmp.w	#-$D0,Alpha(a6)
	bge.s	Dep.NoDn
	move.w	#-$D0,Alpha(a6)

Dep.NoDn	btst	#2,d0
	beq.s	Dep.NoRt
	addq.w	#$8,BetaSpeed(a6)
	cmp.w	#$90,BetaSpeed(a6)
	ble.s	Dep.NoRt
	move.w	#$90,BetaSpeed(a6)

Dep.NoRt	btst	#3,d0
	beq.s	Dep.NoDi
	subq.w	#$8,BetaSpeed(a6)
	cmp.w	#-$90,BetaSpeed(a6)
	bge.s	Dep.NoDi
	move.w	#-$90,BetaSpeed(a6)

* Teste les options de d‚placement
Dep.NoDi	clr.w	Gamma(a6)
	btst	#4,Options2(a6)
	bne.s	Dep.Gamma
	move.w	BetaSpeed(a6),Gamma(a6)

Dep.Gamma	move.w	BetaSpeed(a6),d1
	asr.w	#3,d1
	sub.w	d1,Beta(a6)

	btst	#7,d0		Reacteur en marche ?
	beq.s	Dep.NoBut

	move.w	#2000,d0		Composante horizontale
	move.w	Beta(a6),d1
	sub.w	BetaSpeed(a6),d1
	move.w	d1,-(sp)
	bsr	XSinY
	asr.w	#3,d2
	move.w	d2,SpeedX0(a6)	Fixe la vitesse id‚ale

	move.w	#2000,d0
	move.w	(sp)+,d1
	bsr	XCosY
	asr.w	#3,d2
	move.w	d2,SpeedZ0(a6)

	rts

Dep.NoBut	clr.w	SpeedX0(a6)
	clr.w	SpeedZ0(a6)
	rts


***************************************************************************
*	V‚rifie que les coordonn‚es dans D0-2 sont dans le cube
***************************************************************************
InCube	cmp.w	#7000,d0
	ble.s	InCube.1
	move.w	#7000,d0
InCube.1	cmp.w	#-7000,d0
	bge.s	InCube.2
	move.w	#-7000,d0
InCube.2	cmp.w	#7000,d1
	ble.s	InCube.3
	move.w	#7000,d1
InCube.3	cmp.w	#-7000,d1
	bge.s	InCube.4
	move.w	#-7000,d1
InCube.4	cmp.w	#7000,d2
	ble.s	InCube.5
	move.w	#7000,d2
InCube.5	cmp.w	#-7000,d2
	bge.s	InCube.6
	move.w	#-7000,d2
InCube.6	rts

***************************************************************************
*	V‚rifie que les coordonn‚es dans D0-2 sont dans le cube, Sinon 0
***************************************************************************
InCube2	cmp.w	#7000,d0
	ble.s	InCube2.1
	move.w	#6000,d0
InCube2.1	cmp.w	#-7000,d0
	bge.s	InCube2.2
	move.w	#-6000,d0
InCube2.2	cmp.w	#7000,d1
	ble.s	InCube2.3
	move.w	#6000,d1
InCube2.3	cmp.w	#-7000,d1
	bge.s	InCube2.4
	move.w	#-6000,d1
InCube2.4	cmp.w	#7000,d2
	ble.s	InCube2.5
	move.w	#6000,d2
InCube2.5	cmp.w	#-7000,d2
	bge.s	InCube2.6
	move.w	#-6000,d2
InCube2.6	rts

***************************************************************************
*		Fonction donnant un r‚sultat "al‚atoire" dans d0
***************************************************************************
Random	move.w	Seed(a6),d0
	muls	#997,d0
	addq.w	#1,d0
	move.w	d0,Seed(a6)
	rts

***************************************************************************
*		Recherche de l'azimut visant une cible
***************************************************************************
* M‚thode utilis‚e :
*  TriRotation du vecteur (0,-128,0) (vertical) -> D0-D1-D2
*  L'‚quation du plan d'azimut est alors
*  D0*(X-X0)+D1*(Y-Y0)+D2*(Z-Z0)=0
* Selon le signe de l'expression, on est au dessus ou en dessous de l'azimut
*
* Entr‚e : Comme pour les .I, avec 6(a3) pointant sur Alpha et Beta
*	 d0-d2 indiquent le point … viser
* Sortie : A0 et A3 pr‚serv‚s
*	 D0 = 0,+1,-1 … ajouter … Alpha

AzimPolar	movem.l	d0-d2/a0/a3,-(sp)
	moveq	#0,d0
	moveq	#-128,d1
	moveq	#0,d2
	movem.w	6(a3),d5-d6
	moveq	#0,d7
	movem.w	d5-d7,AlphaL(a6)	Fixe les angles locaux en fonction des angles actuels
	bsr	TriRotateL	Triple rotation

	movem.l	(sp)+,d5-d7/a0/a3	R‚cupŠre les coordonn‚es du point … viser
	sub.w	(a3),d5		Calcule le vecteur diff‚rence
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
* M‚thode utilis‚e :
*  Rotation dans le plan OXZ du vecteur (0,1000) (droit devant) selon le Cap (Beta)
*  Produit vectoriel avec le vecteur diff‚rences
*  Le signe de la composante Y indique la direction … choisir
* Entr‚e : D0-D2 indiquent le point … viser
*          A0-A3 fix‚s comme pour .I, avec 6(a3)=Alpha, 8(a3)=Beta
* Sortie : A0 et A3 pr‚serv‚s
*	 D0 contient 0,+1 ou -1, valeur … ajouter … Beta
*
CapPolar	moveq	#0,d5
	moveq	#100,d6
	move.w	8(a3),d7
	movem.l	d0-d2/a0/a3,-(sp)
	bsr	Rotate		Rotation selon l'angle voulu
	movem.l	(sp)+,d5-d7/a0/a3
	sub.w	(a3),d5		Calcul de DX et DZ
	sub.w	4(a3),d7
	muls	d5,d1		Produits crois‚s
	muls	d7,d0
	sub.l	d0,d1
	neg.l	d1
	bra.s	SignD1		Et recherche du signe


***************************************************************************
*	Recherche d'intersection de cubes :
*	D‚termine si au prochain tour on sera dans X+DX,X-DX...
***************************************************************************
* Entr‚e :
*  D0-D2 : Coordonn‚es de l'objet
*  A1 : Pointeur sur une table OFFX-, OFFX+,OFFY-, OFFY+, OFFZ-, OFFZ+
* Sortie :
*  D7 a les bits … 0 dans l'ordre 0 : X-,... 5 : Z+
*  Le mot haut a les memes bits avant d‚placement
* Un EOR entre la partie haute et la partie basse permet donc de savoir
* Quelles parois ont ‚t‚ travers‚es
Touching	moveq	#-1,d7
	movem.w	CurX(a6),d3-d5
	bsr.s	TC.0
	swap	d7
	add.w	SpeedX(a6),d3
	add.w	SpeedY(a6),d4
	add.w	SpeedZ(a6),d5

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
* Entr‚e : A1 pointe sur une table volumique
***************************************************************************
GereOmbre	bsr	Touching		Calcul des intersections
	move.w	d7,d6
	and.w	#%110011,d6	Isole les composantes X/Z
	bne.s	GO.Ret
	move.w	CurY(a6),d6
	cmp.w	d6,d1		Il ne faut pas que je sois plus bas que la dalle
	blt.s	GO.Ret
	move.w	NxAOmb(a6),d6
	cmp.w	d6,d1		Il ne faut pas que l'ancienne altitude soit plus haute que moi
	bgt.s	GO.Ret
	move.w	d1,NxAOmb(a6)
	move.w	26(a3),NxNOmb(a6)	Indique le num‚ro d'objet
	moveq	#0,d6
	rts
GO.Ret	moveq	#-1,d6
	rts



***************************************************************************
*		Instructions pour chaque objet
***************************************************************************
* En entr‚e, A3 pointe sur les coordonn‚es (qui sont aussi dans D0-D2)
* Offsets/a3:
* -4: Num‚ro de l'objet
* -2: Compteur d'affichage
*  0: X,Y,Z
*  6: Alpha,Beta
* 10: Divers
* 12: Coordonn‚es modifi‚es
* 20: Divers...
* 26: Num‚ro de l'objet (pour identification)
* A0 pointe sur la description de l'objet

* KeyWord #I
ObjPrgs	rts

* Objet qui se dirige selon une trajectoire fixe (Traject)
* L'objet commence sa trajectoire en se dirigeant vers Traject[0]
* et suit tous les ‚l‚ments jusqu'… TrajSize. Alors, retour
* … Traject[0]
PoseTraj.I:
	move.w	-4(a3),d7		Lit la couleur (d‚termine la position)
	and.w	#$F,d7
	move.w	d7,d6
	add.w	d7,d7
	add.w	d6,d7
	add.w	d7,d7		Passe au mot
	lea	Traject(a6),a0
	movem.w	d0-d2,0(a0,d7.w)	Et stocke la position de l'objet dans la traj.
	addq.w	#1,TrajSize(a6)	Un point de trajectoire de plus
	bra	ObjClr		

* Entr‚e de Traject.I:
* Vitesse : D6 (translation), D7 (rotation)
* 10(a3) contient le num‚ro de l'‚l‚ment de trajectoire … suivre
* 20(a3) contient le precedent d‚calage X
* 22(a3) contient le precedent d‚calage Y
Traject.I	move.w	d6,-(sp)		Vitesse de translation

	move.w	d7,-(sp)
	move.w	10(a3),d7
	move.w	d7,d6
	add.w	d7,d7
	add.w	d6,d7
	add.w	d7,d7
	lea	Traject(a6),a5
	movem.w	0(a5,d7.w),d0-d2

	movem.w	d0-d2,-(sp)
	bsr	CapPolar		Teste du Cap
	move.w	d0,d5
	movem.w	(sp)+,d0-d2

	move.w	(sp),d7
	move.w	20(a3),d6		Lecture d‚calage actuel+Signe pr‚c
	move.w	d5,d4
	eor.w	d6,d4		Si dans des directions oppos‚es
	bpl.s	Traject.1
	moveq	#0,d6		Pas de d‚calage
Traject.1	addq.b	#1,d6		Augmentation du d‚calage pr‚c‚dent
	cmp.b	d7,d6		Si plus grand que le d‚calage limite
	ble.s	Traject.2
	move.w	d7,d6		Limite le d‚calage
Traject.2	move.w	d6,20(a3)		Stocke le d‚calage actuel
	lsl.w	d6,d5		Effectue le d‚calage
	smi	20(a3)		Stocke le signe du r‚sultat
	add.w	d5,8(a3)		Modification du cap

	bsr	AzimPolar
	move.w	d0,d5
	move.w	(sp)+,d7
	move.w	22(a3),d6
	move.w	d5,d4
	eor.w	d6,d4		Si dans des directions oppos‚es
	bpl.s	Traject.3
	moveq	#0,d6		Pas de d‚calage
Traject.3	addq.b	#1,d6		Augmentation du d‚calage pr‚c‚dent
	cmp.b	d7,d6		Si plus grand que le d‚calage limite
	ble.s	Traject.4
	move.w	d7,d6		Limite le d‚calage
Traject.4	move.w	d6,22(a3)		Stocke le d‚calage actuel
	lsl.w	d6,d0
	smi	22(a3)
	add.w	d0,6(a3)		Modification de l'azimut
	st	UseLocAng(a6)	Indique l'utilisation d'angle locaux

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
	lea	Traject(a6),a5
	movem.w	0(a5,d7.w),d3-d5
	bsr	Distance		Teste si on a atteint l'‚l‚ment vis‚
	cmp.w	#1000,d0
	bge.s	Traject.R
	move.w	10(a3),d0		Si oui, on passe au suivant
	addq.w	#1,d0
	cmp.w	TrajSize(a6),d0
	blt.s	Traject.S
	moveq	#0,d0
Traject.S	move.w	d0,10(a3)

Traject.R	rts

* Objet Traject qui, si il est touch‚, provoque un son et d‚cale
* D3: Couleur du bord
* D4: Distance avant contact
* D5: Num‚ro du son en cas de rebond
* D6: Vitesse lin‚aire
* D7: Vitesse de rotation
Speeder.I	move.w	#$FF0,d3
	move.w	#1200,d4
	moveq	#StarWar.S,d5
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
	moveq	#StarWar.S,d5
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
	movem.w	CurX(a6),d3-d5
	bsr	Distance
	movem.w	(sp)+,d3-d7
	cmp.w	d4,d0
	bge.s	Explor.R

	move.w	d5,-(sp)
	move.w	d3,CurColor(a6)	Si on est touch‚ par le vaisseau
	movem.w	(a3),d0-d2
	movem.w	CurX(a6),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
	add.w	d3,SpeedX(a6)
	add.w	d4,SpeedY(a6)
	add.w	d5,SpeedZ(a6)
	move.w	(sp)+,d6
	moveq	#100,d7
	bsr	PlaySound
Explor.R	rts


* Horrible alien qui vient vers vous en zigzagant
* 20(a3) contient la vitesse de l'alien
Alien.I	movem.w	CurX(a6),d3-d5
	bsr	Distance
	move.w	d0,d7
	movem.w	(a3),d0-d2
	cmp.w	#500,d7
	ble	Collis.Co
	bsr	TesteMissile		Teste si touch‚ par un missile
	tst.w	d7
	bpl.s	Alien.Contact

	moveq	#Missile.S,d6	Si l'objet est touch‚ par un missile
	moveq	#127,d7		On fait un son de missile
	bsr	PlaySound
	add.w	#3000,ToScore(a6)
	moveq	#2,d7
Alien.1	bsr	Random		Position al‚atoire
	and.w	#16383,d0
	add.w	#8192,d0
	move.w	d0,(a3)+
	dbra	d7,Alien.1
	subq.l	#6,a3
	bra	ObjClr

Alien.Contact:
	movem.w	(a3),d0-d2
	movem.w	CurX(a6),d3-d5	Effectue le calcul du d‚placement
	sub.w	d0,d3
	smi	d0
	sub.w	d1,d4
	smi	d1
	sub.w	d2,d5		Calcule le vecteur d‚placement
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
	movem.w	20(a3),d3-d5	R‚cupŠre les vitesses
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
	move.w	d0,BetaL(a6)
	add.w	#21,d0
	move.w	d0,8(a3)
	clr.w	AlphaL(a6)	Pas d'angles en Gamma et Alpha
	clr.w	GammaL(a6)
	st	UseLocAng(a6)

	rts
	
* Cube qui protŠge un endroit
Protect.I	move.w	-4(a3),d7
	move.w	WhichProtect(a6),d6
	and.w	#$F,d7
	btst	d7,d6
	bne.s	Protect.No
	
	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#3000,d0
	bge.s	Protect.0

	movem.w	(a3),d0-d2
	movem.w	CurX(a6),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
	asr	#2,d3
	asr	#2,d4
	asr	#2,d5
	movem.w	d3-d5,SpeedX(a6)
	move.w	#$F53,CurColor(a6)

	moveq	#Protect.S,d6
	moveq	#100,d7
	bsr	PlaySound

Protect.0	movem.w	6(a3),d0-d2
	addq.w	#1,d0
	addq.w	#2,d1
	addq.w	#3,d2
	movem.w	d0-d2,6(a3)
	movem.w	d0-d2,AlphaL(a6)
	st	UseLocAng(a6)

	rts

* Si le protecteur en question est debranch‚
Protect.No
	move.w	#$F0F0,-2(a3)
	rts

ProtKey.I	move.w	-4(a3),d7
	move.w	WhichProtect(a6),d6
	and.w	#$F,d7
	bset	d7,d6
	bne.s	Protect.No
	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bge.s	Protect.0

	move.w	d6,WhichProtect(a6)
	move.l	Other(a6),a5
	move.w	d6,WhichProtect(a5)		Assure la coh‚rence entre les 2 joueurs
	moveq	#ProtKey.S,d6
	moveq	#100,d7
	bsr	PlaySound

	bra.s	Protect.0


* Dalles allong‚es
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
LongX.X	move.w	d7,CPoint1(a6)
	clr.w	CPoint1+2(a6)
	move.w	#500,CPoint1+4(a6)
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
LongY.X	move.w	#500,CPoint1(a6)
	clr.w	CPoint1+2(a6)
	move.w	d7,CPoint1+4(a6)
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
* jusqu'… 7000
* Si l'utilisateur est en dessous de 7500,
* elle remonte alors toute seule jusqu'… l'altitude initiale
* 6(a3)= Altitude initiale
* 8(a3)= Drapeau: 1=Tombant, -1= Remontant
Falling.I	tst.w	8(a3)
	beq.s	Falling.Init	Initialisation
	bmi.s	Falling.Back
	cmp.w	#7500,CurY(a6)	Si la plaque doit remonter
	bge.s	Falling.SetBack

	moveq	#Falling.S,d6
	bsr	Plaque.X		Teste si plaque touch‚e
	tst.w	d7
	beq.s	Falling.R

	cmp.w	#7000,2(a3)
	bge.s	Falling.R
	add.w	#600,2(a3)

Falling.R	rts

Falling.SetBack:
	move.w	#-1,8(a3)
Falling.Back:
	cmp.w	6(a3),d1		Teste si on est arriv‚
	ble.s	Falling.Init	On recommence … descendre
	sub.w	#200,2(a3)	Sinon on remonte
	moveq	#Falling.S,d6
	bra	Plaque.X

Falling.Init
	move.w	#1,8(a3)		Prete … tomber
	move.w	2(a3),6(a3)	Stocke l'altitude initiale
	moveq	#Falling.S,d6
	bra	Plaque.X

* Dalle clignotante
* 10(a3) contient le nombre de fois o— l'on a rebondit dessus
Clign.I	tst.b	-2(a3)		Si pas affich‚e, abs
	bmi.s	Clign.Abs
	cmp.w	#4,10(a3)	Si affich‚e depuis longtps
	bge.s	Clign.Eff
	moveq	#Clign.S,d6
	bsr	Plaque.X		Sinon normale
	sub.w	d7,10(a3)		Si rebond, inc compteur de rebond
	bra.s	Clign.Abs

Clign.Eff	move.b	#-50,-2(a3)
	clr.w	10(a3)		Remet … zero le compteur de rebond

Clign.Abs	rts

* Rayon attrappant
* Ne doit pas etre plac‚ en (0,0,0)
Catcher.I	movem.w	(a3),d0-d5	Diff‚rence de position
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
	lea	CPoint1(a6),a0	Initialisation des CPOINTs
	move.w	d3,d0		R‚f‚rence au centre de l'objet
	move.w	d4,d1
	move.w	d5,d2
Catcher.1	movem.w	d0-d2,(a0)
	move.w	d0,-(sp)
	bsr	Random		Petit d‚calage al‚atoire
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

	movem.w	d3-d5,-(sp)	Stocke le d‚placement

	movem.w	(a3),d0-d2	D‚placement de la pointe
	movem.w	CurX(a6),d3-d5
	sub.w	d0,d3		Vecteur Vis‚e-CurX
	sub.w	d1,d4
	sub.w	d2,d5
	asr.w	#3,d3		V/8
	asr.w	#3,d4
	asr.w	#3,d5

	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	movem.w	d0-d2,(a3)

	movem.w	CurX(a6),d3-d5	Distance pointe-observ.
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

	movem.w	(sp),d3-d5	R‚cupŠre d‚placement
	asr.w	#5,d3
	asr.w	#5,d4
	asr.w	#5,d5
	add.w	d3,SpeedX(a6)
	add.w	d4,SpeedY(a6)
	add.w	d5,SpeedZ(a6)
	moveq	#Catcher.S,d6
	moveq	#100,d7
	bsr	PlaySound

Catcher.R	addq.l	#6,sp
	rts


* Plaque automatique (qui suit un d‚placement donn‚)

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
	clr.w	AlphaL(a6)
	bra	Plaque.X
	
* Plaque qui n'apparait que si a une distance suffisament faible
* de l'observateur (Pour labyrinthe)
LabP.I	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#4000,d0
	ble.s	LabP.Seen
	move.w	Joueur(a6),d1
	move.b	#-5,-2(a3,d1.w)
LabP.Seen	movem.w	(a3),d0-d2
	moveq	#NoSound,d6	Pas de son
	bra	Plaque.X


* Plaque qui t‚l‚porte 2000 plus haut
PTeleV.I	moveq	#Transpor.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PTeleV.NT
	sub.w	#2000,CurY(a6)
PTeleV.NT	rts

* Bulles vides
BulleV.I	bchg	#1,Options2(a6)	Passe en filaire
	bsr.s	BulleP.I
	bchg	#1,Options2(a6)
Bulle.R	rts
* Bulles pleines
* Ici, on trace un cercle directement sur l'‚cran, sans changement
* de coordonn‚es de points
BulleP.I	tst.w	6(a3)		Teste l'indicateur d'efficacit‚
	bpl.s	BulleP.D

	move.w	Joueur(a6),d0	Si on a touch‚ la bulle :
	move.b	#-10,-2(a3,d0.w)	elle est invisible

	cmp.w	#-300,6(a3)
	blt.s	Bulle.R
	bne.s	Bulle.N
	add.w	#10,Gravite(a6)	Si on a fini le temps
	sub.w	#$123,BackColor(a6)

Bulle.N	subq.w	#1,6(a3)
	bra.s	Bulle.R
	
BulleP.D	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bgt.s	BulleP.T

	moveq	#Bulle.S,d6
	moveq	#100,d7
	bsr	PlaySound

	move.w	#-1,6(a3)
	sub.w	#10,Gravite(a6)	Cas o— l'on touche la bulle
	add.w	#$123,BackColor(a6)
	add.w	#1500,ToScore(a6)
	bra.s	Bulle.R

BulleP.T	moveq	#7,d7		Calcul du petit reflet
	move.w	#128,d6
	lea	PolySomm(a6),a1
	move.w	#50,d0
	move.w	#80,d1
	bsr	DoCircle

	moveq	#7,d7		Transformation de coordonn‚es
	lea	PolySomm(a6),a0
	lea	CPoint1(a6),a1
Bulle.1	movem.w	(a0)+,d0-d1	Calcule les CPoints 1-8
	move.w	d0,(a1)+
	sub.w	#180,d1
	move.w	d1,(a1)+
	add.w	#360,d1
	neg.w	d1
	move.w	d1,(a1)+
	dbra	d7,Bulle.1

	move.w	Joueur(a6),d0	Teste si un affichage est demand‚
	tst.b	-2(a3,d0.w)
	bmi	Bulle.R

	bsr	Random		Modification des diamŠtres X et Y
	and.w	#63,d0
	add.w	#300,d0
	move.w	d0,-(sp)
	bsr	Random
	and.w	#63,d0
	add.w	#300,d0
	move.w	(sp)+,d1

	moveq	#31,d7		Pour 32 points
	moveq	#32,d6		Multiplier par 32
	lea	PolySomm(a6),a1
	bsr	DoCircle

	tst.w	20-4(a3)		Teste si on peut afficher la bulle
	bmi	Bulle.R

	moveq	#31,d7		Calcul de perspective
	lea	PolySomm(a6),a0
Bulle.2	movem.w	(a0),d0-d1
	movem.w	16-4(a3),d3-d5	R‚cupŠre les coordonn‚es du centre
	move.w	d5,d2
	add.w	d3,d0
	add.w	d4,d1
	bsr	Perspect
	move.w	d0,(a0)+
	move.w	d1,(a0)+
	dbra	d7,Bulle.2

	move.w	-4(a3),d0		Calcul de la couleur
	and.w	#$F,d0
	move.w	d0,Couleur(a6)
	moveq	#32,d3
	lea	PolySomm(a6),a0
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
	movem.w	d0-d2,AlphaL(a6)
	st	UseLocAng(a6)
	rts

Oizo.I	move.l	a0,-(sp)
	move.l	a3,-(sp)
	move.w	Timer(a6),d1
	lsl.w	#6,d1
	move.w	#200,d0
	bsr	XSinY
	sub.w	#400,d2
	move.w	d2,CPoint1+2(a6)
	move.w	d2,CPoint2+2(a6)
	move.w	#600,CPoint1(a6)
	move.w	#-600,CPoint2(a6)
	move.w	#-200,CPoint1+4(a6)
	move.w	#-200,CPoint2+4(a6)

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
	move.w	6(a3),d1		R‚cupŠre l'ancien azimuth
	add.w	d0,d1		Modification de l'azimuth

	cmp.w	#100,d1		V‚rifie que l'oiseau ne se penche pas trop
	ble.s	Oizo.Az1
	moveq	#100,d1
Oizo.Az1	cmp.w	#-100,d1
	bge.s	Oizo.SAz
	moveq	#-100,d1

Oizo.SAz	move.w	d1,6(a3)		Stocke l'azimuth
	st	UseLocAng(a6)	Indique l'utilisation d'angle locaux

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

	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#800,d0
	bge.s	Oizo.NoReb

	move.w	#$F3F,CurColor(a6)	Si on est touch‚ par l'oiseau
	movem.w	(a3),d0-d2
	movem.w	CurX(a6),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
*	asr.w	#2,d3
*	asr.w	#2,d4
*	asr.w	#2,d5
	add.w	d3,SpeedX(a6)
	add.w	d4,SpeedY(a6)
	add.w	d5,SpeedZ(a6)
	moveq	#ChocOizo.S,d6
	moveq	#100,d7
	bsr	PlaySound
	add.w	#1000,ToScore(a6)

Oizo.NoReb:
	rts

* Bonus de temps (ajoute environ une minute)
Bonus.I	move.l	WhichBonus(a6),d6	Teste si Bonus d‚ja utilis‚
	move.w	-4(a3),d7
	bset	d7,d6
	bne.s	Bonus.R

	tst.w	6(a3)
	bpl.s	Bonus.M

Bonus.T	cmp.w	#-60,6(a3)
	beq.s	Bonus.S
	subq.w	#1,6(a3)
	add.l	#200,SysTime0(a6)	Ajoute un 10e de seconde par image
Bonus.R	move.w	#$F0F0,-2(a3)
Bonus.R2	rts
Bonus.S	move.l	d6,WhichBonus(a6)
	move.l	Other(a6),a5
	move.l	d6,WhichBonus(a5)
	rts

Bonus.M	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bge.s	Bonus.R2
	add.w	#1000,ToScore(a6)
	moveq	#TimeBonus.S,d6
	moveq	#100,d7
	bsr	PlaySound
	bra.s	Bonus.T



* Diamant (Il faut trouver les 16 pour gagner)
Diamond.I	move.w	WhichDiamond(a6),d6	Teste si Bonus d‚ja utilis‚
	move.w	-4(a3),d7
	and.w	#$F,d7
	bset	d7,d6
	beq.s	Diamond.M

	move.w	#$F0F0,-2(a3)
Diamond.R	rts
Diamond.M	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#500,d0
	bge.s	Diamond.R

	move.w	d6,WhichDiamond(a6)
	move.l	Other(a6),a5
	move.w	d6,WhichDiamond(a5)

	add.w	#10000,ToScore(a6)
	moveq	#Diamond.S,d6
	moveq	#100,d7
	bsr	PlaySound
	subq.w	#1,6(a3)
	rts

* Les diff‚rentes sorties
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

Porte.I	clr.l	CPoint1+2(a6)
	clr.l	CPoint2+2(a6)
	move.w	#250,CPoint1(a6)	Initialisation des CPoints
	move.w	#250,CPoint2(a6)

	move.w	d0,BetaL(a6)
	clr.w	AlphaL(a6)
	clr.w	GammaL(a6)
	st	UseLocAng(a6)

	tst.w	JSuisMort(a6)
	bne.s	Porte.O
	move.w	d6,-(sp)
	movem.w	(a3),d0-d2
	moveq	#Sortie.S,d6
	bsr	Plaque2.X
	move.w	(sp)+,d6

	tst.w	d7
	beq.s	Porte.R
	
	move.w	#30,JSuisMort(a6)
	move.w	-4(a3),Sortie(a6)	Indique quelle sortie est la bonne
	add.w	d6,Tableau(a6)
	clr.l	SpeedX(a6)
	clr.w	SpeedZ(a6)

Porte.R	rts

Porte.O	move.w	JSuisMort(a6),d4	Porte ouverte si positif
	bmi.s	Porte.R

	move.w	-4(a3),d0
	cmp.w	Sortie(a6),d0
	bne.s	Porte.R
	move.w	2(a3),NxAOmb(a6)	Met l'altitude de l'ombre … la bonne valeur
	move.w	26(a3),NxNOmb(a6)

	lsl.w	#3,d4
	move.w	#500,d0
	sub.w	d4,d0
	move.w	d0,CPoint1(a6)
	move.w	d4,CPoint2(a6)

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

	movem.w	CurX(a6),d3-d5
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	asr.w	#1,d3
	asr.w	#1,d4
	asr.w	#1,d5
	movem.w	d3-d5,CurX(a6)

	movem.w	Alpha(a6),d3-d5
	asr.w	#3,d3
	asr.w	#3,d5
	sub.w	d3,Alpha(a6)
	cmp.w	#7,Alpha(a6)
	bhi.s	Porte.1
	clr.w	Alpha(a6)
Porte.1	sub.w	d5,Gamma(a6)
	cmp.w	#7,Gamma(a6)
	bhi.s	Porte.2
	clr.w	Gamma(a6)

Porte.2	add.w	BetaL(a6),d4
	add.w	#512,d4
	and.w	#1023,d4
	sub.w	#512,d4
	asr.w	#2,d4
	neg.w	d4
	add.w	Beta(a6),d4
	bpl.s	Porte.3
	addq.w	#1,d4
Porte.3	move.w	d4,Beta(a6)
	clr.w	BetaSpeed(a6)
	rts

Sortie1.V	dc.w	0,500,-20,20,-500,200
Sortie2.V	dc.w	-500,200,-20,20,-500,0
Sortie3.V	dc.w	-500,0,-20,20,-200,500
Sortie4.V	dc.w	-200,500,-20,20,0,500

TransN.I	add.w	#100,4(a3)		D‚placement
	cmp.w	#7500,4(a3)	On est au mur
	blt.s	TransN.1
	add.w	#32,-4(a3)		Oui: Passe en TransS
TransN.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a6)
	rts
TransE.I	add.w	#100,(a3)		D‚placement
	cmp.w	#7500,(a3)	On est au mur
	blt.s	TransE.1
	add.w	#32,-4(a3)		Oui: Passe en TransS
TransE.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a6)
	rts
TransS.I	sub.w	#100,4(a3)		D‚placement
	cmp.w	#-7500,4(a3)	On est au mur
	bgt.s	TransS.1
	sub.w	#32,-4(a3)		Oui: Passe en TransS
TransS.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a6)
	rts
TransW.I	sub.w	#100,(a3)		D‚placement
	cmp.w	#-7500,(a3)	On est au mur
	bgt.s	TransW.1
	sub.w	#32,-4(a3)		Oui: Passe en TransS
TransW.1	moveq	#Trans.S,d6
	bsr	Plaque.X
	and.w	#200,d7
	add.w	d7,ToScore(a6)
	rts

Rotate.V	dc.w	-500,500,-20,20,-500,500
RotateG.I	lea	Rotate.V(pc),a1
	moveq	#Rotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateG.R
	add.w	#99,ToScore(a6)
	add.w	#96,BetaSpeed(a6)
RotateG.R	st	UseLocAng(a6)
	move.w	Timer(a6),d0
	lsl.w	#3,d0
	move.w	d0,BetaL(a6)
	clr.w	AlphaL(a6)
	clr.w	GammaL(a6)
	rts

RotateD.I	lea	Rotate.V(pc),a1
	moveq	#Rotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateD.R
	add.w	#99,ToScore(a6)
	sub.w	#96,BetaSpeed(a6)
RotateD.R	st	UseLocAng(a6)
	move.w	Timer(a6),d0
	lsl.w	#3,d0
	neg.w	d0
	move.w	d0,BetaL(a6)
	clr.w	AlphaL(a6)
	clr.w	GammaL(a6)
	rts

RotAG.I	lea	Rotate.V(pc),a1
	moveq	#ARotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateG.R
	add.w	#49,ToScore(a6)
	add.w	#64,BetaSpeed(a6)
	add.w	#$10,-4(a3)
	bra.s	RotateG.R

RotaD.I	lea	Rotate.V(pc),a1
	moveq	#ARotat.S,d6
	bsr	Plaque2.X
	tst.w	d7
	beq.s	RotateD.R
	add.w	#49,ToScore(a6)
	sub.w	#64,BetaSpeed(a6)
	sub.w	#$10,-4(a3)
	bra.s	RotateD.R



PlaqueN.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueN.R
	add.w	#77,ToScore(a6)
	add.w	#300,SpeedZ(a6)
PlaqueN.R	st	UseLocAng(a6)
	move.w	#-$40,AlphaL(a6)
	clr.w	BetaL(a6)
	clr.w	GammaL(a6)
	rts

PlaqueE.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueE.R
	add.w	#77,ToScore(a6)
	add.w	#300,SpeedX(a6)
PlaqueE.R	st	UseLocAng(a6)
	move.w	#-$40,AlphaL(a6)
	move.w	#-$100,BetaL(a6)
	clr.w	GammaL(a6)
	rts

PlaqueS.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueS.R
	add.w	#77,ToScore(a6)
	sub.w	#300,SpeedZ(a6)
PlaqueS.R	st	UseLocAng(a6)
	move.w	#-$40,AlphaL(a6)
	move.w	#$200,BetaL(a6)
	clr.w	GammaL(a6)
	rts

PlaqueW.I	moveq	#EnPente.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	PlaqueW.R
	add.w	#77,ToScore(a6)
	sub.w	#300,SpeedX(a6)
PlaqueW.R	st	UseLocAng(a6)
	move.w	#-$40,AlphaL(a6)
	move.w	#$100,BetaL(a6)
	clr.w	GammaL(a6)
	rts

SmlPlaq.I	lea	SmlPlaq.V(pc),a1
	moveq	#Petite.S,d6
	bsr	Plaque2.X
	and.w	#66,d7
	add.w	d7,ToScore(a6)
	rts

Teleport.I:
	moveq	#7,d7		8 points
	lea	CPoint1(a6),a1
Teleport.1:
	move.w	Timer(a6),d1
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
	sub.w	d0,CurX(a6)	D‚calage par rapport … la position
	sub.w	d1,CurY(a6)
	sub.w	d2,CurZ(a6)
	lea	OList(a6),a0
	move.w	ObjNum(a6),d0
	lsl.w	#5,d0
	lea	0(a0,d0.w),a1	A0= D‚but de OList, A1=Fin
	subq.l	#4,a3
	move.w	(a3),d0

Teleport.2:
	lea	32(a3),a3		Boucle de recherche de l'autre t‚l‚
	cmp.l	a1,a3
	bne.s	Teleport.No
	move.l	a0,a3
Teleport.No:
	cmp.w	(a3),d0
	bne.s	Teleport.2
	movem.w	4(a3),d0-d2
	add.w	d0,CurX(a6)
	add.w	d1,CurY(a6)
	add.w	d2,CurZ(a6)
	move.w	#10,10(a3)	Indique que ne t‚l‚porte plus

	moveq	#Teleport.S,d6
	moveq	#100,d7
	bsr	PlaySound
Teleport.R:
	rts
Teleport.Inact:
	subq.w	#1,6(a3)		Inactif pendant un certain temps
	rts


* Rebond sur une plaque.
* Peut etre appel‚ de l'ext‚rieur par Plaque.X
* en fixant le bruit dans D6
* et (pour Plaque2.X) a1 pointant sur l'encombrement
Plaque.I	moveq	#Plaque.S,d6
Plaque.X	lea	Plaque.V(pc),a1	Encombrement de la plaque
Plaque2.X	move.w	d6,-(sp)		Stocke le num‚ro du son
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

Plaque.IJ	move.w	SpeedY(a6),d0
	neg.w	d0
	sub.w	Gravite(a6),d0
	cmp.w	MaxVSpeed(a6),d0
	bgt.s	Plaque.I0
	move.w	MaxVSpeed(a6),d0
Plaque.I0	move.w	d0,SpeedY(a6)

	asr.w	#2,d0
	sub.w	d0,Contract(a6)
	move.w	(sp)+,d6
	moveq	#127,d7
	tst.w	Joueur(a6)
	beq.s	Plaque.S1
	moveq	#100,d7
Plaque.S1	move.w	AltiOmb(a6),d0
	asr	#8,d0
	add.w	d0,d7
	bsr	PlaySound
	moveq	#-1,d7		D7 indique que l'on a touch‚ quelquechose
	rts
Plaque.IR	moveq	#0,d7		Cas o— l'on retourne dehors
	addq.l	#2,sp		R‚cupŠre D6
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
	add.w	d6,NxAOmb(a6)

Collis.NO	and.w	#%111111,d7
	bne.s	Collis.R
Collis.Co	movem.w	CurX(a6),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
	asr	#2,d3
	asr	#2,d4
	asr	#2,d5
	movem.w	d3-d5,SpeedX(a6)
	move.w	#$F34,CurColor(a6)

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
Rebond.I	st	UseLocAng(a6)
	movem.w	(a3),d0-d5
	add.w	Gravite(a6),d4
	add.w	d3,d0		Ajout de la vitesse
	add.w	d4,d1
	add.w	d5,d2

	move.w	d0,d7
	bsr	Random		Calcule un nombre al‚atoire pour les vitesses
	and.w	#2047,d0
	move.w	d0,d6		Stocke une vitesse en d6
	sub.w	#1024,d6		d6= vitesse sign‚e

	bsr	Random
	and.w	#1023,d0
	sub.w	#511,d0
	exg.l	d0,d7		R‚cupŠre l'ancien X

	cmp.w	#8000,d0		Rebond sur les bords du cube
	ble.s	Reb.XPOk
	move.w	#7900,d0
	neg.w	d3
	move.w	d6,d4		Stocke une vitesse de rebond al‚atoire
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
	move.w	d6,d3		Stocke une vitesse horizontale al‚atoire
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

	move.w	Timer(a6),d0
	lsl.w	#4,d0
	move.w	d0,AlphaL(a6)
	add.w	d0,d0
	move.w	d0,BetaL(a6)
	add.w	d0,d0
	move.w	d0,GammaL(a6)

	movem.w	(a3),d0-d2	V‚rifie si on le touche
	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#1000,d0
	bgt.s	Reb.DOK
	move.w	#$F50,CurColor(a6)
	move.w	AlphaL(a6),Alpha(a6)
	and.w	#$7F,Alpha(a6)
	move.w	BetaL(a6),Beta(a6)		Notre cap devient al‚atoire

	movem.w	6(a3),d0-d2
	add.w	d0,SpeedX(a6)
	add.w	d1,SpeedY(a6)
	add.w	d2,SpeedZ(a6)

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
	st	UseLocAng(a6)
	move.l	6(a3),AlphaL(a6)	Angle Alpha/Beta
	clr.w	GammaL(a6)
	subq.w	#1,10(a3)		Compteur de dur‚e de vie
	bne.s	MChenille.N
	add.w	#$10,-4(a3)	Affiche la queue
MChenille.N
	cmp.w	#-1,10(a3)
	blt	ObjClr		Si n‚gatif, disparait

	bra	Chassr.Contact

* Tete de la chenille
TChenille.I
	tst.w	24(a3)
	bne.s	TChenille.NoInit
	movem.w	d0-d2,18(a3)	Si premier lancement de la chenille
	subq.w	#8,20(a3)		Destination = point de placement actuel
	not.w	24(a3)		Et gardiennage
TChenille.NoInit
	lea	OList(a6),a5
	move.w	ObjNum(a6),d7
	cmp.w	#120,d7
	bgt.s	TChenille.NoRoom
	lsl.w	#5,d7
	lea	0(a5,d7.w),a5
	
	move.w	-4(a3),d7		Milieu de chenille
	add.w	#$10,d7
	move.w	d7,(a5)+
	clr.w	(a5)+
	move.l	(a3)+,(a5)+	Copie des coordonn‚es (avec angles)
	move.l	(a3)+,(a5)+
	move.w	(a3)+,(a5)+
	lea	-10(a3),a3

	move.w	-4(a3),d7		Longueur de la chenille
	and.w	#$F,d7
	addq.w	#2,d7
	move.w	d7,(a5)+		Longueur de la chenille

	addq.w	#1,ObjNum(a6)

TChenille.NoRoom
	movem.w	18(a3),d0-d2
	bsr	CapPolar
	lsl.w	#5,d0
	add.w	d0,8(a3)		Modification du cap
	movem.w	18(a3),d0-d2
	bsr	AzimPolar
	lsl.w	#3,d0
	move.w	6(a3),d1		R‚cupŠre l'ancien azimuth
	add.w	d0,d1		Modification de l'azimuth

	move.w	d1,6(a3)		Stocke l'azimuth
	st	UseLocAng(a6)	Indique l'utilisation d'angle locaux

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

	movem.w	CurX(a6),d3-d5	Teste si la chenille nous a vu
	bsr	Distance
	cmp.w	#800,d0
	ble.s	Chassr.DoC	Si contact chasseur
	cmp.w	#4000,d0		Un quart du tableau
	bge.s	TChenille.PasVu
	movem.w	d3-d5,18(a3)
TChenille.PasVu
	bsr	TesteMissile		Teste si touch‚ par un missile
	tst.w	d7
	bpl.s	TChenille.Contact

	moveq	#Missile.S,d6	Si l'objet est touch‚ par un missile
	moveq	#127,d7		On fait un son de missile
	bsr	PlaySound
	add.w	#5000,ToScore(a6)
	bra	ObjClr

TChenille.Contact:
	rts

* Chasseur qui vous poursuit
Chassr.I	moveq	#127,d6
	moveq	#3,d7
	bsr.s	Suiveur.I
	bsr	TesteMissile		Teste si touch‚ par un missile
	tst.w	d7
	bpl.s	Chassr.Contact

	moveq	#Missile.S,d6	Si l'objet est touch‚ par un missile
	moveq	#127,d7		On fait un son de missile
	bsr	PlaySound
	add.w	#3000,ToScore(a6)
	bra	ObjClr

Chassr.Contact
	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#800,d0
	bge.s	Chassr.R

Chassr.DoC
	move.w	#$F31,CurColor(a6)	Si on est touch‚ par le vaisseau
	movem.w	(a3),d0-d2
	movem.w	CurX(a6),d3-d5
	sub.w	d0,d3
	sub.w	d1,d4
	sub.w	d2,d5
*	asr.w	#2,d3
*	asr.w	#2,d4
*	asr.w	#2,d5
	add.w	d3,SpeedX(a6)
	add.w	d4,SpeedY(a6)
	add.w	d5,SpeedZ(a6)
	moveq	#Chasseur.S,d6
	moveq	#100,d7
	bsr	PlaySound
Chassr.R	rts
	

* Objet se pr‚cipitant sur l'utilisateur
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

* Objet suivant l'utilisateur dans ses d‚placements
* D7 : Multiplicateur de vitesse de rotation
Follow.I	move.w	d7,-(sp)
	movem.w	CurX(a6),d0-d2
	bsr	InCube2
	bsr	CapPolar
	move.w	(sp),d7
	lsl.w	d7,d0
	add.w	d0,8(a3)		Modification du cap
	movem.w	CurX(a6),d0-d2
	bsr	InCube2
	bsr	AzimPolar

	move.w	(sp)+,d7
	lsl.w	d7,d0
	add.w	d0,6(a3)		Modification de l'azimut
	st	UseLocAng(a6)	Indique l'utilisation d'angle locaux
	rts			(Qui ont ‚t‚ fix‚s par AzimPolar)

* Canon suivant l'utilisateur en tirant
Canon.I	moveq	#1,d7
	bsr	Follow.I		Suivi du joueur
	bsr	Random
	cmp.w	#30000,d0
	blt.s	C.I.Ret

	lea	OList(a6),a1
	move.w	ObjNum(a6),d7
	cmp.w	#120,d7
	bgt.s	C.I.Ret
	lsl.w	#5,d7
	lea	0(a1,d7.w),a1
	
	move.w	-4(a3),d0
	add.w	#$10,d0
	move.w	d0,(a1)+		Missile
	clr.w	(a1)+
	move.l	(a3)+,(a1)+	Copie des coordonn‚es
	move.l	(a3)+,(a1)+
	move.w	(a3)+,(a1)+

	addq.w	#1,ObjNum(a6)
	addq.w	#1,MissilN(a6)	Indique un missile de plus
C.I.Ret	rts

* Teste si on est touch‚ par un missile
TesteMissile:
	move.w	#Missile.N,d6
	move.w	MissilN(a6),d7
	lea	OList(a6),a1
TM.1	tst.w	d7
	beq.s	C.I.Ret
	movem.w	(a1),d1-d5	Charge les coordonn‚es de l'objet
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
TM.Touch	moveq	#-1,d7		Indique touch‚ par le missile
	rts

* Plaque qui nous permet de tirer
FireP.I	moveq	#FireP.S,d6
	bsr	Plaque.X
	tst.w	d7
	beq.s	FireP.R

	move.w	MaxVSpeed(a6),d0
	asr.w	#1,d0
	cmp.w	SpeedY(a6),d0
	ble.s	FireP.1
	move.w	d0,SpeedY(a6)
FireP.1	lea	OList(a6),a1
	move.w	ObjNum(a6),d7
	cmp.w	#120,d7
	bgt.s	FireP.R
	lsl.w	#5,d7
	lea	0(a1,d7.w),a1
	
	move.w	-4(a3),d0
	sub.w	#$30,d0
	move.w	d0,(a1)+		Missile
	clr.w	(a1)+
	move.l	CurX(a6),(a1)+	Copie des coordonn‚es
	move.w	CurZ(a6),(a1)+
	move.l	Alpha(a6),(a1)
	neg.w	(a1)+
	neg.w	(a1)+

	addq.w	#1,ObjNum(a6)
	addq.w	#1,MissilN(a6)	Ajoute un missile
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
	subq.w	#1,MissilN(a6)
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

	addq.w	#1,MissilN(a6)
	movem.w	CurX(a6),d3-d5
	bsr	Distance
	cmp.w	#200,d0
	bgt.s	Mis.Ret
	move.w	#$FF0,CurColor(a6)
	add.w	#400,SpeedY(a6)

	moveq	#Missile.S,d6
	moveq	#127,d7
	bsr	PlaySound

Mis.Ret	rts

ObjClr	subq.l	#4,a3
	lea	AO.FerTab(a6),a0	Fin de la table
ObjClr.Co	move.l	32(a3),(a3)+	Copie les objets plus proches
	cmp.l	a0,a3
	blt.s	ObjClr.Co
	subq.w	#1,ObjNum(a6)
	movem.l	(sp)+,d0/d7/a0/a3	R‚cup‚ration des registres de DrawWorld (d0= Adresse de retour)
	subq.l	#4,a3		a3 pointe sur l'objet courant (ex suivant)
	bra	DW.ObjClr


****************************************************************************
*		Calcul de la distance d'ordre 1 entre 2 points
****************************************************************************
* Entr‚e : D0-2 : X1-Z1
* 	 D3-5 : X2-Z2
* R‚sultat dans D0
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
*		Affichage du cube (arŠne de jeu)
***************************************************************************
TraceCube	move.w	#-8000,d0
	move.w	d0,CPoint1(a6)		Initialise le CPoint 1 et les autres
	move.w	d0,CPoint1+2(a6)
	move.w	d0,CPoint1+4(a6)
	move.w	d0,CPoint2+2(a6)
	move.w	d0,CPoint2+4(a6)
	move.w	d0,CPoint3+4(a6)
	move.w	d0,CPoint4(a6)
	move.w	d0,CPoint4+4(a6)
	move.w	d0,CPoint5(a6)
	move.w	d0,CPoint5+2(a6)
	move.w	d0,CPoint6+2(a6)
	move.w	d0,CPoint8(a6)

	neg.w	d0			Stockage des coordonn‚es n‚gatives
	move.w	d0,CPoint2(a6)
	move.w	d0,CPoint3(a6)
	move.w	d0,CPoint3+2(a6)
	move.w	d0,CPoint4+2(a6)
	move.w	d0,CPoint5+4(a6)
	move.w	d0,CPoint6(a6)
	move.w	d0,CPoint6+4(a6)
	move.w	d0,CPoint7(a6)
	move.w	d0,CPoint7+2(a6)
	move.w	d0,CPoint7+4(a6)
	move.w	d0,CPoint8+2(a6)
	move.w	d0,CPoint8+4(a6)

	clr.l	ObjX(a6)			Calcul des coordonn‚es transform‚es pour ModObjX
	clr.w	ObjZ(a6)
	clr.w	UseLocAng(a6)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ			Rotation du centre du cube
	movem.w	d0-d2,ModObjX(a6)		Et stockage
	
	lea	Cube1(pc),a0
	btst	#0,Options2(a6)		Trac‚ de fond ?
	beq.s	TC.Fond
	lea	Cube2(pc),a0
TC.Fond	clr.w	UseLocAng(a6)
	st	FastFill(a6)
	bsr	AffObj
	clr.w	FastFill(a6)
	rts

Cube1	dc.b	GO1,GO2,GO3,GO4,GO5,GO6,GO7,GO8,END
	dc.b	1
	dc.b	4,5,9,8,$F0
	dc.b	2,3,$F1
	dc.b	3,4,$F1
	dc.b	5,2,$F1
	dc.b	6,7,$F2
	dc.b	7,8,$F2
	dc.b	8,9,$F2
	dc.b	9,6,$F2
	dc.b	2,6,$F1
	dc.b	3,7,$F1
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

TraceOCub	move.w	d0,CPoint1(a6)		Initialise le CPoint 1 et les autres
	move.w	d0,CPoint1+2(a6)
	move.w	d0,CPoint1+4(a6)
	move.w	d0,CPoint2+2(a6)
		move.w	d0,CPoint2+4(a6)
	move.w	d0,CPoint3+4(a6)
	move.w	d0,CPoint4(a6)
	move.w	d0,CPoint4+4(a6)
	move.w	d0,CPoint5(a6)
	move.w	d0,CPoint5+2(a6)
	move.w	d0,CPoint6+2(a6)
	move.w	d0,CPoint8(a6)

	neg.w	d0			Stockage des coordonn‚es n‚gatives
	move.w	d0,CPoint2(a6)
	move.w	d0,CPoint3(a6)
	move.w	d0,CPoint3+2(a6)
	move.w	d0,CPoint4+2(a6)
	move.w	d0,CPoint5+4(a6)
	move.w	d0,CPoint6(a6)
	move.w	d0,CPoint6+4(a6)
	move.w	d0,CPoint7(a6)
	move.w	d0,CPoint7+2(a6)
	move.w	d0,CPoint7+4(a6)
	move.w	d0,CPoint8+2(a6)
	move.w	d0,CPoint8+4(a6)

	clr.l	ObjX(a6)			Calcul des coordonn‚es transform‚es pour ModObjX
	clr.w	ObjZ(a6)
	clr.w	UseLocAng(a6)
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	bsr	TransXYZ			Rotation du centre du cube
	movem.w	d0-d2,ModObjX(a6)		Et stockage
	lea	DemoCube(pc),a0
	clr.w	UseLocAng(a6)
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
SwapVars	move.l	a6,a5
	move.l	Other(a6),a6	Permutation
* Si le deuxiŠme joueur est dans le mˆme tableau que le premier,
* alors on n'utilise qu'une seule liste d'objets.
	tst.w	Joueur(a6)
	beq.s	SW.Return
	move.w	Tableau(a6),d0
	cmp.w	Tableau(a5),d0
	bne.s	SW.Return
	tst.w	JSuisMort(a5)
	bne.s	SW.Return

	lea	OList(a6),a0
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
* W : Num‚ro d'objet dans la table ObjTab
* W : Timer (si n‚gatif, l'objet n'est pas calcul‚)
* 3W: X,Y,Z de l'objet
* 3W: Donn‚es pour l'objet (Utilis‚ par les .I)

* Tri … bulle selon les Z d‚croissants
* D5 est … -1 si il y a eu une permutation,0 sinon
DrawWorld	cmp.w	#-$20,Alpha(a6)
	bpl.s	DW.Bas
	move.w	#-1,NumOmb(a6)
	bra.s	DW.OEA
DW.Bas	cmp.w	#8001,AltiOmb(a6)
	bne.s	DW.OEA
	bsr	TraceOmbre	Si l'ombre est au sol, on trace
DW.OEA	clr.w	UseLocAng(a6)	Pas d'angles locaux dans les calculs de rotations
	move.w	#8001,NxAOmb(a6)	Prochaine altitude de l'ombre
	clr.w	NxNOmb(a6)	Indique pas d'objet sur lequel l'ombre est pos‚e

	move.w	ObjNum(a6),d7
	subq.w	#1,d7		Adaptation DBRA, plus un objet lu
	bmi	DW.End		Si 0 objet

	move.w	d7,-(sp)
	clr.w	ObjX(a6)		Effacement pour la routine de coordonn‚es
	clr.l	ObjY(a6)
* Rotation des diff‚rents sommets
	lea	OList(a6),a0
DW.Somm	movem.w	4(a0),d0-d2
	movem.l	d7/a0,-(sp)
	bsr	TransXYZ
	movem.l	(sp)+,d7/a0
	cmp.w	#-3000,d2		Si le Z modifi‚ est n‚gatif, on indique que l'objet ne doit pas etre affich‚
	bpl.s	DW.BuBul
	move.w	6(a0),d3		Teste si objet sous ombre
	cmp.w	AltiOmb(a6),d3	si oui
	beq.s	DW.BuBul		Alors ne pas effacer
	move.w	Joueur(a6),d3
	move.b	#-3,2(a0,d3.w)
DW.BuBul	movem.w	d0-d2,16(a0)	Stockage des coordonn‚es modifi‚es
	lea	32(a0),a0
	dbra	d7,DW.Somm

DW.DoBul	move.w	(sp),d7
	lea	OList(a6),a0
	moveq	#0,d5		D5: Indicateur de permutation <>0 si une permutation a ‚t‚ effectu‚e
	move.w	#$50,-32(a0)
	move.w	#$FFFF,-32+2(a0)	Indique objet non visible
	move.w	#$7FFF,-32+20(a0)	Indique un Z modifi‚ pour le premier point qui ne provoquera pas de permutation

DW.Bulle	move.w	20(a0),d2		Lecture du Z modifi‚
	move.w	-32+20(a0),d1	Lecture du Z modifi‚ de l'objet pr‚c‚dent

	cmp.w	d1,d2		L'objet actuel est-il plus proche que celui d'avant
	ble.s	DW.BulOk		Si oui, pas de permutation

	moveq	#-1,d5		Indique qu'une permutation a ‚t‚ effectu‚e
	movem.l	-32(a0),d1-d4	lecture des 32 octets
	movem.l	(a0),a1-a4
	movem.l	d1-d4,(a0)	Ecriture permut‚e
	movem.l	a1-a4,-32(a0)
	movem.l	-16(a0),d1-d4	lecture des 32 octets
	movem.l	16(a0),a1-a4
	movem.l	d1-d4,16(a0)	Ecriture permut‚e
	movem.l	a1-a4,-16(a0)


DW.BulOk	lea	32(a0),a0		Passage … l'objet suivant
	dbra	d7,DW.Bulle
	tst.w	d5		Teste si au moins une permutation a ‚t‚ faite
	bne	DW.DoBul		Si oui, on recommence jusqu'au classement final


* On a maintenant une liste tri‚e dans l'ordre des Z d‚croissants
* DeuxiŠme partie : l'affichage par AffObj
* On commence par lire les coordonn‚es, que l'on stocke dans ObjX
* Ensuite on appelle la routine associ‚e … l'objet
* Enfin on trace l'objet si le Timer est Ok

	lea	OList(a6),a3
	move.w	(sp)+,d7		R‚cup‚ration du nombre d'objets

DW.DLoop	move.w	#-1,ObjetVu(a6)	Indique qu'a priori, l'objet est invisible
	movem.w	(a3)+,d5		Lecture de l'index et du timer
	addq.l	#2,a3
	move.w	d5,d6
	and.w	#$F,d6
	move.w	d6,DefColor(a6)
	
	and.w	#$FFF0,d5		Pointe avec index/16 sur une table
	lsr.w	#1,d5		de 2Longs.

	movem.w	12(a3),d0-d2	Lecture des coordonn‚es transform‚es
	movem.w	d0-d2,ModObjX(a6)	Et stockage
	movem.w	(a3),d0-d2
	movem.w	d0-d2,ObjX(a6)	Stockage des coordonn‚es
	move.l	AdObjTab(a6),a0
	movem.l	0(a0,d5.w),a1/a5
	lea	ObjPrgs(pc),a2
	lea	0(a2,a5.l),a5	R‚cupŠre l'adresse du programme .I
	lea	0(a0,a1.l),a0	Et l'adresse de l'objet … afficher
	movem.l	d7/a0/a3,-(sp)

	clr.w	UseLocAng(a6)
	jsr	(a5)		Appel de la routine .I associ‚e
	movem.l	(sp),d7/a0/a3

	cmp.w	#-1,NumOmb(a6)	Teste si l'ombre a ‚t‚ affich‚e
	bne.s	DW.VNoDisp	Sinon, n'essaie pas d'afficher le vaisseau

	move.w	16(a3),d0		Teste si l'objet est encore devant le vaisseau
	bmi.s	DW.VNoDisp
	cmp.w	PosZ(a6),d0
	bge.s	DW.VNoDisp
	bsr	TraceVaiss	Sinon, affiche le vaisseau
	movem.l	(sp)+,d7/a0/a3
	subq.l	#4,a3
	bra.s	DW.DLoop
DW.VNoDisp:
	move.w	Joueur(a6),d0
	addq.b	#1,-2(a3,d0.w)		Incr‚mentation du timer
	bvs.s	DW.TimOut		teste si pas de d‚passement de capacit‚
	ble.s	DW.NoDisp		Si n‚gatif ou nul: on laisse tomber

DW.DoDisp	bsr	AffObj		Sinon, on affiche l'objet
	tst.w	ObjetVu(a6)
	beq.s	DW.NoDisp
	movem.l	(sp),d7/a0/a3	Indique que l'objet n'a pas ‚t‚ affich‚
	move.w	NumOmb(a6),d0	Sauf si l'ombre est pos‚e dessus
	cmp.w	26(a3),d0
	beq.s	DW.NoDisp
	move.w	Joueur(a6),d0
	move.b	#-3,-2(a3,d0.w)

DW.NoDisp	movem.l	(sp),d7/a0/a3
	move.w	NumOmb(a6),d0	Si l'objet sur lequel est pos‚ l'ombre
	cmp.w	26(a3),d0
	bne.s	DW.ANeg
	bsr	TraceOmbre	Affiche l'ombre

DW.ANeg	movem.l	(sp)+,d7/a0/a3
	lea	28(a3),a3
DW.ObjClr	dbra	d7,DW.DLoop

DW.End	cmp.w	#-1,NumOmb(a6)
	bne.s	DW.VNoDisp2
	bsr	TraceVaiss
DW.VNoDisp2:
	move.w	NxAOmb(a6),AltiOmb(a6)
	move.w	NxNOmb(a6),NumOmb(a6)
	rts
DW.TimOut	clr.b	-2(a3,d0)		En cas de d‚passement du timer, remise … 0
	bra.s	DW.DoDisp		Et affichage

***************************************************************************
*		Affichage d'un objet point‚ par A0
***************************************************************************
* Entr‚e : A0 pointant sur l'objet
*  Cet objet est de la forme suivante :
*   dec.B : D‚calage d'un sommet par rapport au pr‚c‚dent (voir table)
*  0
*   ref : Index de sommet de r‚f‚rence pour sous-objets
*    n1 n2 ... : Liste des facettes (num‚ro < 127)
*    $xC ou x>8 : fin de liste de sommets -> Couleur de la facette
*    0 : Fin de d‚finition de sous-objet
*   0 : fin de d‚finition d'objet
*
* D‚finition des d‚calages  de passage d'un sommet … l'autre
*
	RSRESET
END	rs.b	1	Fin de la liste de sommets

XP1	rs.b	1	Ajout de 100 … l'axe X
XM1	rs.b	1	Soustraction de 100
YP1	rs.b	1
YM1	rs.b	1
ZP1	rs.b	1
ZM1	rs.b	1
XP2	rs.b	1	Ajout de 200 … l'axe X
XM2	rs.b	1	Soustraction de 200
YP2	rs.b	1
YM2	rs.b	1
ZP2	rs.b	1
ZM2	rs.b	1
XP3	rs.b	1	Ajout de 300 … l'axe X
XM3	rs.b	1	Soustraction de 300
YP3	rs.b	1
YM3	rs.b	1
ZP3	rs.b	1
ZM3	rs.b	1
XP4	rs.b	1	Ajout de 400 … l'axe X
XM4	rs.b	1	Soustraction de 400
YP4	rs.b	1
YM4	rs.b	1
ZP4	rs.b	1
ZM4	rs.b	1
XP5	rs.b	1	Ajout de 500 … l'axe X
XM5	rs.b	1	Soustraction de 500
YP5	rs.b	1
YM5	rs.b	1
ZP5	rs.b	1
ZM5	rs.b	1
XP10	rs.b	1	Ajout de 1000 … l'axe X
XM10	rs.b	1	Soustraction de 1000
YP10	rs.b	1
YM10	rs.b	1
ZP10	rs.b	1
ZM10	rs.b	1

ORIG	rs.b	1	Passage au point origine
GO1	rs.b	1	Sommet absolu 1 (rotation effectu‚e sur le moment)
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

XP1.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP1.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP1.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts

XP2.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP2.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP2.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP3.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP3.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP3.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP4.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP4.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP4.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP5.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP5.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP5.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP10.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP10.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP10.Dir	add.w	#0,d0		Valeurs Patch‚es par TrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts


XM1.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM1.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM1.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts

XM2.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM2.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM2.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM3.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM3.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM3.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM4.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM4.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM4.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM5.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM5.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM5.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM10.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM10.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM10.Dir	sub.w	#0,d0		Valeurs Patch‚es par TrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts


Origin.Dir:
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	rts
Point1.Dir:
	movem.w	CPoint1(a6),d0-d2
	bra	TriRotate
Point2.Dir:
	movem.w	CPoint2(a6),d0-d2
	bra	TriRotate
Point3.Dir:
	movem.w	CPoint3(a6),d0-d2
	bra	TriRotate
Point4.Dir:
	movem.w	CPoint4(a6),d0-d2
	bra	TriRotate
Point5.Dir:
	movem.w	CPoint5(a6),d0-d2
	bra	TriRotate
Point6.Dir:
	movem.w	CPoint6(a6),d0-d2
	bra	TriRotate
Point7.Dir:
	movem.w	CPoint7(a6),d0-d2
	bra	TriRotate
Point8.Dir:
	movem.w	CPoint8(a6),d0-d2
	bra	TriRotate
Point9.Dir:
	movem.w	CPoint9(a6),d0-d2
	bra	TriRotate
Point10.Dir:
	movem.w	CPoint10(a6),d0-d2
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

XP1.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP1.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP1.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts

XP2.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP2.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP2.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP3.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP3.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP3.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP4.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP4.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP4.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP5.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP5.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP5.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
XP10.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
YP10.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts
ZP10.LDir	add.w	#0,d0		Valeurs Patch‚es par LTrigInit
	add.w	#0,d1
	add.w	#0,d2
	rts


XM1.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM1.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM1.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts

XM2.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM2.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM2.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM3.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM3.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM3.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM4.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM4.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM4.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM5.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM5.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM5.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
XM10.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
YM10.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts
ZM10.LDir	sub.w	#0,d0		Valeurs Patch‚es par LTrigInit
	sub.w	#0,d1
	sub.w	#0,d2
	rts


Origin.LDir:
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	rts
Point1.LDir:
	movem.w	CPoint1(a6),d0-d2
	bra.s	Point.LDir
Point2.LDir:
	movem.w	CPoint2(a6),d0-d2
	bra.s	Point.LDir
Point3.LDir:
	movem.w	CPoint3(a6),d0-d2
	bra.s	Point.LDir
Point4.LDir:
	movem.w	CPoint4(a6),d0-d2
	bra.s	Point.LDir
Point5.LDir:
	movem.w	CPoint5(a6),d0-d2
	bra.s	Point.LDir
Point6.LDir:
	movem.w	CPoint6(a6),d0-d2
	bra.s	Point.LDir
Point7.LDir:
	movem.w	CPoint7(a6),d0-d2
	bra.s	Point.LDir
Point8.LDir:
	movem.w	CPoint8(a6),d0-d2
	bra.s	Point.LDir
Point9.LDir:
	movem.w	CPoint9(a6),d0-d2
	bra.s	Point.LDir
Point10.LDir:
	movem.w	CPoint10(a6),d0-d2

Point.LDir	bsr	TriRotateL
	bra	TriRotate


AffObj	lea	Sommets(a6),a5
	moveq	#0,d6		d6: Compteur de >0 et <0
	moveq	#0,d7		Zero sommets pour l'instant
	moveq	#0,d0		Coordonn‚es de d‚part
	moveq	#0,d1
	moveq	#0,d2

	lea	DirTab(pc),a1
	tst.w	UseLocAng(a6)
	beq.s	AO.Somm

* Utilisation des registres :
* D0-2 : X Y Z courants par rapport … X
* D3-D5: Usages divers
* d6 : Indicateur avant/arriŠre
* 	Si d6=-NbSommets, tout est derriŠre : On ne trace rien
* 	Si d6=0, tout est devant > l'inverse
* D7 : Nombre de sommets ainsi transform‚s
* A0 : Pointeur sur la liste de descriptions de sommets
* A5 : Pointeur sur la table de sommets

* Transformation de coordonn‚es pour tous les sommets

	movem.l	d0-d2/d6/d7/a0/a5,-(sp)
	bsr	LTrigInit			Init. lignes Trigo Locale
	movem.l	(sp)+,d0-d2/d6/d7/a0/a5
	lea	LDirTab(pc),a1

AO.Somm	movem.w	ModObjX(a6),d3-d5		Lecture de la position du centre
	add.w	d0,d3
	add.w	d1,d4
	add.w	d2,d5
	movem.w	d3-d5,(a5)		Stockage du point obtenu
	addq.l	#8,a5			AccŠs rapide (8 octets / sommet)

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
	beq	AO.Quit		Si oui, on ne trace rien.

	tst.w	d6		d6 est-il nul (tout devant)
	bne.s	AO.Cheval		On est … cheval dessus

* Transformation globale de perspective quand l'objet est entiŠrement devant
	lea	Sommets(a6),a5
	subq.w	#1,d5		Adaptation DBRA
AO.DoPer1	movem.w	(a5),d0-d2	lecture des coordonn‚es
	bsr	Perspect
	movem.w	d0-d1,(a5)
	addq.l	#8,a5
	dbra	d5,AO.DoPer1

* Macro de recherche d'adresse et de Z de sous objet
AOSSOBJ	MACRO	(num‚ro de registre)
	move.l	a0,a\1		a1 : Pointeur de sous objet 1
	lsl.w	#3,d0		d0 pointe dans la liste de sommets
	move.w	4(a5,d0.w),d\1	d1 : Z du sous-objet
	moveq	#0,d0
AO.SSOB\@	move.b	(a0)+,d0
	bne.s	AO.SSOB\@		Recherche du sous-objet suivant
	ENDM

* Test des sous-objets ‚ventuels
AO.Cheval	lea	Sommets-8(a6),a5	a5 pointeur de sommets
	moveq	#0,d0
	move.b	(a0)+,d0		Lecture de la facette de r‚f‚rence
	beq	AO.Quit		rien … tracer
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
	cmp.w	d1,d2
	ble.s	AO.Ok12
	exg.l	a1,a2
	exg.l	d1,d2
AO.Ok12	cmp.w	d2,d3
	ble.s	AO.Ok23
	exg.l	a2,a3
	exg.l	d2,d3
AO.Ok23	cmp.w	d1,d3
	ble.s	AO.Ok13
	exg.l	a1,a3

AO.Ok13	movem.l	a2/a3,-(sp)

	move.l	a1,a0
	bsr.s	AO.Concav
	move.l	(sp)+,a0
	bsr.s	AO.Concav
	move.l	(sp)+,a0


* Affichage d'un sous-objet concave point‚ par a0
* d6 contient 0 si tout est devant, auquel cas les perspectives sont faites
AO.Concav	move.w	d6,-(sp)		Sauvegarde l'indicateur ZClip
	beq	AO.Good

* Avant le ZClipping, on ferme le polygone
	lea	FacFill(pc),a2
	move.l	a2,Filler(a6)
AO.Bad	lea	AO.FerTab(a6),a2
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

* Ici on effectue un clip Z sur les polygones trac‚s
* M‚thode :
* Deux boucles: l'une si le dernier point lu est positif
* auquel cas on l'entre et on lit le deuxiŠme point
* l'autre pour les points n‚gatifs, que l'on n'entre pas
* Quand on passe de l'une … l'autre, on fait un calcul d'intersection
* qui rajoute un point au polygone.
*
* Formule d'intersection: x0 = x2-(x1-x2)*z2/(z1-z2)
	lea	PolySomm(a6),a4	Liste des sommets du polygone
	lea	Sommets-8(a6),a5	Pointeur sur les sommets
	moveq	#0,d3		Compteur d'angles du Polygone

	moveq	#0,d0		Pour Byte -> Word Unsigned
	move.b	(a0)+,d0
	beq	AO.End		Si lecture de la fin
	bmi	AO.BEnd		Si lecture de la couleur

	lsl.w	#3,d0		Pointe sur les sommets
	movem.w	0(a5,d0.w),d0-d2	Lecture de X,Y,Z
	tst.w	d2
	bmi.s	AO.BNeg		Passage dans la boucle des n‚gatifs

* Boucle : le dernier point lu ‚tait positif (-> D0-D2)
AO.BPos	movem.w	d0-d2,(a4)
	movem.w	(a4),d4-d6
	addq.l	#6,a4
	addq.w	#1,d3		Incr‚mente le compteur d'angles

	moveq	#0,d0
	move.b	(a0)+,d0		Lecture du point suivant
	beq	AO.End
	bmi	AO.BEnd
	lsl.w	#3,d0
	movem.w	0(a5,d0.w),d0-d2
	tst.w	d2		Si positif, on l'entre et on recommence
	bpl.s	AO.BPos

* Ici, on a un point n‚gatif dans D0-2 et positif dans D4-6
	movem.w	d0-d2,-(sp)	Stockage des anciens (n‚gatif)

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

	movem.w	d0-d2,(a4)
	addq.l	#6,a4
	addq.w	#1,d3		Un sommet de plus

	movem.w	(sp)+,d0-d2	R‚cup‚ration du sommet devant

* Boucle o— le dernier point est n‚gatif (dans D0-2)
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

* Ici, on a un point positif dans D0-2 et n‚gatif dans D4-6
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

	movem.w	d0-d2,(a4)	On stocke le point d'intersection
	addq.l	#6,a4
	addq.w	#1,d3

	movem.w	(sp)+,d0-d2	Et on r‚cupŠre le point suivant
	bra	AO.BPos		et on retourne dans les positifs (stockage)

AO.BEnd	cmp.b	#$F0,d0
	bhs.s	AO.BEnd2
	add.w	DefColor(a6),d0
AO.BEnd2	and.w	#$F,d0		Fin de lecture d'une facette
	move.w	d0,Couleur(a6)	Stockage de la couleur
	cmp.w	#2,d3
	blt	AO.ReBad		Si oui, on ne plante pas la routine de remplissage

* On a maintenant dans PolySomm des sommets … trois points sans perspective
* On effectue donc la perspective
	move.w	d3,d7
	move.w	d7,d6		Sauvegarde du nombre de points dans D6
	subq.w	#1,d7		Adaptation DBRA
	lea	PolySomm(a6),a4	A4 : pointeur de lecture
	move.l	a4,a5		A5 : Pointeur d'‚criture
* On va lire dans le tableau 3 coordonn‚es et en ‚crire 2: le pointeur
* A5 avancera moins vite que A4, donc ce n'est pas genant
AO.BPers	movem.w	(a4)+,d0-d2
	bsr	Perspect
	move.w	d0,(a5)+
	move.w	d1,(a5)+
	dbra	d7,AO.BPers
	move.w	d6,d3		R‚cup‚ration du nombre de points
	move.l	a3,-(sp)
	move.l	Filler(a6),a3
	jsr	(a3)		Remplissage de facette (selon le cas uniquement positive ou non)
	move.l	(sp)+,a3
AO.ReBad	move.l	a3,a0
	bra	AO.Bad

* Affichage d'un sous objet sans Z-Clipping (tous les sommets sont devant)
AO.Good	lea	PolySomm(a6),a4	Liste des sommets du polygone
	lea	Sommets-8(a6),a5	Pointeur sur les sommets
	moveq	#0,d3		Compteur d'angles du Polygone

AO.GLoop	moveq	#0,d0		Pour Byte -> Word Unsigned
	move.b	(a0)+,d0
	beq.s	AO.End		Si lecture de la fin
	bmi.s	AO.GEnd		Si lecture de la couleur

	lsl.w	#3,d0		Pointe sur les sommets
	movem.w	0(a5,d0.w),d0-d2	Lecture de X et Y. Z est lu pour usage par DoCircle
	move.w	d0,(a4)+
	move.w	d1,(a4)+
	addq.w	#1,d3		Incr‚mente le compteur d'angles

	bra.s	AO.GLoop

AO.GEnd	cmp.b	#$F0,d0		Teste les codes couleurs en E
	bhs.s	AO.GEnd2
	add.w	DefColor(a6),d0
AO.GEnd2	and.w	#$F,d0		Fin de lecture d'une facette
	move.w	d0,Couleur(a6)	Stockage de la couleur

	cmp.w	#1,d3		Teste si un seul point (definition d'une sphere)
	beq.s	AO.Sphere		(Le cas ne se traite que dans AO.Good: 0<Int<1 n'existe pas)

	bsr	FacFill		Remplissage de facette positive
	bra.s	AO.Good

AO.End	move.w	(sp)+,d6
AO.Quit	rts			Fin de l'affichage d'objet

* Cas particulier de la sphere. D2=Z du centre
AO.Sphere	moveq	#0,d0
	move.b	(a0)+,d0		Lecture du rayon
	mulu.w	#10,d0		Multiplication par 10

	move.w	LFactor(a6),d3	Calcul de la perspective
	ext.l	d0
	asl.l	d3,d0
	move.w	KFactor(a6),d3
	add.w	d2,d3
	divs	d3,d0
	move.w	d0,d1

	moveq	#32,d6
	moveq	#31,d7		32 points pour un cercle

	lea	PolySomm(a6),a1
	move.l	(a1),-(sp)	Sauvegarde les coordonn‚es
	move.l	a0,-(sp)
	bsr	DoCircle
	move.l	(sp)+,a0

	movem.w	(sp)+,d0-d1
	lea	PolySomm(a6),a1
	moveq	#31,d7
AO.SphOf	add.w	d0,(a1)+		Calcule le d‚calage ‚cran
	add.w	d1,(a1)+
	dbra	d7,AO.SphOf

	moveq	#32,d3		Effectue le remplissage
	pea	AO.Good(pc)		Pour que le RTS envoie sur AO.Good
	move.l	a0,-(sp)
	lea	PolySomm(a6),a0

	bra	FacFill.NonOr

* DoCircle :  Trace une ellipse dans une zone m‚moire
* Entr‚e: A1 : Zone o— ‚crire
*	D0,D1 : rayons X et Y
*	D5: Angle de l'axe X avec l'horizontale
*	D6: Decalage angulaire entre deux points successifs
*	D7: Nombre de points
DoCircle	move.w	d0,-(sp)
	move.w	d1,-(sp)
DoCirc.1	move.w	d5,d1		D‚termine 300 CosY et 300 SinY
	move.w	(sp),d0
	bsr	XSinY
	move.w	d2,-(sp)
	move.w	d5,d1
	move.w	4(sp),d0
	bsr	XCosY
	move.w	(sp)+,(a1)+	Stockage des coordonn‚es
	move.w	d2,(a1)+
	add.w	d6,d5		Angle suivant

	dbra	d7,DoCirc.1
	addq.l	#4,sp		R‚cupŠre D1 et D2
	rts


* Cas particulier de la ligne
AO.Line	moveq	#0,d7		Pour Byte -> Word Unsigne
	move.b	(a0)+,d7

	lea	Sommets-8(a6),a5
	lsl.w	#3,d7		Pointe sur les sommets
	movem.w	0(a5,d7.w),d0-d2	Lecture de X,Y,Z
	move.b	(a0)+,d7
	lsl.w	#3,d7
	movem.w	0(a5,d7.w),d3-d5
	move.b	1(a0),d7
	cmp.b	#$F0,d7
	bhs.s	AO.LiCol		Couleur par d‚faut
	add.w	DefColor(a6),d7
AO.LiCol	and.w	#$F,d7
	move.w	d7,Couleur(a6)

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

AO.IsPos	movem.w	d3-d5,-(sp)	Trac‚ d'une ligne toute devant
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
* Entr‚e : D3 : Nombre de sommets
* PolySomm(a6) rempli par les dits sommets

FacFill	move.l	a0,-(sp)
	cmp.w	#2,d3		Trac‚ d'une ligne
	blt.s	FF.End
	beq.s	FF.Line

	lea	PolySomm(a6),a0
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
	bgt.s	FF.End		Retour si facette "… l'envers"

FacFill.NonOr:
	btst	#1,Options2(a6)
	bne.s	FF.Lines

	moveq	#0,d1
	moveq	#0,d2		OffSet ‚cran

	bsr	FillPoly
FF.End	move.l	(sp)+,a0
	rts

* Remplissage avec facettes non orient‚es
FF.NonOriented:
	move.w	TextColor(a6),Couleur(a6)
	lea	PolySomm(a6),a0
	moveq	#0,d1
	moveq	#0,d2		OffSet ‚cran
	bra	FillPoly

FF.Line	movem.w	PolySomm(a6),d0-d3
	bsr	Line
	bra.s	FF.End

FF.Lines	lea	PolySomm(a6),a0
	subq.w	#2,d3
	move.w	d3,d7
FF.Lines1	movem.l	a0/d7,-(sp)
	movem.w	(a0),d0-d3
	bsr	Line
	movem.l	(sp)+,a0/d7
	addq.l	#4,a0
	dbra	d7,FF.Lines1
	movem.w	(a0),d0-d1
	movem.w	PolySomm(a6),d2-d3
	bsr	Line
	bra.s	FF.End

***************************************************************************
*		Routine de transformation de coordonn‚es 
***************************************************************************
* Entr‚e : D0, D1 et D2 contiennent les coordonn‚es
* Sortie : les memes, en fonction de :
*  Alpha, Beta, Gamma : angles de vision
*  CurX, CurY, CurZ : Positions de l'observateur
*  ObjX, ObjY, ObjZ : Positions de l'objet
*	PAS DE CALCUL DE PERSPECTIVE ICI !
***************************************************************************


TransXYZ	tst.w	UseLocAng(a6)
	beq.s	TXYZ.NoL
	bsr	TriRotateL

TXYZ.NoL	sub.w	CurX(a6),d0	Position relative / observateur
	sub.w	CurY(a6),d1
	sub.w	CurZ(a6),d2
	add.w	ObjX(a6),d0
	add.w	ObjY(a6),d1
	add.w	ObjZ(a6),d2

	bsr.s	TriRotate
	add.w	PosZ(a6),d2
	rts

****************************************************************************
*		Calculs de perspective en fonction des facteurs...
****************************************************************************
* V‚rifier si pas plus rapide pour les perspectives (2*&2/ Ayayay)
Perspect	move.w	LFactor(a6),d3	Calcul de la perspective
	ext.l	d0
	asl.l	d3,d0
	ext.l	d1
	asl.l	d3,d1
	move.w	KFactor(a6),d3
	add.w	d2,d3
	divs	d3,d0
	divs	d3,d1	

	add.w	PosX(a6),d0	Effectue les d‚calages ‚cran
	add.w	PosY(a6),d1
	rts


****************************************************************************
* Triple rotation de d0-d2 selon Alpha, Beta et Gamma (trigo pr‚mach‚e)
****************************************************************************
TriRotate:
	move.w	d0,d6		Rotation autour de OY
	move.w	d2,d7		Sauvegarde X & Z

	muls	CosB(a6),d0	X cos B
	muls	SinB(a6),d2	Z sin B
	sub.l	d2,d0		-
	swap	d0
	add.w	d0,d0		=X

	muls	SinB(a6),d6
	muls	CosB(a6),d7
	add.l	d6,d7
	swap	d7
	add.w	d7,d7
	move.w	d7,d2		=Z

	move.w	d1,d6		Rotation autour de OX
	move.w	d2,d7		Sauvegarde Y & Z

	muls	CosA(a6),d1
	muls	SinA(a6),d2
	sub.l	d2,d1
	swap	d1
	add.w	d1,d1		=Y

	muls	SinA(a6),d6
	muls	CosA(a6),d7
	add.l	d6,d7
	swap	d7
	add.w	d7,d7
	move.w	d7,d2		=Z

	move.w	d0,d6		Rotation autour de OZ
	move.w	d1,d7		Sauvegarde X & Y

	muls	CosC(a6),d0
	muls	SinC(a6),d1
	sub.l	d1,d0
	swap	d0
	add.w	d0,d0		=X

	muls	SinC(a6),d6
	muls	CosC(a6),d7
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
	move.w	GammaL(a6),d7
	bsr.s	Rotate		Rotation autour de Oz
	move.w	d0,(sp)		Stockage de X2

	move.w	d1,d5		d5=Y2
	move.w	4(sp),d6		D6=Z2=Z1
	move.w	AlphaL(a6),d7
	bsr.s	Rotate		Rotation autour de Ox
	move.w	d0,2(sp)		Stockage de Y3

	move.w	(sp),d5		d5=X3=X2
	move.w	d1,d6		d6=Z3
	move.w	BetaL(a6),d7
	bsr.s	Rotate		Rotation autour de Oy
	move.w	d1,d2		D2=Z
	move.w	2(sp),d1		D1=Y

	addq.l	#6,sp		Restauration pointeur de pile
	rts
	

***************************************************************************
*		Routine de rotation 
***************************************************************************
* Rotation autour d'un axe :
* Entr‚e : D5.w = X,  D6.w = Y
*	 D7.w = Angle de rotation
* Sortie : D0.w = X', D1.w = Y'
*
* Formules utilis‚es :
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
	sub.w	d2,d4	et calcul de la diff‚rence
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
* Entr‚e : D0.W=X, D1.W=Y
* Sortie : D2.W=X*COS(Y)

XCosY	add.w	#256,d1	cos X=sin(X+PI/2)

* Routine X*SIN(Y)
* Entr‚e : D0.W=X, D1.W=Y
* Sortie : D2.W=X*SIN(Y)

XSinY	and.w	#$3FF,d1	RamŠne Y modulo 2*PI
	add.w	d1,d1
	lea	SinTab(pc),a0
	move.w	0(a0,d1.w),d2
	muls	d0,d2
	add.l	d2,d2
	swap	d2
	rts


***************************************************************************
*		Initialisation de CosA, SinA, CosB,...
*		et patching des routines .DIR associ‚es
***************************************************************************
* D‚finition des Macros utilis‚es dans TrigInit
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
	move.w	Alpha(a6),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinA(a6)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosA(a6)

	move.w	Beta(a6),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinB(a6)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosB(a6)

	move.w	Gamma(a6),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinC(a6)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosC(a6)

	TI_Macro	100,0,0,X
	TI_Macro	0,100,0,Y
	TI_Macro	0,0,100,Z

	rts

* Version "Locale" de TrigInit
LTrigInit	lea	SinTab(pc),a0
	move.w	Alpha(a6),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinA(a6)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosA(a6)

	move.w	Beta(a6),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinB(a6)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosB(a6)

	move.w	Gamma(a6),d0
	and.w	#$3FF,d0
	add.w	d0,d0
	move.w	0(a0,d0.w),SinC(a6)
	add.w	#512,d0
	and.w	#$7FE,d0
	move.w	0(a0,d0.w),CosC(a6)

	LTI_Macro	100,0,0,X
	LTI_Macro	0,100,0,Y
	LTI_Macro	0,0,100,Z

	rts


***************************************************************************
*		Routine d'effacement de l'‚cran
***************************************************************************
ClsNorm	moveq	#0,d0
	bra.s	Cls2
Cls	moveq	#-1,d0
Cls2	move.l	a6,-(sp)
	move.l	LogScreen(a6),a0
	move.l	d0,d1	Initialisation des diff‚rents registres
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
	move.l	(sp)+,a6

	btst	#1,Options1(a6)
	beq.s	Cls.1P

	move.l	LogScreen(a6),a0
	lea	160*99(a0),a0
	moveq	#39,d7
Cls.01	move.l	#-1,(a0)+
	clr.l	(a0)+
	dbra	d7,Cls.01

Cls.1P	rts


***************************************************************************
*		Trac‚ d'une ligne sur l'‚cran
***************************************************************************
* Entr‚e : d0,d1 : Position de d‚part de la ligne
*	 d2,d3 : Position d'arriv‚e de la ligne


	
Line	movem.l d4-d7/a2-a6,-(sp)
	move.l	a6,a4		Sauvegarde du pointeur variables
	clr.w	ObjetVu(a6)

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
	beq	Li.okdraw

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

Li.okdraw
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
*	d4: dy	a4: libre
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



***************************************************************************
*		Trac‚ d'une ligne en haute r‚solution
*			Utilise LineA
***************************************************************************
LineHI	move.l	LineA(a4),a0

	add.w	d0,d0			Adaptation coordonn‚es
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
	movem.w	ClipG(a6),d0-d3		R‚cup‚ration des clips
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
*		Permutation d'‚cran
***************************************************************************
SwapScrn	move.l	Other(a6),a5
	btst	#1,Options1(a6)
	bne.s	SwS.Mono
	move.l	BackColor(a6),BackColor(a5)
	movem.l	CurColor(a6),d0-d7
	movem.l	d0-d7,CurColor(a5)

SwS.Mono	movem.l	LogScreen(a6),a0-a1
	exg	a0,a1
	movem.l	a0-a1,LogScreen(a6)
	movem.l	a0-a1,LogScreen(a5)
	move.w	#-1,-(sp)
	move.l	a1,-(sp)
	move.l	a0,-(sp)
	XBIOS	5,12
	move.w	Timer(a6),d0
	and.w	#3,d0
	bne.s	SwS.NoCol
	move.l	BackColor(a6),CurColor(a6)
	move.l	BackColor(a5),CurColor(a5)
SwS.NoCol	XBIOS	37,2
	rts


***************************************************************************
*		Initialisation
***************************************************************************
* Keyword #INIT
Init	move.l	a7,a5		R‚cupŠre l'adresse de la pile
	move.l	#Vars-Start,d0
	lea	Start(pc),a6
	add.l	d0,a6		a6 pointe sur VARS
	lea	TabVisit-Vars(a6),a4
	move.l	a4,TabVisitAd(a6)	Initialisation de l'adresse de TabVisit

	lea	Pile-Vars(a6),sp	SP pointe sur la pile

	move.l	#Screen-Vars,d0	Initialisation des adresses pointeurs
	lea	0(a6,d0.l),a0
	lea	TScreen-Screen(a0),a1
	add.l	#256,a0
	move.l	a0,d0
	and.l	#$FFFFFF00,d0
	move.l	d0,PhyScreen(a6)
	add.l	#32000,d0
	move.l	d0,Screen2Ad(a6)
	move.l	a1,AdTScreen(a6)

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
	move.l	d0,SpareUSP(a6)

	XBIOS	3,2
	move.l	d0,LogScreen(a6)	et physique
	move.l	d0,DefScreen(a6)

	XBIOS	4,2
	move.w	d0,OldResol(a6)
	cmp.w	#1,d0
	bne.s	Init.NoMed
	clr.w	-(sp)
	pea	-1.w
	pea	-1.w
	XBIOS	5,12
	moveq	#0,d0
Init.NoMed:
	move.w	d0,Resol(a6)

* Initialisation des joysticks et suppression de la souris
	dc.w	$a00a		Cache la souris

	pea	InitMouse(pc)
	move.w	#2,-(sp)
	XBIOS	25,8

	XBIOS	34,2		KBD vbase
	move.l	d0,a0
	move.l	16(a0),OldMsVec(a6)	Stocke l'ancien vecteur
	lea	MyMsVec(pc),a1
	move.l	a1,16(a0)		Stocke le nouveau vecteur

	move.l	24(a0),OldJoyst(a6)
	lea	MyJoyVec(pc),a1
	move.l	a1,24(a0)

	lea	IK.Patch+2(pc),a1
	move.l	$118.w,(a1)	Ecriture de la nouvelle interruption
	lea	IKInt(pc),a1
	move.l	a1,$118.w

	move.w	#1,InputDev(a6)	Choisit le clavier comme entr‚e

	dc.w	$A000		Initialisation LineA
	move.l	a0,LineA(a6)

ObjTabRef	move.l	#0+ObjTab-ObjTabRef,a0	Initialisation de l'adresse des tableaux
	lea	ObjTabRef(pc,a0.l),a0
	move.l	a0,AdObjTab(a6)

	and.b	#$FC,$484.w		Suppression du click clavier et du Repeat
	clr.w	Joueur(a6)		Indique que les sprites sont actifs (1 joueur)
	clr.w	FastFill(a6)	Remplissage normal
	move.w	#$0000,Options1(a6)	Retour au centre automatique et jeu … 2

	clr.l	SoundPtr+0.w		Pas de sauvegarde des registres pour le prochain son
	move.l	#MoveMemry-Vars,d0
	lea	0(a6,d0.l),a0
	move.l	a0,MoveMemAd(a6)
	lea	FinMvMemry-MoveMemry(a0),a0
	move.l	a0,EndMvMem(a6)

	lea	TabFileName(pc),a0
	bsr	LoadFile
	move.l	a0,Tableaux(a6)
	lea	NamesFileName(pc),a0
	bsr	LoadFile
	move.l	a0,TabNames(a6)
	lea	ScreenFileName(pc),a0
	bsr	LoadFile
	move.l	a0,BckScreen(a6)

	tst.w	Resol(a6)		Si en haute r‚solution, convertit l'image
	bne.s	Init.HiRes
	bsr	SetHAM		Passe en mode "HAM"
	bra.s	Init.LoRes
Init.HiRes:
	move.w	#0,$FFFF8240.w
	move.l	LogScreen(a6),a1
	lea	34(a0),a0
	move.w	#199,d7
Init.HLin	moveq	#19,d6
	move.w	d7,-(sp)
Init.HWrd	movem.w	(a0),d0-d3	Lecture des plans BR
	addq.l	#8,a0
	moveq	#0,d4		Plans HR pr‚vus
	moveq	#0,d5
	moveq	#15,d7		Compteur de bits
Init.HBit	roxl.w	#1,d0		Conversion plan BR->HR
	roxl.l	#1,d5
	roxl.w	#1,d1
	roxl.l	#1,d5
	roxl.w	#1,d2
	roxl.l	#1,d4
	roxl.w	#1,d3
	roxl.l	#1,d4
	dbra	d7,Init.HBit
	move.l	d5,(a1)+
	move.l	d4,76(a1)
	dbra	d6,Init.HWrd
	lea	80(a1),a1
	move.w	(sp)+,d7
	dbra	d7,Init.HLin

	move.l	LogScreen(a6),a0	Et copie du r‚sultat dans le BckScreen
	move.l	BckScreen(a6),a1
	lea	34(a1),a1
	bsr	CopyScreen

Init.LoRes:
	move.w	#7,Main.MID(a6)	Indique le d‚but du menu

* Initialisation des variables joueur2
	lea	DataLen(a6),a5	Pointe sur Vars2
	move.l	a6,a0
	move.l	a5,a1
Init.CpVars:
	move.w	(a0)+,(a1)+	Copie les variables initialis‚es
	cmp.l	a5,a0
	blt.s	Init.CpVars

	move.l	a6,Other(a5)	Chaque Other pointe sur l'autre groupe de variables
	move.l	a5,Other(a6)
	move.w	#1,Joueur(a5)	Indiquie no de joueur
	move.w	#2,InputDev(a5)

* Effacement des Joysticks
	lea	Joystick1(pc),a0
	clr.w	(a0)+
	clr.w	(a0)+

	bra	Main


TabFileName:
	dc.b	"TABLIB.QB",0
NamesFileName:
	dc.b	"TABNAMES.QB",0
ScreenFileName:
	dc.b	"ALPHA0.PI1",0

****************************************************************************
*	Chargement de fichier sur disque
****************************************************************************
* Entr‚e : A0= Pointeur sur le nom du fichier
* Sortie : A0= Pointeur sur le fichier charg‚
* Il y a pas int‚ret … ce qu'il y ait une erreur
LoadFile	move.l	a0,a5	Sauvegarde a0
	clr.w	-(sp)	AccŠs normal
	move.l	a0,-(sp)	Indique le nom du fichier
	GEMDOS	$4E,8	SEEK FIRST

	GEMDOS	$2F,2	R‚cupŠre l'adresse de DTA
	move.l	d0,a0
	move.l	26(a0),d5	R‚cupŠre la longueur du fichier

	move.l	d5,-(sp)	Indique que l'on veut r‚cup‚rer ces octets
	GEMDOS	$48,6	MALLOC
	move.l	d0,a4	R‚cupŠre l'adresse de transfert

	clr.w	-(sp)	En lecture seulement
	move.l	a5,-(sp)	Adresse du nom de fichier
	GEMDOS	$3D,8	OPEN

	move.w	d0,-(sp)
	move.l	a4,-(sp)	Adresse du chargement
	move.l	d5,-(sp)	Longueur … lire
	move.w	d0,-(sp)
	GEMDOS	$3F,12	READ

	GEMDOS	$3E,4	CLOSE (le handle est dans la pile)

	move.l	a4,a0	Adresse de la zone o— le fichier a ‚t‚ charg‚
	rts


****************************************************************************
*		Initialisation partielle en d‚but de partie
****************************************************************************
* Keyword #MINI
MiniInit	clr.w	Alpha(a6)		Initialisation des registres de position
	clr.w	Beta(a6)
	clr.w	Gamma(a6)
	clr.w	BetaSpeed(a6)	Pas de rotation automatique

	clr.w	CurX(a6)
	btst	#1,Options1(a6)
	beq.s	MI.Only1P
	move.w	Joueur(a6),d0
	lsl.w	#8,d0
	lsl.w	#5,d0
	sub.w	#4096,d0
	move.w	d0,CurX(a6)	Initialisation des positions
MI.Only1P	move.w	#-7900,CurY(a6)
	clr.w	CurZ(a6)
	clr.w	Seed(a6)		Initialisation du g‚n‚rateur al‚atoire

	move.l	$4BA,d0
	add.l	#3*200*60,d0	Temps de jeu: 5 mn au d‚but
	move.l	d0,SysTime0(a6)
	clr.w	ExtraTime(a6)

	clr.l	WhichBonus(a6)	Pas de Bonus ni de diamants
	clr.w	WhichDiamond(a6)
	clr.w	WhichProtect(a6)

	move.l	MoveMemAd(a6),a0	Initialise le pointeur de lecture
	move.l	a0,MovePtr(a6)
	btst	#1,Options1(a6)	Si deux joueurs
	bne.s	MI.NoRec		Pas d'enregistrement
	tst.w	InputDev(a6)
	bmi.s	MI.NoRec

	move.l	a0,EndMvMem(a6)

MI.NoRec	move.l	TabVisitAd(a6),a0
	move.w	#NTABS/4-1,d0
MI.ClrTab	clr.l	(a0)+
	dbra	d0,MI.ClrTab

	lea	Score(pc),a0
	move.l	#'0000',(a0)+
	move.l	#'0000',(a0)+
	clr.w	ToScore(a6)

	lea	Score2(pc),a0
	move.l	#'0000',(a0)+
	move.l	#'0000',(a0)+

	clr.w	JSuisMort(a6)
	clr.w	Tableau(a6)
	clr.w	Inact(a6)
	IFNE	CHEAT
		cmp.l	#$05121968,$202.w
		bne.s	PlayerSet
		move.w	$200.w,Tableau(a6)
		and.w	#NTABS-1,Tableau(a6)
	ENDC

PlayerSet	tst.w	Joueur(a6)
	bne.s	PSet.End
	btst	#1,Options1(a6)	Teste si jeu … 2
	bne.s	TwoPlayrs

OnePlayer	move.w	#160,PosX(a6)
	move.w	#100,PosY(a6)
	move.w	#900,PosZ(a6)
	move.w	#0,ClipH(a6)
	move.w	#199,ClipB(a6)
	move.w	#0,ClipG(a6)
	move.w	#319,ClipD(a6)

	move.w	#500,KFactor(a6)
	move.w	#7,LFactor(a6)

PSet.End	rts

TwoPlayrs	move.w	#160,PosX(a6)
	move.w	#50,PosY(a6)
	move.w	#900,PosZ(a6)
	move.w	#0,ClipH(a6)
	move.w	#98,ClipB(a6)
	move.w	#0,ClipG(a6)
	move.w	#319,ClipD(a6)

	move.w	#1000,KFactor(a6)
	move.w	#7,LFactor(a6)
	
	move.l	Other(a6),a5
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

InitMouse	dc.b	$14,$12
***************************************************************************
*	Interruption de lecture du clavier et des Joysticks
***************************************************************************
IKInt	movem.l	d0-d7/a0-a6,-(sp)
	pea	IK.Ret(pc)	Retour de la routine
	move.w	SR,d0		Empile SR
	move.w	d0,-(sp)
IK.Patch	jmp	0		Ex‚cute l'ancienne routine (patch‚)

* Routine appell‚e au retour de l'interruption clavier
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
	bmi.s	IK.Rel		soit … 0
	bset	d2,(a1)		soit … 1
	bra.s	IK.TheEnd
IK.Rel	bclr	d2,(a1)

IK.TheEnd	movem.l	(sp)+,d0-d7/a0-a6
	rte

Touches	dc.b	$1D,$01,0,0,$4D,$4b,$50,$48

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

	add.w	(a1),d0		V‚rification que sur l'‚cran    
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
*		Routines de trac‚ de la souris
****************************************************************************
DrawMouse	lea	MouseX(pc),a0
	move.w	(a0)+,d4		Lecture des coordonn‚e
	move.w	(a0)+,d0

	move.w	d0,d2
	add.w	d0,d0		*2
	add.w	d0,d0		*4
	add.w	d2,d0		*5
	lsl.w	#5,d0		*160	Offset de ligne

	move.w	d4,d2
	and.w	#$FFF0,d2		Num‚ro du mot
	asr.w	#1,d2		Position en octets
	add.w	d2,d0		Ajout‚ … l'offset

	move.l	LogScreen(a6),a0
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

	moveq	#0,d5		Lecture de la donn‚e
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
*		Routines de trac‚ des icones
****************************************************************************
* Entr‚e: D0: Num‚ro de l'icone
*	D1: Position horizontale de l'icone
* Pour DrawCIcon seulement
*	D2: Taux de compression de l'icone (1,2,4 ou 8)
*	D3: Position de l'icone sur l'‚cran (0,4,6,7)
* Variantes:
*  DrawDIcon: Icone qui se ferme
*  DrawIIcon: Icone qui s'ouvre
	IFEQ	1
DRAWIC	MACRO
	XBIOS	37,2
	movem.w	(sp),d0-d1
	moveq	#\1,d2
	moveq	#\2,d3
	bsr	DrawCIcon
	ENDM

DrawDIcon	movem.w	d0-d1,-(sp)
	DRAWIC	1,0
	DRAWIC	2,4
	DRAWIC	4,6
	DRAWIC	8,7
	movem.w	(sp)+,d0-d1
	rts

DrawIIcon	movem.w	d0-d1,-(sp)
	DRAWIC	8,7
	DRAWIC	4,6
	DRAWIC	2,4
	DRAWIC	1,0
	movem.w	(sp)+,d0-d1
	rts

DrawIcon	moveq	#1,d2
	moveq	#0,d3
DrawCIcon	move.l	LogScreen(a6),a0	Calcule la position ‚cran d'affichage
	move.w	d1,d7
	lsl.w	#3,d7
	lea	0(a0,d7.w),a0
	lea	29440(a0),a0

	lea	DrawCIcon(pc),a1	Calcule l'adresse de l'icone
	add.l	#TheIcons-DrawCIcon,a1
	lsl.w	#7,d0
	lea	0(a1,d0.w),a1

	tst.w	d3		Teste si position sur l'‚cran non nulle
	beq.s	DCI.NoCp		Pas de compression

	mulu	#160,d3		Position sur ‚cran du point de d‚part
	lea	0(a0,d3.w),a2

	moveq	#15,d7		Effacement du fond
DCI.1	clr.l	(a0)+
	clr.l	(a0)+
	lea	160-8(a0),a0
	dbra	d7,DCI.1
	move.l	a2,a0		R‚cupŠre le point de d‚part sur ‚cran

DCI.NoCp	moveq	#15,d7		Compteur de lignes Icone
	move.w	d2,d6		Calcul du d‚calage
	lsl.w	#3,d6
DCI.2	move.l	(a1)+,(a0)+
	move.l	(a1)+,(a0)+
	lea	160-8(a0),a0	Pointe sur la position ‚cran suivante
	lea	-8(a1,d6.w),a1	Pointe sur la position icone suivante
	sub.w	d2,d7
	bpl.s	DCI.2		Bouclage

	move.l	LogScreen(a6),a0	Assure la coh‚rence entre les ‚crans
	move.l	PhyScreen(a6),a1
	lea	29440(a0),a0
	lea	29440(a1),a1
	move.w	#639,d7
DCI.3	move.l	(a0)+,(a1)+
	dbra	d7,DCI.3

	rts

****************************************************************************
*		Affichage de tous les icones
****************************************************************************
DrawIcons	moveq	#6,d7		Compteur de bits
DIS.1	move.w	d7,-(sp)
	move.w	d7,d1
	move.w	d7,d0
	add.w	d0,d0
	btst	d7,Options2(a6)
	beq.s	DIS.Zero
	addq.w	#1,d0
DIS.Zero	bsr	DrawIcon
	move.w	(sp)+,d7
	dbra	d7,DIS.1

	moveq	#10,d7
	moveq	#7,d1
DIS.2	moveq	#Null.X,d0
	movem.w	d1/d7,-(sp)
	bsr	DrawIcon
	movem.w	(sp)+,d7/d1
	addq.w	#1,d1
	dbra	d7,DIS.2

	moveq	#Death.X,d0
	moveq	#18,d1
	bsr	DrawIcon
	moveq	#NMap.X,d0
	moveq	#17,d1
	bsr	DrawIcon
	moveq	#NWait.X,d0
	moveq	#16,d1
	bsr	DrawIcon

	moveq	#YNull.X,d0
	moveq	#15,d1
	bsr	DrawIcon
	moveq	#NNull.X,d0
	moveq	#7,d1
	bsr	DrawIcon

	lea	TabName(pc),a0	Affichage du nom du tableau
	move.l	LogScreen(a6),a1
	lea	160*188+56(a1),a1
	bsr	FastPrt
	moveq	#Disk.X,d0
	moveq	#19,d1
	bra	DrawIcon

	ENDC

****************************************************************************
*		Routines de gestion du son sous interruption
****************************************************************************
* SoundPtr+0 (INT1) est utilis‚ comme adresse des sons … jouer
* La routine de reproduction est patch‚e pour d‚terminer la fin du son … jouer
*		ROUTINES AIMABLEMENT FOURNIES PAR
*			ST-REPLAY (C) 2-Bits Systems

* Entr‚e :
* A0 : Adresse du son … jouer
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
	move.l	TBVEC+0.w,TBVEC.Old(a6)
	move.l	a0,TBVEC+0.w

	lea	HBLInter1(pc),a0	fixe le vecteur pour Tmr B
	move.l	a0,TBVEC+0.w

	lea	VBLInter(pc),a0	Fixe l'interruption de retour ‚cran
	move.l	$70.w,VBLJump+2-VBLInter(a0)
	move.l	a0,$70.w

	move.b	TBCR+0.w,TBCR.Old(a6)
	move.b	TBDR+0.w,TBDR.Old(a6)
	move.b	#8,TBCR+0.w	Event count mode sur B
	move.b	#130,TBDR+0.w	Toutes les 20 lignes

	move.b	IERA+0.w,IERA.Old(a6)
	move.b	IMRA+0.w,IMRA.Old(a6)
	move.b	VECTOR+0.w,VECTOR.Old(a6)
	bset	#0,IERA+0.w	Autorise les interruptions sur le Tmr B
	bset	#0,IMRA+0.w
	bclr.b	#3,VECTOR+0.w	Auto End of Int

	clr.w	CurColor(a6)
	moveq	#-1,d0
	move.l	d0,CurColor+2(a6)
	move.l	d0,CurColor+6(a6)
	move.l	d0,CurColor+28(a6)

	rts

* Supprime le changement de palette en lignes
ClearHAM	move.b	VECTOR.Old(a6),VECTOR+0.w
	move.b	IMRA.Old(a6),IMRA+0.w
	move.b	IERA.Old(a6),IERA+0.w
	move.b	TBDR.Old(a6),TBDR+0.w
	move.b	TBCR.Old(a6),TBCR+0.w
	move.l	TBVEC.Old(a6),TBVEC+0.w

	lea	VBLInter(pc),a0	Restaure la VBL
	move.l	VBLJump+2-VBLInter(a0),$70.w

	rts


HBLInter1	movem.l	d0-d7/a6,-(sp)
	lea	HBLInter1(pc),a6
	add.l	#Vars2-HBLInter1,a6

	movem.l	CurColor(a6),d0-d7
	lea	$FFFF8240.w,a6
	movem.l	d0-d7,(a6)
	movem.l	(sp)+,d0-d7/a6
	rte


VBLInter	move.b	#0,TBCR+0.w
	move.b	#100,TBDR+0.w
	move.b	#8,TBCR+0.w

	movem.l	d0-d7/a6,-(sp)
	lea	VBLInter(pc),a6
	add.l	#Vars-VBLInter,a6
	movem.l	CurColor(a6),d0-d7
	lea	$FFFF8240.w,a6
	movem.l	d0-d7,(a6)

	movem.l	(sp)+,d0-d7/a6

VBLJump	jmp	0

*******************************************************************************
* Routine PlaySound
* Entr‚e:
*  D6: Sample … jouer
*  D7: Vitesse … laquelle le jouer
*******************************************************************************

SoundPtr	EQU	$8C	Adresse du son en cours

PlaySound	btst	#6,Options2(a6)
	bne.s	PS.PasSon
	tst.w	Joueur(a6)
	beq.s	PS.Playr1
	move.l	Other(a6),a6	Si jamais sur le mauvais joueur
	bsr.s	PS.Playr1
	move.l	Other(a6),a6
PS.PasSon	rts

PS.Playr1	tst.w	d6
	beq.s	PS.Ret
	tst.l	SoundPtr+0.w
	beq.s	PS.Rien
	move.w	#$2700,SR
	move.l	a6,a0
	bsr	OLDMFP		Restaure les anciens MFP

PS.Rien	lea	TheSounds(pc),a0	Recherche du bon son
PS.Next	move.w	(a0),d0
	lea	0(a0,d0.w),a0
	dbra	d6,PS.Next

	move.w	(a0)+,d0
	ext.l	d0
	move.l	a0,SoundPtr+0.w		Stocke l'adresse du son … jouer
	add.l	a0,d0
	subq.l	#4,d0		On arrete un peu avant si le fichier a une longueur impaire
	lea	PS.Patch+2(pc),a0	Patche l'adresse de fin (W)
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

* Nettoie tout … la fin du son jou‚
PS.EXIT	MOVE.W	#$2700,SR		DISABLE INTS.
	lea	PS.INull(pc),a0
	bsr	SETINT		Installe une interruption vide

	move.l	#Vars-PS.EXIT,a0
	lea	PS.EXIT(pc,a0.l),a0
	BSR	OLDMFP		RESTORE ORIGINAL MFP DATA
	move.w	#$2300,SR		Remet les interruptions
	clr.l	SoundPtr+0.w		Indique "Son termin‚"
	movem.l	(sp)+,d0-d1/a0	Et r‚staure les registres
	rte



*****************************************
*	THE SYSTEM SUB-ROUTINES	 *
*****************************************
*****************************************
*	PRESERVE THE MFP REGISTERS	*
*****************************************

SAVEMFP	MOVE.B	IERA+0.w,MFPMEM(a6)	PUSH CURRENT MFP DATA
	MOVE.B	IERB+0.w,MFPMEM+1(a6)
	MOVE.B	IMRA+0.w,MFPMEM+2(a6)
	MOVE.B	IMRB+0.w,MFPMEM+3(a6)
	MOVE.B	TADR+0.w,MFPMEM+4(a6)
	MOVE.B	TACR+0.w,MFPMEM+5(a6)
	MOVE.B	VECTOR+0.w,MFPMEM+6(a6)
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
*	R‚glage de la fr‚quence
*****************************************
* Entr‚e : D7= Valeur de TADR
* Pr‚division s‚lectionn‚e : 10

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
	moveq	#10,d1
SetSnd.1	move.w	(a0)+,d0
	movep.w	d0,0(a1)
	dbra	d1,SetSnd.1
	rts

SndITbl	dc.b	0,0,1,0,2,0,3,0
	dc.b	4,0,5,0,7,$F8
	dc.b	8,$D,9,$B,10,$6	Valeurs correspondant … $80 dans la table



****************************************************************************
*		La routine qui joue sous interruptions
****************************************************************************
PS.INull	rte

PS.Inter	movem.l	d0-d1/a0,-(sp)
	move.l	SoundPtr+0.w,a0		Lecture de l'adresse en cours
PS.Patch	cmp.l	#0,a0		V‚rifie si on a fini
	bhi	PS.EXIT		Si oui, on s'en va

	moveq	#0,d0
	MOVE.B	(A0)+,D0		Lit la donn‚e digitalis‚e
	move.l	a0,SoundPtr+0.w

	LSL.W	#3,D0		DOUBLE LONG WORD OFFSET
	lea	PS.Table(PC,D0.W),a0
	move.l	(a0)+,d0
	move.w	(a0)+,d1
	lea	SCREG+0.w,a0
	movep.l	d0,0(a0)
	movep.w	d1,0(a0)

	movem.l	(sp)+,d0-d1/a0
	RTE


PS.Table	dc.w	$80e,$90d,$a0c,0,$80f,$903,$a00,0
	dc.w	$80f,$903,$a00,0,$80f,$903,$a00,0
	dc.w	$80f,$903,$a00,0,$80f,$903,$a00,0
	dc.w	$80f,$903,$a00,0,$80e,$90d,$a0b,0
	dc.w	$80e,$90d,$a0b,0,$80e,$90d,$a0b,0
	dc.w	$80e,$90d,$a0b,0,$80e,$90d,$a0b,0
	dc.w	$80e,$90d,$a0b,0,$80e,$90d,$a0b,0
	dc.w	$80e,$90d,$a0a,0,$80e,$90d,$a0a,0

	dc.w	$80e,$90d,$a0a,0,$80e,$90d,$a0a,0
	dc.w	$80e,$90c,$a0c,0,$80e,$90d,$a00,0
	dc.w	$80d,$90d,$a0d,0,$80d,$90d,$a0d,0
	dc.w	$80d,$90d,$a0d,0,$80d,$90d,$a0d,0
	dc.w	$80d,$90d,$a0d,0,$80d,$90d,$a0d,0
	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0
	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0
	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0

	dc.w	$80e,$90c,$a0b,0,$80e,$90c,$a0b,0
	dc.w	$80e,$90c,$a0a,0,$80e,$90c,$a0a,0
	dc.w	$80e,$90c,$a0a,0,$80e,$90c,$a0a,0
	dc.w	$80d,$90d,$a0c,0,$80d,$90d,$a0c,0
	dc.w	$80e,$90c,$a09,0,$80e,$90c,$a09,0
	dc.w	$80e,$90c,$a05,0,$80e,$90c,$a00,0
	dc.w	$80e,$90c,$a00,0,$80e,$90b,$a0b,0
	dc.w	$80e,$90b,$a0b,0,$80e,$90b,$a0b,0

	dc.w	$80e,$90b,$a0b,0,$80e,$90b,$a0a,0
	dc.w	$80e,$90b,$a0a,0,$80e,$90b,$a0a,0
	dc.w	$80d,$90d,$a0b,0,$80d,$90d,$a0b,0
	dc.w	$80d,$90d,$a0b,0,$80e,$90b,$a09,0
	dc.w	$80e,$90b,$a09,0,$80e,$90b,$a09,0
	dc.w	$80d,$90c,$a0c,0,$80d,$90d,$a0a,0
	dc.w	$80e,$90b,$a07,0,$80e,$90b,$a00,0
	dc.w	$80e,$90b,$a00,0,$80d,$90d,$a09,0

	dc.w	$80d,$90d,$a09,0,$80e,$90a,$a09,0
	dc.w	$80d,$90d,$a08,0,$80d,$90d,$a07,0
	dc.w	$80d,$90d,$a04,0,$80d,$90d,$a00,0
	dc.w	$80e,$90a,$a04,0,$80e,$909,$a09,0
	dc.w	$80e,$909,$a09,0,$80d,$90c,$a0b,0
	dc.w	$80e,$909,$a08,0,$80e,$909,$a08,0
	dc.w	$80e,$909,$a07,0,$80e,$908,$a08,0
	dc.w	$80e,$909,$a01,0,$80c,$90c,$a0c,0

	dc.w	$80d,$90c,$a0a,0,$80e,$908,$a06,0
	dc.w	$80e,$907,$a07,0,$80e,$908,$a00,0
	dc.w	$80e,$907,$a05,0,$80e,$906,$a06,0
	dc.w	$80d,$90c,$a09,0,$80e,$905,$a05,0
	dc.w	$80e,$904,$a04,0,$80d,$90c,$a08,0
	dc.w	$80d,$90b,$a0b,0,$80e,$900,$a00,0
	dc.w	$80d,$90c,$a06,0,$80d,$90c,$a05,0
	dc.w	$80d,$90c,$a02,0,$80c,$90c,$a0b,0

	dc.w	$80c,$90c,$a0b,0,$80d,$90b,$a0a,0
	dc.w	$80d,$90b,$a0a,0,$80d,$90b,$a0a,0
	dc.w	$80d,$90b,$a0a,0,$80c,$90c,$a0a,0
	dc.w	$80c,$90c,$a0a,0,$80c,$90c,$a0a,0
	dc.w	$80d,$90b,$a09,0,$80d,$90b,$a09,0
	dc.w	$80d,$90a,$a0a,0,$80d,$90a,$a0a,0
	dc.w	$80d,$90a,$a0a,0,$80c,$90c,$a09,0
	dc.w	$80c,$90c,$a09,0,$80c,$90c,$a09,0

	dc.w	$80d,$90b,$a06,0,$80c,$90b,$a0b,0
	dc.w	$80c,$90c,$a08,0,$80d,$90b,$a00,0
	dc.w	$80d,$90b,$a00,0,$80c,$90c,$a07,0
	dc.w	$80c,$90c,$a06,0,$80c,$90c,$a05,0
	dc.w	$80c,$90c,$a03,0,$80c,$90c,$a01,0
	dc.w	$80c,$90b,$a0a,0,$80d,$90a,$a05,0
	dc.w	$80d,$90a,$a04,0,$80d,$90a,$a02,0
	dc.w	$80d,$909,$a08,0,$80d,$909,$a08,0

	dc.w	$80c,$90b,$a09,0,$80c,$90b,$a09,0
	dc.w	$80d,$908,$a08,0,$80b,$90b,$a0b,0
	dc.w	$80d,$909,$a05,0,$80c,$90b,$a08,0
	dc.w	$80d,$909,$a02,0,$80d,$908,$a06,0
	dc.w	$80c,$90b,$a07,0,$80d,$907,$a07,0
	dc.w	$80c,$90b,$a06,0,$80c,$90a,$a09,0
	dc.w	$80b,$90b,$a0a,0,$80c,$90b,$a02,0
	dc.w	$80c,$90b,$a00,0,$80c,$90a,$a08,0

	dc.w	$80d,$906,$a04,0,$80d,$905,$a05,0
	dc.w	$80d,$905,$a04,0,$80c,$909,$a09,0
	dc.w	$80d,$904,$a03,0,$80b,$90b,$a09,0
	dc.w	$80c,$90a,$a05,0,$80b,$90a,$a0a,0
	dc.w	$80c,$909,$a08,0,$80b,$90b,$a08,0
	dc.w	$80c,$90a,$a00,0,$80c,$90a,$a00,0
	dc.w	$80c,$909,$a07,0,$80b,$90b,$a07,0
	dc.w	$80c,$909,$a06,0,$80b,$90b,$a06,0

	dc.w	$80b,$90a,$a09,0,$80b,$90b,$a05,0
	dc.w	$80a,$90a,$a0a,0,$80b,$90b,$a02,0
	dc.w	$80b,$90a,$a08,0,$80c,$907,$a07,0
	dc.w	$80c,$908,$a04,0,$80c,$907,$a06,0
	dc.w	$80b,$909,$a09,0,$80c,$906,$a06,0
	dc.w	$80a,$90a,$a09,0,$80c,$907,$a03,0
	dc.w	$80b,$90a,$a05,0,$80b,$909,$a08,0
	dc.w	$80b,$90a,$a03,0,$80a,$90a,$a08,0

	dc.w	$80b,$90a,$a00,0,$80b,$909,$a07,0
	dc.w	$80b,$908,$a08,0,$80a,$90a,$a07,0
	dc.w	$80a,$909,$a09,0,$80c,$901,$a01,0
	dc.w	$80a,$90a,$a06,0,$80b,$908,$a07,0
	dc.w	$80a,$90a,$a05,0,$80a,$909,$a08,0
	dc.w	$80a,$90a,$a02,0,$80a,$90a,$a01,0
	dc.w	$80a,$90a,$a00,0,$809,$909,$a09,0
	dc.w	$80a,$908,$a08,0,$80b,$908,$a01,0

	dc.w	$80a,$909,$a06,0,$80b,$907,$a04,0
	dc.w	$80a,$909,$a05,0,$809,$909,$a08,0
	dc.w	$80a,$909,$a03,0,$80a,$908,$a06,0
	dc.w	$80a,$909,$a00,0,$809,$909,$a07,0
	dc.w	$809,$908,$a08,0,$80a,$908,$a04,0
	dc.w	$809,$909,$a06,0,$80a,$908,$a01,0
	dc.w	$809,$909,$a05,0,$809,$908,$a07,0
	dc.w	$808,$908,$a08,0,$809,$909,$a02,0

	dc.w	$809,$908,$a06,0,$809,$909,$a00,0
	dc.w	$809,$907,$a07,0,$808,$908,$a07,0
	dc.w	$809,$907,$a06,0,$809,$908,$a02,0
	dc.w	$808,$908,$a06,0,$809,$906,$a06,0
	dc.w	$808,$907,$a07,0,$808,$908,$a04,0
	dc.w	$808,$907,$a06,0,$808,$908,$a02,0
	dc.w	$807,$907,$a07,0,$808,$906,$a06,0
	dc.w	$808,$907,$a04,0,$807,$907,$a06,0

	dc.w	$808,$906,$a05,0,$808,$906,$a04,0
	dc.w	$807,$906,$a06,0,$807,$907,$a04,0
	dc.w	$808,$905,$a04,0,$806,$906,$a06,0
	dc.w	$807,$906,$a04,0,$807,$905,$a05,0
	dc.w	$806,$906,$a05,0,$806,$906,$a04,0
	dc.w	$806,$905,$a05,0,$806,$906,$a02,0
	dc.w	$806,$905,$a04,0,$805,$905,$a05,0
	dc.w	$806,$905,$a02,0,$805,$905,$a04,0

	dc.w	$805,$904,$a04,0,$805,$905,$a02,0
	dc.w	$804,$904,$a04,0,$804,$904,$a03,0
	dc.w	$804,$904,$a02,0,$804,$903,$a03,0
	dc.w	$803,$903,$a03,0,$803,$903,$a02,0
	dc.w	$803,$902,$a02,0,$802,$902,$a02,0
	dc.w	$802,$902,$a01,0,$801,$901,$a01,0
	dc.w	$802,$901,$a00,0,$801,$901,$a00,0
	dc.w	$801,$900,$a00,0,$800,$900,$a00,0


	EVEN
****************************************************************************
*		Programme	de remplissage de polygones
*			Fourni par INFOGRAMES
****************************************************************************

FP.Buf1	ds.w	200
FP.Buf2	ds.w	200
FP.Buf3	ds.w	200

	SECTION	TEXT
FP.InputClip
	move.l	(a0)+,d1
	swap	d1	;	patchable	en nop
	cmp	a2,d1
	sge	d4	;	patchable	en sle
	rts

FP.OutputClip
	swap	d0	;	patchable	en nop
	move.l	d0,(a1)+
	swap	d0	;	patchable	en nop
	addq	#1,a3	;	nbout ++
	rts

FP.Clip1Frontiere
	move	#1,FP.Tri(a4)	;=> il faudra retrier apres le clip
	move.l	a5,a0
	move.l	a6,a1
	move	#-1,a3
	bsr.s	FP.InputClip
	move.l	d1,d0
	move	d4,d2
FP.clip	moveq	#0,d4
	bsr.s	FP.InputClip
	tst.b	d2
	beq.s	FP.no1
	bsr.s	FP.OutputClip
FP.no1	eor.b	d4,d2
	beq.s	FP.noi
	movem.l	d1-d5,-(a7)
	cmp	d1,d0
	bge.s	FP.ok3d
	exg.l	d0,d1	; d0 <-> d1 sinon mauvais cube clipping en 3d
FP.ok3d	move	d1,d3
	swap	d1
	move	d1,d2
	move	d0,d1
	swap	d0
	sub	d0,d2
	sub	d1,d3
	move	a2,d5
	sub	d1,d5
	muls	d2,d5
	divs	d3,d5
	add	d5,d0
	swap	d0
	move	a2,d0
	bsr.s	FP.OutputClip
	movem.l (a7)+,d1-d5
FP.noi	move	d4,d2
	move.l	d1,d0
	dbf	d3,FP.clip
	move.l	(a6),(a1)	; fermeture transitive
	exg	a5,a6
	move	a3,d3
	bpl.s	FP.plusdun
	adda	#4+2,a7	; depile l'adresse de retour
	bra	FP.endpol
FP.plusdun rts

;=========================================================================;

FillPoly:
;==========
	move.l	a6,-(sp)
	move.l	a6,a4		Echange des pointeurs de variables (protocole de l'Aztec C : variables sur A4)
	and.w	#15,Couleur(a6)
	bsr.s	FP.Entry
	move.l	(sp)+,a6
	rts

FP.Entry	movem.l d4-d7/a2-a5,-(a7)
	subq	#1,d3
	move	d3,a3
	lea	FP.Buf1(pc),a5	; Buf 1
	lea	FP.Buf2(pc),a6	; Buf 2
	move.l	a5,a1
	clr	FP.Tri(a4)	; flag pour tri again apres clip ?
****	Tri A
	move	#32000,d4	; Xmin
	move	d4,d5	; Ymin
	move	#-32000,d6	; Xmax
	move	d6,d7	; Ymax

FP.ttria	move	(a0)+,d0	; X
	add	d1,d0
	cmp	d4,d0
	bge.s	FP.tt1a
	move	d0,d4	; Xmin = X
FP.tt1a	cmp	d6,d0
	ble.s	FP.tt2a
	move	d0,d6	; Xmax = X
FP.tt2a	move	d0,(a1)+
	move	(a0)+,d0	; Y
	add	d2,d0
	cmp	d5,d0
	bge.s	FP.tt3a
	move	d0,d5	; Ymin = Y
FP.tt3a	cmp	d7,d0
	ble.s	FP.tt4a
	move	d0,d7	; Ymax = Y
FP.tt4a	move	d0,(a1)+
	dbf	d3,FP.ttria
	move.l	(a5),(a1)	; fermeture transitive


****	Clipping
	move	a3,d3	; nb pt
	move	d4,-(a7)
	move	ClipG(a4),a2
	cmp	a2,d4	; Xmin >= ClipG
	bge.s	FP.cl1
	lea	FP.InputClip(pc),a0
	move	#$4841,2(a0)
	move	#$5CC4,6(a0)
	move	#$4840,10(a0)
	move	#$4840,14(a0)
	bsr	FP.Clip1Frontiere
FP.cl1	move	ClipD(a4),a2
	cmp	a2,d6
	ble.s	FP.cl2
	lea	FP.InputClip(pc),a0
	move	#$4841,2(a0)
	move	#$5FC4,6(a0)
	move	#$4840,10(a0)
	move	#$4840,14(a0)
	bsr	FP.Clip1Frontiere
FP.cl2	move	ClipH(a4),a2
	cmp	a2,d5
	bge.s	FP.cl3
	lea	FP.InputClip(pc),a0
	move	#$4E71,2(a0)
	move	#$5CC4,6(a0)
	move	#$4E71,10(a0)
	move	#$4E71,14(a0)
	bsr	FP.Clip1Frontiere
FP.cl3	move	ClipB(a4),a2
	cmp	a2,d7
	ble.s	FP.cl4
	lea	FP.InputClip(pc),a0
	move	#$4E71,2(a0)
	move	#$5FC4,6(a0)
	move	#$4E71,10(a0)
	move	#$4E71,14(a0)
	bsr	FP.Clip1Frontiere
FP.cl4	move	(a7)+,d4
*** Tri des faces
	tst	FP.Tri(a4)
	beq.s	FP.LATERAL	; si aucun clipping pas de new tri

	move.l	a5,a0	; src
	move	#32000,d4	; Xmin
	move	d4,d5	; Ymin
	move	#-32000,d6	; Xmax
	move	d6,d7	; Ymax
FP.tri1	move.l	(a0)+,d0	; Y
	cmp	d5,d0
	bge.s	FP.t3
	move	d0,d5	; Ymin = Y
FP.t3	cmp	d7,d0
	ble.s	FP.t4
	move	d0,d7	; Ymax = Y
FP.t4	dbf	d3,FP.tri1
FP.LATERAL
*******
	move	d5,d2	; d2 = Ymin
	move	d7,d3	; d3 = Ymax
	move.l	a3,d7
	move.l	a5,a0
	move.l	a6,a5
	lea	FP.Buf3(pc),a6
	lea	FP.patch2(pc),a2
FP.lat	move.l	(a0)+,d0	; X1 Y1
	move.l	(a0),d1	; X2 Y2
	move	d0,d4
	move	(a0),d6
	cmp	-4(a0),d6
	bge.s	FP.okx1x2
	exg	d0,d1				; pour cube clipping
FP.okx1x2	move	d0,d6	; sauvegarde Y1
	sub	d1,d0	; Y1-Y2
	beq.s	FP.lati	; Horizontal => poubelle
	cmp	d4,d3	; Y1 = Ymax ?
	beq.s	FP.extr
	cmp	d4,d2	; Y1 = Ymin ?
	bne.s	FP.l000
FP.extr	exg	a5,a6
FP.l000	add	d6,d6	; sizeof(WORD)
	lea	0(a5,d6),a1
	swap	d0
	move	d0,(a1)				; X1 -> Tab
	swap	d0
	move	#$3304,(a2)	; move	d4,-(a1)
FP.dy	tst	d0		; Y1-Y2
	bge.s	FP.l0
	neg	d0		; Abs(Y1-Y2)
	move	#$32C4,(a2)	; move	d4,(a1)+
	lea	2(a1),a1
FP.l0	move	d0,a3	; deltay
	swap	d0		; X1<->Y1
	move	d0,d4	; X=X1
	swap	d1		; X2<->Y2
	sub	d0,d1	; X2-X1
FP.l00	move	a3,d5	; cumul = deltay / 2
	lsr	#1,d5
	move	a3,d6	; deltay cpt
	subq	#1,d6

FP.l1	add	d1,d5	; cumul += deltax
FP.l2	cmp	a3,d5	; cumul >= deltay
	blt.s	FP.patch2
	sub	a3,d5	; cumul -= deltay
	addq	#1,d4
	bra.s	FP.l2
FP.patch2	move	d4,(a1)+	; => X
	dbf	d6,FP.l1

FP.lati	dbf	d7,FP.lat

**** Remplissage proprement dit
* d0 - Xg0 Xd0	a0 - ecran
* d1 - Xd1	a1 - TabDroite
* d2 - Xg1	a2 - TabGauche
* d3 - cptr ligne	a3 - ecran save
* d4 - val 0	a4 - scratch
* d5 - val 1	a5 - Buf gauche
* d6 - $fff0fff0	a6 - Buf droite
* d7 - scratch	a7 - pile

FP.AdrLog:
	move.l	LogScreen(a4),a3

	sub	d2,d3	; Ymax - Ymin
FP.x	beq	FP.endpol

	move	d2,d7	; Ymin
	add	d7,d7	; x 2
	add	d7,d7	; x 4
	add	d2,d7	; x 5
	lsl	#5,d7	; x 160
;	mulu	#160,d7

	add	d7,a3	; ecran
	add	d2,d2	; sizeof(WORD)
	add	d2,a5
	add	d2,a6

	move.l	a5,a1
	move.l	a6,a2
	move	d3,d7	; nb pt
FP.ech	cmp	(a1)+,(a2)+
	beq.s	FP.ex1
	bge.s	FP.ex2
	exg	a5,a6
	bra.s	FP.ex2
FP.ex1	dbf	d7,FP.ech
FP.ex2
	moveq	#-1,d0
	move.l	#$fff0fff0,d6

	lea	FP.MaskD(pc),a1
	lea	FP.MaskG(pc),a2

;	move	#16*12,d7	; offset sizeof(T_MASK)
;	mulu	colorpoly,d7	; couleur

	clr.w	ObjetVu(a4)
	tst.w	FastFill(a4)
	bne	FFP.FilC
	tst.w	Resol(a4)
	bne	FP.FilNB

	move	Couleur(a4),d7	; couleur
	lsl	#6,d7	; x 64
	move	d7,d4	;
	add	d7,d7	; x 128
	add	d4,d7	; x 16*12

	add	d7,a1
	add	d7,a2
	move.l	4(a2),d4	; plan 01
	move.l	8(a2),d5	; plan 23


FP.fil	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne	FP.ajust
FP.pasajust:
*	a3 = pointe sur debut ligne F(y)
*	a0 = pointe sur ecran F(x, y)

	move.l	a0,-(sp)

	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

* ------------------------------------------------------------------------- *
* Incrustation Bitmap Atari		*
* ------------------------------------------------------------------------- *
* ecran = (ecran & !mask) + (col & mask)		*
*			*
* informations neccessaires et suffisantes:		*
*	ecran			*
*	!mask			*
*	col & mask			*
* ------------------------------------------------------------------------- *
* Organisation table:		*
*	LONG	!mask			*
*	LONG	mask & col PLAN 01		*
*	LONG	mask & col PLAN 23		*
* ------------------------------------------------------------------------- *
* Entree:			*
*	d1: XD			*
*	d2: XG			*
*	a0: adresse ecran		*
*	a1: adresse table couleur droite		*
*	a2: adresse table couleur gauche		*
* ------------------------------------------------------------------------- *

FP.AdrGauche
	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l (a4)+,d2	; 12 ; d0 = !mask
	and.l	d2,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 01
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
	and.l	d2,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 23
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
*		= 156

FP.AdrMilieu:
	bra.s	FP.AdrMilieu

	dc.w	$4A	; Fuky BRA par d‚faut ne trace rien

	move.l d4,(a0)+	;	; 1
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 2
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 3
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 4
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 5
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 6
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 7
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 8
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 9
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 10
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 11
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 12
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 13
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 14
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 15
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 16
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 17
	move.l d5,(a0)+
	move.l d4,(a0)+	;	; 18
	move.l d5,(a0)+

FP.AdrDroite:
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l (a4)+,d1	; 12 ; d0 = !mask
	and.l	d1,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 01
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
	and.l	d1,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 23
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
*		= 156
FP.Fin:
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FP.fil

FP.endpol movem.l (a7)+,d4-d7/a2-a5
	rts


* -------------------------------------------------------------------------
* E:	d2: XGn	XDn
*	d0: travail
*	d7: travail
* -------------------------------------------------------------------------

FP.ajust:
	move	d2,d0
	swap	d2
	move	d2,d7
	swap	d2

	cmp.w	d7,d0	Teste si crois‚
	blt.s	FP.XOrder
	
FP.XOrdOK	and.w	d6,d7
	and.w	d6,d0
	sub	d7,d0	; d0 = XDn - XGn
	bne.s	FP.nosame

	lsr	#1,d7
	lea	0(a3,d7.w),a0
	bra	FP.pasajust2

FP.nosame lsr	#1,d7
	lea	0(a3,d7.w),a0	; a0 = adresse ecran a gauche

	lea	FP.AdrMilieu+1(pc),a4
	move.b	FP.Saut+3(PC,d0.w),(a4)
	bra	FP.pasajust

FP.XOrder	swap	d2
	exg.l	d0,d7
	bra.s	FP.XOrdOK

FP.Saut:
	dc.l	0,0,0,0,74,74,74,74,70,70,70,70,66,66,66,66,62,62,62,62,58,58,58,58,54,54,54,54,50,50,50,50
	dc.l	46,46,46,46,42,42,42,42,38,38,38,38,34,34,34,34,30,30,30,30,26,26,26,26,22,22,22,22,18,18,18,18
	dc.l	14,14,14,14,10,10,10,10,6,6,6,6,2,2,2,2

FP.fil2	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne	FP.ajust
FP.pasajust2:
	move.l	a0,-(sp)
	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l (a4)+,d2	; 12 ; d0 = !mask
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	or.l	(a4)+,d2	; 12 ; d2 = !mask
	move.l d2,d1	;	4 ;
	not.l	d1	;	6 ; d1 = mask
	and.l	d2,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 01
	and.l	d1,d7	;	6 ;
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
	and.l	d2,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 23
	and.l	d1,d7	;	6 ;
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
*		= 240
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FP.fil2

	movem.l (a7)+,d4-d7/a2-a5
	rts




**************************************************************************
*		Reprise de la routine dans le cas N&B
**************************************************************************
* Diff‚rence : On remplit deux lignes … la fois avec un remplissage tram‚


FP.FilNB	lea	FPNB.MaskD(pc),a1
	lea	FPNB.MaskG(pc),a2
	move	Couleur(a4),d7	; couleur
	lsl	#6,d7	; x 64
	move	d7,d4	;
	add	d7,d7	; x 128
	add	d4,d7	; x 16*12

	add	d7,a1
	add	d7,a2
	move.l	4(a2),d4	; plan 01
	move.l	8(a2),d5	; plan 23


FPNB.fil	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne	FPNB.ajust
FPNB.pasajust:
*	a3 = pointe sur debut ligne F(y)
*	a0 = pointe sur ecran F(x, y)

	move.l	a0,-(sp)

	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

* ------------------------------------------------------------------------- *
* Incrustation Bitmap Atari		*
* ------------------------------------------------------------------------- *
* ecran = (ecran & !mask) + (col & mask)		*
*			*
* informations neccessaires et suffisantes:		*
*	ecran			*
*	!mask			*
*	col & mask			*
* ------------------------------------------------------------------------- *
* Organisation table:		*
*	LONG	!mask			*
*	LONG	mask & col PLAN 01		*
*	LONG	mask & col PLAN 23		*
* ------------------------------------------------------------------------- *
* Entree:			*
*	d1: XD			*
*	d2: XG			*
*	a0: adresse ecran		*
*	a1: adresse table couleur droite		*
*	a2: adresse table couleur gauche		*
* ------------------------------------------------------------------------- *

FPNB.AdrGauche
	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l (a4)+,d2	; 12 ; d0 = !mask
	and.l	d2,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 01
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
* DeuxiŠme ligne N&B
	and.l	d2,76(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 23
	or.l	d7,76(a0)	; 20 ; ecran = ecran + (col & mask)
*		= 156

	lea	80(a0),a4		a4= 2e ligne
FPNB.AdrMilieu:
	bra.s	FPNB.AdrMilieu

	dc.w	$4A	; Fuky BRA	(vers Rien)

	move.l d4,(a0)+	;	; 1
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 2
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 3
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 4
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 5
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 6
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 7
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 8
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 9
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 10
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 11
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 12
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 13
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 14
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 15
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 16
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 17
	move.l d5,(a4)+
	move.l d4,(a0)+	;	; 18
	move.l d5,(a4)+

FPNB.AdrDroite:
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l (a4)+,d1	; 12 ; d0 = !mask
	and.l	d1,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 01
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
	and.l	d1,76(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 23
	or.l	d7,76(a0)	; 20 ; ecran = ecran + (col & mask)
*		= 156
FPNB.Fin:
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FPNB.fil

FPNB.endpol movem.l (a7)+,d4-d7/a2-a5
	rts


* -------------------------------------------------------------------------
* E:	d2: XGn	XDn
*	d0: travail
*	d7: travail
* -------------------------------------------------------------------------

FPNB.ajust:
	move	d2,d0
	swap	d2
	move	d2,d7
	swap	d2

	cmp.w	d7,d0
	bge.s	FPNB.Order
	exg	d0,d7
	swap	d2

FPNB.Order:
	lsr	#4,d7
	lsr	#4,d0

	sub	d7,d0	; d0 = XDn - XGn
	bne.s	FPNB.nosame
*	lsl	#3,d7 : pour 8 mots par 16 points
	add	d7,d7	Ici on n'a que deux mot
	add	d7,d7
	lea	0(a3,d7.w),a0
	bra.s	FPNB.pasajust2

FPNB.nosame add.w	d7,d7		(lsl	#3,d7 pour la couleur)
	add	d7,d7
	lea	0(a3,d7.w),a0	; a0 = adresse ecran a gauche

	lea	FPNB.AdrMilieu+1(pc),a4
	move.b	FPNB.Saut(PC,d0.w),(a4)
	bra	FPNB.pasajust

FPNB.Saut:
	dc.b	0,74,70,66,62,58,54,50
	dc.b	46,42,38,34,30,26,22,18
	dc.b	14,10,6,2

FPNB.fil2	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne.s	FPNB.ajust
FPNB.pasajust2:
	move.l	a0,-(sp)
	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l (a4)+,d2	; 12 ; d0 = !mask
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	or.l	(a4)+,d2	; 12 ; d2 = !mask
	move.l d2,d1	;	4 ;
	not.l	d1	;	6 ; d1 = mask
	and.l	d2,(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 01
	and.l	d1,d7	;	6 ;
	or.l	d7,(a0)+	; 20 ; ecran = ecran + (col & mask)
	and.l	d2,76(a0)	; 20 ; ecran = ecran & !mask
	move.l (a4)+,d7	; 12 ; d1 = (col & mask) Plan 23
	and.l	d1,d7	;	6 ;
	or.l	d7,76(a0)	; 20 ; ecran = ecran + (col & mask)
*		= 240
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FPNB.fil2

	movem.l (a7)+,d4-d7/a2-a5
	rts



*******************************************************************************
*		Cas particulier du remplissage monoplan
*******************************************************************************



FFP.FilNB	lea	FPNB.MaskD(pc),a1
	lea	FPNB.MaskG(pc),a2
	move	Couleur(a4),d7	; couleur
	lsl	#6,d7	; x 64
	move	d7,d4	;
	add	d7,d7	; x 128
	add	d4,d7	; x 16*12

	add	d7,a1
	add	d7,a2
	move.l	4(a2),d4	; plan 01
	move.l	8(a2),d5	; plan 23
	or.l	#$99999999,d4

FFPNB.fil	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne	FFPNB.ajust
FFPNB.pasajust:
*	a3 = pointe sur debut ligne F(y)
*	a0 = pointe sur ecran F(x, y)

	move.l	a0,-(sp)

	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

* ------------------------------------------------------------------------- *
* Incrustation Bitmap Atari		*
* ------------------------------------------------------------------------- *
* ecran = (ecran & !mask) + (col & mask)		*
*			*
* informations neccessaires et suffisantes:		*
*	ecran			*
*	!mask			*
*	col & mask			*
* ------------------------------------------------------------------------- *
* Organisation table:		*
*	LONG	!mask			*
*	LONG	mask & col PLAN 01		*
*	LONG	mask & col PLAN 23		*
* ------------------------------------------------------------------------- *
* Entree:			*
*	d1: XD			*
*	d2: XG			*
*	a0: adresse ecran		*
*	a1: adresse table couleur droite		*
*	a2: adresse table couleur gauche		*
* ------------------------------------------------------------------------- *

FFPNB.AdrGauche
	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l	(a4),d2
	or.l	d4,d2	
	move.l	d2,(a0)+	; 12 ; d1 = (col & mask) Plan 01

FFPNB.AdrMilieu:
	bra.s	FFPNB.AdrMilieu

	dc.w	$4A	; Fuky BRA	(vers Rien)

	move.l d4,(a0)+	;	; 1
	move.l d4,(a0)+	;	; 2
	move.l d4,(a0)+	;	; 3
	move.l d4,(a0)+	;	; 4
	move.l d4,(a0)+	;	; 5
	move.l d4,(a0)+	;	; 6
	move.l d4,(a0)+	;	; 7
	move.l d4,(a0)+	;	; 8
	move.l d4,(a0)+	;	; 9
	move.l d4,(a0)+	;	; 10
	move.l d4,(a0)+	;	; 11
	move.l d4,(a0)+	;	; 12
	move.l d4,(a0)+	;	; 13
	move.l d4,(a0)+	;	; 14
	move.l d4,(a0)+	;	; 15
	move.l d4,(a0)+	;	; 16
	move.l d4,(a0)+	;	; 17
	move.l d4,(a0)+	;	; 18

FFPNB.AdrDroite:
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l 	(a4),d1
	or.l	d4,d1
	move.l	d1,(a0)+	; 12 ; d1 = (col & mask) Plan 01
FFPNB.Fin:
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FFPNB.fil

FFPNB.endpol movem.l (a7)+,d4-d7/a2-a5
	rts


* -------------------------------------------------------------------------
* E:	d2: XGn	XDn
*	d0: travail
*	d7: travail
* -------------------------------------------------------------------------

FFPNB.ajust:
	move	d2,d0
	lsr	#4,d0
	swap	d2
	move	d2,d7
	lsr	#4,d7
	swap	d2

	sub	d7,d0	; d0 = XDn - XGn
	bne.s	FFPNB.nosame
*	lsl	#3,d7 : pour 8 mots par 16 points
	add	d7,d7	Ici on n'a que deux mot
	add	d7,d7
	lea	0(a3,d7.w),a0
	bra.s	FFPNB.pasajust2

FFPNB.nosame add.w	d7,d7		(lsl	#3,d7 pour la couleur)
	add	d7,d7
	lea	0(a3,d7.w),a0	; a0 = adresse ecran a gauche

	lea	FFPNB.AdrMilieu+1(pc),a4
	move.b	FFPNB.Saut(PC,d0.w),(a4)
	bra	FFPNB.pasajust

	dc.b	0,0,0,0,0,0,0,0
FFPNB.Saut:
	dc.b	0,38,36,34,32,30,28,26
	dc.b	24,22,20,18,16,14,12,10
	dc.b	8,6,4,2
	dc.b	0,0,0,0,0,0,0,0

FFPNB.fil2	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne.s	FFPNB.ajust
FFPNB.pasajust2:
	move.l	a0,-(sp)
	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l	(a4)+,d2	; 12 ; d0 = !mask
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	or.l	(a4)+,d2	; 12 ; d2 = !mask
	or.l	#$99999999,d2	; Ajustement fond
	and.l	d2,(a0)	; 20 ; ecran = ecran & !mask

	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FFPNB.fil2

	movem.l (a7)+,d4-d7/a2-a5
	rts


*******************************************************************************
*		Remplissage monoplan couleurs
*******************************************************************************


FFP.FilC	tst.w	Resol(a4)
	bne	FFP.FilNB
	lea	FP.MaskD(pc),a1
	lea	FP.MaskG(pc),a2
	move	Couleur(a4),d7	; couleur
	lsl	#6,d7	; x 64
	move	d7,d4	;
	add	d7,d7	; x 128
	add	d4,d7	; x 16*12

	add	d7,a1
	add	d7,a2
	move.l	4(a2),d4	; plan 01
	move.l	8(a2),d5	; plan 23


FFP.fil	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne	FFP.ajust
FFP.pasajust:
*	a3 = pointe sur debut ligne F(y)
*	a0 = pointe sur ecran F(x, y)

	move.l	a0,-(sp)

	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

* ------------------------------------------------------------------------- *
* Incrustation Bitmap Atari		*
* ------------------------------------------------------------------------- *
* ecran = (ecran & !mask) + (col & mask)		*
*			*
* informations neccessaires et suffisantes:		*
*	ecran			*
*	!mask			*
*	col & mask			*
* ------------------------------------------------------------------------- *
* Organisation table:		*
*	LONG	!mask			*
*	LONG	mask & col PLAN 01		*
*	LONG	mask & col PLAN 23		*
* ------------------------------------------------------------------------- *
* Entree:			*
*	d1: XD			*
*	d2: XG			*
*	a0: adresse ecran		*
*	a1: adresse table couleur droite		*
*	a2: adresse table couleur gauche		*
* ------------------------------------------------------------------------- *

FFP.AdrGauche
	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	addq.l	#6,a0
	move.w	(a4),(a0)+	; 12 ; d1 = (col & mask) Plan 01

FFP.AdrMilieu:
	bra.s	FFP.AdrMilieu

	dc.w	$4A	; Fuky BRA	(vers Rien)

	addq.l	#6,a0
	move.w d4,(a0)+	;	; 1
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 2
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 3
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 4
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 5
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 6
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 7
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 8
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 9
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 10
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 11
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 12
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 13
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 14
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 15
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 16
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 17
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 18

FFP.AdrDroite:
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	addq.l	#6,a0
	move.w	(a4),(a0)+	; 12 ; d1 = (col & mask) Plan 01

FFP.Fin:
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FFP.fil

FFP.endpol movem.l (a7)+,d4-d7/a2-a5
	rts


* -------------------------------------------------------------------------
* E:	d2: XGn	XDn
*	d0: travail
*	d7: travail
* -------------------------------------------------------------------------

FFP.ajust:
	move	d2,d0
	lsr	#4,d0
	swap	d2
	move	d2,d7
	lsr	#4,d7
	swap	d2

	sub	d7,d0	; d0 = XDn - XGn
	bne.s	FFP.nosame
	lsl	#3,d7 : pour 8 mots par 16 points
	lea	0(a3,d7.w),a0
	bra.s	FFP.pasajust2

FFP.nosame
	lsl	#3,d7
	lea	0(a3,d7.w),a0	; a0 = adresse ecran a gauche

	lea	FFP.AdrMilieu+1(pc),a4
	move.b	FFP.Saut(PC,d0.w),(a4)
	bra	FFP.pasajust

	dc.b	0,0,0,0,0,0,0,0
FFP.Saut:
	dc.b	0,74,70,66,62,58,54,50
	dc.b	46,42,38,34,30,26,22,18
	dc.b	14,10,6,2
	dc.b	0,0,0,0,0,0,0,0

FFP.fil2	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne.s	FFP.ajust
FFP.pasajust2:
	move.l	a0,-(sp)
	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

	and	#$F,d2	;	8 ; calcul masque gauche
	add	d2,d2	;	4 ; 2N
	add	d2,d2	;	4 ; 4N
	move	d2,d7	;	4 ; sauve 4N
	add	d7,d2	;	4 ; 8N
	add	d7,d2	;	4 ; 12N
	lea	0(a2,d2),a4	; 12 ; pointe sur definition !mask, (col & mask)
	move.l (a4)+,d2	; 12 ; d0 = !mask
	and	#$F,d1	;	8 ; calcul masque gauche
	add	d1,d1	;	4 ; 2N
	add	d1,d1	;	4 ; 4N
	move	d1,d7	;	4 ; sauve 4N
	add	d7,d1	;	4 ; 8N
	add	d7,d1	;	4 ; 12N
	lea	0(a1,d1),a4	; 12 ; pointe sur definition !mask, (col & mask)
	or.l	(a4)+,d2	; 12 ; d2 = !mask
	move.w	d2,6(a0)	; 20 ; ecran = ecran & !mask

	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FFP.fil2

	movem.l (a7)+,d4-d7/a2-a5
	rts



	SECTION	DATA

FP.MaskG:
	INCBIN	\ASSEMBLR\PROJET.CUB\MASKDC.INC
FP.MaskD:
	INCBIN	\ASSEMBLR\PROJET.CUB\MASKGC.INC
FPNB.MaskG:
	INCBIN	\ASSEMBLR\PROJET.CUB\MASKDNB.INC
FPNB.MaskD:
	INCBIN	\ASSEMBLR\PROJET.CUB\MASKGNB.INC
***************************************************************************
*		Zone de stockage de donn‚es
***************************************************************************

	SECTION	DATA
SinTab	INCBIN	\ASSEMBLR\PROJET.CUB\SINTAB.INC	Lecture de la table de sinus


****************************************************************************
*		Table de description des tableaux
* Format :
*  W: Taille totale du tableau (passage au tableau suivant)
*  W: Acc‚l‚ration verticale
*  W: Nombre d'objets dans la salle
****************************************************************************


****************************************************************************
*			 Table des objets
* 	L: Offset / Objtab de la description de forme
* 	L: Offset / ObjPrgs du programme d'affichage
****************************************************************************
* KeyWord	#OTAB
ObjTab	dc.l	Ombre.D-ObjTab,0
	dc.l	Ombre.D-ObjTab,OmbreOther.I-ObjPrgs
	dc.l	Vaiss.D-ObjTab,0
	dc.l	Vaiss.D-ObjTab,VaissOther.I-ObjPrgs

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
	dc.l	Bulle.D-ObjTab,BulleP.I-ObjPrgs	Bulle de l‚geret‚ = $230
	dc.l	Bulle.D-ObjTab,BulleV.I-ObjPrgs
	dc.l	Plaque.D-ObjTab,LabP.I-ObjPrgs	Plaque qui n'est vue que de prŠs
	dc.l	PTeleV.D-ObjTab,PTeleV.I-ObjPrgs	Plaque de t‚l‚portation verticale
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

	dc.l	AutoPlq.D-ObjTab,Auto1.I-ObjPrgs	Plaques … d‚placement auto.
	dc.l	AutoPlq.D-ObjTab,Auto2.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto3.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto4.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto5.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto6.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto7.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto8.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto9.I-ObjPrgs
	dc.l	AutoPlq.D-ObjTab,Auto10.I-ObjPrgs

	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs	4 Dunmmies (extensions)
	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs
	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs
	dc.l	Plaque.D-ObjTab,Plaque.I-ObjPrgs


EndObjTab	dc.w	0

MAXOBJ	equ	(EndObjTab-ObjTab)*2-1

****************************************************************************
*		Descriptions d'objets
* Format d'un objet
*    D‚calage de sommets
*  B: Sommet de r‚f‚rence de sous objet (0 pour indiquer la fin)
*    B...B : 0: fin du sous-objet
*	   (1-127) Liste d'index de sommets indiquant la composition d'une
*	facette du sous objet
*	   (>127) Indique la couleur de la facette pr‚c‚dente
****************************************************************************

* KeyWord #OBJ

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
	dc.b	6,5,10,7,$F8	Cot‚ int‚rieur de la couronne
	dc.b	4,3,8,9,$F8
	dc.b	3,6,7,8,$F9
	dc.b	5,4,9,10,$F9

	dc.b	13,14,15,16,$F9	Cot‚s avant et arriŠre du cube
	dc.b	20,19,18,17,$F9

	dc.b	24,23,28,$E0	Fus‚e du canon
	dc.b	25,24,28,$E1
	dc.b	22,25,28,$E0
	dc.b	23,22,28,$E1

	dc.b	13,18,19,14,$FA	Cot‚ ext‚rieurs du cube int‚rieur
	dc.b	20,17,16,15,$FA
	dc.b	15,14,19,20,$FB
	dc.b	13,16,17,18,$FB

	dc.b	7,10,5,6,$F1	Cot‚ ext‚rieur de la couronne
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
	dc.b	19,22,18,$F8	Inf‚rieur extr‚mit‚ aile g
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
*		Liste des sons ‚chantillon‚s
***************************************************************************


TheSounds	dc.w	2

NoSound	equ	0
	dc.w	8,$8080,$8080,$8080


*********************************************************************************
* Macro chargeant un son dans la m‚moire.
* CtrSons est le compteur de sons.
* Appel par INCSND Label,Fichier
* Associe au label indiqu‚ le son contenu dans \ASSEMBLR\PROJET.CUB\FICHIER.CSP

CtrSnd	set	1
INCSND	MACRO
\1	equ	CtrSnd	Compte le nombre d'appels
CtrSnd	set	CtrSnd+1
DbtSon\@	dc.w	FinSon\@-DbtSon\@
	INCBIN	\\ASSEMBLR\\PROJET.CUB\\\2.CSP
FinSon\@
	ENDM
*********************************************************************************


	INCSND	ChocVaiss.S,CHOCVAIS
	INCSND	ParTerre.S,PARTERRE
	INCSND	SurMurs.S,SURMURS
	INCSND	Plaque.S,PLAQUE
	INCSND	Mort.S,MORT
	INCSND	Chasseur.S,CHASSR
	INCSND	Sortie.S,SORTIE
	INCSND	Trans.S,TRANS
	INCSND	Rotat.S,ROTAT
	INCSND	ARotat.S,AROTAT
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
	INCSND	Missile.S,TRANSPOR
	INCSND	FireP.S,CLIGN
	INCSND	Explor.S,EXPLOR
	INCSND	BigOne.S,BIGONE
	INCSND	StarWar.S,STARWAR
	INCSND	Auto.S,AUTO

	dc.b	'W5PZ7F'	(FRANCE=W5PZ8F ANGLETERRE=W5PZ7F ALLEMAGNE=W5PZ6F)
*********************************************************************************
* Macro chargeant un icone dans la m‚moire.
* CtrIcons est le compteur de sons.
* Appel par ICONE Label,Fichier
* Associe au label indiqu‚ le son contenu dans \ASSEMBLR\PROJET.CUB\FICHIER.ICN

	IFEQ	1

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
*		Zone de r‚servation des variables
***************************************************************************
MoveMemry	INCBIN	\ASSEMBLR\PROJET.CUB\DEMO.INC
FinMvMemry	dc.w	0

	SECTION	BSS
	ds.b	10000
TScreen	ds.b	8000
Screen	ds.b	32256
Screen2	ds.b	32000


***************************************************************************
*		Variables du programme (point‚es par A6)
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
PosX	rs.w	1	Position sur l'‚cran
PosY	rs.w	1
PosZ	rs.w	1
Alpha	rs.w	1	Angle de vis‚e
Beta	rs.w	1
Gamma	rs.w	1
BetaSpeed	rs.w	1	Vitesse de rotation
Contract	rs.w	1	Contraction du pied
KFactor	rs.w	1	Facteurs de grandissement / R‚duction
LFactor	rs.w	1

AltiOmb	rs.w	1	Altitude de l'ombre
NxAOmb	rs.w	1	Altitude au prochain tour
NumOmb	rs.w	1	Num‚ro de l'objet de l'ombre; -1= Ombre d‚ja affich‚e; -2= Vaisseau affich‚
NxNOmb	rs.w	1	Pour le prochain tour

SpeedX	rs.w	1	Vitesse selon les trois axes
SpeedY	rs.w	1
SpeedZ	rs.w	1
SpeedX0	rs.w	1	Vitesse … atteindre
SpeedZ0	rs.w	1
Joueur	rs.w	1	0: Joueur 0/Sprites actifs  1: Joueur 1/Sprites inactifs
Tableau	rs.w	1	Num‚ro du tableau actuel
Options1	rs.b	1
*	0: Inutilis‚
*	1: Deux joueurs
*	3: Vert Split 2 joueurs
Options2	rs.b	1
*	0: Fond de cube creux
*	1: Mode lignes
*	2: Retour au centre automatique horizontal
*	3: Retour au bas automatique
*	4: Utilisation de gamma dans les rotations
*	5: Affichage de la pyramide
*	6: Son/ Pas de son

* Variables d'adresses de zones systeme
TabVisitAd	rs.l	1	Pointeur sur TabVisit
Other	rs.l	1	Adresse de l'autre jeu de variables

AdTScreen	rs.l	1
AdObjTab	rs.l	1
LogScreen	rs.l	1	Adresses d'‚cran
PhyScreen	rs.l	1
DefScreen	rs.l	1
BckScreen	rs.l	1	Ecran de fond
Screen2Ad	rs.l	1	Copie de l'‚cran

TabNames	rs.l	1	Adresse des tableaux et des noms de tableaux
Tableaux	rs.l	1
OldJoyst	rs.l	1	Ancien vecteur de traitement du joystick
OldMsVec	rs.l	1	Ancien vecteur de traitement de la souris
BSSStart	rs.l	1	D‚but de la zone BSS
SpareUSP	rs.l	1	Stockage de USP pour retour au GEM
LineA	rs.l	1	Adresse des variables LineA
TBVEC.Old	rs.l	1	Ancien vecteur du TimerB
Filler	rs.l	1	Indique la routine de remplissage

* Variables communes aux deux joueurs
ExtraTime	rs.w	1
JSuisMort	rs.w	1	>0: Tab suivant  <0: Mort
Sortie	rs.w	1	Sortie utilis‚e
MaxVSpeed	rs.w	1	Vitesse verticale maxi autoris‚e dans le tableau
Gravite	rs.w	1	Acc‚l‚ration verticale
CosA	rs.w	1	M‚morisation des valeurs de SIN, COS de A B C
SinA	rs.w	1
CosB	rs.w	1
SinB	rs.w	1
CosC	rs.w	1
SinC	rs.w	1
ObjX	rs.w	1	Position de l'objet regard‚
ObjY	rs.w	1
ObjZ	rs.w	1
ModObjX	rs.w	1	Position relative du centre de l'objet aprŠs rotation
ModObjY	rs.w	1
ModObjZ	rs.w	1
AlphaL	rs.w	1	Angles de rotations locales
BetaL	rs.w	1
GammaL	rs.w	1
UseLocAng	rs.w	1	Utilisation des angles locaux pr‚c‚dants
Resol	rs.w	1	R‚solution d'‚cran
OldResol	rs.w	1	R‚solution … l'appel du programme
ObjetVu	rs.w	1	Objet affich‚ sur l'‚cran ?
Couleur	rs.w	1	Couleur d'affichage
DefColor	rs.w	1	Couleur d‚termin‚e par le num‚ro d'objet
InputDev	rs.w	1	0 : Joy 1  1: Joy 2   2: Kbd
DoLoad	rs.w	1	-1: Indique qu'il faut faire un LOAD,
*			 1 que la derniŠre partie d‚buta par un LOAD,
*			 0 que la derniere partie ‚tait normale

Seed	rs.w	1	Base du g‚n‚rateur de nombres al‚atoires
ObjNum	rs.w	1	Nombre d'objets dans la base de donn‚es
MissilN	rs.w	1	Nombre de Missiles dans la base en cours
Traject	rs.w	3*16	Points de la trajectoire des monstres
TrajSize	rs.w	1	Nombre de points de cette trajectoire

TimerL	rs.w	1	Timer 32 bits
Timer	rs.w	1
SysTime0	rs.l	1	Timer SystŠme 200Hz au d‚but

WhichBonus	rs.l	1	Liste des Bonus de temps
WhichDiamond	rs.w	1	Liste des diamants
WhichProtect	rs.w	1	Liste des Cubes de protection


FastFill	rs.w	1	Indique un remplissage rapide monoplan
FP.Tri	rs.w	1	Tri dans fichier POLY.S
NumReb	rs.w	1	Num‚ro du rebond
MFPMEM	rs.b	8	Stockage des valeurs normales du MFP
VECTOR.Old	rs.b	1
IMRA.Old	rs.b	1
IERA.Old	rs.b	1
TBDR.Old	rs.b	1
TBCR.Old	rs.b	1
BackColor	rs.w	16	Couleurs de fond d'‚cran, utilis‚e par les interruptions VBL
CurColor	rs.w	16	Couleur effectivement affich‚e

* Variables de la pr‚sentation
TextAd	rs.l	1	Adresse du texte en cours
TextPos	rs.w	1	Position sur l'‚cran
TextWait0	rs.w	1	>0: Attendre pour affichage; <0: Fin du texte atteinte
TextWait	rs.w	1	Le TextWait en cours
TextCol	rs.w	1	Colonne en cours
TextColor	rs.w	1
Main.MID	rs.w	1	Index du menu


* Variables du mode CHEAT
PassWd	rs.b	8	Lettres du mot de passe tap‚
CurObj	rs.w	1	Objet en cours d'‚dition
StepStep	rs.w	1	Indique si on est en mode pas … pas
Inact	rs.w	1	indique que les sprites sont inactifs
MovePtr	rs.l	1	Pointeur sur le compteur de d‚placements
EndMvMem	rs.l	1	Pointeur de fin de m‚morisation
MoveMemAd	rs.l	1	Pointeur sur la zone de demo

CPoint1	rs.w	3		Stockage des points particuliers calcul‚s
CPoint2	rs.w	3
CPoint3	rs.w	3
CPoint4	rs.w	3
CPoint5	rs.w	3
CPoint6	rs.w	3
CPoint7	rs.w	3
CPoint8	rs.w	3
CPoint9	rs.w	3
CPoint10	rs.w	3




* Zones de stockage de donn‚es
Sommets	rs.w	4*128	Maxi 128 sommets
OList	rs.w	16*128	Liste des objets
AO.FerTab	rs.b	128	Fermeture du polygone en ZClipping
PolySomm	rs.w	3*128	128 sommets ‚ventuellement 3D

DataLen	rs.w	1	Longueur totale des variables

********************************************************************
*		Stockage effectif des donn‚es
********************************************************************

TabVisit	ds.b	NTABS		Indique si le tableau a ‚t‚ visit‚
CpyScores	ds.b	16

Vars	ds.b	DataLen		R‚serve l'espace pour les variables
Vars2	ds.b	DataLen		Variables joueur 2

DataSave	ds.b	10240		Reserve l'espace de sauvegarde
DataSaveEnd:
	ds.b	1024		R‚serve l'espace pile
Pile	ds.w	1
