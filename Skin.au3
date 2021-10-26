#Region Header

#cs

    Title:          Skinable GUI Controls UDF Library for AutoIt3
    Filename:       Skin.au3
    Description:    Creates and manages a skinnable GUI controls
    Author:         Yashied
    Version:        0.3
    Requirements:   AutoIt v3.3.x.x, Developed/Tested on Windows XP Pro Service Pack 2 and Windows 7 +Windows 10
    Uses:           GDIPlus.au3, WinAPI.au3
    Notes:          The library registers (permanently) the following window message:

                    WM_COMMAND
                    WM_DRAWITEM

    Available functions:

    _Skin_AddButton
    _Skin_AddButtonEx
    _Skin_DeleteButton
    _Skin_Destroy
    _Skin_DisableButton
    _Skin_EnableFocus
    _Skin_EnableKBInput
    _Skin_Helper
    _Skin_SetButton
    _Skin_SetButtonEx
    _Skin_SetFocusRect

    Example:

    #Include <GUIConstantsEx.au3>
    #Include <Skin.au3>

    Global $Button[3]

    $hForm = GUICreate('MyGUI', 278, 106)

    GUICtrlCreatePic('background.bmp', 0, 0, 278, 106)
    GUICtrlSetState(-1, $GUI_DISABLE)

    ; Create buttons from PNG images (images should be located in the same folder as the script)
    $Button[0] = _Skin_AddButton(20 , 20, 66, 66, 'red_normal.png', 'red_hover.png', 'red_click.png', 'disable.png', 'alpha.png', 1)
    $Button[1] = _Skin_AddButton(106, 20, 66, 66, 'yellow_normal.png', 'yellow_hover.png', 'yellow_click.png', 'disable.png', 'alpha.png', 1)
    $Button[2] = _Skin_AddButton(192, 20, 66, 66, 'green_normal.png', 'green_hover.png', 'green_click.png', 'disable.png', 'alpha.png', 1)

    ; #cs

    ; Create buttons from GDI+ HBITMAP handles
    $Button[0] = _Skin_AddButtonEx(20 , 20, 64, 64, _GDIPlus_BitmapCreateFromFile('red_normal.png'), ..., 1, 1)
    $Button[1] = _Skin_AddButtonEx(104, 20, 64, 64, _GDIPlus_BitmapCreateFromFile('yellow_normal.png'), ..., 1, 1)
    $Button[2] = _Skin_AddButtonEx(188, 20, 64, 64, _GDIPlus_BitmapCreateFromFile('green_normal.png'), ..., 1, 1)

    ; #ce

    ; Disable "Yellow" button (Optional)
    _Skin_DisableButton($Button[1], 1)

    ; Enable keyboard input (Optional)
    _Skin_EnableKBInput(1)

    ; Set margins for dotted focus rectangle (Optional)
    For $i = 0 To 2
        _Skin_SetFocusRect($Button[$i], 5, 5, 56, 56)
    Next

    ; Enable dotted focus rectangle (Optional)
    _Skin_EnableFocus(1)

    GUISetState()

    ; _Skin_Helper() must be called continuously in the main loop
    While 1
        _Skin_Helper($hForm)
        $ID = GUIGetMsg()
        Switch $ID
            Case 0
                ContinueLoop
            Case $GUI_EVENT_CLOSE
                ExitLoop
            Case $Button[0]
                ConsoleWrite('Red' & @CR)
            Case $Button[1]
                ConsoleWrite('Yellow' & @CR)
            Case $Button[2]
                ConsoleWrite('Green' & @CR)
            Case Else

        EndSwitch
    WEnd

    ; You must delete all created buttons before destroying the appropriate window
    ;~For $i = 0 To 2
    ;~  _Skin_DeleteButton($Button[$i])
    ;~Next

#ce

#Include-once

#Include <GDIPlus.au3>
#Include <WinAPI.au3>

#EndRegion Header

#Region Local Variables and Constants

Global $skData[1][20] = [[0, 0, 0, 0, 0, 0, DllCallbackRegister('_sk_IconProc', 'ptr', 'hwnd;uint;wparam;lparam'), 0, 0, DllCallbackRegister('_sk_EnumProc', 'int', 'hwnd;lparam'), 0, 0, 0, 0, 0, 0, 0, 0, 0, '']]

#cs

WARNING: DO NOT CHANGE THIS ARRAY, FOR INTERNAL USE ONLY!

$skData[0][0 ]    - Number of items in array
       [0][1 ]    - Current item (0 - No item)
       [0][2 ]    - State (0 - Normal, 1 - Hover, 2 - Click)
       [0][3 ]    - Hold down item (0 - None, (-1) - Hold down outside)
       [0][4 ]    - Hold down jumping update control flag
       [0][5 ]    - Handle to the GDI+ DLL
       [0][6 ]    - Handle to the _sk_IconProc()
       [0][7 ]    - Pointer to the original window procedure
       [0][8 ]    - Focus mode control flag
       [0][9 ]    - Handle to the _sk_EnumProc()
       [0][10]    - Keyboard mode control flag
       [0][11-18] - Don't used

$skData[i][0 ]    - Handle to the icon for "Normal" state
       [i][1 ]    - Handle to the icon for "Hover" state
       [i][2 ]    - Handle to the icon for "Click" state
       [i][3 ]    - Handle to the icon for "Disable" state (Optional)
       [i][4 ]    - Handle to the parent window
       [i][5 ]    - Handle to the Icon control
       [i][6 ]    - ID of the Icon control
       [i][7 ]    - ID of the Button control
       [i][8 ]    - Handle to the GDI+ alpha bitmap
       [i][9 ]    - Disable control flag
       [i][10]    - Hold down control flag
       [i][11]    - Focus control flag
       [i][12]    - Focus rectange (RECT structure)
       [i][13]    - Focus drawing control flag
       [i][14]    - The x-coordinate of the Icon control
       [i][15]    - The y-coordinate of the Icon control
       [i][16]    - The width of the Icon control
       [i][17]    - The height of the Icon control
       [i][18]    - Reserved

