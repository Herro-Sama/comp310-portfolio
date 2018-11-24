Song1_Header:
    .byte $04

    .byte MUSIC_SQ1
    .byte $01
    .byte SQU1
    .byte $BC
    .word Song1_Square1

    .byte MUSIC_SQ2
    .byte $01
    .byte SQU2
    .byte $38
    .word Song1_Square2

    .byte MUSIC_TRI
    .byte $01
    .byte TRI
    .byte $81
    .word Song1_Triangle

    .byte MUSIC_NOI
    .byte $00

;Song taken from the Nerdy Night Sound Part 5: http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=23452
Song1_Square1:
    .byte A3, C4, E4, A4, C5, E5, A5, F3 ;some notes.  A minor
    .byte G3, B3, D4, G4, B4, D5, G5, E3  ;Gmajor
    .byte F3, A3, C4, F4, A4, C5, F5, C5 ;F major
    .byte F3, A3, C4, F4, A4, C5, F5 ;F major
    .byte $FF
    
Song1_Square2:
    .byte A3, A3, A3, E4, A3, A3, E4, A3 
    .byte G3, G3, G3, D4, G3, G3, D4, G3
    .byte F3, F3, F3, C4, F3, F3, C4, F3
    .byte F3, F3, F3, C4, F3, F3, C4
    .byte $FF
    
Song1_Triangle:
    .byte A3, A3, A3, A3, A3, A3, A3, G3
    .byte G3, G3, G3, G3, G3, G3, G3, F3
    .byte F3, F3, F3, F3, F3, F3, F3, F3
    .byte F3, F3, F3, F3, F3, F3, F3
    .byte $FF