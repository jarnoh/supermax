rasta=0
; MXM player, (c) '95/96 Niklas Beisert / pascal
; Converted & Modified by Axon/Xenon Development

.486p
.MODEL FLAT,c
.STACK
;JUMPS
LOCALS
.CODE

;° MACROS °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

; In  BL = interrupt
; Out CX:EDX = Selector:offset
GetIntVec MACRO
 mov ax,0204h
 int 31h
ENDM

; In  BL = Interrupt
;     CX:EDX = Selector:offset
SetIntVec MACRO
 mov ax,0205h
 int 31h
ENDM

public xmpInit
public xmpSetVolume
public xmpGetSync
public xmpGetPos
public xmpPlay
public xmpStop
public xmpGetTimer


;° DATA °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

copyright db "cubic tiny gus xm player v1.2 (c) '95/96 Niklas Beisert / pascal"

mxmheader struc
 hdMXMSig dd ?
 hdNOrders dd ?
 hdOrdLoopStart dd ?
 hdNChannels dd ?
 hdNPatterns dd ?
 hdNInstruments dd ?
 hdIniTempo db ?
 hdIniBPM db ?
 hdOptions dw ?
 hdSampStart dd ?
 hdSampMem8 dd ?
 hdSampMem16 dd ?
 hdPitchMin dd ?
 hdPitchMax dd ?
 hdPanPos db 32 dup (?)
 hdOrderTable db 256 dup (?)
 hdInstrTable dd 128 dup (?)
 hdPatternTable dd 256 dup (?)
ends

instrument struc
 insNSamples dd ?
 insSamples db 96 dup (?)
 insVolFade dw ?
 insVibType db ?
 insVibSweep db ?
 insVibDepth db ?
 insVibRate db ?
 insVNum db ?
 insVSustain db ?
 insVLoopS db ?
 insVLoopE db ?
 insVEnv dw 24 dup (?)
 insPNum db ?
 insPSustain db ?
 insPLoopS db ?
 insPLoopE db ?
 insPEnv dw 24 dup (?)
 db 46 dup (?)
ends

sample struc
 smpGUSStartPos db ?,?,?
 smpGUSLoopPos db ?,?,?
 smpGUSEndPos db ?,?,?
 smpGUSMode db ?
 smpDefVol db ?
 smpDefPan db ?
 smpNormNote dw ?
 db ?,?
ends

channelsize = 256
channel struc
 chGUSInited db ?
 chGUSStartPos dd ?
 chGUSEndPos dd ?
 chGUSLoopPos dd ?
 chGUSMode db ?
 chGUSStopIt db ?
 chGUSChangeSamp db ?
 chGUSNextPos dd ?
 chGUSFrq dw ?
 chGUSVol dw ?
 chGUSPan db ?
 chVol db ?
 chFinalVol db ?
 chPan db ?
 chFinalPan db ?
 chPitch dd ?
 chFinalPitch dd ?
 chCurIns db ?
 chEnvIns dd ?
 chCurNormNote dw ?
 chSustain db ?
 chFadeVol dw ?
 chAVibPos db ?
 chAVibSwpPos db ?
 chVolEnvPos dd ?
 chVolEnvSegPos dw ?
 chPanEnvPos dd ?
 chPanEnvSegPos dw ?
 chDefVol db ?
 chDefPan db ?
 chCommand db ?
 chVCommand db ?
 chPortaToPitch dd ?
 chPortaToVal dd ?
 chVolSlideVal db ?
 chGVolSlideVal db ?
 chVVolPanSlideVal db ?
 chPanSlideVal db ?
 chFineVolSlideUVal db ?
 chFineVolSlideDVal db ?
 chPortaUVal dd ?
 chPortaDVal dd ?
 chFinePortaUVal db ?
 chFinePortaDVal db ?
 chXFinePortaUVal db ?
 chXFinePortaDVal db ?
 chVibRate db ?
 chVibPos db ?
 chVibType db ?
 chVibDep db ?
 chTremRate db ?
 chTremPos db ?
 chTremType db ?
 chTremDep db ?
 chPatLoopCount db ?
 chPatLoopStart db ?
 chArpPos db ?
 chArpNotes db ?,?,?
 chActionTick db ?
 chMRetrigPos db ?
 chMRetrigLen db ?
 chMRetrigAct db ?
 chDelayNote db ?
 chOffset db ?
ends

globaldatastruct struc
 globalvol db ?
 uservol db ?
 syncval db ?
 curtick db ?
 curtempo db ?
 tick0 db ?
 currow dd ?
 patptr dd ?
 patlen dd ?
 curord dd ?
 jumptoord dd ?
 jumptorow dd ?
 patdelay db ?
 procnot db ?
 procins db ?
 procvol db ?
 proccmd db ?
 procdat db ?
 notedelayed db ?
 tmOldTimer df ?
 tmOldSSESP df ?
 tmIntCount dd ?
 tmTimerRate dd ?
 tmTicker dd ?
 tmInRoutine dd ?
 stimerlen dd ?
 stimerpos dd ?
 datasegsel dw ?
 maxtimerrate dd ?
 gusport dd ?
 guschannels dd ?
 portatmp db ?
 head mxmheader ?
 guslinvol dw 257 dup (?)
 chandata db channelsize*32 dup (?)
 tmStack db 1024 dup (?)
 vibtabs db 1024 dup (?)
ends

globdat globaldatastruct ?

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

sintab db 0,2,3,5,6,8,9,11,12,14,16,17,19,20,22,23,24,26,27,29,30,32,33
       db 34,36,37,38,39,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56
       db 56,57,58,59,59,60,60,61,61,62,62,62,63,63,63,64,64,64,64,64
logfreqtab dw 32768,32761,32753,32746,32738,32731,32724,32716,32709,32702,32694,32687,32679,32672,32665,32657
           dw 32768,32650,32532,32415,32298,32182,32066,31950,31835,31720,31606,31492,31379,31266,31153,31041
           dw 32768,30929,29193,27554,26008,24548,23170,21870,20643,19484,18390,17358,16384,15464,14596,13777
           dd 11131415,4417505,1753088,695713,276094,109568,43482,17256,6848,2718,1078,428,170,67,27,11

proccmdtab label dword
  dd procarpeggio-procnothing
  dd procportau-procnothing
  dd procportad-procnothing
  dd procportanote-procnothing
  dd procvibrato-procnothing
  dd procvolsl-procnothing
  dd procvolsl-procnothing
  dd proctremolo-procnothing
  dd procpan-procnothing
  dd 0
  dd procvolsl-procnothing
  dd procjump-procnothing
  dd procnvol-procnothing
  dd procbreak-procnothing
  dd 0
  dd proctempo-procnothing
  dd procgvol-procnothing
  dd procgvolsl-procnothing
  dd 0
  dd 0
  dd proctick-procnothing
  dd 0 ;//?
  dd 0
  dd 0
  dd 0
  dd procpansl-procnothing
  dd 0
  dd procmretrig-procnothing
  dd procsync-procnothing
  dd 0 ;//?
  dd 0
  dd 0
  dd 0
  dd procxfporta-procnothing
  dd 0
  dd 0

  dd 0
  dd procfportau-procnothing
  dd procfportad-procnothing
  dd 0 ;//?
  dd procvibtype-procnothing
  dd 0 ;//?
  dd procpatloop-procnothing
  dd proctremtype-procnothing
  dd procspan-procnothing
  dd proctick-procnothing
  dd procfvolup-procnothing
  dd procfvoldn-procnothing
  dd proctick-procnothing
  dd proctick-procnothing
  dd procpatdelay-procnothing
  dd procsync-procnothing

procvoltab label dword
  dd 0
  dd procvvol0-procnothing
  dd procvvol1-procnothing
  dd procvvol2-procnothing
  dd procvvol3-procnothing
  dd procvvol4-procnothing
  dd procvvpsl-procnothing
  dd procvvpsl-procnothing
  dd procvfvoldn-procnothing
  dd procvfvolup-procnothing
  dd procvvibrat-procnothing
  dd procvvib-procnothing
  dd procvpan-procnothing
  dd procvvpsl-procnothing
  dd procvvpsl-procnothing
  dd procvportanote-procnothing


