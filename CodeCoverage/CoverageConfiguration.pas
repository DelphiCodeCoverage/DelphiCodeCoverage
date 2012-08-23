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
  I_ParameterProvider,
  I_LogManager,
  ModuleNameSpaceUnit,
  uConsoleOutput;

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
    FExcludedUnitsStrLst     : TStringList;
    FExeParamsStrLst         : TStrings;
    FSourcePathLst           : TStrings;
    FStripFileExtension      : Boolean;
    FEmmaOutput              : Boolean;
    FXmlOutput               : Boolean;
    FHtmlOutput              : Boolean;
    FExcludeSourceMaskLst    : TStrings;
    FLoadingFromDProj        : Boolean;
    FModuleNameSpaces        : TModuleNameSpaceList;
    FUnitNameSpaces          : TUnitNameSpaceList;
    FLogManager              : ILogManager;

    procedure ReadUnitsFile(const AUnitsFileName : string);
    procedure ReadSourcePathFile(const ASourceFileName : string);
    function parseParam(const AParameter: Integer): string;
    procedure parseSwitch(var AParameter: Integer);
    procedure parseBooleanSwitches;
    procedure ParseDProj(const DProjFilename: TFileName);
    function IsPathInExclusionList(const APath: TFileName): boolean;
    procedure ExcludeSourcePaths;
    procedure RemovePathsFromUnits;
    function ExpandEnvString(const APath: string): string;
    procedure LogTracking;
  public
    constructor Create(const AParameterProvider: IParameterProvider);
    destructor Destroy; override;

    procedure ParseCommandLine(const ALogManager: ILogManager = nil);

    function GetApplicationParameters         : string;
    function GetExeFileName                   : string;
    function GetMapFileName                   : string;
    function GetOutputDir                     : string;
    function GetSourceDir                     : string;
    function GetDebugLogFile                  : string;
    function GetSourcePaths                   : TStrings;
    function GetUnits                         : TStrings;
    function GetExcludedUnits                 : TStrings;
    function UseApiDebug                      : boolean;
    function IsComplete(var AReason : string) : Boolean;
    function EmmaOutput                       : Boolean;
    function XmlOutput                        : Boolean;
    function HtmlOutput                       : Boolean;

    function GetModuleNameSpace(const modulename : String):TModuleNameSpace;
    function GetUnitNameSpace(const modulename : String) : TUnitNameSpace;
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
  XMLIntf,
  XMLDoc,
  Windows,
  Masks;

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

constructor TCoverageConfiguration.Create(const AParameterProvider: IParameterProvider);
begin
  inherited Create;

  FLogManager := nil;

  FParameterProvider         := AParameterProvider;
  FExeParamsStrLst           := TStringList.Create;

  FUnitsStrLst               := TStringList.Create;
  FUnitsStrLst.CaseSensitive := False;
  FUnitsStrLst.Sorted        := True;
  FUnitsStrLst.Duplicates    := dupIgnore;

  FExcludedUnitsStrLst := TStringList.Create;
  FExcludedUnitsStrLst.CaseSensitive := False;
  FExcludedUnitsStrLst.Sorted := True;
  FExcludedUnitsStrLst.Duplicates := dupIgnore;

  FApiLogging                := False;

  FStripFileExtension        := True;

  FSourcePathLst             := TStringList.Create;
  FEmmaOutput                := False;
  FHtmlOutput                := False;
  FXmlOutput                 := False;
  FExcludeSourceMaskLst      := TStringList.Create;
  FModuleNameSpaces          := TModuleNameSpaceList.Create;
  FUnitNameSpaces            := TUnitNameSpaceList.Create;
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

