unit EmmaDataOutputTests;

interface

uses
  TestFramework, Classes, FileHelper;

type
  TestTEmmaDataOutput = class(TTestCase)
  strict private
    FDataOutput: TEmmaDataOutput;
    FStream: TMemoryStream;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestWriteInt64;
    procedure TestWriteInteger;
    procedure TestWriteByte;
    procedure TestWriteBoolean;
    procedure TestWriteWord;
    procedure TestWriteUTF;
    procedure TestWriteIntArray;
    procedure TestWriteBooleanArray;
  end;

implementation

uses
  Types,
  SysUtils,
  Winsock;

procedure TestTEmmaDataOutput.SetUp;
begin
  FStream := TMemoryStream.Create;
  FDataOutput := TEmmaDataOutput.Create(FStream);
end;

procedure TestTEmmaDataOutput.TearDown;
begin
  FDataOutput.Free;
  FDataOutput := nil;
  FStream.Free;
  FStream := nil;
end;

procedure TestTEmmaDataOutput.TestWriteInt64;
  procedure CheckWriteInt64(const ABase: Int64; const ByteIndex: Integer);
  var
    bytes: TBytes;
    i, j: Integer;
  begin
    for i := 0 to 255 do
    begin
      FStream.Size := 0;
      FDataOutput.WriteInt64(i * ABase);
      CheckEquals(8, FStream.Size);
      SetLength(bytes, 8);
      FStream.Seek(0, soFromBeginning);
      FStream.Read(bytes[0], Length(bytes));

      for j := 0 to Length(bytes) - 2 do
      begin
        if j = ByteIndex then
          CheckEquals(bytes[j], i)
        else
          CheckEquals(bytes[j], 0);
      end;
    end;
  end;
var
  i: Integer;
  bytes: TBytes;
begin

  FStream.Size := 0;
  SetLength(bytes, 8);
  FDataOutput.WriteInt64(0);
  CheckEquals(8, FStream.Size);
  FStream.Seek(0, soFromBeginning);
  FStream.Read(bytes[0], Length(bytes));

  for i := 0 to Length(bytes) - 1 do
    CheckEquals(bytes[i], 0);

  CheckWriteInt64(1, 7);
  CheckWriteInt64(256, 6);
  CheckWriteInt64(65536, 5);
  CheckWriteInt64(72057594037927936, 0);
end;

procedure TestTEmmaDataOutput.TestWriteInteger;
  procedure CheckWriteInteger(const ABase: Integer; const ByteIndex: Integer);
  var
    bytes: TBytes;
    i, j: Integer;
  begin
    for i := 0 to 255 do
    begin
      FStream.Size := 0;
      FDataOutput.WriteInteger(i * ABase);
      CheckEquals(4, FStream.Size);
      SetLength(bytes, 4);
      FStream.Seek(0, soFromBeginning);
      FStream.Read(bytes[0], Length(bytes));

      for j := 0 to Length(bytes) - 2 do
      begin
        if j = ByteIndex then
          CheckEquals(bytes[j], i)
        else
          CheckEquals(bytes[j], 0);
      end;
    end;
  end;
var
  i: Integer;
  bytes: TBytes;
begin
  FStream.Size := 0;
  FDataOutput.WriteInteger(0);
  CheckEquals(4, FStream.Size);
  SetLength(bytes, 4);
  FStream.Seek(0, soFromBeginning);
  FStream.Read(bytes[0], Length(bytes));

  for i := 0 to Length(bytes) - 1 do
    CheckEquals(bytes[i], 0);

  CheckWriteInteger(1, 3);
  CheckWriteInteger(256, 2);
  CheckWriteInteger(65536, 1);
  CheckWriteInteger(16777216, 0);

  FStream.Size := 0;
  FDataOutput.WriteInteger(MaxInt);
  CheckEquals(4, FStream.Size);
  SetLength(bytes, 4);
  FStream.Seek(0, soFromBeginning);
  FStream.Read(bytes[0], Length(bytes));

  for i := 0 to Length(bytes) - 1 do
  begin
    if i = 0 then
      CheckEquals(bytes[i], 127, IntToStr(i))
    else
      CheckEquals(bytes[i], 255, IntToStr(i));
  end;
end;

procedure TestTEmmaDataOutput.TestWriteByte;
var
  i: Integer;
  ExpectedByte, ActualByte: Byte;
begin
  Randomize;
  for i := 0 to (10 + Random(100)) do
  begin
    FStream.Size := 0;
    ExpectedByte := Random(256);
    FDataOutput.WriteByte(ExpectedByte);

    FStream.Seek(0, soFromBeginning);
    FStream.Read(ActualByte, 1);
    CheckEquals(ExpectedByte, ActualByte);
  end;
end;

procedure TestTEmmaDataOutput.TestWriteBoolean;
var
  i: Integer;
  ExpectedBool: Boolean;
  ActualByte: Byte;
