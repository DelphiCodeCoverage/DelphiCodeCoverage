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
  XMLIntf,
  I_CoverageConfiguration,
  I_ParameterProvider,
  I_LogManager,
  ModuleNameSpaceUnit,
  uConsoleOutput;

type
  TCoverageConfiguration = class(TInterfacedObject, ICoverageConfiguration)
  strict private
    FExeFileName: string;
    FMapFileName: string;
    FSourceDir: string;
    FOutputDir: string;
    FDebugLogFileName: string;
    FApiLogging: Boolean;
    FParameterProvider: IParameterProvider;
    FDProjUnitsLst: TStringList;
    FUnitsStrLst: TStringList;
    FExcludedUnitsStrLst: TStringList;
    FExeParamsStrLst: TStrings;
    FSourcePathLst: TStrings;
    FStripFileExtension: Boolean;
    FEmmaOutput: Boolean;
    FSeparateMeta: Boolean;
    FXmlOutput: Boolean;
    FHtmlOutput: Boolean;
    FTestExeExitCode: Boolean;
    FExcludeSourceMaskLst: TStrings;
    FLoadingFromDProj: Boolean;
    FModuleNameSpaces: TModuleNameSpaceList;
    FUnitNameSpaces: TUnitNameSpaceList;
    FLogManager: ILogManager;

    procedure ReadSourcePathFile(const ASourceFileName: string);
    function ParseParameter(const AParameter: Integer): string;
    procedure ParseSwitch(var AParameter: Integer);
    procedure ParseBooleanSwitches;
    function GetCurrentConfig(const Project: IXMLNode): string;
    function GetExeOutputFromDProj(const Project: IXMLNode; const ProjectName: TFileName): string;
    procedure ParseDProj(const DProjFilename: TFileName);
    function IsPathInExclusionList(const APath: TFileName): Boolean;
    procedure ExcludeSourcePaths;
    procedure RemovePathsFromUnits;
    function ExpandEnvString(const APath: string): string;
    procedure LogTracking;
    function IsExecutableSet(var AReason: string): Boolean;
    function IsMapFileSet(var AReason: string): Boolean;
    procedure OpenInputFileForReading(const AFileName: string; var InputFile: TextFile);
    function MakePathAbsolute(const APath, ASourceFileName: string): string;
    procedure ParseExecutableSwitch(var AParameter: Integer);
    procedure ParseMapFileSwitch(var AParameter: Integer);
    procedure ParseUnitSwitch(var AParameter: Integer);
    procedure AddUnitString(AUnitString: string);
    procedure ParseUnitFileSwitch(var AParameter: Integer);
    procedure ReadUnitsFile(const AUnitsFileName: string);
    procedure ParseExecutableParametersSwitch(var AParameter: Integer);
    procedure ParseSourceDirectorySwitch(var AParameter: Integer);
    procedure ParseSourcePathsSwitch(var AParameter: Integer);
    procedure ParseSourcePathsFileSwitch(var AParameter: Integer);
    procedure ParseOutputDirectorySwitch(var AParameter: Integer);
    procedure ParseLoggingTextSwitch(var AParameter: Integer);
    procedure ParseWinApiLoggingSwitch(var AParameter: Integer);
    procedure ParseDprojSwitch(var AParameter: Integer);
    procedure ParseExcludeSourceMaskSwitch(var AParameter: Integer);
    procedure ParseModuleNameSpaceSwitch(var AParameter: Integer);
    procedure ParseUnitNameSpaceSwitch(var AParameter: Integer);
  public
    constructor Create(const AParameterProvider: IParameterProvider);
    destructor Destroy; override;

    procedure ParseCommandLine(const ALogManager: ILogManager = nil);

    function ApplicationParameters: string;
    function ExeFileName: string;
    function MapFileName: string;
    function OutputDir: string;
    function SourceDir: string;
    function DebugLogFile: string;
    function SourcePaths: TStrings;
    function Units: TStrings;
    function ExcludedUnits: TStrings;
    function UseApiDebug: Boolean;
    function IsComplete(var AReason: string): Boolean;
    function EmmaOutput: Boolean;
    function SeparateMeta: Boolean;
    function XmlOutput: Boolean;
    function HtmlOutput: Boolean;
    function TestExeExitCode: Boolean;

    function ModuleNameSpace(const AModuleName: string): TModuleNameSpace;
    function UnitNameSpace(const AModuleName: string): TUnitNameSpace;
  end;

  EConfigurationException = class(Exception);

