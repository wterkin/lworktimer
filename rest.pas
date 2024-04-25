unit rest;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TfmRest }

  TfmRest = class(TForm)
    lblMessage: TLabel;
    Timer: TTimer;
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
  private

  public

  end;


var
  fmRest: TfmRest;

implementation

{$R *.lfm}

{ TfmRest }

procedure TfmRest.TimerTimer(Sender: TObject);
var liLeft, liTop : Integer;
    llColor : Longint;
begin

  liLeft := Random(Screen.Width-Self.Width);
  liTop := Random(Screen.Height-Self.Height);
  llColor := Random($FF) * $FF * $FF + Random($FF) * $FF + Random($FF);
  Self.Left := liLeft;
  Self.Top := liTop;
  lblMessage.Font.Color:=llColor;
end;

procedure TfmRest.FormHide(Sender: TObject);
begin

  Timer.Enabled:=False;
end;

procedure TfmRest.FormShow(Sender: TObject);
begin

  Timer.Enabled:=True;
end;

end.

