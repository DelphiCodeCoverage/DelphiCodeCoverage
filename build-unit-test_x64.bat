@ECHO OFF
ECHO Building Delphi Code Coverage

CALL "SetupEnvironment.Bat"

msbuild /p:Platform=Win64 /t:build /p:config=Release /verbosity:detailed "%PRJDIR%\%PRJ%.dproj"