function TCoverageConfiguration.IsComplete(var AReason : string) : boolean;
begin
  if FSourcePathLst.Count = 0 then
    FSourcePathLst.Add(''); // Default directory.

  Result := True;

  if (FExeFileName = '') then
  begin
    // Executable not specified.
    AReason := 'No executable was specified';
    Exit(False);
  end
  else if not FileExists(FExeFileName) then
  begin
    // Executable does not exists.
    AReason := 'The executable file ' + FExeFileName + ' does not exist. Current dir is ' + GetCurrentDir();
    Exit(False);
  end;

  if (FMapFileName = '') then
  begin
    // Map File not specified.
    AReason := 'No map file was specified';
    Exit(False);
  end
  else if not FileExists(FMapFileName) then
  begin
    // Map File does not exists.
    AReason := 'The map file ' + FMapFileName + ' does not exist. Current dir is ' + GetCurrentDir();
    Exit(False);
  end;
end;

function TCoverageConfiguration.GetUnits : TStrings;
begin
  Result := FUnitsStrLst;
end;

function TCoverageConfiguration.GetExcludedUnits : TStrings;
begin
  Result := FExcludedUnitsStrLst;
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

function TCoverageConfiguration.GetModuleNameSpace(const modulename : String):TModuleNameSpace;
begin
  result := fModuleNameSpaces[modulename];
end;

function TCoverageConfiguration.GetUnitNameSpace(const modulename : String):TUnitNameSpace;
begin
  result := fUnitNameSpaces[modulename];
end;

procedure TCoverageConfiguration.ReadUnitsFile(const AUnitsFileName: string);
var
  InputFile: TextFile;
  UnitLine: string;
begin
  VerboseOutput('Reading units from the following file:' + AUnitsFileName);
  AssignFile(InputFile, AUnitsFileName);
  try
    System.FileMode := fmOpenRead;
    Reset(InputFile);
  except
    on E: EInOutError do
    begin
      ConsoleOutput('Could not open:' + AUnitsFileName);
      raise;
    end;
  end;

  try
    while (not Eof(InputFile)) do
    begin
      ReadLn(InputFile, UnitLine);
      if FStripFileExtension then
        UnitLine := PathExtractFileNameNoExt(UnitLine);

      if UnitLine[1] = '!' then
      begin
        Delete(UnitLine, 1, 1);
        FExcludedUnitsStrLst.Add(UnitLine);
      end
      else
        FUnitsStrLst.Add(UnitLine);
    end;
  finally
    CloseFile(InputFile);
  end;
end;

procedure TCoverageConfiguration.ReadSourcePathFile(
  const ASourceFileName: string);
var
  InputFile: TextFile;
  SourcePathLine: string;
  RootPath: string;
begin
  AssignFile(InputFile, ASourceFileName);
  try
    System.FileMode := fmOpenRead;
    Reset(InputFile);
  except
    on E: EInOutError do
    begin
      ConsoleOutput('Could not open:' + ASourceFileName);
      raise;
    end;
  end;

  try
    while (not Eof(InputFile)) do
    begin
      ReadLn(InputFile, SourcePathLine);

      SourcePathLine := ExpandEnvString(SourcePathLine);
      if TPath.IsRelativePath(SourcePathLine) then
      begin
        RootPath := TPath.GetDirectoryName(TPath.GetFullPath(ASourceFileName));
        SourcePathLine := TPath.GetFullPath(TPath.Combine(RootPath, SourcePathLine));
      end;

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

function TCoverageConfiguration.EmmaOutput;
begin
  result := FEmmaOutput;
end;

function TCoverageConfiguration.XmlOutput;
begin
  result := FXmlOutput;
  if (not FHtmlOutput) then
    result := True;
end;

function TCoverageConfiguration.HtmlOutput;
begin
  result := FHtmlOutput;
end;

function TCoverageConfiguration.IsPathInExclusionList(const APath: TFileName): boolean;
var
  Mask: string;
begin
  Result := False;
  for Mask in FExcludeSourceMaskLst do
    if MatchesMask(APath, Mask) then
    begin
      Result := True;
      break;
    end;
end;

