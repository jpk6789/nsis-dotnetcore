; A set of NSIS macros to check whether a dotnet core runtime is installed and, if not, offer to
; download and install it. Currently only supports dotnet 6.
;
; Inspired by & initially based on NsisDotNetChecker, which does the same thing for .NET framework
; https://github.com/alex-sitnikov/NsisDotNetChecker

!ifndef DOTNETCORE_INCLUDED
!define DOTNETCORE_INCLUDED

; Check that a specific version of the dotnet core runtime is installed and, if not, attempts to
; install it
;
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 5.0, 6.0
!macro CheckDotNetCore Version

!insertmacro DotNetCoreGetLatestVersion ${Version}
Pop $0

DetailPrint "Latest Version of ${Version} is $0"

!macroend

; Gets the latest version of the runtime for a specified dotnet version. This uses the same endpoint
; as the dotnet-install scripts to determine the latest full version of a dotnet version
;
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 5.0, 6.0
;
; \returns The full version number of the latest version - e.g. 6.0.7
!macro DotNetCoreGetLatestVersion Version

Push $0
Push $1
Push $2

StrCpy $0 https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/${Version}/latest.version
DetailPrint "Fetching Latest Version of dotnet core ${Version} From $0"

; Fetch latest version of the desired dotnet version
; todo error handling in the PS script? so we can check for errors here
StrCpy $1 "Write-Host (Invoke-WebRequest -URI $\"$0$\").Content;"
!insertmacro DotNetCorePSExec $1
Pop $2 ; $2 contains latest version, e.g. 6.0.7

; todo error handling here

; Push the result back onto the stack
Push $2

; Restore $0-2
Exch
Pop $2
Exch
Pop $1
Exch
Pop $0

!macroend


; below is adapted from https://nsis.sourceforge.io/PowerShell_support but avoids using the plugin
; directory in favour of a temp file. Methods renamed to avoid conflicting with use of the original
; macros

!macro DotNetCorePSExec PSCommand

  ; Write the command into a temp file
  Push $R0
  Push $R1
  
  ; Note: Using GetTempFileName to get a temp file name, but since we need to have a .ps1 extension
  ; on the end we immediately delete the generated file and create our own with the right extension
  GetTempFileName $R0
  Delete $R0
  StrCpy $R0 "$R0.ps1"

  FileOpen $R1 $R0 w
  FileWrite $R1 "${PSCommand}"
  FileClose $R1
  Pop $R1
 
  !insertmacro DotNetCorePSExecFile $R0
  
  Delete $R0
  Exch
  Pop $R0
!macroend
 
!macro DotNetCorePSExecFile FilePath
  !define PSExecID ${__LINE__}
  Push $R0
 
  nsExec::ExecToStack 'powershell -inputformat none -ExecutionPolicy RemoteSigned -File "${FilePath}"  '
 
  Pop $R0 ;return value is first on stack
  ;script output is second on stack, leave on top of it
  IntCmp $R0 0 finish_${PSExecID}
  SetErrorLevel 2
 
finish_${PSExecID}:
  Exch ;now $R0 on top of stack, followed by script output
  Pop $R0
  !undef PSExecID
!macroend

!endif