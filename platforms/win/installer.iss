
[Setup]
AppName=gPolynomial
AppVersion=0.1
DefaultDirName={pf}\gPolynomial
DefaultGroupName=gPolynomial
OutputDir=..\..\installer

[Files]
Source: "..\..\gPolynomial.exe"; DestDir: "{app}"
Source: "..\..\gui.glade"; DestDir: "{app}"
Source: "C:\Program Files (x86)\Gtk-Runtime\bin\*.dll"; DestDir: "{app}"

[Icons]
Name: "{group}\gPolynomial"; Filename: "{app}\gPolynomial.exe"
Name: "{group}\Uninstall gPolynomial"; Filename: "{uninstallexe}"
