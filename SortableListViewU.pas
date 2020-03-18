unit SortableListViewU;

interface

uses
  Winapi.Windows, System.Classes, Vcl.ComCtrls, Vcl.Controls, Vcl.Graphics, FileCheckerU;

type
  TListView = class(Vcl.ComCtrls.TListView)
  private type
    TSortOptions = record
      SortColumn: Integer;
      SortDescending: Boolean;
    end;
  private
    FSortOptions: TSortOptions;
    FSmallImages: TImageList;
    FLargeImages: TImageList;

    procedure ColumnClick(Sender: TObject; Column: TListColumn);
    procedure Compare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
  public
    constructor Create(aOwner: TComponent); override;
    procedure AddLine(const aFileInformation: TFileInformation);
    procedure Clear; override;
    procedure ShowSelectedInExplorer;
    function ToString: string; override;
  end;

implementation

uses
  Vcl.Forms, System.Generics.Defaults, System.Sysutils, System.IOUtils, Winapi.ShellAPI,
  FileUtilsU;

{ TSortableListView }

procedure TListView.AddLine(const aFileInformation: TFileInformation);
var
  Filename: string;
  Icon: TIcon;
  IconHandle: WORD;
  ImageIndex: Integer;
  ListItem: TListItem;
begin
  Filename := aFileInformation.Filename;
  Icon := TIcon.Create;
  Items.BeginUpdate;
  try
    Icon.Handle := ExtractAssociatedIcon(Application.Handle, PChar(Filename), IconHandle);
    ImageIndex := FSmallImages.AddIcon(Icon);
    FLargeImages.AddIcon(Icon);

    ListItem := Items.Add;
    ListItem.Caption := TPath.GetFileName(Filename);
    ListItem.SubItems.Add(TPath.GetDirectoryName(Filename));

    ListItem.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn', aFileInformation.DataModified));
    ListItem.SubItems.Add(aFileInformation.FileType);
    ListItem.Data := Pointer(aFileInformation.FileSize);

    ListItem.SubItems.Add(FileUtils.ConvertBytes(aFileInformation.FileSize));
    ListItem.SubItems.Add(aFileInformation.CPU);
    ListItem.SubItems.Add(aFileInformation.CompilerName);
    ListItem.SubItems.Add(aFileInformation.SKU);

    ListItem.ImageIndex := ImageIndex;
  finally
    FreeAndNil(Icon);
    Items.EndUpdate;
  end;
end;

procedure TListView.Clear;
begin
  inherited Clear;
  FLargeImages.Clear;
  FSmallImages.Clear;
end;

procedure TListView.ColumnClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index = FSortOptions.SortColumn then
    FSortOptions.SortDescending := not FSortOptions.SortDescending
  else
  begin
    FSortOptions.SortColumn := Column.Index;
    FSortOptions.SortDescending := False;
  end;

  AlphaSort;
end;

procedure TListView.Compare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  if FSortOptions.SortColumn = 0 then
    Compare := TComparer<String>.Default.Compare(Item1.Caption, Item2.Caption)
  else if FSortOptions.SortColumn = 4 then
    Compare := TComparer<Integer>.Default.Compare(Integer(Item1.Data), Integer(Item2.Data))
  else
    Compare := TComparer<String>.Default.Compare(Item1.SubItems[FSortOptions.SortColumn - 1], Item2.SubItems[FSortOptions.SortColumn - 1]);

  if FSortOptions.SortDescending then
    Compare := -Compare;
end;

constructor TListView.Create(aOwner: TComponent);
begin
  Assert(aOwner <> nil, 'You must provide a owner');
  inherited Create(aOwner);

  FSmallImages := TImageList.Create(Self);
  FLargeImages := TImageList.Create(Self);

  LargeImages := FLargeImages;
  SmallImages := FSmallImages;

  FSortOptions.SortColumn := 1;
  FSortOptions.SortDescending := False;

  OnColumnClick := ColumnClick;
  OnCompare := Compare;
end;

procedure TListView.ShowSelectedInExplorer;
var
  Filename: string;
  Parameter: string;
  SelectedItem: TListItem;
begin
  SelectedItem := Selected;

  if not Assigned(SelectedItem) then
    exit;

  Filename := TPath.Combine(SelectedItem.SubItems[0], SelectedItem.Caption);
  Parameter := Format('/select,"%s"', [Filename]);
  ShellExecute(Application.Handle, 'open', 'explorer.exe', PChar(Parameter), nil, SW_NORMAL);
end;

function TListView.ToString: string;
var
  ColumnIndex: Integer;
  RowIndex: Integer;
  CSVList: TStringList;
  Buffer: TStringList;
begin
  Result := '';
  CSVList := TStringList.Create;
  Buffer := TStringList.Create;
  Buffer.QuoteChar := '"';

  try
    CSVList.BeginUpdate;
    try
      for ColumnIndex := 0 to Columns.Count - 1 do
        Buffer.Add(Trim(Columns[ColumnIndex].Caption));

      CSVList.Add(Buffer.CommaText);

      for RowIndex := 0 to Items.Count - 1 do
      begin
        Buffer.Clear;

        Buffer.Add(Items[RowIndex].Caption);

        for ColumnIndex := 1 to Columns.Count - 1 do
          Buffer.Add(Items[RowIndex].SubItems[ColumnIndex - 1]);

        CSVList.Add(Buffer.CommaText);
      end;

      Result := CSVList.Text;
    finally
      Buffer.Free;
      CSVList.EndUpdate;
    end;
  finally
    CSVList.Free;
  end;
end;

end.
