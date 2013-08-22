flareptr        dd 0
flaresizepos    dd 0
skalatableptr   dd 0

flabakoko       dd 5120

flarelcptr      dd 0
flarercptr      dd 0

initflabaz:
;        call    clear_shit
;        call    copy15bit
;        mov     [flaresizepos], 0
        mov     edi, offset flare_lt
        xor     al, al
@@g1:
        stosb
        stosb
        stosb
        inc     al
        jnz     @@g1


; void build_flare(byte *shadetab, byte *rc, byte *lc, byte *lt) {
        mov     eax, [flareptr]
        mov     edx, [flarelcptr] ; offset flare_rc
        mov     ebx, [flarercptr] ; offset flare_lc
        mov     ecx, offset flare_lt
        call    build_flare

        ret

makeflaresize:
        mov     esi, [flaresizeptr]
        xor     edi, edi
@@1:
        mov     cl, 8
        call    random
        mov     [esi+edi], al
        inc     di
        jnz     @@1
        ret

flabaskaletab:
        mov     esi, [flaresizeptr]
        mov     eax, [framecount]
        shl     eax, 6
        and     eax, 0ff00h
        add     esi, eax

        mov     edi, [skalatableptr]
        xor     ebp, ebp
        xor     eax, eax
        xor     edx, edx
@@f0:
        xor     ecx, ecx
        mov     cl, [esi]
        inc     esi
        imul    ecx, [flabakoko]
        shr     ecx, 8
        test    ch, ch
        jnz     @@safetymode
        xor     ebx, ebx
@@f1:
        mov     [eax+edi], bh
        add     ebx, ecx
        inc     ah
        jnz     @@f1
@@f2:
        inc     al
        jnz     @@f0
        ret
        align 4
@@safetymode:
        xor     ebx, ebx
@@f1b:
        mov     [eax+edi], bh
        add     ebx, ecx
        test    bh, bh
        js      @@f1c
        inc     ah
        jnz     @@f1b
        inc     al
        jnz     @@f0
        ret
;        test    ah, ah
;        jz      @@f2b
        align 4
@@f1c:
        mov     [eax+edi], bh
        inc     ah
        jnz     @@f1c
@@f2b:
;        xor     ah, ah
        inc     al
        jnz     @@f0
        ret
อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

runflaba:
        cmp     [flarey], 200
        jge     @@no
        cmp     [flarey], -200
        jle     @@no

        mov     esi, [skalatableptr]
        mov     [@@sk1-4], esi
        mov     [@@sk2-4], esi

        mov     esi, [flareptr]
        mov     [@@fl1-4], esi
        mov     [@@fl2-4], esi

        mov     ebp, [screenbufptr]
        mov     esi, [tunneltableptr]
        mov     edi, 200                ; lines to do


        cmp     [flarey], 0
        jge     @@cutbot
        mov     eax, [flarey]
        add     edi, eax
        neg     eax
        imul    eax, 640
        add     esi, eax
        jmp     @@go
@@cutbot:
        mov     eax, [flarey]
        sub     edi, eax
        imul    eax, 640
        add     ebp, eax
        jmp     @@go
@@go:
        imul    edi, 160

;        mov     ebp, [screenbufptr]
;        mov     esi, [tunneltableptr]
        mov     [@@sb-4], ebp
        mov     [@@tt1-4], esi
        add     esi, 2
        mov     [@@tt2-4], esi

        mov     eax, [flarerota]
        xor     ebx, ebx
        xor     ecx, ecx
        dec     edi
        js      @@no
        align 4
@@xx:
        mov     bx, [edi*4+12345678h]           ; mov     esi, [tunneltableptr]
label   @@tt2 dword
        mov     cx, [edi*4+12345678h]
label   @@tt1 dword
        add     bl, al
        add     cl, al

        mov     bh, [ebx+12345678h]             ; mov     esi, [skalatableptr]
label   @@sk1 dword
        mov     ch, [ecx+12345678h]
label   @@sk2 dword

        mov     ebp, [ebx*2+12345678h]          ; mov     esi, [flareptr]
label   @@fl1 dword
        mov     bp, [ecx*2+12345678h]
label   @@fl2 dword

        mov     [ds:edi*4+12345678h], ebp       ; mov     esi, [screenbufptr]
label   @@sb dword
        dec     edi
        jns     @@xx
@@no:
        ret

flarey  dd 0
flarerota  dd 0
