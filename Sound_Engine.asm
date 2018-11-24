    .rsset $0300
sound_disable_flag      .rs 1   
sound_position          .rs 1 
sound_frame_counter     .rs 1

SQU1_CTRL           = $4000
SQU1_SWEEP          = $4001
SQU1_LOW            = $4002
SQU1_HIGH           = $4003
SQU2_CTRL           = $4004
SQU2_SWEEP          = $4005
SQU2_LOW            = $4006
SQU2_HIGH           = $4007
TRI_CTRL            = $4008
TRI_LOW             = $400A
TRI_HIGH            = $400B
NOISE_CTRL          = $400C

stream_current_sound    .rs 6
stream_status           .rs 6
stream_channel          .rs 6
stream_Volume_Duty      .rs 6
stream_ptr_LOW          .rs 6
stream_ptr_HIGH         .rs 6
stream_Note_LOW         .rs 6
stream_Note_HIGH        .rs 6

sound_temp1             .rs 1
sound_temp2             .rs 1

SQU1                = $00
SQU2                = $01
TRI                 = $02
NOI                 = $03

MUSIC_SQ1           = $00
MUSIC_SQ2           = $01
MUSIC_TRI           = $02
MUSIC_NOI           = $03
SFX_1               = $04
SFX_2               = $05

; ------------------------- This is the where the audio subroutines are located --------------------------------------------

Sound_Initialise:
    
    ; Activate the Audio processor, setting Square One, Square Two, Noise and DMC
    LDA #$0F
    STA APUFLAG

    ; Set the volume for Square 1,2 and noise to nothing
    LDA #$30
    STA SQU1_CTRL
    STA SQU2_CTRL
    STA NOISE_CTRL

    ; Silence the Triangle
    LDA #$80
    STA TRI_CTRL

    LDA #$00
    STA sound_disable_flag ;Clear the sound Disable flag

    RTS

Sound_Disable:
    LDA #$00
    STA APUFLAG ;Disable all audio channels
    LDA #$01
    STA sound_disable_flag
    RTS

Sound_Load:
    STA sound_temp1
    ASL A
    TAY
    LDA Song_Header, y
    STA sound_ptr
    LDA Song_Header+1, y
    STA sound_ptr+1

    LDY #$00
    LDA [sound_ptr], y
    STA sound_temp2
    INY
.loop:
    LDA [sound_ptr], y
    TAX
    INY

    LDA [sound_ptr], y    
    STA stream_status, x
    BEQ .next_stream
    INY
    
    LDA [sound_ptr], y
    STA stream_channel, x
    INY

    LDA [sound_ptr], y
    STA stream_Volume_Duty, x
    INY

    LDA [sound_ptr], y
    STA stream_ptr_LOW, x
    INY

    LDA [sound_ptr], y
    STA stream_ptr_HIGH, x

.next_stream:
    INY
    LDA sound_temp1
    STA stream_current_sound, x

    DEC sound_temp2
    BNE .loop
    RTS

Sound_Play_Frame:
    LDA sound_disable_flag
    BNE .done
    
    INC sound_frame_counter
    LDA sound_frame_counter
    CMP #$08
    BNE .done

    LDX #$00

.loop:
    LDA stream_status, x
    AND #$01
    BEQ .next_stream

    JSR Fetch_Byte
    JSR Set_APU

.next_stream:
    INX
    CPX #$06
    BNE .loop

    LDA #$00
    STA sound_frame_counter    

.done:
    RTS

Set_APU:
    LDA stream_channel, x
    ASL A
    ASL A
    TAY
    LDA stream_Volume_Duty, x
    STA $4000, y
    LDA stream_Note_LOW, x
    STA $4002, y
    LDA stream_Note_HIGH, x
    STA $4003, y

    LDA stream_channel, x
    CMP #TRI
    BCS .end
    LDA #$08
    STA $4001, y
.end
    LDA #0
    RTS    


Sound_Pause:
    STA sound_position


Sound_UnPause:
    LDA sound_position

Fetch_Byte:
    LDA stream_ptr_LOW, x
    STA sound_ptr
    LDA stream_ptr_HIGH, x
    STA sound_ptr+1

    LDY #$00
    LDA [sound_ptr], y
    BPL .note
    CMP #$A0
    BCC .note_length

.opcode:
    JMP .update_pointer

.note_length:
    JMP .update_pointer

.note:
    ASL A
    STY sound_temp1
    TAY
    LDA NoteTable, y
    STA stream_Note_LOW, x
    LDA NoteTable+1, y
    STA stream_Note_HIGH, x
    LDY sound_temp1

.update_pointer:
    INY
    TYA
    CLC
    ADC stream_ptr_LOW, x
    STA stream_ptr_LOW, x
    BCC .end
    INC stream_ptr_HIGH, x


.end:
    LDA #0
    RTS        
    
NUM_SONGS = $04

Song_Header:
    .word Song0_Header
    .word Song1_Header
    .word Song2_Header
    .word Song3_Header

    .include "NoteTable.i"
    .include "song0.i"
    .include "song1.i"
    .include "song2.i"
    .include "song3.i"




