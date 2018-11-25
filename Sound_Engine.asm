; -------------------------------- This code is based on the Nerdy Nights Audio Tutorials ----------------------------------------------
    .rsset $0300
sound_disable_flag      .rs 1   ; A Boolean value used when audio is toggled on or off.
sound_frame_counter     .rs 1   ; This is used to count how many frames into a track in frames the game is

; The memory address in the APU for each of the sounds.
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


; A large chunk of memory is reserved for the audio which is 
stream_current_sound    .rs 6 ; Each of this has six registers assigned
stream_status           .rs 6 ; This is because there are six possible sounds
stream_channel          .rs 6 ; The sounds are Square 1 and 2, Triagnle and Noise
stream_Volume_Duty      .rs 6 ; The Volume and Duty changes the volume or sharpness of the sound
stream_ptr_LOW          .rs 6 ; This is used to tell which sound should be playing in the low register
stream_ptr_HIGH         .rs 6 ; This is the same as above but only the first few bytes are used and the rest make up sound length
stream_Note_LOW         .rs 6 ; This is the actual value which is stored for sound
stream_Note_HIGH        .rs 6 ; This is again the same as above

; These temp values are used to hold exact value the accumulator or x and y regusters are holding.
sound_temp1             .rs 1
sound_temp2             .rs 1

; This is just used as short hand to make it easier to reference each type of sound.
SQU1                = $00
SQU2                = $01
TRI                 = $02
NOI                 = $03

; These are used as reference when deciding what instruments should play and when.
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
    STA sound_disable_flag ; Clear the sound Disable flag

    RTS

	; Disables all sound when called.
Sound_Disable:
    LDA #$00
    STA APUFLAG ; Disable all audio channels
    LDA #$01
    STA sound_disable_flag
    RTS

	; Load the sound file into RAM.
Sound_Load:
    STA sound_temp1 ; Store the value of A into the accumulator in the event it's needed.
    ASL A
    TAY
    LDA Song_Header, y ; Choose which song to load based on the y value.
    STA sound_ptr ; Set the pointer to have the correct values for the appropriate song or sound effect.
    LDA Song_Header+1, y
    STA sound_ptr+1

    LDY #$00 ; Ensure that the sound pointer points to the start of the song.
    LDA [sound_ptr], y
    STA sound_temp2
    INY
.loop:   ; loop through each of the sound components to ensure the values are set correctly from the data.
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

	; This is called when the audio stream ends to load a new stream.
.next_stream:
    INY
    LDA sound_temp1
    STA stream_current_sound, x

    DEC sound_temp2
    BNE .loop
    RTS

	; This is called every frame to play sound and is needed for the audio to actually play if the audio isn't stopped.
Sound_Play_Frame:
    LDA sound_disable_flag
    BNE .done
    
    INC sound_frame_counter
    LDA sound_frame_counter
    CMP #$08
    BNE .done

    LDX #$00
; This is used to make all the audio play provided it's supposed to.
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

	; This is used to setup the audio processing unit ready to play sound.
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

; This actually is used to get the correct audio files from RAM when needed.
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
    
	; The number of sounds their headers and the appropriate files needed to be included to allow them to work.
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




