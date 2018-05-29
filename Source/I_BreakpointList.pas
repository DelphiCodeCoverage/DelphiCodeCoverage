(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit I_BreakPointList;

interface

uses
  I_BreakPoint;

type
  IBreakPointList = interface
    procedure SetCapacity(const AValue: Integer);

    procedure Add(const ABreakPoint: IBreakPoint);

    function Count: Integer;
    function GetBreakPoint(const AIndex: Integer): IBreakPoint;
    property BreakPoint[const AIndex: Integer]: IBreakPoint read GetBreakPoint; default;

    function GetBreakPointByAddress(const AAddress: Pointer): IBreakPoint;
    property BreakPointByAddress[const AAddress: Pointer]: IBreakPoint read GetBreakPointByAddress;
  end;

implementation

end.
