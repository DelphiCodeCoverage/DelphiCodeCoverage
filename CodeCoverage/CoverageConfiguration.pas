(* ************************************************************ *)
(* Delphi Code Coverage                                         *)
(*                                                              *)
(* A quick hack of a Code Coverage Tool for Delphi 2010         *)
(* by Christer Fahlgren                                         *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1                    *)
(* ************************************************************ *)

unit CoverageConfiguration;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  SysUtils,
  I_CoverageConfiguration,
  I_ParameterProvider;

type
  TCoverageConfiguration = class(TINterfacedObject, ICoverageConfiguration)
  private
    FExeFileName       : string;
    FMapFileName       : string;
    FSourceDir         : string;
    FOutputDir         : string;
    FDebugLogFileName  : string;
    FApiLogging        : Boolean;
    FParameterProvider : IParameterProvider;
    FUnitsStrLst       : TStringList;
    FExeParamsStrLst   : TStrings;

    procedure ReadUnitsFile(const AUnitsFileName : string);
    function parseParam(const AParameter: Integer): string;
    procedure parseSwitch(var AParameter: Integer);
  public
    constructor Create(const AParameterProvider: IParameterProvider);
    destructor Destroy; override;

    procedure ParseCommandLine();

    function GetApplicationParameters : string;
    function GetExeFileName           : string;
    function GetMapFileName           : string;
    function GetOutputDir             : string;
    function GetSourceDir             : string;
    function GetUnits                 : TStrings;
    function GetDebugLogFile          : string;
    function UseApiDebug              : boolean;
    function IsComplete               : Boolean;
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
      if param[lp] = I_CoverageConfiguration.ESCAPE_CHARACTER then
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

  FParameterProvider := AParameterProvider;
  FExeParamsStrLst   := TStringList.Create;

  FUnitsStrLst               := TStringList.Create;
  FUnitsStrLst.CaseSensitive := False;
  FUnitsStrLst.Sorted        := True;
  FUnitsStrLst.Duplicates    := dupIgnore;

  FApiLogging        := False;
end;

destructor TCoverageConfiguration.Destroy;
begin
  FUnitsStrLst.Free;
  FExeParamsStrLst.Free;

  inherited;
end;

function TCoverageConfiguration.IsComplete;
begin
  Result := True;

  if (FExeFileName = '') then
  begin
    // Executable not specified.
    Result := False;
  end
  else if not FileExists(FExeFileName) then
  begin
    // Executable does not exists.
    Result := False;
  end;

  if (FMapFileName = '') then
  begin
    // Map File not specified.
    Result := False;
  end
  else if not FileExists(FMapFileName) then
  begin
    // Map File does not exists.
    Result := False;
  end;
end;

function TCoverageConfiguration.GetUnits : TStrings;
begin
  Result := FUnitsStrLst;
end;

function TCoverageConfiguration.GetApplicationParameters: string;
var
  lp: Integer;
begin
  Result := '';
  for lp := 0 to FExeParamsStrLst.Count - 1 do
    //Result := Result + '"' + FExeParamsStrLst[lp] + '" ';
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
      FUnitsStrLst.Add(PathExtractFileNameNoExt(UnitLine));
    end;
  finally
    CloseFile(InputFile);
  end;
end;

function TCoverageConfiguration.UseApiDebug: boolean;
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
    if (leftStr(param, 1) = '-') then
    begin
      Result := '';
    end
    else
      Result := Unescape(param);
  end;
end;

procedure TCoverageConfiguration.parseSwitch(var AParameter: Integer);
var
  UnitString      : string;
  UnitsFileName   : string;
  ExecutableParam : string;
  SwitchItem      : string;
begin
  SwitchItem := FParameterProvider.ParamString(AParameter);
  if SwitchItem = '-e' then
  begin
    inc(AParameter);
    FExeFileName := parseParam(AParameter);
    if FExeFileName = '' then
      raise EConfigurationException.Create('Expected parameter for executable');

    // Now if we haven't yet set the mapfile, we set it by default to be the executable name +.map
    if FMapFileName = '' then
      FMapFileName := ChangeFileExt(FExeFileName, '.map');
  end
  else if SwitchItem = '-m' then
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
  else if SwitchItem = '-u' then
  begin
    inc(AParameter);
    try
      UnitString := parseParam(AParameter);
      while UnitString <> '' do
      begin
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
  else if SwitchItem = '-uf' then
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
  else if SwitchItem = '-a' then
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
  else if SwitchItem = '-sd' then
  begin
    inc(AParameter);
    FSourceDir := parseParam(AParameter);
    if FSourceDir = '' then
      raise EConfigurationException.Create('Expected parameter for source directory');
  end
  else if SwitchItem = '-od' then
  begin
    inc(AParameter);
    FOutputDir := parseParam(AParameter);
    if FOutputDir = '' then
      raise EConfigurationException.Create('Expected parameter for output directory');
  end
  else if SwitchItem = '-lt' then
  begin
    inc(AParameter);
    try
      FDebugLogFileName := parseParam(AParameter);
      if FDebugLogFileName = '' then
        FDebugLogFileName := I_CoverageConfiguration.DEFULT_DEBUG_LOG_FILENAME;
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for mapfile');
    end;
  end
  else if SwitchItem = '-lapi' then
  begin
    inc(AParameter);
    FApiLogging := True;
  end
  else
  begin
    raise EConfigurationException.Create('Unexpected switch:' + SwitchItem);
  end;
end;

end.
