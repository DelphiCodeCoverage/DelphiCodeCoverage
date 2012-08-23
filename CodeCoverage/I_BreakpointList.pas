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