procedure TCoverageConfiguration.parseBooleanSwitches;
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
  FXmlOutput := IsSet(I_CoverageConfiguration.cPARAMETER_XML_OUTPUT);
  FHtmlOutput := IsSet(I_CoverageConfiguration.cPARAMETER_HTML_OUTPUT);
  uConsoleOutput.G_Verbose_Output := IsSet(I_CoverageConfiguration.cPARAMETER_VERBOSE);
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
  I: Integer;
  NewUnitsList: TStrings;
begin
  NewUnitsList := TStringList.Create;
  try
    for I := 0 to FUnitsStrLst.Count - 1 do
    begin
      if FLoadingFromDProj then
        NewUnitsList.Add(ChangeFileExt(ExtractFileName(FUnitsStrLst[I]), ''))
      else
        NewUnitsList.Add(FUnitsStrLst[I]);
    end;

    FUnitsStrLst.Clear;
    for I := 0 to NewUnitsList.Count - 1 do
    begin
      if FExcludedUnitsStrLst.IndexOf(NewUnitsList[I]) < 0 then
        FUnitsStrLst.Add(NewUnitsList[I]);
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
  parseBooleanSwitches;

  ParameterIdx := 1;
  while ParameterIdx <= FParameterProvider.Count do
  begin
    parseSwitch(ParameterIdx);
    inc(ParameterIdx);
  end;

  // exclude not matching source paths
  ExcludeSourcePaths;
  RemovePathsFromUnits;
  LogTracking;
end;

procedure TCoverageConfiguration.LogTracking;
var
  currentUnit: string;
begin
  for currentUnit in FUnitsStrLst do
    VerboseOutput('Will track coverage for:' + currentUnit);

  for currentUnit in FExcludedUnitsStrLst do
    VerboseOutput('Exclude from coverage tracking for:' + currentUnit);
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
      Result := ExpandEnvString(Unescape(param));
  end;
end;

procedure TCoverageConfiguration.ParseDProj(const DProjFilename: TFileName);
var
  Document: IXMLDocument;
  ItemGroup: IXMLNode;
  Node: IXMLNode;
  Project: IXMLNode;
  Unitname: string;
  GroupIndex: Integer;
  I: Integer;
  RootPath: TFileName;
  SourcePath: TFileName;
  DCC_DependencyCheckOutputName: IXMLNode;
begin
  RootPath := ExtractFilePath(TPath.GetFullPath(DProjFilename));
  Document := TXMLDocument.Create(nil);
  Document.LoadFromFile(DProjFilename);
  Project := Document.ChildNodes.FindNode('Project');
  if Project <> nil then
  begin
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
        DCC_DependencyCheckOutputName := Node.ChildNodes.FindNode('DCC_DependencyCheckOutputName');
        if DCC_DependencyCheckOutputName <> nil then
        begin
          FExeFileName := TPath.GetFullPath(TPath.Combine(RootPath, DCC_DependencyCheckOutputName.Text));
          FMapFileName := ChangeFileExt(FExeFileName, '.map');
        end;
      end;
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

          if FExcludedUnitsStrLst.IndexOf(Unitname) < 0 then
            FUnitsStrLst.Add(UnitName);
        end;
      end;
    end;
  end;
end;

function TCoverageConfiguration.ExpandEnvString(const APath: string): string;
var
  size: Cardinal;
