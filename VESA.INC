;*****************************************************************
;
;  VESA library include file
;
;*****************************************************************

ifdef masm                                      ; Allow MASM assembly
Global  EQU     externdef
endif

Global C _BankSetTable        :Dword
Global C Current_Bank         :Byte
Global C VbeSetBank           :Dword
Global C VbeSetStart          :Dword
Global C SetVbeMode           :Near
Global C CheckVbeMode         :Near
Global C VbeFunc06            :Near




;***********************************************************
;                SET VIDEO BANK MACRO
; DL=bank number
;***********************************************************
SetBank MACRO
LOCAL @@setnew
        cmp    Current_Bank,dl
        je     @@setnew
        and    edx,01fh
        mov    Current_Bank,dl
        mov    edx,_BankSetTable[edx*4]
        push   ebx
        xor    ebx,ebx
        call   [VbeSetBank]
        pop    ebx
@@setnew:
ENDM

;***********************************************************
;       INCREMENT THE CURRENT BANK NUMEBR
;***********************************************************
NextBank   MACRO
        push    edx
        push    ebx
        xor     edx,edx
        mov     dl,Current_Bank
        inc     dl
        mov     Current_Bank,dl
        mov     edx,_BankSetTable[edx*4]
        xor     ebx,ebx
        call    [VbeSetBank]
        pop     ebx
        pop     edx
ENDM


;***********************************************************
; SET VIDEO DISPLAY START MACRO
; ECX=pixel in scan line
; EDX=scan line number
;***********************************************************
SetStart MACRO
        call   [VbeSetStart]
ENDM




; Data structure for VESA function 4F00h ( Get VBE Information )
;

     VbeInfoBlock struc
     VbeSignature        db   'VESA'    ; VBE Signature
     VbeVersion          dw   0200h     ; VBE Version
     OemStringPtr        dd   ?         ; Pointer to OEM String
     Capabilities        db   4 dup (?) ; Capabilities of graphics cont.
     VideoModePtr        dd   ?         ; Pointer to Video Mode List
     TotalMemory         dw   ?         ; Number of 64kb memory blocks
                                        ; Added for VBE 2.0
     OemSoftwareRev      dw   ?         ; VBE implementation Software revision
     OemVendorNamePtr    dd   ?         ; Pointer to Vendor Name String
     OemProductNamePtr   dd   ?         ; Pointer to Product Name String
     OemProductRevPtr    dd   ?         ; Pointer to Product Revision String
     _Reserved_          db   222 dup (?); Reserved for VBE implementation
                                        ; scratch area
     OemData             db   256 dup (?); Data Area for OEM Strings
     VbeInfoBlock ends



; Data structure for VESA function 4F01h ( Get mode Information )
;
     ModeInfoBlock   struc

     ; Mandatory information for all VBE revisions
     ModeAttributes      dw ?      ; mode attributes
     WinAAttributes      db ?      ; window A attributes
     WinBAttributes      db ?      ; window B attributes
     WinGranularity      dw ?      ; window granularity
     WinSize             dw ?      ; window size
     WinASegment         dw ?      ; window A start segment
     WinBSegment         dw ?      ; window B start segment
     WinFuncPtr          dd ?      ; pointer to window function
     BytesPerScanLine    dw ?      ; bytes per scan line

     ; Mandatory information for VBE 1.2 and above
     XResolution         dw ?      ; horizontal resolution in pixels or chars
     YResolution         dw ?      ; vertical resolution in pixels or chars
     XCharSize           db ?      ; character cell width in pixels
     YCharSize           db ?      ; character cell height in pixels
     NumberOfPlanes      db ?      ; number of memory planes
     BitsPerPixel        db ?      ; bits per pixel
     NumberOfBanks       db ?      ; number of banks
     MemoryModel         db ?      ; memory model type
     BankSize            db ?      ; bank size in KB
     NumberOfImagePages  db ?      ; number of images
     _Reserved           db ?      ; reserved for page function

     ; Direct Color fields (required for direct/6 and YUV/7 memory models)
     RedMaskSize         db ?      ; size of direct color red mask in bits
     RedFieldPosition    db ?      ; bit position of lsb of red mask
     GreenMaskSize       db ?      ; size of direct color green mask in bits
     GreenFieldPosition  db ?      ; bit position of lsb of green mask
     BlueMaskSize        db ?      ; size of direct color blue mask in bits
     BlueFieldPosition   db ?      ; bit position of lsb of blue mask
     RsvdMaskSize        db ?      ; size of direct color reserved mask in bits
     RsvdFieldPosition   db ?      ; bit position of lsb of reserved mask
     DirectColorModeInfo db ?      ; direct color mode attributes

     ; Mandatory information for VBE 2.0 and above
     PhysBasePtr         dd ?      ; physical address for flat frame buffer
     OffScreenMemOffset  dd ?      ; pointer to start of off screen memory
     OffScreenMemSize    dw ?      ; amount of off screen memory in 1k units
     __Reserved          db 206 dup (?)  ; remainder of ModeInfoBlock
     ModeInfoBlock ends

