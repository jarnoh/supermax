
        malloc  [flareptr], (65536*2)
        malloc  [skalatableptr], 65536
        malloc  [flaresizeptr], 65536

        mov     [flarelcptr], offset flare_rc2
        mov     [flarercptr], offset flare_lc
        call    initflabaz
        call    makeflaresize
        mov     eax, [flaresizeptr]
        mov     edx, 2
        mov     ebx, 13
        call    build_flaresize

;        jmp     @@tahna
@@flaba1:
        call    getframe
        sub     eax, 1400
        neg     eax
        jns     @@ohfuck
        xor     eax, eax
@@ohfuck:
        imul    eax, eax
        shr     eax, 9
        mov     [flabakoko], eax
        call    flabaskaletab
        call    runflaba
        call    copy15bit
        checkesc
;        jmp     @@flaba1
        call    xmpGetPos
        cmp     ax, 0100h
        jb      @@flaba1

;        dealloc
;        dealloc

;        jmp     @@flarepart3
;        jmp     @@baska

;@@part1:
;        call    getframe
;        call    chaoszoom
;        call    copy15bit
;        checkesc
;        call    xmpGetPos
;        cmp     ax, 0100h
;        jb      @@part1

        call    chaoswhite

@@part2:
        call    getframe
        call    chaoszoom
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0120h
        jb      @@part2
;อออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
        mov     [logomode], 1
        call    getframe
        mov     [kunto], eax
@@part3:
        call    getframe
        sub     eax, [kunto]
        imul    eax, 2
        cmp     eax, 511
        jb      @@2
        mov     eax, 511
@@2:
        mov     edi, offset logofade2
        call    build_fade
        call    chaoszoom
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0200h
        jb      @@part3
;-----
        call    getframe
        mov     [kunto], eax
@@part3b:
        call    getframe
        sub     eax, [kunto]
        imul    eax, 3
        cmp     eax, 511
        jb      @@2b
        mov     eax, 511
@@2b:
        mov     edi, offset logofade1
        call    build_fade
        call    chaoszoom
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0220h
        jb      @@part3b
;-----
        call    getframe
        mov     [kunto], eax
@@part3c:
        call    getframe
        sub     eax, [kunto]
        imul    eax, 3
        cmp     eax, 511
        jb      @@2c
        mov     eax, 511
@@2c:
        sub     eax, 511
        neg     eax
        mov     edi, offset logofade2
        call    build_fade
        call    chaoszoom
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0300h
        jb      @@part3c
;-----
        xor     eax, eax
        mov     edi, offset logofade2
        call    build_fade

        call    getframe
        mov     [kunto], eax
@@part3d:
        call    getframe
        sub     eax, [kunto]
        imul    eax, 3
        cmp     eax, 511
        jb      @@2d
        mov     eax, 511
@@2d:
        sub     eax, 511
        neg     eax
        mov     edi, offset logofade1
        call    build_fade
        call    chaoszoom
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0320h
        jb      @@part3d
;-----
        mov     [logomode], 0

        xor     eax, eax
        mov     edi, offset logofade1
        call    build_fade

        call    chaoswhite
@@part4:
        call    getframe
        call    chaoszoompsyke
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0400h
        jb      @@part4
        call    chaoswhite
@@part4b:
        call    getframe
        call    chaoszoom
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0420h
        jb      @@part4b
        call    chaoswhite
@@part4c:
        call    getframe
        call    chaoszoomzoom
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0500h
        jb      @@part4c

@@baska:

        call    clear_shit
@@part5:
        call    getframe
        call    bumprout
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0900h
        jb      @@part5
        call    bumpdealloc

;@@part6:
;        call    getframe
;        call    chaoszoom
;        call    copy15bit
;        checkesc
;        call    xmpGetPos
;        cmp     ax, 0d3fh
;        jb      @@part6
@@poks:
        call    clear_shit
        call    copy15bit
อออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
@@flarepart2:
        call    makeflaresize
        mov     eax, [flaresizeptr]
;        mov     edx, 16
;        mov     ebx, 12
        mov     edx, 19
        mov     ebx, 12
        call    build_flaresize


        mov     [flarelcptr], offset flare_rc
        mov     [flarercptr], offset flare_lc2
        call    initflabaz
        call    getframe
        mov     [framereduce], edx
@@flaba:
        call    getframe
        sub     eax, 570
        neg     eax
        jns     @@ohfuck2
        xor     eax, eax
