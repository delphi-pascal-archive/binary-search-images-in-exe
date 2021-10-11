unit UMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, jpeg, ExtCtrls, XPMan;

type
  Tfrm_Main = class(TForm)
    Image1: TImage;
    btn_Go: TButton;
    Image2: TImage;
    Label1: TLabel;
    Label2: TLabel;
    GroupBox1: TGroupBox;
    rb_PosEx: TRadioButton;
    rb_BMHPascalNatifEx: TRadioButton;
    Label3: TLabel;
    Label4: TLabel;
    GroupBox2: TGroupBox;
    rb_Exe: TRadioButton;
    rb_Dfm: TRadioButton;
    btn_Tic: TButton;
    procedure btn_GoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure rb_ExeClick(Sender: TObject);
    procedure btn_TicClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  frm_Main: Tfrm_Main;

implementation

{$R *.dfm}

uses MMSystem, UFunc2Test;
var
  BinToSearch,      // L'image Jpeg à rechercher
  SearchInBin,      // L'exécutable servant à la recherche
  FoundBin: AnsiString; // L'image Jpeg trouvée dans l'exécutable
  PTic, PTac : AnsiString;

procedure StrToImage(aStrImage: AnsiString; aImage: TImage);
// cette fonction ne sert qu'à afficher une image Jpeg contenue dans une string
var MS: TMemoryStream;
    JPG: TJPEGImage;
begin
  if aStrImage = '' then
    Exit;
  MS := TMemoryStream.Create;
  with MS do
  try
    SetSize(Length(astrImage));
    MoveMemory(Memory, PByte(aStrImage), Length(astrImage));
    //WriteBuffer(PAnsiChar(aStrImage)^, Length(astrImage));
    Seek(0, soFromBeginning);
    if (aImage.Picture.Graphic is TJPEGImage) then
      TJPEGImage(aImage.Picture.Graphic).LoadFromStream(MS)
    else
    begin
      JPG := TJPEGImage.Create;
      try
        JPG.LoadFromStream(MS);
        aImage.Picture.Assign(JPG);
      finally
        JPG.Free;
      end;
    end;
  finally
    Free;
  end;
end;


procedure Tfrm_Main.btn_GoClick(Sender: TObject);
var
  Po: Integer;
begin
  //  Recherche d'une Image Jpeg dans un *.exe
  if rb_PosEx.Checked then
    Po := PosEx(BinToSearch, SearchInBin, 1)
  else
  begin
    // Initialisation de la table de sauts
    InitFastSkip(BinToSearch);
    Po := BMHPascalNatifEx(BinToSearch, SearchInBin, 1);   //
  end;
  // l'image a été trouvée
  if  Po > 0 then
  begin
    // Trouvé à :
    Label2.Caption := Format('Image trouvée à l''adresse : %.0n ', [Po/1]);
    // on ajuste la taille pour récupérer les données
    SetLength(FoundBin, Length(BinToSearch));
    // on copie les données trouvées dans une string avec une fonction
    // prévue pour les string
    FoundBin := Copy(SearchInBin, Po, Length(FoundBin));
    btn_Tic.Click;
    // et pour vérifier le bon fonctionnement on l'affiche
    StrToImage(FoundBin, Image2);
    btn_Tic.Click;
  end;
end;

procedure Tfrm_Main.FormCreate(Sender: TObject);
begin
  // Chargement de l'image Jpeg à rechercher
  with TMemoryStream.Create do
  try
    LoadFromFile('regions_france_carte.jpg');
    Seek(0, soFromBeginning);
    SetLength(BinToSearch, Size);
    MoveMemory(PByte(BinToSearch), Memory, Size);
    //ReadBuffer(PAnsiChar(BinToSearch)^, Size);
  finally
    Free;
  end;

  // Chargement d'un fichier exécutable
  rb_ExeClick(nil);

  // Chargement des sons dans une string pour tester
  with TMemoryStream.Create do
  try
    LoadFromFile('tic.wav');
    Seek(0, soFromBeginning);
    SetLength(PTic, Size);
    MoveMemory(PByte(PTic), Memory, Size);
  finally
    Free;
  end;

  with TMemoryStream.Create do
  try
    LoadFromFile('tac.wav');
    Seek(0, soFromBeginning);
    SetLength(PTac, Size);
    MoveMemory(PByte(PTac), Memory, Size);
  finally
    Free;
  end;

end;

procedure Tfrm_Main.rb_ExeClick(Sender: TObject);
const
  FileNameArray: array[Boolean] of string = ('UMain.dfm.dfm', 'Pos_Img.exe');
  FileDisplayNameArray: array[Boolean] of string = ('le Dfm en Version Binaire',
                                                    'un Exécutable');
begin
  with rb_Exe do
  begin
    with TMemoryStream.Create do
    try
      LoadFromFile(FileNameArray[Checked]);
      Seek(0, soFromBeginning);
      SetLength(SearchInBin, Size);
      MoveMemory(PByte(SearchInBin), Memory, Size);
      //ReadBuffer(PAnsiChar(SearchInBin)^, Size);
    finally
      Free;
    end;
    Label1.Caption := Format('Pour une recherche d''image Jpeg de %.0n Octets'+
                      ' dans %s de %.0n Octets', [Length(BinToSearch)/1,
                      FileDisplayNameArray[Checked], Length(SearchInBin)/1]);
  end;
end;

procedure Tfrm_Main.btn_TicClick(Sender: TObject);
begin
  // teste des sons ... toujours en string
  PlaySound(@PTic[1], 0, SND_SYNC Or SND_MEMORY);
  PlaySound(@PTac[1], 0, SND_SYNC Or SND_MEMORY);
end;

end.
