(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_BreakPointList;

interface

{$INCLUDE CodeCoverage.inc}

uses
  I_BreakPoint;

type
  IBreakPointList = interface
    procedure SetCapacity(const AValue : Integer);

    procedure AddBreakPoint(const ABreakPoint: IBreakPoint);
    function GetBreakPointByAddress(const AAddress: Pointer): IBreakPoint;

    function BreakPointCount : Integer;
    function BreakPoint(const AIndex : Integer) : IBreakPoint;
  end;

implementation

end.
