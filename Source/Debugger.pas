(***********************************************************************)
(* Delphi Code Coverage                                                *)
(*                                                                     *)
(* A quick hack of a Code Coverage Tool for Delphi                     *)
(* by Christer Fahlgren and Nick Ring                                  *)
(*                                                                     *) 
(* This Source Code Form is subject to the terms of the Mozilla Public *)
(* License, v. 2.0. If a copy of the MPL was not distributed with this *)
(* file, You can obtain one at http://mozilla.org/MPL/2.0/.            *)

unit Debugger;

interface

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
  I_BreakPoint,
  ClassInfoUnit,
  ModuleNameSpaceUnit,
  uConsoleOutput,
  JwaPsApi;

type
  TDebugger = class(TInterfacedObject, IDebugger)
  private
    FMapScanner: TJCLMapScanner;
    FDebugProcess: IDebugProcess;
    FProcessID: DWORD;
    FBreakPointList: IBreakPointList;
    FCoverageConfiguration: ICoverageConfiguration;
    FCoverageStats: ICoverageStats;
    FLogManager: ILogManager;
    FModuleList: TModuleList;
    FTestExeExitCode: Integer;
    FLastBreakPoint: IBreakPoint;

    function AddressFromVA(
      const AVA: DWORD;
      const AModule: HMODULE): Pointer; inline;
    function VAFromAddress(
      const AAddr: Pointer;
      const AModule: HMODULE): DWORD; inline;
    function GetImageName(const APtr: Pointer; const AUnicode: Word;
      const AlpBaseOfDll: Pointer; const AHandle: THANDLE): string;
    procedure AddBreakPoints(
      const AModuleList: TStrings;
      const AExcludedModuleList: TStrings;
      const AModule: IDebugModule;
      const AMapScanner: TJCLMapScanner;
      AModuleNameSpace: TModuleNameSpace = nil;
      AUnitNameSpace: TUnitNameSpace = nil);

    procedure Debug;
    function StartProcessToDebug: Boolean;

    procedure ProcessDebugEvents;

    procedure HandleExceptionDebug(
      const ADebugEvent: DEBUG_EVENT;
      var AContProcessEvents: Boolean;
      var ADebugEventHandlingResult: DWORD);
    procedure HandleCreateProcess(const ADebugEvent: DEBUG_EVENT);
    procedure HandleCreateThread(const ADebugEvent: DEBUG_EVENT);
    procedure HandleExitProcess(
      const ADebugEvent: DEBUG_EVENT;
      var AContProcessEvents: Boolean);
    procedure HandleExitThread(const ADebugEvent: DEBUG_EVENT);
    procedure HandleLoadDLL(const ADebugEvent: DEBUG_EVENT);
    procedure HandleOutputDebugString(const ADebugEvent: DEBUG_EVENT);
    procedure HandleUnLoadDLL(const ADebugEvent: DEBUG_EVENT);
    procedure HandleRip(const ADebugEvent: DEBUG_EVENT);

    procedure LogStackFrame(const ADebugEvent: DEBUG_EVENT);

    procedure GenerateReport;

    procedure PrintUsage;
    procedure PrintSummary;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
  end;

function RealReadFromProcessMemory(
  const AhProcess: THANDLE;
  const AqwBaseAddress: DWORD64;
  const AlpBuffer: Pointer;
  const ASize: DWORD;
  var ANumberOfBytesRead: DWORD): BOOL; stdcall;

implementation

uses
  ActiveX,
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
  HTMLCoverageReport,
  CoverageStats,
  DebugProcess,
  DebugThread,
  LogManager,
  LoggerTextFile,
  LoggerAPI,
  XMLCoverageReport,
  I_DebugThread,
  I_Report,
  EmmaCoverageFileUnit,
  DebugModule,
  JclPEImage,
  JclFileUtils;

function RealReadFromProcessMemory(
  const AhProcess: THANDLE;
  const AqwBaseAddress: DWORD64;
  const AlpBuffer: Pointer;
  const ASize: DWORD;
  var ANumberOfBytesRead: DWORD): BOOL; stdcall;
var
  st: DWORD;
begin
  Result := JwaWinBase.ReadProcessMemory(
    AhProcess,
    Pointer(AqwBaseAddress),
    AlpBuffer,
    ASize,
    @st
  );
  ANumberOfBytesRead := st;
end;

constructor TDebugger.Create;
begin
  inherited;
  CoInitialize(nil);

  FBreakPointList := TBreakPointList.Create;
  FCoverageConfiguration := TCoverageConfiguration.Create(TCommandLineProvider.Create);

  FCoverageStats := TCoverageStats.Create('', nil);

  FLogManager := TLogManager.Create;
  uConsoleOutput.G_LogManager := FLogManager;

  FModuleList := TModuleList.Create;
end;

destructor TDebugger.Destroy;
begin
  FCoverageConfiguration := nil;
  FDebugProcess := nil;
  FBreakPointList := nil;
  FCoverageStats := nil;
  uConsoleOutput.G_LogManager := nil;
  FLogManager := nil;
  FModuleList.Free;
  CoUninitialize;

  inherited;
end;

procedure TDebugger.PrintUsage;
begin
  ConsoleOutput('Usage:CodeCoverage.exe [switches]');
  ConsoleOutput('List of switches:');
  // --------------------------------------------------------------------------
  ConsoleOutput('');
  ConsoleOutput('Mandatory switches:');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_EXECUTABLE +
      ' executable.exe   -- the executable to run');
  ConsoleOutput('or');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_DPROJ +
      ' Project.dproj -- Delphi project file');
  ConsoleOutput('');
  ConsoleOutput('Optional switches:');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_MAP_FILE +
      ' mapfile.map      -- the mapfile to use');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_UNIT +
      ' unit1 unit2 etc  -- a list of units to create reports for');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_EXCLUDE_SOURCE_MASK +
      ' mask1 mask2 etc  -- a list of file masks to exclude from list of units'
    );
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_UNIT_FILE +
      ' filename        -- a file containing a list of units to create');
  ConsoleOutput('                       reports for - one unit per line');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_SOURCE_DIRECTORY +
      ' directory       -- the directory where the project file is located.');
  ConsoleOutput(
    '                       This is added as the first entry of the search');
  ConsoleOutput('                       path - default is current directory');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_OUTPUT_DIRECTORY +
      ' directory       -- the output directory where reports shall be');
  ConsoleOutput('                       generated - default is current directory');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_EXECUTABLE_PARAMETER +
      ' param param2 etc -- a list of parameters to be passed to the');
  ConsoleOutput('                       application. Escape character:' +
      I_CoverageConfiguration.cESCAPE_CHARACTER +
        ' (if using from command-line or batch file, use '+
      I_CoverageConfiguration.cESCAPE_CHARACTER + I_CoverageConfiguration.cESCAPE_CHARACTER +
      ')');
     ConsoleOutput(I_CoverageConfiguration.cPARAMETER_LOGGING_TEXT +
      ' [filename]      -- Enable text logging, specifying filename. Default');
  ConsoleOutput('                       file name is:' +
      I_CoverageConfiguration.cDEFULT_DEBUG_LOG_FILENAME);
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_VERBOSE +
      '                  -- Verbose output'
    );
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_LOGGING_WINAPI +
      '               -- Use WinAPI OutputDebugString for debug');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_INCLUDE +
      '                -- include file prefixes. This stops "Common.Encodings"'
    );
  ConsoleOutput('                       being converted to "Common"');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_FILE_EXTENSION_EXCLUDE +
      '                -- exclude file prefixes. Coverts "Common.Encodings.pas"'
    );
  ConsoleOutput('                       to "Common.Encodings" - default');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS +
      ' directories     -- the directory(s) where source code is located -');
  ConsoleOutput('                       default is current directory');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_SOURCE_PATHS_FILE +
      ' filename       -- a file containing a list of source path(s) to');
  ConsoleOutput('                       check for any units to report on');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_EMMA_OUTPUT +
      '               -- Output emma coverage file as coverage.es in the output directory');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_XML_OUTPUT +
      '                -- Output xml report as CodeCoverage_Summary.xml in the output directory');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_HTML_OUTPUT +
      '               -- Output html report as CodeCoverage_Summary.html in the output directory');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_MODULE_NAMESPACE +
      ' name dll [dll2]   -- Create a separate namespace with the given name for the listed dll:s.');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_UNIT_NAMESPACE +
      ' dll_or_exe unitname [unitname2]   -- Create a separate namespace (the namespace name will be the name of the module without extension) *ONLY* for the listed units within the module.');
  ConsoleOutput(I_CoverageConfiguration.cPARAMETER_LINE_COUNT +
    ' [number] -- Count number of times a line is executed up to the specified limit (default 0 - disabled) (Win32 only)');

