' Short name — same as DOUBLE-CLICK-ME.vbs
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
p = fso.GetParentFolderName(WScript.ScriptFullName) & "\DOUBLE-CLICK-ME.vbs"
If fso.FileExists(p) Then
  sh.Run "wscript.exe """ & p & """", 1, False
Else
  MsgBox "Put FIX.vbs next to DOUBLE-CLICK-ME.vbs in your StrokeIQ folder.", vbCritical, "SwimIQ"
End If