implementation

uses
  StrUtils,
  JclFileUtils,
  {$IF CompilerVersion < 21}
  IOUtilsD9,
  {$ELSE}
  IOUtils,
  {$IFEND}
  LoggerTextFile,
  LoggerAPI,
  XMLDoc,
  Windows,
  Masks;

function Unescape(const AParameter: string): string;
var
  lp: Integer;
begin
  Result := '';
  if Length(AParameter) > 0 then
  begin
    lp := 1;
    while lp <= length(AParameter) do
    begin
      if AParameter[lp] = I_CoverageConfiguration.cESCAPE_CHARACTER then
        Inc(lp);
      Result := Result + AParameter[lp];
      Inc(lp);
    end;
  end;
end;

constructor TCoverageConfiguration.Create(const AParameterProvider: IParameterProvider);
begin
  inherited Create;

  FLogManager := nil;

  FParameterProvider := AParameterProvider;
  FExeParamsStrLst := TStringList.Create;

  FUnitsStrLst := TStringList.Create;
  FUnitsStrLst.CaseSensitive := False;
  FUnitsStrLst.Sorted := True;
  FUnitsStrLst.Duplicates := dupIgnore;

  FExcludedUnitsStrLst := TStringList.Create;
  FExcludedUnitsStrLst.CaseSensitive := False;
  FExcludedUnitsStrLst.Sorted := True;
  FExcludedUnitsStrLst.Duplicates := dupIgnore;

  FDProjUnitsLst := TStringList.Create;
  FDProjUnitsLst.CaseSensitive := False;
  FDProjUnitsLst.Sorted := True;
  FDProjUnitsLst.Duplicates := dupIgnore;

  FApiLogging := False;

  FStripFileExtension := True;

  FSourcePathLst := TStringList.Create;
  FEmmaOutput := False;
  FSeparateMeta := False;
  FHtmlOutput := False;
  FXmlOutput := False;
  FExcludeSourceMaskLst := TStringList.Create;
  FModuleNameSpaces := TModuleNameSpaceList.Create;
  FUnitNameSpaces := TUnitNameSpaceList.Create;
end;

destructor TCoverageConfiguration.Destroy;
begin
  FLogManager := nil;
  FUnitsStrLst.Free;
  FExcludedUnitsStrLst.Free;
  FExeParamsStrLst.Free;
  FSourcePathLst.Free;    
  FExcludeSourceMaskLst.Free;
  FModuleNameSpaces.Free;
  FUnitNameSpaces.free;
  inherited;
end;

function TCoverageConfiguration.IsComplete(var AReason: string): Boolean;
begin
  if FSourcePathLst.Count = 0 then
    FSourcePathLst.Add(''); // Default directory.

  Result := IsExecutableSet(AReason) and IsMapFileSet(AReason);
end;

function TCoverageConfiguration.IsExecutableSet(var AReason: string): Boolean;
begin
  AReason := '';

  if (FExeFileName = '') then
    AReason := 'No executable was specified'
  else if not FileExists(FExeFileName) then
    AReason := 'The executable file ' + FExeFileName + ' does not exist. Current dir is ' + GetCurrentDir;

  Result := (AReason = '');
end;

function TCoverageConfiguration.IsMapFileSet(var AReason: string): Boolean;
begin
  AReason := '';

  if (FMapFileName = '') then
    AReason := 'No map file was specified'
  else if not FileExists(FMapFileName) then
    AReason := 'The map file ' + FMapFileName + ' does not exist. Current dir is ' + GetCurrentDir;

  Result := (AReason = '');
end;

function TCoverageConfiguration.Units : TStrings;
begin
  Result := FUnitsStrLst;
end;

