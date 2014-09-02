@ECHO OFF
ECHO Building Delphi Code Coverage

CALL "SetupEnvironment.Bat"

msbuild /p:Platform=Win64 /p:DCC_UnitSearchPath="$(BDS)\lib;$(BDS)\include;..;%LIBS%;%JWAPI%\Win32API;%JWAPI%\Common;%JCL%\source\include;%JCL%\source\common;%JCL%\source\windows;%JVCL%\run;%JVCL%\Common;$(DCC_UnitSearchPath)" /t:build /p:config=Release /verbosity:detailed "%PRJDIR%\%PRJ%.dproj"


