(**************************************************************)
(* Delphi Code Coverage                                       *)
(*                                                            *)
(* A quick hack of a Code Coverage Tool for Delphi 2010       *)
(* by Christer Fahlgren and Nick Ring                         *)
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
  strict private
    FBreakPointLst: IJclStringList;
  public
    function GetBreakPoint(const AIndex: Integer): IBreakPoint;
    property BreakPoint[const AIndex: Integer]: IBreakPoint read GetBreakPoint; default;

    function GetBreakPointByAddress(const AAddress: Pointer): IBreakPoint;
    property BreakPointByAddress[const AAddress: Pointer]: IBreakPoint read GetBreakPointByAddress;

    constructor Create;
    destructor Destroy; override;

    procedure Add(const ABreakPoint: IBreakPoint);

    function Count: Integer;
    procedure SetCapacity(const AValue: Integer);
  end;

implementation

uses
  Classes,
  SysUtils;

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

function TBreakPointList.GetBreakPoint(const AIndex: Integer): IBreakPoint;
begin
  Result := IBreakPoint(FBreakPointLst.Interfaces[AIndex]);
end;

function TBreakPointList.Count: Integer;
begin
  Result := FBreakPointLst.Count;
end;

procedure TBreakPointList.Add(const ABreakPoint: IBreakPoint);
begin
  FBreakPointLst.KeyInterface[IntToHex(Integer(ABreakPoint.Address), 8)] := ABreakPoint;
end;

function TBreakPointList.GetBreakPointByAddress(const AAddress: Pointer): IBreakPoint;
begin
  Result := IBreakPoint(FBreakPointLst.KeyInterface[IntToHex(Integer(AAddress), 8)]);
end;

procedure TBreakPointList.SetCapacity(const AValue: Integer);
begin
  FBreakPointLst.Capacity := AValue;
end;

end.
