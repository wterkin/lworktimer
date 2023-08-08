unit message;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs,
  Buttons, ComCtrls, LCLIntf, ExtCtrls;

type

  { TfmMessage }

  TfmMessage = class(TForm)
    bbtInterrupt: TBitBtn;
    pbPauseTime: TProgressBar;
		NotifyTimer: TTimer;
    procedure bbtInterruptClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
		procedure FormShow(Sender: TObject);
		procedure NotifyTimerTimer(Sender: TObject);
  private
    { private declarations }
    miStep : Integer;
  public
    { public declarations }
  end;

const caiNotifyProcess : array[1..7] of Integer = (128, 160, 200, 160, 128, 160, 200);


var
  fmMessage: TfmMessage;

implementation

uses main;

{$R *.lfm}

{ TfmMessage }

procedure TfmMessage.FormCreate(Sender: TObject);
begin

  inherited;
  pbPauseTime.max:=MainForm.getMaxPauseTime();
end;

procedure TfmMessage.FormShow(Sender: TObject);
begin

  Self.AlphaBlendValue := 0;
  Self.Width := Screen.Width div 2;
  Self.Left := Screen.Width div 4;
  if MainForm.mblPositionTop then
  begin

    Self.Top := 0;
  end else
  begin

    Self.Top := Screen.WorkAreaHeight - Self.Height;
  end;
  miStep := 1;
  NotifyTimer.Enabled := True;
  SetForegroundWindow(MainForm.getActiveWindow());
end;


procedure TfmMessage.NotifyTimerTimer(Sender: TObject);
begin

  if miStep mod 2 = 0 then
  begin

    Self.AlphaBlendValue := 255;
    NotifyTimer.Enabled :=  miStep < 10;
  end else
  begin

    Self.AlphaBlendValue := 0;
	end;
  inc(miStep);
end;


procedure TfmMessage.bbtInterruptClick(Sender: TObject);
begin

  MainForm.Interrupt(True);
  Close;
end;

end.

