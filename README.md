# DotNetCore NSIS macro

This repository contains macro scripts intended to check whether a particular version of the dotnet
core runtime is installed and, if not, install it.

Currently only supports installing the appropriate WindowsDesktop runtime for the platform the
installer is running on (ARM64, X86 or X86).

# Usage

Include the macro header file
```
!include "DotNetCore.nsh"
```

Include one or more of the following to ensure the WindowsDesktop runtime for that version of
dotnet is installed
```
!insertmacro CheckDotNetCore 3.1
!insertmacro CheckDotNetCore 5.0
!insertmacro CheckDotNetCore 6.0
!insertmacro CheckDotNetCore 7.0
```
