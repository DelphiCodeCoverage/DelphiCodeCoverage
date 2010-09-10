(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_ParameterProvider;

interface

{$INCLUDE CodeCoverage.inc}

uses
  SysUtils;

type
  EParameterIndexException = class(Exception);

type
  IParameterProvider = interface
    function Count: Integer;
    function ParamString(const AIndex: Integer): string;
  end;

implementation

end.
