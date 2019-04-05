Unit Images;

Interface

{$I-,G+}

Const
    (* Images errors *)
  ieOK               =   0;

  ieFileNotFount     =   2;
  iePathNotFound     =   3;
  ieTooManyOpenFiles =   4;
  ieAccessDenied     =   5;
  ieNoMemory         = 203;

  ieNotAPCX          = 256;
  ieNotACEL          = 257;


Type
  TPaletteEntry = Record
    R,G,B: Byte
  End;

  TPalette = array[0..255] of TPaletteEntry;

  TImage = Record
    SizeX, SizeY: Integer;
    Buffer      : Pointer;
    Palette     : TPalette;
  End;

  (* Images and file formats *)
Function  LoadCel( Name: String; Var CEL: TImage ): Integer;
Function  LoadPCX( Name: String; Var PCX: TImage ): Integer;
Procedure FreeImage( Var Image: TImage );

  (* Palette manipulation *)
Procedure GetAllPals( Var Palette );
Procedure SetAllPals( Var Palette );
Procedure SetPal( Col,R,G,B: Byte );
Procedure GetPal( Col: Byte; Var R,G,B: Byte );
Procedure CyclePal( StartPal, EndPal: byte; GoUp: Boolean);


Implementation

Const
  MaxAllocMem = 65528;

Type
  Bytes = array[0..$FFFF-1] of Byte;

  PCX_Header = Record
    Manufacturer : byte;                 { must be 10 }
    Version      : byte;
    Encoding     : byte;                 { should be 1 }
    BitsPerPixel : byte;
    Xmin,Ymin    : integer;
    Xmax,Ymax    : integer;
    HDPI         : integer;
    VDPI         : integer;
    ColorMap     : array[0..47] of byte; { I dont know what they are... Help me? }
    Reserved     : byte;                 { must be 0 }
    NPlanes      : byte;
    BytesPerLine : integer;
    PaletteInfo  : integer;
    HScreenSize  : integer;
    VScreenSize  : integer;
    Filler       : array[0..53] of byte; { all must be 0 }
 End;

Function LoadCel( Name: String; Var CEL: TImage ): Integer;
Const
  CELSiganture = $01409119;
Var
  CelFile  : File;
  Siganture: LongInt;
Begin
  FillChar( CEl, SizeOf(CEL), 0 );

  Assign(CelFile, Name);
  Reset( CelFile, 1);

  If InOutRes<>0 Then
    Begin
      LoadCEL:= IOResult;
      Exit;
    End;

  BlockRead( CELFile, Siganture, 4 );
  If Siganture<>CELSiganture Then
    Begin
      Close( CelFile );
      LoadCel:= ieNotACel;
      Exit;
    End;

  With CEL do
    Begin
      BlockRead(CelFile, SizeY, 2 );
      SizeX:= (FileSize(CelFile)-800) div SizeY;

      If (SizeX*SizeY>MaxAllocMem) or (MaxAvail<SizeX*SizeY) Then
        Begin
          Close( CelFile );
          LoadCEL:= ieNoMemory;
          Exit;
        End;

      GetMem( Buffer, SizeX*SizeY );
      Seek( CelFile, 32 );
      BlockRead( CelFile, Palette, SizeOf(Palette) );
      Seek(CelFile, 800);
      BlockRead(CelFile, Buffer^, SizeX*SizeY);
    End;

  Close(CelFile);
  LoadCel:= ieOK
End;

Function LoadPCX( Name: String; Var PCX: TImage ): Integer;
Var
  F: File;
  Header: PCX_Header;
  i, Count : Word;
  TotalBytes: Word;
  x, y: Word;
  Data, Color: Byte;
