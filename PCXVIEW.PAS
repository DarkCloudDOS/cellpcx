
(* ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»   *)
(* º                                                        ºÛ  *)
(* º     Borland Pascal Programs                            ºÛ  *)
(* º     PCXView Source Demo                                ºÛ  *)
(* º                                                        ºÛ  *)
(* ÇÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¶Û  *)
(* º                                                        ºÛ  *)
(* º     Copyright (C) 1997 Diego Iastrubni                 ºÛ  *)
(* º                                                        ºÛ  *)
(* ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼Û  *)
(*  ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß  *)

Program PCXView;

{$DEFINE USE_SVGA}

{$G+,X+,I-,S-,N+,E+}

Const
  Usage  =
       #10#13 +
       #10#13 + 'PCXView version 1.1 Copyright (C) 1997, Diego.'+
       #10#13 + 'Usage: PCXVIEW filename[.pcx].'+
       #10#13 +
       #10#13 + '  In program: '+
       #10#13 + '    Use arrows to scroll the PCX'+
       #10#13 + '    Press Z to Super-Zoom the PCX, ESC to return.' +
       #10#13 + '    Alt+X to quit the program.'+
       #10#13;

  MaximumMemory = 65528;
{$IFDEF USE_SVGA}
  MaxX = 640;
  MaxY = 400;
  XDiv = 25;
  YDiv = 25;
{$ELSE}
  MaxX = 320;
  MaxY = 200;
  XDiv = 100;
  YDiv = 100;
{$ENDIF}

Type
  Directions = (Up,Down);

  TDrawBuffer = array[0..MaxX-1] of Byte;
  Bytes = array[0..$FFFF-1] of Byte;

  PCX_Header = Record
    Manufacturer : byte;
    Version      : byte;
    Encoding     : byte;
    BitsPerPixel : byte;
    Xmin,Ymin    : integer;
    Xmax,Ymax    : integer;
    HDPI         : integer;
    VDPI         : integer;
    ColorMap     : array[0..47] of byte;
    Reserved     : byte;
    NPlanes      : byte;
    BytesPerLine : integer;
    PaletteInfo  : integer;
    HScreenSize  : integer;
    VSrceenSize  : integer;
    Filler       : array[0..53] of byte;
 End;

  TPaletteEntry = Record R,G,B: Byte End;
  TPalette = array[0..255] of TPaletteEntry;

  TTextScreen = array[0..79,0..24] of Record Char: Char; Color: Byte End;

{ÄÄ Interrupts ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ }
Procedure PUSHF; InLine($9C);

Procedure GetIntVec(IntNo: Byte; var Vector: Pointer); Assembler;
Asm
	MOV	AL,	IntNo
	MOV	AH,	35H
	INT	21H
	MOV	AX,	ES
	LES	DI,	Vector
	CLD
	XCHG	AX,	BX
	STOSW
	XCHG	AX,	BX
	STOSW
End;

Procedure SetIntVec(IntNo: Byte; Vector: Pointer); Assembler;
Asm
	PUSH	DS
	LDS	DX,	Vector
	MOV	AL,	IntNo
	MOV	AH,	25H
	INT	21H
	POP	DS
End;

  (* Keyboard *)