begin
  Result := APath;
  size := ExpandEnvironmentStrings(PChar(APath), nil, 0);
  if size > 0 then
  begin
    SetLength(Result, size - 1);
    ExpandEnvironmentStrings(PChar(APath), PChar(Result), size);
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
  DProjPath          : TFileName;
  modulename         : string;
  modulenamespace    : TModuleNameSpace;
  unitnamespace      : TUnitNameSpace;
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
        if FStripFileExtension then
          UnitString := PathRemoveExtension(UnitString); // Ensures that we strip out .pas if it was added for some reason
        if UnitString[1] = '!' then
        begin
          Delete(UnitString, 1, 1);
          FExcludedUnitsStrLst.add(UnitString)
        end
        else
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
    FSourcePathLst.Insert(0, ExpandEnvString(FSourceDir));
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS then
  begin
    inc(AParameter);
    try
      SourcePathString := parseParam(AParameter);
      while SourcePathString <> '' do
      begin
        SourcePathString := PathRemoveExtension(ExpandEnvString(SourcePathString));

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
      raise EConfigurationException.Create('Expected parameter for output directory')
    else
      ForceDirectories(FOutputDir);
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_LOGGING_TEXT then
  begin
    inc(AParameter);
    try
      FDebugLogFileName := parseParam(AParameter);
      if FDebugLogFileName = '' then
      begin
        FDebugLogFileName := I_CoverageConfiguration.cDEFULT_DEBUG_LOG_FILENAME;
        Dec(AParameter); // If default, don't count the name
      end;

      if Assigned(FLogManager) and (FDebugLogFileName <> '') then
      begin
        FLogManager.AddLogger(
          'Textual',
          TLoggerTextFile.Create(FDebugLogFileName)
        );
      end;
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for debug log file');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_LOGGING_WINAPI then
  begin
    inc(AParameter);
    FApiLogging := True;
    if Assigned(FLogManager) then
      FLogManager.AddLogger('WinAPI', TLoggerAPI.Create());
  end
  else if (SwitchItem = I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE) then
    FStripFileExtension := True
  else if (SwitchItem = I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE) then
    FStripFileExtension := False
  else if (SwitchItem = I_CoverageConfiguration.cPARAMETER_EMMA_OUTPUT)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_XML_OUTPUT)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_HTML_OUTPUT)
  or (SwitchItem = I_CoverageConfiguration.cPARAMETER_VERBOSE) then
  begin
    // do nothing, because its already parsed
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_DPROJ then
  begin
    inc(AParameter);
    try
      DProjPath := parseParam(AParameter);
      ParseDProj(DProjPath);
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for project file');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_EXCLUDE_SOURCE_MASK then
  begin
    inc(AParameter);
    try
      SourcePathString := parseParam(AParameter);
      while SourcePathString <> '' do
      begin
        FExcludeSourceMaskLst.Add(SourcePathString);
        inc(AParameter);
        SourcePathString := parseParam(AParameter);
      end;
      if FExcludeSourceMaskLst.Count = 0 then
        raise EConfigurationException.Create('Expected at least one exclude source mask');
      dec(AParameter);
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected at least one exclude source mask');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_MODULE_NAMESPACE then
  begin
    inc(AParameter);
    try
      modulename := parseParam(AParameter);
      modulenamespace := TModuleNameSpace.Create(modulename);
      inc(AParameter);
      modulename := parseParam(AParameter);
      while modulename <> '' do
      begin
        modulenamespace.AddModule(modulename);
        inc(AParameter);
        modulename := parseParam(AParameter);
      end;
      if modulenamespace.Count = 0 then
        raise EConfigurationException.Create('Expected at least one module');
      FModuleNameSpaces.Add(modulenamespace);
      dec(AParameter);
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected at least one module');
    end;
  end
  else if SwitchItem = I_CoverageConfiguration.cPARAMETER_UNIT_NAMESPACE then
  begin
    inc(AParameter);
    try
      modulename := parseParam(AParameter);
      unitnamespace := TUnitNameSpace.Create(modulename);
      inc(AParameter);
      modulename := parseParam(AParameter);
      while modulename <> '' do
      begin
        unitnamespace.AddUnit(modulename);
        inc(AParameter);
        modulename := parseParam(AParameter);
      end;
      if unitnamespace.Count = 0 then
        raise EConfigurationException.Create('Expected at least one module');
      FUnitNameSpaces.Add(unitnamespace);
      dec(AParameter);
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected at least one module');
    end;
  end
  else
  begin
    raise EConfigurationException.Create('Unexpected switch:' + SwitchItem);
  end;
end;

end.