#ce

Global $skEnum[51] = [0]

#EndRegion Local Variables and Constants

#Region Initialization

; IMPORTANT: If you register the following window messages in your code, you should call handlers from this library until
; you return from your handlers, otherwise, the library will not work properly! For example:
;
; Func MY_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
;     Local $Result = SK_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
;     If $Result <> $GUI_RUNDEFMSG Then
;         Return $Result
;     EndIf
;     ...
; EndFunc

GUIRegisterMsg(0x0111, 'SK_WM_COMMAND')
GUIRegisterMsg(0x002B, 'SK_WM_DRAWITEM')

OnAutoItExitRegister('_sk_Exit')

;~If True Then
	_sk_GdipStartup()
;~EndIf

#EndRegion Initialization

#Region Public Functions

Func _Skin_AddButton($iX, $iY, $iWidth, $iHeight, $sNormal, $sHover, $sClick, $sDisable = '', $sAlpha = '', $fOverlap = 0, $sToolTip = '')

	Local $hBitmap[5] = [$sNormal, $sHover, $sClick, $sDisable, $sAlpha]

	For $i = 0 To 4
		$hBitmap[$i] = _GDIPlus_BitmapCreateFromFile($hBitmap[$i])
		If Not $hBitmap[$i] Then
			Switch $i
				Case 0 To 2
					For $j = 0 To $i - 1
						_GDIPlus_BitmapDispose($hBitmap[$j])
					Next
					Return 0
				Case Else

			EndSwitch
		EndIf
	Next
	Return _Skin_AddButtonEx($iX, $iY, $iWidth, $iHeight, $hBitmap[0], $hBitmap[1], $hBitmap[2], $hBitmap[3], $hBitmap[4], $fOverlap, 1, $sToolTip)
EndFunc   ;==>_Skin_AddButton

Func _Skin_AddButtonEx($iX, $iY, $iWidth, $iHeight, $hNormal, $hHover, $hClick, $hDisable = 0, $hAlpha = 0, $fOverlap = 0, $fDelete = 0, $sToolTip = '')

	Local $hBitmap[7] = [$hNormal, $hHover, $hClick, $hDisable, $hAlpha, 0, 0]
	Local $ID[2] = [0, 0]
	Local $hIcon

	Do
		$ID[1] = GUICtrlCreateButton('', -10, -10, 1, 1)
;~		If Not $ID[1] Then
;~			GUICtrlDelete($ID[1])
;~			ExitLoop
;~		EndIf
;~		GUICtrlSetStyle($ID[1], BitOR($BS_NOTIFY, $BS_OWNERDRAW, $WS_TABSTOP))
		GUICtrlSetStyle($ID[1], 0x0001400B)
;~		GUICtrlSetResizing($ID[1], BitOR($GUI_DOCKLEFT, $GUI_DOCKTOP, $GUI_DOCKWIDTH, $GUI_DOCKHEIGHT))
		GUICtrlSetResizing($ID[1], 0x0322)
;~		$ID[0] = GUICtrlCreateIcon('', 0, $iX, $iY, $iWidth, $iHeight, $SS_ICON)
		$ID[0] = GUICtrlCreateIcon('', 0, $iX, $iY, $iWidth, $iHeight, 0x0000)
		If Not $ID[0] Then
			GUICtrlDelete($ID[1])
			ExitLoop
		EndIf
		$hIcon = GUICtrlGetHandle($ID[0])
;~		If True Then
;~			_sk_SetStyle($hIcon, $WS_TABSTOP, 0)
			_sk_SetStyle($hIcon, 0x00010000, 0)
;~		EndIf
		If $fOverlap Then
			$hBitmap[5] = _sk_Overlap($hIcon, $iX, $iY, $iWidth, $iHeight)
		EndIf
		$skData[0][0] += 1
		ReDim $skData[$skData[0][0] + 1][UBound($skData, 2)]
		For $i = 0 To 3
			If $hBitmap[5] Then
				$hBitmap[6] = _sk_GetBitmap($hBitmap[$i], $hBitmap[5])
			Else
				$hBitmap[6] = 0
			EndIf
			If Not $hBitmap[6] Then
				$skData[$skData[0][0]][$i] = _sk_GetIcon($hBitmap[$i])
			Else
				$skData[$skData[0][0]][$i] = _sk_GetIcon($hBitmap[6 ])
;~				If True Then
					_GDIPlus_BitmapDispose($hBitmap[6])
;~				EndIf
			EndIf
		Next
		$skData[$skData[0][0]][4 ] = _WinAPI_GetParent($hIcon)
		$skData[$skData[0][0]][5 ] = $hIcon
		For $i = 6 To 7
			$skData[$skData[0][0]][$i] = $ID[$i - 6]
		Next
		If $hBitmap[4] Then
			$skData[$skData[0][0]][8 ] = _sk_GdipCloneImage($hBitmap[4])
		Else
			$skData[$skData[0][0]][8 ] = 0
		EndIf
		For $i = 9 To 13
			$skData[$skData[0][0]][$i] = 0
		Next
		$skData[$skData[0][0]][14] = $iX
		$skData[$skData[0][0]][15] = $iY
		$skData[$skData[0][0]][16] = $iWidth
		$skData[$skData[0][0]][17] = $iHeight
		$skData[$skData[0][0]][18] = 0
        $skData[$skData[0][0]][19] = $sToolTip
;~		GUICtrlSetState($ID[0], $GUI_DISABLE)
;~		GUICtrlSetState($ID[0], 0x0080)
		If $skData[0][8] Then
			$skData[0][7] = _sk_SetProc($hIcon, DllCallbackGetPtr($skData[0][6]))
		Else
