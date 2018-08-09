(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit CommandLineProvider;

interface

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
  System.SysUtils;

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