Const
  kbEsc       = $011B;  kbAltSpace  = $0200;  kbCtrlIns   = $0400;
  kbShiftIns  = $0500;  kbCtrlDel   = $0600;  kbShiftDel  = $0700;
  kbBack      = $0E08;  kbCtrlBack  = $0E7F;  kbShiftTab  = $0F00;
  kbTab       = $0F09;  kbAltQ      = $1000;  kbAltW      = $1100;
  kbAltE      = $1200;  kbAltR      = $1300;  kbAltT      = $1400;
  kbAltY      = $1500;  kbAltU      = $1600;  kbAltI      = $1700;
  kbAltO      = $1800;  kbAltP      = $1900;  kbCtrlEnter = $1C0A;
  kbEnter     = $1C0D;  kbAltA      = $1E00;  kbAltS      = $1F00;
  kbAltD      = $2000;  kbAltF      = $2100;  kbAltG      = $2200;
  kbAltH      = $2300;  kbAltJ      = $2400;  kbAltK      = $2500;
  kbAltL      = $2600;  kbAltZ      = $2C00;  kbAltX      = $2D00;
  kbAltC      = $2E00;  kbAltV      = $2F00;  kbAltB      = $3000;
  kbAltN      = $3100;  kbAltM      = $3200;  kbF1        = $3B00;
  kbF2        = $3C00;  kbF3        = $3D00;  kbF4        = $3E00;
  kbF5        = $3F00;  kbF6        = $4000;  kbF7        = $4100;
  kbF8        = $4200;  kbF9        = $4300;  kbF10       = $4400;
  kbHome      = $4700;  kbUp        = $4800;  kbPgUp      = $4900;
  kbGrayMinus = $4A2D;  kbLeft      = $4B00;  kbRight     = $4D00;
  kbGrayPlus  = $4E2B;  kbEnd       = $4F00;  kbDown      = $5000;
  kbPgDn      = $5100;  kbIns       = $5200;  kbDel       = $5300;
  kbShiftF1   = $5400;  kbShiftF2   = $5500;  kbShiftF3   = $5600;
  kbShiftF4   = $5700;  kbShiftF5   = $5800;  kbShiftF6   = $5900;
  kbShiftF7   = $5A00;  kbShiftF8   = $5B00;  kbShiftF9   = $5C00;
  kbShiftF10  = $5D00;  kbCtrlF1    = $5E00;  kbCtrlF2    = $5F00;
  kbCtrlF3    = $6000;  kbCtrlF4    = $6100;  kbCtrlF5    = $6200;
  kbCtrlF6    = $6300;  kbCtrlF7    = $6400;  kbCtrlF8    = $6500;
  kbCtrlF9    = $6600;  kbCtrlF10   = $6700;  kbAltF1     = $6800;
  kbAltF2     = $6900;  kbAltF3     = $6A00;  kbAltF4     = $6B00;
  kbAltF5     = $6C00;  kbAltF6     = $6D00;  kbAltF7     = $6E00;
  kbAltF8     = $6F00;  kbAltF9     = $7000;  kbAltF10    = $7100;
  kbCtrlPrtSc = $7200;  kbCtrlLeft  = $7300;  kbCtrlRight = $7400;
  kbCtrlEnd   = $7500;  kbCtrlPgDn  = $7600;  kbCtrlHome  = $7700;
  kbAlt1      = $7800;  kbAlt2      = $7900;  kbAlt3      = $7A00;
  kbAlt4      = $7B00;  kbAlt5      = $7C00;  kbAlt6      = $7D00;
  kbAlt7      = $7E00;  kbAlt8      = $7F00;  kbAlt9      = $8000;
  kbAlt0      = $8100;  kbAltMinus  = $8200;  kbAltEqual  = $8300;
  kbCtrlPgUp  = $8400;  kbAltBack   = $0800;  kbSpace     = $3920;

  kbJustAlt   = $0038;
  kbNoKey     = $0000;

Var
  Key: array [0..$80-1] of Boolean;
  OldInt09: Pointer;

Function ReadKey: Word; Assembler;
Asm
	XOR	AX,	AX
	MOV	ES,	SEG0040
	MOV	BL,	ES:[1AH]
	MOV	BH,	ES:[1CH]
	CMP	BL,	BH
	JE	@NO_KEY
	XOR	AX,	AX
	INT     16H
@NO_KEY:
End;

Procedure ClearBuffer; Assembler;
Asm
	MOV	ES, 	Seg0040
	MOV	AL,	ES:[1CH]
	MOV	ES:[1AH],AL
End;

Procedure NewInt09; Interrupt;
Type
  Call = Procedure;
Begin
  MemW[Seg0040:$17]:= 0;
  PUSHF;
  Call(OldInt09);
  Key[Port[$60] mod $80]:= Port[$60]<$80;
  ClearBuffer;
End;


Procedure InitKeys;
Begin
  FillChar( Key, SizeOf(Key), 0 );
  GetIntVec( 09, OldInt09 );
  SetIntVec( 09, @NewInt09 );
