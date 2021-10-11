program Pos_Img;

uses
  Forms,
  UMain in 'UMain.pas' {frm_Main};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(Tfrm_Main, frm_Main);
  Application.Run;
end.
