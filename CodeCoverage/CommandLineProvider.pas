(* ************************************************************ *)
(* Delphi Code Coverage                                         *)
(*                                                              *)
(* A quick hack of a Code Coverage Tool for Delphi 2010         *)
(* by Christer Fahlgren                                         *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1                    *)
(* ************************************************************ *)

unit CommandLineProvider;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_ParameterProvider;

type
  TCommandLineProvider = class(TInterfacedObject, IParameterProvider)
  private
    function Count: Integer;
  public
    function ParamString(const AIndex: Integer): string;
  end;

implementation

uses
  SysUtils;

function TCommandLineProvider.Count: Integer;
begin
  Result := ParamCount;
end;

function TCommandLineProvider.ParamString(const AIndex: Integer): string;
begin
  if AIndex > Count then
    raise EParameterIndexException.Create('Parameter AIndex:' + IntToStr(AIndex) + ' out of bounds.');
  Result := ParamStr(AIndex);
end;

end.
