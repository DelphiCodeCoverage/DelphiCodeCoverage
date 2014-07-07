unit EmmaDataInputTests;

interface

uses
  TestFramework, Classes, FileHelper;

type
  TestTEmmaDataInput = class(TTestCase)
  strict private
    FDataInput: TEmmaDataInput;
    procedure SetUpDataInput(const AStream: TStream);
  public
    procedure TearDown; override;
  published
    procedure TestReadInt64;
    procedure TestReadInteger;
    procedure TestReadByte;
    procedure TestReadBoolean;
    procedure TestReadWord;
    procedure TestReadUTF;
    procedure TestReadIntArray;
    procedure TestReadBooleanArray;
  end;

implementation

uses
  SysUtils,
  Winsock;

procedure TestTEmmaDataInput.SetUpDataInput(const AStream: TStream);
begin
  AStream.Seek(0, soFromBeginning);
  FDataInput := TEmmaDataInput.Create(AStream);
end;

procedure TestTEmmaDataInput.TearDown;
begin
  FDataInput.Free;
  FDataInput := nil;
end;

procedure TestTEmmaDataInput.TestReadInt64;
var
  i: Byte;
  bytes: TBytes;

  procedure CheckReadInt64(const Expected: Int64; const ABytes: TBytes);
  var
    FStream: TStream;
  begin
    FStream := TBytesStream.Create(ABytes);
    try
      SetUpDataInput(FStream);
      CheckEquals(Expected, FDataInput.ReadInt64);
    finally
      FreeAndNil(FDataInput);
      FreeAndNil(FStream);
    end;
  end;
begin
  SetLength(bytes, 8);
  FillChar(bytes[0], 8, 0);

  for i := 0 to 255 do
  begin
    bytes[7] := i;
    CheckReadInt64(i, bytes);
  end;

  bytes[7] := 0;
  for i := 1 to 255 do
  begin
    bytes[6] := i;
    CheckReadInt64(256 * i, bytes);
  end;

  bytes[6] := 0;
  for i := 1 to 255 do
  begin
    bytes[5] := i;
    CheckReadInt64(65536 * i, bytes);
  end;

  bytes[5] := 0;
  for i := 1 to 255 do
  begin
    bytes[0] := i;
    CheckReadInt64(72057594037927936 * i, bytes);
  end;
end;

procedure TestTEmmaDataInput.TestReadInteger;
var
  i: Byte;
  bytes: TBytes;

  procedure CheckReadInteger(const Expected: Integer; const ABytes: TBytes);
  var
    FStream: TStream;
  begin
    FStream := TBytesStream.Create(ABytes);
    try
      SetUpDataInput(FStream);
      CheckEquals(Expected, FDataInput.ReadInteger);
    finally
      FreeAndNil(FDataInput);
      FreeAndNil(FStream);
    end;
  end;
begin
  SetLength(bytes, 4);
  FillChar(bytes[0], 4, 0);

  for i := 0 to 255 do
  begin
    bytes[3] := i;
    CheckReadInteger(i, bytes);
  end;

  bytes[3] := 0;
  for i := 1 to 255 do
  begin
    bytes[2] := i;
    CheckReadInteger(256 * i, bytes);
  end;

  bytes[2] := 0;
  for i := 1 to 255 do
  begin
    bytes[1] := i;
    CheckReadInteger(65536 * i, bytes);
  end;

  bytes[1] := 0;
  for i := 1 to 255 do
  begin
    bytes[0] := i;
    CheckReadInteger(16777216 * i, bytes);
  end;
end;

procedure TestTEmmaDataInput.TestReadByte;
var
  i: Integer;
  bytes: TBytes;
  FStream: TBytesStream;
begin
  Randomize;
  SetLength(bytes, 10 + Random(100));
  for i := 0 to Length(Bytes) - 1 do
    bytes[i] := Random(256);

  FStream := TBytesStream.Create(bytes);
  try
    SetUpDataInput(FStream);
    for i := 0 to Length(Bytes) - 1 do
      CheckEquals(bytes[i], FDataInput.ReadByte, IntToStr(i) + ': should be ' + IntToStr(bytes[i]));
  finally
    FStream.Free;
  end;
end;

procedure TestTEmmaDataInput.TestReadBoolean;
var
  i: Integer;
  bytes: TBytes;
  FStream: TBytesStream;