function TCoverageConfiguration.ExcludedUnits : TStrings;
begin
  Result := FExcludedUnitsStrLst;
end;

function TCoverageConfiguration.SourcePaths: TStrings;
begin
  Result := FSourcePathLst;
end;

function TCoverageConfiguration.ApplicationParameters: string;
var
  lp: Integer;
begin
  Result := '';
  for lp := 0 to FExeParamsStrLst.Count - 1 do
    Result := Result + FExeParamsStrLst[lp] + ' ';

  Result := Copy(Result, 1, Length(Result) - 1);
end;

function TCoverageConfiguration.DebugLogFile: string;
begin
  Result := FDebugLogFileName;
end;

function TCoverageConfiguration.MapFileName: string;
begin
  Result := FMapFileName;
end;

function TCoverageConfiguration.ExeFileName: string;
begin
  Result := FExeFileName;
end;

function TCoverageConfiguration.OutputDir: string;
begin
  Result := FOutputDir;
end;

function TCoverageConfiguration.SourceDir: string;
begin
  Result := FSourceDir;
end;

function TCoverageConfiguration.ModuleNameSpace(const AModuleName: string):TModuleNameSpace;
begin
  Result := FModuleNameSpaces[AModuleName];
end;

function TCoverageConfiguration.UnitNameSpace(const AModuleName: string):TUnitNameSpace;
begin
  Result := FUnitNameSpaces[AModuleName];
end;

procedure TCoverageConfiguration.OpenInputFileForReading(const AFileName: string; var InputFile: TextFile);
begin
  AssignFile(InputFile, AFileName);
  try
    System.FileMode := fmOpenRead;
    Reset(InputFile);
  except
    on E: EInOutError do
    begin
      ConsoleOutput('Could not open:' + AFileName);
      raise ;
    end;
  end;
end;

function TCoverageConfiguration.UseApiDebug: Boolean;
begin
  Result := FApiLogging;
end;

function TCoverageConfiguration.EmmaOutput: Boolean;
begin
  Result := FEmmaOutput;
end;

function TCoverageConfiguration.SeparateMeta;
begin
  Result := FSeparateMeta;
end;

function TCoverageConfiguration.XmlOutput: Boolean;
begin
  Result := FXmlOutput or not FHtmlOutput;
end;

function TCoverageConfiguration.HtmlOutput: Boolean;
begin
  Result := FHtmlOutput;
end;

function TCoverageConfiguration.TestExeExitCode: Boolean;
begin
  Result := FTestExeExitCode;
end;

function TCoverageConfiguration.IsPathInExclusionList(const APath: TFileName): Boolean;
var
  Mask: string;
begin
  Result := False;
  for Mask in FExcludeSourceMaskLst do
  begin
    if MatchesMask(APath, Mask) then
      Exit(True);
  end;
end;

procedure TCoverageConfiguration.ParseBooleanSwitches;
  function CleanSwitch(const Switch: string): string;
  begin
    Result := Switch;
    if StartsStr('-', Result) then
      Delete(Result, 1, 1);
  end;

  function IsSet(const Switch: string): Boolean;
  begin
    Result := FindCmdLineSwitch(CleanSwitch(Switch), ['-'], true);
  end;
begin
  FEmmaOutput := IsSet(I_CoverageConfiguration.cPARAMETER_EMMA_OUTPUT);
  FSeparateMeta := IsSet(I_CoverageConfiguration.cPARAMETER_EMMA_SEPARATE_META);
  FXmlOutput := IsSet(I_CoverageConfiguration.cPARAMETER_XML_OUTPUT);
  FHtmlOutput := IsSet(I_CoverageConfiguration.cPARAMETER_HTML_OUTPUT);
  uConsoleOutput.G_Verbose_Output := IsSet(I_CoverageConfiguration.cPARAMETER_VERBOSE);
  FTestExeExitCode := IsSet(I_CoverageConfiguration.cPARAMETER_TESTEXE_EXIT_CODE);
end;

procedure TCoverageConfiguration.ExcludeSourcePaths;
var
  I: Integer;