End;

Procedure DoneKeys;
Begin
  SetIntVec( 09, OldInt09 );
End;

  (* Graphics *)
Var
  SaveScreen: TTextScreen;
  CursorX   : Byte;
  CursorY   : Byte;

Procedure SetText; InLine( $B8/$03/$00/$CD/$10);

Procedure GotoXY( x,y: Byte ); Assembler;
Asm
	MOV	AH,     2
	MOV	ES,     Seg0040
	MOV	BH,     0
	MOV	DH,     Y
	MOV	DL,     X
	INT	10h
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

Procedure SaveText;
Begin
  CursorX:= WhereX;
  CursorY:= WhereY;
  SaveScreen:= TTextScreen(Ptr(SegB800,0)^);
End;

Procedure RestoreText;
Begin
  GotoXY( CursorX, CursorY );
  TTextScreen(Ptr(SegB800,0)^):= SaveScreen;
End;

Procedure WaitRetrace; assembler;
asm
	MOV	DX,	3DAh
@L1:	IN	AL,	DX
	TEST	AL,	08h
	JNZ	@L1
@L2:	IN	AL,	DX
	TEST	AL,	08h
	JZ	@L2
end;

{$IFDEF USE_SVGA}
Procedure SetSVGA; ASSEMBLER;
Asm
{Ask VESA 640x400x256 NON-Chained mode}
	MOV     AX,     4F02H
	MOV     BX,     0100H
	INT     10H
{Turn screen off}
	MOV     DX,     03C4h
	MOV     AL,     1
	OUT     DX,     AL
	INC     DX
	IN      AL,     DX
	OR      AL,     020h
	OUT     DX,     AL
{Chain-4}
	MOV     DX,     03C4H
	MOV     AX,     0604H
	OUT     DX,     AX
{Word mode}
	MOV     DX,     03D4H
	MOV     AX,     0E317H
	OUT     DX,     AX
{DWord mode}
	MOV     DX,     03D4H
	MOV     AX,     0014H
	OUT     DX,     AX
{Select all planes and clear video}
	MOV     DX,     03C4H
	MOV     AX,     0F02H
	OUT     DX,     AX
	MOV     ES,     SegA000
	XOR     DI,     DI
	XOR     AX,     AX
	MOV     CX,     0FFFFH/2
	REP     STOSW
{Wait for vertical retrace}
	MOV     DX,     3DAH
@L1:    IN      AL,     DX
	TEST    AL,     08h
	JNZ     @L1
{Turn screen on}
	MOV     DX,     03C4H
	MOV     AL,     1
	OUT     DX,     AL
	INC     DX
	IN      AL,     DX
	AND     AL,     0DFH
	OUT     DX,     AL
End;

Procedure Draw_Line( y: Word; Var B: TDrawBuffer ); Assembler;
Var
  DDI: Word;
Asm
	PUSH	DS
	MOV	DI,	y
	MOV	DX,	DI
	SHL	DI,	7
	SHL	DX,	5
	ADD	DI,	DX
	MOV	ES,	SEGA000
	MOV	DDI,	DI		{ES:DI = Screen}
	LDS	SI,	B		{DS:SI = buffer}

	MOV	BX,	0
@LOOP_X:
	MOV	CX,	BX
	AND	CX,	3
	MOV	AX,	0102H
	SHL	AH,	CL
	MOV	DX,	03C4H
	OUT	DX,	AX

	MOV	DI,	DDI
	MOV	DX,	BX
	SHR	DX,	2
	ADD	DI,	DX

	MOV	AL,	DS:[SI]
	MOV	ES:[DI],AL
	INC	SI
	INC	BX
	CMP	BX, 	MAxX
	JNE	@LOOP_X
	POP	DS
End;

Procedure PutPixel( x, y: Integer; Color: Byte; Where: Word ); Assembler;
Asm
	MOV  BX,     X
	MOV  CX,     BX
	AND  CL,     3
	MOV  AX,     0102H
	SHL  AH,     CL
	MOV  DX,     03C4h
	OUT  DX,     AX

	MOV  DI,     Y
	MOV  AX,     DI
	SHL  DI,     7
	SHL  AX,     5
	ADD  DI,     AX
	MOV  AX,     BX
	SHR  AX,     2
	ADD  DI,     AX
	MOV  AL,     Color
	MOV  ES,     SegA000
	MOV  ES:[DI],AL
