quiet=0
forceshit=0             ; vga shit mode forced even if vesa hicolor found
poorvga=0               ; 160x400 or 320x400
scramble=1

smbeef equ 01000000h

        ideal
        p486
        model flat, c

macro   dealloc
        mov     ax, 0EE40h
        int     31h
        jc      memerror
endm

macro   malloc memptr, size
;        local @@baska
;        cmp     memptr, 0
;        jnz     @@baska
        mov     edx, &size
        mov     ax, 0EE42h
        int     31h
        jc      memerror
        mov     memptr, edx
;@@baska:
endm

extrn   build_bumpshade:near
extrn   build_tunnel:near
extrn   build_flare:near
extrn   build_flaresize:near

;extrn Debug:near

extrn xmpInit:near
extrn xmpPlay:near
extrn xmpStop:near
extrn xmpGetTimer:near
extrn xmpGetPos:near


        stack 1000h
        codeseg

framereduce dd 0
framereduce2 dd 0

proc    getframe
        call    xmpGetTimer
        mov     ebx, 17000
        xor     edx, edx
        div     ebx
;        shr     eax, 1
        mov     edx, eax
        sub     eax, [framereduce]
        mov     [framecount], eax

        ret
endp

macro   checkesc
;;        mov     ah, 1
;;        int     16h
;;        jnz     @@exitdos
        in      al, 60h
        cmp     al, 1
        jz      exitdos
endm

macro   writeln n
        local @@1
if quiet eq 0
        call    @@1
        db n, 13, 10, '$'
@@1:
        pop     edx
        mov     ah,9
        int     21h
endif
endm

; DOS32's vesa stuff... eternally useful?
masm
include vesa.inc
ideal

LINptr          DD 0            ; linear code segment address
LFBptr          DD 0            ; linear frame buffer
PSPptr          dd 0
ENVptr          dd 0            ; environment block (for ultrasnd probe)

vga15bitptr     dd 0            ; 15bit to vga fake conversion
hicolorcutptr   dd 0            ; color cutting table for 15bit
screenbufptr    dd 0
tunneltableptr  dd 0
tmpptr          dd 0
flaresizeptr    dd 0

framecount      dd 0
framez          dd 0

fadepos1        dw 0
fadepos2        dw 0

logofade1       db 32 dup (0)
logofade2       db 32 dup (0)
doublelines     db 0

proc    clear_shit
        cld
        mov     ecx, 320*200*2/4
        xor     eax, eax
        mov     edi, [screenbufptr]
        rep     stosd
        ret
endp



build_fade:
        mov     cl, 32
        xor     edx, edx
@@f1:
        mov     [edi], dh
        inc     edi
        add     edx, eax
        dec     cl
        jnz     @@f1
        ret


build_hicolorcut:
        cld
        mov     edx, 65536*2
        mov     ax,0EE42h
        int     31h
        mov     [hicolorcutptr], edx
        mov     edi, edx
        xor     ecx, ecx
@@1:
        mov     eax, ecx
; force blue (0-63) to 0-31
        bt      eax, 5
        sbb     dl, dl
        and     dl, 30
        or      al, dl
; force green...
        bt      eax, 10
        sbb     edx, edx
        and     edx, 30 shl 5
        or      eax, edx
; force red...
        bt      eax, 15
        sbb     edx, edx
        and     edx, 30 shl 10
        or      eax, edx
        and     eax, 7bdeh              ; 0rrrr0gggg0bbbb0
        stosw
        inc     cx
        jnz     @@1
        ret
build_sine:
        cld
        mov     edi, offset cosine+8
        mov     ecx, 2046
        mov     ebx, [edi-4]
        mov     eax, ebx
@@calc:
        imul    ebx
        shrd    eax, edx, 30-1
        sub     eax, [edi-8]
        stosd
        loop    @@calc
        ret

        align 4
cosine  dd 1073741824     ; 2^30
        dd 1073736771 ;  1073740561     ; 2 ^30*cos(2ã/1024)
        dd 2046 dup (?)

logomode        db 0

