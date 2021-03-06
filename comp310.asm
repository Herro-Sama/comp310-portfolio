 ; ---------------------- Assigning Memory Bank Allocation --------------------------


    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1

; ----------------------- Assigning Variables ---------------------------

PPUCTRL             = $2000
PPUMASK             = $2001
PPUSTATUS           = $2002
OAMADDR             = $2003
OAMDATA             = $2004
PPUSCROLL           = $2005
PPUADDR             = $2006
PPUDATA             = $2007
OAMDMA              = $4014
APUFLAG             = $4015
JOYPAD1             = $4016
JOYPAD2             = $4017

BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001

    .rsset $0000
seed			    .rs 2	 
joypad1_state       .rs 1
nametable_address   .rs 2
scroll_y		    .rs 1
scroll_page		    .rs 1	
bullet_active       .rs 1
jump_active		    .rs 1
generate_x	        .rs 1
player_speed        .rs 2
player_position_sub .rs 1


    .rsset $0200
sprite_player      .rs 4
sprite_bullet      .rs 4

    .rsset $0000
SPRITE_Y           .rs 1
SPRITE_TILE        .rs 1
SPRITE_ATTRIB      .rs 1
SPRITE_X           .rs 1

sound_ptr          .rs 2
current_song       .rs 1

Gravity            = 10
Jump_Speed         = -(2 * 256 + 64)
screen_bottom_y    = 232 




    .bank 0
    .org $8000
    .include "Sound_Engine.asm" ; The Sound engine file is used to handle all audio requests.

; ----------------------- Reset ---------------------------
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

    JSR Sound_Initialise ; This is used to make sure all audio is enabled

    LDA #$01
    STA current_song

    JSR InitialiseGame

    LDA #%10000000 ; Enable NMI
    STA PPUCTRL

    LDA #%00011000 ; Enable sprites and background
    STA PPUMASK
	
	LDA #1
	STA PPUSCROLL ; Set X Scroll
	LDA #0
	STA PPUSCROLL ;Set Y Scroll

    ; Enter an infinite loop
forever:
    JMP forever
; ----------------------- The inital allocation of memory for the first boot of the game and any resets -------------------------------

InitialiseGame: ; Begin subroutine
	; Seed RNG
	LDA #$12
	STA seed
	LDA #$34
	STA seed
	
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
    STA sprite_player + SPRITE_Y
    LDA #1      ; Tile number
    STA sprite_player + SPRITE_TILE
    LDA #0      ; Attributes
    STA sprite_player + SPRITE_ATTRIB
    LDA #128    ; X position
    STA sprite_player + SPRITE_X
	
	
	
	; Load data into the nametable
	LDA #$20
	STA PPUADDR
	LDA #$00
	STA PPUADDR
	
    ; Load the name table data into memory
	LDA #LOW(NameTableData)
	STA nametable_address
	LDA #HIGH(NameTableData)
	STA nametable_address+1

    ;Load first audio file
    LDA #$01
    JSR Sound_Load
	

    ; Load a counter into y and loop until y equals zero
LoadNameTableData2_OuterLoop:	
	LDY #7
LoadNameTableData2_InnerLoop:
	LDA (nametable_address), y
	BEQ LoadNameTable2_End
	STA PPUDATA
	INY
	BNE LoadNameTableData2_InnerLoop
	INC nametable_address+1
	JMP LoadNameTableData2_OuterLoop

LoadNameTable2_End:
	
	; Setup values for the Attribute table
	LDA #$23
	STA PPUADDR
	LDA #$C0
	STA PPUADDR
	
	LDA #%01000000
	LDX #64
	
    ; Load and set attribute colours.
loadAttributes2_Loop:
	STA PPUDATA
	DEX
	BNE loadAttributes2_Loop		
	
	LDY #32

InitialGeneration_Loop:
	JSR GenerateFloor
	DEY
	BNE InitialGeneration_Loop

	
	; Setup values for the Attribute table
	LDA #$23
	STA PPUADDR
	LDA #$C0
	STA PPUADDR
	
	LDA #%00000000
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
	LDA #0
	STA scroll_y

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
    LDA sprite_player + SPRITE_X
    CLC
    ADC #1
    STA sprite_player + SPRITE_X
