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

uses generics.collections, mergableUnit;

type
  TEmmaFile = class
  private
    fMergables: TList<TMergable>;
  public
    constructor create;
    destructor Destroy; override;
    procedure add(AMergable: TMergable);
    procedure read(var AFile: File);
    procedure write(var AFile: File);
  end;

implementation

uses FileHelper, MetaDataUnit, sysutils, CoverageDataUnit;

const
  SKIP_LENGTH = 3 * 4;
  TYPE_METADATA = 0;

constructor TEmmaFile.create;
begin
  fMergables := TList<TMergable>.create;
end;

destructor TEmmaFile.Destroy;
var
  mergable: TMergable;
begin
  for mergable in fMergables do
  begin
    mergable.free;
  end;
  fMergables.free;
end;

procedure TEmmaFile.add(AMergable: TMergable);
begin
  fMergables.add(AMergable);
end;

procedure TEmmaFile.read(var AFile: File);
var
  MagicValue: array [0 .. 3] of Byte;
  fileheaderbuffer: array [0 .. SKIP_LENGTH - 1] of Byte;

  i: Int64;
  count: Integer;
  entryLength: Int64;
  entryType: Byte;
  mergable: TMergable;
begin
  BlockRead(AFile, MagicValue, 4);

  i := readInt64(AFile);
  if (i = $20) then
  begin
    writeln('Yes, version 2.0');
    BlockRead(AFile, fileheaderbuffer, SKIP_LENGTH, count);
    if (count <> SKIP_LENGTH) then
      raise Exception.create(
        'Consuming file header, but file ended unexpectedly');

    while (Not(eof(AFile))) do
    begin
      entryLength := readInt64(AFile);
      entryType := readByte(AFile);
      writeln('EntryLength:' + IntToStr(entryLength));
      writeln('EntryType:' + IntToStr(entryType));
      if (entryType = TYPE_METADATA) then
      begin
        mergable := TEmmaMetaData.create();
        mergable.loadFromFile(AFile);
        fMergables.add(mergable);
      end
      else
      begin
        mergable := TEmmaCoverageData.create;
        mergable.loadFromFile(AFile);
        fMergables.add(mergable);
      end;

    end;

  end
  else
  begin
    writeln('ERROR: Not version 2.0)');
  end;

end;

procedure TEmmaFile.write(var AFile: File);
var
  buffer: array [0 .. 3] of Byte;
  i: Integer;
  mergable: TMergable;
  written, pos: longint;

begin
  buffer[0] := Byte('E');
  buffer[1] := Byte('M');
  buffer[2] := Byte('M');
  buffer[3] := Byte('A');

  pos := Filepos(AFile);
  BlockWrite(AFile, buffer, 4);
  written := Filepos(AFile) - pos;
  writeln(written);
  // Write file version
  writeInt64(AFile, $00000020);
  // Write file header with application version info
  writeInteger(AFile, $2);
  writeInteger(AFile, 0);
  writeInteger(AFile, $14C0);

  for i := 0 to fMergables.count - 1 do
  begin
    mergable := fMergables[i];
    writeInt64(AFile, mergable.getEntryLength());
    writeByte(AFile, mergable.getEntryType());
    mergable.writeToFile(AFile);
  end;
end;

end.
