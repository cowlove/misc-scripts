#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#SingleInstance Force

Folder = E:\Downloads
CURL=C:\users\jim\Downloads\curl-7.75.0_5-win64-mingw\curl-7.75.0-win64-mingw\Bin\curl.exe 

Loop, %Folder%\*.stl {
     FileGetTime, Time, %A_LoopFileFullPath%, C
     If (Time > Time_Orig) {
          Time_Orig := Time
          File := A_LoopFileName
     }
}

ZcodeFile = % RegExReplace(File,"i).stl$",".zcode")
;MsgBox, Newest file in %Folder% is %File% %ZcodeFile%
;MsgBox Run %CURL% -v --form "file=@%Folder%\%ZcodeFile%"  http://192.168.4.3/upload.cgi
;Run %CURL% -v --form "file=@%Folder%\%ZcodeFile%"  http://192.168.4.3/upload.cgi
;Return


Runwait taskkill /F /IM Z-SUITE.exe
Runwait powershell del '%Folder%\%ZcodeFile%'
Sleep 2000
Run "C:\Program Files\Zortrax\Z-Suite\Z-SUITE.exe" "%Folder%\%File%"
WinWait Z-SUITE


if WinExist("Z-SUITE") {
	WinActivate

	SendMode, Input
	CoordMode, Pixel, Window
	CoordMode, Mouse, Window

	MouseGetPos, x, y
	PixelGetColor, c, %x%, %y%

	;MouseMove,        1130, 920, 100
	;MouseClick, left, 1270, 400
	;Sleep 1000

	;MouseClick, left, 1262, 855   ; shows as 1253, 846, add +9,+11			; 1260x850

	i = 0
	while( WinExist("Z-SUITE")) { 
		Sleep 5000
		WinMove,,,0,0, 1200,600
		WinActivate
		;dummy mouseclick to prompt button color changes, thanks zortrax 
		MouseClick, left, 500,500

		;;;; look for preview/print/export button 
		PixelGetColor, c, 1040, 597 
		;MsgBox %c% 
		if (c == 0xf78a2e) { 
			MouseClick, left, 1040, 597 
		}

		;;;; look for EXPORT button 
		PixelGetColor, c, 832,269
		;MsgBox %c% 
		if (c == 0xf48d35) { 
			MouseClick, left, 832,269
			Sleep 2000
			ControlClick, Button2, Save
			Sleep 2000
			if (WinExist("Save")) { 
				ControlClick, Button1, Save
			}
			Sleep 2000

			Runwait powershell (Get-Item '%Folder%\%ZcodeFile%').LastWriteTime=(Get-Date -Year 2000 -Day 1 -Month 1 -Hour 1 -Minute 1 -Second 0)
			Runwait %CURL% -v --form "file=@%Folder%\%ZcodeFile%"  http://192.168.4.3/upload.cgi

			WinExist("Z-SUITE")
			WinActivate	
			WinMinimize
			return
		}


 	}

}


