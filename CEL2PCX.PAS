Program CONVERT_CEL_2_PCX;

{$I-,X+,G+,S-}

Uses Images;

Function FileExist( Name: String ): Boolean;
Var
  F: File;
Begin
  Assign( F, Name );
  Reset( F );
  Close( F );
  FileExist:= IOResult=0
End;

Type
  Bytes = Array[0..$FFFF-1] of Byte;
  PCX_Header = Record
    Manufacturer : byte;                {set to 10 = ZSoft .pcx}
    Version      : byte;                {5 means uses palette}
    Encoding     : byte;                {must be 1}
    BitsPerPixel : byte;                {we use 8 bits i.e. a byte}
    Xmin,Ymin    : integer;
    Xmax,Ymax    : integer;
    HDPI         : integer;
    VDPI         : integer;
    ColorMap     : array[0..47] of byte;
    Reserved     : byte;                 { must be 0 }
    NPlanes      : byte;
    BytesPerLine : integer;
    PaletteInfo  : integer;
    HScreenSize  : integer;
    VSrceenSize  : integer;
    Filler       : array[0..53] of byte; { all must be 0}
 End;

Var
  CEL: TImage;
  PCX: File;
  CELName: String[80];
  PCXName: String[80];

  Header: PCX_Header;
  Line, Buf  : array[0..1024] of Byte;
  Count, Data, tmp: Byte;
  y,x  : Word;
Begin
  WriteLn( 'CEL2PCX convertor version 1.0' );
  If ParamCount < 1 Then
    Begin
      WriteLn( 'Usage: CEL2PCX CELNAME[.CEL] {PCXNAME[.PCX]}.');
      Halt;
    End;
  WriteLn;


  CELName:= ParamStr(1);
  PCXName:= ParamStr(2);

  If Not FileExist(CELName) Then
    Begin
      CELName:= CELName+'.CEL';
      If not FileExist(CELName) Then Begin
        WriteLn( 'File not found :',ParamStr(1),'.' );
        Halt(1);
      End;
    End;

  If PCXName<>''
    Then Begin
           If Pos('.', PCXName)=0 Then PCXName:= PCXNAme+'.PCX'
         End
    Else Begin
           PCXName:= CELName;
           While PCXName[ Byte(PCXName[0]) ]<>'.' do
             Dec( PCXName[0] );
           PCXName:= PCXName + 'PCX';
         End;

  If LoadCel( CELName,CEL )<>ieOK Then
    Begin
      WriteLn( 'Error loading ', ParamStr(1), '.' );
      Halt(1);
    End;

  WriteLn( CELName, ' -> ', PCXName );
  Assign( PCX, PCXName );
  ReWrite( PCX, 1 );

  Header.Manufacturer := 10;                {set to 10 = ZSoft .pcx}
  Header.Version      :=  5;                {5 means uses palette}
  Header.Encoding     :=  1;                {must be 1}
  Header.BitsPerPixel :=  8;                {we use 8 bits i.e. a byte}
  Header.xMin         :=  0;
  Header.yMin         :=  0;
  Header.xMax         :=  CEL.SizeX-1;
  Header.yMax         :=  CEL.SizeY-1;
  Header.HDPI         :=  0;
  Header.VDPI         :=  0;
  Header.NPlanes      :=  1;
  Header.BytesPerLine :=  CEL.SizeX;
  Header.PaletteInfo  :=  0;
  Header.HScreenSize  :=  0;
  Header.VSrceenSize  :=  0;
  FillChar( Header.Filler, 54, 0 );         { all must be 0}

  WriteLn( 'Size of PCX: ', CEL.SizeX, 'x', CEL.SizeY );
  WriteLn( 'Writing header ...');
  BlockWrite( PCX, Header, SizeOf(Header) );

  For y:= 0 to CEL.SizeY-1 do
    Begin
      Write( #13'Writing line ', y+1  );
      Move( Bytes(CEL.Buffer^)[y*CEL.SizeX], Line, CEL.SizeX );
      x:= 0;
      Repeat
        Count:= 0;

        Repeat
          Data:= Line[x];
          Inc( Count );
          Inc( x );
        Until (Line[x]<>Data) or (Count = $3F-1 ) or (x = CEL.SizeX);

        If (Count>1)
           Then Begin
                  tmp:= Count or $C0;
                  BlockWrite( PCX, tmp, 1 );
                  BlockWrite( PCX, Data, 1 )
                End
           Else Begin
                  If Data and (not $3F) = (not $3F)
                    Then Begin
                           Count:= $C0 + 1;
                           BlockWrite( PCX, Count, 1 );
                           BlockWrite( PCX, Data , 1 );
                         End
                    Else BlockWrite( PCX, Data, 1 )
                End;
      Until x = CEL.SizeX;
    End;

  WriteLn;
  WriteLn( 'Calibrating palette.' );
  For tmp := 0 to 255 do
    With CEL do Begin
      Palette[tmp].R:= Palette[tmp].R shl 2;
      Palette[tmp].G:= Palette[tmp].G shl 2;
      Palette[tmp].B:= Palette[tmp].B shl 2;
    End;

  WriteLn( 'Writing palette to file.' );
  tmp:= 12;
  BlockWrite( PCX, tmp, 1 ); { 12 means there is a palette }
  BlockWrite( PCX, CEL.Palette, SizeOf(CEL.Palette) );

  WriteLn( 'Final size ', FileSize(PCX) );
  WriteLn;
  Close( PCX );
End.
