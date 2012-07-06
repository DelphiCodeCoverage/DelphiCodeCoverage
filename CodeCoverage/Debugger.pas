(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren and Nick Ring *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit Debugger;

interface

{$INCLUDE CodeCoverage.inc}

uses
  Classes,
  JclDebug,
  JwaWinBase,
  JwaWinType,
  JwaImageHlp,
  I_Debugger,
  I_DebugProcess,
  I_DebugModule,
  I_BreakPointList,
  I_CoverageConfiguration,
  I_CoverageStats,
  I_LogManager,
  ClassInfoUnit,
  ModuleNameSpaceUnit;

type
  TDebugger = class(TInterfacedObject, IDebugger)
  private
    FJCLMapScanner: TJCLMapScanner;
    FDebugProcess: IDebugProcess;
    FProcessID: DWORD;
    FBreakPointList: IBreakPointList;
    FCoverageConfiguration: ICoverageConfiguration;
    FCoverageStats: ICoverageStats;
    FLogManager: ILogManager;
    FModuleList: TModuleList;

    function AddressFromVA(const AVA: DWORD; const module: HMODULE): Pointer;
{$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
    function VAFromAddress(const AAddr: Pointer; const module: HMODULE): DWORD;
{$IFDEF SUPPORTS_INLINE} inline; {$ENDIF}
    procedure AddBreakPoints(const AModuleList: TStrings;
      const module: IDebugModule; const mapScanner: TJCLMapScanner;
      mns: TModuleNameSpace = nil; uns: TUnitNameSpace = nil);

    procedure Debug();
    function StartProcessToDebug(const AExeFileName: string): Boolean;

    procedure ProcessDebugEvents();

    procedure HandleExceptionDebug(const ADebugEvent: DEBUG_EVENT;
      var AContProcessEvents: Boolean; var ADebugEventHandlingResult: DWORD);
    procedure HandleCreateProcess(const ADebugEvent: DEBUG_EVENT);
    procedure HandleCreateThread(const ADebugEvent: DEBUG_EVENT);
    procedure HandleExitProcess(const ADebugEvent: DEBUG_EVENT;
      var AContProcessEvents: Boolean);
    procedure HandleExitThread(const ADebugEvent: DEBUG_EVENT);
    procedure HandleLoadDLL(const ADebugEvent: DEBUG_EVENT);
    procedure HandleOutputDebugString(const ADebugEvent: DEBUG_EVENT);
    procedure HandleUnLoadDLL(const ADebugEvent: DEBUG_EVENT);
    procedure HandleRip(const ADebugEvent: DEBUG_EVENT);

    procedure LogStackFrame(const ADebugEvent: DEBUG_EVENT);

    procedure ProcedureReport();

    procedure PrintUsage;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start();
  end;

function RealReadFromProcessMemory(const AhProcess: THANDLE;
  const AqwBaseAddress: DWORD64; const AlpBuffer: Pointer;
  const ASize: DWORD; var ANumberOfBytesRead: DWORD): BOOL; stdcall;

implementation

uses
  SysUtils,
  JwaNtStatus,
  JwaWinNT,
{$IFDEF madExcept}
  madExcept,
{$ENDIF madExcept}
  BreakPoint,
  BreakPointList,
  CommandLineProvider,
  CoverageConfiguration,
  CoverageReport,
  CoverageStats,
  DebugProcess,
  DebugThread,
  LogManager,
  LoggerTextFile,
  LoggerAPI,
  XMLCoverageReport,
  I_BreakPoint,
  I_DebugThread,
  I_Report,
  EmmaCoverageFileUnit,
  DebugModule,
  JclPEImage,
  JclFileUtils;

function RealReadFromProcessMemory(const AhProcess: THANDLE;
  const AqwBaseAddress: DWORD64; const AlpBuffer: Pointer;
  const ASize: DWORD; var ANumberOfBytesRead: DWORD): BOOL; stdcall;
var
  st: DWORD;
begin
  Result := JwaWinBase.ReadProcessMemory(AhProcess, Pointer(AqwBaseAddress),
    AlpBuffer, ASize, @st);
  ANumberOfBytesRead := st;
end;

constructor TDebugger.Create;
begin
  inherited;

  FBreakPointList := TBreakPointList.Create;
  FCoverageConfiguration := TCoverageConfiguration.Create
    (TCommandLineProvider.Create);

  FCoverageStats := TCoverageStats.Create('', nil);

  FLogManager := TLogManager.Create;
  FModuleList := TModuleList.Create;
end;

destructor TDebugger.Destroy;
begin
  // FJCLMapScanner.Free;

  FCoverageConfiguration := nil;
  FDebugProcess := nil;
  FBreakPointList := nil;
  FCoverageStats := nil;
  FLogManager := nil;

  inherited;
end;

procedure TDebugger.PrintUsage();
begin
  WriteLn('Usage:CodeCoverage.exe [switches]');
  WriteLn('List of switches:');
  // --------------------------------------------------------------------------
  WriteLn('');
  WriteLn('Mandatory switches:');
  WriteLn(I_CoverageConfiguration.cPARAMETER_EXECUTABLE +
      ' executable.exe   -- the executable to run');
  WriteLn('or');
  WriteLn(I_CoverageConfiguration.cPARAMETER_DPROJ +
      ' Project.dproj -- Delphi project file');
  WriteLn('');
  WriteLn('Optional switches:');
  WriteLn(I_CoverageConfiguration.cPARAMETER_MAP_FILE +
      ' mapfile.map      -- the mapfile to use');
  WriteLn(I_CoverageConfiguration.cPARAMETER_UNIT +
      ' unit1 unit2 etc  -- a list of units to create reports for');
  WriteLn(I_CoverageConfiguration.cPARAMETER_EXCLUDE_SOURCE_MASK +
      ' mask1 mask2 etc  -- a list of file masks to exclude from list of units'
    );
  WriteLn(I_CoverageConfiguration.cPARAMETER_UNIT_FILE +
      ' filename        -- a file containing a list of units to create');
  WriteLn('                       reports for - one unit per line');
  WriteLn(I_CoverageConfiguration.cPARAMETER_SOURCE_DIRECTORY +
      ' directory       -- the directory where the project file is located.');
  WriteLn(
    '                       This is added as the first entry of the search');
  WriteLn('                       path - default is current directory');
  WriteLn(I_CoverageConfiguration.cPARAMETER_OUTPUT_DIRECTORY +
      ' directory       -- the output directory where reports shall be');
  WriteLn('                       generated - default is current directory');
  WriteLn(I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER +
      ' param param2 etc -- a list of parameters to be passed to the');
  WriteLn('                       application. Escape character:' +
      I_CoverageConfiguration.cESCAPE_CHARACTER);
  WriteLn(I_CoverageConfiguration.cPARAMETER_LOGGING_TEXT +
      ' [filename]      -- Enable text logging, specifying filename. Default');
  WriteLn('                       file name is:' +
      I_CoverageConfiguration.cDEFULT_DEBUG_LOG_FILENAME);
  WriteLn(I_CoverageConfiguration.cPARAMETER_LOGGING_WINAPI +
      '               -- Use WinAPI OutputDebugString for debug');
  WriteLn(I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE +
      '                -- include file prefixes. This stops "Common.Encodings"'
    );
  WriteLn('                       being converted to "Common"');
  WriteLn(I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE +
      '                -- exclude file prefixes. Coverts "Common.Encodings.pas"'
    );
  WriteLn('                       to "Common.Encodings" - default');
  WriteLn(I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS +
      ' directories     -- the directory(s) where source code is located -');
  WriteLn('                       default is current directory');
  WriteLn(I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE +
      ' filename       -- a file containing a list of source path(s) to');
  WriteLn('                       check for any units to report on');
  WriteLn(I_CoverageConfiguration.cPARAMETER_EMMA_OUTPUT +
      '               -- Output emma coverage file as coverage.es in the output directory');
  WriteLn(I_CoverageConfiguration.cPARAMETER_XML_OUTPUT +
      '                -- Output xml report as CodeCoverage_Summary.xml in the output directory');
  WriteLn(I_CoverageConfiguration.cPARAMETER_HTML_OUTPUT +
      '               -- Output html report as CodeCoverage_Summary.html in the output directory');
  WriteLn(I_CoverageConfiguration.cPARAMETER_MODULE_NAMESPACE +
      ' name dll [dll2]   -- Create a separate namespace with the given name for the listed dll:s.');
  WriteLn(I_CoverageConfiguration.cPARAMETER_UNIT_NAMESPACE +
      ' dll_or_exe unitname [unitname2]   -- Create a separate namespace (the namespace name will be the name of the module without extension) *ONLY* for the listed units within the module.');

end;

function TDebugger.VAFromAddress(const AAddr: Pointer;
  const module: HMODULE): DWORD;
begin
  Result := DWORD_PTR(AAddr) - module - $1000;
end;

function TDebugger.AddressFromVA(const AVA: DWORD;
  const module: HMODULE): Pointer;
begin
  Result := Pointer(DWORD_PTR(AVA + module + $1000));
end;

procedure TDebugger.Start();
var
  reason: String;
begin
  try
    FCoverageConfiguration.ParseCommandLine();

    if FCoverageConfiguration.IsComplete(reason) then
    begin
      if (FCoverageConfiguration.GetDebugLogFile() <> '') then
        FLogManager.AddLogger('Textual',
          TLoggerTextFile.Create(FCoverageConfiguration.GetDebugLogFile()));

      if (FCoverageConfiguration.UseApiDebug) then
        FLogManager.AddLogger('WinAPI', TLoggerAPI.Create());

      Debug();
    end
    else
    begin
      WriteLn('The configuration was incomplete due to the following error:');
      WriteLn(reason);
      PrintUsage();
    end;
  except
    on e: EConfigurationException do
    begin
      WriteLn('Exception parsing the command line:' + e.message);
      PrintUsage();
    end;
    on e: Exception do
    begin
      WriteLn(e.ClassName, ': ', e.message);
{$IFDEF madExcept}
      HandleException(etNormal, e);
{$ENDIF madExcept}
    end;
  end;
end;

procedure TDebugger.ProcedureReport;
var
  csModule: ICoverageStats;
  csUnit: ICoverageStats;
  lpBreakPoints: Integer;
  lpDetails: Integer;
  BreakPoint: IBreakPoint;
  BreakPointDetail: TBreakPointDetail;
  CoverageReport: IReport; // TCoverageReport;
  XMLCoverageReport: IReport; // TXMLCoverageReport;
  EmmaFile: IReport;
begin
  csModule := nil;
  csUnit := nil;

  for lpBreakPoints := 0 to Pred(FBreakPointList.BreakPointCount) do
  begin
    BreakPoint := FBreakPointList.BreakPoint(lpBreakPoints);

    for lpDetails := 0 to Pred(BreakPoint.DetailCount) do
    begin
      BreakPointDetail := BreakPoint.DetailByIndex(lpDetails);

      if (csModule = nil) or (csModule.GetName <> BreakPointDetail.ModuleName)
        then
      begin
        csUnit := nil;
        csModule := FCoverageStats.GetCoverageReport
          (BreakPointDetail.ModuleName);
      end;

      if (csUnit = nil) or (csUnit.GetName <> BreakPointDetail.UnitName) then
      begin
        csUnit := csModule.GetCoverageReport(BreakPointDetail.UnitName);
      end;

      if not csUnit.AlreadyCovered(BreakPointDetail.Line) then
        csUnit.AddLineCoverage(BreakPointDetail.Line, BreakPoint.Covered);
    end;
  end;

  FCoverageStats.CalculateStatistics();

  if (FCoverageConfiguration.HtmlOutput) then
  begin
    CoverageReport := TCoverageReport.Create(FCoverageConfiguration);
    CoverageReport.Generate(FCoverageStats, FModuleList);
  end;
  if (FCoverageConfiguration.XmlOutput) then
  begin
    XMLCoverageReport := TXMLCoverageReport.Create(FCoverageConfiguration);
    XMLCoverageReport.Generate(FCoverageStats, FModuleList);
  end;
  if (FCoverageConfiguration.EmmaOutput) then
  begin
    EmmaFile := TEmmaCoverageFile.Create(FCoverageConfiguration);
    EmmaFile.Generate(FCoverageStats, FModuleList);
  end;
end;

function TDebugger.StartProcessToDebug(const AExeFileName: string): Boolean;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Parameters: string;
begin
  Parameters := FCoverageConfiguration.GetApplicationParameters;
  FLogManager.Log('Trying to start ' + AExeFileName +
      ' with the Parameters :' + Parameters);
  FillChar(StartInfo, sizeof(TStartupInfo), #0);
  FillChar(ProcInfo, sizeof(TProcessInformation), #0);
  StartInfo.cb := sizeof(TStartupInfo);

  StartInfo.dwFlags := STARTF_USESTDHANDLES;
  StartInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
  StartInfo.hStdOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  StartInfo.hStdError := GetStdHandle(STD_ERROR_HANDLE);

  Parameters := '"' + AExeFileName + '" ' + Parameters;
  Result := CreateProcess(nil, PChar(Parameters), nil, nil, True,
    CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS + DEBUG_PROCESS, nil, nil,
    StartInfo, ProcInfo);
  FProcessID := ProcInfo.dwProcessId;
end;

procedure TDebugger.Debug();
var
  startedok: Boolean;
begin
  try
    FJCLMapScanner := TJCLMapScanner.Create
      (FCoverageConfiguration.GetMapFileName());
    if FJCLMapScanner.LineNumberCount > 0 then
    begin
      startedok := StartProcessToDebug(FCoverageConfiguration.GetExeFileName());
      if startedok then
      begin
        ProcessDebugEvents();
        ProcedureReport();
      end
      else
      begin
        WriteLn('Unable to start executable "' +
            FCoverageConfiguration.GetExeFileName + '"');
        WriteLn('Error :' + I_LogManager.GetLastErrorInfo());
      end;
    end
    else
    begin
      WriteLn(
        'No line information in map file. Enable Debug Information in project options');
    end;
  except
    on e: Exception do
    begin
      WriteLn(e.ClassName, ': ', e.message);
{$IFDEF madExcept}
      HandleException(etNormal, e);
{$ENDIF madExcept}
    end;
  end;
end;

function GetEventCodeName(const DebugEventCode: DWORD): string;
begin
  case DebugEventCode of
    CREATE_PROCESS_DEBUG_EVENT:
      Result := 'CREATE_PROCESS_DEBUG_EVENT';
    CREATE_THREAD_DEBUG_EVENT:
      Result := 'CREATE_THREAD_DEBUG_EVENT';
    EXCEPTION_DEBUG_EVENT:
      Result := 'EXCEPTION_DEBUG_EVENT';
    EXIT_PROCESS_DEBUG_EVENT:
      Result := 'EXIT_PROCESS_DEBUG_EVENT';
    EXIT_THREAD_DEBUG_EVENT:
      Result := 'EXIT_THREAD_DEBUG_EVENT';
    LOAD_DLL_DEBUG_EVENT:
      Result := 'LOAD_DLL_DEBUG_EVENT';
    UNLOAD_DLL_DEBUG_EVENT:
      Result := 'UNLOAD_DLL_DEBUG_EVENT';
    RIP_EVENT:
      Result := 'RIP_EVENT';
    OUTPUT_DEBUG_STRING_EVENT:
      Result := 'OUTPUT_DEBUG_STRING_EVENT';
  else
    Result := IntToStr(DebugEventCode);
  end;
end;

procedure TDebugger.ProcessDebugEvents;
var
  waitok: Boolean;
  DebugEvent: DEBUG_EVENT;
  DebugEventHandlingResult: DWORD;
  CanContinueDebugEvent: Boolean;
  ContProcessEvents: Boolean;
begin
  ContProcessEvents := True;
  while (ContProcessEvents) do
  begin
    waitok := WaitForDebugEvent(DebugEvent, 1000);
    DebugEventHandlingResult := DBG_CONTINUE;
    if waitok then
    begin
      if DebugEvent.dwProcessId <> FProcessID then
      begin
        FLogManager.Log('Skip subprocess event ' + GetEventCodeName
            (DebugEvent.dwDebugEventCode) + ' for process ' + IntToStr
            (DebugEvent.dwProcessId));
      end
      else
        case DebugEvent.dwDebugEventCode of
          CREATE_PROCESS_DEBUG_EVENT:
            HandleCreateProcess(DebugEvent);
          CREATE_THREAD_DEBUG_EVENT:
            HandleCreateThread(DebugEvent);
          EXCEPTION_DEBUG_EVENT:
            HandleExceptionDebug(DebugEvent, ContProcessEvents,
              DebugEventHandlingResult);
          EXIT_PROCESS_DEBUG_EVENT:
            HandleExitProcess(DebugEvent, ContProcessEvents);
          EXIT_THREAD_DEBUG_EVENT:
            HandleExitThread(DebugEvent);
          LOAD_DLL_DEBUG_EVENT:
            HandleLoadDLL(DebugEvent);
          UNLOAD_DLL_DEBUG_EVENT:
            HandleUnLoadDLL(DebugEvent);
          RIP_EVENT:
            HandleRip(DebugEvent);
          OUTPUT_DEBUG_STRING_EVENT:
            HandleOutputDebugString(DebugEvent);
        end;
      CanContinueDebugEvent := ContinueDebugEvent(DebugEvent.dwProcessId,
        DebugEvent.dwThreadId, DebugEventHandlingResult);
      if not CanContinueDebugEvent then
      begin
        FLogManager.Log('Continue Debug Event error :' +
            I_LogManager.GetLastErrorInfo());
        ContProcessEvents := False;
      end;
    end
    else
      FLogManager.Log('Wait For Debug Event timed-out');
  end;
end;

procedure TDebugger.AddBreakPoints(const AModuleList: TStrings;
  const module: IDebugModule; const mapScanner: TJCLMapScanner;
  mns: TModuleNameSpace; uns: TUnitNameSpace);
var
  lp: Integer;
  BreakPoint: IBreakPoint;
  ModuleName: string;
  ModuleNameFromAddr: string;
  UnitName: string;
  UnitModuleName: string;
  JclMapLineNumber: TJclMapLineNumber;
  SkippedModules: TStringList;
  prefix: String;
  unitns : String;
begin
  if mns <> nil then
    prefix := mns.GetName + '_'
  else
    prefix := '';

  if (mapScanner <> nil) then
  begin
    SkippedModules := TStringList.Create;
    try
      SkippedModules.Sorted := True;
      SkippedModules.Duplicates := dupIgnore;

      FLogManager.Log('Adding breakpoints for module:' + module.GetName());

      if FBreakPointList.BreakPointCount = 0 then
        FBreakPointList.SetCapacity(mapScanner.LineNumberCount); // over kill!

      for lp := 0 to mapScanner.LineNumberCount - 1 do
      begin
        JclMapLineNumber := mapScanner.LineNumberByIndex[lp];
        if (JclMapLineNumber.Segment in [1, 2]) then
        // RINGN:Segment 2 are .itext (ICODE).
        begin


          ModuleName := mapScanner.MapStringToStr(JclMapLineNumber.UnitName);

          ModuleNameFromAddr := mapScanner.ModuleNameFromAddr
            (JclMapLineNumber.VA);
          if uns <> nil then
          begin
            if uns.hasUnit(ModuleName) then
            begin
              unitns := uns.GetName;
              unitns := ChangeFileExt(unitns, '');
              unitns := unitns + '.';
            end
            else
              unitns := '';
          end;
          if (ModuleName = ModuleNameFromAddr) then
          begin
            UnitName := mapScanner.SourceNameFromAddr(JclMapLineNumber.VA);
            UnitModuleName := ChangeFileExt(UnitName, '');
            if (AModuleList.IndexOf(UnitModuleName) > -1) then
            begin
              FLogManager.Log('Setting BreakPoint:' + IntToStr(lp));

              // BreakPoint := TBreakPoint.Create(FDebugProcess, AddressFromVA(JclMapLineNumber.VA), JclMapLineNumber.LineNumber, ModuleNameFromAddr, UnitName);
              BreakPoint := FBreakPointList.GetBreakPointByAddress
                (AddressFromVA(JclMapLineNumber.VA,
                  module.getBase()));
              if not Assigned(BreakPoint) then
              begin
                BreakPoint := TBreakPoint.Create(FDebugProcess,
                  AddressFromVA(JclMapLineNumber.VA, module.getBase()),
                  module, FLogManager);
                FBreakPointList.AddBreakPoint(BreakPoint);
                FModuleList.HandleBreakPoint(prefix + Unitns+ ModuleName, UnitName,
                  mapScanner.ProcNameFromAddr(JclMapLineNumber.VA), BreakPoint);
              end;
              BreakPoint.AddDetails(prefix + Unitns+ModuleName, UnitName,
                JclMapLineNumber.LineNumber);

              if (not BreakPoint.Activate) then
                FLogManager.Log('BP FAILED to activate successfully');
            end
            else
              SkippedModules.Add(UnitModuleName);
          end
          else
            FLogManager.Log('Module name "' + ModuleName +
                '" did not match module from address name "' +
                ModuleNameFromAddr + '" at address:' + IntToHex
                (JclMapLineNumber.VA, 8));
        end;
      end;
      for UnitModuleName in SkippedModules do
        FLogManager.Log('Module ' + UnitModuleName + ' skipped');
    finally
      SkippedModules.Free;
    end;
  end;
  FLogManager.Log('Done adding  BreakPoints ');

end;

function GetImageName(Ptr: Pointer; Unicode: Word; handle: THANDLE): String;
var
  ptrDllName: Pointer;
  ByteRead: DWORD;
  // Double the MAX_PATH to ensure room for unicode filenames.
  ImageName: array [0 .. MAX_PATH] of Char;
begin
  Result := '';
  if (Ptr <> nil) then
  begin
    if ReadProcessMemory(handle, Ptr, @ptrDllName, sizeof(ptrDllName),
      @ByteRead) then
    begin
      if (ptrDllName <> nil) then
      begin
        if ReadProcessMemory(handle, ptrDllName, @ImageName, sizeof(ImageName),
          @ByteRead) then
        begin
          if Unicode <> 0 then
            Result := string(PWideChar(@ImageName))
          else
            Result := string(PChar(@ImageName));
        end;
      end;
    end;
  end;
end;

procedure TDebugger.HandleCreateProcess(const ADebugEvent: DEBUG_EVENT);
var
  DebugThread: IDebugThread;
  processname: String;
  img: TJCLPEImage;
  size: Cardinal;
begin
  processname := FCoverageConfiguration.GetExeFileName();

  img := TJCLPEImage.Create();
  try
    img.filename := processname;
    size := img.OptionalHeader32.SizeOfCode;
  finally
    img.Free;
  end;
  FLogManager.Log('Create Process:' + IntToStr(ADebugEvent.dwProcessId)
      + ' name:' + processname);

  FDebugProcess := TDebugProcess.Create(ADebugEvent.dwProcessId,
    ADebugEvent.CreateProcessInfo.hProcess,
    DWORD(ADebugEvent.CreateProcessInfo.lpBaseOfImage),
    processname, size, FJCLMapScanner, FLogManager);
  DebugThread := TDebugThread.Create(ADebugEvent.dwThreadId,
    ADebugEvent.CreateProcessInfo.hThread);
  FDebugProcess.AddThread(DebugThread);
  try
    AddBreakPoints(FCoverageConfiguration.GetUnits(), FDebugProcess,
      FJCLMapScanner, FCoverageConfiguration.GetModuleNameSpace(ExtractFileName(processname)),
      FCoverageConfiguration.GetUnitNameSpace(ExtractFileName(processname)));
  except
    on e: Exception do
    begin
      FLogManager.Log('Exception during add breakpoints:' + e.Message + ' ' +
          e.ToString());

    end;
  end;
  // if not CloseHandle(ADebugEvent.CreateProcessInfo.hFile) then
  // begin
  // FLogManager.Log('Error closing Create Process hFile handle : ' + I_LogManager.GetLastErrorInfo());
  // end;

  // if not CloseHandle(ADebugEvent.CreateProcessInfo.hProcess) then
  // begin
  // FLogManager.Log('Error closing Create Process hProcess handle : ' + I_LogManager.GetLastErrorInfo());
  // end;

  // if not CloseHandle(ADebugEvent.CreateProcessInfo.hThread) then
  // begin
  // FLogManager.Log('Error closing Create Process hThread handle : ' + I_LogManager.GetLastErrorInfo());
  // end;
end;

procedure TDebugger.HandleCreateThread(const ADebugEvent: DEBUG_EVENT);
var
  DebugThread: IDebugThread;
begin
  FLogManager.Log('Create thread:' + IntToStr(ADebugEvent.dwThreadId));

  DebugThread := TDebugThread.Create(ADebugEvent.dwThreadId,
    ADebugEvent.CreateThread.hThread);
  FDebugProcess.AddThread(DebugThread);

  // if not CloseHandle(ADebugEvent.CreateThread.hThread) then
  // begin
  // FLogManager.Log('Error closing Create Thread hThread handle : ' + I_LogManager.GetLastErrorInfo());
  // end;
end;

procedure TDebugger.HandleExceptionDebug(const ADebugEvent: DEBUG_EVENT;
  var AContProcessEvents: Boolean; var ADebugEventHandlingResult: DWORD);
var
  DebugThread: IDebugThread;
  BreakPoint: IBreakPoint;
  lp: Integer;
  ExceptionRecord: EXCEPTION_RECORD;
  module: IDebugModule;
  mapScanner: TJCLMapScanner;
begin
  ADebugEventHandlingResult := Cardinal(DBG_EXCEPTION_NOT_HANDLED);

  ExceptionRecord := ADebugEvent.Exception.ExceptionRecord;
  module := FDebugProcess.FindDebugModuleFromAddress
    (ExceptionRecord.ExceptionAddress);
  if (module <> nil) then
    mapScanner := module.getJCLMapScanner
  else
    mapScanner := nil;
  case ExceptionRecord.ExceptionCode of
    Cardinal(EXCEPTION_ACCESS_VIOLATION):
      begin
        FLogManager.Log('ACCESS VIOLATION at Address:' + IntToHex
            (Integer(ExceptionRecord.ExceptionAddress), 8));
        FLogManager.Log(IntToHex(ExceptionRecord.ExceptionCode,
            8) + ' not a debug BreakPoint');
        if ExceptionRecord.NumberParameters > 1 then
        begin
          if ExceptionRecord.ExceptionInformation[0] = 0 then
            FLogManager.Log('Tried to read');
          if ExceptionRecord.ExceptionInformation[0] = 1 then
            FLogManager.Log('Tried to write');
          if ExceptionRecord.ExceptionInformation[0] = 8 then
            FLogManager.Log('DEP exception');
          FLogManager.Log('Trying to access Address:' + IntToHex
              (Integer(ExceptionRecord.ExceptionInformation[1]), 8));
          if (mapScanner <> nil) then
          begin
            for lp := 0 to mapScanner.LineNumberCount - 1 do
            begin
              if mapScanner.LineNumberByIndex[lp].VA = VAFromAddress
                (ExceptionRecord.ExceptionAddress, module.getBase()) then
              begin
                FLogManager.Log(mapScanner.ModuleNameFromAddr
                    (mapScanner.LineNumberByIndex[lp].VA) + ' line ' + IntToStr
                    (mapScanner.LineNumberByIndex[lp].LineNumber));
                break;
              end;
            end;
          end
          else
          begin
            if module = nil then
              FLogManager.Log('No map information available Address:' + IntToHex
                  (Integer(ExceptionRecord.ExceptionInformation[1]),
                  8) + ' in unknown module')
            else
              FLogManager.Log('No map information available Address:' + IntToHex
                  (Integer(ExceptionRecord.ExceptionInformation[1]),
                  8) + ' module ' + module.GetName());

          end;
          LogStackFrame(ADebugEvent);
        end;
      end;

    // Cardinal(EXCEPTION_ARRAY_BOUNDS_EXCEEDED) :
    Cardinal(EXCEPTION_BreakPoint):
      begin
        BreakPoint := FBreakPointList.GetBreakPointByAddress
          (ExceptionRecord.ExceptionAddress);
        if BreakPoint <> nil then
        begin
          for lp := 0 to Pred(BreakPoint.DetailCount) do
            FLogManager.Log('Adding coverage:' + BreakPoint.DetailByIndex(lp)
                .UnitName + ' (' + BreakPoint.DetailByIndex(lp)
                .ModuleName + ') ' + IntToStr(BreakPoint.DetailByIndex(lp)
                  .Line));

          DebugThread := FDebugProcess.GetThreadById(ADebugEvent.dwThreadId);
          if (DebugThread <> nil) then
          begin
            if (BreakPoint.IsActive) then
            begin
              BreakPoint.Clear(DebugThread);
              BreakPoint.Covered := True;
            end
            else
              FLogManager.Log(
                'BreakPoint already cleared - BreakPoint in source?');
          end
          else
            FLogManager.Log('Couldn''t find thread:' + IntToStr
                (ADebugEvent.dwThreadId));
        end
        else
        begin
          // A good contender for this is ntdll.DbgBreakPoint {$7C90120E}
          FLogManager.Log('Couldn''t find BreakPoint for exception address:' +
              IntToHex(Integer(ExceptionRecord.ExceptionAddress), 8));
        end;
        ADebugEventHandlingResult := Cardinal(DBG_CONTINUE);
      end;

    Cardinal(EXCEPTION_DATATYPE_MISALIGNMENT):
      begin
        FLogManager.Log('EXCEPTION_DATATYPE_MISALIGNMENT Address:' + IntToHex
            (Integer(ExceptionRecord.ExceptionAddress), 8));
        FLogManager.Log(IntToHex(ExceptionRecord.ExceptionCode,
            8) + ' not a debug BreakPoint');
        AContProcessEvents := False;
      end;

    // Cardinal(EXCEPTION_FLT_DENORMAL_OPERAND)
    // Cardinal(EXCEPTION_FLT_DIVIDE_BY_ZERO)
    // Cardinal(EXCEPTION_FLT_INEXACT_RESULT)
    // Cardinal(EXCEPTION_FLT_INVALID_OPERATION)
    // Cardinal(EXCEPTION_FLT_OVERFLOW)
    // Cardinal(EXCEPTION_FLT_STACK_CHECK)
    // Cardinal(EXCEPTION_FLT_UNDERFLOW)
    // Cardinal(EXCEPTION_ILLEGAL_INSTRUCTION)
    // Cardinal(EXCEPTION_IN_PAGE_ERROR)
    // Cardinal(EXCEPTION_INT_DIVIDE_BY_ZERO)
    // Cardinal(EXCEPTION_INT_OVERFLOW)
    // Cardinal(EXCEPTION_INVALID_DISPOSITION)
    // Cardinal(EXCEPTION_NONCONTINUABLE_EXCEPTION)
    // Cardinal(EXCEPTION_PRIV_INSTRUCTION)
    // Cardinal(EXCEPTION_SINGLE_STEP)
    // Cardinal(EXCEPTION_STACK_OVERFLOW)

  else
    begin
      FLogManager.Log('EXCEPTION CODE:' + IntToHex
          (ExceptionRecord.ExceptionCode, 8));
      FLogManager.Log('Address:' + IntToHex
          (Integer(ExceptionRecord.ExceptionAddress), 8));
      FLogManager.Log('EXCEPTION flags:' + IntToHex
          (ExceptionRecord.ExceptionFlags, 8));
      LogStackFrame(ADebugEvent);
    end;
  end
end;

procedure TDebugger.LogStackFrame(const ADebugEvent: DEBUG_EVENT);
var
  ContextRecord: TContext;
  res: BOOL;
  StackFrame: TSTACKFRAME64;
  // stackwalkResult : BOOL;
  lp: Integer;
  JclMapLineNumber: TJclMapLineNumber;
  DebugThread: IDebugThread;
  module: IDebugModule;
  mapScanner: TJCLMapScanner;
begin
  ContextRecord.ContextFlags := CONTEXT_ALL;

  DebugThread := FDebugProcess.GetThreadById(ADebugEvent.dwThreadId);

  if DebugThread <> nil then
  begin
    res := GetThreadContext(DebugThread.GetHandle, ContextRecord);
    if (res { <> False } ) then
    begin
      FillChar(StackFrame, sizeof(StackFrame), 0);
      StackFrame.AddrPC.Offset := ContextRecord.Eip;
      StackFrame.AddrPC.Mode := AddrModeFlat;
      StackFrame.AddrFrame.Offset := ContextRecord.Ebp;
      StackFrame.AddrFrame.Mode := AddrModeFlat;
      StackFrame.AddrStack.Offset := ContextRecord.Esp;
      StackFrame.AddrStack.Mode := AddrModeFlat;

      { stackwalkResult := }
      StackWalk64(IMAGE_FILE_MACHINE_I386, FDebugProcess.GetHandle,
        DebugThread.GetHandle, StackFrame, @ContextRecord,
        @RealReadFromProcessMemory, nil, nil, nil);
      FLogManager.Log('---------------Stack trace --------------');
      while StackWalk64(IMAGE_FILE_MACHINE_I386, FDebugProcess.GetHandle,
        DebugThread.GetHandle, StackFrame, @ContextRecord,
        @RealReadFromProcessMemory, nil, nil, nil) do
      begin
        if (StackFrame.AddrPC.Offset <> 0) then
        begin
          module := FDebugProcess.FindDebugModuleFromAddress
            (Pointer(StackFrame.AddrPC.Offset));
          if (module <> nil) then
          begin

            mapScanner := module.getJCLMapScanner;

            FLogManager.Log('Module : ' + module.GetName()
                + ' Stack frame:' + IntToHex
                (Cardinal(Pointer(StackFrame.AddrPC.Offset)), 8));
            if (mapScanner <> nil) then
            begin

              for lp := 0 to mapScanner.LineNumberCount - 1 do
              begin
                JclMapLineNumber := mapScanner.LineNumberByIndex[lp];
                if JclMapLineNumber.VA = VAFromAddress
                  (Pointer(StackFrame.AddrPC.Offset), module.getBase())
                  then
                begin
                  FLogManager.Log('Exact line:' + mapScanner.ModuleNameFromAddr
                      (JclMapLineNumber.VA) + ' line ' + IntToStr
                      (JclMapLineNumber.LineNumber));
                  break;
                end
                else if (JclMapLineNumber.VA > VAFromAddress
                    (Pointer(StackFrame.AddrPC.Offset), module.getBase())) and
                  (VAFromAddress(Pointer(StackFrame.AddrPC.Offset),
                    module.getBase()) < mapScanner.LineNumberByIndex[lp + 1]
                    .VA) then
                begin
                  FLogManager.Log('After line:' + mapScanner.ModuleNameFromAddr
                      (JclMapLineNumber.VA) + ' line ' + IntToStr
                      (JclMapLineNumber.LineNumber));
                  break;
                end;
              end;
            end
            else
            begin
              FLogManager.Log('Module : ' + module.GetName()
                  + ' - no MAP information exists');
            end;
          end
          else
          begin
            FLogManager.Log('No module found for exception address:' + IntToHex
                (StackFrame.AddrPC.Offset, 8));
          end;
        end;
      end;
      FLogManager.Log('---------------End of Stack trace --------------');
    end
    else
      FLogManager.Log('Failed to get thread context : ' +
          I_LogManager.GetLastErrorInfo());
  end
  else
    FLogManager.Log('Thread not found : ' + IntToStr(ADebugEvent.dwThreadId));
end;

procedure TDebugger.HandleExitProcess(const ADebugEvent: DEBUG_EVENT;
  var AContProcessEvents: Boolean);
begin
  FLogManager.Log('Process ' + IntToStr(ADebugEvent.dwProcessId)
      + ' exiting. Exit code :' + IntToStr(ADebugEvent.ExitProcess.dwExitCode)
    );
  AContProcessEvents := False;
end;

procedure TDebugger.HandleExitThread(const ADebugEvent: DEBUG_EVENT);
begin
  FLogManager.Log('Thread exit:' + IntToStr(ADebugEvent.dwThreadId));
  FDebugProcess.RemoveThread(ADebugEvent.dwThreadId);
end;

procedure TDebugger.HandleLoadDLL(const ADebugEvent: DEBUG_EVENT);
var
  DllName: string;
  ExtraMsg: string;
  module: TDebugModule;
  img: TJCLPEImage;
  size: Cardinal;
  mapFile: String;
  mapScanner: TJCLMapScanner;
  mns: TModuleNameSpace;
begin

  ExtraMsg := '';
  DllName := GetImageName(ADebugEvent.LoadDll.lpImageName,
    ADebugEvent.LoadDll.fUnicode, FDebugProcess.GetHandle);

  img := TJCLPEImage.Create();
  try
    img.filename := DllName;
    size := img.OptionalHeader32.SizeOfCode;
  finally
    img.Free;
  end;

  mapFile := PathRemoveExtension(DllName) + '.map';
  if FileExists(mapFile) then
  begin
    FLogManager.Log('Loading map file:' + mapFile);

    mapScanner := TJCLMapScanner.Create(mapFile);
  end
  else
    mapScanner := nil;

  module := TDebugModule.Create(DllName,
    HMODULE(ADebugEvent.LoadDll.lpBaseOfDll), size, mapScanner);
  FDebugProcess.AddModule(module);
  ExtraMsg := ' (' + DllName + ') size :' + IntToStr(size);

  FLogManager.Log('Loading DLL at addr:' + IntToHex
      (DWORD(ADebugEvent.LoadDll.lpBaseOfDll), 8) + ExtraMsg);

  mns := FCoverageConfiguration.GetModuleNameSpace(ExtractFileNAme(DllName));
  try
    AddBreakPoints(FCoverageConfiguration.GetUnits(), module, mapScanner, mns,
      FCoverageConfiguration.GetUnitNameSpace(ExtractFileNAme(DllName)));
  except
    on e: Exception do
    begin
      FLogManager.Log('Exception during add breakpoints:' + e.Message + ' ' +
          e.ToString());

    end;
  end;
  // if not CloseHandle(ADebugEvent.LoadDll.hFile) then
  // begin
  // FLogManager.Log('Error closing Load DLL hFile handle : ' + I_LogManager.GetLastErrorInfo());
  // end;
end;

procedure TDebugger.HandleUnLoadDLL(const ADebugEvent: DEBUG_EVENT);
begin
  FLogManager.Log('UnLoading DLL:' + IntToHex
      (DWORD(ADebugEvent.LoadDll.lpBaseOfDll), 8));
end;

procedure TDebugger.HandleOutputDebugString(const ADebugEvent: DEBUG_EVENT);
begin
  // FLoggerManager.Log('Outputdebugstring:' + ADebugEvent.DebugString.lpDebugStringData);
end;

procedure TDebugger.HandleRip(const ADebugEvent: DEBUG_EVENT);
begin
  //
end;

end.
