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
  TCoverageOptions = class;
  TClassDescriptor = class;

  TEmmaMetaData = class(TMergable)
    fCoverageOptions: TCoverageOptions;
    fHasSrcFileInfo: Boolean;
    fHasLineNumberInfo: Boolean;
    fClassList: TList<TClassDescriptor>;
    constructor Create;
    destructor Destroy; override;
    procedure loadFromFile(var aFile: File); override;
    function ToString(): String; override;
    function getEntryLength(): Int64; override;
    function getEntryType: Byte; override;
    procedure writeToFile(var aFile: File); override;
    procedure add(cd: TClassDescriptor);
  end;

  TCoverageOptions = class
    fExcludeSyntheticMethods: Boolean;
    fExcludeBridgeMethods: Boolean;
    fDoSUIDCompensation: Boolean;

    procedure loadFromFile(var aFile: File);
    function getEntryLength(): Int64;
    procedure writeToFile(var aFile: File);

  end;

  TMethodDescriptor = class;

  TClassDescriptor = class
  private
    fClassVMName: String;
    fPackageVMName: String;
    fName: String;
    fStamp: Int64;
    fSrcFileNameFlag: Byte;
    fSrcFileName: String;
    fMethods: TList<TMethodDescriptor>;
  public
    constructor Create(AName: String; ASrcFileNameFlag: Integer;
      ASrcFileName: String; AClassVMName: String; APackageVMName : String);
    constructor CreateFromFile(var aFile: File);
    destructor Destroy; override;
    procedure loadFromFile(var aFile: File);
    function ToString(): String; override;
    function getEntryLength(): Int64;
    procedure writeToFile(var aFile: File);
    procedure add(AMethodDescriptor: TMethodDescriptor);

  end;

  TMethodDescriptor = class
    fName: String;
    fDescriptor: String;
    fStatus: Integer;
    fBlockMap: array of TIntArray;
    fBlockSizes: TIntArray;
    fFirstLine: Integer;
    procedure loadFromFile(var aFile: File);
    function ToString(): String; override;
    function getEntryLength(): Int64;
    procedure writeToFile(var aFile: File);

  end;

const
  METHOD_NO_LINE_NUMBER_TABLE = $01;

  METHOD_ABSTRACT_OR_NATIVE = $02;

  METHOD_EXCLUDED = $04;

  METHOD_ADDED = $08;

  METHOD_NO_BLOCK_DATA =
    (METHOD_ABSTRACT_OR_NATIVE OR METHOD_EXCLUDED OR METHOD_ADDED);

  METHOD_NO_LINE_DATA = (METHOD_NO_LINE_NUMBER_TABLE OR METHOD_NO_BLOCK_DATA);

implementation

uses sysutils,strutils;

procedure TCoverageOptions.loadFromFile(var aFile: File);
begin
  fExcludeSyntheticMethods := readBoolean(aFile);
  fExcludeBridgeMethods := readBoolean(aFile);
  fDoSUIDCompensation := readBoolean(aFile);
end;

function TCoverageOptions.getEntryLength(): Int64;
begin
  result := sizeof(Boolean) * 3;
end;

procedure TCoverageOptions.writeToFile(var aFile: File);
begin
  writeBoolean(aFile, fExcludeSyntheticMethods);
  writeBoolean(aFile, fExcludeBridgeMethods);
  writeBoolean(aFile, fDoSUIDCompensation);
end;

procedure TMethodDescriptor.loadFromFile(var aFile: File);
var
  i: Integer;
  length: Integer;
