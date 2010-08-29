(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren                                       *)
(**************************************************************)
(* Licensed under Mozilla Public License 1.1                  *)
(**************************************************************)

unit BreakPointList;

interface

{$INCLUDE CodeCoverage.inc}

uses
  JclStringLists,
  I_BreakPoint,
  I_BreakPointList;

type
  TBreakPointList = class(TInterfacedObject, IBreakPointList)
  private
    FBreakPointLst: IJclStringList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetCapacity(const AValue : Integer);

    procedure AddBreakPoint(const ABreakPoint: IBreakPoint);

    function GetBreakPointByAddress(const AAddress: Pointer): IBreakPoint;

    function BreakPointCount : Integer;
    function BreakPoint(const AIndex : Integer) : IBreakPoint;
  end;

implementation

uses
  Classes,
  SysUtils;

function TBreakPointList.BreakPoint(const AIndex: Integer): IBreakPoint;
begin
  Result := IBreakPoint(FBreakPointLst.Interfaces[AIndex]);
end;

function TBreakPointList.BreakPointCount: Integer;
begin
  Result := FBreakPointLst.Count;
end;

constructor TBreakPointList.Create;
begin
  inherited;

  FBreakPointLst            := TJclStringList.Create;
  FBreakPointLst.Sorted     := True;
  FBreakPointLst.Duplicates := dupError;
end;

destructor TBreakPointList.Destroy;
begin
  FBreakPointLst := nil;

  inherited;
end;

procedure TBreakPointList.AddBreakPoint(const ABreakPoint: IBreakPoint);
begin
  FBreakPointLst.KeyInterface[IntToHex(Integer(ABreakPoint.GetAddress), 8)] := ABreakPoint;
end;

function TBreakPointList.GetBreakPointByAddress(const AAddress: Pointer):
    IBreakPoint;
begin
  Result := IBreakPoint(FBreakPointLst.KeyInterface[IntToHex(Integer(AAddress), 8)]);
end;

procedure TBreakPointList.SetCapacity(const AValue: Integer);
begin
  FBreakPointLst.Capacity := AValue;
end;

end.