docmdtab label dword
  dd doarpeggio-procnothing
  dd doportau-procnothing
  dd doportad-procnothing
  dd doportanote-procnothing
  dd dovibrato-procnothing
  dd doportavol-procnothing
  dd dovibvol-procnothing
  dd dotremolo-procnothing
  dd 0
  dd 0
  dd dovolsl-procnothing
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd dogvolsl-procnothing
  dd 0
  dd 0
  dd dokeyoff-procnothing
  dd 0
  dd 0
  dd 0
  dd 0
  dd dopansl-procnothing
  dd 0
  dd domretrig-procnothing
  dd 0
  dd 0 ;//?
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0

  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd doretrig-procnothing
  dd 0
  dd 0
  dd donotecut-procnothing
  dd dodelay-procnothing
  dd 0
  dd 0

dovoltab label dword
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd 0
  dd dovvolsld-procnothing
  dd dovvolslu-procnothing
  dd 0
  dd 0
  dd 0
  dd dovibrato-procnothing
  dd 0
  dd dovpansll-procnothing
  dd dovpanslr-procnothing
  dd doportanote-procnothing


;° CODE °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°



.code

loadebp PROC
 lea ebp,globdat
 ret
endp

inittables PROC
 call @@getadr
@@getadr:
 pop esi
 add esi,sintab-@@getadr
 lea edi,[ebp].vibtabs
 mov ecx,16
 rep movsd
 mov al,64
 stosb
 mov cl,63
@@sintabloop1:
 dec esi
 mov al,[esi]
 stosb
 dec cl
 jnz @@sintabloop1
 lea esi,[ebp].vibtabs
 mov cl,128
@@sintabloop2:
 lodsb
 neg al
 stosb
 dec cl
 jnz @@sintabloop2
@@dwntabloop:
 mov al,cl
 sar al,1
 neg al
 stosb
 dec cl
 jnz @@dwntabloop
@@rectabloop:
 mov al,cl
 and al,80h
 sub al,40h
 stosb
 dec cl
 jnz @@rectabloop
@@uptabloop:
 mov al,cl
 sar al,1
 stosb
 dec cl
 jnz @@uptabloop
 mov [ebp].guslinvol[0],0
 mov [ebp].guslinvol[512],0EFFFh
 mov edi,1
@@lintabloop:
 mov ebx,edi
 mov edx,7
@@logloop:
 cmp ebx,0
 je @@logfound
 shr ebx,1
 inc edx
 jmp @@logloop
@@logfound:
 mov eax,edi
 mov cl,20
 sub cl,dl
 shl eax,cl
 and eax,0fffh
 shl edx,12
 or eax,edx
 sub eax,1000h
 mov [ebp].guslinvol[2*edi],ax
 inc edi
 cmp edi,256
 jne @@lintabloop
 ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; esi:mxmdata, ecx:maxtimerrate, eax:pspseg
XMPInit PROC
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 push ebp
 call loadebp
 mov [ebp].maxtimerrate,ecx
 mov [ebp].uservol,40h
; test eax,80000000h                     ; High bit of EAX set. AX = GusPort
; jnz @@portgiven
 mov edi, eax
 call gusGetPort
@@portgiven:
; and eax,not 80000000h
 test eax, eax
 jnz @@guz
 call a_init
@@guz:
 mov [ebp].gusport,eax
 cmp [esi].hdMXMSig,004D584Dh                   ; ' MXM'
 jne @@fail
 lea edi,[ebp].head.hdMXMSig
 mov ecx,750h/4
 rep movsd
 sub esi,750h
 sub edi,600h
 mov ecx,180h
@@relloop:
 add [edi],esi
 add edi,4
 dec ecx
 jnz @@relloop
 test byte ptr [esi].hdOptions,4
 jz @@nodelta
 and byte ptr [esi].hdOptions,not 4
 mov ecx,[esi].hdSampMem8
 mov ebx,[esi].hdSampStart
 add ebx,esi
 xor eax,eax
 cmp ecx,0
 je @@8bitfini
@@8bitdelta:
 add al,[ebx]
 mov [ebx],al
 inc ebx
 dec ecx
 jnz @@8bitdelta
@@8bitfini:
 mov ecx,[esi].hdSampMem16
 xor eax,eax
 cmp ecx,0
 je @@16bitfini
@@16bitdelta:
 add ax,[ebx]
 mov [ebx],ax
 add ebx,2
 dec ecx
 jnz @@16bitdelta
@@16bitfini:
@@nodelta:
 mov ecx,[esi].hdSampMem16
 shl ecx,1
 add ecx,[esi].hdSampMem8
 mov eax,[esi].hdSampStart
 add esi,eax
 call gusUploadSamples
 call inittables
 mov edx, [ebp].gusport
 mov eax,1
 jmp @@done
@@fail:
 xor edx,edx
 xor eax,eax
@@done:
 pop ebp
 ret
endp

getfreq6848 proc
uses edx, ebx, ecx, esi
 add eax,8000h
 mov edx,eax
 mov ebx,eax
 mov ecx,eax
 shr eax,12
 shr edx,8
 shr ebx,4
 and eax,15
 and ebx,15
 and ecx,15
 and edx,15
 call @@getadr
@@getadr:
 pop esi
 add esi,logfreqtab-@@getadr
 mov eax,[esi+6*16+eax*4]
 movzx edx,word ptr [esi+4*16+edx*2]
 movzx ebx,word ptr [esi+2*16+ebx*2]
 movzx ecx,word ptr [esi+0*16+ecx*2]
 mul edx
 shrd eax,edx,15
 mul ebx
 shrd eax,edx,15
 mul ecx
 shrd eax,edx,15
 ret
endp

PlayNote PROC
 mov [ebp].portatmp,0
 cmp [ebp].proccmd,3
 jne @@noportac
 mov [ebp].portatmp,1
@@noportac:
 cmp [ebp].proccmd,5
 jne @@noportacv
 mov [ebp].portatmp,1
@@noportacv:
 cmp [ebp].procvol,0f0h
 jb @@noportav
 mov [ebp].portatmp,1
@@noportav:
 movzx eax,[ebp].procins
 cmp al,0
 je @@noins1
 cmp eax,[ebp].head.hdNInstruments
 ja @@noins1
 mov [edi].chCurIns,al
@@noins1:
 cmp [edi].chCurIns,0
 je @@done
 movzx eax,[ebp].procnot
 cmp al,0
 je @@nonote
 cmp al,97
 je @@keyoff
 mov [edi].chDelayNote,al
 cmp [ebp].proccmd,49
 jne @@nodelay
 cmp [ebp].procdat,0
 jne @@done
@@nodelay:
 dec al
 cmp [ebp].portatmp,1
 je @@portanote
 mov [edi].chGUSStopIt,1
 movzx edx,[edi].chCurIns
 dec dl
 mov edx,[ebp].head.hdInstrTable[4*edx]
 movzx ebx,insSamples[edx][eax]
 cmp ebx,insNSamples[edx]
 jae @@done
 shl ebx,4
 lea ebx,[ebx+edx+256]
 mov [edi].chGUSInited,1
 mov [edi].chGUSChangeSamp,1
 push eax
 mov eax,dword ptr [ebx].smpGUSStartPos
 and eax,0ffffffh
 mov [edi].chGUSStartPos,eax
 mov eax,dword ptr [ebx].smpGUSLoopPos
 and eax,0ffffffh
 mov [edi].chGUSLoopPos,eax
 mov eax,dword ptr [ebx].smpGUSEndPos
 and eax,0ffffffh
 mov [edi].chGUSEndPos,eax
 mov al,[ebx].smpGUSMode
 mov [edi].chGUSMode,al
 pop eax
 cmp [ebp].procins,0
 je @@noins2
 mov [edi].chEnvIns,edx
 mov dl,[ebx].smpDefVol
 mov [edi].chDefVol,dl
 mov dl,[ebx].smpDefPan
 mov [edi].chDefPan,dl
@@noins2:
 mov dx,[ebx].smpNormNote
 mov [edi].chCurNormNote,dx
 shl eax,8
 add ax,dx
 neg ax
 add ah,48
 movsx eax,ax
 test byte ptr [ebp].head.hdOptions,1
 jnz @@line1
 neg eax
 call getfreq6848
@@line1:
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
 mov [edi].chPortaToPitch,eax
 xor eax,eax
 cmp [ebp].proccmd,9
 jne @@nooffset
 mov al,[ebp].procdat
 cmp al,0
 je @@reuseoffset
 mov [edi].chOffset,al
@@reuseoffset:
 movzx eax,[edi].chOffset
 shl eax,8
@@nooffset:
 mov [edi].chGUSNextPos,eax
 mov [edi].chVibPos,0
 mov [edi].chTremPos,0
 mov [edi].chArpPos,0
 mov [edi].chMRetrigPos,0
 jmp @@nonote
