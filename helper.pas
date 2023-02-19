{*******************************************************************************

                            some helper functions

*******************************************************************************}

unit helper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dos, LazUTF8, FileUtil,
  {$ifdef WINDOWS}
  Registry;
  {$endif}
  {$ifdef UNIX}
  IniFiles;
  {$endif}

//Tables for simple crypto voodoo
const RedTable1 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜßabcdefghijklmnopqrstuvwxyzäöü1234567890+#!"§$%&/()=?`*^²³{[]}\~ ,.-<>|;:_@€µ°';
      RedTable2 = '*67~89no;pqär\stuv+#!"wxy:za.bÜ,}cd|öe]f§&/gh>ijk_lmN°O[P QRS()=TUVW-X{YZA€BüC?`DEFµGÄ^HI<J²K$%L@M01³2Ö345ß';

function isWOW64: Boolean;
function getAutorunFile: String;
function getHour: word;
function instAutorun: Boolean;
function remAutorun: Boolean;
function isAutorun: Boolean;
function encrypt(AValue: String): String;
function decrypt(AValue: String): String;

implementation

//get running OS type
//True = 64bit
function isWOW64: Boolean;
begin
  Result := sysutils.GetEnvironmentVariable('ProgramW6432') <> '';
end;

function getAutorunFile: String;
var username: String;
begin
  username := sysutils.GetEnvironmentVariable('USER');
  Result := '/home/'+username+'/.config/autostart/goip.desktop';
end;

//gets current hour
function getHour: word;
var Hour, Min, Sec, HSec: Word;
begin
  Hour := 0;
  Min := 0;
  Sec := 0;
  HSec := 0;

  getTime(Hour, Min, Sec, HSec);

  Result := Hour;
end;

{*******************************************************************************

                                 manage Autostart

*******************************************************************************}
//install autorun
{$ifdef WINDOWS}
function instAutorun: Boolean;
var Reg: TRegistry;
begin
  Result := False;
  if isWOW64 then
    Reg := TRegistry.Create(KEY_READ or KEY_WRITE or $0100)
  else
    Reg := TRegistry.Create;
  try
    //Reg.RootKey:=HKEY_LOCAL_MACHINE;
    Result := Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run\', True);
    Reg.WriteString('goIP-Client', '"' + ParamStr(0) + '"' +' -min');
  finally
    FreeAndNil(Reg);
  end;
end;
{$endif}

{$ifdef UNIX}
function instAutorun: Boolean;
var arINI:TIniFile;
begin
  Result := False;
  try
    arINI := TIniFile.Create(getAutorunFile);
    arINI.WriteString('Desktop Entry', 'Name', 'GoIP-Client');
    arINI.WriteString('Desktop Entry', 'Type', 'Application');
    arINI.WriteString('Desktop Entry', 'Comment', 'Aktualisiert die IP für GoIP.de');
    arINI.WriteString('Desktop Entry', 'Exec', ParamStr(0)+' -min');
    Result := True;
  finally
    FreeAndNil(arINI);
  end;
end;
{$endif}

//remove autorun
{$ifdef WINDOWS}
function remAutorun: Boolean;
var Reg: TRegistry;
begin
  Result := False;
  if isWOW64 then
    Reg := TRegistry.Create(KEY_READ or KEY_WRITE or $0100)
  else
    Reg := TRegistry.Create;
  try
    //Reg.RootKey:=HKEY_LOCAL_MACHINE;
    Result := Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Run\', True);
    Reg.DeleteValue('goIP-Client');
  finally
    FreeAndNil(Reg);
  end;
end;
{$endif}

{$ifdef UNIX}
function remAutorun: Boolean;
begin
  Result := DeleteFileUTF8(getAutorunFile);
end;
{$endif}

//check autorun is installed
{$ifdef WINDOWS}
function isAutorun: Boolean;
var Reg: TRegistry;
begin
  if isWOW64 then
    Reg := TRegistry.Create(KEY_READ or $0100)
  else
    Reg := TRegistry.Create;
  try
    //Reg.RootKey:=HKEY_LOCAL_MACHINE;
    Reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Run\');
    Result := Reg.ValueExists('goIP-Client');
  finally
    FreeAndNil(Reg);
  end;
end;
{$endif}

{$ifdef UNIX}
function isAutorun: Boolean;
begin
  Result := FileExistsUTF8(getAutorunFile);
end;
{$endif}

//encrypt a string
function encrypt(AValue: String): String;
var i, CharPos: Integer;
    CryptChar : String;
begin
  Result := '';
  for i := 1 to UTF8Length(AValue) do
  begin
    CryptChar := UTF8Copy(AValue, i , 1);
    CharPos := UTF8Pos(CryptChar, RedTable1);
    try
      Result := Result + UTF8Copy(RedTable2, CharPos, 1);
    finally
    end;
  end;
end;

//decrypt a string
function decrypt(AValue: String): String;
var i, CharPos: Integer;
    CryptChar : String;
begin
  Result := '';
  for i := 1 to UTF8Length(AValue) do
  begin
    CryptChar := UTF8Copy(AValue, i , 1);
    CharPos := UTF8Pos(CryptChar, RedTable2);
    try
      Result := Result + UTF8Copy(RedTable1, CharPos, 1);
    finally
    end;
  end;
end;

end.

