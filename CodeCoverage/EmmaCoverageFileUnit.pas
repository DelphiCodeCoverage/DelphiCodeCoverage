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
  ClassInfoUnit, I_CoverageConfiguration, I_LogManager;

type
  TEmmaCoverageFile = class(TInterfacedObject, IReport)
  private
    FCoverageConfiguration: ICoverageConfiguration;

  public
    Constructor Create(const ACoverageConfiguration: ICoverageConfiguration);
    procedure Generate(const ACoverage: ICoverageStats;
      const AModuleInfoList: TModuleList; logMgr: ILogManager);
  end;

implementation

uses
  SysUtils,
  JclFileUtils, EmmaDataFile, metadataunit, coveragedataunit,
  Generics.Collections,
  I_BreakPoint, breakpoint, FileHelper;

{ TEmmaCoverageFile }

constructor TEmmaCoverageFile.Create(const ACoverageConfiguration
    : ICoverageConfiguration);
begin
  inherited Create;
  FCoverageConfiguration := ACoverageConfiguration;
end;

procedure TEmmaCoverageFile.Generate(const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList; logMgr: ILogManager);
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
  bkptiter: TEnumerator<Integer>;
  boolarr: TMultiBooleanArray;
  methodindex: Integer;
  classIsCovered: Boolean;
  modulePrefix: String;
  vmStyleModuleName: String;
  vmStyleClassName: String;
  fqnClassName: String;
  currLine : Integer;
begin
  try
    logMgr.Log('Generating EMMA file');
    emmafile := TEmmaFile.Create;
    metadata := TEmmaMetaData.Create;
    coverageData := TEmmaCoverageData.Create;
    moduleIterator := AModuleInfoList.getModuleIterator;
    while (moduleIterator.MoveNext) do
    begin
      module := moduleIterator.Current;
      logMgr.Log('Generating EMMA data for module: ' + module.ToString);

      metadata.fCoverageOptions := TCoverageOptions.Create;
      metadata.fHasSrcFileInfo := true;
      metadata.fHasLineNumberInfo := true;
      classiter := module.getClassIterator;
      while (classiter.MoveNext) do
      begin
        classinfo := classiter.Current;
        logMgr.Log('Generating EMMA data for class: ' + classinfo.getClassName()
          );
        classIsCovered := classinfo.getIsCovered();
        modulePrefix := module.getModuleName();
        if (Length(modulePrefix) > 0) then
        begin
          modulePrefix := modulePrefix + '.';
        end;
        vmStyleModuleName := StringReplace(module.getModuleName(), '.', '/',
          [rfReplaceAll]);
        fqnClassName := modulePrefix + classinfo.getClassName();
        cd := TClassDescriptor.Create(classinfo.getClassName, 1,
          module.getModuleFileName, fqnClassName, vmStyleModuleName);
        methoditer := classinfo.getProcedureIterator;

        setlength(boolarr, classinfo.getProcedureCount());
        methodindex := 0;
        while (methoditer.MoveNext) do
        begin

          methodinfo := methoditer.Current;
          logMgr.Log('Generating EMMA data for method: ' + methodinfo.getName +
              ' l:' + IntToStr(methodinfo.getNoLines) + ' c:' + IntToStr
              (methodinfo.getCoveredLines));

          md := TMethodDescriptor.Create;
          md.fName := methodinfo.getName;
          md.fDescriptor := '()V';
          md.fStatus := 0;
          bkptiter := methodinfo.getLineIterator;
          setlength(md.fBlockSizes, methodinfo.getNoLines);
          for I := 0 to methodinfo.getNoLines() - 1 do
          begin
            md.fBlockSizes[I] := 1;
          end;

          I := 0;
          setlength(md.fBlockMap, methodinfo.getNoLines);
          setlength(boolarr[methodindex], methodinfo.getNoLines);
          while (bkptiter.MoveNext) do
          begin
            currLine := bkptiter.Current;

            setlength(md.fBlockMap[I], 1);
            md.fBlockMap[I, 0] := currLine;
            boolarr[methodindex, I] := methodInfo.isLineCovered(currLine);
            inc(I);
          end;
          cd.add(md);
          inc(methodindex);
        end;
      end;
      vmStyleClassName := StringReplace(fqnClassName, '.', '/', [rfReplaceAll]);
      dh := TDataHolder.Create(vmStyleClassName, 0, boolarr);
      if (classIsCovered) then
        coverageData.add(dh);
      metadata.add(cd);
    end;

    emmafile.add(metadata);
    emmafile.add(coverageData);
    FileMode := fmOpenReadWrite;
    AssignFile(outFile, PathAppend(FCoverageConfiguration.GetOutputDir(),
        'coverage.es'));
    try
      rewrite(outFile, 1);
      emmafile.write(outFile);
    finally
      CloseFile(outFile);
    end;
    logMgr.Log('Emma file generated');
  except
    on eipe: EInvalidPointer do
    begin

      writeln(eipe.ToString);
      writeln(eipe.StackTrace);
    end;

  end;

end;

end.