db ' -- piece of junk code for lammaz without 15bit hicolor !! -- '
copy15bit:
        cmp     [logomode], 0
        jz      @@nologoz

        mov     esi, offset smlogo1+128+320*90
        mov     edi, [screenbufptr]
        add     edi, 640*90
        mov     ebp, 320*30

        mov     ebx, [hicolorcutptr]
        xor     eax, eax
        xor     ecx, ecx
        xor     edx, edx
@@zz:
        mov     dl, [esi]
        mov     cl, [esi+64128]
        mov     dl, [logofade1+edx]
        add     dl, [logofade2+ecx]
        mov     ax, [edi]
        add     ax, [bwpal+edx*2]
        mov     ax, [ebx+eax*2]
        mov     [edi], ax
        inc     esi
        add     edi, 2
        dec     ebp
        jnz     @@zz
@@pax:

@@nologoz:
        cmp     [LFBptr], 0
        jz      @@fakevga
        cld
        mov     esi, [screenbufptr]
        mov     edi, [LFBptr]
        test    [doublelines], 1
        jnz     @@dubbel
        mov     ecx, 32000
        rep     movsd
        ret
@@dubbel:

;        xor     [doublelines], 2
        mov     edx, 200
;        test    [doublelines], 2
;        jz      @@vit
;        add     edi, 640
@@vit:
        i=0
        rept 640/4
        mov     eax, [esi+i]
        mov     [edi+i], eax
        mov     [edi+i+640], eax
        i=i+4
        endm
        add     esi, 640
        add     edi, 640*2
        dec     edx
        jnz     @@vit
        ret
@@fakevga:
        mov     dx, 3c4h
        mov     ax, 0f02h
        out     dx, ax
        inc     dl

        mov     esi, [screenbufptr]
        mov     edi, 0a0000h
        sub     edi, [LINptr]

        xor     ebx, ebx
        xor     ebp, ebp

        mov     ecx, 39 shl 16
@@0:
if poorvga eq 1
        mov     ax, 0302h
endif
if poorvga eq 0
        mov     ax, 0102h
endif
        mov     dx, 3c4h
        out     dx, ax
        call    __blit
if poorvga eq 1
        add     esi, 4
endif
if poorvga eq 0
        add     esi, 2
        mov     ax, 0202h
        mov     dx, 3c4h
        out     dx, ax
        call    __blit2
        add     esi, 2
endif

if poorvga eq 1
        mov     ax, 0c02h
endif
if poorvga eq 0
        mov     ax, 0402h
endif
        mov     dx, 3c4h
        out     dx, ax
        call    __blit

if poorvga eq 1
        add     esi, 4
endif
if poorvga eq 0
        add     esi, 2
        mov     ax, 0802h
        mov     dx, 3c4h
        out     dx, ax
        call    __blit2
        add     esi, 2
endif

        add     esi, 640*5-4*2
        add     edi, 80*5*2
        sub     ecx, 10000h
        jnc     @@0
        ret

if scramble eq 0
__blit2:
endif
__blit:
        push    esi edi
        mov     ch, 5
__blit1b:
        mov     cl, 20
__blit1a:
        i=0
        mov     bx, [esi+8*2]
        mov     bp, [esi+12*2]
        mov     ax, [ebx*2+smbeef]
label __blit1hf1
        mov     dx, [ebp*2+smbeef]
label __blit1hf2
        xchg    ah, dl
        shl     eax, 16
        mov     bx, [esi]
        shl     edx, 16
        mov     bp, [esi+4*2]
        mov     ax, [ebx*2+smbeef]
label __blit1hf3
        mov     dx, [ebp*2+smbeef]
label __blit1hf4
        xchg    ah, dl
        mov     [edi], eax
        add     esi, 16*2
        add     edi, 4
        dec     cl
        mov     [edi+80-4], edx
        jnz     __blit1a
        add     edi, 80
        dec     ch
        jnz     __blit1b
        pop     edi esi
        ret

if scramble eq 1
if poorvga eq 0
__blit2:
        push    esi edi
        mov     ch, 5
__blit2b:
        mov     cl, 20
__blit2a:
        i=0
        mov     bx, [esi+8*2]
        mov     bp, [esi+12*2]
        mov     ax, [ebx*2+smbeef]
