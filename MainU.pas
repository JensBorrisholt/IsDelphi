unit MainU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Menus, System.Actions, Vcl.ActnList, Vcl.ComCtrls, System.Generics.Collections,

  FileCheckerU, SortableListViewU, FileScannerU;

type
  TMainForm = class(TForm)
    lvFiles: TListView;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;

    ActionList1: TActionList;
    actCancel: TAction;
    actCopyToClipboard: TAction;
    actExit: TAction;
    actOpenFile: TAction;
    actOpenFolder: TAction;
    actRefresh: TAction;
    actShowInExplorer: TAction;

    CopytoClipboard2: TMenuItem;
    N2: TMenuItem;
    OpeninExplorer1: TMenuItem;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    OpenFiles1: TMenuItem;
    OpenFolders1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    Edit1: TMenuItem;
    CopytoClipboard1: TMenuItem;
    View1: TMenuItem;
    Cancel1: TMenuItem;
    Refresh1: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure actExitExecute(Sender: TObject);
    procedure actOpenFileExecute(Sender: TObject);
    procedure actOpenFolderExecute(Sender: TObject);
    procedure actShowInExplorerExecute(Sender: TObject);
    procedure actCopyToClipboardExecute(Sender: TObject);
    procedure actRefreshExecute(Sender: TObject);
    procedure actCancelExecute(Sender: TObject);
    procedure ActionList1Update(Action: TBasicAction; var Handled: Boolean);
  private
    FFileInformations: TList<TFileInformation>;
    FFileScanner: TFileScanner;

    procedure Clear;
    procedure UpdateFileCount;
    procedure FileFound(const aFileInformation: TFileInformation);
  end;

var
  MainForm: TMainForm;

implementation

uses
  FileUtilsU, Vcl.Clipbrd;

{$R *.dfm}
{ TfrmMain }

procedure TMainForm.actCancelExecute(Sender: TObject);
begin
  StatusBar1.Panels[1].Text := 'Done.';
  FFileScanner.Terminate;
  FFileScanner := nil;
end;

procedure TMainForm.actCopyToClipboardExecute(Sender: TObject);
begin
  Clipboard.AsText := lvFiles.ToString;
end;

procedure TMainForm.actExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.ActionList1Update(Action: TBasicAction; var Handled: Boolean);
var
  IsScanning: Boolean;
begin
  IsScanning := FFileScanner <> nil;
  actOpenFile.Enabled := not IsScanning;
  actOpenFolder.Enabled := not IsScanning;
  actCancel.Enabled := IsScanning;
  actRefresh.Enabled := not IsScanning;
  actShowInExplorer.Enabled := Assigned(lvFiles.Selected);
  actCopyToClipboard.Enabled := lvFiles.Items.Count > 0;
end;

procedure TMainForm.actOpenFileExecute(Sender: TObject);
var
  &File: string;
  Item: TFileTypeItem;
begin
  with TFileOpenDialog.Create(nil) do
    try
      Options := [fdoAllowMultiSelect, fdoPathMustExist, fdoFileMustExist];

      Item := FileTypes.Add;
      Item.DisplayName := 'All Files';
      Item.FileMask := '*.*';

      Item := FileTypes.Add;
      Item.DisplayName := 'Executable Files';
      Item.FileMask := FileUtils.ExecuteableFileExtentionsString;

      FileTypeIndex := 2;

      if not Execute then
        exit;

      Clear;

      for &File in Files do
        TFileScanner.Create(&File, FileFound);
    finally
      Free;
    end;
end;

procedure TMainForm.actOpenFolderExecute(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
    try
      Options := [fdoPickFolders];

      if not Execute then
        exit;

      Clear;
      FFileScanner := TFileScanner.Create(FileName, FileFound);
    finally
      Free;
    end;
end;

procedure TMainForm.actRefreshExecute(Sender: TObject);
var
  Information: TFileInformation;
begin
  lvFiles.Clear;

  for Information in FFileInformations do
    FileFound(Information);
end;

procedure TMainForm.actShowInExplorerExecute(Sender: TObject);
begin
  lvFiles.ShowSelectedInExplorer;
end;

procedure TMainForm.Clear;
begin
  FFileInformations.Clear;
  lvFiles.Clear;
end;

procedure TMainForm.FileFound(const aFileInformation: TFileInformation);
var
  FileName: string;
begin
  FileName := aFileInformation.FileName;

  if aFileInformation.FileSize < 0 then
  begin
    if FileName <> '' then
      StatusBar1.Panels[1].Text := 'Scanning ' + FileName + ' ...'
    else
    begin
      FFileScanner := nil;
      StatusBar1.Panels[1].Text := 'Done.';
    end;

    exit;
  end;

  if not FFileInformations.Contains(aFileInformation) then
    FFileInformations.Add(aFileInformation);

  UpdateFileCount;
  lvFiles.AddLine(aFileInformation);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FFileInformations := TList<TFileInformation>.Create;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  actCancel.Execute;
  FFileInformations.Free;
end;

procedure TMainForm.UpdateFileCount;
var
  FileCount: Integer;
begin
  FileCount := FFileInformations.Count;

  if FileCount = 0 then
    StatusBar1.Panels[0].Text := 'No files found'
  else
    StatusBar1.Panels[0].Text := Format('%.0n files found', [FileCount + 0.0]);
end;

end.
