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

    function getCountedModuleName(count: Integer; filename: string): String;
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

function TEmmaCoverageFile.getCountedModuleName(count: Integer;
  filename: string): String;
var
  ext, start: String;
begin
  start := PathExtractFileNameNoExt(filename);
  ext := ExtractFileExt(filename);
  result := start + IntToStr(count) + ext;
end;

procedure TEmmaCoverageFile.Generate(const ACoverage: ICoverageStats;
  const AModuleInfoList: TModuleList; logMgr: ILogManager);
var
  outFile: File;
  emmafile: TEmmaFile;
  metaemma: TEmmaFile;
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
  currLine: Integer;
  count: Integer;
  covfilename : String;
begin
  try
    logMgr.Log('Generating EMMA file');
    emmafile := TEmmaFile.Create;
    metadata := TEmmaMetaData.Create;
    coverageData := TEmmaCoverageData.Create;
    metadata.fCoverageOptions := TCoverageOptions.Create;
    metadata.fHasSrcFileInfo := true;
    metadata.fHasLineNumberInfo := true;

    moduleIterator := AModuleInfoList.getModuleIterator;
    if (moduleIterator <> nil) then
    begin
      while (moduleIterator.MoveNext) do
      begin
        module := moduleIterator.Current;
        if (module <> nil) then
        begin
          logMgr.Log('Generating EMMA data for module: ' + module.ToString);

          classiter := module.getClassIterator;
          if (classiter <> nil) then
          begin
            count := 0;
            while (classiter.MoveNext) do
            begin
              inc(count);
              classinfo := classiter.Current;
              if (classinfo <> nil) then
              begin
                logMgr.Log('Generating EMMA data for class: ' +
                    classinfo.getClassName());
                classIsCovered := classinfo.getIsCovered();
                modulePrefix := module.getModuleName();
                if (Length(modulePrefix) > 0) then
                begin
                  modulePrefix := modulePrefix + '.';
                end;
                vmStyleModuleName := StringReplace(module.getModuleName(), '.',
                  '/', [rfReplaceAll]);
                fqnClassName := modulePrefix + classinfo.getClassName();
                cd := TClassDescriptor.Create(classinfo.getClassName, 1,
                  module.getModuleFileName(), fqnClassName, vmStyleModuleName);
                methoditer := classinfo.getProcedureIterator;

                setlength(boolarr, classinfo.getProcedureCount());
                methodindex := 0;
                while (methoditer.MoveNext) do
                begin

                  methodinfo := methoditer.Current;
                  logMgr.Log
                    ('Generating EMMA data for method: ' +
                      methodinfo.getName + ' l:' + IntToStr
                      (methodinfo.getNoLines) + ' c:' + IntToStr
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
                    boolarr[methodindex, I] := methodinfo.isLineCovered
                      (currLine);
                    inc(I);
                  end;
                  cd.add(md);
                  inc(methodindex);
                end;
                vmStyleClassName := StringReplace(fqnClassName, '.', '/',
                  [rfReplaceAll]);
                dh := TDataHolder.Create(vmStyleClassName, 0, boolarr);
                if (classIsCovered) then
                  coverageData.add(dh);
                metadata.add(cd);

              end
              else
              begin
                logMgr.Log(
                  'Generating emma file - current class  was null- skipping.');
              end;
            end;
          end
          else
          begin
            logMgr.Log(
              'Generating emma file - no classes, classiter was null- skipping.'
              );
          end;
        end
        else
        begin
          logMgr.Log
            ('Generating emma file - current module was null- skipping.');

        end;
      end;
      if (FCoverageConfiguration.SeparateMeta) then
      begin
        metaemma := TEmmaFile.Create;
        metaemma.add(metadata);
        FileMode := fmOpenReadWrite;
        AssignFile(outFile, PathAppend(FCoverageConfiguration.GetOutputDir(),
            'coverage.em'));
        try
          rewrite(outFile, 1);
          metaemma.write(outFile);
        finally
          CloseFile(outFile);
        end;
        covfilename := 'coverage.ec';
      end
      else
      begin
        emmafile.add(metadata);
        covfilename :='coverage.es';
      end;
      emmafile.add(coverageData);
      FileMode := fmOpenReadWrite;
      AssignFile(outFile, PathAppend(FCoverageConfiguration.GetOutputDir(),
          covfilename));
      try
        rewrite(outFile, 1);
        emmafile.write(outFile);
      finally
        CloseFile(outFile);
      end;
      logMgr.Log('Emma file generated');
    end
    else
    begin
      logMgr.Log(
        'Generating emma file - Module iterator is null- thus no emma file generated.');
    end;
  except
    on eipe: EInvalidPointer do
    begin

      writeln(eipe.ToString);
      writeln(eipe.StackTrace);
    end;

  end;

end;

end.