ReadRight_Done:         ; }

    ; React to Down button
    LDA joypad1_state
    AND #BUTTON_DOWN
    BEQ ReadDown_Done  ; if ((JOYPAD1 & 1) != 0) {
    LDA sprite_player + SPRITE_Y
    CLC
    ADC #1
    STA sprite_player + SPRITE_Y
	
ReadDown_Done:         ; }

    ; React to Left button
    LDA joypad1_state
    AND #BUTTON_LEFT
    BEQ ReadLeft_Done  ; if ((JOYPAD1 & 1) != 0) {
    LDA sprite_player + SPRITE_X
    SEC
    SBC #1
    STA sprite_player + SPRITE_X

ReadLeft_Done:         ; }

    ; React to Up button
    LDA joypad1_state
    AND #BUTTON_UP
    BEQ ReadUp_Done  ; if ((JOYPAD1 & 1) != 0) {
    JSR LoadNewSong ; Change the song when the user presses the up button.

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
    LDA sprite_player + SPRITE_Y    ; Y position
    STA sprite_bullet + SPRITE_Y
    LDA #2      ; Tile number
    STA sprite_bullet + SPRITE_TILE
    LDA #1      ; Attributes
    STA sprite_bullet + SPRITE_ATTRIB
    LDA sprite_player + SPRITE_X    ; X position
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
    LDA #LOW(Jump_Speed)
    STA player_speed
    LDA #HIGH(Jump_Speed)
    STA player_speed+1
	LDA #1
    STA jump_active
	
ReadB_Done:	

; Apply gravity to the players speed pulling them down.
   LDA player_speed
   CLC
   ADC #LOW(Gravity)
   STA player_speed
   LDA player_speed+1
   ADC #HIGH(Gravity)
   STA player_speed+1

; Set the players sprite position after it's been updated by the player_speed
   LDA player_position_sub
   CLC
   ADC player_speed
   STA player_position_sub
   LDA sprite_player+SPRITE_Y
   ADC player_speed+1
   STA sprite_player+SPRITE_Y

; Check if the player is needs to be clamped to the floor.
   CMP #screen_bottom_y
   BCC updatePlayer_NoClamp
   

   LDA player_speed+1
   BMI updatePlayer_ToTop
   LDA #screen_bottom_y-1
   JMP updatePlayer_DoClamp

updatePlayer_ToTop: ; Clamp the player to the top of the screen if necessary
   LDA #0


updatePlayer_DoClamp: ; Clamps the player to the botom of the screen and resets their jump.
   STA sprite_player+SPRITE_Y
   LDA #0
   STA player_speed
   STA player_speed+1
   STA jump_active
   JMP scroll_NoWrap

updatePlayer_NoClamp: 
	LDA #1
	STA jump_active

scroll_NoWrap:
	LDA #02
	STA PPUSCROLL

	LDA scroll_y
	AND #7
	BNE scroll_NoGenerate
	JSR GenerateFloor
scroll_NoGenerate:
	
	
	;Ensure PPUCTRL is set
	STA scroll_page
	ORA #%10000000
	STA PPUCTRL
	
    ; Copy sprite data to the PPU
    LDA #0
    STA OAMADDR
    LDA #$02
    STA OAMDMA

    JSR Sound_Play_Frame

	LDA #0

    RTI         ; Return from interrupt

; ------------------------------Random Number Generator Literally Magic stuff from Ed's Videos -------------------------------

prng:
	LDX #8
	LDA seed+0
	
prng_1:
	ASL A
	ROL seed+1
	BCC prng_2
	EOR #$2D
	
prng_2:
	DEX
	BNE prng_1
	STA seed+0
	CMP #0
	RTS


; -----------------------Helper Functions called at various points -----------------------------------
LoadNewSong:

    INC current_song ; Loads the next sound to be played and then returns to the previous functions.
    LDA current_song
    CMP #NUM_SONGS
    BNE .done
    LDA #$01
    STA current_song
.done:
    LDA current_song
    JSR Sound_Load
    RTS


GenerateFloor:

	LDA #%00000000
	STA PPUCTRL

	; Find most significatant byte of PPU address.	
	LDA generate_x
	AND #32   ; Accumulator = 0 for nametable $2000 or 32 for nametable $2400
	LSR A
	LSR A
	LSR A    ;This clears the carry flag
	ADC #$20
	STA PPUADDR
	
	; Find the least thing and do it too.
	LDA generate_x
	AND #31
	STA PPUADDR
	
	; Write data values
	LDA generate_x
	LDX #30
	
GenerateFloor_Loop:
	STA PPUDATA
	DEX
	BNE GenerateFloor_Loop
	
	;Increment X
	LDA generate_x
	CLC
	ADC #1
	AND #63
	
	RTS
	; The name table is setup to store all of the background sprite images.
NameTableData:	
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
	.db $00	

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
