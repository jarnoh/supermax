

        align 4
matrixtable     dd 256 dup (?)
xpos            dd 0
ypos            dd 0
mm1             dd 11000
spotlightptr    dd 0
bumpofsptr      dd 0
bumppicptr      dd 0
bumphiptr       dd 0
cmapptr         dd 0                    ; colormap 256x256 15bit

; Calculate square root of ECX
; (returns value in EBX)
macro   Sqrt
local @@SQR_NI, @@SQR_NO
        mov     eax, 040000000h
        xor     ebx, ebx
@@SQR_NI:
        lea     edx, [eax+ebx]
        shr     ebx, 1
        cmp     edx, ecx
        ja      @@SQR_NO
        or      ebx, eax
        sub     ecx, edx
@@SQR_NO:
        shr     eax, 2
        jnz     @@SQR_NI
endm


proc    build_hilite
        mov     edi, [spotlightptr]
        push    edi
        mov     ecx, 640*800/4
        xor     eax, eax
        rep     stosd

        pop     edi

        mov     [ypos], 400
@@y:
        mov     esi, [ypos]
        sub     esi, 200
        imul    esi, esi
        push    edi
        mov     ebp, 400
@@x:
        mov     ebx, ebp
        sub     ebx, 200
        imul    ebx, ebx
        lea     ecx, [ebx+esi]
        imul    ecx, 415
        shr     ecx, 8
        Sqrt
        not     bl
        cmp     bh, 1
        sbb     bh, bh
        and     bl, bh
        shr     bl, 2
        mov     [byte edi+240+200*640], bl
        inc     edi
        dec     ebp
        jnz     @@x
        pop     edi
        add     edi, 640
        dec     [ypos]
        jnz     @@y
        ret
endp

proc    build_pictures
        malloc  [bumphiptr], (64000)
; -- zoom pic to 2x2
        cld
        push    ds
        pop     es
        mov     esi, offset clxlogo+800
        mov     edi, [bumppicptr]
        mov     ch, 100
@@py:
        mov     cl, 160
@@px:
        lodsb
        mov     ah, al
        mov     [edi+320], ax
        stosw
        dec     cl
        jnz     @@px
        add     edi, 320
        dec     ch
        jnz     @@py
; copy to picture
;        mov     ecx, 64000/4
;        mov     esi, [bumppicptr]
;        mov     edi, [bumphiptr]
;        rep     movsd
; make blur filter
        xor     eax, eax
        mov     ecx, 256
        mov     edi, offset matrixtable
@@matbuild:
        stosd
        add     eax, 256/9
        loop    @@matbuild

; blur the bump image
        mov     esi, [bumppicptr]
        mov     edi, [bumphiptr]
        sub     edi, esi
        mov     ecx, 64000
@@blur:
        call    getblurvalue
        mov     [edi+esi], dh
        inc     esi
        dec     ecx
        jnz     @@blur

; proc    build_normals
        xor     eax, eax
        xor     edx, edx
        mov     ecx, 256
        mov     edi, offset matrixtable
@@matbuild2:
        stosd
        add     eax, [mm1]
        loop    @@matbuild2

        mov     esi, [bumphiptr]
        mov     edi, [bumpofsptr]
        mov     [ypos], 200
@@filt:
        mov     [xpos], 320
@@filt2:
        call    getdeltaz
        sar     ebp, 14
        sar     edx, 14
        add     ebp, [xpos]
        add     edx, [ypos]

;        sar     ebp, 1
;        sar     edx, 1

        cmp     ebp, 0
        jnl     @@sx
        xor     ebp, ebp
@@sx:
        cmp     edx, 0
        jnl     @@sy
        xor     edx, edx
@@sy:
        cmp     ebp, 639
        jng     @@sx2
        mov     ebp, 639
@@sx2:
        cmp     edx, 399
        jng     @@sy2
        mov     edx, 399
@@sy2:
        imul    edx, 640
        add     edx, ebp
        add     edx, [spotlightptr]
        mov     [edi], edx
        add     edi, 4
        inc     esi
        dec     [xpos]
        jnz     @@filt2
        dec     [ypos]
        jnz     @@filt

        cld
        mov     edx, 100
        mov     esi, offset clxlogo+800
        mov     edi, [bumppicptr]
@@1:
        mov     ecx, 160/4
        rep     movsd
        sub     esi, 160
        mov     ecx, 160/4
        rep     movsd
        dec     edx
        jnz     @@1
        dealloc
        ret
endp

getdeltaz:
        xor     eax, eax
        xor     edx, edx
        xor     ebp, ebp
; y delta... (3x5)
;        mov     al, [esi]
;        imul    ebx, eax, -256

        mov     al, [esi-1-320]
        sub     edx, [eax*4+matrixtable]
        mov     al, [esi-320]
        sub     edx, [eax*4+matrixtable]
        mov     al, [esi+1-320]
        sub     edx, [eax*4+matrixtable]
        mov     al, [esi+320-1]
        add     edx, [eax*4+matrixtable]
        mov     al, [esi+320]
        add     edx, [eax*4+matrixtable]
        mov     al, [esi+320+1]
        add     edx, [eax*4+matrixtable]
        mov     al, [esi-1-320]
        sub     ebp, [eax*4+matrixtable]
        mov     al, [esi-1]
        sub     ebp, [eax*4+matrixtable]
        mov     al, [esi-1+320]
        sub     ebp, [eax*4+matrixtable]
        mov     al, [esi+1-320]
        add     ebp, [eax*4+matrixtable]
        mov     al, [esi+1]
        add     ebp, [eax*4+matrixtable]
        mov     al, [esi+1+320]
        add     ebp, [eax*4+matrixtable]
        ret