@@portanote:
 shl eax,8
 add ax,[edi].chCurNormNote
 neg ax
 add ah,48
 movsx eax,ax
 test byte ptr [ebp].head.hdOptions,1
 jnz @@line2
 neg eax
 call getfreq6848
@@line2:
 mov [edi].chPortaToPitch,eax
@@nonote:
 cmp [ebp].procins,0
 je @@done
 cmp [ebp].notedelayed,1
 je @@noinsvolpan
 mov al,[edi].chDefVol
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 test byte ptr [ebp].head.hdOptions,2
 jnz @@noinsvolpan
 mov al,[edi].chDefPan
 mov [edi].chPan,al
 mov [edi].chFinalPan,al
@@noinsvolpan:
 xor eax,eax
 mov [edi].chSustain,1
 mov [edi].chFadeVol,8000h
 mov [edi].chAVibPos,al
 mov [edi].chAVibSwpPos,al
 mov [edi].chVolEnvPos,eax
 mov [edi].chVolEnvSegPos,ax
 mov [edi].chPanEnvPos,eax
 mov [edi].chPanEnvSegPos,ax
 jmp @@done
@@keyoff:
 mov [edi].chSustain,0
@@done:
 ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
xmpSetVolume PROC
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 push ebp
 call loadebp
 mov [ebp].uservol,al
 pop ebp
 ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
xmpGetSync PROC
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 push ebp
 call loadebp
 mov al,[ebp].syncval
 pop ebp
 ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
xmpGetPos PROC
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 push ebp
 call loadebp
 mov al,byte ptr [ebp].currow
 mov ah,byte ptr [ebp].curord
 pop ebp
 ret
endp

freqrange PROC
 cmp eax,[ebp].head.hdPitchMin
 jg @@lowlimok
 mov eax,[ebp].head.hdPitchMin
@@lowlimok:
 cmp eax,[ebp].head.hdPitchMax
 jl @@highlimok
 mov eax,[ebp].head.hdPitchMax
 jmp @@highlimok
@@highlimok:
 ret
endp

;° EFFECTS °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

procnothing PROC
 ret
endp

procjump PROC
 movzx eax,[ebp].procdat
 mov [ebp].jumptoord,eax
 mov [ebp].jumptorow,0
 ret
endp

procbreak PROC
 cmp [ebp].jumptoord,-1
 jne @@onlyrow
 mov eax,[ebp].curord
 inc eax
 mov [ebp].jumptoord,eax
@@onlyrow:
 movzx eax,[ebp].procdat
 mov ebx,eax
 shr al,4
 imul eax,10
 and bl,0fh
 add eax,ebx
 mov [ebp].jumptorow,eax
 ret
endp

procpatloop PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@set
 inc [edi].chPatLoopCount
 cmp [edi].chPatLoopCount,al
 ja @@nextrow
 movzx eax,[edi].chPatLoopStart
 mov [ebp].jumptorow,eax
 mov eax,[ebp].curord
 mov [ebp].jumptoord,eax
 jmp @@done
@@nextrow:
 mov [edi].chPatLoopCount,0
 mov al,byte ptr [ebp].currow
 inc al
 mov [edi].chPatLoopStart,al
 jmp @@done
@@set:
 mov al,byte ptr [ebp].currow
 mov [edi].chPatLoopStart,al
@@done:
 ret
endp

procpatdelay PROC
 mov al,[ebp].procdat
 mov [ebp].patdelay,al
 ret
endp

proctempo PROC
 movzx ebx,[ebp].procdat
 cmp bl,20h
 jb @@speed
 mov eax,2983615
 xor edx,edx
 div ebx
 mov [ebp].stimerlen,eax
 ret
@@speed:
 cmp bl,0
 je @@ignore
 mov [ebp].curtempo,bl
@@ignore:
 ret
endp

procnvol PROC
 mov al,[ebp].procdat
 cmp al,40h
 jbe @@vok
 mov al,40h
@@vok:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

procgvol PROC
 mov al,[ebp].procdat
 cmp al,40h
 jbe @@vok
 mov al,40h
@@vok:
 mov [ebp].globalvol,al
 ret
endp

procpan PROC
 mov al,[ebp].procdat
 mov [edi].chPan,al
 mov [edi].chFinalPan,al
 ret
endp

procspan PROC
 mov al,[ebp].procdat
 shl al,4
 or al,[ebp].procdat
 mov [edi].chPan,al
 mov [edi].chFinalPan,al
 ret
endp

procvpan PROC
 mov al,[ebp].procvol
 shl al,4
 or al,[ebp].procvol
 mov [edi].chPan,al
 mov [edi].chFinalPan,al
 ret
endp

procarpeggio PROC
 movzx eax,[ebp].procdat
 cmp al,0
 jne @@doit
 mov [edi].chCommand,0ffh
@@doit:
 shl eax,4
 shr al,4
 mov [edi].chArpNotes[0],0
 mov [edi].chArpNotes[1],ah
 mov [edi].chArpNotes[2],al
 ret
endp

procportau PROC
 movzx eax,[ebp].procdat
 cmp al,0
 je @@reuse
 shl eax,4
 mov [edi].chPortaUVal,eax
@@reuse:
 ret
endp

procportad PROC
 movzx eax,[ebp].procdat
 cmp al,0
 je @@reuse
 shl eax,4
 mov [edi].chPortaDVal,eax
@@reuse:
 ret
endp

procportanote PROC
 movzx eax,[ebp].procdat
 cmp al,0
 je @@reuse
 shl eax,4
 mov [edi].chPortaToVal,eax
@@reuse:
 ret
endp

procvibrato PROC
 mov al,[ebp].procdat
 and al,0Fh
 jz @@reusel
 shl al,2
 mov [edi].chVibDep,al
@@reusel:
 mov al,[ebp].procdat
 and al,0F0h
 jz @@reuseh
 shr al,2
 mov [edi].chVibRate,al
@@reuseh:
 ret
endp

proctremolo PROC
 mov al,[ebp].procdat
 and al,0Fh
 jz @@reusel
 shl al,2
 mov [edi].chTremDep,al
@@reusel:
 mov al,[ebp].procdat
 and al,0F0h
 jz @@reuseh
 shr al,2
 mov [edi].chTremRate,al
@@reuseh:
 ret
endp

procvolsl PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@reuse
 mov [edi].chVolSlideVal,al
@@reuse:
 ret
endp

procpansl PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@reuse
 mov [edi].chPanSlideVal,al
@@reuse:
 ret
endp

procgvolsl PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@reuse
 mov [edi].chGVolSlideVal,al
@@reuse:
 ret
endp

procfportau PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@reuse
 mov [edi].chFinePortaUVal,al
@@reuse:
 movzx eax,[edi].chFinePortaUVal
 shl eax,4
 neg eax
 add eax,[edi].chPitch
 call freqrange
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
 ret
endp

procfportad PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@reuse
 mov [edi].chFinePortaDVal,al
@@reuse:
 movzx eax,[edi].chFinePortaDVal
 shl eax,4
 add eax,[edi].chPitch
 call freqrange
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
 ret
endp

procxfporta PROC
 movzx eax,[ebp].procdat
 shl eax,4
 shr al,4
 cmp ah,2
 je @@down
 cmp ah,1
 jne @@done
 cmp al,0
 je @@reuseu
 mov [edi].chXFinePortaUVal,al
@@reuseu:
 movzx eax,[edi].chXFinePortaUVal
 shl eax,2
 neg eax
 add eax,[edi].chPitch
 call freqrange
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
 jmp @@done
@@down:
 cmp al,0
 je @@reused
 mov [edi].chXFinePortaDVal,al
@@reused:
 movzx eax,[edi].chXFinePortaDVal
 shl eax,2
 add eax,[edi].chPitch
 call freqrange
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
@@done:
 ret
endp

procfvolup PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@reuse
 mov [edi].chFineVolSlideUVal,al
@@reuse:
 mov al,[edi].chVol
 add al,[edi].chFineVolSlideUVal
 cmp al,40h
 jbe @@vok
 mov al,40h
@@vok:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

procfvoldn PROC
 mov al,[ebp].procdat
 cmp al,0
 je @@reuse
 mov [edi].chFineVolSlideDVal,al
@@reuse:
 mov al,[edi].chVol
 sub al,[edi].chFineVolSlideDVal
 jnc @@vok
 mov al,0
