(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit MockCommandLineProvider;

interface

uses
  Classes,
  I_ParameterProvider;

type
  TMockCommandLineProvider = class(TInterfacedObject, IParameterProvider)
  private
    FParamsStrLst: TStrings;
  public
    constructor Create(const AStringArray : array of string);
    destructor Destroy; override;
    function Count: Integer;
    function ParamString(const AIndex: Integer): string;
  end;

implementation

uses
  SysUtils;

constructor TMockCommandLineProvider.create(const AStringArray : array of string);
var
  idx: Integer;
begin
  FParamsStrLst := TStringList.Create;

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