end;

function TDebugger.VAFromAddress(
  const AAddr: Pointer;
  const AModule: HMODULE): DWORD;
begin
  Result := DWORD_PTR(AAddr) - AModule - $1000;
end;

function TDebugger.AddressFromVA(
  const AVA: DWORD;
  const AModule: HMODULE): Pointer;
begin
  Result := Pointer(DWORD_PTR(AVA + AModule + $1000));
end;

procedure TDebugger.Start;
var
  Reason: String;
begin
  try
    FCoverageConfiguration.ParseCommandLine(FLogManager);

    if FCoverageConfiguration.IsComplete(Reason) then
    begin
      ForceDirectories(FCoverageConfiguration.OutputDir);
      Debug
    end
    else
    begin
      ConsoleOutput('The configuration was incomplete due to the following error:');
      ConsoleOutput(Reason);
      PrintUsage;
    end;
    if FCoverageConfiguration.TestExeExitCode then
      ExitCode := FTestExeExitCode;
  except
    on E: EConfigurationException do
    begin
      ConsoleOutput('Exception parsing the command line:' + E.message);
      PrintUsage;
    end;
    on E: Exception do
    begin
      ConsoleOutput(E.ClassName + ': ' + E.message);
{$IFDEF madExcept}
      HandleException(etNormal, E);
{$ENDIF madExcept}
    end;
  end;
