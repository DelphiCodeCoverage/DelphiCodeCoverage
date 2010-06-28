(* ************************************************************ *)
(* Delphi Code Coverage *)
(* *)
(* A quick hack of a Code Coverage Tool for Delphi 2010 *)
(* by Christer Fahlgren *)
(* ************************************************************ *)
(* Licensed under Mozilla Public License 1.1 *)
(* ************************************************************ *)

unit Debugger;

interface

uses DebugProcess, DebugThread, classes, breakpoint, jcldebug, coverageresult,
  jwawindows, jwaimagehlp, Configuration;

type
  TDebugger = class
  private
    process: TDebugProcess;
    lpde: _DEBUG_EVENT;
    ms: TJCLMapScanner;
    bplist: TBreakpointList;
    quit: Boolean;
    Coverage: TCoverage;
    Configuration: TCoverageConfiguration;
  public
    constructor Create;
    procedure Start();

  private
    procedure HandleCreateProcess(var lpde: _DEBUG_EVENT);
    procedure HandleExceptionDebug(var lpde: _DEBUG_EVENT);
    procedure HandleCreateThread(var lpde: _DEBUG_EVENT);
    procedure HandleExitThread(var lpde: _DEBUG_EVENT);
    procedure HandleLoadDLL(var lpde: _DEBUG_EVENT);
    procedure HandleUnLoadDLL(var lpde: _DEBUG_EVENT);
    procedure HandleOutputDebugString(var lpde: _DEBUG_EVENT);
    function StartProcessToDebug(executable: string): Boolean;
    procedure Debug();
    function VAFromAddr(const Addr: Pointer): DWORD;
    function AddrFromVA(VA: DWORD): Pointer;
    procedure AddBreakPoints(list: TStrings);
    procedure PrintUsage;
  end;

function RealReadFromProcessMemory(hprocess: THANDLE; qwBaseAddress: DWORD64; lpBuffer: Pointer; size: DWORD;
  var numberofbytesread: DWORD): BOOL; stdcall;

implementation

uses sysutils, logger, strutils, CoverageReport;

constructor TDebugger.Create;
begin
  bplist := TBreakpointList.Create;
  Coverage := TCoverage.Create;
  Configuration := TCoverageConfiguration.Create;
end;

procedure TDebugger.Start();
begin
  try
    Configuration.ParseCommandLine();
    Debug();
  except
    on e: ECOnfigurationException do
    begin
      writeln('Exception parsing the command line:' + e.message);
      PrintUsage();
    end;
  end;
end;

procedure TDebugger.PrintUsage();
begin
  writeln('Usage:CodeCoverage.exe [switches]');
  writeln('List of switches:');
  writeln('-e executable.exe   -- the executable to run                  -- MANDATORY');
  writeln('-m mapfile.map      -- the mapfile to use                     -- OPTIONAL');
  writeln('-u unit1 unit2 etc  -- a list of units to create reports for  -- MANDATORY');
  writeln('-sd directory       -- the directory where source code is ');
  writeln('                       located - default is current directory -- OPTIONAL');
  writeln('-od directory       -- the output directory where reports ');
  writeln('                       shall be generated, default is ');
  writeln('                       current directory                      -- OPTIONAL');
  writeln('-a param param2 etc -- a list of parameters to be passed to');
  writeln('                       the application. Escape character:\    -- OPTIONAL');
end;

function TDebugger.VAFromAddr(const Addr: Pointer): DWORD;
begin
  result := DWORD_PTR(Addr) - process.GetModule() - $1000;
end;

function TDebugger.AddrFromVA(VA: DWORD): Pointer;
begin
  result := Pointer(DWORD_PTR(VA + process.GetModule() + $1000));
end;

procedure TDebugger.AddBreakPoints(list: TStrings);
var
  I: Integer;
  bp: TBreakpoint;
  coverageunit: TUnitCoverage;
  modulename: string;
  segment: TJclMapSegment;