getblurvalue:
        xor     eax, eax
        xor     edx, edx
        xor     ebp, ebp
i=-1
rept 3
j=-1
rept 3
        mov     al, [esi+i+j*320]
        add     edx, [eax*4+matrixtable]
j=j+1
endm
i=i+1
endm
        ret


proc    movemental
        mov     eax, [framecount]
        imul    ecx, eax
        imul    edx, eax
        shr     ecx, 7
        shr     edx, 7
        add     ecx, 2048
        and     ecx, 2047*4
        and     edx, 2047*4
        mov     edi, [cosine+edx]
        sar     edi, 23
        add     edi, 256
        imul    edi, 640
        mov     eax, [cosine+ecx]
        sar     eax, 23
        add     eax, 256
        add     edi, eax
        ret
endp


bumprout:
        mov     ecx, -700
        mov     edx, 1373
        call    movemental
        mov     [__bufspot1a-4], edi
        mov     [__bufspot1b-4], edi

        mov     ecx, 1100
        mov     edx, 680
        call    movemental
        mov     [__bufspot2a-4], edi
        mov     [__bufspot2b-4], edi

        mov     ecx, -1400
        mov     edx, -554
        call    movemental
        mov     [__bufspot3a-4], edi
        mov     [__bufspot3b-4], edi

;
;@@poks:
;        mov     ax, 3
;        int     33h
;        and     ecx, 0ffffh
;        and     edx, 0ffffh
;        add     edx, 16
;        imul    eax, edx, 640
;        mov     edi, ecx
;        add     ecx, eax
;;        mov     [__bufspot1a-4], ecx
;;        mov     [__bufspot1b-4], ecx
;
;        imul    eax, edx, 640
;        neg     edi
;        add     edi, eax
;        sub     edi, 640
;;        mov     [__bufspot2a-4], edi
;;        mov     [__bufspot2b-4], edi
;


        xor     eax, eax
        xor     edx, edx
        xor     ecx, ecx
        xor     edi, edi
        mov     esi, 320*196/2
__bumpper:
        mov     ebx, [esi*8+smbeef]             ; bump "position"
label __bufofs2
        mov     al, [esi+smbeef]                ; detail picture
label __bufpic
        mov     cl, al
        mov     dl, al
        mov     ah, [ebx+smbeef]
label __bufspot1a
        mov     ch, [ebx+smbeef]
label __bufspot2a
        mov     dh, [ebx+smbeef]
label __bufspot3a
        mov     ebx, [esi*8+smbeef]
label __bufofs1
        mov     di, [word eax*2+smbeef]
label __cmap1
        add     di, [word ecx*2+smbeef]
label __cmap2
        mov     di, [edi*2+smbeef]
label __hcc1
        add     di, [word edx*2+smbeef]
label __cmap3
        mov     bp, [edi*2+smbeef]
label __hcc2
;---------
        mov     ah, [ebx+smbeef]
label __bufspot1b
        shl     ebp, 16
        mov     ch, [ebx+smbeef]
label __bufspot2b
        mov     dh, [ebx+smbeef]
label __bufspot3b
        mov     di, [word eax*2+smbeef]
label __cmap4
        add     di, [word ecx*2+smbeef]
label __cmap5
        mov     di, [edi*2+smbeef]
label __hcc3
        add     di, [word edx*2+smbeef]
label __cmap6
        mov     bp, [edi*2+smbeef]
label __hcc4
;---------
;        add     ebp, [esi*4+smbeef]
;label __bufscr2
;        shr     ebp, 1
;        and     ebp, 7bde7bdeh
        mov     [esi*4+smbeef], ebp
label __bufscr
        dec     esi
        jnz     __bumpper
        ret

bumpdealloc:
        dealloc
        dealloc
        dealloc
        dealloc
        ret
bumpalloc:
        malloc  [spotlightptr], (640*800)
        malloc  [bumppicptr], (64000)
        malloc  [bumpofsptr], (64000*4)
        malloc  [cmapptr], (256*256*2)

; selfmodifying...
        mov     edi, [screenbufptr]
        add     edi, 640*3
        mov     [__bufscr-4], edi
;        mov     [__bufscr2-4], edi

        mov     edi, [bumpofsptr]
        add     edi, 320*2*4
        mov     [__bufofs1-4], edi
        add     edi, 4
        mov     [__bufofs2-4], edi

        mov     edi, [bumppicptr]
        add     edi, 320*2
        mov     [__bufpic-4], edi

        mov     edi, [cmapptr]
        mov     [__cmap1-4], edi
        mov     [__cmap4-4], edi
        add     edi, 64*256*2
        mov     [__cmap2-4], edi
        mov     [__cmap5-4], edi
        add     edi, 64*256*2
        mov     [__cmap3-4], edi
        mov     [__cmap6-4], edi

        mov     edi, [hicolorcutptr]
        mov     [__hcc1-4], edi
        mov     [__hcc2-4], edi
        mov     [__hcc3-4], edi
        mov     [__hcc4-4], edi
        ret

;        align 4
;colormap        dw 256*256 dup (0)
; picture         db 64800 dup (0)
; bumppi          db 64800 dup (0)
; offsetbuf       dd 64000 dup (?)
