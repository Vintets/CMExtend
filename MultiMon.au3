#Region Header
;===================================================================================================
;
; Title:            MultiMon
; Filename:         MultiMon.au3
; Description:      Get parameter all Monitors
; Version:          4.2.1
; Requirement(s):   Autoit 3.3.14.5
; Author(s):        xrxca (autoit@forums.xrx.ca)
; Modified          mLipok, Decibel, Vint
; Link              https://www.autoitscript.com/forum/topic/82353-dual-monitor-resolution-detection/?do=findComment&comment=1405494
; Date:             14.10.2021
;
;===================================================================================================
#EndRegion Header

#include-Once
#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7

#include <Array.au3>

Global $__MonitorList[1][7]
$__MonitorList[0][0] = 0

; For testing - uncomment following line 'CTRL+Q in SciTE4AutoIt'
; If Not @Compiled Then
    ; _Example_ShowMonitorInfo()
    ; _ArrayDisplay($__MonitorList, 'Monitors', Default, Default, '|', 'hMonitor|left|top|right|bottom|width|height')
; EndIf


; #FUNCTION# =======================================================================================
; Name ..........: _Example_ShowMonitorInfo
; Description ...: Show the info in $__MonitorList in a msgbox (line 0 is entire screen)
; Syntax ........: _Example_ShowMonitorInfo()
; Parameters ....: None
; Return values .: None
; Author ........: xrxca (autoit@forums.xrx.ca)
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ==================================================================================================
Func _Example_ShowMonitorInfo()
    If $__MonitorList[0][0] == 0 Then _GetMonitors()

    Local $sMessage = ""
    For $i = 0 To $__MonitorList[0][0]
        If $i = 0 Then
            $sMessage &= $i & StringFormat(" - mon:%-18s", $__MonitorList[$i][0])
        Else
            $sMessage &= $i & StringFormat(" - hnd:%-10s", $__MonitorList[$i][0])
        EndIf
        $sMessage &= StringFormat(", L:%-4s, T:%-4s, R:%-4s, B:%-4s, W:%-4s, H:%-4s", $__MonitorList[$i][1], $__MonitorList[$i][2], $__MonitorList[$i][3], $__MonitorList[$i][4], $__MonitorList[$i][5], $__MonitorList[$i][6])
        If $i < $__MonitorList[0][0] Then $sMessage &= @CRLF
    Next
    MsgBox(0, $__MonitorList[0][0] & " Monitors: ", $sMessage)
EndFunc   ;==>_Example_ShowMonitorInfo

; #FUNCTION# =======================================================================================
; Name ..........: _MaxOnMonitor
; Description ...: Maximize a window on a specific monitor (or the monitor the mouse is on)
; Syntax ........: _MaxOnMonitor($sTitle[, $sText = ''[, $iMonitor = -1]])
; Parameters ....: $sTitle              - a string value. The title/hWnd/class of the window to Move/Maximize
;                  $sText               - [optional] a string value. Default is ''. The text of the window to Move/Maximize
;                  $iMonitor            - [optional] an integer value. Default is -1. The monitor, to which window should be moved (1..NumMonitors). Use default -1 to select monitor on which mouse is on
; Return values .: None, or sets the @error flag to non-zero if the window is not found.
; Author ........: xrxca (autoit@forums.xrx.ca)
; Modified ......: mLipok
; Remarks .......:
; Related .......: WinGetHandle
; Link ..........:
; Example .......: No
; ==================================================================================================
Func _MaxOnMonitor($sTitle, $sText = '', $iMonitor = -1)
    _CenterOnMonitor($sTitle, $sText, $iMonitor)
    If @error Then Return SetError(@error, @extended)
    WinSetState($sTitle, $sText, @SW_MAXIMIZE)
EndFunc   ;==>_MaxOnMonitor

