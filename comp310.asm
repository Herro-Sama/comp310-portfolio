    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1

; ---------------------------------------------------------------------------

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014
JOYPAD1   = $4016
JOYPAD2   = $4017

BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001

    .rsset $0000
joypad1_state      .rs 1
nametable_address  .rs 2
scroll_y		   .rs 1
scroll_page		   .rs 1	
bullet_active      .rs 1
jump_active		   .rs 1
temp_x             .rs 1
temp_y             .rs 1

    .rsset $0200
sprite_player1      .rs 4
sprite_player2      .rs 4
sprite_player3      .rs 4
sprite_player4      .rs 4
sprite_bullet      .rs 4

    .rsset $0000
SPRITE_Y           .rs 1
SPRITE_TILE        .rs 1
SPRITE_ATTRIB      .rs 1
SPRITE_X           .rs 1


    .bank 0
    .org $C000

; Initialisation code based on https://wiki.nesdev.com/w/index.php/Init_code
RESET:
    SEI        ; ignore IRQs
    CLD        ; disable decimal mode
    LDX #$40
    STX $4017  ; disable APU frame IRQ
    LDX #$ff
    TXS        ; Set up stack
    INX        ; now X = 0
    STX PPUCTRL  ; disable NMI
    STX PPUMASK  ; disable rendering
    STX $4010  ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; If the user presses Reset during vblank, the PPU may reset
    ; with the vblank flag still true.  This has about a 1 in 13
    ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
    ; flag now so the vblankwait1 loop sees an actual vblank.
    BIT PPUSTATUS

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblankwait1:  
    BIT PPUSTATUS
    BPL vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    TXA
clrmem:
    LDA #0
    STA $000,x
    STA $100,x
    STA $300,x
    STA $400,x
    STA $500,x
    STA $600,x
    STA $700,x  ; Remove this if you're storing reset-persistent data

    ; We skipped $200,x on purpose.  Usually, RAM page 2 is used for the
    ; display list to be copied to OAM.  OAM needs to be initialized to
    ; $EF-$FF, not 0, or you'll get a bunch of garbage sprites at (0, 0).

    LDA #$FF
    STA $200,x

    INX
    BNE clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.
   
vblankwait2:
    BIT PPUSTATUS
    BPL vblankwait2

    ; End of initialisation code

    JSR InitialiseGame

    LDA #%10000000 ; Enable NMI
    STA PPUCTRL

    LDA #%00011000 ; Enable sprites and background
    STA PPUMASK
	
	LDA #0
	STA PPUSCROLL ; Set X Scroll
	LDA #0
	STA PPUSCROLL ;Set Y Scroll
	
	

    ; Enter an infinite loop
forever:
    JMP forever

; ---------------------------------------------------------------------------

InitialiseGame: ; Begin subroutine
    ; Reset the PPU high/low latch
    LDA PPUSTATUS

    ; Write address $3F00 (background colour pallete) to the PPU
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR

	; Assign background colour value
    LDA #$37
    STA PPUDATA
	LDA #$17
    STA PPUDATA
    LDA #$07
    STA PPUDATA
    LDA #$3D
    STA PPUDATA
	
    ; Write address $3F10 (sprite pallete colours colour) to the PPU
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR

    ; Write the background colour
    LDA #$37
    STA PPUDATA

    ; Write the palette colours
    LDA #$30
    STA PPUDATA
    LDA #$06
    STA PPUDATA
    LDA #$3D
    STA PPUDATA
	
	 ; Write the background colour
    LDA #$37
    STA PPUDATA

    ; Write the palette colours
    LDA #$20
    STA PPUDATA
    LDA #$07
    STA PPUDATA
    LDA #$10
    STA PPUDATA

    ; Write sprite data for sprite 0
    LDA #120    ; Y position
    STA sprite_player1 + SPRITE_Y
    LDA #1      ; Tile number
    STA sprite_player1 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player1 + SPRITE_ATTRIB
    LDA #128    ; X position
    STA sprite_player1 + SPRITE_X
	
	; Write sprite data for sprite 1
    LDA #120    ; Y position
    STA sprite_player2 + SPRITE_Y
    LDA #2      ; Tile number
    STA sprite_player2 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player2 + SPRITE_ATTRIB
    LDA #136    ; X position
    STA sprite_player2 + SPRITE_X
	
	; Write sprite data for sprite 2
    LDA #128    ; Y position
    STA sprite_player3 + SPRITE_Y
    LDA #3      ; Tile number
    STA sprite_player3 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player3 + SPRITE_ATTRIB
    LDA #128    ; X position
    STA sprite_player3 + SPRITE_X
	
	; Write sprite data for sprite 3
    LDA #128    ; Y position
    STA sprite_player4 + SPRITE_Y
    LDA #4      ; Tile number
    STA sprite_player4 + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player4 + SPRITE_ATTRIB
    LDA #136    ; X position
    STA sprite_player4 + SPRITE_X
	
	; Load data into the nametable
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
	LDA #LOW(NameTableData)
	STA nametable_address
	LDA #HIGH(NameTableData)
	STA nametable_address+1
	
LoadNameTableData_OuterLoop:	
	LDY #0
LoadNameTableData_InnerLoop:
	LDA [nametable_address], y
	BEQ LoadNameTable_End
	STA PPUDATA
	INY
	BNE LoadNameTableData_InnerLoop
	INC nametable_address+1
	JMP LoadNameTableData_OuterLoop

