(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit EmmaDataFile;

interface

uses
  Generics.Collections,
  MergableUnit;

type
  TEmmaFile = class
  private
    FMergables: TList<TMergable>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AMergable: TMergable);
    procedure Read(var AFile: File);
    procedure Write(var AFile: File);
  end;

implementation

uses
  FileHelper,
  MetaDataUnit,
  SysUtils,
  uConsoleOutput,
  CoverageDataUnit;

const
  SKIP_LENGTH = 3 * 4;
  TYPE_METADATA = 0;

constructor TEmmaFile.Create;
begin
  inherited Create;

  FMergables := TList<TMergable>.create;
end;

destructor TEmmaFile.Destroy;
var
  Mergable: TMergable;
begin
  for Mergable in FMergables do
    mergable.free;
  FMergables.free;
end;

procedure TEmmaFile.Add(const AMergable: TMergable);
begin
  FMergables.Add(AMergable);
end;

procedure TEmmaFile.Read(var AFile: File);
var
  MagicValue: array [0 .. 3] of Byte;
  FileHeaderBuffer: array [0 .. SKIP_LENGTH - 1] of Byte;

  i: Int64;
  Count: Integer;
  EntryLength: Int64;
  EntryType: Byte;
  Mergable: TMergable;
begin
  BlockRead(AFile, MagicValue, 4);

  i := FileHelper.readInt64(AFile);
  if (i = $20) then
  begin
    VerboseOutput('Yes, version 2.0');
    BlockRead(AFile, FileHeaderBuffer, SKIP_LENGTH, Count);
    if (Count <> SKIP_LENGTH) then
      raise Exception.Create('Consuming file header, but file ended unexpectedly');

    while not Eof(AFile) do
    begin
      EntryLength := FileHelper.readInt64(AFile);
      EntryType := FileHelper.readByte(AFile);
      VerboseOutput('EntryLength:' + IntToStr(EntryLength));
      VerboseOutput('EntryType:' + IntToStr(EntryType));
      if (EntryType = TYPE_METADATA) then
      begin
        Mergable := TEmmaMetaData.Create;
        Mergable.LoadFromFile(AFile);
        FMergables.Add(Mergable);
      end
      else
      begin
        Mergable := TEmmaCoverageData.Create;
        Mergable.LoadFromFile(AFile);
        FMergables.Add(Mergable);
      end;
    end;
  end
  else
    ConsoleOutput('ERROR: Not version 2.0)');
end;

procedure TEmmaFile.Write(var AFile: File);
var
  Buffer: array [0 .. 3] of Byte;
  Mergable: TMergable;
begin
  Buffer[0] := Byte('E');
  Buffer[1] := Byte('M');
  Buffer[2] := Byte('M');
  Buffer[3] := Byte('A');

  BlockWrite(AFile, Buffer, 4);

  // Write file version
  FileHelper.writeInt64(AFile, $00000020);
  // Write file header with application version info
  FileHelper.writeInteger(AFile, $2);
  FileHelper.writeInteger(AFile, 0);
  FileHelper.writeInteger(AFile, $14C0);

  for Mergable in FMergables do
  begin
    FileHelper.writeInt64(AFile, Mergable.EntryLength);
    FileHelper.writeByte(AFile, Mergable.EntryType);
    Mergable.WriteToFile(AFile);
  end;
end;

end.
