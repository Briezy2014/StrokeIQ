' SwimIQ — double-click this (OneDrive-safe).
' Opens the LOCAL upload folder and highlights swimiq-web-godaddy.zip.
' Does NOT open GitHub or any website.
Option Explicit

Dim shell, fso, desktop, oneDrive, root, uploadDir, zipPath, howPath
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
         "Open Desktop\StrokeIQ (the INNER StrokeIQ if there are two)," & vbCrLf & _
         "put this .vbs file in that folder, then double-click again.", _
         vbCritical, "SwimIQ"
  WScript.Quit 1
End If

uploadDir = root & "\UPLOAD-TO-GODADDY"
zipPath = uploadDir & "\swimiq-web-godaddy.zip"
howPath = uploadDir & "\READ-ME-UPLOAD-STEPS.txt"

If Not fso.FolderExists(uploadDir) Then
  MsgBox "Missing folder:" & vbCrLf & uploadDir & vbCrLf & vbCrLf & _
         "Your StrokeIQ folder may be incomplete. Ask for a fresh folder copy.", _
         vbCritical, "SwimIQ"
  WScript.Quit 1
End If

If Not fso.FileExists(zipPath) Then
  MsgBox "Missing the website zip:" & vbCrLf & vbCrLf & _
         "UPLOAD-TO-GODADDY\swimiq-web-godaddy.zip" & vbCrLf & vbCrLf & _
         "Look inside UPLOAD-TO-GODADDY. If the zip is not there," & vbCrLf & _
         "your folder copy is incomplete.", _
         vbCritical, "SwimIQ"
  shell.Run "explorer.exe """ & uploadDir & """", 1, False
  WScript.Quit 1
End If

WriteHow howPath, zipPath

' Copy to Desktop so it is easy to grab for GoDaddy Upload
Dim deskZip
deskZip = desktop & "\swimiq-web-godaddy.zip"
On Error Resume Next
fso.CopyFile zipPath, deskZip, True
On Error GoTo 0

shell.Run "notepad.exe """ & howPath & """", 1, False
WScript.Sleep 600
shell.Run "explorer.exe /select,""" & zipPath & """", 1, False

MsgBox "READY — no website needed." & vbCrLf & vbCrLf & _
       "File Explorer highlighted:" & vbCrLf & _
       "  swimiq-web-godaddy.zip" & vbCrLf & vbCrLf & _
       "Also copied to your Desktop (same name)." & vbCrLf & vbCrLf & _
       "GoDaddy → public_html → Upload that zip →" & vbCrLf & _
       "Extract → Overwrite → then Ctrl+Shift+R on the app." & vbCrLf & vbCrLf & _
       "Folder:" & vbCrLf & root, _
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
  candidate = startPath & "\StrokeIQ"
  If fso.FileExists(candidate & "\swimiq\pubspec.yaml") Then
    FindRepo = candidate
    Exit Function
  End If
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

Sub WriteHow(path, zipFile)
  Dim ts
  Set ts = fso.CreateTextFile(path, True)
  ts.WriteLine "UPLOAD THIS FILE TO GODADDY"
  ts.WriteLine "==========================="
  ts.WriteLine ""
  ts.WriteLine "ONLY this file:"
  ts.WriteLine "  swimiq-web-godaddy.zip"
  ts.WriteLine ""
  ts.WriteLine "Do NOT use GitHub."
  ts.WriteLine "Do NOT use Kara-DOUBLE-CLICK-STARTER."
  ts.WriteLine "Do NOT use anything from build\web."
  ts.WriteLine ""
  ts.WriteLine "Steps:"
  ts.WriteLine "  1. GoDaddy File Manager → public_html"
  ts.WriteLine "  2. Upload swimiq-web-godaddy.zip"
  ts.WriteLine "     (from Desktop OR from UPLOAD-TO-GODADDY)"
  ts.WriteLine "  3. Extract → Overwrite ALL"
  ts.WriteLine "  4. Open the app → Ctrl+Shift+R"
  ts.WriteLine "  5. Denison 50 Fly → Run AI Swim Analysis"
  ts.WriteLine "     Keep tab open up to 2 minutes"
  ts.WriteLine ""
  ts.WriteLine zipFile
  ts.Close
End Sub