LoadNameTable_End:
	
	
	LDA #$23
	STA PPUADDR
	LDA #$C0
	STA PPUADDR
	
	LDA #0
	LDX #64
	
loadAttributes_Loop:
	STA PPUDATA
	DEX
	BNE loadAttributes_Loop	
	
	
    RTS ; End subroutine

; ---------------------------------------------------------------------------

; NMI is called on every frame
NMI:
    ; Initialise controller 1
    LDA #1
    STA JOYPAD1
    LDA #0
    STA JOYPAD1

    ; Read joypad state
    LDX #0
    STX joypad1_state
ReadController:
    LDA JOYPAD1
    LSR A
    ROL joypad1_state
    INX
    CPX #8
    BNE ReadController

    ; React to Right button
    LDA joypad1_state
    AND #BUTTON_RIGHT
    BEQ ReadRight_Done  ; if ((JOYPAD1 & 1) != 0) {
    LDA sprite_player1 + SPRITE_X
    CLC
    ADC #1
    STA sprite_player1 + SPRITE_X
	LDA sprite_player2 + SPRITE_X
    CLC
    ADC #1
    STA sprite_player2 + SPRITE_X
	LDA sprite_player3 + SPRITE_X
    CLC
    ADC #1
    STA sprite_player3 + SPRITE_X
	LDA sprite_player4 + SPRITE_X
    CLC
    ADC #1
    STA sprite_player4 + SPRITE_X
ReadRight_Done:         ; }

    ; React to Down button
    LDA joypad1_state
    AND #BUTTON_DOWN
    BEQ ReadDown_Done  ; if ((JOYPAD1 & 1) != 0) {
    LDA sprite_player1 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player1 + SPRITE_Y
	LDA sprite_player2 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player2 + SPRITE_Y
    LDA sprite_player3 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player3 + SPRITE_Y
    LDA sprite_player4 + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player4 + SPRITE_Y
	
ReadDown_Done:         ; }

    ; React to Left button
    LDA joypad1_state
    AND #BUTTON_LEFT
    BEQ ReadLeft_Done  ; if ((JOYPAD1 & 1) != 0) {
    LDA sprite_player1 + SPRITE_X
    SEC
    SBC #1
    STA sprite_player1 + SPRITE_X
	LDA sprite_player2 + SPRITE_X
    SEC
    SBC #1
    STA sprite_player2 + SPRITE_X
	LDA sprite_player3 + SPRITE_X
    SEC
    SBC #1
    STA sprite_player3 + SPRITE_X
	LDA sprite_player4 + SPRITE_X
    SEC
    SBC #1
    STA sprite_player4 + SPRITE_X
ReadLeft_Done:         ; }

    ; React to Up button
    LDA joypad1_state
    AND #BUTTON_UP
    BEQ ReadUp_Done  ; if ((JOYPAD1 & 1) != 0) {
    LDA sprite_player1 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player1 + SPRITE_Y
	LDA sprite_player2 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player2 + SPRITE_Y
	LDA sprite_player3 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player3 + SPRITE_Y
	LDA sprite_player4 + SPRITE_Y
    SEC
    SBC #1
    STA sprite_player4 + SPRITE_Y
ReadUp_Done:         ; }

    ; React to A button
    LDA joypad1_state
    AND #BUTTON_A
    BEQ ReadA_Done
    ; Spawn a bullet if one is not active
    LDA bullet_active
    BNE ReadA_Done
    ; No bullet active, so spawn one
    LDA #1
    STA bullet_active
    LDA sprite_player1 + SPRITE_Y    ; Y position
    STA sprite_bullet + SPRITE_Y
    LDA #6      ; Tile number
    STA sprite_bullet + SPRITE_TILE
    LDA #1      ; Attributes
    STA sprite_bullet + SPRITE_ATTRIB
    LDA sprite_player1 + SPRITE_X    ; X position
    STA sprite_bullet + SPRITE_X
ReadA_Done:

    ; Update the bullet
    LDA bullet_active
    BEQ UpdateBullet_Done
    LDA sprite_bullet + SPRITE_Y
    SEC
    SBC #1
    STA sprite_bullet + SPRITE_Y
    BCS UpdateBullet_Done
    ; If carry flag is clear, bullet has left the top of the screen -- destroy it
    LDA #0
    STA bullet_active
UpdateBullet_Done:

	; React to B button
    LDA joypad1_state
    AND #BUTTON_B
    BEQ ReadB_Done
    ; Perform a jump if one is not happening
    LDA jump_active
    BNE ReadB_Done
		
	LDA #0
	STA PPUSCROLL
	LDA scroll_y
	CLC
	ADC #250
	STA scroll_y
	STA PPUSCROLL
	BCC scroll_NoWrap
	
	LDA scroll_page
	EOR #1
	STA scroll_page
	ORA #%10000000
	STA PPUCTRL
	
ReadB_Done:	

scroll_NoWrap:
	LDA #02

	
    ; Copy sprite data to the PPU
    LDA #0
    STA OAMADDR
    LDA #$02
    STA OAMDMA

    RTI         ; Return from interrupt

; ---------------------------------------------------------------------------
	
NameTableData:	
	.db $07,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$07,$07,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$07,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.db $64
	
	
; ---------------------------------------------------------------------------

    .bank 1
    .org $FFFA
    .dw NMI
    .dw RESET
    .dw 0

; ---------------------------------------------------------------------------

    .bank 2
    .org $0000
    .incbin "spriteSheet.chr"