begin
  I := 0;
  while I < FUnitsStrLst.Count do
  begin
    if IsPathInExclusionList(FUnitsStrLst[I]) then
    begin
      VerboseOutput('Skipping Unit ' + FUnitsStrLst[I] + ' from tracking because source path is excluded.');
      FUnitsStrLst.Delete(I);
    end
    else
      Inc(I);
  end;

  I := 0;
  while I < FDprojUnitsLst.Count do
  begin
    if IsPathInExclusionList(FDprojUnitsLst[I]) then
    begin
      VerboseOutput('Skipping Unit ' + FDprojUnitsLst[I] + ' from tracking because source path is excluded.');
      FDprojUnitsLst.Delete(I);
    end
    else
      Inc(I);
  end;

  I := 0;
  while I < FExcludedUnitsStrLst.Count do
  begin
    if IsPathInExclusionList(FExcludedUnitsStrLst[I]) then
      FExcludedUnitsStrLst.Delete(I)
    else
      Inc(I);
  end;

  I := 0;
  while I < FSourcePathLst.Count do
  begin
    if IsPathInExclusionList(FSourcePathLst[I]) then
      FSourcePathLst.Delete(I)
    else
      Inc(I);
  end;
end;

procedure TCoverageConfiguration.RemovePathsFromUnits;
var
  NewUnitsList: TStrings;
  CurrentUnit: string;
begin
  NewUnitsList := TStringList.Create;
  try
    for CurrentUnit in FUnitsStrLst do
      NewUnitsList.Add(CurrentUnit);

    for CurrentUnit in FDProjUnitsLst do
      NewUnitsList.Add(ChangeFileExt(ExtractFileName(CurrentUnit), ''));

    FUnitsStrLst.Clear;
    for CurrentUnit in NewUnitsList do
    begin
      if FExcludedUnitsStrLst.IndexOf(CurrentUnit) < 0 then
        FUnitsStrLst.Add(CurrentUnit);
    end;
  finally
    NewUnitsList.Free;
  end;
end;

procedure TCoverageConfiguration.ParseCommandLine(const ALogManager: ILogManager = nil);
var
  ParameterIdx: Integer;
begin
  FLogManager := ALogManager;

  // parse boolean switches first, so we don't have to care about the order here
  ParseBooleanSwitches;

  ParameterIdx := 1;
  while ParameterIdx <= FParameterProvider.Count do
  begin
    ParseSwitch(ParameterIdx);
    Inc(ParameterIdx);
  end;

  // exclude not matching source paths
  ExcludeSourcePaths;
  RemovePathsFromUnits;
  LogTracking;
end;

procedure TCoverageConfiguration.LogTracking;
var
  CurrentUnit: string;
begin
  for CurrentUnit in FUnitsStrLst do
    VerboseOutput('Will track coverage for:' + CurrentUnit);

  for CurrentUnit in FExcludedUnitsStrLst do
    VerboseOutput('Exclude from coverage tracking for:' + CurrentUnit);
end;

function TCoverageConfiguration.ParseParameter(const AParameter: Integer): string;
var
  Param: string;
begin
  Result := '';

  if AParameter <= FParameterProvider.Count then
  begin
    Param := FParameterProvider.ParamString(AParameter);

    if (LeftStr(Param, 1) <> '-') then
      Result := ExpandEnvString(Unescape(Param));
  end;
end;

function TCoverageConfiguration.ExpandEnvString(const APath: string): string;
var
  Size: Cardinal;
begin
  Result := APath;
  Size := ExpandEnvironmentStrings(PChar(APath), nil, 0);
  if Size > 0 then
  begin
    SetLength(Result, Size - 1);
    ExpandEnvironmentStrings(PChar(APath), PChar(Result), Size);
  end;
end;

procedure TCoverageConfiguration.ParseSwitch(var AParameter: Integer);
var
  SwitchItem: string;
