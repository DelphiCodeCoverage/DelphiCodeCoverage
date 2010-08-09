(* ************************************************************ *)
(* Delphi Code Coverage                                         *)
(*                                                              *)
(* A quick hack of a Code Coverage Tool for Delphi 2010         *)
(* by Christer Fahlgren                                         *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1                    *)
(* ************************************************************ *)

unit Configuration;

interface

uses classes, sysutils;

type
  EParameterIndexException = class(Exception);

    TParameterProvider = class public function Count: Integer;
    virtual;
    abstract;
    function ParamString(index: Integer): string; virtual; abstract;
  end;

  TCommandLineProvider = class(TParameterProvider)
    function Count: Integer; override;
    function ParamString(index: Integer): string; override;
  end;

  TCoverageConfiguration = class
  private
    parameterProvider: TParameterProvider;
    executable: string;
    mapfile: string;
    units: TStringList;
    sourcedir: string;
    outputdir: string;
    executableParams: TStringList;
    function parseParam(var paramiter: Integer): string;
    function parseSwitch(var paramiter: Integer): string;
  public
    constructor Create(parameterProvider: TParameterProvider);
    destructor Destroy; override;
    procedure ParseCommandLine();
    function isComplete: boolean;
    function getUnits: TStringList;
    function getApplicationParameters: string;
    function getMapFile: string;
    function getExecutable: string;
    function getOutputDir: string;
    function getSourceDir: string;
  end;

  EConfigurationException = class(Exception);

implementation

uses strutils, JclFileUtils;

function Unescape(const param: string): string;
var
  I: Integer;
begin
  result := '';
  if length(param) > 0 then
  begin
    I := 1;
    while I <= length(param) do
    begin
      if param[I] = '^' then
        inc(I);
      result := result + param[I];
      inc(I);
    end;
  end;
end;

function TCommandLineProvider.Count: Integer;
begin
  result := ParamCount;
end;

function TCommandLineProvider.ParamString(index: Integer): string;
begin
  if index > Count then
    raise EParameterIndexException.Create('Parameter Index:' + IntToStr(index) + ' out of bounds.');
  result := ParamStr(index);
end;

constructor TCoverageConfiguration.Create(parameterProvider: TParameterProvider);
begin
  self.parameterProvider := parameterProvider;
  units := TStringList.Create;
  executableParams := TStringList.Create;
end;

destructor TCoverageConfiguration.Destroy;
begin
  units.free;
  executableParams.free;
end;

function TCoverageConfiguration.isComplete;
begin
  result := executable <> '';
end;

function TCoverageConfiguration.getUnits;
begin
  result := units;
end;

function TCoverageConfiguration.getApplicationParameters;
var
  I: Integer;
begin
  result := '';
  for I := 0 to executableParams.Count - 1 do
  begin
    if (I < executableParams.Count - 1) then
    begin
      //only add space if it isn't the last one
      result := result + executableParams[I] + ' ';
    end
    else
    begin
      result := result + executableParams[I];
    end;
  end;
end;

function TCoverageConfiguration.getMapFile: string;
begin
  result := mapfile;
end;

function TCoverageConfiguration.getExecutable: string;
begin
  result := executable;
end;

function TCoverageConfiguration.getOutputDir: string;
begin
  result := outputdir;
end;

function TCoverageConfiguration.getSourceDir: string;
begin
  result := sourcedir;
end;

procedure TCoverageConfiguration.ParseCommandLine();
var
  I: Integer;
  paramiter: Integer;
begin
  paramiter := 1;
  while paramiter <= parameterProvider.Count do
  begin
    parseSwitch(paramiter);
    inc(paramiter);
  end;
end;

function TCoverageConfiguration.parseParam(var paramiter: Integer): string;
var
  param: string;
begin
  if paramiter > parameterProvider.Count then
  begin
    result := '';
  end
  else
  begin
    param := parameterProvider.ParamString(paramiter);
    if (leftStr(param, 1) = '-') then
    begin
      result := '';
    end
    else
      result := Unescape(param);
  end;
end;

function TCoverageConfiguration.parseSwitch(var paramiter: Integer): string;
var
  unitstring: string;
  executableparam: string;
  switchitem: string;
begin
  switchitem := parameterProvider.ParamString(paramiter);
  if switchitem = '-e' then
  begin
    inc(paramiter);
    executable := parseParam(paramiter);
    if executable = '' then
      raise EConfigurationException.Create('Expected parameter for executable');

    // Now if we haven't yet set the mapfile, we set it by default to be the executable name +.map
    if mapfile = '' then
      mapfile := ChangeFileExt(executable, '.map');
  end
  else if switchitem = '-m' then
  begin
    inc(paramiter);
    try
      mapfile := parseParam(paramiter);
      if mapfile = '' then
        raise EConfigurationException.Create('Expected parameter for mapfile');
    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected parameter for mapfile');
    end;
  end
  else if switchitem = '-u' then
  begin
    inc(paramiter);
    try
      unitstring := parseParam(paramiter);
      while unitstring <> '' do
      begin
        unitstring := PathRemoveExtension(unitstring); // Ensures that we strip out .pas if it was added for some reason
        units.add(lowercase(unitstring));
        inc(paramiter);
        unitstring := parseParam(paramiter);
      end;
      if units.Count = 0 then
        raise EConfigurationException.Create('Expected at least one unit');
      dec(paramiter);

    except
      on EParameterIndexException do
        raise EConfigurationException.Create('Expected at least one unit');

    end;
  end
  else if switchitem = '-a' then
  begin
    inc(paramiter);
    executableparam := parseParam(paramiter);
    while executableparam <> '' do
    begin
      executableParams.add(executableparam);
      inc(paramiter);
      executableparam := parseParam(paramiter);
    end;
    if executableParams.Count = 0 then
      raise EConfigurationException.Create('Expected at least one executable parameter');
    dec(paramiter);

  end
  else if switchitem = '-sd' then
  begin
    inc(paramiter);
    sourcedir := parseParam(paramiter);
    if sourcedir = '' then
      raise EConfigurationException.Create('Expected parameter for source directory');

  end
  else if switchitem = '-od' then
  begin
    inc(paramiter);
    outputdir := parseParam(paramiter);
    if outputdir = '' then
      raise EConfigurationException.Create('Expected parameter for output directory');
  end
  else
  begin
    raise EConfigurationException.Create('Unexpected switch:' + switchitem);
  end;
end;

end.