end;

procedure TDebugger.GenerateReport;
var
  ModuleStats: ICoverageStats;
  UnitStats: ICoverageStats;
  BreakPointIndex: Integer;
  BreakPointDetailIndex: Integer;
  BreakPoint: IBreakPoint;
  BreakPointDetail: TBreakPointDetail;
  CoverageReport: IReport; // TCoverageReport;
begin
  FLogManager.Log('ProcedureReport');
  ModuleStats := nil;
  UnitStats := nil;

  for BreakPointIndex := 0 to Pred(FBreakPointList.Count) do
  begin
    BreakPoint := FBreakPointList[BreakPointIndex];

    for BreakPointDetailIndex := 0 to Pred(BreakPoint.DetailCount) do
    begin
      BreakPointDetail := BreakPoint.DetailByIndex(BreakPointDetailIndex);

      if (ModuleStats = nil)
      or (ModuleStats.Name <> BreakPointDetail.ModuleName) then
      begin
        UnitStats := nil;
        ModuleStats := FCoverageStats.CoverageReportByName[BreakPointDetail.ModuleName];
      end;

      if (UnitStats = nil)
      or (UnitStats.Name <> BreakPointDetail.UnitName) then
      begin
        UnitStats := ModuleStats.CoverageReportByName[BreakPointDetail.UnitName];
      end;

      UnitStats.AddLineCoverage(BreakPointDetail.Line, BreakPoint.BreakCount);
    end;
  end;

  FCoverageStats.Calculate;

  FLogManager.Log('Generating reports');

  if (FCoverageConfiguration.HtmlOutput) then
  begin
    CoverageReport := THTMLCoverageReport.Create(FCoverageConfiguration);
    CoverageReport.Generate(FCoverageStats, FModuleList, FLogManager);
  end;

  if (FCoverageConfiguration.XmlOutput) then
  begin
    CoverageReport := TXMLCoverageReport.Create(FCoverageConfiguration);
    CoverageReport.Generate(FCoverageStats, FModuleList,FLogManager);
  end;

  if (FCoverageConfiguration.EmmaOutput) or (FCoverageConfiguration.EmmaOutput21) then
  begin
    CoverageReport := TEmmaCoverageFile.Create(FCoverageConfiguration);
    CoverageReport.Generate(FCoverageStats, FModuleList,FLogManager);
  end;
end;