;~			$skData[0][7] = 0
		EndIf
;~		If True Then
			_sk_SetIcon($hIcon, $skData[$skData[0][0]][0])
;~		EndIf
	Until 1
	If $hBitmap[5] Then
		_GDIPlus_BitmapDispose($hBitmap[5])
	EndIf
	If $fDelete Then
		For $i = 0 To 4
			If $hBitmap[$i] Then
				_GDIPlus_BitmapDispose($hBitmap[$i])
			EndIf
		Next
	EndIf
	Return $ID[0]
EndFunc   ;==>_Skin_AddButtonEx

Func _Skin_DeleteButton($CtrlID)

	Local $ID = _sk_GetID($CtrlID)

	If Not $ID Then
		Return 0
	EndIf
	If $skData[0  ][7] Then
		_sk_SetProc($skData[$ID][5], $skData[0][7])
	EndIf
	For $i = 6 To 7
		GUICtrlDelete($skData[$ID][$i])
	Next
	For $i = 0 To 3
		If $skData[$ID][$i] Then
			_WinAPI_DestroyIcon($skData[$ID][$i])
		EndIf
	Next
	If $skData[$ID][8] Then
		_GDIPlus_BitmapDispose($skData[$ID][8])
	EndIf
	For $i = $ID To $skData[0][0] - 1
		For $j = 0 To UBound($skData, 2) - 1
			$skData[$i][$j] = $skData[$i + 1][$j]
		Next
	Next
	$skData[0][0] -= 1
	ReDim $skData[$skData[0][0] + 1][UBound($skData, 2)]
	If Not $skData[0][0] Then
		$skData[0][7 ] = 0
	EndIf
	For $i = 1 To 4
		$skData[0][$i] = 0
	Next
	Return 1
EndFunc   ;==>_Skin_DeleteButton

Func _Skin_Destroy()
	For $i = 1 To $skData[0][0]
		If $skData[0 ][7] Then
			_sk_SetProc($skData[$i][5], $skData[0][7])
		EndIf
		For $j = 6 To 7
			GUICtrlDelete($skData[$i][$j])
		Next
		For $j = 0 To 3
			If $skData[$i][$j] Then
				_WinAPI_DestroyIcon($skData[$i][$j])
			EndIf
		Next
		If $skData[$i][8] Then
			_GDIPlus_BitmapDispose($skData[$i][8])
		EndIf
	Next
	ReDim $skData[1][UBound($skData, 2)]
	$skData[0][7] = 0
	For $i = 0 To 4
		$skData[0][$i] = 0
	Next
EndFunc   ;==>_Skin_Destroy

Func _Skin_DisableButton($CtrlID, $fDisable)

	Local $ID = _sk_GetID($CtrlID)

	If Not $ID Then
		Return 0
	EndIf
	If $fDisable Then
		$skData[$ID][9] = 1
;~		GUICtrlSetState($skData[$ID][7], $GUI_DISABLE)
		GUICtrlSetState($skData[$ID][7], 0x0080)
		If $skData[$ID][3] Then
			_sk_SetIcon($skData[$ID][5], $skData[$ID][3])
		Else
			_sk_SetIcon($skData[$ID][5], $skData[$ID][0])
		EndIf
	Else
		$skData[$ID][9] = 0
;~		GUICtrlSetState($skData[$ID][7], $GUI_ENABLE)
		GUICtrlSetState($skData[$ID][7], 0x0040)
;~		If True Then
			_sk_SetIcon($skData[$ID][5], $skData[$ID][0])
;~		EndIf
	EndIf
	If $skData[0][1] = $ID Then
		For $i = 1 To 4
			$skData[0][$i] = 0
		Next
	EndIf
	Return 1
EndFunc   ;==>_Skin_DisableButton

Func _Skin_EnableFocus($fEnable)
	If $fEnable Then
		If $skData[0][8] Then

		Else
			$skData[0][8] = 1
			For $i = 1 To $skData[0][0]
				$skData[0][7] = _sk_SetProc($skData[$i][5], DllCallbackGetPtr($skData[0][6]))
				If $skData[$i][11] Then
					_WinAPI_InvalidateRect($skData[$i][5], 0, 0)
				EndIf
			Next
		EndIf
	Else
		If $skData[0][8] Then
			$skData[0][8] = 0
			For $i = 1 To $skData[0][0]
				_sk_SetProc($skData[$i][5], $skData[0][7])
				If $skData[$i][11] Then
					_WinAPI_InvalidateRect($skData[$i][5], 0, 0)
				EndIf
			Next
;~			If True Then
				$skData[0][7] = 0
;~			EndIf
		Else

		EndIf
	EndIf
EndFunc   ;==>_Skin_EnableFocus

Func _Skin_EnableKBInput($fEnable)
	If $fEnable Then
		$skData[0][10] = 1
	Else
		$skData[0][10] = 0
	EndIf
EndFunc   ;==>_Skin_EnableKBInput

Func _Skin_Helper($hWnd = 0)

	Local $Index, $Info

	If $skData[0][10] Then
		If _sk_HelperEx() Then
			Return
		EndIf
	EndIf
	$Info = GUIGetCursorInfo($hWnd)
	If $hWnd Then
		If (Not _sk_IsEnable($hWnd)) Or ((Not _sk_IsActive($hWnd)) And (($Info[2]) Or ($Info[3]) Or (Not _sk_IsOver($hWnd)))) Then
			$Info = 0
		EndIf
	EndIf
	If Not Isarray($Info) Then
		_sk_Update(0, 0)
	Else
		$Index = _sk_Index($Info)
		If $Info[2] Then
			If $Index <> $skData[0][1] Then
				If $Index Then
					If (Not $skData[0][3]) Or ($skData[0][3] = $Index) Then
						_sk_Update($Index, 2)
						$skData[0][3] = $Index
						$skData[0][4] = 1
					Else
						If $skData[0][3] =-1 Then
