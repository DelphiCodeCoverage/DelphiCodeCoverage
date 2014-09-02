@ECHO OFF

ECHO Running unit tests

CALL "SetupEnvironment.bat"
PUSHD %BUILD%\Win32

%PRJ%.exe

POPD