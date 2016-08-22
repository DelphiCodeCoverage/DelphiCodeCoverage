(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit I_BreakPoint;

interface

{$INCLUDE CodeCoverage.inc}

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
