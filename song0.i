;Blank File for no Audio

Song0_Header:
    .byte $04

    .byte MUSIC_SQ1
    .byte $01
    .byte SQU1
    .byte $BC
    .word Song0_Square1

    .byte MUSIC_SQ2
    .byte $01
    .byte SQU2
    .byte $38
    .word Song0_Square2

    .byte MUSIC_TRI
    .byte $01
    .byte TRI
    .byte $81
    .word Song0_Triangle

    .byte MUSIC_NOI
    .byte $00

;Song taken from the Nerdy Night Sound Part 5: http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=23452
Song0_Square1:
    .byte C4, G4, C4, C4, G4, G5, C4, C4     
    .byte C4, G4, C4, C4, G4, G5, C4, C4 
    .byte C4, G4, C4, C4, G4, G5, C4, C4    
    .byte C4, G4, C4, C4, G4, G5, C4, C4    
    .byte $FF
    
Song0_Square2:
    .byte F4, C5, C4, A4, C4, C5, F4, C5 
    .byte F4, C5, C4, A4, C4, C5, F4, C5        
    .byte F4, C5, C4, A4, C4, C5, F4, C5
    .byte F4, C5, C4, A4, C4, C5, F4, C5
    .byte $FF
    
Song0_Triangle:
    .byte D4, D3, D3, D4, D3, D3, D3, E3
    .byte D4, D3, D3, D4, D3, D3, D3, E3
    .byte D4, D3, D3, D4, D3, D3, D3, E3
    .byte D4, D3, D3, D4, D3, D3, D3, E3
    .byte $FF