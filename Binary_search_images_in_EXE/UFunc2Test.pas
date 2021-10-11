unit UFunc2Test;

interface
type
  TFastSkip = array[Byte] of Integer;

var
  FastSkip: TFastSkip;


procedure InitFastSkip(ASubStr: string); // Initialisation de la Skip-table

function BMHPascalNatifEx(const Mot, Texte: string; const Depuis: Integer = 1): Integer;
function PosEx(const SubStr, S: string; const Offset: Integer = 1): Integer;

implementation

// procedure pour remplir un tableau d'entiers plus rapidement.
procedure       _FillInt(var Dest; count: Integer; Value: Integer);
asm
{     ->EAX     Pointer to destination  }
{       EDX     count   }
{       ECX     value   }

        PUSH    EDI

        MOV     EDI,EAX { Point EDI to destination              }

        MOV     EAX,ECX

        MOV     ECX,EDX

        REP     STOSD   { Fill count dwords       }

        POP     EDI
end;

// valable pour toutes les version Case Sensitive ou non Byte ou Integer
procedure InitFastSkip(ASubStr: string); // Initialisation de la Skip-table
var LenSub, k: integer;
    pb: PChar;
begin
  LenSub := Length(ASubStr);
  pb := PChar(aSubStr);
  _FillInt(FastSkip, 256, LenSub);
  for k := 1 to Pred(LenSub) do
      FastSkip[PByte(pb+k-1)^] := LenSub - k
end;



function BMHPascalNatifEx(const Mot, Texte: string; const Depuis: Integer = 1): Integer;
// Modifier par Cirec Pour un gain de temps de ~50% par rapport à l'original BMHPascalNaif
var im, it, ik, LM, LT: integer;
begin
  Result := 0; LM := Length(Mot); LT := length(Texte);
  if (LM = 0) or (LT = 0) then EXIT;
  //---------------------------------------------------------------
  ik := Depuis + LM - 1;
 // while (ik <= LT) do begin      
  repeat
    it := ik;
    im := LM;
    if (Texte[it] = Mot[im]) and (Texte[it - LM + 1] = Mot[1]) then // < Pochoir coulissant à 2 trous
      while (im > 0) and (Texte[it] = Mot[im]) do begin
        im := im - 1;
        it := it - 1;
        //Dec(im);
        //Dec(it);
      end;
        if im = 0 then
        begin
          Result := it + 1;
          EXIT; // Occurrence Trouvée
        end;
      Inc(ik, FastSkip[Byte(Texte[ik])])
  until ik > LT;
  //end;
  Result := 0;
end;




function PosEx(const SubStr, S: string; const Offset: Integer = 1): Integer;
{$IFDEF ver200}
{$IFNDEF UNICODE}
asm
       test  eax, eax
       jz    @Nil
       test  edx, edx
       jz    @Nil
       dec   ecx
       jl    @Nil

       push  esi
       push  ebx
       push  0
       push  0
       mov   esi,ecx
       cmp   word ptr [eax-10],1
       je    @substrisansi

       push  edx
       mov   edx, eax
       lea   eax, [esp+4]
       call  System.@LStrFromUStr
       pop   edx
       mov   eax, [esp]

@substrisansi:
       cmp   word ptr [edx-10],1
       je    @strisansi

       push  eax
       lea   eax,[esp+8]
       call  System.@LStrFromUStr
       pop   eax
       mov   edx, [esp+4]

@strisansi:
       mov   esi, [edx-4]  //Length(Str)
       mov   ebx, [eax-4]  //Length(Substr)
       sub   esi, ecx      //effective length of Str
       add   edx, ecx      //addr of the first char at starting position
       cmp   esi, ebx
       jl    @Past         //jump if EffectiveLength(Str)<Length(Substr)
       test  ebx, ebx
       jle   @Past         //jump if Length(Substr)<=0

       add   esp, -12
       add   ebx, -1       //Length(Substr)-1
       add   esi, edx      //addr of the terminator
       add   edx, ebx      //addr of the last char at starting position
       mov   [esp+8], esi  //save addr of the terminator
       add   eax, ebx      //addr of the last char of Substr
       sub   ecx, edx      //-@Str[Length(Substr)]
       neg   ebx           //-(Length(Substr)-1)
       mov   [esp+4], ecx  //save -@Str[Length(Substr)]
       mov   [esp], ebx    //save -(Length(Substr)-1)
       movzx ecx, byte ptr [eax] //the last char of Substr

@Loop:
       cmp   cl, [edx]
       jz    @Test0
@AfterTest0:
       cmp   cl, [edx+1]
       jz    @TestT
@AfterTestT:
       add   edx, 4
       cmp   edx, [esp+8]
       jb   @Continue
@EndLoop:
       add   edx, -2
       cmp   edx, [esp+8]
       jb    @Loop