Begin
  FillChar( PCX, SizeOf(PCX), 0 );
  Assign( F, Name );
  Reset( F, 1 );

  If InOutRes<>0 Then
    Begin
      LoadPCX:= IOResult;
      Exit;
    End;

  BlockRead( F, Header, 128 );
  If (Header.Manufacturer<>10) or (Header.Reserved<>0) Then
    Begin
      Close( F );
      LoadPCX:= ieNotAPCX;
      Exit;
    End;

  With Header do
    Begin
      PCX.SizeX:= XMax - XMin + 1;
      PCX.SizeY:= YMax - YMin + 1;
      TotalBytes:= NPlanes * BytesPerLine;
    End;

  If (PCX.SizeX*PCX.SizeY>MaxAllocMem) or (MaxAvail<PCX.SizeX*PCX.SizeY) Then
    Begin
      Close( F );
      LoadPCX:= ieNoMemory;
      Exit;
    End;

  With PCX do GetMem  ( Buffer , SizeX*SizeY );
  With PCX do FillChar( Buffer^, SizeX*SizeY, 0 );
  Seek( F, 128 );

  i:= 0;
  For y:= 0 to PCX.SizeY-1 do
    Begin
      Count:= 0;
      Repeat
        BlockRead( F, Data, 1 );
	If Data and (not $3F) = (not $3F)
	  Then Begin
                 BlockRead( F, Color, 1 );
		 FillChar( Bytes(PCX.Buffer^)[i+Count], Data and $3F, Color );
                 Inc( Count, Data and $3F  );
	       End
	  Else Begin
		 Bytes(PCX.Buffer^)[i+Count]:= Data;
                 Inc( Count );
	       End;
      Until Count = TotalBytes;
      Inc( i, TotalBytes );
    End;

  If Header.Version = 5 Then
    Begin
      Seek( F, FileSize(F)-769 );
      BlockRead( F, Data, 1 );
      If Data = 12 Then
        With PCX do Begin
          BlockRead( F, PCX.Palette, 768 );
          For i:= 0 to 255 do
             Begin
               Palette[i].R:= Palette[i].R shr 2;
               Palette[i].G:= Palette[i].G shr 2;
               Palette[i].B:= Palette[i].B shr 2;
             End;
        End;
    End;

  Close( F );
  LoadPCX:= ieOK;
End;

Procedure FreeImage( Var Image: TImage );
Begin
  If Image.Buffer<>nil Then
    With Image do
      FreeMem( Buffer, SizeX*SizeY );
  FillChar( Image, SizeOf(Image) ,0 );
End;

 (* Palette manipulation *)
Procedure GetAllPals( Var Palette ); Assembler;
Asm
  MOV AL, 0FFH
  MOV DX, 0C6H
  OUT DX, AL
  MOV DX, 03C7H
  MOV AL, 0
  OUT DX, AL
  MOV DX, 03C9H

  LES DI, Palette
  MOV CX, 768
@B2:
  IN   AL, DX
  MOV  [ES:DI], AL
  INC  DI
  Loop @B2
End;

Procedure SetAllPals ( Var Palette ); Assembler;
Asm
   PUSH   DS
   LDS    SI, Palette
   MOV    DX, 03C8H
   MOV    AL, 0
   OUT    DX, AL
   INC    DX
   MOV    CX, 768
   REP    OUTSB
   POP    DS
End;

Procedure SetPal( Col,R,G,B: Byte ); assembler;
asm
  MOV    DX, 03C8H
  MOV    AL,[col]
  OUT    DX,AL
  INC    DX
  MOV    AL,[r]
  OUT    DX,AL
  MOV    AL,[g]
  OUT    DX,AL
  MOV    AL,[b]
  OUT    DX,AL
end;

Procedure GetPal( Col: Byte; Var R,G,B: Byte ); Assembler;
Asm
  MOV    DX     , 03C7H
  MOV    AL     , Col
  OUT    DX     , AL
  ADD    DX     , 2
  IN     AL     , DX
  LES    BX     , R
  MOV    ES:[BX], AL
  IN     AL     , DX
  LES    BX     , G
  MOV    ES:[BX], AL
  IN     AL     , DX
  LES    BX     , B
  MOV    ES:[BX], AL
End;

Procedure CyclePal( StartPal, EndPal: Byte; GoUp: Boolean );
Var
  CP     : TPalette;
  OnePal : TPaletteEntry;
  n      : Word;
Begin
  GetAllPals(CP);
  If GoUp
    Then Begin
           OnePal:= CP[StartPal];
           For n:= StartPal To EndPal-1 Do
             SetPal(n, CP[n+1].R, CP[n+1].G, CP[n+1].B );
           SetPal(EndPal, OnePal.R, OnePal.G, OnePal.B )
         End
    Else Begin
           OnePal:= CP[EndPal];
           For n:= StartPal+1 To EndPal Do
             SetPal(n, CP[n-1].R, CP[n-1].G, CP[n-1].B );
           SetPal(StartPal, OnePal.R, OnePal.G, OnePal.B )
         End
End;

End.