begin
  SwitchItem := FParameterProvider.ParamString(AParameter);
  if SwitchItem = I_CoverageConfiguration.cPARAMETER_EXECUTABLE then
    ParseExecutableSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_MAP_FILE then
    ParseMapFileSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_UNIT then
    ParseUnitSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_UNIT_FILE then
    ParseUnitFileSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER then
    ParseExecutableParametersSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_SOURCE_DIRECTORY then
    ParseSourceDirectorySwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS then
    ParseSourcePathsSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE then
    ParseSourcePathsFileSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_OUTPUT_DIRECTORY then
    ParseOutputDirectorySwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_LOGGING_TEXT then
    ParseLoggingTextSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_LOGGING_WINAPI then
    ParseWinApiLoggingSwitch(AParameter)
  else if (SwitchItem = I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE) then
    FStripFileExtension := True
  else if (SwitchItem = I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE) then
    FStripFileExtension := False
  else if (SwitchItem = I_CoverageConfiguration.cPARAMETER_EMMA_OUTPUT)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_EMMA_SEPARATE_META)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_XML_OUTPUT)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_HTML_OUTPUT)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_VERBOSE)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_TESTEXE_EXIT_CODE) then
  begin
    // do nothing, because its already parsed
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_DPROJ then
    ParseDprojSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_EXCLUDE_SOURCE_MASK then
    ParseExcludeSourceMaskSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_MODULE_NAMESPACE then
    ParseModuleNameSpaceSwitch(AParameter)
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_UNIT_NAMESPACE then
    ParseUnitNameSpaceSwitch(AParameter)
  else
    raise EConfigurationException.Create('Unexpected switch:' + SwitchItem);
end;

procedure TCoverageConfiguration.ParseExecutableSwitch(var AParameter: Integer);
begin
  Inc(AParameter);
  FExeFileName := ParseParameter(AParameter);
  if FExeFileName = '' then
    raise EConfigurationException.Create('Expected parameter for executable');
  // Now if we haven't yet set the mapfile, we set it by default to be the executable name +.map
  if FMapFileName = '' then
    FMapFileName := ChangeFileExt(FExeFileName, '.map');
end;

procedure TCoverageConfiguration.ParseMapFileSwitch(var AParameter: Integer);
begin
  Inc(AParameter);
  try
    FMapFileName := ParseParameter(AParameter);
    if FMapFileName = '' then
      raise EConfigurationException.Create('Expected parameter for mapfile');
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected parameter for mapfile');
  end;
end;

procedure TCoverageConfiguration.ParseUnitSwitch(var AParameter: Integer);
var
  UnitString: string;
begin
  Inc(AParameter);
  try
    UnitString := ParseParameter(AParameter);
    while UnitString <> '' do
    begin
      if FStripFileExtension then
        UnitString := PathRemoveExtension(UnitString); // Ensures that we strip out .pas if it was added for some reason
      AddUnitString(UnitString);

      Inc(AParameter);
      UnitString := ParseParameter(AParameter);
    end;

    if FUnitsStrLst.Count = 0 then
      raise EConfigurationException.Create('Expected at least one unit');

    Dec(AParameter);
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected at least one unit');
  end;
end;

procedure TCoverageConfiguration.AddUnitString(AUnitString: string);
begin
  if Length(AUnitString) > 0 then
  begin
    if AUnitString[1] = cIGNORE_UNIT_PREFIX then
    begin
      Delete(AUnitString, 1, 1);
      if Length(AUnitString) > 0 then
        FExcludedUnitsStrLst.Add(AUnitString);
    end
    else
      FUnitsStrLst.add(AUnitString);
  end;
end;

procedure TCoverageConfiguration.ParseUnitFileSwitch(var AParameter: Integer);
var
  UnitsFileName: string;
begin
  Inc(AParameter);
  try
    UnitsFileName := ParseParameter(AParameter);

    if UnitsFileName <> '' then
      ReadUnitsFile(UnitsFileName)
    else
      raise EConfigurationException.Create('Expected parameter for units file name');
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected parameter for units file name');
  end;
end;

procedure TCoverageConfiguration.ReadUnitsFile(const AUnitsFileName: string);
var
  InputFile: TextFile;
  UnitLine: string;
