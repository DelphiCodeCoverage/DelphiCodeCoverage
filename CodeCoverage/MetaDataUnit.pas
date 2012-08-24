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

uses MergableUnit, Generics.Collections, FileHelper;

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
  public
    property Name: string read FName write FName;
    property Descriptor: string read FDescriptor write FDescriptor;
    property Status: Integer read FStatus write FStatus;
    property BlockMap: TIntArrays read FBlockMap write FBlockMap;
    property BlockSizes: TIntArray read FBlockSizes write FBlockSizes;
    property FirstLine: Integer read FFirstLine write FFirstLine;
    property EntryLength: Int64 read GetEntryLength;

    function ToString: string; override;
    procedure LoadFromFile(var AFile: File);
    procedure WriteToFile(var AFile: File);
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

    constructor CreateFromFile(var AFile: File);
    destructor Destroy; override;

    function ToString: string; override;

    procedure LoadFromFile(var AFile: File);
    procedure WriteToFile(var AFile: File);
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

    procedure LoadFromFile(var AFile: File);
    procedure WriteToFile(var AFile: File);
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
    procedure LoadFromFile(var AFile: File); override;
    procedure WriteToFile(var AFile: File); override;

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
  SysUtils,
  StrUtils;

{$region 'TMethodDescriptor'}
function TMethodDescriptor.GetEntryLength: Int64;
var
  i: Integer;
