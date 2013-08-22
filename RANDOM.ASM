proc    random
; input
;       cl bits
; output
;       eax random

        push    ebx edx
        xor     eax, eax
        mov     bl, [byte @@rndseed]
        and     bl, 1
@@1:
        add     eax, eax
        mov     edx, [@@rndseed]
        shr     edx, 9
        xor     bl, dl
        shr     edx, 5
        xor     bl, dl
        bt      ebx, 1
        rcr     [@@rndseed], 1
        setc    bl
        or      al, bl
        dec     cl
        jnz     @@1
        pop     edx ebx
        ret
@@rndseed       dd 0b36f98a7h
endp
