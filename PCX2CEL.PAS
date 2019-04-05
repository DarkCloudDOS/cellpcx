Program CONVERT_PCX_2_CEL;

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

Const
  CELSignature: LongInt = { $0140 9119} $1409119;

Var
  CELName: String;
  PCXName: String;
  Image: TImage;
  F: File;
  Header: array[0..31] of Byte;
Begin
  WriteLn( 'PCX2CEL convertor version 1.0.');
  If ParamCount < 1 Then
    Begin
      WriteLn( 'Usage: PCX2CEL CELNAME[.CEL] PCXNAME[.PCX] ');
      Halt( 1 );
    End;

  PCXName:= ParamStr(1);
  CELName:= ParamStr(2);

  If Not FileExist(PCXName) Then
    Begin
      PCXName:= PCXName+'.PCX';
      If not FileExist(PCXName) Then Begin
        WriteLn( 'File not found :',ParamStr(1),'.' );
        Halt(1);
      End;
    End;

  If CELName<>''
    Then Begin
           If Pos('.', CELName)=0 Then CELName:= CELNAme+'.CEL'
         End
    Else Begin
           CELName:= PCXName;
           While CELName[ Byte(CELName[0]) ]<>'.' do
             Dec( CELName[0] );
           CELName:= CELName + 'CEL';
         End;

  WriteLn( PCXName, ' -> ', CELName );

  Write(#13'Loading PCX. Please wait...' );
  If LoadPCX( PCXName, Image )<>ieOK Then
    Begin
      WriteLn( 'Error loading ', ParamStr(1), '.' );
      Halt(1);
    End;

  WriteLn( #13, 'Loading PCX done. PCX is OK.' );
  WriteLn( 'Writting CEL.' );
  Assign( F, CELName );
  ReWrite( F, 1 );

  FillChar( Header, 32, $FF );
    { Siganture ? }
  Header[$0]:= $19;
  Header[$1]:= $91;
  Header[$2]:= $40;
  Header[$3]:= $01;
    { Image size  }
  Header[$4]:= Lo( Image.SizeY );
  Header[$5]:= Hi( Image.SizeY );
    { More siganture ? }
{  Header[$A]:= $08;
  Header[$D]:= $FA;}


  BlockWrite( F, Header, 32 );
  BlockWrite( F, Image.Palette, SizeOf(Image.Palette) );
  With Image do BlockWrite( F, Buffer^, SizeX*SizeY );

  WriteLn( 'Final size ', FileSize(F), '.' );
  WriteLn;
  Close( F );
End.