@@vok:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

proctick PROC
 mov al,[ebp].procdat
 mov [edi].chActionTick,al
 ret
endp

procvvol PROC
procvvol4:
 mov [ebp].procvol,10h
procvvol3:
 add [ebp].procvol,10h
procvvol2:
 add [ebp].procvol,10h
procvvol1:
 add [ebp].procvol,10h
procvvol0:
 mov al,[ebp].procvol
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

procvvpsl PROC
 mov al,[ebp].procvol
 mov [edi].chVVolPanSlideVal,al
 ret
endp

procvfvolup PROC
 mov al,[edi].chVol
 add al,[ebp].procvol
 cmp al,40h
 jbe @@vok
 mov al,40h
@@vok:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

procvfvoldn PROC
 mov al,[edi].chVol
 sub al,[ebp].procvol
 jnc @@vok
  mov al,0
@@vok:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

procvvibrat PROC
 mov al,[ebp].procvol
 shl al,2
 je @@reuse
 mov [edi].chVibRate,al
@@reuse:
 ret
endp

procvvib PROC
 mov al,[ebp].procvol
 shl al,2
 je @@reuse
 mov [edi].chVibDep,al
@@reuse:
 ret
endp

procmretrig PROC
 movzx eax,[ebp].procdat
 cmp al,0
 je @@reuse
 shl eax,4
 shr al,4
 mov [edi].chMRetrigLen,al
 mov [edi].chMRetrigAct,ah
 mov [edi].chMRetrigPos,0
@@reuse:
 ret
endp

procvportanote PROC
 movzx eax,[ebp].procvol
 cmp al,0
 je @@reuse
 shl eax,8
 mov [edi].chPortaToVal,eax
@@reuse:
 ret
endp

procvibtype PROC
 mov al,[ebp].procdat
 and al,3
 mov [edi].chVibType,al
 ret
endp

proctremtype PROC
 mov al,[ebp].procdat
 and al,3
 mov [edi].chTremType,al
 ret
endp

procsync PROC
 mov al,[ebp].procdat
 mov [ebp].syncval,al
 ret
endp

doarpeggio PROC
 movzx eax,[edi].chArpPos
 mov al,[edi].chArpNotes[eax]
 test byte ptr [ebp].head.hdOptions,1
 je @@amiga
 shl eax,8
 neg eax
 add eax,[edi].chFinalPitch
 call freqrange
 mov [edi].chFinalPitch,eax
 jmp @@noamiga
@@amiga:
 call @@getadr
@@getadr:
 pop edx
 mov ax,[edx+logfreqtab[16*4+eax*2]-@@getadr]
 mul [edi].chFinalPitch
 shrd eax,edx,15
 call freqrange
 mov [edi].chFinalPitch,eax
@@noamiga:
 inc [edi].chArpPos
 cmp [edi].chArpPos,3
 jne @@done
 mov [edi].chArpPos,0
@@done:
 ret
endp

doportau PROC
 cmp [ebp].tick0,0
 jne @@done
 mov eax,[edi].chPitch
 sub eax,[edi].chPortaUVal
 call freqrange
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
@@done:
 ret
endp

doportad PROC
 cmp [ebp].tick0,0
 jne @@done
 mov eax,[edi].chPitch
 add eax,[edi].chPortaDVal
 call freqrange
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
@@done:
 ret
endp

doportanote PROC
 cmp [ebp].tick0,0
 jne @@done
 mov eax,[edi].chPitch
 cmp eax,[edi].chPortaToPitch
 je @@done
 jg @@down
 add eax,[edi].chPortaToVal
 cmp eax,[edi].chPortaToPitch
 jle @@set
 mov eax,[edi].chPortaToPitch
 jmp @@set
@@down:
 sub eax,[edi].chPortaToVal
 cmp eax,[edi].chPortaToPitch
 jge @@set
 mov eax,[edi].chPortaToPitch
@@set:
 mov [edi].chPitch,eax
 mov [edi].chFinalPitch,eax
@@done:
 ret
endp

dovibrato PROC
 movzx eax,word ptr [edi].chVibPos
 movsx eax,[ebp].vibtabs[eax]
 imul [edi].chVibDep
 sar eax,3
 add eax,[edi].chFinalPitch
 call freqrange
 mov [edi].chFinalPitch,eax
 cmp [ebp].tick0,0
 jne @@done
 mov al,[edi].chVibRate
 add [edi].chVibPos,al
@@done:
 ret
endp

dotremolo PROC
 movzx eax,word ptr [edi].chTremPos
 movsx eax,[ebp].vibtabs[eax]
 imul [edi].chTremDep
 sar eax,6
 add al,[edi].chFinalVol
 jns @@lok
 mov al,0
@@lok:
 cmp al,40h
 jbe @@tok
 mov al,40h
@@tok:
 mov [edi].chFinalVol,al
 cmp [ebp].tick0,0
 jne @@done
 mov al,[edi].chTremRate
 add [edi].chTremPos,al
@@done:
 ret
endp

dovolsl PROC
 mov bl,[edi].chVolSlideVal
 mov al,[edi].chVol
 cmp [ebp].tick0,0
 jne @@done
 test bl,0f0h
 jnz @@up
 sub al,bl
 jnc @@done
 mov al,0
 jmp @@done
@@up:
 shr bl,4
 add al,bl
 cmp al,40h
 jbe @@done
 mov al,40h
@@done:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

dovibvol PROC
 call dovibrato
 jmp dovolsl
endp

doportavol PROC
 call doportanote
 jmp dovolsl
endp

dogvolsl PROC
 mov bl,[edi].chGVolSlideVal
 mov al,[ebp].globalvol
 cmp [ebp].tick0,0
 jne @@done
 test bl,0f0h
 jnz @@up
 sub al,bl
 jnc @@done
 mov al,0
 jmp @@done
@@up:
 shr bl,4
 add al,bl
 cmp al,40h
 jbe @@done
 mov al,40h
@@done:
 mov [ebp].globalvol,al
 ret
endp

dopansl PROC
 mov bl,[edi].chPanSlideVal
 mov al,[edi].chPan
 cmp [ebp].tick0,0
 jne @@done
 test bl,0f0h
 jnz @@left
 add al,bl
 jnc @@done
 mov al,0ffh
 jmp @@done
@@left:
 shr bl,4
 sub al,bl
 jnc @@done
 mov al,0
@@done:
 mov [edi].chPan,al
 mov [edi].chFinalPan,al
 ret
endp

dokeyoff PROC
 mov al,[edi].chActionTick
 cmp [ebp].tick0,0
 jne @@done
 mov [edi].chSustain,0
@@done:
 ret
endp

donotecut PROC
 mov al,[edi].chActionTick
 cmp [ebp].tick0,0
 jne @@done
 mov [edi].chVol,0
 mov [edi].chFinalVol,0
@@done:
 ret
endp

doretrig PROC
 cmp [edi].chActionTick,0
 je @@done
 movzx eax,[ebp].curtick
 div [edi].chActionTick
 cmp ah,0
 jne @@done
 mov [edi].chGUSNextPos,0
@@done:
 ret
endp

domretrig PROC
 mov al,[edi].chMRetrigPos
 inc [edi].chMRetrigPos
 cmp al,[edi].chMRetrigLen
 jne @@done
 mov [edi].chMRetrigPos,0
 mov [edi].chGUSNextPos,0
 mov al,[edi].chVol
 mov bl,[edi].chMRetrigAct
 test bl,7
 jz @@done
 cmp bl,1
 jne @@not1
 dec al
@@not1:
 cmp bl,2
 jne @@not2
 sub al,2
@@not2:
 cmp bl,3
 jne @@not3
 sub al,4
@@not3:
 cmp bl,4
 jne @@not4
 sub al,8
@@not4:
 cmp bl,5
 jne @@not5
 sub al,16
@@not5:
 cmp bl,6
 jne @@not6
 mov ah,al
 shr al,2
 add al,ah
 shr al,1
@@not6:
 cmp bl,7
 jne @@not7
 shr al,1
@@not7:
 cmp bl,9
 jne @@not9
 inc al
@@not9:
 cmp bl,10
 jne @@not10
 add al,2
@@not10:
 cmp bl,11
 jne @@not11
 add al,4
@@not11:
 cmp bl,12
 jne @@not12
 add al,8
@@not12:
 cmp bl,13
 jne @@not13
 add al,16
@@not13:
 cmp bl,14
 jne @@not14
 mov ah,al
 shr al,1
 add al,ah