begin
  VerboseOutput('Reading units from the following file: ' + AUnitsFileName);

  OpenInputFileForReading(AUnitsFileName, InputFile);
  try
    while not Eof(InputFile) do
    begin
      ReadLn(InputFile, UnitLine);
      // Ensures that we strip out .pas if it was added for some reason
      if FStripFileExtension then
        UnitLine := PathExtractFileNameNoExt(UnitLine);

      AddUnitString(UnitLine);
    end;
  finally
    CloseFile(InputFile);
  end;
end;

procedure TCoverageConfiguration.ParseExecutableParametersSwitch(var AParameter: Integer);
var
  ExecutableParam: string;
begin
  Inc(AParameter);
  try
    ExecutableParam := ParseParameter(AParameter);

    while ExecutableParam <> '' do
    begin
      FExeParamsStrLst.add(ExecutableParam);
      Inc(AParameter);
      ExecutableParam := ParseParameter(AParameter);
    end;

    if FExeParamsStrLst.Count = 0 then
      raise EConfigurationException.Create('Expected at least one executable parameter');

    Dec(AParameter);
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected at least one executable parameter');
  end;
end;

procedure TCoverageConfiguration.ParseSourceDirectorySwitch(var AParameter: Integer);
begin
  Inc(AParameter);
  try
    FSourceDir := ParseParameter(AParameter);
    if FSourceDir = '' then
      raise EConfigurationException.Create('Expected parameter for source directory');

    // Source Directory should be checked first.
    FSourcePathLst.Insert(0, ExpandEnvString(FSourceDir));
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected parameter for source directory');
  end;
end;

procedure TCoverageConfiguration.ParseSourcePathsSwitch(var AParameter: Integer);
var
  SourcePathString: string;
begin
  Inc(AParameter);
  try
    SourcePathString := ParseParameter(AParameter);

    while SourcePathString <> '' do
    begin
      SourcePathString := MakePathAbsolute(SourcePathString, GetCurrentDir);

      if DirectoryExists(SourcePathString) then
        FSourcePathLst.Add(SourcePathString);

      Inc(AParameter);
      SourcePathString := ParseParameter(AParameter);
    end;

    if FSourcePathLst.Count = 0 then
      raise EConfigurationException.Create('Expected at least one source path');

    Dec(AParameter);
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected at least one source path');
  end;
end;

procedure TCoverageConfiguration.ParseSourcePathsFileSwitch(var AParameter: Integer);
var
  SourcePathFileName: string;
begin
  Inc(AParameter);
  try
    SourcePathFileName := ParseParameter(AParameter);

    if SourcePathFileName <> '' then
      ReadSourcePathFile(SourcePathFileName)
    else
      raise EConfigurationException.Create('Expected parameter for source path file name');
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected parameter for source path file name');
  end;
end;

procedure TCoverageConfiguration.ReadSourcePathFile(const ASourceFileName: string);
var
  InputFile: TextFile;
  SourcePathLine: string;
begin
  OpenInputFileForReading(ASourceFileName, InputFile);
  try
    while (not Eof(InputFile)) do
    begin
      ReadLn(InputFile, SourcePathLine);

      SourcePathLine := MakePathAbsolute(SourcePathLine, ASourceFileName);

      if DirectoryExists(SourcePathLine) then
        FSourcePathLst.Add(SourcePathLine);
    end;
  finally
    CloseFile(InputFile);
  end;
end;

function TCoverageConfiguration.MakePathAbsolute(const APath, ASourceFileName: string): string;
var
  RootPath: string;
begin
  Result := ExpandEnvString(APath);
  if TPath.IsRelativePath(Result) then
  begin
    RootPath := TPath.GetDirectoryName(TPath.GetFullPath(ASourceFileName));
    Result := TPath.GetFullPath(TPath.Combine(RootPath, Result));
  end;
end;

procedure TCoverageConfiguration.ParseOutputDirectorySwitch(var AParameter: Integer);
begin
  Inc(AParameter);
  try
    FOutputDir := ParseParameter(AParameter);
    if FOutputDir = '' then
      raise EConfigurationException.Create('Expected parameter for output directory');
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected parameter for output directory')
  end;
