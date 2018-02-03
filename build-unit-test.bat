@ECHO OFF
ECHO Building Delphi Code Coverage

CALL "SetupEnvironment.Bat"

msbuild /p:Platform=Win32 /t:build /p:config=Release /verbosity:detailed "%PRJDIR%\%PRJ%.dproj"