@@not14:
 cmp bl,15
 jne @@not15
 shl al,1
 jns @@not15
 dec al
@@not15:
 cmp al,0
 jge @@lok
 mov al,0
@@lok:
 cmp al,40h
 jbe @@tok
 mov al,40h
@@tok:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
@@done:
 ret
endp

dodelay PROC
 cmp [ebp].tick0,0
 jne @@done
 mov al,[ebp].curtick
 cmp al,[edi].chActionTick
 jne @@done
 mov [ebp].notedelayed,1
 mov al,[edi].chDelayNote
 mov [ebp].procnot,al
 mov al,[edi].chCurIns
 mov [ebp].procins,al
 mov [ebp].proccmd,0ffh
 mov [ebp].procvol,0
 call PlayNote
@@done:
 ret
endp

dovvolsld PROC
 mov al,[edi].chVol
 cmp [ebp].tick0,0
 jne @@done
 sub al,[edi].chVVolPanSlideVal
 jnc @@done
 mov al,0
@@done:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

dovvolslu PROC
 mov al,[edi].chVol
 cmp [ebp].tick0,0
 jne @@done
 add al,[edi].chVVolPanSlideVal
 cmp al,40h
 jbe @@done
 mov al,40h
@@done:
 mov [edi].chVol,al
 mov [edi].chFinalVol,al
 ret
endp

dovpansll PROC
 mov al,[edi].chPan
 cmp [ebp].tick0,0
 jne @@done
 sub al,[edi].chVVolPanSlideVal
 jnc @@done
 mov al,0
@@done:
 mov [edi].chPan,al
 mov [edi].chFinalPan,al
 ret
endp

dovpanslr PROC
 mov al,[edi].chVol
 cmp [ebp].tick0,0
 jne @@done
 add al,[edi].chVVolPanSlideVal
 jnc @@done
 mov al,0ffh
@@done:
 mov [edi].chPan,al
 mov [edi].chFinalPan,al
 ret
endp

;° EFFECTS END °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

callproccmdtab PROC
 call @@getadr
@@getadr:
 pop ebx
 mov eax,[ebx+proccmdtab[4*eax]-@@getadr]
 lea eax,[eax+ebx+procnothing-@@getadr]
 jmp eax
endp

PlayTick PROC
 mov [ebp].tick0,0
 lea edi,[ebp].chandata
 xor ecx,ecx
@@resetvalloop:
 mov al,[edi].chVol
 mov [edi].chFinalVol,al
 mov al,[edi].chPan
 mov [edi].chFinalPan,al
 mov eax,[edi].chPitch
 mov [edi].chFinalPitch,eax
 add edi,channelsize
 inc ecx
 cmp ecx,[ebp].head.hdNChannels
 jne @@resetvalloop
 inc [ebp].curtick
 mov al,[ebp].curtick
 cmp al,[ebp].curtempo
 jne @@notnextrow
 mov [ebp].curtick,0
 cmp [ebp].patdelay,0
 jz @@nextrow
 dec [ebp].patdelay
 jmp @@notnextrow
@@nextrow:
 mov [ebp].tick0,1
 inc [ebp].currow
 cmp [ebp].jumptoord,-1
 jne @@dojump
 mov eax,[ebp].currow
 cmp eax,[ebp].patlen
 jb @@donotjump
 mov eax,[ebp].curord
 inc eax
 mov [ebp].jumptoord,eax
 mov [ebp].jumptorow,0
@@dojump:
 mov eax,[ebp].jumptoord
 cmp [ebp].curord,eax
 je @@noresetploop
 lea edi,[ebp].chandata
 xor ecx,ecx
@@resetplloop:
 mov [edi].chPatLoopCount,0
 mov [edi].chPatLoopStart,0
 add edi,channelsize
 inc ecx
 cmp ecx,[ebp].head.hdNChannels
 jne @@resetplloop
@@noresetploop:
 mov eax,[ebp].jumptoord
 cmp eax,[ebp].head.hdNOrders
 jb @@dontloop
 mov eax,[ebp].head.hdOrdLoopStart
@@dontloop:
 mov [ebp].curord,eax
 mov eax,[ebp].jumptorow
 mov [ebp].currow,eax
 mov [ebp].jumptoord,-1
;if (!currentpattern&&!currentrow&&!patdelay)
;{
; currentpattern=0;
; currentrow=0;
; memset(tdata, 0, sizeof(tdata));
; for (i=0; i<channels; i++)
; {
;  tdata[i].num=i;
;  tdata[i].chanvol=0xFF;
;  tdata[i].finalpan=tdata[i].pan=(i&1)?255:0;
;  mcpReset(i);
; }
; tempo=...;
; speed=...;
; globalvol=0x40;
; mcpSetSpeed(...);
;}
 mov eax,[ebp].curord
 movzx eax,[ebp].head.hdOrderTable[eax]
 mov esi,[ebp].head.hdPatternTable[4*eax]
 lodsd
 mov [ebp].patlen,eax
 cmp [ebp].jumptorow,0
 je @@rowfound
@@rowfind:
@@chanskip:
 lodsb
 cmp al,0
 je @@rowend
 test al,20h
 jz @@not20
 add esi,2
@@not20:
 test al,40h
 jz @@not40
 inc esi
@@not40:
 test al,80h
 jz @@chanskip
 add esi,2
 jmp @@chanskip
@@rowend:
 dec [ebp].jumptorow
 jnz @@rowfind
@@rowfound:
 mov [ebp].patptr,esi
@@donotjump:
 mov esi,[ebp].patptr
 lea edi,[ebp].chandata
 xor ecx,ecx
@@processrow:
 mov [ebp].procnot,0
 mov dword ptr [ebp].procins,0
 mov [edi].chCommand,0ffh
 mov al,[esi]
 cmp al,0
 je @@procnextchan
 and al,1fh
 cmp al,cl
 jne @@procnextchan
 lodsb
 mov ah,al
 test ah,20h
 jz @@nonot
 lodsb
 mov [ebp].procnot,al
 lodsb
 mov [ebp].procins,al
@@nonot:
 test ah,40h
 jz @@novol
 lodsb
 mov [ebp].procvol,al
@@novol:
 test ah,80h
 jz @@nocmd
 lodsb
 mov [ebp].proccmd,al
 lodsb
 mov [ebp].procdat,al
@@nocmd:
@@procnote:
 mov [ebp].notedelayed,0
 call PlayNote
 movzx eax,[ebp].procvol
 and [ebp].procvol,0fh
 shr eax,4
 mov [edi].chVCommand,al
 add eax,(procvoltab-proccmdtab)/4
 call callproccmdtab
 movzx eax,[ebp].proccmd
 cmp al,52
 jae @@procnextchan
 mov [edi].chCommand,al
 call callproccmdtab
@@procnextchan:
 add edi,channelsize
 inc ecx
 cmp ecx,[ebp].head.hdNChannels
 jne @@processrow
 inc esi
 mov [ebp].patptr,esi
@@notnextrow:
 lea edi,[ebp].chandata
 xor ecx,ecx
@@dotickloop:
; process volume column
 movzx eax,[edi].chVCommand
 add eax,(dovoltab-proccmdtab)/4
 call callproccmdtab
; process command
 movzx eax,[edi].chCommand
 cmp al,52
 jae @@donocmd
 add eax,(docmdtab-proccmdtab)/4
 call callproccmdtab
@@donocmd:
 mov ebx,[edi].chEnvIns
 cmp ebx,0
 je @@noenvins
; process fadeout
 movzx eax,[edi].chFinalVol
 mul [ebp].uservol
 shr eax,6
 mul [ebp].globalvol
 mul [edi].chFadeVol
 shr edx,4
 mov [edi].chFinalVol,dl
 cmp [edi].chSustain,0
 jne @@sustain
 mov ax,[ebx].insVolFade
 sub [edi].chFadeVol,ax
 jnb @@sustain
 mov [edi].chFadeVol,0
@@sustain:
; process volume envelope
 mov eax,[edi].chVolEnvPos
 cmp [edi].chVolEnvSegPos,0
 je @@vnoloop
 cmp al,[ebx].insVLoopE
 jne @@vnoloop
 mov al,[ebx].insVLoopS
 mov [edi].chVolEnvPos,eax
