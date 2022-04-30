**************************************************************************
*
*		Routine de remplissage de polygones
*		Version ST: Richard
*
**************************************************************************


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
	movem.l d4-d7/a2-a6,-(a7)
	and.w	#15,Couleur(a4)
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
	lsl	#8,d7	; x 256

	add	d7,a1
	lea	4(a2,d7.w),a4
	add.w	d7,a2

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
	and	#$F,d2	8 ; calcul masque gauche
	lsl.w	#4,d2	14<20 : Position
	movem.l	0(a2,d2),d2/d4/d5	28 ?
	move.l	(a0),d7	12
	and.l	d2,d7	6
	or.l	d4,d7	6
	move.l	d7,(a0)+	12
	move.l	(a0),d7	12
	and.l	d2,d7	6
	or.l	d5,d7	6
	move.l	d7,(a0)+	12

	movem.l	(a4),d4-d5	; 24?
*	=146 ...<156
FP.AdrMilieu:
	bra.s	FP.AdrMilieu

	dc.w	$4A	; Fuky BRA par d‚faut ne Dessine rien

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
	move.l d4,(a0)+	;	; 19
	move.l d5,(a0)+

FP.AdrDroite:
	and.w	#$F,d1
	lsl.w	#4,d1		14<20 : Position
	movem.l	0(a1,d1),d2/d4/d5	28 ?
	move.l	(a0),d7		12
	and.l	d2,d7		6
	or.l	d4,d7		6
	move.l	d7,(a0)+		12
	move.l	(a0),d7		12
	and.l	d2,d7		6
	or.l	d5,d7		6
	move.l	d7,(a0)+		12
*	=122 ...<156

FP.Fin:
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FP.fil

FP.endpol movem.l (a7)+,d4-d7/a2-a6
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
	blt	FP.XOrder	Saut pour l'instruction rare (PipeLine)
FP.XOrdOK	and	d6,d0
	and	d6,d7
	sub	d7,d0	; d0 = XDn - XGn
	bne.s	FP.nosame

	lsr	#1,d7
	lea	0(a3,d7.w),a0
	bra.s	FP.pasajust2

FP.nosame lsr	#1,d7

	lea	FP.AdrMilieu+1(pc),a0
	lsr	#2,d0
	sub.w	#82,d0
	neg.w	d0
	move.b	d0,(a0)
	lea	0(a3,d7.w),a0	; a0 = adresse ecran a gauche
	bra	FP.pasajust

FP.XOrder	swap	d2
	exg	d0,d7
	bra	FP.XOrdOK

FP.fil2	move	(a5)+,d2
	swap	d2
	move	(a6)+,d2
	move.l	d2,d7
	and.l	d6,d7
	and.l	d6,d0
	cmp.l	d0,d7
	bne.s	FP.ajust
FP.pasajust2:
	move.l	a0,-(sp)
	move.l	d2,d0	; pour coup suivant
	move	d2,d1	; d1 = Xd
	swap	d2		; d2 = Xg

	and	#$F,d2		8 ; calcul masque gauche
	lsl.w	#4,d2		14
	move.l	0(a2,d2),d2	12 ; pointe sur definition !mask, (col & mask)
	and	#$F,d1		8 ; calcul masque gauche
	lsl.w	#4,d1		14
	movem.l	0(a1,d1),d1/d4/d5	28 ; pointe sur definition !mask, (col & mask)

	or.l	d1,d2		6  ; d2=!mask
	move.l	d2,d1		4
	not.l	d1		6  ; d1=mask

	move.l	(a0),d7		12 ; d1=donn‚e 1
	and.l	d2,d7		6  ; 
	and.l	d1,d4		6
	or.l	d4,d7		6
	move.l	d7,(a0)+		12

	move.l	(a0),d7		12
	and.l	d2,d7		6
	and.l	d1,d5		6
	or.l	d5,d7		6
	move.l	d7,(a0)+		12