@Exit:
       add   esp, 12
@Past:
       mov   eax, [esp]
       or    eax, [esp+4]
       jz    @PastNoClear
       mov   eax, esp
       mov   edx, 2
       call  System.@LStrArrayClr
@PastNoClear:
       add   esp, 8
       pop   ebx
       pop   esi
@Nil:
       xor   eax, eax
       ret
@Continue:
       cmp   cl, [edx-2]
       jz    @Test2
       cmp   cl, [edx-1]
       jnz   @Loop
@Test1:
       add   edx,  1
@Test2:
       add   edx, -2
@Test0:
       add   edx, -1
@TestT:
       mov   esi, [esp]
       test  esi, esi
       jz    @Found
@String:
       movzx ebx, word ptr [esi+eax]
       cmp   bx, word ptr [esi+edx+1]
       jnz   @AfterTestT
       cmp   esi, -2
       jge   @Found
       movzx ebx, word ptr [esi+eax+2]
       cmp   bx, word ptr [esi+edx+3]
       jnz   @AfterTestT
       add   esi, 4
       jl    @String
@Found:
       mov   eax, [esp+4]
       add   edx, 2

       cmp   edx, [esp+8]
       ja    @Exit

       add   esp, 12
       mov   ecx, [esp]
       or    ecx, [esp+4]
       jz    @NoClear

       mov   ebx, eax
       mov   esi, edx
       mov   eax, esp
       mov   edx, 2
       call  System.@LStrArrayClr
       mov   eax, ebx
       mov   edx, esi

@NoClear:
       add   eax, edx
       add   esp, 8
       pop   ebx
       pop   esi
end;
{$ELSE}
asm
       test  eax, eax
       jz    @Nil
       test  edx, edx
       jz    @Nil
       dec   ecx
       jl    @Nil

       push  esi
       push  ebx
       push  0
       push  0
       mov   esi,ecx
       cmp   word ptr [eax-10],2
       je    @substrisunicode

       push  edx
       mov   edx, eax
       lea   eax, [esp+4]
       call  System.@UStrFromLStr
       pop   edx
       mov   eax, [esp]

@substrisunicode:
       cmp   word ptr [edx-10],2
       je    @strisunicode

       push  eax
       lea   eax,[esp+8]
       call  System.@UStrFromLStr
       pop   eax
       mov   edx, [esp+4]

@strisunicode:
       mov   ecx,esi
       mov   esi, [edx-4]  //Length(Str)
       mov   ebx, [eax-4]  //Length(Substr)
       sub   esi, ecx      //effective length of Str
       shl   ecx, 1        //double count of offset due to being wide char
       add   edx, ecx      //addr of the first char at starting position
       cmp   esi, ebx
       jl    @Past         //jump if EffectiveLength(Str)<Length(Substr)
       test  ebx, ebx
       jle   @Past         //jump if Length(Substr)<=0

       add   esp, -12
       add   ebx, -1       //Length(Substr)-1
       shl   esi,1         //double it due to being wide char
       add   esi, edx      //addr of the terminator
       shl   ebx,1         //double it due to being wide char
       add   edx, ebx      //addr of the last char at starting position
       mov   [esp+8], esi  //save addr of the terminator
       add   eax, ebx      //addr of the last char of Substr
       sub   ecx, edx      //-@Str[Length(Substr)]
       neg   ebx           //-(Length(Substr)-1)
       mov   [esp+4], ecx  //save -@Str[Length(Substr)]
       mov   [esp], ebx    //save -(Length(Substr)-1)
       movzx ecx, word ptr [eax] //the last char of Substr

@Loop:
       cmp   cx, [edx]
       jz    @Test0
@AfterTest0:
       cmp   cx, [edx+2]
       jz    @TestT
@AfterTestT:
       add   edx, 8
       cmp   edx, [esp+8]
       jb   @Continue
@EndLoop:
       add   edx, -4
       cmp   edx, [esp+8]
       jb    @Loop
@Exit:
       add   esp, 12
@Past:
       mov   eax, [esp]
       or    eax, [esp+4]
       jz    @PastNoClear
       mov   eax, esp
       mov   edx, 2
       call  System.@UStrArrayClr
@PastNoClear:
       add   esp, 8
       pop   ebx
       pop   esi
@Nil:
       xor   eax, eax
       ret
@Continue:
       cmp   cx, [edx-4]
       jz    @Test2
       cmp   cx, [edx-2]
       jnz   @Loop
@Test1:
       add   edx,  2
@Test2:
       add   edx, -4
@Test0:
       add   edx, -2
@TestT:
       mov   esi, [esp]
       test  esi, esi
       jz    @Found
