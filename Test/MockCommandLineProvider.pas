(* ************************************************************ *)
(* Delphi Code Coverage                                         *)
(*                                                              *)
(* A quick hack of a Code Coverage Tool for Delphi 2010         *)
(* by Christer Fahlgren                                         *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1                    *)
(* ************************************************************ *)

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
