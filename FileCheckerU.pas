unit FileCheckerU;

interface

type
  TFileInformation = record
    FileName: string;
    FileSize: Int64;
    DataModified: TDateTime;
    FileType: string;
    CPU: string;
    CompilerName: string;
    SKU: string;
  private
    procedure Clear;
  public
    constructor Create(aFileName: string);
  end;

  TResourceInformation = record
    ResourceIsFDM: Boolean;
    ResourceContainsLCLVersion: Boolean;
  end;

function FileIsInteresting(const aFileName: string; var aFileDetails: TFileInformation): Boolean;

implementation

uses
  System.SysUtils, Winapi.Windows, System.Classes, FileUtilsU;

function CheckCompiler(const aFileName: string; var aCompilerName, aSKUName: string): Boolean; forward;
function CheckDFMResource(ALibraryHandle: Cardinal; const aResourceName: string): TResourceInformation; forward;
function CheckDVCLAL(ALibraryHandle: Cardinal; var aCompilerName, aSKUName: string): Boolean; forward;
function CheckForLazarusForm(aResourceStream: TResourceStream): Boolean; forward;
function CheckPackageInfo(ALibraryHandle: Cardinal; var aCompilerName: string): Boolean; forward;
function CheckPE(const aFileName: string; var aCPU: string): Boolean; forward;

procedure TFileInformation.Clear;
begin
  FileName := '';
  FileSize := -1;
  DataModified := 0;
  FileType := '';
  CPU := '';
  CompilerName := '';
  SKU := '';
end;

procedure PackageInfoCallbackProc(const Name: string; NameType: TNameType; Flags: Byte; Param: Pointer);
begin
  // Intentionaly left empty
end;

function EnumRCDataCallbackProc(HMODULE: THandle; lpszType, lpszName: PChar; List: TStrings): Boolean; stdcall;
begin
  List.Add(lpszName);
  Result := True;
end;

function CheckCompiler(const aFileName: string; var aCompilerName, aSKUName: string): Boolean;
var
  ResourceName: string;
  LibraryHandle: Cardinal;
  ResourceNameList: TStringList;
  DFMCount: Integer;
  ResourceInformation: TResourceInformation;
begin
  Result := False;

  LibraryHandle := LoadLibraryEX(PChar(aFileName), 0, LOAD_LIBRARY_AS_DATAFILE);
  if LibraryHandle <= 0 then
    exit;

  try
    if CheckDVCLAL(LibraryHandle, aCompilerName, aSKUName) then
      Result := True;

    if CheckPackageInfo(LibraryHandle, aCompilerName) then
      Result := True;

    if Result then
      exit;

    try
      ResourceNameList := TStringList.Create;
      ResourceNameList.CaseSensitive := False;
      ResourceNameList.Sorted := True;
      try
        EnumResourceNames(LibraryHandle, RT_RCDATA, @EnumRCDataCallbackProc, NativeInt(ResourceNameList));
        DFMCount := 0;

        for ResourceName in ResourceNameList do
        begin
          ResourceInformation := CheckDFMResource(LibraryHandle, ResourceName);

          if ResourceInformation.ResourceIsFDM then
            Inc(DFMCount);

          if ResourceInformation.ResourceContainsLCLVersion then
          begin
            aCompilerName := 'Lazarus';
            exit(True);
          end;
        end;

        if ResourceNameList.IndexOf('DVCLAL') >= 0 then
        begin
          aCompilerName := 'Delphi or C++ Builder (has DVCLAL)';
          aSKUName := 'Unreadable';
          exit(True);
        end;

        if ResourceNameList.IndexOf('PACKAGEINFO') >= 0 then
        begin
          aCompilerName := 'Delphi or C++ Builder (has PACKAGEINFO)';
          exit(True);
        end;

        if DFMCount > 0 then
        begin
          aCompilerName := 'Delphi or C++ Builder (has DFM)';
          exit(True);
        end;
      finally
        ResourceNameList.Free;
      end;

    except
      // TODO: Add proper exception handling
    end;

  finally
    FreeLibrary(LibraryHandle);
  end;
