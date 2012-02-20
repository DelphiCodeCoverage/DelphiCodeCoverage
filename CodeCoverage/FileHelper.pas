(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit FileHelper;

interface

type
  TIntArray = array of Integer;
  TBooleanArray = array of Boolean;
  TMultiBooleanArray = array of TBooleanArray;

function readInt64(var aFile: File): Int64;
procedure writeInt64(var aFile: File; const val: Int64);
function readInteger(var aFile: File): Integer;
procedure writeInteger(var aFile: File; const val: Integer);

function readByte(var aFile: File): Byte;
procedure writeByte(var aFile: File; const val: Byte);

function readBoolean(var aFile: File): Boolean;
procedure writeBoolean(var aFile: File; const val: Boolean);

function readWord(var aFile: File): Word;
procedure writeWord(var aFile: File; const val: Word);

function readUTF(var aFile: File): String;
procedure writeUTF(var aFile: File; const val: String);
function getUtf8Length(const val: String): Integer;

procedure readIntArray(var aFile: File; var arr: TIntArray);
procedure writeIntArray(var aFile: File; var arr: TIntArray);
function getEntryLength(var arr: TIntArray): Int64; overload;

procedure readBooleanArray(var aFile: File; var arr: TBooleanArray);
procedure writeBooleanArray(var aFile: File; var arr: TBooleanArray);
function getEntryLength(var arr: TBooleanArray): Int64; overload;

implementation

uses sysutils, winsock;

function readByte(var aFile: File): Byte;
var
  b: Byte;
begin
  BlockRead(aFile, b, 1);
  result := b;
end;

procedure writeByte(var aFile: File; const val: Byte);
begin
  BlockWrite(aFile, val, 1);
end;

procedure writeBoolean(var aFile: File; const val: Boolean);
var
  b: Byte;
begin
  b := Byte(val);
  BlockWrite(aFile, b, sizeof(b));

end;

function readBoolean(var aFile: File): Boolean;
var
  b: Byte;
begin
  BlockRead(aFile, b, sizeof(b));
  result := Boolean(b);
end;

function readUTF(var aFile: File): String;
var
  length: Word;
  str: RawByteString;
  count: Integer;
begin
  length := readWord(aFile);
  setlength(str, length);
  BlockRead(aFile, str[1], length, count);
  if (length <> count) then
    raise Exception.Create('Reading string but EOF encountered');
  result := UTF8Decode(str);
end;

procedure writeUTF(var aFile: File; const val: String);
var
  strLength: Word;
  str: RawByteString;
  count: Integer;
begin
  str := UTF8Encode(val);
  strLength := length(str);
  writeWord(aFile, strLength);

  BlockWrite(aFile, str[1], strLength, count);
  if (strLength <> count) then
    raise Exception.Create('Writing string but not enough chars were written');
end;

function getUtf8Length(const val: String): Integer;
var
  str: RawByteString;
begin
  str := UTF8Encode(val);
  result := length(str) + sizeof(Word);
end;

procedure readIntArray(var aFile: File; var arr: TIntArray);
var
  length: Integer;
  i: Integer;

begin
  length := readInteger(aFile);

  setlength(arr, length);
  for i := 0 to length - 1 do
  begin
    arr[i] := readInteger(aFile);
  end;

end;

procedure writeIntArray(var aFile: File; var arr: TIntArray);
var
  i: Integer;

begin
  writeInteger(aFile, length(arr));
  for i := 0 to high(arr) do
  begin
    writeInteger(aFile, arr[i]);
  end;

end;

function getEntryLength(var arr: TIntArray): Int64;
var
  size: Int64;
begin
  size := 0;
  size := size + sizeof(Integer);
  size := size + length(arr) * sizeof(Integer);
  result := size;
end;

procedure readBooleanArray(var aFile: File; var arr: TBooleanArray);
var
  length: Integer;
  i: Integer;

begin
  length := readInteger(aFile);

  setlength(arr, length);
  for i := 0 to length - 1 do
  begin
    arr[i] := readBoolean(aFile);
  end;

end;

procedure writeBooleanArray(var aFile: File; var arr: TBooleanArray);
var
  i: Integer;

begin
  writeInteger(aFile, length(arr));

  for i := 0 to High(arr) do
  begin
    writeBoolean(aFile, arr[i]);
  end;

end;

function getEntryLength(var arr: TBooleanArray): Int64;
var
  size: Int64;
begin
  size := 0;
  size := size + sizeof(Integer);
  size := size + length(arr) * sizeof(Boolean);
  result := size;
end;

function reverseInt64_Pure(const aVal: Int64): Int64;
begin
  Int64Rec(result).Bytes[0] := Int64Rec(aVal).Bytes[7];
  Int64Rec(result).Bytes[1] := Int64Rec(aVal).Bytes[6];
  Int64Rec(result).Bytes[2] := Int64Rec(aVal).Bytes[5];
  Int64Rec(result).Bytes[3] := Int64Rec(aVal).Bytes[4];
  Int64Rec(result).Bytes[4] := Int64Rec(aVal).Bytes[3];
  Int64Rec(result).Bytes[5] := Int64Rec(aVal).Bytes[2];
  Int64Rec(result).Bytes[6] := Int64Rec(aVal).Bytes[1];
  Int64Rec(result).Bytes[7] := Int64Rec(aVal).Bytes[0];
end;

function readInt64(var aFile: File): Int64;
var
  val: Int64;
  count: Integer;
begin
  BlockRead(aFile, val, sizeof(val), count);
  if (count <> sizeof(val)) then
    raise Exception.Create('Not enough bytes to read an Int64');
  result := reverseInt64_Pure(val);
end;

procedure writeInt64(var aFile: File; const val: Int64);
var
  valToWrite: Int64;
  count: Integer;
begin
  valToWrite := reverseInt64_Pure(val);
  BlockWrite(aFile, valToWrite, sizeof(valToWrite), count);
  if (count <> sizeof(valToWrite)) then
    raise Exception.Create('Not enough bytes written');
end;

function reverseInt_Pure(const aVal: Integer): Integer; inline;
begin
  result := ntohl(aVal);
end;

function reverseWord(const aVal: Word): Word; inline;
begin
  result := ntohs(aVal);
end;

function readInteger(var aFile: File): Integer;
var
  val: Integer;
  count: Integer;
begin
  BlockRead(aFile, val, sizeof(val), count);
  if (count <> sizeof(val)) then
    raise Exception.Create('Not enough bytes to read an Integer');
  result := reverseInt_Pure(val);
end;

procedure writeInteger(var aFile: File; const val: Integer);
var
  valToWrite: Integer;
  count: Integer;
begin
  valToWrite := reverseInt_Pure(val);
  BlockWrite(aFile, valToWrite, sizeof(valToWrite), count);
  if (count <> sizeof(valToWrite)) then
    raise Exception.Create('Not enough bytes written for  an Integer');

end;

function readWord(var aFile: File): Word;
var
  val: Word;
  count: Integer;
begin
  BlockRead(aFile, val, sizeof(val), count);
  if (count <> sizeof(val)) then
    raise Exception.Create('Not enough bytes to read a Word');
  result := reverseWord(val);
end;

procedure writeWord(var aFile: File; const val: Word);
var
  valToWrite: Word;
  count: Integer;
begin
  valToWrite := reverseWord(val);
  BlockWrite(aFile, valToWrite, sizeof(valToWrite), count);
  if (count <> sizeof(valToWrite)) then
    raise Exception.Create('Not enough bytes written for a word');

end;

end.
