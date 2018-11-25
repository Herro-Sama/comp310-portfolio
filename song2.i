; This is the same as song0 but at a lower octave.
Song2_Header:
    .byte $04

    .byte MUSIC_SQ1
    .byte $01
    .byte SQU1
    .byte $BC
    .word Song2_Square1

    .byte MUSIC_SQ2
    .byte $01
    .byte SQU2
    .byte $38
    .word Song2_Square2

    .byte MUSIC_TRI
    .byte $01
    .byte TRI
    .byte $81
    .word Song2_Triangle

    .byte MUSIC_NOI
    .byte $00

Song2_Square1:
    .byte C1, G1, C1, C1, G1, G3, C1, C1     
    .byte C1, G1, C1, C1, G1, G3, C1, C1 
    .byte C1, G1, C1, C1, G1, G3, C1, C1    
    .byte C1, G1, C1, C1, G1, G3, C1, C1    
    .byte $FF
    
Song2_Square2:
    .byte F1, C3, C1, A1, C1, C3, F1, C3 
    .byte F1, C3, C1, A1, C1, C3, F1, C3        
    .byte F1, C3, C1, A1, C1, C3, F1, C3
    .byte F1, C3, C1, A1, C1, C3, F1, C3
    .byte $FF
    
Song2_Triangle:
    .byte D1, D2, D2, D1, D2, D2, D2, E2
    .byte D1, D2, D2, D1, D2, D2, D2, E2
    .byte D1, D2, D2, D1, D2, D2, D2, E2
    .byte D1, D2, D2, D1, D2, D2, D2, E2
    .byte $FF