end;

function CheckDFMResource(ALibraryHandle: Cardinal; const aResourceName: string): TResourceInformation;
var
  ResourceStream: TResourceStream;
  Buffer: TBytes;
begin
  Result.ResourceIsFDM := False;
  Result.ResourceContainsLCLVersion := False;

  try
    ResourceStream := TResourceStream.Create(ALibraryHandle, aResourceName, RT_RCDATA);
    try
      // The first 4 bytes of a form resource are "TPF0"
      SetLength(Buffer, 4);
      ResourceStream.Read(Buffer[0], Length(Buffer));
      if StringOf(Buffer) = 'TPF0' then
      begin
        Result.ResourceIsFDM := True;

        // Since we've already read the form, might as well do some extra checking
        Result.ResourceContainsLCLVersion := CheckForLazarusForm(ResourceStream);
      end;
    finally
      ResourceStream.Free;
    end;
  except
  end;
end;

function CheckDVCLAL(ALibraryHandle: Cardinal; var aCompilerName, aSKUName: string): Boolean;
const
  SKU_PER: TBytes = [$23, $78, $5D, $23, $B6, $A5, $F3, $19, $43, $F3, $40, $02, $26, $D1, $11, $C7];
  SKU_PRO: TBytes = [$A2, $8C, $DF, $98, $7B, $3C, $3A, $79, $26, $71, $3F, $09, $0F, $2A, $25, $17];
  SKU_ENT: TBytes = [$26, $3D, $4F, $38, $C2, $82, $37, $B8, $F3, $24, $42, $03, $17, $9B, $3A, $83];
var
  Buffer: TBytes;
  ResourceSize: Integer;
  ResourceStream: TResourceStream;
begin
  Result := False;
  aSKUName := '';

  try
    ResourceStream := TResourceStream.Create(ALibraryHandle, 'DVCLAL', RT_RCDATA); // load resource in memory
    try
      ResourceSize := ResourceStream.Size;
      SetLength(Buffer, ResourceSize);
      ResourceStream.Read(Buffer[0], Length(Buffer));
    finally
      ResourceStream.Free;
    end;

    if ResourceSize > 0 then
    begin
      Result := True;
      aCompilerName := 'Delphi or C++ Builder';

      if CompareMem(Buffer, SKU_ENT, ResourceSize) then
        aSKUName := 'Enterprise'
      else if CompareMem(Buffer, SKU_PRO, ResourceSize) then
        aSKUName := 'Professional'
      else if CompareMem(Buffer, SKU_PER, ResourceSize) then
        aSKUName := 'Personal'
      else
        aSKUName := 'Unknown';
    end;
  except
    Result := False;
  end;
end;

function CheckForLazarusForm(aResourceStream: TResourceStream): Boolean;
var
  DFMStream: TMemoryStream;
  DFM: TStringList;
begin
  Result := False;

  DFMStream := TMemoryStream.Create;
  try
    aResourceStream.Seek(0, 0);
    // Form resources are always stored as binary
    ObjectBinaryToText(aResourceStream, DFMStream);
    DFMStream.Seek(0, 0);
    DFM := TStringList.Create;
    try
      DFM.LoadFromStream(DFMStream);
      if Pos('LCLVersion', DFM.Text) <> 0 then
        exit(True);
    finally
      DFM.Free;
    end;
  finally
    DFMStream.Free;
  end;
end;

function CheckPackageInfo(ALibraryHandle: Cardinal; var aCompilerName: string): Boolean;
var
  PackageFlags: Integer;
begin
  Result := False;

  try
    GetPackageInfo(ALibraryHandle, nil, PackageFlags, PackageInfoCallbackProc);
    Result := True;

    if (PackageFlags and pfProducerMask = pfV3Produced) then
      aCompilerName := 'Delphi pre-V4'
    else if (PackageFlags and pfProducerMask = pfDelphi4Produced) then
      aCompilerName := 'Delphi'
    else if (PackageFlags and pfProducerMask = pfBCB4Produced) then
      aCompilerName := 'C++ Builder'
    else if (PackageFlags and pfProducerMask = pfProducerUndefined) then
      aCompilerName := 'Delphi or C++ Builder (undefined flag)';
  except
    // ACompilerName left as-is
  end;
