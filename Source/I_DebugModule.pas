(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit I_DebugModule;

interface

uses Winapi.Windows, JCLDebug;

type
   IDebugModule = interface
     function Name: string;
     function Base: HMODULE;
     function Size: Cardinal;
     function MapScanner: TJCLMapScanner;
  end;

implementation
end.