@@vnoloop:
 lea esi,[ebx].insVEnv[4*eax]
 cmp al,[ebx].insVNum
 je @@venvlast
 mov ax,[esi][4][2]
 mov dx,[esi][0][2]
 sub eax,edx
 imul [edi].chVolEnvSegPos
 idiv word ptr [esi][0][0]
 add al,byte ptr [esi][0][2]
 mul [edi].chFinalVol
 shr eax,6
 mov [edi].chFinalVol,al
 mov ax,[edi].chVolEnvSegPos
 cmp ax,0
 jne @@vnosustain
 cmp [edi].chSustain,0
 je @@vnosustain
 mov edx,[edi].chVolEnvPos
 cmp dl,[ebx].insVSustain
 je @@venvnostep
@@vnosustain:
 inc eax
 cmp ax,[esi][0][0]
 jb @@venvnostep
 xor eax,eax
 inc [edi].chVolEnvPos
@@venvnostep:
 mov [edi].chVolEnvSegPos,ax
 jmp @@venvend
@@venvlast:
 mov al,byte ptr [esi][0][2]
 mul [edi].chFinalVol
 shr eax,6
 mov [edi].chFinalVol,al
@@venvend:
; process panning envelope
 mov eax,[edi].chPanEnvPos
 cmp [edi].chPanEnvSegPos,0
 je @@pnoloop
 cmp al,[ebx].insPLoopE
 jne @@pnoloop
 mov al,[ebx].insPLoopS
 mov [edi].chPanEnvPos,eax
@@pnoloop:
 lea esi,[ebx].insPEnv[4*eax]
 cmp al,[ebx].insPNum
 je @@penvlast
 mov ax,[esi][4][2]
 mov dx,[esi][0][2]
 sub eax,edx
 imul [edi].chPanEnvSegPos
 idiv byte ptr [esi][0][0]
 add al,byte ptr [esi][0][2]
 sub al,32
 movsx edx,[edi].chFinalPan
 xor dl,dh
 imul dl
 shr eax,5
 add [edi].chFinalPan,al
 mov ax,[edi].chPanEnvSegPos
 cmp ax,0
 jne @@pnosustain
 cmp [edi].chSustain,0
 je @@pnosustain
 mov edx,[edi].chPanEnvPos
 cmp dl,[ebx].insPSustain
 je @@penvnostep
@@pnosustain:
 inc eax
 cmp ax,[esi][0][0]
 jb @@penvnostep
 xor eax,eax
 inc [edi].chPanEnvPos
@@penvnostep:
 mov [edi].chPanEnvSegPos,ax
 jmp @@penvend
@@penvlast:
 mov al,byte ptr [esi][0][2]
 sub al,32
 movsx edx,[edi].chFinalPan
 xor dl,dh
 imul dl
 shr eax,5
 add [edi].chFinalPan,al
@@penvend:
; process auto vibrato
 movzx eax,[edi].chAVibPos
 mov ah,[ebx].insVibType
 mov al,[ebp].vibtabs[eax]
 imul [ebx].insVibDepth
 shr eax,4
 mov dl,[edi].chAVibSwpPos
 cmp dl,[ebx].insVibSweep
 jae @@nosweep
 imul dl
 idiv [ebx].insVibSweep
 inc [edi].chAVibSwpPos
@@nosweep:
 neg eax
 movsx eax,al
 add eax,[edi].chFinalPitch
 call freqrange
 mov [edi].chFinalPitch,eax
 mov al,[ebx].insVibRate
 add [edi].chAVibPos,al
@@noenvins:
; conv vals for gus
 movzx eax,[edi].chFinalVol
 shl eax,1
 mov ax,[ebp].guslinvol[2*eax]
 mov [edi].chGUSVol,ax
 mov al,[edi].chFinalPan
 shr al,4
 mov [edi].chGUSPan,al
 mov eax,[edi].chFinalPitch
 test byte ptr [ebp].head.hdOptions,1
 jz @@amiga
 call getfreq6848
 mul [ebp].guschannels
 mov ebx,494
 div ebx
 jmp @@noamiga
@@amiga:
 cmp eax,100
 jb @@noamiga
 mov ebx,eax
 mov eax,94929
 mul [ebp].guschannels
 div ebx
@@noamiga:
 and al,not 1
 mov [edi].chGUSFrq,ax
 add edi,channelsize
 inc ecx
 cmp ecx,[ebp].head.hdNChannels
 jne @@dotickloop
 ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
xmpPlay PROC
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 push ebp
 call loadebp
 mov [ebp].jumptoord,eax
 mov [ebp].curord,eax
 xor eax,eax
 mov [ebp].currow,eax
 call gusOpen
 lea edi,[ebp].chandata
 mov ecx,channelsize*8
 xor eax,eax
 rep stosd
 lea edi,[ebp].chandata
 xor ecx,ecx
@@panloop:
 mov al,[ebp].head.hdPanPos[ecx]
 mov [edi].chPan,al
 add edi,channelsize
 inc ecx
 cmp cl,32
 jne @@panloop
 xor eax,eax
 mov [ebp].globalvol,40h
 mov [ebp].jumptorow,eax
 mov [ebp].syncval,al
 mov al,[ebp].head.hdIniTempo
 mov [ebp].curtempo,al
 dec al
 mov [ebp].curtick,al
 mov eax,2983615
 xor edx,edx
 movzx ebx,[ebp].head.hdIniBPM
 div ebx
 mov [ebp].stimerlen,eax
 call tmInit
 pop ebp
 ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
xmpStop PROC
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 push ebp
 call loadebp
 call tmClose
 call gusClose
 cmp [ebp].gusport, 0
 jnz @@guz
 call a_init
@@guz:
 pop ebp
 ret
endp

;° SYSTEM TIMER °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

tmTimerHandler PROC
 pushad
if rasta eq 1
 mov dx, 3c8h
 xor al, al
 out dx, al
 inc dl
 not al
 out dx, al
 not al
 out dx, al
 out dx, al
endif
 push ds
 push es
 push fs
 push gs
 call loadebp
 mov esi,ebp
 cld
 mov ds,cs:[esi].datasegsel                            ; Axon
 mov es,[esi].datasegsel                               ; Axon
 mov eax,[esi].tmTimerRate
 add [esi].tmTicker,eax
 add [esi].tmIntCount,eax
 cmp byte ptr [esi].tmIntCount+2,0
 je @@noorgcall
 mov byte ptr [esi].tmIntCount+2,0
 pushfd
 call [esi].tmOldTimer
@@noorgcall:
 mov al,20h
 out 20h,al
 mov ebx,[esi].maxtimerrate
 mov ecx,[esi].stimerlen
 mov edx,[esi].stimerpos
 sub edx,ebx
 ja @@another
 mov edx,ecx
@@another:
 mov [esi].stimerpos,edx
 cmp edx,ebx
 jb @@intervalok
 mov edx,ebx
@@intervalok:
 mov [esi].tmTimerRate,edx
 mov al,34h
 out 43h,al
 mov al,dl
 out 40h,al
 mov al,dh
 out 40h,al
 cmp [esi].stimerpos,ecx
 jne @@notick
 cmp [esi].tmInRoutine,0
 jnz @@notick
 mov [esi].tmInRoutine,1
 mov dword ptr [esi].tmOldSSESP,esp
 mov word ptr [esi].tmOldSSESP+4,ss

 push ds                                               ; Axon
 pop ss                                                ; Axon
 lea esp,[esi].tmStack+1024                            ; Axon

 sti
 call gusPlayTick
 call PlayTick
 cli
 lss esp,[ebp].tmOldSSESP                              ; Axon
 mov ds:[ebp].tmInRoutine,0
@@notick:
 pop gs
 pop fs
 pop es
 pop ds

if rasta eq 1
 mov dx, 3c8h
 xor al, al
 out dx, al
 inc dl
 out dx, al
 out dx, al
 out dx, al
endif
 popad
 iretd
endp

tmInit PROC
 mov [ebp].datasegsel,ds                               ; Axon
 xor eax,eax
 mov [ebp].stimerpos,eax
 mov [ebp].tmIntCount,eax
 mov [ebp].tmInRoutine,0
 mov [ebp].tmTimerRate,65536
 mov eax,-65536
 sub eax,[ebp].stimerlen
 mov [ebp].tmTicker,eax
 push es
                                        ; Axon
; mov ax,3508h
; int 21h
; mov dword ptr [ebp].tmOldTimer+0,ebx
; mov word ptr [ebp].tmOldTimer+4,es
 mov bl,8
 GetIntVec
 mov dword ptr [ebp].tmOldTimer+0,edx
 mov word ptr [ebp].tmOldTimer+4,cx
