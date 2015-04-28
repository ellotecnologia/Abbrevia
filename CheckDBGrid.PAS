unit CheckDBGrid;
// v1.1 03.08.2001 M.Peter - mpeter@web.de
//
// create Interbase-Domain with:
// CREATE DOMAIN "BOOLEAN" AS CHAR(1) DEFAULT 'F' CHECK (VALUE IN ('F','T')) NOT NULL;


interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, DB, DBGrids;

type
  TCheckColumn = class(TColumn)
  private
    FCheck: Boolean;
    FValueChecked: String;
    FValueUnChecked: String;
    procedure SetCheck(const Value: boolean);
    procedure SetValueChecked(const Value: string);
    procedure SetValueUnchecked(const Value: string);
  public
    constructor Create(Collection: TCollection); override;
  published
    property Check: Boolean read FCheck write SetCheck default false;
    property ValueChecked: String read FValueChecked write SetValueChecked;
    property ValueUnchecked: String read FValueUnchecked write SetValueUnchecked;
  end;

  TCheckDBGrid = class(TDBGrid)
   private
    Editing :Boolean;
    FAllowAppend: Boolean;
    OriginalOptions: TDBGridOptions;
    function ValueMatch(const ValueList, Value: string): Boolean;
    procedure SaveBoolean;
   protected
    function  CreateColumns: TDBGridColumns; override;
   protected
    procedure CellClick(Column: TColumn); override;
    procedure ColEnter; override;
    procedure ColExit; override;
    procedure DoEnter; override;
    Procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DrawColumnCell(const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState); override;
   published
    property AllowAppend: Boolean read FAllowAppend write FAllowAppend default True;
  end;

procedure Register;

implementation

constructor TCheckColumn.Create(Collection: TCollection);
  begin
    inherited;
    FValueChecked:='T';
    FValueUnchecked:='F';
  end;

procedure TCheckColumn.SetCheck(const Value: boolean);
  begin
    FCheck:=Value;
    Changed(False);
  end;

procedure TCheckColumn.SetValueChecked(const Value: string);
  begin
    FValueChecked:=Value;
    Changed(False);
  end;

procedure TCheckColumn.SetValueUnchecked(const Value: string);
  begin
    FValueUnchecked:=Value;
    Changed(False);
  end;

function TCheckDBGrid.ValueMatch(const ValueList, Value: string): Boolean;
  var Pos: Integer;
  begin
    Result := False;
    Pos := 1;
    while Pos <= Length(ValueList) do
      if AnsiCompareText(ExtractFieldName(ValueList, Pos), Value) = 0 then
      begin
        Result := True;
        Break;
      end;
  end;

function TCheckDBGrid.CreateColumns: TDBGridColumns;
  begin
    Result := TDBGridColumns.Create(Self, TCheckColumn);
  end;

procedure TCheckDBGrid.SaveBoolean;
  var column :TCheckColumn;
      pos    :integer;
  begin
    column:=TCheckColumn(Columns[SelectedIndex]);
    if not column.ReadOnly then begin
      SelectedField.Dataset.Edit;
      if SelectedField.DataType=ftBoolean then
       SelectedField.AsBoolean:=not SelectedField.AsBoolean
      else begin
        pos:=1;
        if ValueMatch(column.ValueChecked, SelectedField.AsString) then
         SelectedField.AsString:=ExtractFieldName(column.ValueUnchecked,pos)
        else
         SelectedField.AsString:=ExtractFieldName(column.ValueChecked,pos);
      end;
      SelectedField.Dataset.Post;
    end;
    inherited;
  end;

procedure TCheckDBGrid.CellClick(Column: TColumn);
  begin
    if TCheckColumn(Column).Check then SaveBoolean;
    inherited;
  end;

procedure TCheckDBGrid.ColEnter;
  begin
    if TCheckColumn(Columns[SelectedIndex]).Check then begin
      Editing:=dgEditing in Options;
      Options:=Options-[dgEditing];
    end;
    inherited;
  end;

procedure TCheckDBGrid.DoEnter;
  begin
    if TCheckColumn(Columns[SelectedIndex]).Check then begin
      Editing:=dgEditing in Options;
      Options:=Options-[dgEditing];
    end;
    inherited;
  end;

procedure TCheckDBGrid.ColExit;
  begin
    if (TCheckColumn(Columns[SelectedIndex]).Check)and Editing then
     Options:=Options+[dgEditing];
    inherited;
  end;

procedure TCheckDBGrid.DoExit;
  begin
    if (TCheckColumn(Columns[SelectedIndex]).Check)and Editing then
     Options:=Options+[dgEditing];
    inherited;
  end;

procedure TCheckDBGrid.KeyDown(var Key: Word; Shift: TShiftState);
  begin
    inherited;
    if (Key=VK_SPACE)and TCheckColumn(Columns[SelectedIndex]).Check then SaveBoolean;
    if (not FAllowAppend)and(DataLink.DataSet.eof)and(Key=VK_DOWN) then begin
      Key:=0;
      DataLink.DataSet.Cancel;
    end;
  end;

procedure TCheckDBGrid.DrawColumnCell(const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
  const CtrlState :array[Boolean] of Integer = (DFCS_BUTTONCHECK, DFCS_BUTTONCHECK or DFCS_CHECKED);
  begin
    inherited;
    if TCheckColumn(Column).Check then begin
      Canvas.FillRect(Rect);
      DrawFrameControl(Canvas.Handle,Rect,DFC_BUTTON,CtrlState[Column.Field.AsBoolean]);
    end;
 end;

procedure Register;
begin
  RegisterComponents('CheckGrids', [TCheckDBGrid]);
end;

end.