begin

  for I := 0 to ms.LineNumberCount - 1 do
  begin
    if (ms.LineNumberbyindex[I].segment = 1) then
    begin
      modulename := ms.mapstringToStr(ms.LineNumberbyindex[I].UnitName);

      if list.indexof(modulename) > -1 then
      begin
        if modulename = ms.ModuleNameFromAddr(ms.LineNumberbyindex[I].VA) then
        begin
          coverageunit := Coverage.GetUnit(ms.ModuleNameFromAddr(ms.LineNumberbyindex[I].VA));
          if not(coverageunit.alreadycovered(ms.LineNumberbyindex[I].LineNumber)) then
          begin
            coverageunit.AddLineCoverage(ms.LineNumberbyindex[I].LineNumber, false);
            log.log('Setting breakpoint:' + inttostr(I));
            bp := TBreakpoint.Create(process, AddrFromVA(ms.LineNumberbyindex[I].VA),
              ms.LineNumberbyindex[I].LineNumber, ms.ModuleNameFromAddr(ms.LineNumberbyindex[I].VA));
            bplist.AddBreakpoint(bp);
            if not(bp.Activate) then
              log.log('BP FAILED to activate successfully');
          end;
        end
        else
          log.log('Module name:' + modulename + ' did not match module name:' + ms.ModuleNameFromAddr
              (ms.LineNumberbyindex[I].VA) + ' from Addr:' + inttohex(ms.LineNumberbyindex[I].VA, 8));
      end
      else
        log.log('Module name:' + modulename + ' not in list');
    end;
  end;
  log.log('AddBreakPoints completed.');

end;

procedure TDebugger.HandleCreateProcess(var lpde: _DEBUG_EVENT);
var
  thread: TDebugThread;

begin
  log.log('Create process:' + inttostr(lpde.dwProcessId));
  process := TDebugProcess.Create(lpde.dwProcessId, lpde.CreateProcessInfo.hprocess,
    DWORD(lpde.CreateProcessInfo.lpBaseOfImage));
  thread := TDebugThread.Create(lpde.dwThreadId, lpde.CreateProcessInfo.hthread);
  process.addThread(thread);
  AddBreakPoints(Configuration.getUnits());
end;

procedure TDebugger.HandleExceptionDebug(var lpde: _DEBUG_EVENT);
var
  thr: TDebugThread;
  bp: TBreakpoint;
  coverageunit: TUnitCoverage;
  jclstackinfo: TJclStackInfoList;
  stringlist: TStringList;
  I: Integer;
  stackwalkresult: BOOL;
  stckframe: TSTACKFRAME64;
  contextrecord: TContext;
  result: BOOL;