; #FUNCTION# =======================================================================================
; Name ..........: _CenterOnMonitor
; Description ...: Center a window on a specific monitor (or the monitor the mouse is on)
; Syntax ........: _CenterOnMonitor($Title[, $sText = ''[, $iMonitor = -1]])
; Parameters ....: $Title               - an unknown value. The title/hWnd/class of the window to center on monitor
;                  $sText               - [optional] a string value. Default is ''. The text of the window to center on monitor
;                  $iMonitor            - [optional] an integer value. Default is -1. The monitor, to which window should be moved (1..NumMonitors). Use default -1 to select monitor on which mouse is on
; Return values .: None, or sets the @error flag to non-zero if the window is not found.
; Author ........: xrxca (autoit@forums.xrx.ca)
; Modified ......: mLipok
; Remarks .......: Should probably have specified return/error codes but haven't put them in yet
; Remarks .......:
; Related .......: WinGetHandle
; Link ..........:
; Example .......: No
; ==================================================================================================
Func _CenterOnMonitor($Title, $sText = '', $iMonitor = -1)
    Local $hWindow = WinGetHandle($Title, $sText)
    If @error Then Return SetError(1)

    If $iMonitor == -1 Then $iMonitor = _GetMonitorFromPoint()
    If $__MonitorList[0][0] == 0 Then _GetMonitors()

    If ($iMonitor > 0) And ($iMonitor <= $__MonitorList[0][0]) Then
        ; Restore the window if necessary
        Local $WinState = WinGetState($hWindow)
        If BitAND($WinState, 16) Or BitAND($WinState, 32) Then
            WinSetState($hWindow, '', @SW_RESTORE)
        EndIf
        Local $WinSize = WinGetPos($hWindow)
        Local $x = Int(($__MonitorList[$iMonitor][3] - $__MonitorList[$iMonitor][1] - $WinSize[2]) / 2) + $__MonitorList[$iMonitor][1]
        Local $y = Int(($__MonitorList[$iMonitor][4] - $__MonitorList[$iMonitor][2] - $WinSize[3]) / 2) + $__MonitorList[$iMonitor][2]
        WinMove($hWindow, '', $x, $y)
    EndIf
EndFunc   ;==>_CenterOnMonitor

; #FUNCTION# =======================================================================================
; Name ..........: _GetMonitorFromPoint
; Description ...: Get a monitor number from an x/y pos or the current mouse position
; Syntax ........: _GetMonitorFromPoint([$XorPoint = 0[, $y = 0]])
; Parameters ....: $XorPoint            - [optional] an unknown value. Default is 0. X Position or Array with X/Y as items 0,1 (ie from MouseGetPos())
;                  $y                   - [optional] an unknown value. Default is 0. Y Position
; Return values .: $iMonitor, or set @error to 1
; Author ........: xrxca (autoit@forums.xrx.ca)
; Modified ......: mLipok
; Remarks .......: Used to use MonitorFromPoint DLL call, but it didn't seem to always work.
; Related .......: MouseGetPos
; Link ..........:
; Example .......: No
; ==================================================================================================
Func _GetMonitorFromPoint($XorPoint = 0, $y = 0)
    Local $i_MouseX, $i_MouseY
    If @NumParams = 0 Then
        Local $aMousePos = MouseGetPos()
        $i_MouseX = $aMousePos[0]
        $i_MouseY = $aMousePos[1]
    ElseIf (@NumParams = 1) And IsArray($XorPoint) Then
        If UBound($XorPoint) <> 2 Then Return SetError(1, 1)
        $i_MouseX = $XorPoint[0]
        If Not IsInt($i_MouseX) Then Return SetError(2, 2)
        $i_MouseY = $XorPoint[1]
        If Not IsInt($i_MouseY) Then Return SetError(2, 3)
    Else
        If Not IsInt($XorPoint) Then Return SetError(2, 1)
        If Not IsInt($y) Then Return SetError(2, 2)
        $i_MouseX = $XorPoint
        $i_MouseY = $y
    EndIf
    If $__MonitorList[0][0] == 0 Then _GetMonitors()

    Local $iMonitor = 0
    For $i = 1 To $__MonitorList[0][0]
        If ($i_MouseX >= $__MonitorList[$i][1]) _
                And ($i_MouseX < $__MonitorList[$i][3]) _
                And ($i_MouseY >= $__MonitorList[$i][2]) _
                And ($i_MouseY < $__MonitorList[$i][4]) Then $iMonitor = $i
    Next
    Return $iMonitor
EndFunc   ;==>_GetMonitorFromPoint