End;
{$ELSE}

Procedure SetMCGA; InLine( $B8/$13/$00/$CD/$10 );
Procedure PutPixel( x,y: Word; Color: Byte; Where: Word);
InLine( $8B/$DD/$8B/$EC/$8B/$7E/$04/$C1/$E7/$06/$67/$8D/$3C/$BF/
	$8E/$46/$00/$8A/$46/$02/$03/$7E/$06/$26/$88/$05/$8B/$EB/
	$83/$C4/$08 );

Procedure Draw_Line( y: Word; Var B: TDrawBuffer ); Assembler;
Asm
	PUSH 	DS
	MOV	DI,	Y
	MOV	DX,	DI
	SHL	DI,	8
	SHL	DX,	6
	ADD	DI,	DX
	MOV	ES,	SEGA000
	LDS	SI,	B

	MOV	CX,	MaxX
	REP	MOVSB
	POP	DS
End;

{$ENDIF}

Const
  Size = 80;

Procedure Set_C4; Assembler;
Asm
	MOV	AX,	13H
	INT	10H

	MOV 	DX, 	03C4h
	MOV 	AX, 	0604h
	OUT 	DX, 	AX	 {PORTW[$3C4]:= $0604}
	MOV 	AX, 	0100h
	OUT 	DX, 	AX       {PORTW[$3C4]:= $0100}
	MOV 	DX, 	03C2h
	MOV 	AL, 	0E3h
	OUT 	DX, 	AL       {PORT[$3C2]:= $E3}
	MOV 	DX, 	03C4h
	MOV 	AX, 	0300h
	OUT 	DX, 	AX       {PORTW[$3C4]:= $0300}
	MOV 	DX, 	03D4h
	MOV 	AL, 	$11
	OUT 	DX, 	AL       {PORT[$3D4]:= $11}
	INC 	DX
	IN  	AL,	DX
	AND	AL,	$7F
	OUT	DX, 	AL       {PORT[$3D5]:= PORT[$3D4] AND $7F}
	DEC	DX
	CLD
	MOV	AX, 	0D06h
	OUT	DX, 	AX       {PORTW[$3D4]:= $0D06}
	MOV	AX, 	3E07h
	OUT	DX, 	AX       {PORTW[$3D4]:= $3E07}
	MOV	AX, 	4109h
	OUT	DX, 	AX       {PORTW[$3D4]:= $4109}
	MOV	AX, 	0EA10h
	OUT	DX, 	AX       {PORTW[$3D4]:= $EA10}
	MOV	AX, 	0AC11h
	OUT	DX, 	AX       {PORTW[$3D4]:= $AC11}
	MOV	AX, 	0DF12h
	OUT	DX, 	AX	 {PORTW[$3D4]:= $DF12}
	MOV	AX, 	0014h
	OUT	DX, 	AX	 {PORTW[$3D4]:= $0014}
	MOV	AX, 	0E715h
	OUT	DX, 	AX	 {PORTW[$3D4]:= $E715}
	MOV	AX, 	0616h
	OUT	DX, 	AX	 {PORTW[$3D4]:= $0616}
	MOV	AX,	0E317h
	OUT	DX,	AX	 {PORTW[$3D4]:= $E317}

	MOV	DX,	03D4H
	MOV	AL,	13H
	OUT	DX,	AL
	INC	DX
	MOV	AL,	SIZE
	OUT	DX,	AL

	MOV	DX,	03C4H
	MOV	AX,	0F02H
	OUT	DX,	AX

	MOV	CX,	0FFFFH
	MOV	ES,	SEGA000
	XOR	DI,	DI
	XOR	AX,	AX
	REP	STOSW

@L1:    IN      AL,     DX
	TEST    AL,     08h
	JNZ     @L1

	MOV     DX,     03C4H
	MOV     AL,     1
	OUT     DX,     AL
	INC     DX
	IN      AL,     DX
	AND     AL,     0DFH
	OUT     DX,     AL