;
 pop es
 push ds
 push cs
 pop ds
 call @@getadr
@@getadr:
 pop edx
 add edx,tmTimerHandler-@@getadr
; BL = int, CX:EDX

; DS:EDX - routine
; mov ax,2508h
 mov bl,8
 mov cx,ds
 SetIntVec
; int 21h
;
 pop ds
 mov al,34h
 out 43h,al
 mov eax,[ebp].tmTimerRate
 out 40h,al
 mov al,ah
 out 40h,al
 ret
endp


; BL = int, CX:EDX

; DS:EDX - routine
;;;; mov ax,2508h
; mov bl,8
; mov cx,ds
; SetIntVec
; int 21h
tmClose PROC
 push ds
 mov bl,8
; mov ax,2508h
 lds edx,[ebp].tmOldTimer
 mov cx,ds
 setintvec
; int 21h
 pop ds
 mov al,34h
 out 43h,al
 xor al,al
 out 40h,al
 out 40h,al
 ret
endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
xmpGetTimer PROC
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 pushf
 xor eax,eax
 cli
 out 43h,al
 in al,40h
 mov ah,al
 in al,40h
 popf
 xchg ah,al
 neg eax
 push ebp
 call loadebp
 add eax,[ebp].tmTimerRate
 add eax,[ebp].tmTicker
 pop ebp
 ret
endp

;° GUS °°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

gusoutp PROC
 add edx,[ebp].gusport
 out dx,al
 sub edx,[ebp].gusport
 ret
endp

gusout PROC
uses edx
 mov dx,103h
 xchg al,bl
 call gusoutp
 add dl,2
 xchg al,bl
 call gusoutp
 ret
endp

gusoutd PROC
uses edx
 mov dx,103h
 xchg al,bl
 call gusoutp
 add dl,2
 xchg al,bl
 call gusoutp
 call gusdelay
 call gusoutp
 ret
endp

gusoutw PROC
uses edx
 mov dx,103h
 xchg al,bl
 call gusoutp
 inc edx
 xchg al,bl
 add edx,[ebp].gusport
 out dx,ax
 ret
endp

gusin PROC
uses edx
 mov dx,103h
 xchg al,bl
 call gusoutp
 add dl,2
 xchg al,bl
 add edx,[ebp].gusport
 in al,dx
 ret
endp

gusinw PROC
uses edx
 mov dx,103h
 xchg al,bl
 call gusoutp
 inc edx
 xchg al,bl
 add edx,[ebp].gusport
 in ax,dx
 ret
endp

gusdelay PROC
uses edx, eax
 mov dx,107h
 add edx,[ebp].gusport
 in al,dx
 in al,dx
 in al,dx
 in al,dx
 in al,dx
 in al,dx
 in al,dx
 ret
endp

gusselchn PROC
uses edx
 mov dx,102h
 xchg al,cl
 call gusoutp
 xchg al,cl
 ret
endp


gussetpoint PROC
uses eax
 shr eax,7
 and eax,1FFFh
 call gusoutw
 mov eax,[esp]
 inc bl
 shl eax,9
 call gusoutw
 dec bl
 ret
endp

gusopenchan PROC
 cmp al,14
 jae @@chanok
 mov al,14
@@chanok:
 mov [ebp].guschannels,eax
 mov bl,04ch
 mov al,0
 call gusout
 call gusdelay
 call gusdelay
 inc al
 call gusout
 call gusdelay
 call gusdelay
 mov bl,0eh
 mov al,byte ptr [ebp].guschannels
 dec al
 or al,0c0h
 call gusout
 xor ecx,ecx
@@initloop:
 call gusselchn
 xor ax,ax
 mov bl,9
 call gusoutw
 mov al,3
 mov bl,0
 call gusoutd
 mov al,3
 mov bl,0dh
 call gusoutd
 mov al,3fh
 mov bl,6
 call gusout
 call gusdelay
 inc ecx
 cmp ecx,32
 jne @@initloop
 mov bl,4ch
 mov al,7
 call gusout
 mov cl,0
 call gusselchn
 xor edx,edx
 mov al,8
 call gusoutp
 ret
endp

gusfadevol PROC
 mov bl,89h
 call gusinw
 movzx eax,ax
 mov bl,0
 cmp eax,edx
 jbe @@up
 xchg eax,edx
 mov bl,40h
@@up:
 sub edx,eax
 jz @@done
 cmp edx,4096
 jae @@normfade
 cmp bl,40h
 je @@swapped
 add eax,edx
@@swapped:
 mov bl,9
 call gusoutw
 jmp @@done
@@normfade:
 add edx,eax
 cmp eax,4096
 jae @@stok
 mov eax,4096
@@stok:
 cmp edx,64512
 jbe @@eok
 mov edx,64512
@@eok:
 push ebx
 mov al,ah
 mov bl,7
 call gusout
 mov al,dh
 mov bl,8
 call gusout
 pop eax
 mov bl,0dh
 call gusoutd
@@done:
 ret
endp

gusfadevoldown PROC uses ebx eax
 mov bl,07h
 mov al,04h
 call gusout
 mov bl,08h
 mov al,0fch
 call gusout
 mov bl,0dh
 mov al,40h
 call gusoutd
 ret
endp

gusPlayTick PROC
 cmp [ebp].gusport,0
 je @@nogus
 lea edi,[ebp].chandata
 xor ecx,ecx
@@clearloop:
 cmp [edi].chGUSInited,0
 je @@nostop
 cmp [edi].chGUSStopIt,0
 je @@nostop
 call gusselchn
 mov bl,0
 mov al,[edi].chGUSMode
 or al,3
 call gusoutd
 call gusfadevoldown
 mov [edi].chGUSStopIt,0
@@nostop:
 add edi,channelsize
 inc ecx
 cmp ecx,[ebp].head.hdNChannels
 jne @@clearloop
 xor ecx,ecx
@@waitloop:
 call gusselchn
 mov bl,8dh
@@dowait:
 call gusin
 test al,1
 jz @@dowait
 inc ecx
 cmp ecx,[ebp].head.hdNChannels
 jne @@waitloop
 lea edi,[ebp].chandata
 xor ecx,ecx
@@playloop:
 call gusselchn
 cmp [edi].chGUSInited,0
 je @@quiet
 cmp [edi].chGUSChangeSamp,0
 je @@samesample
 mov bl,2
 mov eax,[edi].chGUSLoopPos
 call gussetpoint
 mov bl,4
 mov eax,[edi].chGUSEndPos
 call gussetpoint
@@samesample:
 cmp [edi].chGUSNextPos,-1
 je @@noposchange
 mov eax,[edi].chGUSNextPos
 add eax,[edi].chGUSStartPos
 cmp eax,[edi].chGUSEndPos
 jb @@posok
 mov eax,[edi].chGUSEndPos
 dec eax
@@posok:
 mov bl,10
 call gussetpoint
 mov bl,80h
 call gusin
 mov bl,0
 and al,40h
 or al,[edi].chGUSMode
 call gusout
@@noposchange:
 mov bl,80h
 call gusin
 test bl,1
 jnz @@quiet
 mov bl,0ch
 mov al,[edi].chGUSPan
 call gusout
 mov bl,1
 mov ax,[edi].chGUSFrq
 call gusoutw
 movzx edx,[edi].chGUSVol
 call gusfadevol
 jmp @@nextchan
@@quiet:
 call gusfadevoldown
@@nextchan:
 mov [edi].chGUSChangeSamp,0
 mov [edi].chGUSNextPos,-1
 add edi,channelsize
 inc ecx
 cmp ecx,[ebp].head.hdNChannels
 jne @@playloop
 ret
@@nogus:
call a_noize
 ret
endp

gusOpen PROC
 cmp [ebp].gusport,0
 je @@nogus
 mov eax,[ebp].head.hdNChannels
 call gusopenchan
 mov cl,0
 call gusselchn
 xor edx,edx
 mov al,9
 call gusoutp
@@nogus:
 ret
endp

gusClose PROC
 cmp [ebp].gusport,0
 je @@nogus
 mov eax,14
 call gusopenchan
@@nogus:
 ret
endp

gusUploadSamples PROC
 cmp [ebp].gusport,0
 je @@done
 shr ecx,4
 jz @@done
 xor ebx,ebx
@@bigloop:
 pushf
 cli
 mov edx,[ebp].gusport
 add dx,103h
 mov al,44h
 out dx,al
 add dl,2
 mov eax,ebx
 shr eax,16
 out dx,al
 sub dl,2
 mov al,43h
 out dx,al
 inc dl
 cli
