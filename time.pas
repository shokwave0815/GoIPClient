unit time;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Spin;

type

  { TForm_Time }

  TForm_Time = class(TForm)
    Btn_save: TButton;
    Btn_Cancel: TButton;
    Label1: TLabel;
    Label2: TLabel;
    SpEdit_Time: TSpinEdit;
    procedure Btn_CancelClick(Sender: TObject);
    procedure Btn_saveClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form_Time: TForm_Time;

implementation

{$R *.lfm}

{ TForm_Time }

procedure TForm_Time.Btn_saveClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TForm_Time.Btn_CancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.