End;

Procedure PutPixel_C4(X, Y : Integer; Color: Byte); Assembler;
Asm
	MOV	SI,	x
	MOV	CX,     SI
	AND	CX,     3
	MOV	AX,     0100H
	SHL	AX,     CL
	ADD	AL,     2
	MOV	DX,     03C4H
	OUT	DX,     AX

	MOV	DI,     y
	MOV	AX,     DI
	SHL	DI,     7
	SHL	AX,     5
	ADD	DI,     AX
	MOV	AX,	SI
	SHR	AX,     2
	ADD	DI,     AX
	MOV	AL,     Color
	MOV	ES,     SegA000
	MOV	ES:[DI],AL
End;

Procedure MoveScr_C4(X,Y : Integer); Assembler;
Asm
	MOV	DX,	03DAH
@L1:	IN	AL,	DX
	TEST	AL,	08H
	JNZ	@L1
@L2:	IN	AL,	DX
	TEST	AL,	08H
	JZ	@L2

{2*Size*Y+x}
	MOV	AX,	Size
	MUL	Y
	SHL	AX,	2
	ADD	AX,	x
	MOV	DI,	AX


	MOV	DX,	03D4H
	MOV	AL,	0CH
	OUT	DX,	AL
	MOV	AX,	DI
	AND	AX,	0FF00H
	MOV	AL,	AH
	INC	DX
	OUT	DX,	AL
	DEC	DX
	MOV	AL,	0DH
	OUT	DX,	AL
	MOV	AX,	DI
	AND	AX,	00FFH
	INC	DX
	OUT	DX,	AL
End;

Procedure SetPalette( Var Palette: TPalette ); Assembler;
Asm
	PUSH	DS
	LDS	SI,	Palette
	MOV	DX,	03C8h
	MOV	AL,	0
	OUT	DX,	AL
	INC	DX
	MOV	CX,	768
	REP	OUTSB
	POP	DS
End;

Procedure GetPalette( Var Palette: TPalette ); Assembler;
Asm
	MOV	AL,	0FFH
	MOV	DX,	0C6H
	OUT	DX,	AL
	MOV	DX,	03C7H
	MOV	AL,	0
	OUT	DX,	AL
	MOV	DX,	03C9H

	LES	DI,	Palette
	MOV	CX,	768
@@:	IN	AL,	DX
	MOV	[ES:DI],AL
	INC	DI
	LOOP	@@
End;

Procedure FillPalette( Var Palette: TPalette; R,G,B: Byte ); Assembler;
Asm
	LES	DI,	Palette

	MOV	CX,	256
@LOOP:	MOV	AL,	R
	STOSB
	MOV	AL,	G
	STOSB
	MOV	AL,	B
	STOSB
	LOOP	@LOOP
End;

Procedure Fade( Var Pal: TPalette );
Var
  CP      : TPalette;
  i, Color: Byte;
Begin
  GetPalette(Cp);

  For i:=1 to 63 Do
    Begin
      For Color:= 0 to 255 Do
	Begin
	  If CP[Color].R > Pal[Color].R Then Dec(CP[Color].R ) Else
	  If CP[Color].R < Pal[Color].R Then Inc(CP[Color].R );

	  If CP[Color].G > Pal[Color].G Then Dec(CP[Color].G ) Else
	  If CP[Color].G < Pal[Color].G Then Inc(CP[Color].G );

	  If CP[Color].B > Pal[Color].B Then Dec(CP[Color].B ) Else
	  If CP[Color].B < Pal[Color].B Then Inc(CP[Color].B );
	End;
      WaitRetrace;
      SetPalette( CP );
    End;
End;

 (* Files *)
Var
  PCX    : File;
  Buffer : Pointer;
  Index  : Word;
  BufSize: Word;

Function FileExist( Name: String ): Boolean;
Var
  F: File;
Begin
  Assign( F, Name );
  Reset( F );
  Close( F );
  FileExist:= IOResult=0;
End;