begin
  fName := readUTF(aFile);
  fDescriptor := readUTF(aFile);
  fStatus := readInteger(aFile);
  fFirstLine := 0;
  if (fStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    readIntArray(aFile, fBlockSizes);
    if ((fStatus and METHOD_NO_LINE_DATA) = 0) then
    begin
      length := readInteger(aFile);
      setLength(fBlockMap, length);

      for i := 0 to length - 1 do
      begin
        readIntArray(aFile, fBlockMap[i]);
      end;
      fFirstLine := readInteger(aFile);
    end;
  end;

end;

function TMethodDescriptor.getEntryLength: Int64;
var
  size: Int64;
  i: Integer;
begin
  size := 0;
  size := size + getUTF8Length(fName);
  size := size + getUTF8Length(fDescriptor);
  size := size + sizeof(fStatus);
  if (fStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    size := size + FileHelper.getEntryLength(fBlockSizes);
    if ((fStatus and METHOD_NO_LINE_DATA) = 0) then
    begin
      size := size + sizeof(Integer);
      for i := 0 to High(fBlockSizes) do
      begin
        size := size + FileHelper.getEntryLength(fBlockMap[i]);
      end;
      size := size + sizeof(fFirstLine);
    end;
  end;
  result := size;

end;

procedure TMethodDescriptor.writeToFile(var aFile: File);
var
  i: Integer;

begin
  writeUTF(aFile, fName);
  writeUTF(aFile, fDescriptor);
  writeInteger(aFile, fStatus);
  if (fStatus and METHOD_NO_BLOCK_DATA) = 0 then
  begin
    writeIntArray(aFile, fBlockSizes);
    if ((fStatus and METHOD_NO_LINE_DATA) = 0) then
    begin
      writeInteger(aFile, length(fBlockMap));

      for i := 0 to High(fBlockMap) do
      begin
        writeIntArray(aFile, fBlockMap[i]);
      end;
      writeInteger(aFile, fFirstLine);
    end;
  end;

end;

function TMethodDescriptor.toString: String;
var
  i: Integer;
  j: Integer;
begin

  result := ' MD[';
  result := result + ' name=' + fName;
  result := result + ' status=' + IntToStr(fStatus);
  result := result + ' firstline=' + IntToStr(fFirstLine);
  for i := 0 to length(fBlockMap) - 1 do
  begin
    result := result + ' Block[ no=' + IntToStr(i);
    result := result + ' Lines[';

    for j := 0 to length(fBlockMap[i]) - 1 do
    begin
      result := result + IntToStr(fBlockMap[i][j]);
      if (j <> length(fBlockMap[i]) - 1) then
        result := result + ',';
    end;
    result := result + ']';
  end;

  result := result + ']';
end;

constructor TClassDescriptor.Create(AName: String; ASrcFileNameFlag: Integer;
  ASrcFileName: String; AClassVMName: String; APackageVMName : String);
begin
  fMethods := TList<TMethodDescriptor>.Create;
  fName := AName;
  fSrcFileNameFlag := ASrcFileNameFlag;
  if (fSrcFileNameFlag <>0) then fSrcFileName := ASrcFileName;
  fClassVMName := AClassVMName;
  fPackageVMName := APackageVMName;
end;

constructor TClassDescriptor.CreateFromFile(var aFile: File);
begin
  fMethods := TList<TMethodDescriptor>.Create;
  loadFromFile(aFile);
end;

destructor TClassDescriptor.Destroy;
begin
  fMethods.Free;
end;

procedure TClassDescriptor.loadFromFile(var aFile: File);
var
  i: Integer;
  md: TMethodDescriptor;
  l: Integer;
begin
  fClassVMName := readUTF(aFile);
  fPackageVMName := readUTF(aFile);
  fName := readUTF(aFile);
  fStamp := readInt64(aFile);
  fSrcFileNameFlag := readByte(aFile);
  if (fSrcFileNameFlag <> 0) then
    fSrcFileName := readUTF(aFile);
  l := readInteger(aFile);
  for i := 0 to l - 1 do
  begin
    md := TMethodDescriptor.Create;
    md.loadFromFile(aFile);
    fMethods.add(md);
  end;
end;

procedure TClassDescriptor.writeToFile(var aFile: File);
var
  md: TMethodDescriptor;
begin
  writeUTF(aFile, fClassVMName);
  writeUTF(aFile, fPackageVMName);
  writeUTF(aFile, fName);
  writeInt64(aFile, fStamp);
  writeByte(aFile, fSrcFileNameFlag);
  if (fSrcFileNameFlag <> 0) then
    writeUTF(aFile, fSrcFileName);
  writeInteger(aFile, fMethods.Count);
  for md in fMethods do
  begin
    md.writeToFile(aFile);
  end;
end;

function TClassDescriptor.toString(): String;
var
  mthd: TMethodDescriptor;
begin
  result := 'CD [ name=' + fName;
  result := ' stamp=' + IntToStr(fStamp);
  for mthd in fMethods do
  begin
    result := result + mthd.toString();
  end;
  result := result + ']';
end;

function TClassDescriptor.getEntryLength(): Int64;
var
  size: Int64;
  mthd: TMethodDescriptor;
begin
  size := 0;
  size := size + getUTF8Length(fClassVMName);
  size := size + getUTF8Length(fPackageVMName);
  size := size + getUTF8Length(fName);
  size := size + sizeof(Int64);
  size := size + sizeof(Byte);

  if (fSrcFileNameFlag <> 0) then
    size := size + getUTF8Length(fSrcFileName);

  size := size + sizeof(Integer);

  for mthd in fMethods do
  begin
    size := size + mthd.getEntryLength();
  end;
  result := size;
end;

procedure TClassDescriptor.add(AMethodDescriptor: TMethodDescriptor);
begin
  fMethods.add(AMethodDescriptor);
end;

constructor TEmmaMetaData.Create;
begin
  fClassList := TList<TClassDescriptor>.Create();
end;

destructor TEmmaMetaData.Destroy;
begin
  fClassList.Destroy;
end;

procedure TEmmaMetaData.loadFromFile(var aFile: File);
var
  i: Integer;
  cd: TClassDescriptor;
  size: Integer;
begin
  fCoverageOptions := TCoverageOptions.Create;
  fCoverageOptions.loadFromFile(aFile);
  fHasSrcFileInfo := readBoolean(aFile);
  fHasLineNumberInfo := readBoolean(aFile);
  size := readInteger(aFile);
  for i := 0 to size - 1 do
  begin
    cd := TClassDescriptor.CreateFromFile(aFile);
    cd.loadFromFile(aFile);
    fClassList.add(cd);
  end;

end;

function TEmmaMetaData.toString;
var
  className: String;
  cd: TClassDescriptor;
begin
  for cd in fClassList do
  begin
    if (cd <> nil) then
    begin
      result := result + ' Class:' + className;
      result := result + cd.toString();
    end;
  end;
end;

function TEmmaMetaData.getEntryLength(): Int64;

var
  size: Int64;
  entryEnum: TList<MetaDataUnit.TClassDescriptor>.TEnumerator;
  entry: TClassDescriptor;
begin
  size := 0;
  size := size + fCoverageOptions.getEntryLength();
  size := size + sizeof(Boolean);
  size := size + sizeof(Boolean);
  size := size + sizeof(Integer);
  entryEnum := fClassList.GetEnumerator();
  while (entryEnum.MoveNext) do
  begin
    entry := entryEnum.Current;

    size := size + entry.getEntryLength();
  end;
  result := size;
end;

function TEmmaMetaData.getEntryType: Byte;
begin
  result := 0;
end;

procedure TEmmaMetaData.writeToFile(var aFile: File);
var
  entryEnum: TList<MetaDataUnit.TClassDescriptor>.TEnumerator;
  entry: TClassDescriptor;

begin
  fCoverageOptions.writeToFile(aFile);
  writeBoolean(aFile, fHasSrcFileInfo);
  writeBoolean(aFile, fHasLineNumberInfo);
  writeInteger(aFile, fClassList.Count);
  entryEnum := fClassList.GetEnumerator();
  while (entryEnum.MoveNext) do
  begin
    entry := entryEnum.Current;
    entry.writeToFile(aFile);
  end;
end;

procedure TEmmaMetaData.add(cd: TClassDescriptor);
begin
  fClassList.add(cd);
end;

end.