end;

procedure TCoverageConfiguration.ParseLoggingTextSwitch(var AParameter: Integer);
begin
  inc(AParameter);
  try
    FDebugLogFileName := ParseParameter(AParameter);

    if FDebugLogFileName = '' then
    begin
      FDebugLogFileName := I_CoverageConfiguration.cDEFULT_DEBUG_LOG_FILENAME;
      Dec(AParameter);
    end;

    if Assigned(FLogManager) and (FDebugLogFileName <> '') then
      FLogManager.AddLogger(TLoggerTextFile.Create(FDebugLogFileName));
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected parameter for debug log file');
  end;
end;

procedure TCoverageConfiguration.ParseWinApiLoggingSwitch(var AParameter: Integer);
begin
  Inc(AParameter);
  FApiLogging := True;
  if Assigned(FLogManager) then
    FLogManager.AddLogger(TLoggerAPI.Create);
end;

procedure TCoverageConfiguration.ParseDprojSwitch(var AParameter: Integer);
var
  DProjPath: TFileName;
begin
  Inc(AParameter);
  try
    DProjPath := ParseParameter(AParameter);
    ParseDProj(DProjPath);
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected parameter for project file');
  end;
end;

function TCoverageConfiguration.GetCurrentConfig(const Project: IXMLNode): string;
var
  Node: IXMLNode;
  CurrentConfigNode: IXMLNode;
begin
  Assert(Assigned(Project));
  Result := '';
  Node := Project.ChildNodes.Get(0);
  if (Node.LocalName = 'PropertyGroup') then
  begin
    CurrentConfigNode := Node.ChildNodes.FindNode('Config');
    if CurrentConfigNode <> nil then
      Result := CurrentConfigNode.Text;
  end;
end;

function TCoverageConfiguration.GetExeOutputFromDProj(const Project: IXMLNode; const ProjectName: TFileName): string;
var
  CurrentConfig: string;
  CurrentPlatform: string;
  DCC_ExeOutputNode: IXMLNode;
  DCC_ExeOutput: string;
  GroupIndex: Integer;
  Node: IXMLNode;
begin
  Result := '';
  Assert(Assigned(Project));
  CurrentConfig := GetCurrentConfig(Project);

  {$IFDEF WIN64}
  CurrentPlatform := 'Win64';
  {$ELSE}
  CurrentPlatform := 'Win32';
  {$ENDIF}

  for GroupIndex := 0 to Project.ChildNodes.Count - 1 do
  begin
    Node := Project.ChildNodes.Get(GroupIndex);
    if (Node.LocalName = 'PropertyGroup')
    and Node.HasAttribute('Condition')
    and (
      (Node.Attributes['Condition'] = '''$(Base)''!=''''')
      or (Node.Attributes['Condition'] = '''$(Basis)''!=''''')
    ) then
    begin
      if CurrentConfig <> '' then
      begin
        DCC_ExeOutputNode := Node.ChildNodes.FindNode('DCC_ExeOutput');
        if DCC_ExeOutputNode <> nil then
        begin
          DCC_ExeOutput := DCC_ExeOutputNode.Text;
          DCC_ExeOutput := StringReplace(DCC_ExeOutput, '$(Platform)', CurrentPlatform, [rfReplaceAll, rfIgnoreCase]);
          DCC_ExeOutput := StringReplace(DCC_ExeOutput, '$(Config)', CurrentConfig, [rfReplaceAll, rfIgnoreCase]);
          Result := IncludeTrailingPathDelimiter(DCC_ExeOutput) + ChangeFileExt(ProjectName, '.exe');
        end;
      end;
    end;
  end;
end;

procedure TCoverageConfiguration.ParseDProj(const DProjFilename: TFileName);
var
  Document: IXMLDocument;
  ItemGroup: IXMLNode;
  Node: IXMLNode;
  Project: IXMLNode;
  Unitname: string;
  I: Integer;
  RootPath: TFileName;
  SourcePath: TFileName;
  ExeFileName: TFileName;
