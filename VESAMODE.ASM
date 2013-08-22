masm
Include vesa.inc

align 4
VBE_BytesPerScanLine    DD 0
VbeSetBank              DD Offset SetBank_RealMode
VbeSetStart             DD Offset SetStart_RealMode
Old_PhysBasePtr         DD -1

;_BSS SEGMENT
PmodeSetStart           DD 0
file_buffer             DD 0
ProgramBaseAddress      DD 0
_BankSetTable           DD 128 DUP (0)
VideoModeNumber         DW 0
Total64Kbocks           DW 0
Current_Bank            DB 0
VBE_StarPerPixelFactor  DB 0
DOS_segs LABEL DWORD
Real_ES     DW  0
Real_DS     DW  0
;_BSS ENDS

;--------------------------------------------------------
; Call real mode set video bank function
; Note: very very slow....
;----------------------------------------------------------
SetBank_RealMode PROC
        push   ebx
        xor    ebx,ebx
        mov    ax,04F05h
        int    10h
        pop    ebx
        Ret
SetBank_RealMode ENDP

;--------------------------------------------------------
; Call real mode set display start bank function
; CX=pixel in scan line
; DX=scan line number
; Note: very very slow....
;----------------------------------------------------------
SetStart_RealMode PROC
        push   ebx
        xor    ebx,ebx
        mov    ax,04F07h
        int    10h
        pop    ebx
        Ret
SetStart_RealMode ENDP


;--------------------------------------------------------
; Call Protected mode set display start bank function
; ECX=pixel in scan line
; EDX=scan line number
;----------------------------------------------------------
SetStart_ProtectedMode PROC
        push   ebx
        xor    ebx,ebx
        imul   edx,[VBE_BytesPerScanLine]
        add    edx,ecx
        mov    cl,[VBE_StarPerPixelFactor]
        shr    edx,cl
        mov    cx,dx
        shr    edx,16
        mov    ax,04F07h
        Call   [PmodeSetStart]
        pop    ebx
        Ret
SetStart_ProtectedMode ENDP

;------------------------------------------------------------
; Procudure to call a DOS interrupt.
;
; Expects the intrrupt number pushed on the stack.
;
;  e.g    push  10h
;         call  DOSinterrupt
;         jc   error
; Real mode ES and DS registers are passed via varibles Real_ES and Real_DS.
;
;
; As explained in the DOS32 documentaion, DOS32 initally handles all interrupts
; such that calling a protected mode interrupt will automatically call
; the same interrupt number in real mode.  However, using this method there
; is no way to specify the values of the real mode SEGMENT registers.
; Some of the VESA calls require ES:DI to point to buffers and so
; we need to use INT31h AX=300h service to call a real mode interrupt.
; The procedure below does exactly that...
;
;------------------------------------------------------------
DOSinterrupt PROC
        push    dword ptr 0             ; ignore  SS, SP
        lea     esp,[esp - 8]           ; ignore  CS, IP ,FS, GS
        push    [DOS_segs]              ; push DS and ES
        pushfw
        pushad
        mov     edi,esp
        mov     ax,0300h
        xor     cx,cx
        movzx   Ebx,Byte Ptr [esp+36h]  ; Get int number from stack param
        int     31h                     ; Emulate Real Mode Interrupt
        popad
        popfw
        pop     [DOS_segs]              ; get DS and ES
        lea     esp,[esp+12]            ; Ignore SS,SP,CS,IP,FS,GS
        ret     4                       ; return ingnoring parameter
DOSinterrupt ENDP


;
;  VBE Function 06h - Set/Get Logical Scan Line Length
;
VbeFunc06 PROC
          mov  ax,4F06h
          int  10h
          cmp  ah,00h
          jne  @@J1
          mov  Word Ptr [VBE_BytesPerScanLine],BX
@@J1:     ret
VbeFunc06 ENDP



CheckVbeMode PROC