end;

function CheckPE(const aFileName: string; var aCPU: string): Boolean;
var
  Base: Pointer;
  Handle, Map: HWND;
  DosHeader: pImageDosHeader;
  ImageNTHeader32: pImageNtHeaders32;
begin
  Result := False;
  aCPU := '';

  Handle := CreateFile(PChar(aFileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

  if Handle = INVALID_HANDLE_VALUE then
  begin
    // raise Exception.Create('Unable to open file: ' + SysErrorMessage(GetLastError));
    exit;
  end;

  try
    Map := CreateFileMapping(Handle, nil, PAGE_READONLY, 0, 0, nil);

    if (Map = 0) then
      exit;

    try
      if (GetLastError() = ERROR_ALREADY_EXISTS) then
      begin
        // raise Exception.Create('Mapping already exists - not created.');
        exit;
      end;

      Base := MapViewOfFile(Map, FILE_MAP_READ, 0, 0, 0);
      if (Base = nil) then
        exit;

      try
        try
          DosHeader := pImageDosHeader(Base);

          if DosHeader.e_magic <> IMAGE_DOS_SIGNATURE then
          begin
            // raise Exception.Create('Invalid DOS header signature');
            exit;
          end;

          ImageNTHeader32 := pImageNtHeaders32(Pointer(Integer(Base) + DosHeader._lfanew));

          // All .Net assemblies are PE files
          // http://www.codeguru.com/cpp/w-p/dll/openfaq/article.php/c14001/Determining-Whether-a-DLL-or-EXE-Is-a-Managed-Component.htm
          if (ImageNTHeader32.Signature = IMAGE_NT_SIGNATURE) and (ImageNTHeader32.OptionalHeader.Magic = $10B) then
          begin
            if ImageNTHeader32.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR].VirtualAddress <> 0 then
            begin
              // No need to check .Net assemblies
              exit;
            end;
          end;

          case ImageNTHeader32.OptionalHeader.Magic of
            $10B:
              aCPU := '32 bit';
            $20B:
              aCPU := '64 bit';
            $107:
              aCPU := 'ROM Image';
          else
            aCPU := 'Unknown';
          end;

          Result := True;
        except
          exit;
        end;
      finally
        if Handle <> 0 then
        begin
          UnmapViewOfFile(Base);
        end;
      end;
    finally
      CloseHandle(Map);
    end;
  finally
    CloseHandle(Handle);
  end;
end;

function FileIsInteresting(const aFileName: string; var aFileDetails: TFileInformation): Boolean;
var
  CompilerName: string;
  SKUName: string;
  CPU: string;
  AttributeData: TWin32FileAttributeData;
begin
  Result := True;

  aFileDetails.Clear;
  aFileDetails.FileName := aFileName;

  if not CheckPE(aFileName, CPU) then
    exit(False);

  aFileDetails.CPU := CPU;

  if not CheckCompiler(aFileName, CompilerName, SKUName) then
    exit(False);

  aFileDetails.CompilerName := CompilerName;
  aFileDetails.SKU := SKUName;

  aFileDetails.FileType := FileUtils.GetFileTypeName(aFileName);

  if GetFileAttributesEx(PChar(aFileName), GetFileExInfoStandard, @AttributeData) then
  begin
    Int64Rec(aFileDetails.FileSize).Lo := AttributeData.nFileSizeLow;
    Int64Rec(aFileDetails.FileSize).Hi := AttributeData.nFileSizeHigh;
    aFileDetails.DataModified := FileUtils.FileTimeToDateTime(AttributeData.ftLastWriteTime);
  end;
end;

constructor TFileInformation.Create(aFileName: string);
begin
  Clear;
  FileName := aFileName;
end;

end.
