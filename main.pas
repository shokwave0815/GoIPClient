unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Menus, HTTPSend, Synacode, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    Btn_Update: TButton;
    Btn_Close: TButton;
    Edit_PW: TEdit;
    Edit_User: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenIt_Close: TMenuItem;
    MenIt_Time: TMenuItem;
    MenuItem3: TMenuItem;
    MenIt_Autorun: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenIt_Info: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    PopupMenu1: TPopupMenu;
    Timer1: TTimer;
    TrayIcon: TTrayIcon;
    procedure Btn_UpdateClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure IdleTimer1Timer(Sender: TObject);
    procedure MenIt_CloseClick(Sender: TObject);
    procedure MenIt_AutorunClick(Sender: TObject);
    procedure MenIt_InfoClick(Sender: TObject);
    procedure MenIt_TimeClick(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    isStartup: Boolean;
    o_Top: Integer;
    o_Left: Integer;
    myVersion: String;
    ConfDir: String;
    LastUpD: String;
    LastUpT: String;
    UpdTime: Integer;
    procedure LoadConfig();
    procedure SaveConfig();
    function UpdateNow(user, password: String): String;
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

uses time, helper;

//Button: update now
procedure TForm1.Btn_UpdateClick(Sender: TObject);
begin
  Memo1.Clear;
  Memo1.Append('Nachricht vom '+ DateToStr(now) + ' um '+TimeToStr(now));
  Memo1.Append(UpdateNow(Edit_User.text, Edit_PW.Text));
end;

{*******************************************************************************

                                  program end

*******************************************************************************}
procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveConfig;
  CloseAction := caFree;
end;

{*******************************************************************************

                                  program start

*******************************************************************************}
procedure TForm1.FormCreate(Sender: TObject);
begin
  isStartup := True;
  myVersion := 'goIP-Client V1.1';
  Caption := myVersion;
  TRayIcon.Hint := myVersion;

  ConfDir := GetAppConfigDir(false);

  MenIt_Autorun.Checked := isAutorun;
end;

{*******************************************************************************

                                  tray icon stuff

*******************************************************************************}
procedure TForm1.FormShow(Sender: TObject);
begin
  if isStartup then
  begin
    LoadConfig;

    if ParamCount > 0 then
    begin

      if ParamStr(1) = '-min' then
      begin

        Form1.Hide;
      end;
    end;
    isStartup := False;
  end else
  begin
    Form1.showInTaskbar := stAlways;
    TrayIcon.Hide;
  end;

end;

procedure TForm1.TrayIconDblClick(Sender: TObject);
begin
  Form1.WindowState := wsNormal;
  Form1.Show;
end;


procedure TForm1.FormHide(Sender: TObject);
begin
  o_Top := Top;
  o_Left := Left;
  TrayIcon.Show;
  Form1.showInTaskbar := stNever;
end;

procedure TForm1.FormWindowStateChange(Sender: TObject);
begin
  if Windowstate = wsMinimized then
  begin
    o_Top := Top;
    o_Left := Left;
    Form1.Hide;
  end;
end;

{*******************************************************************************

                                  timer

Intervall should be 300000 = 5 min
*******************************************************************************}
procedure TForm1.IdleTimer1Timer(Sender: TObject);
begin
  //only once a day is enough
  //only after "UpdTime" o'clock, most provider disconnect between 0 and 3 o'clock
  if (LastUpD = '') or
     (LastUpT = '') or
     ((LastUpD <> DateToStr(date)) and (getHour >= UpdTime)) or
     ((LastUpD = DateToStr(date)) and (getHour >= UpdTime) and (StrToInt(LastUpT) < UpdTime)) then
  begin
    Memo1.Clear;
    Memo1.Append('Nachricht vom '+ DateToStr(now) + ' um ' + TimeToStr(now));
    Memo1.Append(UpdateNow(Edit_User.text, Edit_PW.Text));
  end;
end;

{*******************************************************************************

                                  Mainmenu

*******************************************************************************}
//close
procedure TForm1.MenIt_CloseClick(Sender: TObject);
begin
  Close;
end;

//autorun
procedure TForm1.MenIt_AutorunClick(Sender: TObject);
begin
  if MenIt_Autorun.Checked then
  begin
    if remAutorun then
    begin
      MessageDlg('Autostart erfolgreich entfernt.', mtInformation, [mbOK], 0);
    end else
    begin
      MessageDlg('Fehler: Autostart konnte nicht entfernt werden!', mtError, [mbOK], 0);
    end;
  end else
  begin
    if instAutorun then
    begin
      MessageDlg('Autostart erfolgreich eingerichtet.', mtInformation, [mbOK], 0);
    end else
    begin
      MessageDlg('Fehler: Autostart konnte nicht eingerichtet werden!', mtError, [mbOK], 0);
    end;
  end;


  MenIt_Autorun.Checked := isAutorun;
end;

//info
procedure TForm1.MenIt_InfoClick(Sender: TObject);
begin
  MessageDlg('Informationen', myVersion + LineEnding+
                             '(c) 2015 by Ingo Steiniger' + LineEnding + LineEnding +
                             'Tool zum aktualisieren der IP-Adresse für den DynDNS-Dienst goIP.de.',
                             mtInformation, [mbOK], 0);
end;

//set time for update
procedure TForm1.MenIt_TimeClick(Sender: TObject);
begin
  Form_Time.SpEdit_Time.Value := UpdTime;
  if Form_Time.ShowModal = mrOK then
  begin
    UpdTime := Form_Time.SpEdit_Time.Value;
    SaveConfig;
  end;
end;

{*******************************************************************************

                          manage configuration

*******************************************************************************}
procedure TForm1.LoadConfig;
var Conf: TINIFile;
begin
  if FileExistsUTF8(ConfDir + 'config.ini') then
  begin
    try
      Conf := TINIFile.Create(ConfDir + 'config.ini');

      //Window
      Top := Conf.ReadInteger('Window', 'Top', 100);
      Left := Conf.ReadInteger('Window', 'Left', 150);
      Height := Conf.ReadInteger('Window', 'Height', 350);
      Width := Conf.ReadInteger('Window', 'Width', 500);

      //User
      Edit_User.Text := Conf.ReadString('Userinfo', 'username', '');
      Edit_PW.Text := decrypt(Conf.ReadString('Userinfo', 'password', ''));

      //Timer
      LastUpD := Conf.ReadString('Timer', 'LastUpdateDate', '');
      LastUpT := Conf.ReadString('Timer', 'LastUpdateTime', '');
      UpdTime := Conf.ReadInteger('Timer', 'UpdTime', 4);
    finally
      FreeAndNil(Conf);

    end;
  end;
end;

procedure TForm1.SaveConfig;
var Conf:TINIFile;
begin
  ForceDirectoriesUTF8(ConfDir);
  try
    Conf := TINIFile.Create(ConfDir + 'config.ini');

    //Window
    Conf.WriteInteger('Window', 'Top', Top);
    Conf.WriteInteger('Window', 'Left', Left);
    Conf.WriteInteger('Window', 'Height', Height);
    Conf.WriteInteger('Window', 'Width', Width);

    //User
    Conf.WriteString('Userinfo', 'username', Edit_User.Text);
    Conf.WriteString('Userinfo', 'password', encrypt(Edit_PW.Text));

    //Timer
    Conf.WriteString('Timer', 'LastUpdateDate', LastUpD);
    Conf.WriteString('Timer', 'LastUpdateTime', LastUpT);
    Conf.WriteInteger('Timer', 'UpdTime', UpdTime);

  finally
    FreeAndNil(Conf);
  end;
end;

{*******************************************************************************

                                  Update IP

Using synapse to send a message to goIP and recieve the answer
*******************************************************************************}
function TForm1.UpdateNow(user, password: String): String;
var URL: string;
    Params: string;
    Response: TMemoryStream;
    sl: TStringList;
    doneOK: Boolean;
begin
  doneOK := False;
  URL := 'http://www.goip.de/setip?';
  Params := 'username=' + EncodeURLElement(UTF8ToSys(user)) + '&' +
            'password=' + EncodeURLElement(UTF8ToSys(password));
  if (user <> '') and (password <> '') then
  begin

    try
      Response := TMemoryStream.Create;

      if HttpPostURL(URL, Params, Response) then
      begin
        Response.Position := 0;

        //response
        sl := TStringLIst.Create;
        sl.LoadFromStream(Response);
        Result := sl.Text;
        doneOK := Pos('erfolgreich', sl.Text) <> 0; //successful?
        FreeAndNil(sl);

      end else
      begin
        Result := 'Fehler: Keine Verbindung zum goIP-Server!' + LineEnding +
                  'Kontrollieren Sie die Internetverbindung.';
      end;

    finally
      FreeAndNil(Response);

      //update time of update if successful
      if doneOK then
      begin
        LastUpD := DateToStr(now);
        LastUpT := IntToStr(GetHour);
        SaveConfig;
      end;
    end;

  end else
    Result := 'Fehler: Kein Benutzername und/oder Passwort eingegeben!';

end;

end.

