unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Buttons, windows, message, config,
  tini, tstr;

type

  { TfmMain }

  KeybdLLHookStruct = record

      vkCode      : cardinal;
      scanCode    : cardinal;
      flags       : cardinal;
      time        : cardinal;
      dwExtraInfo : cardinal;
    end;
  MouseLLHookStruct = record

    pt          : TPoint;
    mouseData   : cardinal;
    flags       : cardinal;
    time        : cardinal;
    dwExtraInfo : cardinal;
  end;

  TWorkModes = (wmWork,wmWait,wmPause,wmNotWork,wmNotPause);

  TfmMain = class(TForm)
		Label1: TLabel;
		lbValue: TLabel;
    MainTimer: TTimer;
		pbWorkTime: TProgressBar;
    sbConfig: TSpeedButton;
    sbPause: TSpeedButton;
    sbExit: TSpeedButton;
    tmNotNow: TTimer;
    TrayIcon: TTrayIcon;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
		procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
					{%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    procedure MainTimerTimer(Sender: TObject);
    procedure sbPauseClick(Sender: TObject);
    procedure sbConfigClick(Sender: TObject);
    procedure sbExitClick(Sender: TObject);
    procedure tmNotNowTimer(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
  private
    { private declarations }
    moWorkMode            : TWorkModes;

    //***** Конфигурируемые величины
    mlMaxWorkTime         : Longint;
    mlMaxWaitTime         : LongInt;
    mlMaxPauseTime        : Longint;
    mlMaxNotWorkTime      : Longint;

    //***** Изменяемые величины
    mlCurrentWorkTime     : Longint;
    mlCurrentWaitTime     : Longint;
    mlCurrentPauseTime    : Longint;
    mlCurrentNotWorkTime  : Longint;
    mlCurrentNotPauseTime : Longint;
    mblFormHidden         : Boolean;
    mhActiveWindow        : HWND;
  public

    procedure WMWINDOWPOSCHANGING(var Msg: TWMWINDOWPOSCHANGING); message WM_WINDOWPOSCHANGING;
    function  getMaxPauseTime() : Longint;
    procedure Interrupt(pblForce : Boolean = False);
    procedure Display();
    procedure readConfig();
    procedure saveConfig();
    function  getActiveWindow() : HWND;
  end;


  function LowLevelKeybdHookProc(nCode: LongInt; WPARAM: WPARAM; lParam : LPARAM) : LRESULT; stdcall;
  function LowLevelMouseHookProc(nCode: LongInt; WPARAM: WPARAM; lParam : LPARAM) : LRESULT; stdcall;
  function GetFocusedWindow: HWND;

{define __debug__}

const
      {$ifdef __debug__}
      csTitle              = 'ОТЛАДКА!!!';
      clMaxWorkTime        = 10; // Максимальное время работы до перерыва, сек
      clMaxIdleTime        = 5;  // Время ожидания прекращения работы, сек
      clMaxPauseTime       = 5;  // Время перерыва, сек
      clNotWorkTime        = 5;  // Время бездействия, после которого таймер
                                 // работы выключится
      {$else}
      csTitle              = 'LWorkTimer ver. 2.4';
      clMaxWorkTime        = 1200; // Максимальное время работы до перерыва, сек
      clMaxIdleTime        = 10;   // Время ожидания прекращения работы, сек
      clMaxPauseTime       = 300;  // Время перерыва, сек
      clNotWorkTime        = 10;    // Время бездействия, после которого таймер
                                   // работы выключится
      {$endif}

      clMainTimerInterval  = 1000; // Тики периода
      csIniFileName        = 'lworktimer.ini';

var fmMain : TfmMain;
    MainForm : TfmMain;
    goMouseHook : cardinal;
    goKeyHook : cardinal;


implementation
{$R *.lfm}


{ TfmMain }
procedure TfmMain.FormCreate(Sender: TObject);
const
  wh_keybd_ll = 13;
  wh_mouse_ll = 14;
begin

  inherited;
  MainForm:=fmMain;
  readConfig();

  moWorkMode:=wmWork;

  //***** Счетчики
  mlCurrentWorkTime:=0;
  mlCurrentWaitTime:=0;
  mlCurrentPauseTime:=0;
  mlCurrentNotWorkTime:=0;
  mlCurrentNotPauseTime:=0;

  //***** Таймер
  MainTimer.Interval:=clMainTimerInterval;
  MainTimer.Enabled:=True;

  //***** прогрессбары
  pbWorkTime.Max:=mlMaxWorkTime;

  Display;

  goKeyHook := SetWindowsHookEx(wh_keybd_ll, @LowLevelKeybdHookProc, hInstance, 0);
  goMouseHook := SetWindowsHookEx(wh_mouse_ll, @LowLevelMouseHookProc, hInstance, 0);

  MainForm.Hide;
  TrayIcon.Show;
  TrayIcon.BalloonTimeout:=mlMaxWaitTime;
  mblFormHidden:=True;
  MainForm.Hint := csTitle;
end;


procedure TfmMain.FormDestroy(Sender: TObject);
begin

  UnhookWindowsHookEx(goKeyHook);
  UnhookWindowsHookEx(goMouseHook);
  saveConfig();
  inherited;
end;


procedure TfmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin

  if Key=VK_ESCAPE then
  begin

    Hide();
    TrayIcon.Show;
  end;
  if (Key=VK_Q) and (ssCtrl in SHIFT) then
  begin

    Close;
	end;
end;

procedure TfmMain.FormMouseDown(Sender: TObject; Button: TMouseButton;
			Shift: TShiftState; X, Y: Integer);
const SC_DRAGMOVE : Longint = $F013;
begin

  if Button <> mbRight then
  begin

    ReleaseCapture;
    SendMessage(Handle, WM_SYSCOMMAND, SC_DRAGMOVE, 0);
  end;
end;


procedure TfmMain.MainTimerTimer(Sender: TObject);
begin

  case moWorkMode of
    //** Основной режим, когда человек работает
    wmWork: begin

      //** Если еще рано для паузы..
      if mlCurrentWorkTime<mlMaxWorkTime then
      begin

        //** ждем дальше.
        inc(mlCurrentWorkTime);
      end
      else
      begin

        //** а нет, уже пора. переключаемся в режим ожидания
        moWorkMode:=wmWait;
        TrayIcon.ShowBalloonHint;
      end;

      //** Проверим, не гоняет ли балду товарищ не вовремя?
      if mlCurrentNotWorkTime<=mlMaxNotWorkTime then
      begin

        inc(mlCurrentNotWorkTime);
      end
      else
      begin

        moWorkMode:=wmNotWork;
        mlCurrentNotWorkTime:=0;
      end;
      Display();
    end;

    //** Режим ожидания паузы в работе для организации паузы
    wmWait: begin

      //** Ждем, пока будет достигнута пауза в работе длиной mlMaxWaitTime
      if mlCurrentWaitTime<mlMaxWaitTime then
      begin

        inc(mlCurrentWaitTime);
      end
      else
      begin

        //** Переключаемся в режим паузы
        moWorkMode:=wmPause;
        mlCurrentWaitTime:=0;
        if fmMessage<>nil then
        begin

          mhActiveWindow := GetFocusedWindow();
          fmMessage.bbtInterrupt.Enabled:=False;
          tmNotNow.Enabled:=True;
          fmMessage.Show;
        end;
      end;
      Display();
    end;

    //** Режим паузы
    wmPause: begin

      if mlCurrentPauseTime<mlMaxPauseTime then
      begin

        inc(mlCurrentPauseTime);
      end else
      begin

        if fmMessage<>nil then
        begin

          fmMessage.Close;
        end;
        moWorkMode:=wmWork;
        mlCurrentPauseTime:=0;
        mlCurrentWorkTime:=0;
      end;
      Display();
    end;

    //** Режим, когда человек может работать, но не работает!
    wmNotWork: begin

      if mlCurrentWorkTime>0 then
      begin

        dec(mlCurrentWorkTime);
      end;
      Display();
    end;

    //** Режим, когда человек должен отдыхать, но не отдыхает!
    wmNotPause: begin

      Display();
    end;
  end;
end;


procedure TfmMain.readConfig();
var loIniMgr      : TEasyIniManager;
begin

  loIniMgr := TEasyIniManager.Create();
  loIniMgr.read('main', 'count', 0);
  mlMaxWorkTime:=loIniMgr.read('main', 'maxworktime', clMaxWorkTime);
  mlMaxWaitTime:=loIniMgr.read('main', 'maxidletime', clMaxIdleTime);
  mlMaxPauseTime:=loIniMgr.read('main', 'maxpausetime', clMaxPauseTime);
  mlMaxNotWorkTime:=loIniMgr.read('main', 'maxnotworktime', clNotWorkTime);
  loIniMgr.read(fmMain);
  FreeAndNil(loIniMgr);
end;


procedure TfmMain.saveConfig();
var loIniMgr      : TEasyIniManager;
begin

  loIniMgr := TEasyIniManager.Create();
  loIniMgr.write('main','maxworktime',mlMaxWorkTime);
  loIniMgr.write('main','maxidletime',mlMaxWaitTime);
  loIniMgr.write('main','maxpausetime',mlMaxPauseTime);
  loIniMgr.write('main','maxnotworktime',mlMaxNotWorkTime);
  loIniMgr.write(fmMain);
  FreeAndNil(loIniMgr);
end;


function TfmMain.getActiveWindow : HWND;
begin

  Result := mhActiveWindow;
end;


procedure TfmMain.sbPauseClick(Sender: TObject);
begin

  mlCurrentWorkTime:=mlMaxWorkTime-2;
end;


procedure TfmMain.sbConfigClick(Sender: TObject);
begin

  MainTimer.Enabled:=False;
  fmConfig.sedMaxWorkTime.Value:=mlMaxWorkTime div 60;
  fmConfig.sedMaxWaitTime.Value:=mlMaxWaitTime;
  fmConfig.sedMaxPauseTime.Value:=mlMaxPauseTime div 60;
  fmConfig.sedMaxNotWorkTime.Value:=mlMaxNotWorkTime;
  if fmConfig.ShowModal=mrOK then
  begin

    mlMaxWorkTime:=fmConfig.sedMaxWorkTime.Value*60;
    mlMaxWaitTime:=fmConfig.sedMaxWaitTime.Value;
    mlMaxPauseTime:=fmConfig.sedMaxPauseTime.Value*60;
    mlMaxNotWorkTime:=fmConfig.sedMaxNotWorkTime.Value;
  end;
  MainTimer.Enabled:=True;
end;


procedure TfmMain.sbExitClick(Sender: TObject);
begin

  Close;
end;


procedure TfmMain.tmNotNowTimer(Sender: TObject);
begin

  fmMessage.bbtInterrupt.Enabled:=True;
  tmNotNow.Enabled:=False;
end;


procedure TfmMain.TrayIconDblClick(Sender: TObject);
begin

  if mblFormHidden then
  begin

    MainForm.Show;
    mblFormHidden:=False;
  end
  else
  begin

    MainForm.Hide;
    mblFormHidden:=True;
  end;
end;

procedure TfmMain.WMWINDOWPOSCHANGING(var Msg: TWMWINDOWPOSCHANGING);
var WorkArea: TRect;
    StickAt : Word;
begin

  StickAt := 6;
  SystemParametersInfo(SPI_GETWORKAREA, 0, @WorkArea, 0);
  with WorkArea, Msg.WindowPos^ do
  begin

    // Сдвигаем границы для сравнения с левой и верхней сторонами
	  Right:=Right-cx;
	  Bottom:=Bottom-cy;
	  if abs(Left - x) <= StickAt then
    begin

	    x := Left;
		end;
		if abs(Right - x) <= StickAt then
    begin

	    x := Right;
		end;
		if abs(Top - y) <= StickAt then
    begin

	    y := Top;
		end;
		if abs(Bottom - y) <= StickAt then
    begin

	    y := Bottom;
		end;
	end;
  inherited;
end;


function TfmMain.getMaxPauseTime(): Longint;
begin

  Result:=mlMaxPauseTime;
end;


procedure TfmMain.Interrupt(pblForce : Boolean = False);
begin

  case moWorkMode of
    wmWork:    mlCurrentNotWorkTime:=0;
    wmWait:    mlCurrentWaitTime:=0;
    wmPause:   if pblForce then begin

      mlCurrentPauseTime:=mlMaxPauseTime;
    end;
    wmNotWork: moWorkMode:=wmWork;
  end;
end;


procedure TfmMain.Display();
begin

  pbWorkTime.Position:=mlCurrentWorkTime+1;
  lbValue.Caption:=
    alignRight(IntToStr((mlMaxWorkTime-mlCurrentWorkTime) div 60),2,'0')+':'+
    alignRight(IntToStr((mlMaxWorkTime-mlCurrentWorkTime) mod 60),2,'0');
  if fmMessage<>Nil then
  begin

    fmMessage.pbPauseTime.Position:=mlCurrentPauseTime;
	end;
end;


function LowLevelKeybdHookProc(nCode: LongInt; WPARAM: WPARAM; lParam : LPARAM) : LRESULT; stdcall;
// possible wParam values: WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP
var
  info : ^KeybdLLHookStruct absolute lParam;
begin
  result := CallNextHookEx(goKeyHook, nCode, wParam, lParam);
  if info<>nil then
  begin

    with info^ do
    begin

      case wParam of
        wm_keydown : begin

          MainForm.Interrupt();
        end;
      end;
		end;
	end;
end;


function LowLevelMouseHookProc(nCode: LongInt; WPARAM: WPARAM; lParam : LPARAM) : LRESULT; stdcall;
var info : ^MouseLLHookStruct absolute lParam;
begin

  result := CallNextHookEx(goMouseHook, nCode, wParam, lParam);
  if info<>nil then
  begin

    with info^ do
    begin
      case wParam of
        wm_lbuttondown ,
        wm_lbuttonup   ,
        wm_mbuttondown ,
        wm_mbuttonup   ,
        wm_rbuttondown ,
        wm_rbuttonup   ,
        wm_mousewheel  : begin

          MainForm.Interrupt();
        end;
      end;
		end;
	end;
end;


function GetFocusedWindow: HWND;
var CurrThID, ThID: DWORD;
begin
  Result := GetForegroundWindow;
  if Result <> 0 then
  begin

    CurrThID := GetCurrentThreadId;
    ThID := GetWindowThreadProcessId(result, // handle to window
                                     nil // process identifier
                                     );
    Result := 0;
    if CurrThID = ThId then
    begin

      Result := GetFocus
    end else
    begin

      if AttachThreadInput(CurrThID, ThID, True) then
      begin

        Result := GetFocus;
        AttachThreadInput(CurrThID, ThID, False);
      end;
    end;
  end;
  (*Можно создать окно со стилями WS_EX_TOPMOST+ WS_EX_NOACTIVATE*)
end;

end.