begin
  case lpde.Exception.ExceptionRecord.ExceptionCode of
    Cardinal(EXCEPTION_BREAKPOINT):
      begin
        bp := bplist.GetBreakPointByAddress(lpde.Exception.ExceptionRecord.ExceptionAddress);
        if bp <> nil then
        begin
          coverageunit := Coverage.GetUnit(bp.GetUnitName());
          coverageunit.ModifyLineCoverage(bp.GetLineNumber(), true);
          log.log('adding coverage:' + bp.GetUnitName() + ' ' + inttostr(bp.GetLineNumber()));
          thr := process.GetThreadById(lpde.dwThreadId);
          if (thr <> nil) then
            bp.clear(thr)
          else
            log.log('Couldnt find thread:' + inttostr(lpde.dwThreadId));
        end
        else
          log.log('couldnt find breakpoint for exceptionAddress:' + inttohex
              (Integer(lpde.Exception.ExceptionRecord.ExceptionAddress), 8));
      end;
    Cardinal(EXCEPTION_ACCESS_VIOLATION):
      begin
        log.log('ACCESS VIOLATION at Address:' + inttohex(Integer(lpde.Exception.ExceptionRecord.ExceptionAddress), 8));
        log.log(inttohex(lpde.Exception.ExceptionRecord.ExceptionCode, 8) + ' not a debug breakpoint');
        if lpde.Exception.ExceptionRecord.NumberParameters > 1 then
        begin
          if lpde.Exception.ExceptionRecord.ExceptionInformation[0] = 0 then
            log.log('Tried to read');
          if lpde.Exception.ExceptionRecord.ExceptionInformation[0] = 1 then
            log.log('Tried to write');
          if lpde.Exception.ExceptionRecord.ExceptionInformation[0] = 8 then
            log.log('DEP exception');
          log.log('Trying to access Address:' + inttohex
              (Integer(lpde.Exception.ExceptionRecord.ExceptionInformation[1]), 8));
          for I := 0 to ms.LineNumberCount - 1 do
          begin
            if ms.LineNumberbyindex[I].VA = VAFromAddr(lpde.Exception.ExceptionRecord.ExceptionAddress) then
            begin
              log.log(ms.ModuleNameFromAddr(ms.LineNumberbyindex[I].VA) + ' line ' + inttostr
                  (ms.LineNumberbyindex[I].LineNumber));
              break;
            end;
          end;

          contextrecord.contextflags := CONTEXT_ALL;
          result := GetThreadContext(process.GetThreadById(lpde.dwThreadId).GetHandle, contextrecord);
          if (result <> false) then
          begin
            fillchar(stckframe, sizeof(stckframe), #0);
            stckframe.AddrPC.Offset := contextrecord.Eip;
            stckframe.AddrPC.Mode := AddrModeFlat;
            stckframe.AddrFrame.Offset := contextrecord.Ebp;
            stckframe.AddrFrame.Mode := AddrModeFlat;
            stckframe.AddrStack.Offset := contextrecord.Esp;
            stckframe.AddrStack.Mode := AddrModeFlat;
            stackwalkresult := StackWalk64(IMAGE_FILE_MACHINE_I386, process.GetHandle,
              process.GetThreadById(lpde.dwThreadId).GetHandle, stckframe, @contextrecord, @RealReadFromProcessMemory,
              nil, nil, nil);
            while StackWalk64(IMAGE_FILE_MACHINE_I386, process.GetHandle,
              process.GetThreadById(lpde.dwThreadId).GetHandle, stckframe, @contextrecord, @RealReadFromProcessMemory,
              nil, nil, nil) do
            begin
              if (stckframe.AddrPC.Offset <> 0) then
              begin
                log.log('Stack frame:' + inttohex(Cardinal(Pointer(stckframe.AddrPC.Offset)), 8));
                for I := 0 to ms.LineNumberCount - 1 do
                begin
                  if ms.LineNumberbyindex[I].VA = VAFromAddr(Pointer(stckframe.AddrPC.Offset)) then
                  begin
                    log.log('STACK:' + ms.ModuleNameFromAddr(ms.LineNumberbyindex[I].VA) + ' line ' + inttostr
                        (ms.LineNumberbyindex[I].LineNumber));
                    break;
                  end
                  else if (ms.LineNumberbyindex[I].VA > VAFromAddr(Pointer(stckframe.AddrPC.Offset))) and
                    (VAFromAddr(Pointer(stckframe.AddrPC.Offset)) < ms.LineNumberbyindex[I + 1].VA) then
                  begin
                    log.log('AFTER STACK:' + ms.ModuleNameFromAddr(ms.LineNumberbyindex[I].VA) + ' line ' + inttostr
                        (ms.LineNumberbyindex[I].LineNumber));
                    break;
                  end;
                end;
              end;
            end;

          end
          else
            log.log('Failed to get thread context   ' + inttohex(getlasterror(), 8));
        end;
        quit := true;
      end;

    Cardinal(EXCEPTION_DATATYPE_MISALIGNMENT):
      begin
        log.log('EXCEPTION_DATATYPE_MISALIGNMENT Address:' + inttohex
            (Integer(lpde.Exception.ExceptionRecord.ExceptionAddress), 8));
        log.log(inttohex(lpde.Exception.ExceptionRecord.ExceptionCode, 8) + ' not a debug breakpoint');
        quit := true;
      end;
  else
    begin
      log.log('EXCEPTION CODE:' + inttohex(lpde.Exception.ExceptionRecord.ExceptionCode, 8));
      log.log('Address:' + inttohex(Integer(lpde.Exception.ExceptionRecord.ExceptionAddress), 8));
      log.log('EXCEPTION flags:' + inttohex(lpde.Exception.ExceptionRecord.ExceptionFlags, 8));
    end;
  end
end;

procedure TDebugger.HandleCreateThread(var lpde: _DEBUG_EVENT);
var
  thread: TDebugThread;
begin
  log.log('Thread create:' + inttostr(lpde.dwThreadId));
  thread := TDebugThread.Create(lpde.dwThreadId, lpde.CreateThread.hthread);
  process.addThread(thread);
end;

procedure TDebugger.HandleExitThread(var lpde: _DEBUG_EVENT);
begin
  log.log('Thread exit:' + inttostr(lpde.dwThreadId));
  process.RemoveThread(lpde.dwThreadId);
end;

procedure TDebugger.HandleLoadDLL(var lpde: _DEBUG_EVENT);
begin
  log.log('Loading DLL at addr:' + inttohex(DWORD(lpde.LoadDll.lpBaseOfDll), 8));
end;

procedure TDebugger.HandleUnLoadDLL(var lpde: _DEBUG_EVENT);
begin
  log.log('UnLoading DLL:' + inttohex(DWORD(lpde.LoadDll.lpBaseOfDll), 8));
end;

procedure TDebugger.HandleOutputDebugString(var lpde: _DEBUG_EVENT);
begin
  // log.Log('Outputdebugstring:' + lpde.DebugString.lpDebugStringData);
end;

function TDebugger.StartProcessToDebug(executable: string): Boolean;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CreateOK: Boolean;
  parameters: string;
begin
  parameters := Configuration.getApplicationParameters;
  fillchar(StartInfo, sizeof(TStartupInfo), #0);
  fillchar(ProcInfo, sizeof(TProcessInformation), #0);
  StartInfo.cb := sizeof(TStartupInfo);
  CreateOK := CreateProcess(pchar(executable), pchar(parameters), nil, nil, false,
    CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS + DEBUG_PROCESS, nil, nil, StartInfo, ProcInfo);
  result := CreateOK = true;
end;

procedure TDebugger.Debug();
var
  I: Integer;
  mappath: string;
  waitok: Boolean;
  continueok: Boolean;
  Projectitem: string;
  startedok: Boolean;
  report: TCoverageReport;
begin
  try
    if Configuration.isComplete() then
    begin
      ms := TJCLMapScanner.Create(Configuration.getmapfile());
      startedok := StartProcessToDebug(Configuration.getexecutable());
      if startedok then
      begin
        quit := false;
        while (quit <> true) do
        begin
          waitok := waitfordebugevent(lpde, 1000);
          if waitok then
          begin
            case lpde.dwDebugEventCode of
              CREATE_PROCESS_DEBUG_EVENT:
                HandleCreateProcess(lpde);
              EXCEPTION_DEBUG_EVENT:
                HandleExceptionDebug(lpde);
              CREATE_THREAD_DEBUG_EVENT:
                HandleCreateThread(lpde);
              EXIT_THREAD_DEBUG_EVENT:
                HandleExitThread(lpde);
              EXIT_PROCESS_DEBUG_EVENT:
                quit := true;
              LOAD_DLL_DEBUG_EVENT:
                HandleLoadDLL(lpde);
              UNLOAD_DLL_DEBUG_EVENT:
                HandleUnLoadDLL(lpde);
              OUTPUT_DEBUG_STRING_EVENT:
                HandleOutputDebugString(lpde);
            end;
            continueok := ContinueDebugEvent(lpde.dwProcessId, lpde.dwThreadId, DBG_CONTINUE);
          end
          else
            log.log('wait timed out');
        end;
        Coverage.CalculateStatistics();
        report := TCoverageReport.Create;
        report.generate(Coverage, Configuration.getsourcedir, Configuration.getoutputdir);
      end
      else
        writeln('Didn''t start ok');
    end
    else
      PrintUsage();
  except
    on e: Exception do
      writeln(e.ClassName, ': ', e.message);
  end;
end;

function RealReadFromProcessMemory(hprocess: THANDLE; qwBaseAddress: DWORD64; lpBuffer: Pointer; size: DWORD;
  var numberofbytesread: DWORD): BOOL; stdcall;
var
  bRet: BOOL;
  st: DWORD;
begin
  bRet := ReadProcessMemory(hprocess, Pointer(qwBaseAddress), lpBuffer, size, @st);
  numberofbytesread := st;
  result := bRet;
end;

initialization

end.
