program IsDelphi;

uses
  Vcl.Forms,
  FileCheckerU in 'FileCheckerU.pas',
  FileScannerU in 'FileScannerU.pas',
  FileUtilsU in 'FileUtilsU.pas',
  MainU in 'MainU.pas' {MainForm},
  SortableListViewU in 'SortableListViewU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