@@ohfuck2:
        mov     ebx, eax
        imul    ebx, eax
        imul    eax, eax
        sar     ebx, 11
        mov     [flarey], ebx
        sar     eax, 6
        mov     [flabakoko], eax
        call    flabaskaletab
        call    runflaba
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0a00h
        jb      @@flaba


@@flarepart3:
        mov     [flarelcptr], offset flare_rc3
        mov     [flarercptr], offset flare_lc
        call    initflabaz
        call    getframe
        mov     [framereduce], edx
@@flaba3:
        call    getframe
        cmp     eax, 600
        jb      @@ohfuck3
        mov     eax, 600
@@ohfuck3:
        mov     ebx, eax
        imul    ebx, eax
        imul    eax, eax
        sar     ebx, 11
        neg     ebx
        mov     [flarey], ebx
        sar     eax, 7
        mov     [flabakoko], eax
        call    flabaskaletab
        call    clear_shit
        call    runflaba
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0b00h
        jb      @@flaba3

        mov     [flarey], 0
        mov     [flarelcptr], offset flare_rc3
        mov     [flarercptr], offset flare_lc2
        call    initflabaz
        call    getframe
        mov     [framereduce], edx
@@flaba4:
        call    getframe
        mov     [flarerota], eax
        shl     eax, 5
        and     eax, 2047*4
        mov     eax, [cosine+eax]
        sar     eax, 22
        add     eax, 412
        cmp     eax, 0
        jg      @@norsu
        xor     eax, eax
@@norsu:
        mov     [flabakoko], eax

        call    flabaskaletab
        call    runflaba
        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0c00h
        jb      @@flaba4

@@tahna:
        call    clear_shit
        call    copy15bit

        mov     [flabakoko], 400
        mov     [flarelcptr], offset flare_rc
        mov     [flarercptr], offset flare_lc3
        call    initflabaz

        call    makeflaresize
        mov     eax, [flaresizeptr]
        mov     edx, 8
        mov     ebx, 8
        call    build_flaresize

        call    getframe
        mov     [framereduce], edx
@@flaba5:
        call    getframe
;        neg     eax
;        sar     eax, 1
;        mov     [flarerota], eax

        call    getframe
        imul    eax, 9
        and     eax, 2047*4
        mov     eax, [cosine+eax]
        sar     eax, 24
        mov     [flarerota], eax

        call    flabaskaletab
        call    runflaba

        mov     esi, offset huuhaatext+200+320*150+128
        mov     edi, 640*150+400
        add     edi, [screenbufptr]
        mov     ebx, [hicolorcutptr]
        xor     eax, eax
        mov     ch, 50
@@yy1:
        mov     cl, 120
@@xx1:
        mov     dx, [edi]
        mov     al, [esi]
        and     dx, 7bdeh
        inc     esi
        add     dx, [bwpal+eax*4]
        mov     dx, [edx*2+ebx]
        mov     [edi], dx
        add     edi, 2
        dec     cl
        jnz     @@xx1
        add     edi, 2*(320-120)
        add     esi, (320-120)
        dec     ch
        jnz     @@yy1

        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0d00h
        jb      @@flaba5

;        mov     ecx, [framereduce]
        call    getframe
        mov     [framereduce2], edx
@@flaba6:
        call    getframe
        mov     ebx, edx
        sub     ebx, [framereduce2]
        imul    eax, 9
        and     eax, 2047*4
        mov     eax, [cosine+eax]
        sar     eax, 24
        mov     [flarerota], eax
        cmp     ebx, 1400
        jb      @@ohfuckz
        mov     ebx, 1400
@@ohfuckz:
        imul    ebx, ebx
        shr     ebx, 5
        add     ebx, 400
        mov     [flabakoko], ebx



        call    flabaskaletab
        call    runflaba

        mov     esi, offset huuhaatext+200+320*150+128
        mov     edi, 640*150+400
        add     edi, [screenbufptr]
        mov     ebx, [hicolorcutptr]
        xor     eax, eax
        mov     ch, 50
@@yy1b:
        mov     cl, 120
@@xx1b:
        mov     dx, [edi]
        mov     al, [esi]
        and     dx, 7bdeh
        inc     esi
        add     dx, [bwpal+eax*4]
        mov     dx, [edx*2+ebx]
        mov     [edi], dx
        add     edi, 2
        dec     cl
        jnz     @@xx1b
        add     edi, 2*(320-120)
        add     esi, (320-120)
        dec     ch
        jnz     @@yy1b

        call    copy15bit
        checkesc
        call    xmpGetPos
        cmp     ax, 0d3fh
        jb      @@flaba6

;        dealloc
;        dealloc