label __blit2hf1
        mov     dx, [ebp*2+smbeef]
label __blit2hf2
        xchg    ah, dl
        shl     eax, 16
        mov     bx, [esi]
        shl     edx, 16
        mov     bp, [esi+4*2]
        mov     ax, [ebx*2+smbeef]
label __blit2hf3
        mov     dx, [ebp*2+smbeef]
label __blit2hf4
        xchg    ah, dl
        mov     [edi], edx
        add     esi, 16*2
        add     edi, 4
        dec     cl
        mov     [edi+80-4], eax
        jnz     __blit2a
        add     edi, 80
        dec     ch
        jnz     __blit2b
        pop     edi esi
        ret
endif
endif

set15bitmode:
        cmp     [LFBptr], 0
        jnz     SetVbeMode
set15bitemu:                    ; 320 x 400, colors splitted
        mov     ax, 0013h
        int     10h

;        mov     dx, 3c8h
;        mov     al, 0h
;        out     dx, al

        mov     dx, 3c8h
        xor     al, al
        out     dx, al
        inc     dl
        mov     ecx, 256*3
@@bpal1:
        out     dx, al
        loop    @@bpal1

        mov     dx, 3c4h
        mov     ax, 00604h
        out     dx, ax
        mov     dl, 0d4h
        mov     ax, 00014h
        out     dx, ax
        mov     ax, 0e317h
        out     dx, ax
        mov     ax, 00009h
        out     dx, ax
        mov     dl, 0c4h
        mov     ax, 00f02h
        out     dx, ax

        cld
        push    ds
        pop     es
        mov     edi, 0a0000h
        sub     edi, [LINptr]
        xor     eax, eax
        mov     ecx, 16384
        rep     stosd

;----------------------------------------------------------------------
; @@r = red
; bl blue
; dl green
; dh red
                mov     esi, [vga15bitptr]
                sub     esi, 2
;                mov     [@@r], ah
@@1:            xor     dh, dh
@@2:            xor     dl, dl
@@3:            xor     eax, eax
                mov     al, dl
                shr     al, 1
                cmp     al, 14
                jbe     @@4
                mov     al, 14
@@4:            xor     ebx, ebx
                mov     bl, dh
                mov     ecx, ebx
                xor     ebx, ebx
                sar     ecx, 1
                mov     bl, [@@r] ; dl
                shl     ecx, 8
                sar     ebx, 1
                add     ecx,0000f000H
                add     ecx,ebx
                and     eax, 0ffh
                shl     eax, 4
                add     esi, 2
                add     eax, ecx
                mov     [word esi], ax
                inc     dl              ;dl
                cmp     dl, 32
                jb      @@3
                inc     dh              ;dh
                cmp     dh, 32
                jb      @@2
                mov     bl, [@@r]       ;bl
                inc     bl
                mov     [@@r], bl
                cmp     bl, 32
                jb      @@1

        mov     edi, [vga15bitptr]
        mov     [__blit1hf1-4], edi
        mov     [__blit1hf2-4], edi
        mov     [__blit1hf3-4], edi
        mov     [__blit1hf4-4], edi
if scramble eq 1
if poorvga eq 0
        mov     [__blit2hf1-4], edi
        mov     [__blit2hf2-4], edi
        mov     [__blit2hf3-4], edi
        mov     [__blit2hf4-4], edi
endif
endif

;----------------------------------------------------------------------
        mov     dx, 3c8h
        xor     al, al
        out     dx, al
        inc     dl

;        mov     bh, 3
        xor     bh, bh
        mov     ch, 15
@@pal1:
;        mov     bl, 3
        xor     bl, bl
        mov     cl, 16
@@pal0:
        mov     al, bl
        out     dx, al
        xor     al, al
        out     dx, al
        mov     al, bh
        out     dx, al
        add     bl, 4
        dec     cl
        jnz     @@pal0
        add     bh, 4
        dec     ch
        jnz     @@pal1

        xor     eax, eax
        mov     cl, 16
@@pal2:
        xor     al, al
        out     dx, al
        mov     al, ah
        out     dx, al
        xor     al, al
        out     dx, al
        add     ah, 4
        dec     cl
        jnz     @@pal2
        ret
