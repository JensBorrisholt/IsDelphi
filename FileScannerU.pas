unit FileScannerU;

interface


uses
  System.Classes, System.Generics.Collections, FileCheckerU;

type
  TMessageProc<T> = reference to procedure(const Data: T);

  TComThread<T> = class(TThread)
  private
    FReceiver: TMessageProc<T>;
  strict protected
    procedure SendToMain(const aValue: T);
  public
    constructor Create(aCreateSuspended: Boolean; const aReceiver: TMessageProc<T>); reintroduce;
  end;

  TFileScanner = class(TComThread<TFileInformation>)
  private
    FPath: string;
  protected
    procedure Execute; override;
  public
    constructor Create(aPath: string; const aFileFoundProc: TMessageProc<TFileInformation>); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.IoUtils,

  FileUtilsU;

{ TFileScanner }

constructor TFileScanner.Create(aPath: string; const aFileFoundProc: TMessageProc<TFileInformation>);
begin
  inherited Create(False, aFileFoundProc);
  FreeOnTerminate := True;
  FPath := aPath;
end;

destructor TFileScanner.Destroy;
begin
  SendToMain(TFileInformation.Create(''));
  inherited;
end;

procedure TFileScanner.Execute;
var
  LastPath: string;
  FileInformation: TFileInformation;
begin
  LastPath := '';

  if TFile.Exists(FPath) then
  begin
    if FileIsInteresting(FPath, FileInformation) then
      SendToMain(FileInformation);
    exit;
  end;

  TDirectory.GetFiles(FPath, TSearchOption.soAllDirectories,
    function(const Path: string; const SearchRec: TSearchRec): Boolean
    begin
      Result := False;

      if Terminated then
        exit;

      if Path <> LastPath then
      begin
        LastPath := Path;
        SendToMain(TFileInformation.Create(Path));
      end;

      if FileUtils.IsValidExtention(TPath.GetExtension(SearchRec.Name)) then
        if FileIsInteresting(TPath.Combine(Path, SearchRec.Name), FileInformation) then
          SendToMain(FileInformation);
    end);
end;

{ TComThread<T> }

constructor TComThread<T>.Create(aCreateSuspended: Boolean; const aReceiver: TMessageProc<T>);
begin
  FReceiver := aReceiver;
  inherited Create(aCreateSuspended);
end;

procedure TComThread<T>.SendToMain(const aValue: T);
var
  CallBack: TThreadProcedure;
begin
  CallBack := procedure
    begin
      FReceiver(aValue);
    end;

  Synchronize(CallBack);
end;

end.
