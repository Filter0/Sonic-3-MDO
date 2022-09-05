; ---------------------------------------------------------------------------
; Adds art to the DMA queue
; Inputs:
; d1 = source address
; d2 = destination VRAM address
; d3 = number of words to transfer
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================


Add_To_DMA_Queue:
		; Detect if transfer crosses 128KB boundary
		lsr.l	#1,d1
		move.w	d3,d0
		neg.w	d0
		sub.w	d1,d0
		bcc.s	.transfer
		; Do first transfer
		movem.l	d1-d3,-(sp)
		add.w	d0,d3		; d3 = words remaining in 128KB "bank"
		bsr.s	.transfer
		movem.l	(sp)+,d1-d3
		; Get second transfer's source, destination, and length
		moveq	#0,d0
		sub.w	d1,d0
		sub.w	d0,d3
		add.l	d0,d1
		add.w	d0,d2
		add.w	d0,d2
		; Do second transfer
	.transfer:

                movea.l	(DMA_queue_slot).w,a1
		tst.w	(a1)	; is the queue full?
		bne.s	Add_To_DMA_Queue_Done	; if not, return

		move.w	#$9300,d0
		move.b	d3,d0
		move.w	d0,(a1)+	; command to specify transfer length in words & $00FF

		move.w	#$9400,d0
		lsr.w	#8,d3
		move.b	d3,d0
		move.w	d0,(a1)+	; command to specify transfer length in words & $FF00

		move.w	#$9500,d0
		move.b	d1,d0
		move.w	d0,(a1)+	; command to specify transfer source & $0001FE

		move.w	#$9600,d0
		lsr.l	#8,d1
		move.b	d1,d0
		move.w	d0,(a1)+	; command to specify transfer source & $01FE00

		move.w	#$9700,d0
		lsr.l	#8,d1
		andi.b	#$7F,d1		; this instruction safely allows source to be in RAM; S2's lacks this
		move.b	d1,d0
		move.w	d0,(a1)+	; command to specify transfer source & $FE0000

		andi.l	#$FFFF,d2
		lsl.l	#2,d2
		lsr.w	#2,d2
		swap	d2
		ori.l	#vdpComm($0000,VRAM,DMA),d2
		move.l	d2,(a1)+	; command to specify transfer destination and begin DMA

		move.l	a1,(DMA_queue_slot).w	; set new free slot address
		tst.w	(a1)	; has the end of the queue been reached?
		beq.s	Add_To_DMA_Queue_Done	; if yes, branch
		move.w	#0,(a1)	; place stop token at the end of the queue

Add_To_DMA_Queue_Done:
		rts
; End of function Add_To_DMA_Queue


; =============== S U B R O U T I N E =======================================


Process_DMA_Queue:
		lea	(VDP_control_port).l,a5
		lea	(DMA_queue).w,a1

$$loop:
		move.w	(a1)+,d0	; has a stop token been encountered?
		beq.s	$$stop	; if it has, branch
		move.w	d0,(a5)
		move.w	(a1)+,(a5)
		move.w	(a1)+,(a5)
		move.w	(a1)+,(a5)
		move.w	(a1)+,(a5)
		move.w	(a1)+,(a5)
		move.w	(a1)+,(a5)
		tst.w	(a1)	; has the end of the queue been reached?
		bne.s	$$loop	; if not, loop

$$stop:
		move.w	#0,(DMA_queue).w
		move.l	#DMA_queue,(DMA_queue_slot).w
		rts
; End of function Process_DMA_Queue