begin
  Randomize;
  for i := 0 to (10 + Random(100)) do
  begin
    FStream.Size := 0;
    ExpectedBool := Boolean(Random(2));
    FDataOutput.WriteBoolean(ExpectedBool);

    FStream.Seek(0, soFromBeginning);
    FStream.Read(ActualByte, 1);
    CheckEquals(ExpectedBool, Boolean(ActualByte));
  end;
end;

procedure TestTEmmaDataOutput.TestWriteWord;
  procedure CheckWriteWord(const ABase: Word; const ByteIndex: Integer);
  var
    bytes: TBytes;
    i, j: Integer;
  begin
    for i := 0 to 255 do
    begin
      FStream.Size := 0;
      FDataOutput.WriteWord(i * ABase);
      CheckEquals(2, FStream.Size);
      SetLength(bytes, 2);
      FStream.Seek(0, soFromBeginning);
      FStream.Read(bytes[0], Length(bytes));

      for j := 0 to Length(bytes) - 2 do
      begin
        if j = ByteIndex then
          CheckEquals(bytes[j], i)
        else
          CheckEquals(bytes[j], 0);
      end;
    end;
  end;
var
  i: Integer;
  bytes: TBytes;
begin
  FStream.Size := 0;
  FDataOutput.WriteWord(0);
  CheckEquals(2, FStream.Size);
  SetLength(bytes, 2);
  FStream.Seek(0, soFromBeginning);
  FStream.Read(bytes[0], Length(bytes));

  for i := 0 to Length(bytes) - 1 do
    CheckEquals(bytes[i], 0);

  CheckWriteWord(1, 1);
  CheckWriteWord(256, 0);

  FStream.Size := 0;
  FDataOutput.WriteWord(65535);
  CheckEquals(2, FStream.Size);
  SetLength(bytes, 2);
  FStream.Seek(0, soFromBeginning);
  FStream.Read(bytes[0], Length(bytes));

  for i := 0 to Length(bytes) - 1 do
    CheckEquals(bytes[i], 255, IntToStr(i));
end;

procedure TestTEmmaDataOutput.TestWriteUTF;
var
  Expected: string;
  Actual: RawByteString;
  ExpectedDataSize: Word;
  ActualDataSize: Word;
begin
  Expected := 'Hello Wörld';
  ExpectedDataSize := GetUtf8Length(Expected) - SizeOf(ExpectedDataSize);
  FDataOutput.WriteUTF(Expected);

  FStream.Seek(0, soFromBeginning);
  FStream.Read(ActualDataSize, SizeOf(ActualDataSize));
  ActualDataSize := ntohs(ActualDataSize);
  CheckEquals(ExpectedDataSize, ActualDataSize, 'Data size');

  SetLength(Actual, ActualDataSize);

  FStream.Read(Actual[1], ActualDataSize);
  CheckEqualsString(Expected, UTF8ToString(Actual), 'Data');
end;

procedure TestTEmmaDataOutput.TestWriteIntArray;
var
  ExpectedIntArray: TIntArray;
  ExpectedDataSize, ActualDataSize: Integer;
  i: Integer;
  ActualValue: Integer;
begin
  Randomize;
  SetLength(ExpectedIntArray, 10 + Random(100));
  ExpectedDataSize := Length(ExpectedIntArray);
  for i := 0 to Length(ExpectedIntArray) - 1 do
    ExpectedIntArray[i] := Random(MaxInt);


  FDataOutput.WriteIntArray(ExpectedIntArray);
  FStream.Seek(0, soFromBeginning);
  FStream.Read(ActualDataSize, SizeOf(ActualDataSize));
  ActualDataSize := ntohl(ActualDataSize);
  CheckEquals(ExpectedDataSize, ActualDataSize, 'Data size');

  for i := 0 to ActualDataSize - 1 do
  begin
    FStream.Read(ActualValue, SizeOf(ActualValue));
    ActualValue := ntohl(ActualValue);
    CheckEquals(ExpectedIntArray[i], ActualValue, 'Data ' + IntToStr(i));
  end;
end;

procedure TestTEmmaDataOutput.TestWriteBooleanArray;
var
  ExpectedBoolArray: TBooleanDynArray;
  ExpectedDataSize, ActualDataSize: Integer;
  i: Integer;
  ActualValue: Byte;
begin
  Randomize;
  SetLength(ExpectedBoolArray, 10 + Random(100));
  ExpectedDataSize := Length(ExpectedBoolArray);
  for i := 0 to Length(ExpectedBoolArray) - 1 do
    ExpectedBoolArray[i] := Boolean(Random(2));

  FDataOutput.WriteBooleanArray(ExpectedBoolArray);
  FStream.Seek(0, soFromBeginning);
  FStream.Read(ActualDataSize, SizeOf(ActualDataSize));
  ActualDataSize := ntohl(ActualDataSize);
  CheckEquals(ExpectedDataSize, ActualDataSize, 'Data size');

  for i := 0 to ActualDataSize - 1 do
  begin
    FStream.Read(ActualValue, 1);
    CheckEquals(ExpectedBoolArray[i], Boolean(ActualValue), 'Data ' + IntToStr(i));
  end;
end;

initialization
  RegisterTest(TestTEmmaDataOutput.Suite);
end.


