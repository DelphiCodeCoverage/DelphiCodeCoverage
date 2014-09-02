unit IOUtilsD9;

interface

type
  TPath = record
  private
    class function IsAbsolute(const Path: string): Boolean; static;
  public
    class function GetFullPath(const Path: string): string; static;
    class function Combine(const Path1, Path2: string): string; inline; static;
    class function GetDirectoryName(FileName: string): string; static;
    class function IsRelativePath(const Path: string): Boolean; static;
  end;

  TFile = record
  public
    class procedure WriteAllText(const Path, Contents: string); static;
    class procedure Delete(const Path: string); static;
  end;

implementation

uses
  Classes,
  Windows,
  SysUtils,
  StrUtils;

class function TPath.Combine(const Path1, Path2: string): string;
var
  sTmp: string;
begin

  if IsAbsolute(Path2) then
    Result := Path2
  else
  begin
    sTmp := Path2;
    while IsPathDelimiter(sTmp, 1) do
      Delete(sTmp, 1, 1);

    Result := IncludeTrailingPathDelimiter(Path1) + sTmp;
  end;
end;

class function TPath.GetDirectoryName(FileName: string): string;
begin
  Result := ExtractFilePath(FileName);
end;

class function TPath.GetFullPath(const Path: string): string;
var
  lpFileName : pchar;
  lpBuffer : array[0..MAX_PATH] of char;
begin
  Result := Path;

  if not IsAbsolute(Path) then
  begin
    lpFileName := PChar(Path);
    if GetFullPathName(lpFileName, MAX_PATH, lpBuffer, lpFileName) > 0 then
      Result := lpBuffer;
  end;
end;

class function TPath.IsAbsolute(const Path: string): Boolean;
var
  tmp: string;
  FirstChar: Byte;
begin
  Result := StartsStr('\\', Path);
  if not Result
  and (Length(Path) >= 3) then
  begin
    tmp := Copy(Path, 2, 2);
    FirstChar := Ord(UpperCase(Path)[1]);
    Result := (tmp = ':\')
              and (FirstChar >= Ord('A'))
              and (FirstChar <= Ord('Z'));
  end;
end;

class function TPath.IsRelativePath(const Path: string): Boolean;
begin
  Result := not IsAbsolute(Path);
end;

{ TFile }

class procedure TFile.Delete(const Path: string);
begin
  DeleteFile(Path);
end;

class procedure TFile.WriteAllText(const Path, Contents: string);
var
  fs: TFileStream;
  ss: TStringStream;
begin
  if not FileExists(Path)
  or DeleteFile(Path) then
  begin
    ss := TStringStream.Create(Path);
    try
      fs := TFileStream.Create(Path, fmCreate or fmShareDenyNone);
      try
        fs.CopyFrom(ss, 0);
      finally
        fs.Free;
      end;
    finally
      ss.Free;
    end;
  end;
end;

end.