Procedure OpenFile( Name: String );
Begin
  Assign( PCX, Name );
  Reset( PCX, 1 );
End;

Procedure OpenCache;
Begin
  If MaxAvail> MaximumMemory
    Then BufSize:= MaximumMemory
    Else BufSize:= MaxAvail;

  GetMem( Buffer, BufSize );
  Index:= BufSize;       { Next time you read a byte it will load from
			   the file and not from the memory              }
End;

{ Using this procedure for reading a byte from the file is faster,
  because it reads from the memory cache (the pointer called Buffer)
  instead of the disk, wich is slow.	                                 }
Function GetByte: Byte;
Var
  Data: Byte;
Begin
  If Buffer <> nil
    Then Begin
	   If Index = BufSize Then
	     Begin
	       BlockRead( PCX, Buffer^, BufSize );
	       Index:= 0;
	     End;
	   GetByte:= Bytes(Buffer^)[Index];
	   Inc( Index );
	 End
    Else Begin
	   BlockRead( PCX, Data, 1 );
	   GetByte:= Data;
	 End
End;

Procedure CloseFile;
Begin
  If Buffer<>nil Then
    Begin
      FreeMem( Buffer, BufSize );
      Index  := 0;
      BufSize:= 0;
    End;

  Close( PCX );
End;

  (* Main graphic output *)
Var
  Header         : PCX_Header;
  Image          : array[0..1280] of ^Bytes;
  Palette        : TPalette;
  BlackPal	 : TPalette;
  SizeX, SizeY   : Word;
  StartX, StartY : Word;
  UsesPalette    : Boolean;
  B              : TDrawBuffer;
  Dir		 : Directions;

Procedure ShowFrom( NewX, NewY: Word; DirectionDraw: Directions; AlwaysDraw: Boolean );
Var
  sx, sy,
   x, y,
  xx, yy: Word;
Begin
  If (NewX>SizeX) or (NewY>SizeY) or
     ((NewX = StartX) and (NewY = StartY) and not AlwaysDraw) Then Exit;

  If SizeX<=MaxX Then NewX:= 0;
  If SizeY<=MaxY Then NewY:= 0;

  If (SizeX>MaxX) or (SizeY>MaxY)
    Then Begin
	   If NewX+SizeX>=MaxX
	     Then Begin
		    If NewX+MaxX>=SizeX Then NewX:= SizeX-MaxX;
		    sx:= MaxX;
		    x := 0
		  End
	     Else Begin
		    NewX:= 0;
		    sx:= SizeX;
		    x:= (MaxX-SizeX) div 2;
		  End;

	   If NewY+SizeY>=MaxY
	     Then Begin
		    If NewY+MaxY>=SizeY Then NewY:= SizeY-MaxY;
		    sy:= MaxY;
		    y := 0
		  End
	     Else Begin
		    NewY:= 0;
		    sy:= SizeY;
		    y:= (MaxY-SizeY) div 2;
		  End;

	    If (StartX<>NewX) or (StartY<>NewY) or AlwaysDraw Then
{	      For yy:= 0 to sy-1 do
		For xx:= 0 to sx-1 do
		  PutPixel( xx+x, yy+y, Image[yy+NewY]^[xx+NewX], SegA000 );}
	      If DirectionDraw = Up
		Then For yy:= sy-1 DownTo 0 do
		       Begin
			 Move( Image[yy+NewY]^[NewX], B, sx );
			 Draw_Line( yy+y, b );
			 ClearBuffer;
		       End
		Else For yy:= 0 to sy-1 do
		       Begin
			 Move( Image[yy+NewY]^[NewX], B, sx );
			 Draw_Line( yy+y, b );
			 ClearBuffer;
		     End;

	    StartX:= NewX;
	    StartY:= NewY;
	  End
    Else If AlwaysDraw Then
	   Begin
	     StartX:= (MaxX-SizeX) div 2;
	     StartY:= (MaxY-SizeY) div 2;

