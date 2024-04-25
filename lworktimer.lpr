program lworktimer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, config, rest
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmConfig, fmConfig);
  Application.CreateForm(TfmRest, fmRest);
  Application.Run;
end.

