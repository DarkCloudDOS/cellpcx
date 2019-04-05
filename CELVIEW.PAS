
(* ษออออออออออออออออออออออออออออออออออออออออออออออออออออออออป   *)
(* บ                                                        บÛ  *)
(* บ     Borland Pascal Programs                            บÛ  *)
(* บ     CelView Source Demo                                บÛ  *)
(* บ     dark - cloud programming                           บÛ  *)
(* วฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤถÛ  *)
(* บ                                                        บÛ  *)
(* บ     Copyright (C) 1996-7 Diego Iastrubni               บÛ  *)
(* บ                                                        บÛ  *)
(* ศออออออออออออออออออออออออออออออออออออออออออออออออออออออออผÛ  *)
(*  ฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿  *)

Program CelView;

{$G+,X+,I-,S-}

Const
  Usage  =
       #10#13 +
       #10#13 + 'CelView version 6.0, Copyright (C) 1996-97, dark-cloud (DGI).'+
       #10#13 + 'First release!!!' +
       #10#13 + 'Usage: CELVIEW filename[.cel].';

Const
  MCGA = $13;
  Text = $03;

Const
  MaxAllocMem = 65528;

    (* Images errors *)

  CELSignature: LongInt = $1409119;

  ieOK               =   0;
  ieFileNotFount     =   2;
  iePathNotFound     =   3;
  ieTooManyOpenFiles =   4;
  ieAccessDenied     =   5;
  ieNoMemory         = 203;

  ieNotACEL          = 257;
  ieImageTooBig	     = 258;


Type
  Bytes = array[0..$FFFF-1] of Byte;

  TPaletteEntry = Record
    R,G,B: Byte
  End;

  TPalette = array[0..255] of TPaletteEntry;

  TImage = Record
    SizeX, SizeY: Integer;
    Buffer      : ^Bytes;
    Palette     : TPalette;
  End;

  TTextScreen = array[0..79,0..24] of Record Char: Char; Color: Byte End;

Function FileExist( Name: String ): Boolean;
Var
  F: File;
Begin
  Assign( F, Name );
  Reset( F );
  Close( F );
  FileExist:= IOResult=0;
End;

Procedure FreeImage( Var Image: TImage );
Begin
  If Image.Buffer<>nil Then
    With Image do
      FreeMem( Buffer, SizeX*SizeY );
  FillChar( Image, SizeOf(Image) ,0 );
End;

Function LoadCel( Name: String; Var CEL: TImage ): Integer;
Const
  CELSiganture = $1409119;
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

Procedure SetAllPals( Var Palette ); Assembler;
Asm
   PUSH   DS
   LDS    SI, Palette
   MOV    DX, $3C8
   MOV    AL, 0
   OUT    DX, AL
   INC    DX
   MOV    CX, 768
   REP    OUTSB
   POP    DS
End;

Procedure PutPixel( X,Y: word; Color: Byte ); Assembler;
Asm
   MOV    ES,   SegA000
   MOV    BX,   X
   MOV    DX,   Y
   MOV    DI,   BX
   MOV    BX,   DX
   SHL    DX,   8
   SHL    BX,   6
   ADD    DX,   BX
   ADD    DI,   DX
   MOV    AL,   Color
   MOV    ES:[DI], AL
End;

Procedure PrintStr(const S: String); assembler;
Asm
   PUSH   DS
   LDS    SI,   S
   CLD
   LODSB
   XOR    AH,   AH
   XCHG   AX,   CX
   MOV    AH,   40H
   MOV    BX,   1
   MOV    DX,   SI
   INT    21H
   POP    DS
End;

Procedure PutImage( x,y : Word; Var Image : TImage );
Var
  xx, yy: Word;
Begin
  With Image do
    For yy:= 0 to SizeY-1 do
      For xx:= 0 to SizeX-1 do
        PutPixel( xx+x, yy+y, Buffer^[SizeX*yy+xx] );
End;

Procedure GotoXY( x,y: Byte ); Assembler;
Asm
   MOV  AH,     2
   MOV  ES,     Seg0040
   MOV  BH,     0
   MOV  DH,     Y
   MOV  DL,     X
   INT  10h
End;

Function WhereX: Byte; Assembler;
Asm
        MOV     AH,     3
        MOV     ES,     Seg0040
        XOR     BH,     BH
        INT     10H
        MOV     AL,     DL
End;

Function WhereY: Byte; Assembler;
Asm
        MOV     AH,     3
        MOV     ES,     Seg0040
        XOR     BH,     BH
        INT     10H
        MOV     AL,     DH
End;

Procedure SetMode( n: Byte ); InLine($58/$CD/$10);
Function ReadKey: Char; InLine($B8/$00/$00/$CD/$16);

Var
  Screen     : TTextScreen absolute $B800:$0000;
  SaveScreen : TTextScreen;
  CursorX    : Byte;
  CursorY    : Byte;
  Black      : TPalette;
  Cel        : TImage;
  CelName    : String;

Begin
  If ParamStr(1) = ''
    Then Begin
           PrintStr(Usage);
           Halt;
         End;

  CelName:= ParamStr( 1 );

  If Not FileExist(CelName) Then
     Begin
       CelName:= CelName+'.CEL';
       If Not FileExist(CelName) Then Begin
         PrintStr('File not found. ('+ParamStr(1)+')'#10#13);
         Halt(1)
       End;
     End;

  Case LoadCel(CelName, Cel) of
   ieFileNotFount:
     Begin
       PrintStr('Error: Could not read file '''+ParamStr(1)+'''.'#10#13);
       Halt(1);
     End;
   iePathNotFound:
     Begin
       PrintStr('Error: Path not fund.'#10#13);
       Halt(1);
     End;
   ieTooManyOpenFiles:
     Begin
       PrintStr('Error: Too many open files.'#10#13);
       Halt(1);
     End;
   ieAccessDenied:
     Begin
       PrintStr('Error: Accsess denied '''+ParamStr(1)+'''.'#10#13);
       Halt(1);
     End;
   ieNoMemory:
     Begin
       PrintStr('Not enough memory to complete operation.'#10#13);
       Halt(1);
     End;
   ieNotACEL:
     Begin
       PrintStr('Error: Not a CEL file: '''+ParamStr(1)+'''.'#10#13);
       Halt(1);
     End;
   ieImageTooBig:
     Begin
       PrintStr('Erro: Not a 320x200x256 CEL '''+ParamStr(1)+'''.'#10#13);
       Halt(1);
     End;
  End;

  SaveScreen := Screen;
  CursorX    := WhereX;
  CursorY    := WhereY;

  SetMode(MCGA);
  SetAllPals(Black);
  PutImage(0,0,Cel);
  SetAllPals(Cel.Palette);
  ReadKey;
  FreeImage(Cel);

  SetMode( Text );
  GotoXY(CursorX, CursorY);
  Screen:= SaveScreen;
End.