; Some of the vesa bios functions require a transfer of data in the
; real mode address space. The best way to do this is by taking advantage
; of the 8Kb file buffer initally setup by DOS32. As explained in the API.DOC
; this 8Kb buffer is in the real mode address space and may be use to temporary
; hold information.
;
         pushad
         mov    VideoModeNumber,ax

         mov    ax,0EE02h       ; GET REAL MODE SEGMENT OF FILE I/O BUFFER
         int    31h

         ; returns AX = real mode segment of 8Kb buffer.
         ;         EBX = program linear base address.

         mov    ProgramBaseAddress,ebx
         mov    Real_ES,ax
         And    Eax,0FFFFh
         shl    Eax,4
         sub    eax,ebx
         Mov    file_buffer,eax     ; save near address of 8Kb file buffer.


     ;
     ;  GET VESA INFORMATION
     ;
         mov    ax,4F00h
         mov    di,0            ; (real mode) ES:DI -> 256 byte buffer
         push   10h
         call   DOSinterrupt
         Cmp    AX,004Fh
         jne    NoVESA


     ;
     ; Search video mode list for 640x480x256 ( VESA mode 101h )
     ; The vesa driver Func 4F00h fills in the buffer with the information.
     ; Offset 0Eh of this buffer contains a real mode SEG:OFS of the video
     ; mode list. This list consists of each supported VESA mode and
     ; terminates with 0FFFFh.
     ;
         mov    EBP,[file_buffer]                       ; save video mem size
         mov    dx,[ VbeInfoBlock.TotalMemory + EBP]
         mov    [Total64Kbocks],dx


     ; Get the real mode far pointer of the video mode list and
     ; convert the real mode SEG:OFS address into a 32bit near pointer.
     ;
         Movzx edx,Word Ptr [ VbeInfoBlock.VideoModePtr + EBP + 2]
         shl   edx,4
         sub   edx,ProgramBaseAddress
         Movzx ebx,Word Ptr [ VbeInfoBlock.VideoModePtr + EBP ]
         add   edx,ebx                      ; EDX points to video mode list.
         mov   bx,VideoModeNumber
         and   bx,0111111111b               ; read bits 0..8
         xor eax,eax
Loop01:  Mov   ax,[Edx]                     ; Read video mode from list
         Cmp   Ax,0FFFFh
         je  @@ModeNotFound
         add   Edx,2
         cmp   Ax,Bx
         jne   Loop01


     ;
     ; Get VBE MODE information
     ; Note, the mode information block is also stored in the file buffer
     ;
        mov    ax,4F01h
        mov    cx,VideoModeNumber
        and    cx,0111111111b               ; read bits 0..8
        mov    di,0                         ; ES:DI -> 256 byte buffer
        push   10h
        call   DOSinterrupt
        Cmp    AX,004Fh
        jne   ModeNotGood


        Mov    EBP,file_buffer              ; EBP -> ModeInfoBlock


     ;
     ; Determine to use windowing or linear memory mapping.
     ;
        test    VideoModeNumber,0100000000000000b
        jz      DoWithBanks


 ; ******************************************************
 ; Setup for linear memory mapping mode.
 ; ******************************************************
        Test   [ ModeInfoBlock.ModeAttributes + EBP],10000000b
        jz     ModeNotGood
     ;
     ; Calulate a near pointer to physical linear mapping address.
     ;
         Mov    ebx,[ ModeInfoBlock.PhysBasePtr + EBP]
         Mov    eax,[Old_PhysBasePtr]
         cmp    eax,ebx
         je     Jskip06
         mov    [Old_PhysBasePtr],ebx
         mov    cx,bx
         shr    ebx,16
         mov    si,Total64Kbocks
         xor    edi,edi
         mov    ax,0800h                ; map physical memory
         int    31h
         jc     ModeNotGood
         shl    ebx,16
         mov    bx,cx
         mov    eax,ebx                 ; eax = linear address
Jskip06:
         mov    [esp+4*7],eax           ; save eax in stack
         jmp    Finished


