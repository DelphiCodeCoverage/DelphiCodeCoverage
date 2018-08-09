(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit I_ParameterProvider;

interface

uses
  System.SysUtils;

type
  EParameterIndexException = class(Exception);

type
  IParameterProvider = interface
    function Count: Integer;
    function ParamString(const AIndex: Integer): string;
  end;

implementation

end.
