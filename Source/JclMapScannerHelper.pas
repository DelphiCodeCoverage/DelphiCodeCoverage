unit JclMapScannerHelper;

interface

uses
  JclDebug;

type
  TJclAbstractMapParserHelper = class helper for TJclAbstractMapParser
    class function MapStringToSourceFile(MapString: PJclMapString): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TJclAbstractMapParserHelper }

class function TJclAbstractMapParserHelper.MapStringToSourceFile(
  MapString: PJclMapString): string;
var
  P: PJclMapString;
begin
  if MapString = nil then
  begin
    Result := '';
    Exit;
  end;
  if MapString^ = '(' then
  begin
    Inc(MapString);
    P := MapString;
    while (P^ <> #0) and not (P^ in [')', #10, #13]) do
      Inc(P);
  end
  else
  begin
    P := MapString;
    while (P^ <> #0) and (P^ > ' ') do
      Inc(P);
  end;
  SetString(Result, MapString, P - MapString);
  if Result.Contains('(') then
    Result := Result.Substring(Result.IndexOf('(')+1, Result.IndexOf(')') - Result.IndexOf('(') - 1)
end;

end.
