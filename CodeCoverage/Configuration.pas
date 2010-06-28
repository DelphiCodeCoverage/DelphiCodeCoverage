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
  TCoverageConfiguration = class
  private
    executable: string;
    mapfile: string;
    units: TStringList;
    sourcedir: string;
    outputdir: string;
    executableParams: TStringList;
    function parseParam(var paramiter: Integer): string;
    function parseSwitch(var paramiter: Integer): string;
  public
    constructor Create;
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

uses strutils;

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
      if param[I] = '\' then
        inc(I);
      result := result + param[I];
      inc(I);
    end;
  end;
end;

constructor TCoverageConfiguration.Create;
begin
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
  if executable <> '' then
    result := true;
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
    result := result + executableParams[I] + ' ';
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
  while paramiter <= paramcount do
  begin
    parseSwitch(paramiter);
    inc(paramiter);
  end;
end;

function TCoverageConfiguration.parseParam(var paramiter: Integer): string;
var
  param: string;
begin
  if paramiter > paramcount then
  begin
    result := '';
  end
  else
  begin
    param := ParamStr(paramiter);
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
  switchitem := ParamStr(paramiter);
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
    mapfile := parseParam(paramiter);
    if mapfile = '' then
      raise EConfigurationException.Create('Expected parameter for mapfile');
  end
  else if switchitem = '-u' then
  begin
    inc(paramiter);
    unitstring := parseParam(paramiter);
    while unitstring <> '' do
    begin
      units.add(unitstring);
      inc(paramiter);
      unitstring := parseParam(paramiter);
    end;
    if units.Count = 0 then
      raise EConfigurationException.Create('Expected at least one unit');
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

  end
  else if switchitem = '-sd' then
  begin
    inc(paramiter);
    sourcedir := ParamStr(paramiter);
    if sourcedir = '' then
      raise EConfigurationException.Create('Expected parameter for source directory');

  end
  else if switchitem = '-od' then
  begin
    inc(paramiter);
    outputdir := ParamStr(paramiter);
    if outputdir = '' then
      raise EConfigurationException.Create('Expected parameter for output directory');
  end
end;

end.
