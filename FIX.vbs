' Short name — same as DOUBLE-CLICK-ME.vbs (local zip only, no website)
Option Explicit
Dim fso, shell, p
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
p = fso.GetParentFolderName(WScript.ScriptFullName) & "\DOUBLE-CLICK-ME.vbs"
If fso.FileExists(p) Then
  shell.Run "wscript.exe """ & p & """", 1, False
Else
  MsgBox "Put FIX.vbs next to DOUBLE-CLICK-ME.vbs in your StrokeIQ folder.", vbCritical, "SwimIQ"
End If
