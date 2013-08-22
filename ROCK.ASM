r=(2 shl 10)
g=(2 shl 5)
b=2

label molota dword
        dd 21, r
        dd 12, g+b
        dd 14, r+g
        dd 21, b
        dd 12, r+g
        dd  8, g
        dd 0

my=340
mx=460
;kolor   = 2 shl 20+2 shl 15+4 shl 10+2 shl 5+2
kolor   = 4 shl 20+2 shl 15+4 shl 10+2 shl 5+2
kolor   = 2 shl 10

molokoko= 8                   ; 9
xsize   = 384
ysize   = 256+32
blksize = 16

;global  chaosdots:dword
;global  chaoszoomclear:near
;global  chaoszoom:near

include 'random.asm'

proc    chaoszoomclear
        push    ds
        pop     es
        cld

; alloc some memory
        mov     ebp, xsize*ysize*2

        mov     edx, ebp
        mov     ax,0EE42h
        int     31h
        mov     [dispbuf], edx
        mov     edx, ebp
        mov     ax,0EE42h
        int     31h
        mov     [drawbuf], edx
        mov     edx, ebp
        mov     ax,0EE42h
        int     31h
        mov     [blurbuf], edx


        xor     eax, eax
        mov     edi, [dispbuf]
        mov     ecx, xsize*ysize*2/4
        rep     stosd
        xor     eax, eax
        mov     edi, [drawbuf]
        mov     ecx, xsize*ysize*2/4
        rep     stosd
        xor     eax, eax
;        mov     eax, 30+30 shl 5+16 shl 10
        mov     edi, [blurbuf]
        mov     ecx, xsize*ysize*2/4
        rep     stosd

        mov     edx, 1023
@@1:
        mov     cl, 8
        call    random
        mov     [ransu+edx], al
        dec     edx
        jns     @@1


        ret
endp

ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ
nasta:
        add     ecx, 2048
        and     ecx, 2047*4
        and     edx, 2047*4
        mov     eax, [cosine+ecx]
        sar     eax, 16
        imul    eax, my
        sar     eax, 16
;        imul    eax, 5
;        sar     eax, 9
        add     eax, 96
        imul    ebx, eax, xsize*2
        mov     eax, [cosine+edx]
        sar     eax, 16
        imul    eax, mx
        sar     eax, 16
        add     ebx, [blurbuf]
        lea     ebx, [eax*2+ebx]
        i=-molokoko
        rept molokoko*2
          j=-molokoko
          rept molokoko*2
            if (i*i+j*j) le (molokoko*molokoko)
              add     [ebx+xsize+j*2+i*xsize*2], bp
            endif
            if (i*i+j*j) le ((molokoko*3/4)*(molokoko*3/4))
              add     [ebx+xsize+j*2+i*xsize*2], bp
            endif
            j=j+1
          endm
          i=i+1
        endm
        ret

kunt    dd 0

proc    chaoswhite
        mov     ecx, xsize*ysize*2/4
        mov     edi, [blurbuf]
        mov     esi, [dispbuf]
        sub     esi, edi
@@1:
        mov     [dword edi], 7bde7bdeh
        mov     [dword esi+edi], 7bde7bdeh
        add     edi, 4
        dec     ecx
        jnz     @@1
        ret
endp

moloz:
@@mainloop:
        push    esi
        xor     edx, edx
        mov     ecx, [framecount]
        add     ecx, 1234567
        mov     dl, [esi]
        add     edx, 34
        imul    edx, ecx
        xor     eax, eax
        mov     al, [esi+1]
        add     eax, 34
        imul    ecx, eax
        shr     edx, 5
        shr     ecx, 5
        call    nasta
        pop     esi
        add     esi, 2
        dec     [kunt]
        jns     @@mainloop
        ret


chaoszoomzoom:
        mov     [nakki], 2
        jmp     chaoszoom2
chaoszoompsyke:
        mov     [nakki], 1
        jmp     chaoszoom2
proc    chaoszoom
        mov     [nakki], 0
chaoszoom2:
        push    ds
        pop     es

;        call    debug

        mov     esi, offset ransu
        mov     ebp, offset molota
        push    ebp
@@mololoop:
        mov     ebp, [esp]
        mov     eax, [ds:ebp]
        test    eax, eax
        jz      @@pois
        mov     [kunt], eax
        add     [dword esp], 8
        mov     ebp, [ds:ebp+4]
        push    offset @@mololoop
        jmp     moloz
@@pois:
        pop     ebp

;        mov     ax, 3
;        int     33h
;        test    bx, 1
;        jz      @@maunu
;        call    chaoswhite
;@@maunu:
        push    offset @@bak
        cmp     [nakki], 1
        jz      psyke
        cmp     [nakki], 2
        jz      zoomzoom
        jmp     zoom
@@bak:
        call    blur
        inc     [framecount]
        push    [drawbuf] [dispbuf]
        pop     [drawbuf] [dispbuf]
        mov     edi, [blurbuf]
        ret
nakki db 0
endp

ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ

psyke:
        mov     edx, [framecount]
        xor     eax, eax
        rept 4
        shr     edx, 1
        rcl     eax, 1
        endm
        mov     [binv], eax
        mov     [x], eax
        mov     [zy], -11
@@xloop:
        mov     [zx], -9
        mov     edx, [binv]
@@yloop:
        mov     edi, edx
        mov     esi, edx
        imul    edi, xsize
        add     edi, [x]                ; destination = y*256+x

        sub     esi, [zx]
        sub     esi, [zy]             ; zoom !! sub
        imul    esi, xsize              ; sourceY=(Y-zx-zy)*256
        add     esi, [x]
        sub     esi, [zy]
;        add     esi, [zx]               ; sourceX=X-zx+zy ; zoom !!!

; hicolor...
        add     esi, esi
        add     edi, edi

        add     esi, [dispbuf]
        add     edi, [drawbuf]

        rept 16
        rept 8
        movsd
        endm
        add     esi, (xsize-16)*2
        add     edi, (xsize-16)*2
        endm

        add     edx, blksize
        inc     [zx]
        cmp     edx, ysize-blksize
        jb      @@yloop

        add     [x], blksize
        inc     [zy]
        cmp     [x], xsize-blksize
        jb      @@xloop
        ret
อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
zoom:
        mov     edx, [framecount]
        xor     eax, eax
        rept 4
        shr     edx, 1
        rcl     eax, 1
        endm
        mov     [binv], eax
        mov     [x], eax
        mov     [zy], -11
@@xloop:
        mov     [zx], -9
        mov     edx, [binv]
@@yloop:
        mov     edi, edx
        mov     esi, edx
        imul    edi, xsize
        add     edi, [x]                ; destination = y*256+x

        sub     esi, [zx]
        sub     esi, [zy]             ; zoom !! sub
        imul    esi, xsize              ; sourceY=(Y-zx-zy)*256
        add     esi, [x]
        sub     esi, [zy]
        add     esi, [zx]               ; sourceX=X-zx+zy ; zoom !!!

; hicolor...
        add     esi, esi
        add     edi, edi

        add     esi, [dispbuf]
        add     edi, [drawbuf]

        rept 16
        rept 8
        movsd
        endm
        add     esi, (xsize-16)*2
        add     edi, (xsize-16)*2
        endm

        add     edx, blksize
        inc     [zx]
        cmp     edx, ysize-blksize
        jb      @@yloop

        add     [x], blksize
        inc     [zy]
        cmp     [x], xsize-blksize
        jb      @@xloop
        ret
อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
zoomzoom:
        mov     edx, [framecount]
        xor     eax, eax
        rept 4
        shr     edx, 1
        rcl     eax, 1
        endm
        mov     [binv], eax
        mov     [x], eax
        mov     [zy], -11
@@xloop:
        mov     [zx], -9
        mov     edx, [binv]
@@yloop:
        mov     edi, edx
        mov     esi, edx
        imul    edi, xsize
        add     edi, [x]                ; destination = y*256+x

        sub     esi, [zx]
;        sub     esi, [zy]               ; zoom !! sub
        imul    esi, xsize              ; sourceY=(Y-zx-zy)*256
        add     esi, [x]
        sub     esi, [zy]
;        add     esi, [zx]               ; sourceX=X-zx+zy ; zoom !!!

; hicolor...
        add     esi, esi
        add     edi, edi

        add     esi, [dispbuf]
        add     edi, [drawbuf]

        rept 16
        rept 8
        movsd
        endm
        add     esi, (xsize-16)*2
        add     edi, (xsize-16)*2
        endm

        add     edx, blksize
        inc     [zx]
        cmp     edx, ysize-blksize
        jb      @@yloop

        add     [x], blksize
        inc     [zy]
        cmp     [x], xsize-blksize
        jb      @@xloop
        ret
อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

blur:
        mov     ebp, 7bde7bdeh
        mov     esi, [drawbuf]
        mov     edi, [blurbuf]
        add     esi, xsize*60*2
        sub     esi, edi
        add     edi, (xsize-320)
        mov     ebx, [screenbufptr]
        mov     ch, 200
@@blur_y:
        mov     cl, 160
;        align 16
@@blur_x:
        mov     eax, [edi]
        add     eax, [esi+edi]
        shr     eax, 1
        and     eax, ebp
;        add     eax, [esi+edi]
;        shr     eax, 1
        add     edi, 4
;        and     eax, ebp
        mov     [edi-4], eax
        mov     [dword ebx], eax
        add     ebx, 4
        dec     cl
        mov     [esi+edi-4], eax
        jnz     @@blur_x
        add     edi, (xsize-320)*2
        dec     ch
        jnz     @@blur_y
        ret

        align 4
drawbuf         dd 0;offset screenbuf1
dispbuf         dd 0;offset screenbuf2
blurbuf         dd 0
rnd1            dd 0925c9425h
rnd2            dd 0d1e0fa57h
zx              dd ?
zy              dd ?
binv            dd ?
x               dd ?
y               dd ?
tmp             dd ?

ransu           db 1024 dup (0)