begin
  Randomize;
  SetLength(bytes, 10 + Random(100));
  for i := 0 to Length(Bytes) - 1 do
    bytes[i] := Random(2);

  FStream := TBytesStream.Create(bytes);
  try
    SetUpDataInput(FStream);
    for i := 0 to Length(Bytes) - 1 do
      CheckEquals(Boolean(bytes[i]), FDataInput.ReadBoolean, IntToStr(i) + ': should be ' + BoolToStr(Boolean(bytes[i])));
  finally
    FStream.Free;
  end;
end;

procedure TestTEmmaDataInput.TestReadWord;
var
  i: Byte;
  bytes: TBytes;

  procedure CheckReadWord(const Expected: Word; const ABytes: TBytes);
  var
    FStream: TStream;
  begin
    FStream := TBytesStream.Create(ABytes);
    try
      SetUpDataInput(FStream);
      CheckEquals(Expected, FDataInput.ReadWord);
    finally
      FreeAndNil(FDataInput);
      FreeAndNil(FStream);
    end;
  end;
begin
  SetLength(bytes, 2);
  FillChar(bytes[0], 2, 0);

  for i := 0 to 255 do
  begin
    bytes[1] := i;
    CheckReadWord(i, bytes);
  end;

  bytes[1] := 0;
  for i := 1 to 255 do
  begin
    bytes[0] := i;
    CheckReadWord(256 * i, bytes);
  end;
end;

procedure TestTEmmaDataInput.TestReadUTF;
var
  FStream: TMemoryStream;
  Expected: string;
  DataSize: Word;
  bytes: TBytes;
begin
  Expected := 'Hello Wörld';
  FStream := TMemoryStream.Create;
  try
    CheckEquals(0, FStream.Size);
    DataSize := ntohs(GetUtf8Length(Expected) - SizeOf(DataSize));
    bytes := TEncoding.UTF8.GetBytes(Expected);

    FStream.Write(DataSize, SizeOf(DataSize));
    FStream.Write(bytes[0], Length(bytes));

    SetUpDataInput(FStream);
    CheckEqualsString(Expected, FDataInput.ReadUTF);
  finally
    FStream.Free;
  end;
end;

procedure TestTEmmaDataInput.TestReadIntArray;
var
  ExpectedIntArray: TIntArray;
  i: Integer;
  v: Integer;
  FStream: TMemoryStream;
  actualArray: TIntArray;
begin
  Randomize;
  SetLength(ExpectedIntArray, 10 + Random(100));

  for i := 0 to Length(ExpectedIntArray) - 1 do
    ExpectedIntArray[i] := Random(MaxInt);

  FStream := TMemoryStream.Create;
  try
    v := ntohl(Length(ExpectedIntArray));
    FStream.Write(v, SizeOf(v));

    for i := 0 to Length(ExpectedIntArray) - 1 do
    begin
      v := ntohl(ExpectedIntArray[i]);
      FStream.Write(v, SizeOf(v));
    end;

    SetUpDataInput(FStream);

    SetLength(actualArray, 0);
    FDataInput.ReadIntArray(actualArray);
    CheckEquals(Length(ExpectedIntArray), Length(actualArray), 'Length');

    for i := 0 to Length(actualArray) - 1 do
      CheckEquals(ExpectedIntArray[i], actualArray[i], IntToStr(i));
  finally
    FStream.Free;
  end;
end;

procedure TestTEmmaDataInput.TestReadBooleanArray;
var
  ExpectedBoolArray: TBooleanArray;
  i: Integer;
  v: Byte;
  FStream: TMemoryStream;
  actualArray: TBooleanArray;
begin
  Randomize;
  SetLength(ExpectedBoolArray, 10 + Random(100));

  for i := 0 to Length(ExpectedBoolArray) - 1 do
    ExpectedBoolArray[i] := Boolean(Random(2));

  FStream := TMemoryStream.Create;
  try
    i := ntohl(Length(ExpectedBoolArray));
    FStream.Write(i, SizeOf(i));

    for i := 0 to Length(ExpectedBoolArray) - 1 do
    begin
      v := Byte(ExpectedBoolArray[i]);
      FStream.Write(v, 1);
    end;

    SetUpDataInput(FStream);

    SetLength(actualArray, 0);
    FDataInput.ReadBooleanArray(actualArray);
    CheckEquals(Length(ExpectedBoolArray), Length(actualArray), 'Length');

    for i := 0 to Length(actualArray) - 1 do
      CheckEquals(ExpectedBoolArray[i], actualArray[i], IntToStr(i));
  finally
    FStream.Free;
  end;
end;

initialization
  RegisterTest(TestTEmmaDataInput.Suite);
end.