@@loop:
 mov eax,ebx
 out dx,ax
 lodsb
 add dl,3
 out dx,al
 sub dl,3
 inc ebx
 test bl,0fh
 jnz @@loop
 popf
 dec ecx
 jnz @@bigloop
@@done:
 ret
endp

ideal
proc    gusGetPort
        xor     eax, eax
        xor     ecx, ecx
        dec     ecx
        jmp     @@scanentry
@@envscan:
        repne   scasb
@@scanentry:
        cmp     [byte edi], 0
        je      @@done
        cmp     [dword edi], 'RTLU'
        jne     @@envscan
        cmp     [dword edi+4], 'DNSA'
        jne     @@envscan
        cmp     [word edi+8], '2='
        jne     @@envscan
        cmp     [word edi+11], ',0'
        jne     @@envscan
        mov     al,[edi+10]
        sub     al,30h
        shl     al,4
        mov     ah,2
@@done:
        ret
endp
masm

;ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ Simplex Adlib Player ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ
;this doesn't just read raw data to output to adlib like the one
;used in the last starport intro. This player really does have
;note & instrument data it reads and processes!

;±±±±±±±±±±±±±±±± output data to adlib ±±±±±±±±±±±±±±
a_lodsboutaw03: ;size optimization related entry (instrument loading)
        call    a_lodsboutaw
        add     ah,3
a_lodsboutaw: ;size optimization related entry (instrument loading)
        lodsb
a_outaw PROC NEAR ;ah=reg,al=data
        push    eax
        push    ecx
        xchg    al,ah
        mov     dx,388h
        out     dx,al
        mov     ecx,7
        call    a_wait
        inc     dl
        mov     al,ah
        out     dx,al
        mov     ecx,30
        call    a_wait
        pop     ecx
        pop     eax
        ret
a_wait: in      al,dx
        dec     ecx
        jnz     a_wait
        ret
a_outaw ENDP

;±±±±±±±±±±±±±±±± load instrument to adlib ±±±±±±±±±±±±±±
a_loadinstrument PROC NEAR
        ;bx=channel, ds:si=offset to instrument data
        mov     ah,a_inst_table[ebx]
        mov     ecx,4
@@1:    call    a_lodsboutaw03
        add     ah,20h-3
        dec     ecx
        jnz     @@1
        add     ah,40h
        call    a_lodsboutaw03
        mov     ah,bl
        add     ah,0c0h
        jmp     a_lodsboutaw
a_loadinstrument ENDP

;±±±±±±±±±±±±±±±± set note on/off ±±±±±±±±±±±±±±
a_playnote PROC NEAR
        ;bx=channel, ax=data
        push    ebx
        xchg    ah,bl
        add     ah,0a0h
        call    a_outaw
        mov     al,bl
        add     ah,010h
        pop     ebx
        jmp     a_outaw
a_playnote ENDP

;±±±±±±±±±±±±±±±± initialize/clear/shutup adlib ±±±±±±±±±±±±±±
a_init PROC NEAR
        pusha
        mov     ax,00120h
        call    a_outaw
        mov     ax,00800h
        call    a_outaw
        mov     ah,0bdh
        call    a_outaw
        mov     ebp,9
        xor     ebx,ebx
        mov     edi,OFFSET music_instruments
@@x1:   mov     esi,[edi]
        add     edi,4
        call    a_loadinstrument
        xor     eax,eax
        call    a_playnote
        inc     ebx
        dec     ebp
        jnz     @@x1
        popa
        ret
a_init ENDP

a_noize:
        pusha
        mov     ebx, 7
@@zz:
        mov     al, basta[ebx]
        add     nasta[ebx], al
        and     nasta[ebx], 3
        jnz     @@vit
        push    ebx
        xor     ax, ax
        call    a_playnote
        mov     ebx, [esp]
        mov     eax, [dox1]
        mov     ebx, [dox2]
        add     [dox1], ebx
        mov     [dox2], eax
        xor     ax, 1234h
        call    a_playnote
        pop     ebx
@@vit:
        dec     ebx
        jns     @@zz
        popa
        ret

nasta   db 8 dup (0)
basta   db 1,2,5,7,3,4,5,6,11

;adlib player data
a_inst_table LABEL BYTE
        db 20h+0,20h+1,20h+2,20h+8,20h+9,20h+10,20h+16,20h+17,20h+18
NTB equ 8192 ;+1024*1
a_note_table LABEL WORD
        dw NTB+363,NTB+385,NTB+408,NTB+432,NTB+458,NTB+485
        dw NTB+514,NTB+544,NTB+577,NTB+611,NTB+647,NTB+868
        ;note: a zero word is expected after this table (found in col0)

;################## Music - (tune by skaven/fc) ###################
;generated with ST3->SIMPLEXADLIB, handoptimized by psi (283 bytes)
music_channels equ 8
music_speed equ 8
music_instruments LABEL BYTE
dd OFFSET ains6
dd OFFSET ains2
dd OFFSET ains4
dd OFFSET ains3
dd OFFSET ains3
dd OFFSET ains1
dd OFFSET ains1
dd OFFSET ains4
ains1 LABEL BYTE
db 65,194,6,0,35,242,240,240,1,0,4
ains2 LABEL BYTE
db 145,64,135,128,243,111,35,3,1,1,2
ains3 LABEL BYTE
db 225,33,17,128,17,19,34,34,0,0,12
ains4 LABEL BYTE
db 97,33,27,0,98,132,86,85,0,0,14
ains6 LABEL BYTE
db 145,64,135,136,243,111,35,3,1,1,2
music_patterns LABEL dword
ach0 dd OFFSET ach5d,OFFSET ach0dr
ach1 dd OFFSET ach1d,OFFSET ach1dr
ach2 dd OFFSET ach2d,OFFSET ach2dr
ach3 dd OFFSET ach3d,OFFSET ach3d
ach4 dd OFFSET ach4d,OFFSET ach4d
ach5 dd OFFSET ach5d,OFFSET ach5d
ach6 dd OFFSET ach6d,OFFSET ach6d
ach7 dd OFFSET ach7d,OFFSET ach7d
ach0d LABEL BYTE
db 081h
ach0dr LABEL BYTE
db 057h,050h,050h,055h,057h,050h,055h,057h
db 050h,055h,057h,050h,055h,057h,050h,055h
db 0
ach1d LABEL BYTE
db 081h
ach1dr LABEL BYTE
db 050h,055h,057h,050h,055h,057h,050h,055h
db 057h,050h,055h,057h,050h,055h,057h,050h
db 0
ach2d LABEL BYTE
db 0C0h,050h,084h
db 030h,020h,030h,020h,02Ah,01Ah,02Ah,01Ah
db 030h,020h,030h,020h,02Ah,01Ah,02Ah,01Ah
ach2dr LABEL BYTE
db 030h,020h,030h,020h,02Ah,01Ah,02Ah,01Ah
db 025h,015h,025h,015h,028h,018h,02Ah,01Ah
db 0
ach3d LABEL BYTE
db 0A0h,050h,040h,0C0h,040h,088h,040h,040h
db 03Ah,042h,090h,045h,088h,040h,042h,040h
db 047h,090h,04Ah,088h,045h,098h,040h
db 0
ach4d LABEL BYTE
db 0A0h,050h,030h,0C0h,047h,088h,047h,043h
db 042h,045h,047h,045h,048h,047h,047h,050h
db 052h,084h,050h,04Ah,088h,050h,098h,045h
db 0
ach5d LABEL BYTE
db 0C0h,020h,0A0h,010h,010h,090h,010h,02Ah
db 025h,088h,028h,02Ah,090h,010h,02Ah,025h
db 088h,028h,02Ah
db 0
ach6d LABEL BYTE
db 0C0h,020h,0A0h,020h,020h,090h,020h,01Ah
db 015h,088h,018h,01Ah,090h,020h,01Ah,015h
db 088h,018h,01Ah
db 0
ach7d LABEL BYTE
db 0C0h,00Ch,0FEh,050h,090h,00Ch,081h,04Ah
db 050h,084h,052h,055h,086h,04Ah,081h,050h
db 04Ah,086h,050h,082h,055h,098h,045h
db 0
;#########################################################


;adlib data
a_musiccnt      dd 0
a_chdelaycnt    db 9 dup(0)
a_chdelay       db 9 dup(0)

dox1    dd 546984335
dox2    dd 213193729

end