;~							If True Then
								_sk_Update($Index, 1)
;~							EndIf
						Else
							If $skData[0][4] Then
								_sk_Update(0, 0)
							EndIf
						EndIf
					EndIf
				Else
					_sk_Update(0, 0)
				EndIf
			Else
				If $Index Then
					If ($skData[0][3] <> -1) And ($skData[0][2] <> 2)  Then
						_sk_Update($Index, 2)
;~						GUICtrlSetState($skData[$Index][7], $GUI_FOCUS)
						GUICtrlSetState($skData[$Index][7], 0x0100)
						$skData[0][3] = $Index
						$skData[0][4] = 1
					EndIf
				Else
					If Not $skData[0][3]  Then
						$skData[0][3] =-1
					EndIf
				EndIf
			EndIf
		Else
			If $Index <> $skData[0][1] Then
				If $Index Then
					_sk_Update($Index, 1)
                    ToolTip($skData[$Index][19])
				Else
					_sk_Update(0, 0)
                    ToolTip('')
				EndIf
			Else
				If $Index Then
					If $skData[0][2] <> 1 Then
						_sk_Update($Index, 1)
						If $skData[0][3] = $Index Then
;~							_SendMessage($skData[$Index][4], $WM_COMMAND, $skData[$Index][6], $skData[$Index][5])
							_SendMessage($skData[$Index][4], 0x0111, $skData[$Index][6], $skData[$Index][5])
						EndIf
					EndIf
				EndIf
			EndIf
			$skData[0][3] = 0
		EndIf
	EndIf
EndFunc   ;==>_Skin_Helper

Func _Skin_SetButton($CtrlID, $sNormal, $sHover, $sClick, $sDisable = '', $sAlpha = '', $fOverlap = 0)

	Local $hBitmap[5] = [$sNormal, $sHover, $sClick, $sDisable, $sAlpha]

	If Not _sk_GetID($CtrlID) Then
		Return 0
	EndIf
	For $i = 0 To 4
		$hBitmap[$i] = _GDIPlus_BitmapCreateFromFile($hBitmap[$i])
		If Not $hBitmap[$i] Then
			Switch $i
				Case 0 To 2
					For $j = 0 To $i - 1
						_GDIPlus_BitmapDispose($hBitmap[$j])
					Next
					Return 0
				Case Else

			EndSwitch
		EndIf
	Next
	Return _Skin_SetButtonEx($CtrlID, $hBitmap[0], $hBitmap[1], $hBitmap[2], $hBitmap[3], $hBitmap[4], $fOverlap, 1)
EndFunc   ;==>_Skin_SetButton

Func _Skin_SetButtonEx($CtrlID, $hNormal, $hHover, $hClick, $hDisable = 0, $hAlpha = 0, $fOverlap = 0, $fDelete = 0)

	Local $hBitmap[7] = [$hNormal, $hHover, $hClick, $hDisable, $hAlpha, 0, 0]
	Local $ID = _sk_GetID($CtrlID)
	Local $hIcon[4]

	Do
		If Not $ID Then
			ExitLoop
		EndIf
		For $i = 0 To 3
			$hIcon[$i] = $skData[$ID][$i]
		Next
		If $fOverlap Then
			$hBitmap[5] = _sk_Overlap($skData[$ID][5], $skData[$ID][14], $skData[$ID][15], $skData[$ID][16], $skData[$ID][17])
		EndIf
		For $i = 0 To 3
			If $hBitmap[5] Then
				$hBitmap[6] = _sk_GetBitmap($hBitmap[$i], $hBitmap[5])
			Else
				$hBitmap[6] = 0
			EndIf
			If Not $hBitmap[6] Then
				$skData[$ID][$i] = _sk_GetIcon($hBitmap[$i])
			Else
				$skData[$ID][$i] = _sk_GetIcon($hBitmap[6 ])
;~				If True Then
					_GDIPlus_BitmapDispose($hBitmap[6])
;~				EndIf
			EndIf
		Next
		If $hBitmap[4] Then
			$skData[$ID][8] = _sk_GdipCloneImage($hBitmap[4])
		Else
			$skData[$ID][8] = 0
		EndIf
		If $skData[$ID][9] Then
			If $skData[$ID][3] Then
				_sk_SetIcon($skData[$ID][5], $skData[$ID][3])
			Else
				_sk_SetIcon($skData[$ID][5], $skData[$ID][0])
			EndIf
		Else
			If $skData[0][1] = $ID Then
				_sk_SetIcon($skData[$ID][5], $skData[$ID][$skData[0][2]])
			Else
				_sk_SetIcon($skData[$ID][5], $skData[$ID][0])
			EndIf
		EndIf
		For $i = 0 To 3
			If $hIcon[$i] Then
				_WinAPI_DestroyIcon($hIcon[$i])
			EndIf
		Next
		$ID = 1
	Until 1
	If $hBitmap[5] Then
		_GDIPlus_BitmapDispose($hBitmap[5])
	EndIf
	If $fDelete Then
		For $i = 0 To 4
			If $hBitmap[$i] Then
				_GDIPlus_BitmapDispose($hBitmap[$i])
			EndIf
		Next
	EndIf
	Return $ID
EndFunc   ;==>_Skin_SetButtonEx

