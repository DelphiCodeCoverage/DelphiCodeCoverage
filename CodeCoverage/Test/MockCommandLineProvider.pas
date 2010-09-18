(* ************************************************************ *)
(* Delphi Code Coverage                                         *)
(*                                                              *)
(* A quick hack of a Code Coverage Tool for Delphi 2010         *)
(* by Christer Fahlgren                                         *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1                    *)
(* ************************************************************ *)

unit MockCommandLineProvider;

interface

uses
  Classes,
  I_ParameterProvider;

type
  TMockCommandLineProvider = class(TInterfacedObject, IParameterProvider)
  private
    FParamsStrLst: TStringList;
  public
    constructor Create(const AStringArray : array of string);
    destructor Destroy; override;
    function Count: Integer;
    function ParamString(const AIndex: Integer): string;
  end;

const
  cInvalidParameter            : array [0 .. 0] of string = ('-frank');
  cEnableAPILogging            : array [0 .. 0] of string = ('-lapi');
  cEnableFileLogDefault        : array [0 .. 0] of string = ('-lt');
  cEnableFileLogSpecified      : array [0 .. 1] of string = ('-lt', 'some-debug-log-file.txt');
  cOutputDirError              : array [0 .. 0] of string = ('-od');
  cOutputDir                   : array [0 .. 1] of string = ('-od', 'some-output-dir');
  cSourcePathFileNameParam     : array [0 .. 0] of string = ('-spf');
  cSourcePathEmptyParam        : array [0 .. 0] of string = ('-sp');
  cSourceDirParamEmpty         : array [0 .. 0] of string = ('-sd');
  cSourceDirParam              : array [0 .. 1] of string = ('-sd', 'some_parameter');
  cExecutableParameterEmpty    : array [0 .. 0] of string = ('-a');
  cExecutableParameterSingle   : array [0 .. 1] of string = ('-a', 'some_parameter');
  cExecutableParameterMultiple : array [0 .. 2] of string = ('-a', 'some_parameter', 'another_parameter');
  cExecutableParameterEscaping : array [0 .. 1] of string = ('-a', '^^some_parameter');
  cUnitFileNameParam           : array [0 .. 0] of string = ('-uf');
  cUnitParam                   : array [0 .. 0] of string = ('-u');
  cMapFileParam                : array [0 .. 0] of string = ('-m');
  cExecutableParam             : array [0 .. 0] of string = ('-e');

  //cIncompleteParams  : array [0 .. 1] of string = ('-m', 'mapfile.map');
  //cNoMapFileParams   : array [0 .. 0] of string = ('-m');
  //cUnitParams        : array [0 .. 3] of string = ('-m', 'mapfile.map',
  //                                                 '-u', 'TestUnit.pas');
  //cApplicationParams : array [0 .. 5] of string = ('-m', 'mapfile.map',
  //                                                 '-u', 'TestUnit.pas',
  //                                                 '-a', '^-inputparam');

implementation

uses
  SysUtils;

constructor TMockCommandLineProvider.create(const AStringArray : array of string);
var
  idx: Integer;
begin
  FParamsStrLst := TStringList.create;

  for idx := Low(AStringArray) to High(AStringArray) do
  begin
    FParamsStrLst.add(AStringArray[idx]);
  end;
end;

destructor TMockCommandLineProvider.Destroy;
begin
  FParamsStrLst.Free;
  inherited;
end;

function TMockCommandLineProvider.Count: Integer;
begin
  Result := FParamsStrLst.Count;
end;

function TMockCommandLineProvider.ParamString(const AIndex: Integer): string;
begin
  if AIndex > Count then
    raise EParameterIndexException.create('Parameter Index:' + IntToStr(AIndex) + ' out of bounds.');
  Result := FParamsStrLst.Strings[AIndex - 1];
end;

end.