{	     For yy:= 0 to SizeY-1 do
	       For xx:= 0 to SizeX-1 do
		 PutPixel( xx+StartX, yy+StartY, Image[yy]^[xx], SegA000 )}
	     For yy:= 0 to SizeY-1 do
	       Begin
		 FillChar( b, SizeOf(B), 0 );
		 Move( Image[yy]^, B[StartX], SizeX );
		 Draw_Line( yy+StartY, B );
	       End;
	   End
End;

Procedure DoZoom;
Var
  DivFaqtor : Single;
  DivX, DivY: Single; {Other type of real}
  ScanCode  : Word;
  Abort     : Boolean;
  x, y      : Integer;
Begin
  Set_C4;
  If UsesPalette Then SetPalette( BlackPal );

  Abort:= False;
  DivX:= SizeX/640;
  DivY:= SizeY/400;

  If DivX<DivY
    Then DivFaqtor:= DivX
    Else DivFaqtor:= DivY;

  For y:= 0 to 400-1 do
    Begin
      For x:= 0 to 640-1 do
	If ReadKey = kbEsc
	  Then Begin Abort:= True; Break End
	  Else PutPixel_C4( x, y, Image[Round(y*DivY) mod SizeY]^
				       [Round(x*DivX) mod SizeX] );
      If Abort Then Break;
    End;

  If Not Abort then
    Begin
      InitKeys;
      x:= 0;
      y:= 0;

      If UsesPalette Then Fade( Palette );
      Repeat
	If Key[Hi(kbLeft)]  Then Dec(x);
	If Key[Hi(kbRight)] Then Inc(x);
	If Key[Hi(kbUp)]    Then Dec(y);
	If Key[Hi(kbDown)]  Then Inc(y);
	If Key[Hi(kbPgUp)]  Then Begin Inc(x); Dec(y); End;
	If Key[Hi(kbPgDn)]  Then Begin Inc(x); Inc(y); End;
	If Key[Hi(kbHome)]  Then Begin Dec(x); Dec(y); End;
	If Key[Hi(kbEnd)]   Then Begin Dec(x); Inc(y); End;

	If Key[kbJustAlt] and Key[Hi(kbAltX)] Then
	   Begin
	     DoneKeys;
	     ClearBuffer;
	     For y:= 0 to SizeY-1 do
	       FreeMem( Image[y], SizeX );
	     CloseFile;
	     WaitRetrace;
	     SetText;
	     RestoreText;
	     Halt;
	   End;

	If x<0        Then x:= 0;
	If x>={640-320}80 Then x:= {640-320-1}80;
	If y<0        Then y:= 0;
	If y>={400-240} 85 Then y:= {400-240-1}85;

	MoveScr_C4( x, y );
      Until Key[Hi(kbEsc)] or Key[Hi(kbAltZ)];
      Fade( BlackPal );
    End;

  WaitRetrace;
  DoneKeys;

{$IFDEF USE_SVGA}
  SetSVGA;
{$ELSE}
  SetMCGA;
{$ENDIF}

  If UsesPalette Then SetPalette( BlackPal );
  ShowFrom( 0, 0, Dir, True );
  If UsesPalette Then SetPalette( Palette );
End;

Var
  PCXName      : String;
  TotalBytes   : Word;
  y            : Word;
  IncX, IncY   : Word;
  Count        : Word;
  ScanCode     : Word;
  Data         : Byte;
