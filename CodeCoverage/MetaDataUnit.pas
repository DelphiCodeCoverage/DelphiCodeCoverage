(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit MetaDataUnit;

interface

uses
  Types,
  Classes,
  Generics.Collections,
  MergableUnit,
  FileHelper;

type
  TIntArrays = array of TIntArray;

  TMethodDescriptor = class
  strict private
    FName: string;
    FDescriptor: string;
    FStatus: Integer;
    FBlockMap: TIntArrays;
    FBlockSizes: TIntArray;
    FFirstLine: Integer;
    function GetEntryLength: Int64;
    function FindFirstLine: Integer;
  public
    property Name: string read FName write FName;
    property Descriptor: string read FDescriptor write FDescriptor;
    property Status: Integer read FStatus write FStatus;
    property BlockMap: TIntArrays read FBlockMap write FBlockMap;
    property BlockSizes: TIntArray read FBlockSizes write FBlockSizes;
    property FirstLine: Integer read FFirstLine write FFirstLine;
    property EntryLength: Int64 read GetEntryLength;

    destructor Destroy; override;

    function ToString: string; override;
    procedure LoadFromFile(const DataInput: IEmmaDataInput);
    procedure WriteToFile(DataOutput: IEmmaDataOutput);
    procedure SetBlockSizesLength(const ALength: Integer);
    procedure SetBlockMapLength(const ALength: Integer);
  end;

  TClassDescriptor = class
  strict private
    FClassVMName: string;
    FPackageVMName: string;
    FName: string;
    FStamp: Int64;
    FSrcFileNameFlag: Byte;
    FSrcFileName: string;
    FMethods: TList<TMethodDescriptor>;
    function GetEntryLength: Int64;
  public
    property ClassVMName: string read FClassVMName;
    property PackageVMName: string read FPackageVMName;
    property Name: string read FName;
    property Stamp: Int64 read FStamp;
    property SrcFileNameFlag: Byte read FSrcFileNameFlag;
    property SrcFileName: string read FSrcFileName;
    property EntryLength: Int64 read GetEntryLength;

    constructor Create(
      const AName: string;
      const ASrcFileNameFlag: Integer;
      const ASrcFileName: string;
      const AClassVMName: string;
      const APackageVMName: string);

    constructor CreateFromFile(const DataInput: IEmmaDataInput);
    destructor Destroy; override;

    function ToString: string; override;

    procedure LoadFromFile(const DataInput: IEmmaDataInput);
    procedure WriteToFile(DataOutput: IEmmaDataOutput);
    procedure Add(const AMethodDescriptor: TMethodDescriptor);

  end;

  TCoverageOptions = class
  strict private
    FExcludeSyntheticMethods: Boolean;
    FExcludeBridgeMethods: Boolean;
    FDoSUIDCompensation: Boolean;
    function GetEntryLength: Int64;
  public
    property ExcludeSyntheticMethods: Boolean read FExcludeSyntheticMethods write FExcludeSyntheticMethods;
    property ExcludeBridgeMethods: Boolean read FExcludeBridgeMethods write FExcludeBridgeMethods;
    property DoSUIDCompensation: Boolean read FDoSUIDCompensation write FDoSUIDCompensation;
    property EntryLength: Int64 read GetEntryLength;

    procedure LoadFromFile(const DataInput: IEmmaDataInput);
    procedure WriteToFile(DataOutput: IEmmaDataOutput);
  end;

  TEmmaMetaData = class(TMergable)
  strict private
    FCoverageOptions: TCoverageOptions;
    FHasSourceFileInfo: Boolean;
    FHasLineNumberInfo: Boolean;
    FClassList: TList<TClassDescriptor>;
  protected
    function GetEntryLength: Int64; override;
    function GetEntryType: Byte; override;
  public
    property CoverageOptions: TCoverageOptions read FCoverageOptions;
    property HasSourceFileInfo: Boolean read FHasSourceFileInfo write FHasSourceFileInfo;
    property HasLineNumberInfo: Boolean read FHasLineNumberInfo write FHasLineNumberInfo;
    property ClassList: TList<TClassDescriptor> read FClassList;

    constructor Create;
    destructor Destroy; override;

    function ToString: string; override;
    procedure LoadFromFile(const DataInput: IEmmaDataInput); override;
    procedure WriteToFile(DataOutput: IEmmaDataOutput); override;

    procedure Add(const AClassDescriptor: TClassDescriptor);
  end;

const
  METHOD_NO_LINE_NUMBER_TABLE = $01;
  METHOD_ABSTRACT_OR_NATIVE = $02;
  METHOD_EXCLUDED = $04;
  METHOD_ADDED = $08;
  METHOD_NO_BLOCK_DATA = (
    METHOD_ABSTRACT_OR_NATIVE
    OR METHOD_EXCLUDED
    OR METHOD_ADDED
  );
  METHOD_NO_LINE_DATA = (
    METHOD_NO_LINE_NUMBER_TABLE
    OR METHOD_NO_BLOCK_DATA
  );

implementation

uses
  Math,
  SysUtils,
  StrUtils;

{$region 'TMethodDescriptor'}
destructor TMethodDescriptor.Destroy;
var
  i: Integer;
begin
  for i := 0 to Length(FBlockMap) - 1 do
    SetLength(FBlockMap[i], 0);
  SetLength(FBlockMap, 0);
  SetLength(FBlockSizes, 0);

  inherited Destroy;
end;

function TMethodDescriptor.GetEntryLength: Int64;
var
  i: Integer;
begin
  Result := 0;
  Result := Result + FileHelper.GetUtf8Length(FName);
  Result := Result + FileHelper.GetUtf8Length(FDescriptor);
  Result := Result + SizeOf(FStatus);

  if (FStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    Result := Result + FileHelper.GetEntryLength(FBlockSizes);
    if (FStatus and METHOD_NO_LINE_DATA) = 0 then
    begin
      Result := Result + SizeOf(Integer);
      for i := 0 to High(FBlockSizes) do
        Result := Result + FileHelper.GetEntryLength(FBlockMap[i]);
      Result := Result + SizeOf(FFirstLine);
    end;
  end;
end;

function TMethodDescriptor.ToString: string;
var
  i: Integer;
  j: Integer;
begin
  Result := ' MD[';
  Result := Result + ' name=' + FName;
  Result := Result + ' status=' + IntToStr(FStatus);
  Result := Result + ' firstline=' + IntToStr(FFirstLine);

  for i := 0 to Length(FBlockMap) - 1 do
  begin
    Result := Result + ' Block[ no=' + IntToStr(i);
    Result := Result + ' Lines[';

    for j := 0 to Length(FBlockMap[i]) - 1 do
    begin
      Result := Result + IntToStr(FBlockMap[i][j]);
      if j <> Length(FBlockMap[i]) - 1 then
        Result := Result + ',';
    end;

    Result := Result + ']';
  end;

  Result := Result + ']';
end;

procedure TMethodDescriptor.LoadFromFile(const DataInput: IEmmaDataInput);
var
  i: Integer;
  BlockMapLength: Integer;
begin
  FName := DataInput.ReadUTF;
  FDescriptor := DataInput.ReadUTF;
  FStatus := DataInput.ReadInteger;
  FFirstLine := 0;
  if (FStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    DataInput.ReadIntArray(FBlockSizes);
    if (FStatus and METHOD_NO_LINE_DATA) = 0 then
    begin
      BlockMapLength := DataInput.ReadInteger;
      SetLength(FBlockMap, BlockMapLength);

      for i := 0 to BlockMapLength - 1 do
        DataInput.ReadIntArray(FBlockMap[i]);

      FFirstLine := DataInput.ReadInteger;
    end;
  end;
end;

procedure TMethodDescriptor.SetBlockMapLength(const ALength: Integer);
begin
  SetLength(FBlockMap, ALength);
end;

procedure TMethodDescriptor.SetBlockSizesLength(const ALength: Integer);
begin
  SetLength(FBlockSizes, ALength);
end;

function TMethodDescriptor.FindFirstLine: Integer;
var
  MinValues: TIntegerDynArray;
  I: Integer;
begin
  SetLength(MinValues, Length(FBlockMap));
  for I := Low(FBlockMap) to High(FBlockMap) do
    MinValues[i] := MinIntValue(FBlockMap[i]);
  Result := MinIntValue(MinValues);
end;

procedure TMethodDescriptor.WriteToFile(DataOutput: IEmmaDataOutput);
var
  i: Integer;
begin
  DataOutput.WriteUTF(FName);
  DataOutput.WriteUTF(FDescriptor);
  DataOutput.WriteInteger(FStatus);

  if (FStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    DataOutput.WriteIntArray(FBlockSizes);
    if (FStatus and METHOD_NO_LINE_DATA) = 0 then
    begin
      DataOutput.WriteInteger(Length(FBlockMap));

      for i := 0 to High(FBlockMap) do
        DataOutput.WriteIntArray(FBlockMap[i]);

      FFirstLine := FindFirstLine;
      DataOutput.WriteInteger(FFirstLine);
    end;
  end;
end;
{$endregion 'TMethodDescriptor'}

{$region 'TClassDescriptor'}
constructor TClassDescriptor.Create(
  const AName: string;
  const ASrcFileNameFlag: Integer;
  const ASrcFileName: string;
  const AClassVMName: string;
  const APackageVMName: string);
begin
  inherited Create;

  FMethods := TList<TMethodDescriptor>.Create;

  FName := AName;
  FSrcFileNameFlag := ASrcFileNameFlag;
  if FSrcFileNameFlag <> 0 then
    FSrcFileName := ASrcFileName
  else
    FSrcFileName := '';

  FClassVMName := AClassVMName;
  FPackageVMName := '';
end;

constructor TClassDescriptor.CreateFromFile(const DataInput: IEmmaDataInput);
begin
  inherited Create;

  FMethods := TList<TMethodDescriptor>.Create;
  LoadFromFile(DataInput);
end;

destructor TClassDescriptor.Destroy;
var
  CurrentMethod: TMethodDescriptor;
begin
  for CurrentMethod in FMethods do
    CurrentMethod.Free;

  FMethods.Free;

  inherited Destroy;
end;

procedure TClassDescriptor.LoadFromFile(const DataInput: IEmmaDataInput);
var
  MethodIndex: Integer;
  MethodDescriptor: TMethodDescriptor;
  MethodCount: Integer;
begin
  FClassVMName := DataInput.ReadUTF;
  FPackageVMName := DataInput.ReadUTF;
  FName := DataInput.ReadUTF;
  FStamp := DataInput.ReadInt64;
  FSrcFileNameFlag := DataInput.ReadByte;
  if FSrcFileNameFlag <> 0 then
    FSrcFileName := DataInput.ReadUTF
  else
    FSrcFileName := '';

  MethodCount := DataInput.ReadInteger;
  for MethodIndex := 0 to MethodCount - 1 do
  begin
    MethodDescriptor := TMethodDescriptor.Create;
    MethodDescriptor.LoadFromFile(DataInput);
    FMethods.Add(MethodDescriptor);
  end;
end;

procedure TClassDescriptor.WriteToFile(DataOutput: IEmmaDataOutput);
var
  MethodDescriptor: TMethodDescriptor;
begin
  DataOutput.WriteUTF(FClassVMName);
  DataOutput.WriteUTF(FPackageVMName);
  DataOutput.WriteUTF(FName);
  DataOutput.WriteInt64(FStamp);
  DataOutput.WriteByte(FSrcFileNameFlag);
  if FSrcFileNameFlag <> 0 then
    DataOutput.WriteUTF(FSrcFileName);
  DataOutput.WriteInteger(FMethods.Count);
  for MethodDescriptor in FMethods do
    MethodDescriptor.WriteToFile(DataOutput);
end;

function TClassDescriptor.ToString: string;
var
  MethodDescriptor: TMethodDescriptor;
begin
  Result := 'CD [ name=' + FName;
  Result := Result + ' stamp=' + IntToStr(FStamp);
  for MethodDescriptor in FMethods do
    Result := Result + MethodDescriptor.ToString;
  Result := Result + ']';
end;

function TClassDescriptor.GetEntryLength: Int64;
var
  MethodDescriptor: TMethodDescriptor;
begin
  Result := 0;
  Result := Result + FileHelper.GetUtf8Length(FClassVMName);
  Result := Result + FileHelper.GetUtf8Length(FPackageVMName);
  Result := Result + FileHelper.GetUtf8Length(FName);
  Result := Result + SizeOf(Int64);
  Result := Result + SizeOf(Byte);

  if (FSrcFileNameFlag <> 0) then
    Result := Result + FileHelper.GetUtf8Length(FSrcFileName);

  Result := Result + SizeOf(Integer);

  for MethodDescriptor in FMethods do
    Result := Result + MethodDescriptor.EntryLength;
end;

procedure TClassDescriptor.Add(const AMethodDescriptor: TMethodDescriptor);
begin
  FMethods.Add(AMethodDescriptor);
end;
{$endregion 'TClassDescriptor'}

{$region 'TCoverageOptions'}
function TCoverageOptions.GetEntryLength: Int64;
begin
  Result := SizeOf(Boolean) * 3;
end;

procedure TCoverageOptions.LoadFromFile(const DataInput: IEmmaDataInput);
begin
  FExcludeSyntheticMethods := DataInput.ReadBoolean;
  FExcludeBridgeMethods := DataInput.ReadBoolean;
  FDoSUIDCompensation := DataInput.ReadBoolean;
end;

procedure TCoverageOptions.WriteToFile(DataOutput: IEmmaDataOutput);
begin
  DataOutput.WriteBoolean(FExcludeSyntheticMethods);
  DataOutput.WriteBoolean(FExcludeBridgeMethods);
  DataOutput.WriteBoolean(FDoSUIDCompensation);
end;
{$endregion 'TCoverageOptions'}

{$region 'TEmmaMetaData'}
constructor TEmmaMetaData.Create;
begin
  inherited Create;

  FClassList := TList<TClassDescriptor>.Create;
  FCoverageOptions := TCoverageOptions.Create;
end;

destructor TEmmaMetaData.Destroy;
var
  CurrentClass: TClassDescriptor;
begin
  for CurrentClass in FClassList do
    CurrentClass.Free;

  FClassList.Destroy;
  FCoverageOptions.Free;
  inherited Destroy;
end;

procedure TEmmaMetaData.LoadFromFile(const DataInput: IEmmaDataInput);
var
  ClassDescriptorIndex: Integer;
  ClassDescriptorCount: Integer;
begin
  FCoverageOptions.LoadFromFile(DataInput);
  FHasSourceFileInfo := DataInput.ReadBoolean;
  FHasLineNumberInfo := DataInput.ReadBoolean;
  ClassDescriptorCount := DataInput.ReadInteger;

  for ClassDescriptorIndex := 0 to ClassDescriptorCount - 1 do
    FClassList.Add(TClassDescriptor.CreateFromFile(DataInput));
end;

function TEmmaMetaData.ToString;
var
  ClassDescriptor: TClassDescriptor;
begin
  for ClassDescriptor in FClassList do
  begin
    Result := Result + ' Class:' + ClassDescriptor.Name;
    Result := Result + ClassDescriptor.ToString;
  end;
end;

function TEmmaMetaData.GetEntryLength: Int64;
var
  ClassDescriptor: TClassDescriptor;
begin
  Result := 0;
  Result := Result + FCoverageOptions.EntryLength;
  Result := Result + SizeOf(Boolean);
  Result := Result + SizeOf(Boolean);
  Result := Result + SizeOf(Integer);
  for ClassDescriptor in FClassList do
    Result := Result + ClassDescriptor.EntryLength;
end;

function TEmmaMetaData.GetEntryType: Byte;
begin
  Result := 0;
end;

procedure TEmmaMetaData.WriteToFile(DataOutput: IEmmaDataOutput);
var
  ClassDescriptor: TClassDescriptor;
begin
  FCoverageOptions.WriteToFile(DataOutput);
  DataOutput.WriteBoolean(FHasSourceFileInfo);
  DataOutput.WriteBoolean(FHasLineNumberInfo);
  DataOutput.WriteInteger(FClassList.Count);
  for ClassDescriptor in FClassList do
    ClassDescriptor.WriteToFile(DataOutput);
end;

procedure TEmmaMetaData.Add(const AClassDescriptor: TClassDescriptor);
begin
  FClassList.Add(AClassDescriptor);
end;
{$endregion 'TEmmaMetaData'}

end.
