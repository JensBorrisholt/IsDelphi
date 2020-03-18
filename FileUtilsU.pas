unit FileUtilsU;

interface

uses
  System.Generics.Collections, Winapi.Windows;

type
  FileUtils = class sealed
  strict private
    class var FFileTypeNameCache: TDictionary<string, string>;
    class var FExecuteableFileExtentions: TList<string>;
    class var FExecuteableFileExtentionsString: string;
  strict protected
    constructor Create; reintroduce;
  public
    class constructor Create;
    class destructor Destroy;

    class function ConvertBytes(Bytes: Int64): string;
    class function FileTimeToDateTime(AFileTime: TFileTime): TDateTime;
    class function GetFileTypeName(const AFileName: string): string;
    class function IsValidExtention(const aExtention: string): Boolean;

    class property ExecuteableFileExtentions: TList<string> read FExecuteableFileExtentions;
    class property ExecuteableFileExtentionsString: string read FExecuteableFileExtentionsString;
  end;

implementation

uses
  System.Math, System.SysUtils, Winapi.ShellAPI;

{ FileUtils }

constructor FileUtils.Create;
begin
  raise Exception.Create('This is a static class! DO NOT create an instance');
end;

class function FileUtils.ConvertBytes(Bytes: Int64): string;
const
  Description: Array [0 .. 8] of string = ('Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB');
var
  i: Integer;
begin
  i := 0;

  while Bytes > Power(1024, i + 1) do
    Inc(i);

  Result := FormatFloat('###0.##', Bytes / IntPower(1024, i)) + ' ' + Description[i];
end;

class constructor FileUtils.Create;
const
  Separator: array [0 .. 0] of string = ('|');
  EXECUTABLE_FILE_EXTENSIONS = '.exe|.dll|.ocx|.bpl|.cpl|.scr';
var
  FileInfo: SHFILEINFO;
  s, FileExtension: String;
begin
  FExecuteableFileExtentions := TList<string>.Create;
  FExecuteableFileExtentions.AddRange(EXECUTABLE_FILE_EXTENSIONS.Split(Separator));

  FFileTypeNameCache := TDictionary<string, string>.Create;

  FExecuteableFileExtentionsString := '';

  for s in FExecuteableFileExtentions do
  begin
    FExecuteableFileExtentionsString := FExecuteableFileExtentionsString + '*' + s + ';';
    FileExtension := '*' + s;
    if SHGetFileInfo(PChar(FileExtension), FILE_ATTRIBUTE_NORMAL, FileInfo, SizeOf(FileInfo), SHGFI_TYPENAME or SHGFI_USEFILEATTRIBUTES) <> 0 then
      FFileTypeNameCache.Add(s, string(FileInfo.szTypeName));
  end;
end;

class destructor FileUtils.Destroy;
begin
  FExecuteableFileExtentions.Free;
  FFileTypeNameCache.Free;
end;

class function FileUtils.FileTimeToDateTime(AFileTime: TFileTime): TDateTime;
var
  LModifiedTime: TFileTime;
  LSystemTime: TSystemTime;
begin
  Result := 0;

  if (AFileTime.dwLowDateTime = 0) and (AFileTime.dwHighDateTime = 0) then
    Exit;

  try
    FileTimeToLocalFileTime(AFileTime, LModifiedTime);
    FileTimeToSystemTime(LModifiedTime, LSystemTime);
    Result := SystemTimeToDateTime(LSystemTime);
  except
    Result := Now;
  end;
end;

class function FileUtils.GetFileTypeName(const AFileName: string): string;
begin
  if not FFileTypeNameCache.TryGetValue(ExtractFileExt(AFileName), Result) then
    Result := '<Unknown filetype>';
end;

class function FileUtils.IsValidExtention(const aExtention: string): Boolean;
begin
  Result := FExecuteableFileExtentions.Contains(aExtention);
end;

end.
