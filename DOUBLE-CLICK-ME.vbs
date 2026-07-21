' SwimIQ — double-click this file (OneDrive-safe; .bat files often disappear)
' Finds your real StrokeIQ folder, makes sure the CONNECTED zip is ready,
' and opens the upload folder. No browser typing required.
Option Explicit

Dim shell, fso, desktop, oneDrive, root, uploadDir, zipPath, howPath, found
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

desktop = shell.SpecialFolders("Desktop")
oneDrive = ""
On Error Resume Next
oneDrive = shell.ExpandEnvironmentStrings("%OneDrive%")
On Error GoTo 0

root = FindRepo(fso.GetParentFolderName(WScript.ScriptFullName))
If root = "" Then root = FindRepo(desktop)
If root = "" And oneDrive <> "" And fso.FolderExists(oneDrive & "\Desktop") Then
  root = FindRepo(oneDrive & "\Desktop")
End If
If root = "" Then root = FindRepoDeep(desktop, 3)
If root = "" And oneDrive <> "" Then root = FindRepoDeep(oneDrive, 3)

If root = "" Then
  MsgBox "Could not find your SwimIQ folder (needs a swimiq\pubspec.yaml inside)." & vbCrLf & vbCrLf & _
         "Look on Desktop for a folder named StrokeIQ, open the INNER StrokeIQ folder if there are two, then put this .vbs file in that folder and double-click again.", _
         vbCritical, "SwimIQ"
  WScript.Quit 1
End If

uploadDir = root & "\UPLOAD-TO-GODADDY"
If Not fso.FolderExists(uploadDir) Then fso.CreateFolder uploadDir

zipPath = uploadDir & "\swimiq-web-godaddy.zip"
howPath = uploadDir & "\READ-ME-UPLOAD-STEPS.txt"

' Prefer zip already in the repo (no network). Else copy. Else silent download.
found = False
If fso.FileExists(zipPath) Then
  If VerifyZipHasKeys(zipPath) Then found = True
End If

If Not found And fso.FileExists(root & "\UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip") Then
  ' already checked path
End If

If Not found Then
  ' Silent download via PowerShell (no browser window)
  Dim ps, rc
  ps = "powershell -NoProfile -ExecutionPolicy Bypass -Command " & _
       """$ErrorActionPreference='Stop'; " & _
       "$zip='" & zipPath & "'; " & _
       "$url='https://github.com/Briezy2014/StrokeIQ/releases/download/swimiq-web-LATEST/swimiq-web-godaddy.zip'; " & _
       "New-Item -ItemType Directory -Force -Path '" & uploadDir & "' | Out-Null; " & _
       "Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing; " & _
       "if ((Get-Item $zip).Length -lt 5000000) { throw 'too small' }; " & _
       "Add-Type -AssemblyName System.IO.Compression.FileSystem; " & _
       "$z=[IO.Compression.ZipFile]::OpenRead($zip); " & _
       "try { $e=$z.GetEntry('main.dart.js'); $r=New-Object IO.StreamReader($e.Open()); $t=$r.ReadToEnd(); $r.Close(); " & _
       "if ($t -notmatch 'bryurwyeosbffvfpdpbv\.supabase\.co') { throw 'not connected' } } finally { $z.Dispose() }"""
  rc = shell.Run(ps, 0, True)
  If rc = 0 And fso.FileExists(zipPath) Then found = True
End If

If Not found Then
  MsgBox "Could not prepare the website zip." & vbCrLf & vbCrLf & _
         "Connect to phone hotspot Wi-Fi, then double-click this file again." & vbCrLf & _
         "Folder used: " & root, vbCritical, "SwimIQ"
  WScript.Quit 1
End If

WriteHow howPath, zipPath

