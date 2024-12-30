# DotNetCore NSIS macro

This repository contains macro scripts intended to check whether a particular version of the dotnet
core runtime is installed and, if not, install it.

All current runtimes (as of early 2025) can be installed checked and installed (dotnet, AspNetCore, WindowsDesktop).

The platform will be detected during installation and the appropriate runtime installer will be used.
Supports `ARM64`, `X86` and `X86` platforms.

# Usage

Include the macro header file
```
!include "DotNetCore.nsh"
```

Include one or more of the following to ensure the dotnet runtime for that version of
dotnet is installed
```
!insertmacro CheckDotNetCore 3.1
!insertmacro CheckDotNetCore 5.0
!insertmacro CheckDotNetCore 6.0
!insertmacro CheckDotNetCore 7.0
...
```

Include one or more of the following to ensure the AspNetCore runtime for that version of
dotnet is installed
```
!insertmacro CheckAspNetCore 3.1
!insertmacro CheckAspNetCore 5.0
!insertmacro CheckAspNetCore 6.0
!insertmacro CheckAspNetCore 7.0
...
```

Include one or more of the following to ensure the WindowsDesktop runtime for that version of
dotnet is installed
```
!insertmacro CheckWindowsDesktop 3.1
!insertmacro CheckWindowsDesktop 5.0
!insertmacro CheckWindowsDesktop 6.0
!insertmacro CheckWindowsDesktop 7.0
...
```