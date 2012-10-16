// Implementation of needed Helpers for Delphi < XE
unit StrUtilsD9;

interface

uses
  Types;

function SplitString(const S, Delimiters: string): TStringDynArray;

implementation

uses
  Generics.Collections,
  StrUtils;

function SplitString(const S, Delimiters: string): TStringDynArray;
var
  delimiterIndex: Integer;
  currentDelimiter: Char;
  delimiterPositions: TList<Integer>;
  currentDelimiterPosition, nextDelimiterPosition: Integer;
  i: Integer;
begin
  {$IF CompilerVersion >= 21}
  Result := StrUtils.SplitString(S, Delimiters);
  Exit;
  {$IFEND}

  SetLength(Result, 0);
  delimiterPositions := TList<Integer>.Create;
  try
    for delimiterIndex := 1 to Length(Delimiters) do
    begin
      currentDelimiter := Delimiters[delimiterIndex];
      currentDelimiterPosition := Pos(currentDelimiter, S);
      while currentDelimiterPosition > 0 do
      begin
        if not delimiterPositions.Contains(currentDelimiterPosition) then
          delimiterPositions.Add(currentDelimiterPosition);
        currentDelimiterPosition := PosEx(currentDelimiter, S, currentDelimiterPosition + 1);
      end;
    end;

    if delimiterPositions.Count = 0 then
    begin
      SetLength(Result, 1);
      Result[0] := S;
    end
    else
    begin
      SetLength(Result, delimiterPositions.Count + 1);
      delimiterPositions.Sort;
      for i := 0 to delimiterPositions.Count do
      begin
        if i = 0 then
          currentDelimiterPosition := 0
        else
          currentDelimiterPosition := delimiterPositions[i - 1];
        if i = delimiterPositions.Count then
          nextDelimiterPosition := Length(S) + 1
        else
          nextDelimiterPosition := delimiterPositions[i];


        Result[i] := Copy(S, currentDelimiterPosition + 1, nextDelimiterPosition - currentDelimiterPosition - 1);
      end;
    end;
  finally
    delimiterPositions.Clear;
    delimiterPositions.Free;
  end;

end;

end.