@@r     db 0

startti:
        writeln 'SUPERMAX         (c) COMPLEX 1996'

        mov     ax, 0ee02h
        int     31h
        mov     [LINptr], ebx
        mov     [PSPptr], esi
        mov     [ENVptr], edi

        mov     edx, 64000*2
        mov     ax,0EE42h
        int     31h
        mov     [screenbufptr], edx

        malloc  [vga15bitptr], 65536

        sti
        cld
        push    ds
        pop     es

        call    build_sine
        call    build_hicolorcut

; for bump picture routine
        call    bumpalloc
        call    build_pictures
;        call    build_normals
        call    build_hilite
        mov     eax, [cmapptr]
        mov     edx, offset clxlogo+32
        call    build_bumpshade

        writeln ' - Measuring Galvados Factor'
        malloc  [tunneltableptr], 128000
        malloc  [tmpptr], 20000
        mov     eax, [tunneltableptr]
        mov     edx, [tmpptr]
        call    build_tunnel
        dealloc

        writeln ' - Initializing cubic tiny GUS XM player'

        mov     ecx, 17000 ; 65536
        mov     esi, offset modi_poppi
        mov     eax, [ENVptr]
        call    xmpInit

        test    edx, edx
        jnz     @@gus
        writeln ' - Pubic failed, using SoundBlaster player instead.'
;        mov     [adlib], 1
@@gus:


        writeln ' - Checking VBE 2.0 (mode 410dh)'


;        call    debug
        mov     [doublelines], 0
        mov     ax, 410dh               ; linear 320x200x15bit
        call    CheckVbeMode
        test    eax, eax
        jnz     @@ok
        mov     [doublelines], 1
        mov     ax, 412fh               ; linear 320x200x15bit
        call    CheckVbeMode
@@ok:
if forceshit eq 1
        xor     eax, eax
endif
        mov     [LFBptr], eax           ; lfb is 0 if no linear mode...
        test    eax, eax
        jnz     @@nolfb
if forceshit eq 0
        writeln ' * VESA 2.0 320x200x15bit LFB Init Failed. (Did you remember UniVBE?)'
        writeln 'Press X to go on using **SLOW** Fake VGA Hi-Color, any other to quit.'
        mov     ah, 0
        int     16h
        cmp     al, 'X'
        jz      @@nolfb
        cmp     al, 'x'
        jz      @@nolfb
        mov     ax, 4cffh
        int     21h
endif
@@nolfb:

        xor     eax,eax
        call    xmpPlay


        call    chaoszoomclear
        call    set15bitmode
        call    clear_shit
include 'skripti.asm'

exitdos:
        mov     ax,3
        int     10h

        call    xmpStop

Exit:
        mov     ax, 4c00h
        int     21h

memerror:
        writeln 'insufficient mindflow'
        mov     ax, 4c20h
        int     21h

;        call    debug


kunto   dd 0


label bwpal word
        i=0
        rept 30
        dw (i+i shl 5+i shl 10) and 7bdeh
        i=i+1
        dw (i+i shl 5+i shl 10) and 7bdeh
        endm
        rept 63
        dw (i+i shl 5+i shl 10) and 7bdeh
        endm
;        dw 256 dup (0)


include 'tuna.asm'
include 'rock.asm'
include 'filu.asm'
;include 'vesamode.asm'


        align 4

modi_poppi      db 'modi_poppi', 37000 dup (0)
smlogo1         db 'smaxlogo_1', (64128+64128) dup (0)
clxlogo         db 'complexlogo', 16800 dup (0)
huuhaatext      db 'huuhaatext', 64128 dup (0)

flare_lc        db 'flare1lc', 768 dup (0)
flare_rc        db 'flare1rc', 768 dup (0)
flare_lc2       db 'flare2lc', 768 dup (0)
flare_rc2       db 'flare2rc', 768 dup (0)
flare_lc3       db 'flare3lc', 768 dup (0)
flare_rc3       db 768 dup (128)
flare_lt        db 'flare_lt', 768 dup (0)
flare_rt        db 'flare_rt', 768 dup (0)

; hftab           dw 65536 dup (?)


End     startti
