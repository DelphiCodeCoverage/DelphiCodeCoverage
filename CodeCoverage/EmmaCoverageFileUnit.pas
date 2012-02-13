(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit EmmaCoverageFileUnit;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  I_Report,
  I_CoverageStats,
  JclSimpleXml,
  ClassInfoUnit,I_CoverageConfiguration;

type
  TEmmaCoverageFile = class(TInterfacedObject, IReport)
   private
    FCoverageConfiguration : ICoverageConfiguration;

  public
    Constructor Create(const ACoverageConfiguration : ICoverageConfiguration);
    procedure Generate(const ACoverage: ICoverageStats;
      const AModuleInfoList: TModuleList);
  end;

implementation

uses
  SysUtils,
  JclFileUtils, EmmaDataFile, metadataunit, coveragedataunit, Generics.Collections,
  I_BreakPoint, breakpoint, FileHelper;

{ TEmmaCoverageFile }


constructor TEmmaCoverageFile.Create(const ACoverageConfiguration: ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

procedure TEmmaCoverageFile.Generate(const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList);
var
  outFile: File;
  emmafile: TEmmaFile;
  metadata: TEmmaMetaData;
  coverageData: TEmmaCoverageData;
  moduleIterator: TEnumerator<TModuleInfo>;
  module: TModuleInfo;
  cd: TClassDescriptor;
  md: TMethodDescriptor;
  I: Integer;
  dh: TDataHolder;
  classiter: TEnumerator<TClassInfo>;
  classinfo: TClassInfo;
  methoditer: TEnumerator<TProcedureInfo>;
  methodinfo: TProcedureInfo;
  bkpt: IBreakPoint;
  bkptiter: TEnumerator<IBreakPoint>;
  boolarr: TMultiBooleanArray;
  methodindex: Integer;
begin

  emmafile := TEmmaFile.create;
  metadata := TEmmaMetaData.create;
  coverageData := TEmmaCoverageData.create;
  moduleIterator := AModuleInfoList.getModuleIterator;
  while (moduleIterator.MoveNext) do
  begin
    module := moduleIterator.Current;
    metadata.fCoverageOptions := TCoverageOptions.create;
    metadata.fHasSrcFileInfo := true;
    metadata.fHasLineNumberInfo := true;
    classiter := module.getClassIterator;
    while (classiter.MoveNext) do
    begin
      classinfo := classiter.Current;
      cd := TClassDescriptor.create(classinfo.getClassName, 1, module.getModuleFileName, classinfo.getClassName);
      methoditer := classinfo.getProcedureIterator;
      setlength(boolarr, classinfo.getProcedureCount());
      methodindex := 0;
      while (methoditer.MoveNext) do
      begin
        methodinfo := methoditer.Current;
        md := TMethodDescriptor.create;
        md.fName := methodinfo.getName;
        md.fDescriptor := '()V';
        md.fStatus := 0;
        bkptiter := methodinfo.getBreakPointIterator;
        setlength(md.fBlockSizes, methodinfo.getNoLines);
        for I := 0 to methodinfo.getNoLines() do
        begin
          md.fBlockSizes[I] := 1;
        end;

        I := 0;
        setlength(md.fBlockMap, methodinfo.getNoLines);
        setlength(boolarr[methodindex], methodinfo.getNoLines);
        while (bkptiter.MoveNext) do
        begin
          bkpt := bkptiter.Current;
          setlength(md.fBlockMap[I], 1);
          md.fBlockMap[I, 0] := bkpt.DetailByIndex(0).Line;
          boolarr[methodindex, I] := bkpt.Covered;
          inc(I);
        end;
        cd.add(md);
        inc(methodindex);
      end;
      dh := TDataHolder.create(classinfo.getClassName(), 0, boolarr);
      coverageData.add(dh);
      metadata.add(cd);
    end;
  end;

  emmafile.add(metadata);
  emmafile.add(coverageData);
  FileMode := fmOpenReadWrite;
  AssignFile(outFile, PathAppend(FCoverageConfiguration.GetOutputDir(), 'coverage.es'));
  try
    rewrite(outFile, 1);
    emmafile.write(outFile);
  finally
    CloseFile(outFile);
  end;

end;

end.