Begin
  If ParamStr(1) = ''
    Then Begin
	   WriteLn(Usage);
	   Halt;
	 End;

  UsesPalette:= False;
  PCXName:= ParamStr( 1 );

  If Not FileExist(PCXName) Then
     Begin
       PCXName:= PCXName+'.PCX';
       If Not FileExist(PCXName) Then Begin
	 WriteLn('File not found. ('+ParamStr(1)+')'#10#13);
	 Halt(1)
       End;
     End;

  SaveText;

  OpenFile( PCXName );
  BlockRead(PCX , Header, 128 );
  With Header do
    Begin
      TotalBytes:= NPlanes * BytesPerLine;
      SizeX:= XMax - XMin + 1;
      SizeY:= YMax - YMin + 1;
      IncX := SizeX div XDiv;
      IncY := SizeY div YDiv;
    End;

  If MemAvail<LongInt(SizeX)*LongInt(SizeY) {4 extra KB for disk cache (line 298)}
    Then Begin
	   WriteLn('Not enough memory to load the picture.');
	   WriteLn;
	   WriteLn('You need ', LongInt(SizeX)*LongInt(SizeY) div 1024, 'KB of conventional memory');
	   WriteLn('You have ', MemAvail    div 1024, 'KB.' );
	   WriteLn('Free ', (LongInt(SizeX)*LongInt(SizeY) div 1024) - (MemAvail div 1024),
	     'KB and try again.' );
	   Halt(1)
	 End;

  For y:= 0 to SizeY-1 do GetMem( Image[y], SizeX );

  Seek( PCX, FileSize(PCX)-769 );
  BlockRead( PCX, Data, 1 );
  If Data = 12 Then
    Begin
      BlockRead( PCX, Palette, 768 );
      For count:= 0 to 255 do
	Begin
	  Palette[count].R:= Palette[count].R div 4;
	  Palette[count].G:= Palette[count].G div 4;
	  Palette[count].B:= Palette[count].B div 4;
	End;
      UsesPalette:= True;
    End;
  Seek( PCX, 128 );
  FillPalette( BlackPal, Palette[0].R, Palette[0].G, Palette[0].B );

  OpenCache;
{ Decompress file}
  For y:= 0 to SizeY-1 do
    Begin
      ScanCode:= ReadKey;
      If (ScanCode = kbEsc)  or
	 (ScanCode = kbAltX) or
	 (Lo(ScanCode) = Ord(^Q)) Then
	 Begin
	   ClearBuffer;
	   For y:= 0 to SizeY-1 do
	     FreeMem( Image[y], SizeX );
	   CloseFile;
	   RestoreText;
	   WriteLn( 'Aborted by user.' );
	   Halt;
	End;

      If y mod 10=0 Then {write to screen every 10 lines}
	Write( #13'Reading line', y:5, ' of', SizeY:5,
		   ', ',  y/SizeY*100:4:2, ' %' );

      Count:= 0;
      Repeat
	Data:= GetByte;
	If Data and (not $3F) = (not $3F)
	  Then Begin
		 FillChar( Image[y]^[Count], Data and $3F, GetByte );
		 Inc( Count, Data and $3F  );
	       End
	  Else Begin
		 Image[y]^[Count]:= Data;
		 Inc( Count );
	       End;
      Until Count = TotalBytes;
    End;

{$IFDEF USE_SVGA}
  SetSVGA;
{$ELSE}
  SetMCGA;
{$ENDIF}

  If UsesPalette Then SetPalette( BlackPal );
  ShowFrom( 0, 0, Dir, True );
  If UsesPalette Then SetPalette( Palette );

  Repeat
    ScanCode:= ReadKey;
    Case ScanCode of
      kbHome : ShowFrom( 0,           StartY, Dir, False );
      kbEnd  : ShowFrom( SizeX-MaxX,  StartY, Dir, False );
      kbLeft : ShowFrom( StartX-IncX, StartY, Dir, False );
      kbRight: ShowFrom( StartX+IncX, StartY, Dir, False );
      kbUp   : Begin Dir:= Up;   ShowFrom( StartX, StartY-IncY, Dir, False ); End;
      kbDown : Begin Dir:= Down; ShowFrom( StartX, StartY+IncY, Dir, False ); End;
      kbPgDn : Begin Dir:= Up;   ShowFrom( StartX, SizeY-MaxY,  Dir, False ); End;
      kbPgUp : Begin Dir:= Down; ShowFrom( StartX,           0, Dir, False ); End;
    End;

    If (Lo(ScanCode) = Ord('z')) or (Lo(ScanCode) = Ord('Z')) Then
      BEgin DoZoom;
	    scancode:= 0
	    end;
  Until (ScanCode= kbEsc)  or
	(ScanCode= kbAltX) or
	(Lo(ScanCode) = Ord(^Q));

  For y:= 0 to SizeY-1 do FreeMem( Image[y], SizeX );
  CloseFile;
  WaitRetrace;
  SetText;
  RestoreText;
End.