function TDebugger.StartProcessToDebug: Boolean;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  Parameters: string;
begin
  Parameters := FCoverageConfiguration.ApplicationParameters;
  FLogManager.Log(
    'Trying to start ' + FCoverageConfiguration.ExeFileName +
    ' with the Parameters :' + Parameters);

  FillChar(StartInfo, SizeOf(TStartupInfo), #0);
  FillChar(ProcInfo, SizeOf(TProcessInformation), #0);
  StartInfo.cb := SizeOf(TStartupInfo);

  StartInfo.dwFlags := STARTF_USESTDHANDLES;
  StartInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
  StartInfo.hStdOutput := GetStdHandle(STD_OUTPUT_HANDLE);
  StartInfo.hStdError := GetStdHandle(STD_ERROR_HANDLE);

  Parameters := '"' + FCoverageConfiguration.ExeFileName + '" ' + Parameters;
  Result := CreateProcess(
    nil,
    PChar(Parameters),
    nil,
    nil,
    True,
    CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS + DEBUG_PROCESS,
    nil,
    nil,
    StartInfo,
    ProcInfo
  );

  FProcessID := ProcInfo.dwProcessId;
end;

procedure TDebugger.PrintSummary;
  function PadString(const AString: string): string;
  begin
    Result := AString + ' ';
    while Length(Result) < 11 do
      Result := ' ' + Result;
  end;
begin
  ConsoleOutput('');
  ConsoleOutput('Summary:');
  ConsoleOutput('');
  ConsoleOutput('+-----------+-----------+-----------+');
  ConsoleOutput('|   Lines   |  Covered  | Covered % |');
  ConsoleOutput('+-----------+-----------+-----------+');
  ConsoleOutput(
    Format(
      '|%s|%s|%s|',
      [
        PadString(IntToStr(FCoverageStats.LineCount)),
        PadString(IntToStr(FCoverageStats.CoveredLineCount)),
        PadString(IntToStr(FCoverageStats.PercentCovered) + ' %')
      ]
    )
  );
  ConsoleOutput('+-----------+-----------+-----------+');
end;

procedure TDebugger.Debug;
begin
  try
    FMapScanner := TJCLMapScanner.Create(FCoverageConfiguration.MapFileName);
    try
      if FMapScanner.LineNumbersCnt > 0 then
      begin
        if StartProcessToDebug then
        begin
          VerboseOutput('Started successfully');
          ProcessDebugEvents;
          VerboseOutput('Finished processing debug events');
          GenerateReport;
          VerboseOutput('Finished generating reports');
          PrintSummary;
        end
        else
        begin
          ConsoleOutput(
            'Unable to start executable "' +
            FCoverageConfiguration.ExeFileName + '"');
          ConsoleOutput('Error :' + I_LogManager.LastErrorInfo);
        end;
      end
      else
        ConsoleOutput('No line information in map file. Enable Debug Information in project options');
    finally
      FMapScanner.Free;
    end;
  except
    on E: Exception do
    begin
      ConsoleOutput(E.ClassName + ': ' + E.message);
{$IFDEF madExcept}
      HandleException(etNormal, E);
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
  WaitOK: Boolean;
  DebugEvent: DEBUG_EVENT;
  DebugEventHandlingResult: DWORD;
  CanContinueDebugEvent: Boolean;
  ContProcessEvents: Boolean;
begin
  ContProcessEvents := True;
  while ContProcessEvents do
  begin
    WaitOK := WaitForDebugEvent(DebugEvent, 1000);

    DebugEventHandlingResult := DBG_CONTINUE;

    if WaitOK then
    begin
      if DebugEvent.dwProcessId <> FProcessID then
      begin
        FLogManager.Log(
          'Skip subprocess event ' + GetEventCodeName(DebugEvent.dwDebugEventCode) +
          ' for process ' + IntToStr(DebugEvent.dwProcessId));
      end
      else
      begin
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
      end;

      CanContinueDebugEvent := ContinueDebugEvent(
        DebugEvent.dwProcessId,
        DebugEvent.dwThreadId,
        DebugEventHandlingResult
      );

      if not CanContinueDebugEvent then
      begin
        FLogManager.Log('Continue Debug Event error :' + I_LogManager.LastErrorInfo);
        ContProcessEvents := False;
      end;
    end
    else
      FLogManager.Log('Wait For Debug Event timed-out');
  end;
end;

procedure TDebugger.AddBreakPoints(
  const AModuleList: TStrings;
  const AExcludedModuleList: TStrings;
  const AModule: IDebugModule;
  const AMapScanner: TJCLMapScanner;
  AModuleNameSpace: TModuleNameSpace;
  AUnitNameSpace: TUnitNameSpace);
var
  LineIndex: Integer;
  BreakPoint: IBreakPoint;
  ModuleName: string;
  ModuleNameFromAddr: string;
  UnitName: string;
  UnitModuleName: string;
  MapLineNumber: TJclMapLineNumber;
  SkippedModules: TStringList;
  Prefix: String;
  UnitNameSpace : String;
begin
  UnitNameSpace := '';
  if Assigned(AModuleNameSpace) then
    Prefix := AModuleNameSpace.Name + '_'
  else
    Prefix := '';

  if (AMapScanner <> nil) then
  begin
    SkippedModules := TStringList.Create;
    try
      SkippedModules.Sorted := True;
      SkippedModules.Duplicates := dupIgnore;

      FLogManager.Log('Adding breakpoints for module:' + AModule.Name);

      if FBreakPointList.Count = 0 then
        FBreakPointList.SetCapacity(AMapScanner.LineNumbersCnt); // over kill!

      for LineIndex := 0 to AMapScanner.LineNumbersCnt - 1 do
      begin
        MapLineNumber := AMapScanner.LineNumberByIndex[LineIndex];

        // RINGN:Segment 2 are .itext (ICODE).
        if (MapLineNumber.Segment in [1, 2]) then
        begin
          ModuleName := AMapScanner.MapStringToStr(MapLineNumber.UnitName);
          ModuleNameFromAddr := AMapScanner.ModuleNameFromAddr(MapLineNumber.VA);
          if Assigned(AUnitNameSpace) then
          begin
            if AUnitNameSpace.HasUnit(ModuleName) then
            begin
              UnitNameSpace := AUnitNameSpace.ModuleName;
              UnitNameSpace := ChangeFileExt(UnitNameSpace, '');
              UnitNameSpace := UnitNameSpace + '.';
            end
            else
              UnitNameSpace := '';
          end;

          if (ModuleName = ModuleNameFromAddr) then
          begin
            UnitName := AMapScanner.SourceNameFromAddr(MapLineNumber.VA);
            if ExtractFileExt(UnitName) = '' then
              UnitName := ChangeFileExt(UnitName, '.pas');
            UnitModuleName := ExtractFileName(ChangeFileExt(UnitName, ''));

            if (AModuleList.IndexOf(UnitModuleName) > -1)
            and (AModuleList.IndexOf(ModuleName) > -1)
            and (AExcludedModuleList.IndexOf(UnitModuleName) < 0) then
            begin
              FLogManager.Log(
                'Setting BreakPoint for module: ' + ModuleName +
                ' unit ' + UnitName +
                ' addr:' + IntToStr(LineIndex));

              BreakPoint := FBreakPointList.BreakPointByAddress[(AddressFromVA(MapLineNumber.VA, AModule.Base))];
              if not Assigned(BreakPoint) then
              begin
                BreakPoint := TBreakPoint.Create(
                  FDebugProcess,
                  AddressFromVA(MapLineNumber.VA, AModule.Base),
                  AModule,
                  FLogManager
                );
                FBreakPointList.Add(BreakPoint);
                FModuleList.HandleBreakPoint(
                  Prefix + UnitNameSpace + ModuleName,
                  UnitName,
                  AMapScanner.ProcNameFromAddr(MapLineNumber.VA),
                  MapLineNumber.LineNumber,
                  BreakPoint,
                  FLogManager
                );
              end;

              BreakPoint.AddDetails(
                Prefix + UnitNameSpace + ModuleName,
                UnitName,
                MapLineNumber.LineNumber
              );

              if (not BreakPoint.Activate) then
                FLogManager.Log('BP FAILED to activate successfully');
            end
            else
              SkippedModules.Add(UnitModuleName);
          end
          else
            FLogManager.Log(
              'Module name "' + ModuleName + '" did not match module from address name "' +
              ModuleNameFromAddr + '" at address:' + IntToHex(MapLineNumber.VA, 8));
        end;
      end;

      for UnitModuleName in SkippedModules do
      begin
        FLogManager.Log('Module ' + UnitModuleName + ' skipped');
      end;
    finally
      SkippedModules.Free;
    end;
  end;

  FLogManager.Log('Done adding  BreakPoints');
end;

function TDebugger.GetImageName(const APtr: Pointer; const AUnicode: Word;
  const AlpBaseOfDll: Pointer; const AHandle: THANDLE): string;
var
  PtrDllName: Pointer;
  ByteRead: DWORD;
  // Double the MAX_PATH to ensure room for unicode filenames.
  ImageName: array [0 .. MAX_PATH] of Char;
begin
  Result := '';
  if (APtr <> nil) then
  begin
    if ReadProcessMemory(AHandle, APtr, @PtrDllName, sizeof(PtrDllName), @ByteRead) then
    begin
      if (PtrDllName <> nil) then
      begin
        if ReadProcessMemory(AHandle, PtrDllName, @ImageName, sizeof(ImageName), @ByteRead) then
        begin
          if AUnicode <> 0 then
            Result := string(PWideChar(@ImageName))
          else
            Result := string(PChar(@ImageName));
        end;
      end;
    end
    else
    begin
      // if ReadProcessMemory failed
      FLogManager.Log('ReadProcessMemory error: ' + SysErrorMessage(GetLastError));
      if GetModuleFileNameEx (AHandle, HMODULE(AlpBaseOfDll), ImageName, MAX_PATH) = 0 then
        FLogManager.Log('GetModuleFileNameEx error: ' + SysErrorMessage(GetLastError))
      else
        Result := string(PWideChar(@ImageName));
    end;
  end;
end;

procedure TDebugger.HandleCreateProcess(const ADebugEvent: DEBUG_EVENT);
var
  DebugThread: IDebugThread;
  ProcessName: String;
  PEImage: TJCLPEImage;
  Size: Cardinal;
begin
  ProcessName := FCoverageConfiguration.ExeFileName;

  PEImage := TJCLPEImage.Create;
  try
    PEImage.FileName := ProcessName;
    Size := PEImage.OptionalHeader32.SizeOfCode;
  finally
    PEImage.Free;
  end;

  FLogManager.Log('Create Process:' + IntToStr(ADebugEvent.dwProcessId) + ' name:' + ProcessName);

  FDebugProcess := TDebugProcess.Create(
    ADebugEvent.dwProcessId,
    ADebugEvent.CreateProcessInfo.hProcess,
    DWORD(ADebugEvent.CreateProcessInfo.lpBaseOfImage),
    ProcessName,
    Size,
    FMapScanner,
    FLogManager);

  DebugThread := TDebugThread.Create(
    ADebugEvent.dwThreadId,
    ADebugEvent.CreateProcessInfo.hThread);

  FDebugProcess.AddThread(DebugThread);

  try
    AddBreakPoints(
      FCoverageConfiguration.Units(),
      FCoverageConfiguration.ExcludedUnits(),
      FDebugProcess,
      FMapScanner,
      FCoverageConfiguration.ModuleNameSpace(ExtractFileName(ProcessName)),
      FCoverageConfiguration.UnitNameSpace(ExtractFileName(ProcessName)));

  except
    on E: Exception do
    begin
      FLogManager.Log(
        'Exception during add breakpoints:' + E.Message + ' ' + E.ToString());
    end;
  end;
end;

procedure TDebugger.HandleCreateThread(const ADebugEvent: DEBUG_EVENT);
var
  DebugThread: IDebugThread;
begin
  FLogManager.Log('Create thread:' + IntToStr(ADebugEvent.dwThreadId));

  DebugThread := TDebugThread.Create(
    ADebugEvent.dwThreadId,
    ADebugEvent.CreateThread.hThread);

  FDebugProcess.AddThread(DebugThread);
end;

procedure TDebugger.HandleExceptionDebug(
  const ADebugEvent: DEBUG_EVENT;
  var AContProcessEvents: Boolean;
  var ADebugEventHandlingResult: DWORD);
var
  DebugThread: IDebugThread;
  BreakPoint: IBreakPoint;
  BreakPointDetailIndex: Integer;
  ExceptionRecord: EXCEPTION_RECORD;
  Module: IDebugModule;
  MapScanner: TJCLMapScanner;
  ContextRecord: TContext;
begin
  ADebugEventHandlingResult := Cardinal(DBG_EXCEPTION_NOT_HANDLED);

  ExceptionRecord := ADebugEvent.Exception.ExceptionRecord;
  Module := FDebugProcess.FindDebugModuleFromAddress(ExceptionRecord.ExceptionAddress);
  if Assigned(Module) then
    MapScanner := Module.MapScanner
  else
    MapScanner := nil;

  case ExceptionRecord.ExceptionCode of
    Cardinal(EXCEPTION_ACCESS_VIOLATION):
      begin
        FLogManager.Log(
          'ACCESS VIOLATION at Address:' + IntToHex(Integer(ExceptionRecord.ExceptionAddress), 8));
        FLogManager.Log(IntToHex(ExceptionRecord.ExceptionCode, 8) + ' not a debug BreakPoint');

        if ExceptionRecord.NumberParameters > 1 then
        begin
          if ExceptionRecord.ExceptionInformation[0] = 0 then
            FLogManager.Log('Tried to read');
          if ExceptionRecord.ExceptionInformation[0] = 1 then
            FLogManager.Log('Tried to write');
          if ExceptionRecord.ExceptionInformation[0] = 8 then
            FLogManager.Log('DEP exception');

          FLogManager.Log(
            'Trying to access Address:' + IntToHex(Integer(ExceptionRecord.ExceptionInformation[1]), 8));

          if Assigned(MapScanner) then
          begin
            for BreakPointDetailIndex := 0 to MapScanner.LineNumbersCnt - 1 do
            begin
              if MapScanner.LineNumberByIndex[BreakPointDetailIndex].VA = VAFromAddress(
                ExceptionRecord.ExceptionAddress, Module.Base) then
              begin
                FLogManager.Log(
                  MapScanner.ModuleNameFromAddr(MapScanner.LineNumberByIndex[BreakPointDetailIndex].VA) +
                  ' line ' + IntToStr(MapScanner.LineNumberByIndex[BreakPointDetailIndex].LineNumber));
                break;
              end;
            end;
          end
          else
          begin
            if not Assigned(Module) then
              FLogManager.Log(
                'No map information available Address:' +
                IntToHex(Integer(ExceptionRecord.ExceptionInformation[1]), 8) +
                ' in unknown module')
            else
              FLogManager.Log(
                'No map information available Address:' +
                IntToHex(Integer(ExceptionRecord.ExceptionInformation[1]), 8) +
                ' module ' + Module.Name);
          end;

          LogStackFrame(ADebugEvent);
        end;
      end;

    // Cardinal(EXCEPTION_ARRAY_BOUNDS_EXCEEDED) :
    Cardinal(EXCEPTION_BreakPoint):
      begin
        BreakPoint := FBreakPointList.BreakPointByAddress[
          ExceptionRecord.ExceptionAddress
        ];
        if Assigned(BreakPoint) then
        begin
          for BreakPointDetailIndex := 0 to Pred(BreakPoint.DetailCount) do
            FLogManager.Log(
              'Adding coverage:' +
                BreakPoint.DetailByIndex(BreakPointDetailIndex).UnitName +
                ' (' + BreakPoint.DetailByIndex(BreakPointDetailIndex).ModuleName + ') ' +
                IntToStr(BreakPoint.DetailByIndex(BreakPointDetailIndex).Line));

          DebugThread := FDebugProcess.GetThreadById(ADebugEvent.dwThreadId);
          if (DebugThread <> nil) then
          begin
            if (BreakPoint.IsActive) then
            begin
              BreakPoint.IncBreakCount;
              if BreakPoint.BreakCount < FCoverageConfiguration.LineCountLimit then
              begin
                BreakPoint.DeActivate; // Breakpoint will be reset after STEP
                ContextRecord.ContextFlags := CONTEXT_CONTROL;
                if GetThreadContext(DebugThread.Handle, ContextRecord) then
                begin
                  // Rewind to previous instruction
                  Dec(ContextRecord.Eip);
                  // Set TF (Trap Flag so we get debug exception after next instruction
                  ContextRecord.EFlags := ContextRecord.EFlags or $100;
                  SetThreadContext(DebugThread.Handle, ContextRecord);
                end;
                FLastBreakPoint := BreakPoint;
              end
              else // Breakpoint has exceeded CountLimit, so is not needed again
              begin
                BreakPoint.Clear(DebugThread);
              end;
            end
            else
            begin
              FLogManager.Log('BreakPoint already cleared - BreakPoint in source?');
            end;
          end
          else
            FLogManager.Log('Couldn''t find thread:' + IntToStr(ADebugEvent.dwThreadId));
        end
        else
        begin
          // A good contender for this is ntdll.DbgBreakPoint {$7C90120E}
          FLogManager.Log(
            'Couldn''t find BreakPoint for exception address:' +
            IntToHex(Integer(ExceptionRecord.ExceptionAddress), 8));
        end;
        ADebugEventHandlingResult := Cardinal(DBG_CONTINUE);
      end;
    Cardinal(EXCEPTION_SINGLE_STEP):
      begin
        // This is triggered after a breakpoint by TF - it is automatically reset by the interrupt
        // We need to let the breakpoint instruction execute, then reset the breakpoint
        if Assigned(FLastBreakPoint) then
        begin
          FLastBreakPoint.Activate;
          FLastBreakPoint := nil;
        end;
        ADebugEventHandlingResult := Cardinal(DBG_CONTINUE);
      end;

    Cardinal(EXCEPTION_DATATYPE_MISALIGNMENT):
      begin
        FLogManager.Log(
          'EXCEPTION_DATATYPE_MISALIGNMENT Address:' +
          IntToHex(Integer(ExceptionRecord.ExceptionAddress), 8));
        FLogManager.Log(
          IntToHex(ExceptionRecord.ExceptionCode, 8) + ' not a debug BreakPoint');
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
      FLogManager.Log('EXCEPTION CODE:' + IntToHex(ExceptionRecord.ExceptionCode, 8));
      FLogManager.Log('Address:' + IntToHex(Integer(ExceptionRecord.ExceptionAddress), 8));
      FLogManager.Log('EXCEPTION flags:' + IntToHex(ExceptionRecord.ExceptionFlags, 8));
      LogStackFrame(ADebugEvent);
    end;
  end
end;

procedure TDebugger.LogStackFrame(const ADebugEvent: DEBUG_EVENT);
var
  ContextRecord: TContext;
  StackFrame: TSTACKFRAME64;
  LineIndex: Integer;
  MapLineNumber: TJclMapLineNumber;
  DebugThread: IDebugThread;
  Module: IDebugModule;
  MapScanner: TJCLMapScanner;
begin
  ContextRecord.ContextFlags := CONTEXT_ALL;

  DebugThread := FDebugProcess.GetThreadById(ADebugEvent.dwThreadId);

  if DebugThread <> nil then
  begin
    if GetThreadContext(DebugThread.Handle, ContextRecord) then
    begin
      FillChar(StackFrame, SizeOf(StackFrame), 0);
      StackFrame.AddrPC.Offset := ContextRecord.Eip;
      StackFrame.AddrPC.Mode := AddrModeFlat;
      StackFrame.AddrFrame.Offset := ContextRecord.Ebp;
      StackFrame.AddrFrame.Mode := AddrModeFlat;
      StackFrame.AddrStack.Offset := ContextRecord.Esp;
      StackFrame.AddrStack.Mode := AddrModeFlat;

      StackWalk64(
        IMAGE_FILE_MACHINE_I386,
        FDebugProcess.Handle,
        DebugThread.Handle,
        StackFrame,
        @ContextRecord,
        @RealReadFromProcessMemory,
        nil, nil, nil);

      FLogManager.Log('---------------Stack trace --------------');
      while StackWalk64(
        IMAGE_FILE_MACHINE_I386,
        FDebugProcess.Handle,
        DebugThread.Handle,
        StackFrame,
        @ContextRecord,
        @RealReadFromProcessMemory,
        nil, nil, nil
      ) do
      begin
        if (StackFrame.AddrPC.Offset <> 0) then
        begin
          Module := FDebugProcess.FindDebugModuleFromAddress(Pointer(StackFrame.AddrPC.Offset));
          if (Module <> nil) then
          begin
            MapScanner := Module.MapScanner;

            FLogManager.Log(
              'Module : ' + Module.Name +
              ' Stack frame:' + IntToHex(Cardinal(Pointer(StackFrame.AddrPC.Offset)), 8));
            if Assigned(MapScanner) then
            begin
              for LineIndex := 0 to MapScanner.LineNumbersCnt - 1 do
              begin
                MapLineNumber := MapScanner.LineNumberByIndex[LineIndex];
                if MapLineNumber.VA =
                  VAFromAddress(Pointer(StackFrame.AddrPC.Offset), Module.Base) then
                begin
                  FLogManager.Log(
                    'Exact line:' + MapScanner.ModuleNameFromAddr(MapLineNumber.VA) +
                    ' line ' + IntToStr(MapLineNumber.LineNumber));
                  break;
                end
                else if (MapLineNumber.VA > VAFromAddress
                    (Pointer(StackFrame.AddrPC.Offset), Module.Base)) and
                  (VAFromAddress(Pointer(StackFrame.AddrPC.Offset),
                    Module.Base) < MapScanner.LineNumberByIndex[LineIndex + 1]
                    .VA) then
                begin
                  FLogManager.Log(
                    'After line:' + MapScanner.ModuleNameFromAddr(MapLineNumber.VA) +
                    ' line ' + IntToStr(MapLineNumber.LineNumber));
                  break;
                end;
              end;
            end
            else
              FLogManager.Log('Module : ' + Module.Name + ' - no MAP information exists');
          end
          else
          begin
            FLogManager.Log(
              'No module found for exception address:' +
              IntToHex(StackFrame.AddrPC.Offset, 8));
          end;
        end;
      end;
      FLogManager.Log('---------------End of Stack trace --------------');
    end
    else
      FLogManager.Log('Failed to get thread context : ' + I_LogManager.LastErrorInfo);
  end
  else
    FLogManager.Log('Thread not found : ' + IntToStr(ADebugEvent.dwThreadId));
end;

procedure TDebugger.HandleExitProcess(
  const ADebugEvent: DEBUG_EVENT;
  var AContProcessEvents: Boolean);
begin
  FTestExeExitCode := ADebugEvent.ExitProcess.dwExitCode;
  FLogManager.Log(
    'Process ' + IntToStr(ADebugEvent.dwProcessId) +
    ' exiting. Exit code :' + IntToStr(ADebugEvent.ExitProcess.dwExitCode));

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
  Module: TDebugModule;
  PEImage: TJCLPEImage;
  Size: Cardinal;
  MapFile: string;
  MapScanner: TJCLMapScanner;
  ModuleNameSpace: TModuleNameSpace;
begin
  ExtraMsg := '';
  DllName := GetImageName(
    ADebugEvent.LoadDll.lpImageName,
    ADebugEvent.LoadDll.fUnicode,
    ADebugEvent.LoadDll.lpBaseOfDll,
    FDebugProcess.Handle);

  if DllName = 'WOW64_IMAGE_SECTION' then
  begin
    FLogManager.Log('DllName = WOW64_IMAGE_SECTION');
    Exit;
  end;
  if DllName <> '' then
  begin
    PEImage := TJCLPEImage.Create;
    try
      PEImage.FileName := DllName;
      Size := PEImage.OptionalHeader32.SizeOfCode;
    finally
      PEImage.Free;
    end;

    if FDebugProcess.GetModule(DllName) = nil then
    begin
      MapFile := PathRemoveExtension(DllName) + '.map';

      if FileExists(MapFile) then
      begin
        FLogManager.Log('Loading map file:' + MapFile);
        MapScanner := TJCLMapScanner.Create(MapFile);
      end
      else
        MapScanner := nil;

      Module := TDebugModule.Create(
        DllName,
        HMODULE(ADebugEvent.LoadDll.lpBaseOfDll),
        Size,
        MapScanner);
      FDebugProcess.AddModule(Module);
      ExtraMsg := ' (' + DllName + ') size :' + IntToStr(Size);

      FLogManager.Log(
        'Loading DLL at addr:' + IntToHex(DWORD(ADebugEvent.LoadDll.lpBaseOfDll), 8) +
        ExtraMsg);

      ModuleNameSpace := FCoverageConfiguration.ModuleNameSpace(ExtractFileName(DllName));
      try
        AddBreakPoints(
          FCoverageConfiguration.Units,
          FCoverageConfiguration.ExcludedUnits,
          Module,
          MapScanner,
          ModuleNameSpace,
          FCoverageConfiguration.UnitNameSpace(ExtractFileName(DllName)));
      except
        on E: Exception do
        begin
          FLogManager.Log(
            'Exception during add breakpoints:' + E.Message + ' ' + E.ToString());
        end;
      end;
    end
    else
    begin
      FLogManager.Log(
        'WARNING: The module ' + DllName +
        ' was already loaded. Skipping breakpoint generation and coverage for subsequent load.');
    end;
  end;
end;

procedure TDebugger.HandleUnLoadDLL(const ADebugEvent: DEBUG_EVENT);
begin
  FLogManager.Log(
    'UnLoading DLL:' + IntToHex(DWORD(ADebugEvent.LoadDll.lpBaseOfDll), 8));
end;

procedure TDebugger.HandleOutputDebugString(const ADebugEvent: DEBUG_EVENT);
begin
end;

procedure TDebugger.HandleRip(const ADebugEvent: DEBUG_EVENT);
begin
end;

end.
