# DotNetCore NSIS macro

This repository contains macro scripts intended to check whether a particular version of the dotnet
core runtime is installed and, if not, install it.

Very rough'n'ready at the moment with almost noerror handling and currently only supports installing
the WindowsDesktop runtime. Needs better UI feedback, possibly automatically switching to using
[Inetc](https://nsis.sourceforge.io/Inetc_plug-in) to perform the download with progress when the
plugin is available, and would probably benefit from a 'would you like to install... " prompt

Would also be good to handle a three digit version as a "minimum" or "exact" version in future,
possibly using > as a prefix for "minimum". Right now it just makes sure _any_ version of the
specified runtime is installed.

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
```
