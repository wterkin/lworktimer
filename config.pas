unit config;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Buttons,
  ExtCtrls, StdCtrls, Spin;

type

  { TfmConfig }

  TfmConfig = class(TForm)
    bbtOk: TBitBtn;
    bbtCancel: TBitBtn;
    Label3: TLabel;
    Panel1: TPanel;
    sedMaxWorkTime: TSpinEdit;
    sedMaxWaitTime: TSpinEdit;
    sedMaxPauseTime: TSpinEdit;
    sedMaxNotWorkTime: TSpinEdit;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fmConfig: TfmConfig;

implementation

{$R *.lfm}

end.