Func _Skin_SetFocusRect($CtrlID, $iX, $iY, $iWidth, $iHeight)

	Local $ID = _sk_GetID($CtrlID)
	Local $tRect

	If Not $ID Then
		Return 0
	EndIf
	If ($iX < 0) Or ($iY < 0) Or ($iWidth < 1) Or ($iHeight < 1) Then
		If IsDllStruct($skData[$ID][12]) Then
			$skData[$ID][12] = 0
		Else
			Return 1
		EndIf
	Else
		$tRect = DllStructCreate('long;long;long;long')
		DllStructSetData($tRect, 1, $iX)
		DllStructSetData($tRect, 2, $iY)
		DllStructSetData($tRect, 3, $iX + $iWidth)
		DllStructSetData($tRect, 4, $iY + $iHeight)
		$skData[$ID][12] = $tRect
	EndIf
	If ($skData[0][8]) And ($skData[$ID][11]) Then
		_WinAPI_InvalidateRect($skData[$ID][5], 0, 0)
	EndIf
	Return 1
EndFunc   ;==>_Skin_SetFocusRect

#EndRegion Public Functions

#Region Internal Functions

Func _sk_Enum($hWnd)

	Local $Ret

	$skEnum[0] = 0
	$Ret = DllCall('user32.dll', 'int', 'EnumChildWindows', 'hwnd', $hWnd, 'ptr', DllCallbackGetPtr($skData[0][9]), 'lparam', 0)
	If (@Error) Or (Not $Ret[0]) Or (Not $skEnum[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return 1
EndFunc   ;==>_sk_Enum

Func _sk_GetBitmap($hBitmap, $hOverlap)

	Local $hGraphics, $hResult, $Size

	$Size = _sk_GdipGetImageDimension($hBitmap)
	If @Error Then
		Return 0
	EndIf
	$hResult = _sk_GdipCreateBitmapFromScan0($Size[0], $Size[1])
	$hGraphics = _GDIPlus_ImageGetGraphicsContext($hResult)
	_GDIPlus_GraphicsDrawImageRectRect($hGraphics, $hOverlap, 0, 0, $Size[0], $Size[1], 0, 0, $Size[0], $Size[1])
	_GDIPlus_GraphicsDrawImageRectRect($hGraphics, $hBitmap, 0, 0, $Size[0], $Size[1], 0, 0, $Size[0], $Size[1])
	_GDIPlus_GraphicsDispose($hGraphics)
	Return $hResult
EndFunc   ;==>_sk_GetBitmap

Func _sk_GetIcon($hBitmap)

	Local $tBITMAPINFOHEADER = DllStructCreate('dword;long;long;ushort;ushort;dword;dword;long;long;dword;dword')
	Local $tICONINFO = DllStructCreate('int;dword;dword;ptr;ptr')
	Local $tData, $Size, $Ret, $hIcon = 0
	Local $hData[2] = [0, 0]

	$Size = _sk_GdipGetImageDimension($hBitmap)
	If @Error Then
		Return 0
	EndIf
	Do
;~		$tData = _GDIPlus_BitmapLockBits($hBitmap, 0, 0, $Size[0], $Size[1], $GDIP_ILMREAD, $GDIP_PXF32ARGB)
		$tData = _GDIPlus_BitmapLockBits($hBitmap, 0, 0, $Size[0], $Size[1], 0x0001, 0x0026200A)
		DllStructSetData($tBITMAPINFOHEADER, 1, DllStructGetSize($tBITMAPINFOHEADER))
		DllStructSetData($tBITMAPINFOHEADER, 2, $Size[0])
		DllStructSetData($tBITMAPINFOHEADER, 3, $Size[1])
		DllStructSetData($tBITMAPINFOHEADER, 4, 1)
		DllStructSetData($tBITMAPINFOHEADER, 5, 32)
		DllStructSetData($tBITMAPINFOHEADER, 6, 0)
		$Ret = DllCall('gdi32.dll', 'ptr', 'CreateDIBSection', 'hwnd', 0, 'ptr', DllStructGetPtr($tBITMAPINFOHEADER), 'uint', 0, 'ptr*', 0, 'ptr', 0, 'dword', 0)
		If (@Error) Or (Not $Ret[0]) Then
			ExitLoop
		EndIf
		$hData[0] = $Ret[0]
		$Ret = DllCall('gdi32.dll', 'dword', 'SetBitmapBits', 'ptr', $hData[0], 'dword', $Size[0] * $Size[1] * 4, 'ptr', DllStructGetData($tData, 'Scan0'))
		If (@Error) Or (Not $Ret[0]) Then
			ExitLoop
		EndIf
		$hData[1] = _WinAPI_CreateBitmap($Size[0], $Size[1], 1, 1)
		DllStructSetData($tICONINFO, 1, 1)
		DllStructSetData($tICONINFO, 2, 0)
		DllStructSetData($tICONINFO, 3, 0)
		DllStructSetData($tICONINFO, 4, $hData[1])
		DllStructSetData($tICONINFO, 5, $hData[0])
		$Ret = DllCall('user32.dll', 'ptr', 'CreateIconIndirect', 'ptr', DllStructGetPtr($tICONINFO))
		If (@Error) Or (Not $Ret[0]) Then
			ExitLoop
		EndIf
		$hIcon = $Ret[0]
	Until 1
;~	If True Then
		_GDIPlus_BitmapUnlockBits($hBitmap, $tData)
;~	EndIf
	For $i = 0 To 1
		If $hData[$i] Then
			_WinAPI_DeleteObject($hData[$i])
		EndIf
	Next
	Return $hIcon
EndFunc   ;==>_sk_GetIcon

Func _sk_GetID($hWnd, $iFlag = 0)
	For $i = 1 To $skData[0][0]
		Switch $iFlag
			Case 0
				If $skData[$i][6] = $hWnd Then
					Return $i
				EndIf
			Case 1
				If $skData[$i][7] = $hWnd Then
					Return $i
				EndIf
			Case 2
				If $skData[$i][5] = $hWnd Then
					Return $i
				EndIf
			Case Else

		EndSwitch
	Next
	Return 0
EndFunc   ;==>_sk_GetID

Func _sk_HelperEx()

	Local $Result = False

	For $i = 1 To $skData[0][0]
;~		If BitAND(GUICtrlSendMsg($skData[$i][7], $BM_GETSTATE, 0, 0), $BST_PUSHED) Then
		If BitAND(GUICtrlSendMsg($skData[$i][7], 0x00F2, 0, 0),  0x04) Then
			If $skData[$i][10] Then

			Else
				If ($skData[0][1]) And ($skData[0][1] <> $i) Then
					_sk_SetIcon($skData[$skData[0][1]][5], $skData[$skData[0][1]][0])
				EndIf
				_sk_SetIcon($skData[$i][5], $skData[$i][2])
				$skData[$i][10] = 1
				For $j = 1 To 4
					$skData[0][$j] = 0
				Next
			EndIf
			$Result = 1
		Else
			If $skData[$i][10] Then
				_sk_SetIcon($skData[$i][5], $skData[$i][0])
				$skData[$i][10] = 0
			Else

			EndIf
		EndIf
	Next
	Return $Result
EndFunc   ;==>_sk_HelperEx

Func _sk_Index(ByRef $aInfo)

	Local $ID = _sk_GetID($aInfo[4])
	Local $tPoint, $tRect
	Local $ARGB

	If (Not $ID) Or ($skData[$ID][9]) Then
		Return 0
	EndIf
	If $skData[$ID][8] Then
;~		If True Then
			$tPoint = _WinAPI_GetMousePos(1, $skData[$ID][5])
;~		EndIf
		$tRect = _WinAPI_GetClientRect($skData[$ID][5])
		If (DllStructGetData($tPoint, 1) > (DllStructGetData($tRect, 3) - DllStructGetData($tRect, 1) - 1)) Or (DllStructGetData($tPoint, 2) > (DllStructGetData($tRect, 4) - DllStructGetData($tRect, 2) - 1)) Then
			Return 0
		EndIf
		$ARGB = _sk_GdipBitmapGetPixel($skData[$ID][8], DllStructGetData($tPoint, 1), DllStructGetData($tPoint, 2))
		If (Not @Error) And (Not BitAND($ARGB, 0xFF000000)) Then
			Return 0
		EndIf
	EndIf
	Return $ID
EndFunc   ;==>_sk_Index

Func _sk_IsActive($hWnd)
	If BitAND(WinGetState($hWnd), 8) Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_sk_IsActive

Func _sk_IsEnable($hWnd)
	If BitAND(WinGetState($hWnd), 4) Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_sk_IsEnable

Func _sk_IsOver($hWnd)

	If Not $hWnd Then
		Return 0
	EndIf

	Local $tPoint = _WinAPI_GetMousePos()

	If _WinAPI_WindowFromPoint($tPoint) = $hWnd Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_sk_IsOver

Func _sk_Overlap($hWnd, $iX, $iY, $iWidth, $iHeight)

	Local $hSrcDC, $hDstDC, $hSrcSv, $hDstSv, $hSrcBmp, $hDstBmp, $hBrush, $hResult
	Local $hParent = _WinAPI_GetParent($hWnd)
	Local $tRect[3], $X, $Y, $Ret
	Local $hPic = 0
    Local $tPoint

	If Not  _sk_Enum($hParent) Then
		Return 0
	EndIf
	$tPoint = DllStructCreate('long;long')
	For $i = $skEnum[0] To 1 Step -1
		If $skEnum[$i] = $hWnd Then
			ContinueLoop
		EndIf
		$tRect[0] = _WinAPI_GetWindowRect($skEnum[$i])
;~		If False Then

;~		EndIf
		$tRect[1] = DllStructCreate('long;long;long;long')
		DllStructSetData($tRect[1], 1, $iX)
		DllStructSetData($tRect[1], 2, $iY)
		DllCall('user32.dll', 'int', 'ClientToScreen', 'hwnd', $hParent, 'ptr', DllStructGetPtr($tRect[1]))
		DllStructSetData($tRect[1], 3, DllStructGetData($tRect[1], 1) + $iWidth)
		DllStructSetData($tRect[1], 4, DllStructGetData($tRect[1], 2) + $iHeight)
		$tRect[2] = DllStructCreate('long[4]')
		$Ret = DllCall('user32.dll', 'int', 'IntersectRect', 'ptr', DllStructGetPtr($tRect[2]), 'ptr', DllStructGetPtr($tRect[0]), 'ptr', DllStructGetPtr($tRect[1]))
		If (Not @Error) And ($Ret[0]) Then
			$hPic = $skEnum[$i]
			ExitLoop
		EndIf
	Next
	If Not $hPic Then
		Return 0
	EndIf
	$X = DllStructGetData($tRect[1], 1) - DllStructGetData($tRect[0], 1)
	$Y = DllStructGetData($tRect[1], 2) - DllStructGetData($tRect[0], 2)
;~	$hSrcBmp = _SendMessage($hPic, $STM_GETIMAGE, 0, 0)
	$hSrcBmp = _SendMessage($hPic, 0x0173, 0, 0)
	If Not $hSrcBmp Then
		Return 0
	EndIf
	$hDstBmp = _WinAPI_CreateBitmap($iWidth, $iHeight, 1, 32)
	$hSrcDC = _WinAPI_CreateCompatibleDC(0)
	$hSrcSv = _WinAPI_SelectObject($hSrcDC, $hSrcBmp)
	$hDstDC = _WinAPI_CreateCompatibleDC(0)
	$hDstSv = _WinAPI_SelectObject($hDstDC, $hDstBmp)
	DllStructSetData($tRect[1], 1, 0)
	DllStructSetData($tRect[1], 2, 0)
	DllStructSetData($tRect[1], 3, $iWidth)
	DllStructSetData($tRect[1], 4, $iHeight)
;~	$hBrush = _WinAPI_CreateSolidBrush(_WinAPI_GetSysColor($COLOR_3DFACE))
	$hBrush = _WinAPI_CreateSolidBrush(_WinAPI_GetSysColor(15))
	_WinAPI_FillRect($hDstDC, DllStructGetPtr($tRect[1]), $hBrush)
;~	_WinAPI_BitBlt($hDstDC, 0, 0, $iWidth, $iHeight, $hSrcDC, $X, $Y, $SRCCOPY)
	_WinAPI_BitBlt($hDstDC, 0, 0, $iWidth, $iHeight, $hSrcDC, $X, $Y, 0x00CC0020)
	_WinAPI_DeleteObject($hBrush)
	_WinAPI_SelectObject($hDstDC, $hDstSv)
	_WinAPI_DeleteDC($hDstDC)
	_WinAPI_SelectObject($hSrcDC, $hSrcSv)
	_WinAPI_DeleteDC($hSrcDC)
	$hResult = _GDIPlus_BitmapCreateFromHBITMAP($hDstBmp)
;~	If Not $hResult Then

;~	EndIf
	_WinAPI_DeleteObject($hDstBmp)
	Return $hResult
EndFunc   ;==>_sk_Overlap

Func _sk_SetIcon($hWnd, $hIcon)
;~	If _SendMessage($hWnd, $STM_SETIMAGE, 1, $hIcon) Then
	If _SendMessage($hWnd, 0x0172, 1, $hIcon) Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_sk_SetIcon

Func _sk_SetProc($hWnd, $hProc)

	Local $Ret

	If @AutoItX64 Then
		$Ret = DllCall('user32.dll', 'ptr', 'SetWindowLongPtrW', 'hwnd', $hWnd, 'int', -4, 'ptr', $hProc)
	Else
		$Ret = DllCall('user32.dll', 'ptr', 'SetWindowLongW', 'hwnd', $hWnd, 'int', -4, 'ptr', $hProc)
	EndIf
	If (@Error) Or (Not $Ret[0]) Then
		Return 0
	EndIf
	Return $Ret[0]
EndFunc   ;==>_sk_SetProc

Func _sk_SetStyle($hWnd, $iStyle, $fSet, $fExStyle = 0, $fUpdate = 0)

	Local $Flag, $Style

	If $fExStyle Then
		$Flag = -20
	Else
		$Flag = -16
	EndIf
	$Style = _WinAPI_GetWindowLong($hWnd, $Flag)
	If Not $fSet Then
		_WinAPI_SetWindowLong($hWnd, $Flag, BitAND($Style, BitNOT($iStyle)))
	Else
		_WinAPI_SetWindowLong($hWnd, $Flag, BitOR($Style, $iStyle))
	EndIf
	If $fUpdate Then
		_WinAPI_InvalidateRect($hWnd)
	EndIf
EndFunc   ;==>_sk_SetStyle

Func _sk_Update($iIndex, $iState)

	Local $ID

	If Not $iIndex Then
		$ID = $skData[0][1]
	Else
		$ID = $iIndex
		If ($skData[0][1]) And ($skData[0][1] <> $ID) Then
			_sk_SetIcon($skData[$skData[0][1]][5], $skData[$skData[0][1]][0])
		EndIf
	EndIf
	If $ID Then
;~		If True Then
			_sk_SetIcon($skData[$ID][5], $skData[$ID][$iState])
;~		EndIf
	EndIf
	$skData[0][1] = $iIndex
	$skData[0][2] = $iState
	If Not $iIndex Then
		$skData[0][4] = 0
	EndIf
EndFunc   ;==>_sk_Update

#EndRegion Internal Functions

#Region GDI+ Functions

Func _sk_GdipBitmapGetPixel($hBitmap, $iX, $iY)

	Local $Ret = DllCall($skData[0][5], 'uint', 'GdipBitmapGetPixel', 'ptr', $hBitmap, 'int', $iX, 'int', $iY, 'uint*', 0)

	If (@Error) Or ($Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[4]
EndFunc   ;==>_sk_GdipBitmapGetPixel

Func _sk_GdipCloneImage($hBitmap)

	Local $Ret = DllCall($skData[0][5], 'uint', 'GdipCloneImage', 'ptr', $hBitmap, 'ptr*', 0)

	If (@Error) Or ($Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[2]
EndFunc   ;==>_sk_GdipCloneImage

Func _sk_GdipCreateBitmapFromScan0($iWidth, $iHeight, $iStride = 0, $iPixelFormat = 0x0026200A, $pScan0 = 0)

	Local $Ret = DllCall($skData[0][5], 'uint', 'GdipCreateBitmapFromScan0', 'int', $iWidth, 'int', $iHeight, 'int', $iStride, 'int', $iPixelFormat, 'ptr', $pScan0, 'ptr*', 0)

	If (@Error) Or ($Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[6]
EndFunc   ;==>_sk_GdipCreateBitmapFromScan0

Func _sk_GdipGetImageDimension($hBitmap)

	Local $Ret = DllCall($skData[0][5], 'uint', 'GdipGetImageDimension', 'ptr', $hBitmap, 'float*', 0, 'float*', 0)

	If (@Error) Or ($Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf

	Local $Result[2]

	For $i = 0 To 1
		$Result[$i] = $Ret[$i + 2]
	Next
	Return $Result
EndFunc   ;==>_sk_GdipGetImageDimension

#cs

Func _sk_GdipShutdown()
	If _GDIPlus_Shutdown() Then
		DllClose($skData[0][5])
;~		If False Then

;~		EndIf
	EndIf
EndFunc   ;==>_sk_GdipShutdown

#ce

Func _sk_GdipStartup()
	If _GDIPlus_Startup() Then
		$skData[0][5] = DllOpen('gdiplus.dll')
;~		If False Then

;~		EndIf
	EndIf
EndFunc   ;==>_sk_GdipStartup

#EndRegion GDI+ Functions

#Region DLL Callback Functions

Func _sk_EnumProc($hWnd, $lParam)

	#forceref $lParam

	Local $Ret

	$Ret = DllCall('user32.dll', 'int', 'GetClassNameW', 'hwnd', $hWnd, 'wstr', '', 'int', 1024)
	If (@Error) Or (Not $Ret[0]) Or ($Ret[2] <> 'Static') Then
		Return 1
	EndIf
	$skEnum[0] += 1
	If $skEnum[0] > UBound($skEnum) - 1 Then
		ReDim $skEnum[$skEnum[0] + 50]
	EndIf
	$skEnum[$skEnum[0]] = $hWnd
	Return 1
EndFunc   ;==>_sk_EnumProc

Func _sk_IconProc($hWnd, $iMsg, $wParam, $lParam)

	#forceref $wParam, $lParam

	If $skData[0][8] Then
		Switch $iMsg
			Case 0x000F ; WM_PAINT

				Local $ID = _sk_GetID($hWnd, 2)

				If ($ID) And ($skData[$ID][11]) And ($skData[$ID][13]) Then

					Local $tPAINTSTRUCT = DllStructCreate('hwnd;int;long[4];int;int;byte[32]')
					Local $pPAINTSTRUCT = DllStructGetPtr($tPAINTSTRUCT)
					Local $tRECT[2], $hDC, $Ret

					$hDC = DllCall('user32.dll', 'hwnd', 'BeginPaint', 'hwnd', $hWnd, 'ptr', $pPAINTSTRUCT)
;~					DllCall('user32.dll', 'lresult', 'CallWindowProc', 'ptr', $skData[0][7], 'hwnd', $hWnd, 'uint', $WM_PRINTCLIENT, 'wparam', $hDC[0], 'lparam', $PRF_CLIENT)
					DllCall('user32.dll', 'lresult', 'CallWindowProc', 'ptr', $skData[0][7], 'hwnd', $hWnd, 'uint', 0x0318, 'wparam', $hDC[0], 'lparam', 0x04)
					For $i = 0 To 1
						$tRECT[$i] = DllStructCreate('long[4]')
					Next
					DllCall('user32.dll', 'int', 'GetClientRect', 'hwnd', $hWnd, 'ptr', DllStructGetPtr($tRECT[0]))
					If IsDllStruct($skData[$ID][12]) Then
						$Ret = DllCall('user32.dll', 'int', 'IntersectRect', 'ptr', DllStructGetPtr($tRECT[1]), 'ptr', DllStructGetPtr($tRECT[0]), 'ptr', DllStructGetPtr($skData[$ID][12]))
						If (@Error) Or (Not $Ret[0]) Then
							$tRECT[1] = $tRECT[0]
						EndIf
					EndIf
					DllCall('user32.dll', 'int', 'DrawFocusRect', 'hwnd', $hDC[0], 'ptr', DllStructGetPtr($tRECT[1]))
					DllCall('user32.dll', 'int', 'EndPaint', 'hwnd', $hWnd, 'ptr', $pPAINTSTRUCT)
					Return 0
				EndIf
			Case Else

		EndSwitch
	EndIf
	Return _WinAPI_CallWindowProc($skData[0][7], $hWnd, $iMsg, $wParam, $lParam)
EndFunc   ;==>_sk_IconProc

#EndRegion DLL Callback Functions

#Region Windows Message Functions

Func SK_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)

	#forceref $hWnd, $iMsg, $lParam

	Local $ID = _sk_GetID(_WinAPI_LoWord($wParam), 1)

	If $ID Then
		Switch _WinAPI_HiWord($wParam)
			Case 0x0000 ; BN_CLICKED
				If $skData[0][10] Then
;~					_SendMessage($skData[$ID][4], $WM_COMMAND, $skData[$ID][6], $skData[$ID][5])
					_SendMessage($skData[$ID][4], 0x0111, $skData[$ID][6], $skData[$ID][5])
				EndIf
				Return 0
			Case 0x0007 ; BN_KILLFOCUS
				$skData[$ID][11] = 0
				If $skData[0][8 ] Then
					_WinAPI_InvalidateRect($skData[$ID][5], 0, 0)
				EndIf
				Return 0
			Case 0x0006 ; BN_SETFOCUS
				$skData[$ID][11] = 1
				If $skData[0][8 ] Then
					_WinAPI_InvalidateRect($skData[$ID][5], 0, 0)
				EndIf
				Return 0
			Case Else

		EndSwitch

	EndIf
    Return 'GUI_RUNDEFMSG'
EndFunc   ;==>SK_WM_COMMAND

Func SK_WM_DRAWITEM($hWnd, $iMsg, $wParam, $lParam)

	#forceref $hWnd, $iMsg, $wParam

	Local $ID = _sk_GetID($wParam, 1)

	If $ID Then

		Local $tDRAWITEMSTRUCT = DllStructCreate('uint;uint;uint;uint;uint;hwnd;hwnd;long[4];ulong_ptr', $lParam)

;~		If BitAND(DllStructGetData($tDRAWITEMSTRUCT, 5), $ODS_NOFOCUSRECT) Then
		If BitAND(DllStructGetData($tDRAWITEMSTRUCT, 5), 0x0200) Then
			$skData[$ID][13] = 0
		Else
			$skData[$ID][13] = 1
		EndIf
		Return 1
	EndIf
	Return 'GUI_RUNDEFMSG'
EndFunc   ;==>SK_WM_DRAWITEM

#EndRegion Windows Message Functions

#Region AutoIt Exit Functions

Func _sk_Exit()
	If $skData[0][7] Then
		For $i = 1 To $skData[0][0]
			_sk_SetProc($skData[$i][5], $skData[0][7])
		Next
	EndIf
EndFunc   ;==>_sk_Exit

#EndRegion AutoIt Exit Functions