; #FUNCTION# =======================================================================================
; Name ..........: _GetMonitors
; Description ...: Load monitor positions
; Syntax ........: _GetMonitors()
; Parameters ....: None
; Return values .: $__MonitorList and 2D Array of Monitors
;                       [0][0] = Number of Monitors
;                       [i][0] = HMONITOR handle of this monitor.
;                       [i][1] = Left Position of Monitor
;                       [i][2] = Top Position of Monitor
;                       [i][3] = Right Position of Monitor
;                       [i][4] = Bottom Position of Monitor
;                       [i][5] = Width of Monitor
;                       [i][6] = Height  Position of Monitor
; Author ........: xrxca (autoit@forums.xrx.ca)
; Modified ......: mLipok
; Remarks .......: [0][1..4] are set to Left,Top,Right,Bottom of entire screen.
;                  [0][5..6] Width and Height of entire screen.
;                  hMonitor is returned in [i][0], but no longer used by these routines.
;                  Also sets $__MonitorList Global variable (for other subs to use)
; Related .......:
; Link ..........:
; Example .......: _Example_ShowMonitorInfo()
; ==================================================================================================
Func _GetMonitors()
    $__MonitorList[0][0] = 0 ;  Added so that the global array is reset if this is called multiple times
    Local $handle = DllCallbackRegister(__MonitorEnumProc, "int", "hwnd;hwnd;ptr;lparam")
    DllCall("user32.dll", "int", "EnumDisplayMonitors", "hwnd", 0, "ptr", 0, "ptr", DllCallbackGetPtr($handle), "lparam", 0)
    DllCallbackFree($handle)
    $__MonitorList[0][1] = 0
    $__MonitorList[0][2] = 0
    For $i = 1 To $__MonitorList[0][0]
        If $__MonitorList[$i][1] < $__MonitorList[0][1] Then $__MonitorList[0][1] = $__MonitorList[$i][1]
        If $__MonitorList[$i][2] < $__MonitorList[0][2] Then $__MonitorList[0][2] = $__MonitorList[$i][2]
        If $__MonitorList[$i][3] > $__MonitorList[0][3] Then $__MonitorList[0][3] = $__MonitorList[$i][3]
        If $__MonitorList[$i][4] > $__MonitorList[0][4] Then $__MonitorList[0][4] = $__MonitorList[$i][4]
    Next

    For $i = 0 To UBound($__MonitorList, 1) - 1
        $__MonitorList[$i][5] = $__MonitorList[$i][3] - $__MonitorList[$i][1]
        $__MonitorList[$i][6] = $__MonitorList[$i][4] - $__MonitorList[$i][2]
    Next

    ; _ArraySort($__MonitorList, 0, 1, 0, 0, 0) ;added to sort it by the first column (hMonitor) so that they line up in physical order like Display Settings-->Rearrange Displays
    Return $__MonitorList
EndFunc   ;==>_GetMonitors

; #INTERNAL_USE_ONLY# ==============================================================================
; Name ..........: __MonitorEnumProc
; Description ...: Enum Callback Function for EnumDisplayMonitors in _GetMonitors
; Syntax ........: __MonitorEnumProc($hMonitor, $hDC, $lRect, $lParam)
; Parameters ....: $hMonitor            - a handle value.
;                  $hDC                 - a handle value.
;                  $lRect               - an unknown value.
;                  $lParam              - an unknown value.
; Return values .: 1 and set $__MonitorList
; Author ........: xrxca (autoit@forums.xrx.ca)
; Modified ......: mLipok
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ==================================================================================================
Func __MonitorEnumProc($hMonitor, $hDC, $lRect, $lParam)
    #forceref $hDC, $lParam
    Local $tRect = DllStructCreate("int left;int top;int right;int bottom", $lRect)
    $__MonitorList[0][0] += 1
    ReDim $__MonitorList[$__MonitorList[0][0] + 1][7]
    $__MonitorList[$__MonitorList[0][0]][0] = $hMonitor
    $__MonitorList[$__MonitorList[0][0]][1] = DllStructGetData($tRect, "left")
    $__MonitorList[$__MonitorList[0][0]][2] = DllStructGetData($tRect, "top")
    $__MonitorList[$__MonitorList[0][0]][3] = DllStructGetData($tRect, "right")
    $__MonitorList[$__MonitorList[0][0]][4] = DllStructGetData($tRect, "bottom")
    Return 1 ; Return 1 to continue enumeration
EndFunc   ;==>__MonitorEnumProc