begin
  RootPath := ExtractFilePath(TPath.GetFullPath(DProjFilename));
  Document := TXMLDocument.Create(nil);
  Document.LoadFromFile(DProjFilename);
  Project := Document.ChildNodes.FindNode('Project');
  if Project <> nil then
  begin
    ExeFileName := GetExeOutputFromDProj(Project, ExtractFileName(DProjFilename));
    if ExeFileName <> '' then
    begin
      if FExeFileName = '' then
        FExeFileName := TPath.GetFullPath(TPath.Combine(RootPath, ExeFileName));
      if FMapFileName = '' then
        FMapFileName := ChangeFileExt(FExeFileName, '.map');
    end;

    ItemGroup := Project.ChildNodes.FindNode('ItemGroup');
    if ItemGroup <> nil then
    begin
      FLoadingFromDProj := True;
      for I := 0 to ItemGroup.ChildNodes.Count - 1 do
      begin
        Node := ItemGroup.ChildNodes.Get(I);
        if Node.LocalName = 'DCCReference' then
        begin
          Unitname := TPath.GetFullPath(TPath.Combine(RootPath, Node.Attributes['Include']));
          SourcePath := TPath.GetDirectoryName(Unitname);
          if FSourcePathLst.IndexOf(SourcePath) = -1 then
            FSourcePathLst.Add(SourcePath);

          if FDProjUnitsLst.IndexOf(UnitName) = -1 then
            FDProjUnitsLst.Add(UnitName);
        end;
      end;
    end;
  end;
end;

procedure TCoverageConfiguration.ParseExcludeSourceMaskSwitch(var AParameter: Integer);
var
  SourcePathString: string;
begin
  Inc(AParameter);
  try
    SourcePathString := ParseParameter(AParameter);
    while SourcePathString <> '' do
    begin
      FExcludeSourceMaskLst.Add(SourcePathString);
      Inc(AParameter);
      SourcePathString := ParseParameter(AParameter);
    end;

    if FExcludeSourceMaskLst.Count = 0 then
      raise EConfigurationException.Create('Expected at least one exclude source mask');

    Dec(AParameter);
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected at least one exclude source mask');
  end;
end;

procedure TCoverageConfiguration.ParseModuleNameSpaceSwitch(var AParameter: Integer);
var
  ModuleNameSpace: TModuleNameSpace;
  ModuleName: string;
begin
  Inc(AParameter);
  try
    ModuleName := ParseParameter(AParameter);
    ModuleNameSpace := TModuleNameSpace.Create(ModuleName);

    Inc(AParameter);
    ModuleName := ParseParameter(AParameter);
    while ModuleName <> '' do
    begin
      ModuleNameSpace.AddModule(ModuleName);
      Inc(AParameter);
      ModuleName := ParseParameter(AParameter);
    end;

    if ModuleNameSpace.Count = 0 then
    begin
      ModuleNameSpace.Free;
      raise EConfigurationException.Create('Expected at least one module');
    end;

    FModuleNameSpaces.Add(ModuleNameSpace);
    Dec(AParameter);
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected at least one module');
  end;
end;

procedure TCoverageConfiguration.ParseUnitNameSpaceSwitch(var AParameter: Integer);
var
  UnitNameSpace: TUnitNameSpace;
  ModuleName: string;
begin
  Inc(AParameter);
  try
    ModuleName := ParseParameter(AParameter);
    UnitNameSpace := TUnitNameSpace.Create(ModuleName);

    Inc(AParameter);
    ModuleName := ParseParameter(AParameter);
    while ModuleName <> '' do
    begin
      UnitNameSpace.AddUnit(ModuleName);
      Inc(AParameter);
      ModuleName := ParseParameter(AParameter);
    end;

    if UnitNameSpace.Count = 0 then
    begin
      UnitNameSpace.Free;
      raise EConfigurationException.Create('Expected at least one module');
    end;

    FUnitNameSpaces.Add(UnitNameSpace);
    Dec(AParameter);
  except
    on EParameterIndexException do
      raise EConfigurationException.Create('Expected at least one module');
  end;
end;

end.

