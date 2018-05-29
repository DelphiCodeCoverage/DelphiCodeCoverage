(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit I_BreakPoint;

interface

uses
  I_DebugThread, I_DebugModule;

type
  TBreakPointDetail = record
    ModuleName : string;
    UnitName   : string;
    Line       : Integer;
  end;

type
  IBreakPoint = interface
    procedure Clear(const AThread: IDebugThread);

    function Activate: Boolean;

    function DeActivate: Boolean;
    function BreakCount:integer;

    procedure IncBreakCount;

    function Address: Pointer;
    function Module: IDebugModule;

    function DetailCount: Integer;
    function DetailByIndex(const AIndex: Integer): TBreakPointDetail;
    procedure AddDetails(
      const AModuleName: string;
      const AUnitName: string;
      const ALineNumber: Integer);

    function IsActive: Boolean;

    function GetCovered: Boolean;
    property IsCovered: Boolean read GetCovered;
  end;


implementation

end.