begin
  Result := 0;
  Result := Result + FileHelper.getUTF8Length(FName);
  Result := Result + FileHelper.getUTF8Length(FDescriptor);
  Result := Result + SizeOf(FStatus);

  if (FStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    Result := Result + FileHelper.getEntryLength(FBlockSizes);
    if (FStatus and METHOD_NO_LINE_DATA) = 0 then
    begin
      Result := Result + SizeOf(Integer);
      for i := 0 to High(FBlockSizes) do
        Result := Result + FileHelper.getEntryLength(FBlockMap[i]);
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

procedure TMethodDescriptor.LoadFromFile(var AFile: File);
var
  i: Integer;
  BlockMapLength: Integer;
begin
  FName := FileHelper.readUTF(AFile);
  FDescriptor := FileHelper.readUTF(AFile);
  FStatus := FileHelper.readInteger(AFile);
  FFirstLine := 0;
  if (FStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    FileHelper.readIntArray(AFile, FBlockSizes);
    if (FStatus and METHOD_NO_LINE_DATA) = 0 then
    begin
      BlockMapLength := FileHelper.readInteger(aFile);
      SetLength(FBlockMap, BlockMapLength);

      for i := 0 to BlockMapLength - 1 do
        FileHelper.readIntArray(AFile, FBlockMap[i]);

      FFirstLine := FileHelper.readInteger(AFile);
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

procedure TMethodDescriptor.WriteToFile(var AFile: File);
var
  i: Integer;
begin
  FileHelper.writeUTF(AFile, FName);
  FileHelper.writeUTF(AFile, FDescriptor);
  FileHelper.writeInteger(AFile, FStatus);

  if (FStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    FileHelper.writeIntArray(AFile, FBlockSizes);
    if (FStatus and METHOD_NO_LINE_DATA) = 0 then
    begin
      FileHelper.writeInteger(AFile, Length(FBlockMap));

      for i := 0 to High(FBlockMap) do
        FileHelper.writeIntArray(AFile, FBlockMap[i]);

      FileHelper.writeInteger(AFile, FFirstLine);
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
  FPackageVMName := APackageVMName;
end;

constructor TClassDescriptor.CreateFromFile(var AFile: File);
begin
  inherited Create;

  FMethods := TList<TMethodDescriptor>.Create;
  LoadFromFile(AFile);
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

procedure TClassDescriptor.LoadFromFile(var AFile: File);
var
  MethodIndex: Integer;
  MethodDescriptor: TMethodDescriptor;
  MethodCount: Integer;
begin
  FClassVMName := FileHelper.readUTF(AFile);
  FPackageVMName := FileHelper.readUTF(AFile);
  FName := FileHelper.readUTF(AFile);
  FStamp := FileHelper.readInt64(AFile);
  FSrcFileNameFlag := FileHelper.readByte(AFile);
  if FSrcFileNameFlag <> 0 then
    FSrcFileName := FileHelper.readUTF(AFile)
  else
    FSrcFileName := '';

  MethodCount := FileHelper.readInteger(AFile);
  for MethodIndex := 0 to MethodCount - 1 do
  begin
    MethodDescriptor := TMethodDescriptor.Create;
    MethodDescriptor.LoadFromFile(AFile);
    FMethods.Add(MethodDescriptor);
  end;
end;

procedure TClassDescriptor.WriteToFile(var AFile: File);
var
  MethodDescriptor: TMethodDescriptor;
begin
  FileHelper.writeUTF(AFile, FClassVMName);
  FileHelper.writeUTF(AFile, FPackageVMName);
  FileHelper.writeUTF(AFile, FName);
  FileHelper.writeInt64(AFile, FStamp);
  FileHelper.writeByte(AFile, FSrcFileNameFlag);
  if FSrcFileNameFlag <> 0 then
    FileHelper.writeUTF(AFile, FSrcFileName);
  FileHelper.writeInteger(AFile, FMethods.Count);
  for MethodDescriptor in FMethods do
    MethodDescriptor.WriteToFile(AFile);
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
  Result := Result + FileHelper.getUTF8Length(FClassVMName);
  Result := Result + FileHelper.getUTF8Length(FPackageVMName);
  Result := Result + FileHelper.getUTF8Length(FName);
  Result := Result + SizeOf(Int64);
  Result := Result + SizeOf(Byte);

  if (FSrcFileNameFlag <> 0) then
    Result := Result + FileHelper.getUTF8Length(FSrcFileName);

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

procedure TCoverageOptions.LoadFromFile(var AFile: File);
begin
  FExcludeSyntheticMethods := FileHelper.readBoolean(AFile);
  FExcludeBridgeMethods := FileHelper.readBoolean(AFile);
  FDoSUIDCompensation := FileHelper.readBoolean(AFile);
end;

procedure TCoverageOptions.WriteToFile(var AFile: File);
begin
  FileHelper.writeBoolean(AFile, FExcludeSyntheticMethods);
  FileHelper.writeBoolean(AFile, FExcludeBridgeMethods);
  FileHelper.writeBoolean(AFile, FDoSUIDCompensation);
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

procedure TEmmaMetaData.LoadFromFile(var AFile: File);
var
  ClassDescriptorIndex: Integer;
  ClassDescriptorCount: Integer;
begin
  FCoverageOptions.LoadFromFile(AFile);
  FHasSourceFileInfo := FileHelper.readBoolean(AFile);
  FHasLineNumberInfo := FileHelper.readBoolean(AFile);
  ClassDescriptorCount := FileHelper.readInteger(AFile);

  for ClassDescriptorIndex := 0 to ClassDescriptorCount - 1 do
    FClassList.Add(TClassDescriptor.CreateFromFile(AFile));
end;

function TEmmaMetaData.ToString;
var
  LClassName: String;
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

procedure TEmmaMetaData.WriteToFile(var AFile: File);
var
  ClassDescriptor: TClassDescriptor;
begin
  FCoverageOptions.WriteToFile(AFile);
  FileHelper.writeBoolean(AFile, FHasSourceFileInfo);
  FileHelper.writeBoolean(AFile, FHasLineNumberInfo);
  FileHelper.writeInteger(AFile, FClassList.Count);
  for ClassDescriptor in FClassList do
    ClassDescriptor.writeToFile(AFile);
end;

procedure TEmmaMetaData.Add(const AClassDescriptor: TClassDescriptor);
begin
  FClassList.Add(AClassDescriptor);
end;
{$endregion 'TEmmaMetaData'}

end.