DoWithBanks:

 ; ******************************************************
 ; Setup for windowing mode.
 ; ******************************************************

     ; check is windowing is avalible ( writable and availible )
     ;
        Test   [ ModeInfoBlock.ModeAttributes + EBP],01000000b
        jnz   ModeNotGood
        Mov    bl,[ ModeInfoBlock.WinAAttributes + EBP]
        and    bl,0000101b
        cmp    bl,0000101b
        jne   ModeNotGood

    ;
    ; Setup Bank Numbering table
    ;
        Movzx  eax,[ ModeInfoBlock.WinSize + EBP]
        Movzx  ebx,[ ModeInfoBlock.WinGranularity + EBP]
        xor    edx,edx
        div    ebx
        xor    edx,edx
        xor    ecx,ecx
@@loop01:
        mov    _BankSetTable[ECX*4],edx
        add    edx,eax
        inc    ecx
        cmp    ecx,LENGTH _BankSetTable
        jb     @@loop01


     ;
     ; Calulate 32bit linear pointer to CPU video memory WindowA
     ;
         Movzx  eax,[ ModeInfoBlock.WinASegment + EBP]
         shl    eax,4
         mov    [esp+4*7],eax           ; save eax in stack


Finished:


    ;
    ; If 32bit VBE inteface is availible then use the bloody thing
    ;
        mov    ax,4F0Ah
        mov    BL,0                 ; return pmode interface
        push   10h
        call   DOSinterrupt
        Cmp    AX,004Fh
        jne    No32bitInterface
        movzx  Esi,Real_ES              ; convert ES:DI to 32bit near ptr
        shl    esi,4
        and    edi,0ffffh
        add    esi,edi
        sub    esi,ProgramBaseAddress     ; ESI -> protected mode table.

     ; Use protected mode bank proc only for zero length memory list.
     ;
        movzx  edi,Word Ptr [ESI+06]      ; get port/memory table list
        and    edi,edi
        jz     @@usePmodeBanks
@@L5:   cmp    Word Ptr [ESI+EDI],0FFFFh  ; search port list
        lea    edi,[edi+2]
        jne @@L5
        cmp    Word Ptr [ESI+EDI],0FFFFh  ; see if mem list is zero
        jne    @@SkipPmodeBanks

@@usePmodeBanks:
        movzx  eax,Word Ptr [ESI+00]
        add    eax,esi
        mov    [VbeSetBank],eax         ; save Set Bank code address.

@@SkipPmodeBanks:


      ; Save Set display start code address.
      ;
        movzx  eax,Word Ptr [ESI+02]
        add    eax,esi
        mov    [PmodeSetStart],eax
        mov    [VbeSetStart],Offset SetStart_ProtectedMode


      ; Get bytes per scan line for the protected mode SetStart function.
      ;
        mov    ax,[ ModeInfoBlock.BytesPerScanLine + EBP]
        mov    Word Ptr [VBE_BytesPerScanLine],ax


      ; adjust for plane boundary for 8 bit+ modes
      ;
        mov    [VBE_StarPerPixelFactor],0
        Cmp    [ ModeInfoBlock.BitsPerPixel + EBP],4
        je @@1
        mov    [VBE_StarPerPixelFactor],2
@@1:


No32bitInterface:


         mov    eax,ProgramBaseAddress  ; convert linear pointer to near
         sub    [esp+4*7],eax
         popad
         clc
         ret



;------------------------ Error messages ---------------------------------
ModeNotGood:
         popad
         mov dl,3
         jmp Abort

@@ModeNotFound:
         popad
         mov dl,2
         jmp Abort

NoVESA:
         popad
         mov dl,1

Abort:
         xor  eax,eax
         stc
         ret

CheckVbeMode ENDP



SetVbeMode PROC
     ;
     ; Set VIDEO mode
     ;
         pushad
         xor    eax,eax
         xor    ebx,ebx
         xor    ecx,ecx
         xor    edx,edx
         mov    BX,VideoModeNumber
         mov    ax,4F02h
         Int    10h
         popad
         Ret
SetVbeMode ENDP
ideal
