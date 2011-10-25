(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit CoverageConfiguration;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  SysUtils,
  I_CoverageConfiguration,
  I_ParameterProvider;

type
  TCoverageConfiguration = class(TInterfacedObject, ICoverageConfiguration)
  private
    FExeFileName             : string;
    FMapFileName             : string;
    FSourceDir               : string;
    FOutputDir               : string;
    FDebugLogFileName        : string;
    FApiLogging              : Boolean;
    FParameterProvider       : IParameterProvider;
    FUnitsStrLst             : TStringList;
    FExeParamsStrLst         : TStrings;
    FSourcePathLst           : TStrings;
    FStripFileExtenstion     : Boolean;

    procedure ReadUnitsFile(const AUnitsFileName : string);
    procedure ReadSourcePathFile(const ASourceFileName : string);
    function parseParam(const AParameter: Integer): string;
    procedure parseSwitch(var AParameter: Integer);
  public
    constructor Create(const AParameterProvider: IParameterProvider);
    destructor Destroy; override;

    procedure ParseCommandLine();

    function GetApplicationParameters         : string;
    function GetExeFileName                   : string;
    function GetMapFileName                   : string;
    function GetOutputDir                     : string;
    function GetSourceDir                     : string;
    function GetDebugLogFile                  : string;
    function GetSourcePaths                   : TStrings;
    function GetUnits                         : TStrings;
    function UseApiDebug                      : boolean;
    function IsComplete(var AReason : string) : Boolean;
  end;

  EConfigurationException = class(Exception);

implementation

uses
  StrUtils,
  JclFileUtils;

function Unescape(const param: string): string;
var
  lp: Integer;
begin
  Result := '';
  if length(param) > 0 then
  begin
    lp := 1;
    while lp <= length(param) do
    begin
      if param[lp] = I_CoverageConfiguration.cESCAPE_CHARACTER then
        inc(lp);
      Result := Result + param[lp];
      inc(lp);
    end;
  end;
end;

constructor TCoverageConfiguration.Create(const AParameterProvider:
    IParameterProvider);
begin
  inherited Create;

  FParameterProvider         := AParameterProvider;
  FExeParamsStrLst           := TStringList.Create;

  FUnitsStrLst               := TStringList.Create;
  FUnitsStrLst.CaseSensitive := False;
  FUnitsStrLst.Sorted        := True;
  FUnitsStrLst.Duplicates    := dupIgnore;

  FApiLogging                := False;

  FStripFileExtenstion       := True;

  FSourcePathLst             := TStringList.Create;
end;

destructor TCoverageConfiguration.Destroy;
begin
  FUnitsStrLst.Free;
  FExeParamsStrLst.Free;
  FSourcePathLst.Free;    

  inherited;
end;

function TCoverageConfiguration.IsComplete(var AReason : string) : boolean;
begin
  if FSourcePathLst.Count = 0 then
    FSourcePathLst.Add(''); // Default directory.

  Result := True;

  if (FExeFileName = '') then
  begin
    // Executable not specified.
    Result := False;
    AReason := 'No executable was specified';
  end
  else if not FileExists(FExeFileName) then
  begin
    // Executable does not exists.
    Result := False;
    AReason := 'The executable file ' + FExeFileName + ' does not exist. Current dir is ' + GetCurrentDir();
  end;

  if (FMapFileName = '') then
  begin
    // Map File not specified.
    Result := False;
    AReason := 'No map file was specified';
  end
  else if not FileExists(FMapFileName) then
  begin
    // Map File does not exists.
    Result := False;
    AReason := 'The map file ' + FMapFileName + ' does not exist. Current dir is ' + GetCurrentDir();
   end;
end;

function TCoverageConfiguration.GetUnits : TStrings;
begin
  Result := FUnitsStrLst;
end;

function TCoverageConfiguration.GetSourcePaths: TStrings;
begin
  Result := FSourcePathLst;
end;

function TCoverageConfiguration.GetApplicationParameters: string;
var
  lp: Integer;
begin
  Result := '';
  for lp := 0 to FExeParamsStrLst.Count - 1 do
    Result := Result + FExeParamsStrLst[lp] + ' ';

  Result := Copy(Result, 1, Length(Result) - 1);
end;

function TCoverageConfiguration.GetDebugLogFile: string;
begin
  Result := FDebugLogFileName;
end;

function TCoverageConfiguration.GetMapFileName: string;
begin
  Result := FMapFileName;
end;

function TCoverageConfiguration.GetExeFileName: string;
begin
  Result := FExeFileName;
end;

function TCoverageConfiguration.GetOutputDir: string;
begin
  Result := FOutputDir;
end;

function TCoverageConfiguration.GetSourceDir: string;
begin
  Result := FSourceDir;
end;

procedure TCoverageConfiguration.ReadUnitsFile(const AUnitsFileName: string);
var
  InputFile : TextFile;
  UnitLine  : string;
begin
  AssignFile(InputFile, AUnitsFileName);
  try
    try
      System.FileMode := fmOpenRead;
      Reset(InputFile);
    except
      on E: EInOutError do
      begin
        WriteLn('Could not open:' + AUnitsFileName);
        raise;
      end;
    end;

    while (not Eof(InputFile)) do
    begin
      ReadLn(InputFile, UnitLine);
      if FStripFileExtenstion then
        UnitLine := PathExtractFileNameNoExt(UnitLine);
      FUnitsStrLst.Add(UnitLine);
    end;
  finally
    CloseFile(InputFile);
  end;
end;

procedure TCoverageConfiguration.ReadSourcePathFile(
  const ASourceFileName: string);
var
  InputFile : TextFile;
  SourcePathLine  : string;
begin
  AssignFile(InputFile, ASourceFileName);
  try
    try
      System.FileMode := fmOpenRead;
      Reset(InputFile);
    except
      on E: EInOutError do
      begin
        WriteLn('Could not open:' + ASourceFileName);
        raise;
      end;
    end;

    while (not Eof(InputFile)) do
    begin
      ReadLn(InputFile, SourcePathLine);

      if DirectoryExists(SourcePathLine) then
        FSourcePathLst.Add(SourcePathLine);
    end;
  finally
    CloseFile(InputFile);
  end;
end;

function TCoverageConfiguration.UseApiDebug: Boolean;
begin
  Result := FApiLogging;
end;

procedure TCoverageConfiguration.ParseCommandLine();
var
  ParameterIdx: Integer;
begin
  ParameterIdx := 1;
  while ParameterIdx <= FParameterProvider.Count do
  begin
    parseSwitch(ParameterIdx);
    inc(ParameterIdx);
  end;
end;

function TCoverageConfiguration.parseParam(const AParameter: Integer): string;
var
  param: string;
begin
  if AParameter > FParameterProvider.Count then
  begin
    Result := '';
  end
  else
  begin
    param := FParameterProvider.ParamString(AParameter);
    if (LeftStr(param, 1) = '-') then
    begin
      Result := '';
    end
    else
      Result := Unescape(param);
  end;
end;

procedure TCoverageConfiguration.parseSwitch(var AParameter: Integer);
var
  SourcePathString   : string;
  SourcePathFileName : string;
  UnitString         : string;
  UnitsFileName      : string;
  ExecutableParam    : string;
  SwitchItem         : string;
begin
  SwitchItem := FParameterProvider.ParamString(AParameter);
  if SwitchItem = I_CoverageConfiguration.cPARAMETER_EXECUTABLE then
  begin
    inc(AParameter);
    FExeFileName := parseParam(AParameter);
    if FExeFileName = '' then
      raise EConfigurationException.Create('Expected parameter for executable');

    // Now if we haven't yet set the mapfile, we set it by default to be the executable name +.map
    if FMapFileName = '' then
      FMapFileName := ChangeFileExt(FExeFileName, '.map');
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_MAP_FILE then
  begin
    inc(AParameter);
    try
      FMapFileName := parseParam(AParameter);
      if FMapFileName = '' then
        raise EConfigurationException.Create('Expected parameter for mapfile');
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for mapfile');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_UNIT then
  begin
    inc(AParameter);
    try
      UnitString := parseParam(AParameter);
      while UnitString <> '' do
      begin
        if FStripFileExtenstion then
          UnitString := PathRemoveExtension(UnitString); // Ensures that we strip out .pas if it was added for some reason
        FUnitsStrLst.add(UnitString);
        inc(AParameter);
        UnitString := parseParam(AParameter);
      end;
      if FUnitsStrLst.Count = 0 then
        raise EConfigurationException.Create('Expected at least one unit');
      dec(AParameter);
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected at least one unit');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_UNIT_FILE then
  begin
    inc(AParameter);
    try
      UnitsFileName := parseParam(AParameter);
      if UnitsFileName <> '' then
      begin
        ReadUnitsFile(UnitsFileName);
      end
      else
        raise EConfigurationException.Create('Expected parameter for units file name');
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for units file name');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER then
  begin
    inc(AParameter);
    ExecutableParam := parseParam(AParameter);
    while ExecutableParam <> '' do
    begin
      FExeParamsStrLst.add(ExecutableParam);
      inc(AParameter);
      ExecutableParam := parseParam(AParameter);
    end;
    if FExeParamsStrLst.Count = 0 then
      raise EConfigurationException.Create('Expected at least one executable parameter');
    dec(AParameter);
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_SOURCE_DIRECTORY then
  begin
    inc(AParameter);
    FSourceDir := parseParam(AParameter);
    if FSourceDir = '' then
      raise EConfigurationException.Create('Expected parameter for source directory');

    // Source Directory should be checked first.
    FSourcePathLst.Insert(0, FSourceDir);
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS then
  begin
    inc(AParameter);
    try
      SourcePathString := parseParam(AParameter);
      while SourcePathString <> '' do
      begin
        SourcePathString := PathRemoveExtension(SourcePathString);

        if DirectoryExists(SourcePathString) then
          FSourcePathLst.add(SourcePathString);

        inc(AParameter);
        SourcePathString := parseParam(AParameter);
      end;
      if FSourcePathLst.Count = 0 then
        raise EConfigurationException.Create('Expected at least one source path');
      dec(AParameter);
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected at least one source path');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE then
  begin
    inc(AParameter);
    try
      SourcePathFileName := parseParam(AParameter);
      if SourcePathFileName <> '' then
      begin
        ReadSourcePathFile(SourcePathFileName);
      end
      else
        raise EConfigurationException.Create('Expected parameter for source path file name');
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for source path file name');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_OUTPUT_DIRECTORY then
  begin
    inc(AParameter);
    FOutputDir := parseParam(AParameter);
    if FOutputDir = '' then
      raise EConfigurationException.Create('Expected parameter for output directory');
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_LOGGING_TEXT then
  begin
    inc(AParameter);
    try
      FDebugLogFileName := parseParam(AParameter);
      if FDebugLogFileName = '' then
        FDebugLogFileName := I_CoverageConfiguration.cDEFULT_DEBUG_LOG_FILENAME;
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for debug log file');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_LOGGING_WINAPI then
  begin
    inc(AParameter);
    FApiLogging := True;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE then
  begin
    FStripFileExtenstion := False;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE then
  begin
    FStripFileExtenstion := True;
  end
  else
  begin
    raise EConfigurationException.Create('Unexpected switch:' + SwitchItem);
  end;
end;

end.

