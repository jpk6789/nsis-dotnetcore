; A set of NSIS macros to check whether a dotnet core runtime is installed and, if not, offer to
; download and install it. Currently only supports dotnet 6.
;
; Inspired by & initially based on NsisDotNetChecker, which does the same thing for .NET framework
; https://github.com/alex-sitnikov/NsisDotNetChecker

!include "WordFunc.nsh"
!include "TextFunc.nsh"

!ifndef DOTNETCORE_INCLUDED
!define DOTNETCORE_INCLUDED

; Check that a specific version of the dotnet core runtime is installed and, if not, attempts to
; install it
;
; \param Version The desired dotnet core runtime version as a 2 digit version. e.g. 3.1, 5.0, 6.0
!macro CheckDotNetCore Version
!define ID ${__LINE__}

; Check current installed version
!insertmacro DotNetCoreGetInstalledVersion ${Version}
Pop $0

; If $0 is blank then there is no version installed, otherwise it is installed
; todo in future we might want to support "must be at least 6.0.7", for now we only deal with "yes/no" for a major version (e.g. 6.0)
StrCmp $0 "" notinstalled_${ID}
DetailPrint "dotnet version $0 already installed"
Goto end_${ID}

notinstalled_${ID}:
DetailPrint "dotnet ${Version} is not installed"

!insertmacro DotNetCoreGetLatestVersion ${Version}
Pop $0

DetailPrint "Latest Version of ${Version} is $0"


; Get number of input digits
; ${WordFind} $0 "." "#" $R0
; DetailPrint "version parts count is $R0"

; ${WordFind} $0 "." "+1" $R1
; DetailPrint "version part 1 is $R1"

; ${WordFind} $0 "." "+2" $R2
; DetailPrint "version part 2 is $R2"

; ${WordFind} $0 "." "+3" $R3
; DetailPrint "version part 3 is $R3"

!insertmacro DotNetCoreInstallVersion $0


end_${ID}:

!undef ID
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
DetailPrint "Fetching Latest Version of dotnet core ${Version} from $0"

; Fetch latest version of the desired dotnet version
; todo error handling in the PS script? so we can check for errors here
StrCpy $1 "Write-Host (Invoke-WebRequest -UseBasicParsing -URI $\"$0$\").Content;"
!insertmacro DotNetCorePSExec $1 $2
; $2 contains latest version, e.g. 6.0.7

; todo error handling here

; Push the result back onto the stack
${TrimNewLines} $2 $2
Push $2

; Restore $0-2
Exch
Pop $2
Exch
Pop $1
Exch
Pop $0

!macroend

!macro DotNetCoreGetInstalledVersion Version
!define DNC_INS_ID ${__LINE__}

Push $0
Push $1

DetailPrint "Checking installed version of dotnet core ${Version}"

StrCpy $0 "dotnet --list-runtimes | % { if($$_ -match $\".*WindowsDesktop.*(${Version}.\d+).*$\") { $$matches[1] } } | Sort-Object {[int]($$_ -replace '\d.\d.(\d+)', '$$1')} -Descending | Select-Object -first 1"
!insertmacro DotNetCorePSExec $0 $1
; $1 contains highest installed version, e.g. 6.0.7

${TrimNewLines} $1 $1

; If there is an installed version it should start with the same two "words" as the input version,
; otherwise assume we got an error response

; todo improve this simple test which checks there are at least 3 "words" separated by periods
${WordFind} $1 "." "E#" $0
IfErrors error_${DNC_INS_ID}

; If less than 3 "words", error
IntCmp $0 3 0 error_${DNC_INS_ID}

; If more than 4 "words", error
IntCmp $0 4 0 0 error_${DNC_INS_ID}

Goto end_${DNC_INS_ID}

; todo error handling here

error_${DNC_INS_ID}:
StrCpy $1 "" ; Set result to blank string if any error occurs (means not installed)

end_${DNC_INS_ID}:
!undef DNC_INS_ID

; Push the result back onto the stack
Push $1

; Restore $0-1
Exch
Pop $1
Exch
Pop $0

!macroend

!macro DotNetCoreInstallVersion Version

Push $R0
Push $R1
Push $R2

GetTempFileName $R0
Rename $R0 "$R0.exe"
StrCpy $R0 "$R0.exe"

; todo can download as a .zip, which is smaller, then we'd need to unzip it before running it...
StrCpy $R1 https://dotnetcli.azureedge.net/dotnet/WindowsDesktop/${Version}/windowsdesktop-runtime-${Version}-win-x64.exe
DetailPrint "Downloading dotnet ${Version} from $R1"

;$PayloadURL = "$AzureFeed/WindowsDesktop/$SpecificVersion/windowsdesktop-runtime-$SpecificProductVersion-win-$CLIArchitecture.zip"

;below v5
;$PayloadURL = "$AzureFeed/Runtime/$SpecificVersion/windowsdesktop-runtime-$SpecificProductVersion-win-$CLIArchitecture.zip"

; Fetch runtime installer
; todo error handling in the PS script? so we can check for errors here
StrCpy $R2 "Invoke-WebRequest -UseBasicParsing -URI $\"$R1$\" -OutFile $\"$R0$\""
!insertmacro DotNetCorePSExec $R2 $R2
; $R2 contains powershell script result

DetailPrint "Download complete"

DetailPrint "Installing dotnet ${Version}"
ExecWait "$\"$R0$\" /install /quiet /norestart" $R2
DetailPrint "Installer completed (Result: $R2)"

Delete $R0

; Error checking? Verify download result?

Pop $R2
Pop $R1
Pop $R0

!macroend

; below is adapted from https://nsis.sourceforge.io/PowerShell_support but avoids using the plugin
; directory in favour of a temp file and providing a return variable rather than returning on the
; stack. Methods renamed to avoid conflicting with use of the original macros

; DotNetCorePSExec
; Executes a powershell script
;
; \param[in] PSCommand The powershell command or script to execute
; \param[out] Result The output from the powershell script
!macro DotNetCorePSExec PSCommand Result

  ; Save variables
  Push $R0
  Push $R1
  Push $R2

  ; Push and pop parameters so we don't have conflicts if ${PSCommand} is $R0-2
  Push ${PSCommand}
  Pop $R0 ; Powershell command

  ; Write the command into a temp file
  ; Note: Using GetTempFileName to get a temp file name, but since we need to have a .ps1 extension
  ; on the end we rename it with an extra file extension
  GetTempFileName $R1
  Rename $R1 "$R1.ps1"
  StrCpy $R1 "$R1.ps1"

  FileOpen $R2 $R1 w
  FileWrite $R2 $R0
  FileClose $R2

  ; Execute the powershell script and delete the temp file
  !insertmacro DotNetCorePSExecFile $R1
  Delete $R1

  ; Restore registers
  Exch
  Pop $R2
  Exch
  Pop $R1
  Exch
  Pop $R0

  ; Fetch result
  Pop ${Result}

!macroend

; DotNetCorePSExecFile
; Executes a powershell file
;
; \param[in] FilePath The path to the powershell script file to execute
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