shell.Run "notepad.exe """ & howPath & """", 1, False
WScript.Sleep 800
shell.Run "explorer.exe /select,""" & zipPath & """", 1, False

MsgBox "READY." & vbCrLf & vbCrLf & _
       "1) Upload this file to GoDaddy public_html:" & vbCrLf & _
       "   swimiq-web-godaddy.zip" & vbCrLf & vbCrLf & _
       "2) Extract → Overwrite ALL" & vbCrLf & vbCrLf & _
       "3) Then open swimiqapp.com and press Ctrl+Shift+R" & vbCrLf & vbCrLf & _
       "Your SwimIQ folder:" & vbCrLf & root, _
       vbInformation, "SwimIQ"

WScript.Quit 0

Function FindRepo(startPath)
  Dim p, candidate
  FindRepo = ""
  If startPath = "" Then Exit Function
  If Not fso.FolderExists(startPath) Then Exit Function
  If fso.FileExists(startPath & "\swimiq\pubspec.yaml") Then
    FindRepo = startPath
    Exit Function
  End If
  ' If this is Desktop\StrokeIQ with nested StrokeIQ
  candidate = startPath & "\StrokeIQ"
  If fso.FileExists(candidate & "\swimiq\pubspec.yaml") Then
    FindRepo = candidate
    Exit Function
  End If
  ' Script dropped inside swimiq\
  p = fso.GetParentFolderName(startPath)
  If fso.FileExists(p & "\swimiq\pubspec.yaml") Then FindRepo = p
End Function

Function FindRepoDeep(startPath, depthLeft)
  Dim folder, subf, hit
  FindRepoDeep = ""
  If depthLeft < 0 Then Exit Function
  If Not fso.FolderExists(startPath) Then Exit Function
  hit = FindRepo(startPath)
  If hit <> "" Then FindRepoDeep = hit : Exit Function
  Set folder = fso.GetFolder(startPath)
  For Each subf In folder.SubFolders
    If Left(subf.Name, 1) <> "." Then
      hit = FindRepoDeep(subf.Path, depthLeft - 1)
      If hit <> "" Then FindRepoDeep = hit : Exit Function
    End If
  Next
End Function

Function VerifyZipHasKeys(path)
  Dim ps, rc
  VerifyZipHasKeys = False
  ps = "powershell -NoProfile -ExecutionPolicy Bypass -Command " & _
       """Add-Type -AssemblyName System.IO.Compression.FileSystem; " & _
       "$z=[IO.Compression.ZipFile]::OpenRead('" & path & "'); " & _
       "try { $e=$z.GetEntry('main.dart.js'); if ($null -eq $e) { exit 2 }; " & _
       "$r=New-Object IO.StreamReader($e.Open()); $t=$r.ReadToEnd(); $r.Close(); " & _
       "if ($t -match 'bryurwyeosbffvfpdpbv\.supabase\.co') { exit 0 } else { exit 3 } } finally { $z.Dispose() }"""
  rc = shell.Run(ps, 0, True)
  If rc = 0 Then VerifyZipHasKeys = True
End Function

Sub WriteHow(path, zipFile)
  Dim ts
  Set ts = fso.CreateTextFile(path, True)
  ts.WriteLine "UPLOAD THIS FILE TO GODADDY"
  ts.WriteLine "==========================="
  ts.WriteLine ""
  ts.WriteLine "File:"
  ts.WriteLine "  swimiq-web-godaddy.zip"
  ts.WriteLine ""
  ts.WriteLine "Steps:"
  ts.WriteLine "  1. GoDaddy File Manager already open? Use it."
  ts.WriteLine "  2. Open public_html"
  ts.WriteLine "  3. Upload swimiq-web-godaddy.zip"
  ts.WriteLine "  4. Extract → Overwrite ALL"
  ts.WriteLine "  5. Ctrl+Shift+R on swimiqapp.com"
  ts.WriteLine ""
  ts.WriteLine "You should see LOGIN, not 'not connected'."
  ts.WriteLine ""
  ts.WriteLine zipFile
  ts.Close
End Sub