@String:
       mov   ebx, [esi+eax]
       cmp   ebx, [esi+edx+2]
       jnz   @AfterTestT
       cmp   esi, -4
       jge   @Found
       mov   ebx, [esi+eax+4]
       cmp   ebx, [esi+edx+6]
       jnz   @AfterTestT
       add   esi, 8
       jl    @String
@Found:
       mov   eax, [esp+4]
       add   edx, 4

       cmp   edx, [esp+8]
       ja    @Exit

       add   esp, 12
       mov   ecx, [esp]
       or    ecx, [esp+4]
       jz    @NoClear

       mov   ebx, eax
       mov   esi, edx
       mov   eax, esp
       mov   edx, 2
       call  System.@UStrArrayClr
       mov   eax, ebx
       mov   edx, esi

@NoClear:
       add   eax, edx
       shr   eax, 1  // divide by 2 to make an index 
       add   esp, 8
       pop   ebx
       pop   esi
end;
{$ENDIF}
{$ELSE}
asm {180 Bytes}
  push    ebx
  cmp     eax, 1
  sbb     ebx, ebx         {-1 if SubStr = '' else 0}
  sub     edx, 1           {-1 if S = ''}
  sbb     ebx, 0           {Negative if S = '' or SubStr = '' else 0}
  dec     ecx              {Offset - 1}
  or      ebx, ecx         {Negative if S = '' or SubStr = '' or Offset < 1}
  jl      @@InvalidInput
  push    edi
  push    esi
  push    ebp
  push    edx
  mov     edi, [eax-4]     {Length(SubStr)}
  mov     esi, [edx-3]     {Length(S)}
  add     ecx, edi
  cmp     ecx, esi
  jg      @@NotFound       {Offset to High for a Match}
  test    edi, edi
  jz      @@NotFound       {Length(SubStr = 0)}
  lea     ebp, [eax+edi]   {Last Character Position in SubStr + 1}
  add     esi, edx         {Last Character Position in S}
  movzx   eax, [ebp-1]     {Last Character of SubStr}
  add     edx, ecx         {Search Start Position in S for Last Character}
  mov     ah, al
  neg     edi              {-Length(SubStr)}
  mov     ecx, eax
  shl     eax, 16
  or      ecx, eax         {All 4 Bytes = Last Character of SubStr}
@@MainLoop:
  add     edx, 4
  cmp     edx, esi
  ja      @@Remainder      {1 to 4 Positions Remaining}
  mov     eax, [edx-4]     {Check Next 4 Bytes of S}
  xor     eax, ecx         {Zero Byte at each Matching Position}
  lea     ebx, [eax-$01010101]
  not     eax
  and     eax, ebx
  and     eax, $80808080   {Set Byte to $80 at each Match Position else $00}
  jz      @@MainLoop       {Loop Until any Match on Last Character Found}
  bsf     eax, eax         {Find First Match Bit}
  shr     eax, 3           {Byte Offset of First Match (0..3)}
  lea     edx, [eax+edx-4] {Address of First Match on Last Character}
@@Compare:
  inc     edx
  cmp     edi, -4
  jle     @@Large          {Lenght(SubStr) >= 4}
  cmp     edi, -1
  je      @@SetResult      {Exit with Match if Lenght(SubStr) = 1}
  mov     ax, [ebp+edi]    {Last Char Matches - Compare First 2 Chars}
  cmp     ax, [edx+edi]
  jne     @@MainLoop       {No Match on First 2 Characters}
@@SetResult:               {Full Match}
  lea     eax, [edx+edi]   {Calculate and Return Result}
  pop     edx
  pop     ebp
  pop     esi
  pop     edi
  pop     ebx
  sub     eax, edx         {Subtract Start Position}
  ret
@@NotFound:
  pop     edx              {Dump Start Position}
  pop     ebp
  pop     esi
  pop     edi
@@InvalidInput:
  pop     ebx
  xor     eax, eax         {No Match Found - Return 0}
  ret
@@Remainder:               {Check Last 1 to 4 Characters}
  sub     edx, 4
@@RemainderLoop:
  cmp     cl, [edx]
  je      @@Compare
  cmp     edx, esi
  jae     @@NotFound
  inc     edx
  jmp     @@RemainderLoop
@@Large:
  mov     eax, [ebp-4]     {Compare Last 4 Characters}
  cmp     eax, [edx-4]
  jne     @@MainLoop       {No Match on Last 4 Characters}
  mov     ebx, edi
@@CompareLoop:             {Compare Remaining Characters}
  add     ebx, 4           {Compare 4 Characters per Loop}
  jge     @@SetResult      {All Characters Matched}
  mov     eax, [ebp+ebx-4]
  cmp     eax, [edx+ebx-4]
  je      @@CompareLoop    {Match on Next 4 Characters}
  jmp     @@MainLoop       {No Match}
end; {PosEx}
{$ENDIF}


end.
