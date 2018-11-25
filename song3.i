; Very short sound sequence.
Song3_Header:
    .byte $04

    .byte MUSIC_SQ1
    .byte $01
    .byte SQU1
    .byte $BC
    .word Song3_Square1

    .byte MUSIC_SQ2
    .byte $01
    .byte SQU2
    .byte $38
    .word Song3_Square2

    .byte MUSIC_TRI
    .byte $01
    .byte TRI
    .byte $81
    .word Song3_Triangle

    .byte MUSIC_NOI
    .byte $00

;Song taken from the Nerdy Night Sound Part 5: http://nintendoage.com/forum/messageview.cfm?catid=22&threadid=23452
Song3_Square1:
    .byte A1, A2, A3, A4, A5, A6, A7, A8
    .byte $FF
    
Song3_Square2:
    .byte B1, B2, B3, B4, B5, B6, B7, B8
    .byte $FF
    
Song3_Triangle:
    .byte C1, C2, C3, C4, C5, C6, C7, C8
    .byte $FF