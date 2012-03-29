:: setup following environment variables to point to correct location of external libraries
if not defined JCL set JCL=C:\lib\jcl\jcl
if not defined JWAPI set JWAPI=C:\Users\christer\Downloads\jedi_api22a_jwscl092a\jwapi2.2a
if not defined JVCL set JVCL=C:\lib\jvcl\jvcl

if defined PROGRAMFILES(X86) (
  set DELPHIPROGRAMFILES=%PROGRAMFILES(X86)%
) else (
  set DELPHIPROGRAMFILES=%PROGRAMFILES%
)

:: check for Delphi XE2
if exist "%DELPHIPROGRAMFILES%\Embarcadero\RAD Studio\9.0\bin\rsvars.bat1" (
  Call "%DELPHIPROGRAMFILES%\Embarcadero\RAD Studio\9.0\bin\rsvars.bat"
) else (
:: Delphi 2010
  Call "%DELPHIPROGRAMFILES%\Embarcadero\RAD Studio\7.0\bin\rsvars.bat"
)
