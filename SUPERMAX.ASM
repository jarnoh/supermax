blks    equ 52800

        .486p
        ideal
segment koodit byte public 'CODE' use16
        assume cs:koodit, ds:koodit

start:
        mov     bx, ss
        mov     ax, es
        sub     bx, ax
        mov     ax, sp
        add     ax, 0Fh
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        shr     ax, 1
        add     bx, ax
        mov     ah, 4Ah
        int     21h

        push    cs
        pop     ds
        mov     dx, offset fname
        mov     ah, 3Ch                 ; create
        mov     cx, 0                   ; attrib
        int     21h
        mov     bx, ax

        i=dataz
        rept 6
        xor     dx, dx
        mov     cx, blks
        mov     ax, i
        mov     ds, ax
        mov     ax, 4000h
        int     21h
        i=i+3300
        endm
        mov     ah, 3Eh                 ; close
        int     21h

        cld
        push    cs cs
        pop     ds es
        mov     dx, offset fname
        mov     bx, offset nolla
;        mov     di, 0
;        mov     si, 0
        mov     ax, 4b00h
        int     21h

        push    cs
        pop     ds
        mov     dx, offset fname
        mov     ah, 41h
;        int     21h                     ; delete

        mov     ax, 4C00h
        int     21h

fname   db 'c:\@$perma_.exe',0

nolla   db 0

ends

segment dataz use16
        db '_exe_here_'
        db (blks*6) dup (0)
ends

segment pinoz stack
        db 1024 dup (?)
ends
        end start