* Soit 172 cycles, anciennement 240... (Gain=68 cycles)

	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FP.fil2

	movem.l (a7)+,d4-d7/a2-a6
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
	move.l d4,(a0)+	;	; 19
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

FPNB.endpol movem.l (a7)+,d4-d7/a2-a6
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
	dc.b	0,78,74,70,66,62,58,54,50
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

	movem.l (a7)+,d4-d7/a2-a6
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
	move.l d4,(a0)+	;	; 19

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

FFPNB.endpol movem.l (a7)+,d4-d7/a2-a6
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
	dc.b	0,40,38,36,34,32,30,28,26
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

	movem.l (a7)+,d4-d7/a2-a6
	rts


*******************************************************************************
*		Remplissage monoplan couleurs
*******************************************************************************


FFP.FilC	tst.w	Resol(a4)
	bne	FFP.FilNB
	lea	FP.MaskD(pc),a1
	lea	FP.MaskG(pc),a2
	move	Couleur(a4),d7	; couleur
	lsl	#8,d7	; x 64

	add	d7,a1
	add	d7,a2
	lea	4(a2),a4

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
	lsl.w	#4,d2
	addq.l	#6,a0
	move.w	0(a2,d2),(a0)+	; 12 ; d1 = (col & mask) Plan 01
	move.l	(a4),d4

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
	addq.l	#6,a0
	move.w d4,(a0)+	;	; 19

FFP.AdrDroite:
	and	#$F,d1	;	8 ; calcul masque gauche
	lsl.w	#4,d1
	addq.l	#6,a0
	move.w	0(a1,d1),(a0)+	; 12 ; d1 = (col & mask) Plan 01

FFP.Fin:
	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FFP.fil

FFP.endpol movem.l (a7)+,d4-d7/a2-a6
	rts


* -------------------------------------------------------------------------
* E:	d2: XGn	XDn
*	d0: travail
*	d7: travail
* -------------------------------------------------------------------------

FFP.ajust:
	move	d2,d0
	swap	d2
	move	d2,d7
	swap	d2

	cmp.w	d7,d0	Teste si crois‚
	blt	FFP.XOrder	Saut pour l'instruction rare (PipeLine)
FFP.XOrdOK:
	and.w	d6,d7
	and.w	d6,d0
	sub	d7,d0	; d0 = XDn - XGn
	bne.s	FFP.nosame
	lsr	#1,d7 : pour 8 mots par 16 points
	lea	0(a3,d7.w),a0
	bra.s	FFP.pasajust2

FFP.nosame
	lsr	#1,d7

	lsr.w	#2,d0
	sub.w	#82,d0
	neg.w	d0
	lea	FFP.AdrMilieu+1(pc),a0
	move.b	d0,(a0)
	lea	0(a3,d7.w),a0	; a0 = adresse ecran a gauche
	bra	FFP.pasajust

FFP.XOrder:
	swap	d2
	exg	d0,d7
	bra	FFP.XOrdOK


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
	lsl.w	#4,d2
	move.l	0(a2,d2),d2	; 12 ; pointe sur definition !mask, (col & mask)
	and	#$F,d1	;	8 ; calcul masque gauche
	lsl.w	#4,d1
	move.l	0(a1,d1),d1	; 12 ; pointe sur definition !mask, (col & mask)
	or.l	d2,d1	; 12 ; d2 = !mask
	move.w	d1,6(a0)	; 20 ; ecran = ecran & !mask

	move.l (sp)+,a0
	lea	160(a0),a0
	lea	160(a3),a3
	dbf	d3,FFP.fil2

	movem.l (a7)+,d4-d7/a2-a6
	rts

	SECTION	DATA
	EVEN
FP.MaskG:
	INCBIN	\PROJET.CUB\MASKDC2.INC
FP.MaskD:
	INCBIN	\PROJET.CUB\MASKGC2.INC
FPNB.MaskG:
	INCBIN	\PROJET.CUB\MASKDNB.INC
FPNB.MaskD:
	INCBIN	\PROJET.CUB\MASKGNB.INC
