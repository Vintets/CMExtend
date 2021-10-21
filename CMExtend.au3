#Region Header
;===============================================================================
;
; Title:            CMExtend
; Filename:         CMTools.au3
; Description:      CMExtend
; Version:          0.0.3
; Requirement(s):   Autoit 3.3.14.5
; Author(s):        Vint
; Date:             21.10.2021
;
;===============================================================================
#EndRegion Header

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=cmex.ico
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Res_Comment=CMExtend
#AutoIt3Wrapper_Res_Fileversion=0.0.3
#AutoIt3Wrapper_Res_LegalCopyright=Vint
#AutoIt3Wrapper_Res_Language=1049
#AutoIt3Wrapper_Res_requestedExecutionLevel=None
#AutoIt3Wrapper_Res_Field=Version|0.0.3
#AutoIt3Wrapper_Res_Field=Build|2021.10.21
#AutoIt3Wrapper_Res_Field=Coded by|Vint
#AutoIt3Wrapper_Res_Field=Compile date|%longdate% %time%
; #AutoIt3Wrapper_Res_Field=AutoIt Version|%AutoItVer%
#AutoIt3Wrapper_Res_Field=AutoIt Version|3.3.14.5
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Region    **** AutoItSetOption ****
#RequireAdmin
Opt('MustDeclareVars', 1)
Opt('WinWaitDelay', 100)  ; пауза после успешных оконных функций. 250 мс
Opt('TrayIconDebug', 1)
Opt('WinSearchChildren', 1)  ; Поиск окон верхнего уровня и дочерних
;~ Opt('WinTitleMatchMode', 2)  ; 1-начальное, 2-любая подстрока, 3-точное, 4-расширено, -1 to -4=Nocase
#EndRegion **** AutoItSetOption ****

#Region    ************ Includes ************
#include <WinAPI.au3>
#include <Array.au3>

#include <WindowsConstants.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#EndRegion ************ Includes ************


Global $hWndCMM = '', $hWndCM = '', $hWndCMR = '', $iPidCM = ''
Global $aPosCM[4], $aPosCMR[4]
Global $fileini = ''
Global $CM_name = ''
Global $CM_title = ''
Global $repeated = False
Global $aWindows2D[3][14], $k = 0


_Init()
_Starting()
_LogPos()


Global $hGuiDummyMain
; $hGuiDummyMain = GUICreate('dummy_main', $aPosCM[2]-6, $aPosCM[3]-30*2, 0, 30, BitOR($WS_POPUP, $WS_BORDER))
$hGuiDummyMain = GUICreate('dummy_main', $aPosCM[2]-6, $aPosCM[3]-30-29, 0, 30, $WS_POPUP)
GUISetBkColor(0xD7EAE2)
_WinAPI_SetParent($hGuiDummyMain, $hWndCM)
GUISetState(@SW_SHOW, $hGuiDummyMain)
; Sleep(10000)


While 1
    ; _CheckAvailable()
    Sleep(500)
WEnd


Func _Init()
    If @Compiled Then
        $fileini = @ScriptDir & '\settings_cme.ini'
    Else
        $fileini = @ScriptDir & '\CMTools\settings_cme.ini'
    EndIf
    _CheckINI()
    $CM_name = IniRead($fileini, 'clickermann', 'program_name', 'Clickermann')
    $CM_title = '[TITLE:' & $CM_name & '; W:310; H:194]'
EndFunc   ;==>_Init

Func _Starting()
    _WaitCM()
    _ReadPosCM('main')
    _ReadPosCM('editor')
EndFunc   ;==>_Start

Func _WaitCM()
    $hWndCM = WinWait($CM_title, '', 3)
    $repeated = False
    If Not _IsWinCM() Then
        MsgBox(16+4096, 'Внимание!', 'Окно Clickermann не найдено.' & @CRLF & 'Дополнительный функционал не подключен!', 3)
        SetError(1)
        Exit
    EndIf
EndFunc   ;==>WaitCM

Func _IsWinCM()
    $hWndCMM = _GetWin('базовое', '[CLASS:TApplication; TITLE:' & $CM_name & '; W:0; H:0]')
    $hWndCM = _GetWin('главное', $CM_title)
    If $hWndCMM And $hWndCM Then
        if Not $repeated Then
            $hWndCMR = _GetWin('редактора', '[TITLE:Редактор -]')
            ;_WinAPI_GetWindowThreadProcessId($hWndCM, $iPidCM2)

            $iPidCM = WinGetProcess($hWndCM)
            ; ConsoleWrite('Идентификатор PID ' & $iPidCM & @CRLF)
        EndIf
        $repeated = True
        return True
    Else
        $hWndCMM = ''
        $hWndCM = ''
        $hWndCMR = ''
        $iPidCM = ''
        return False
    EndIf
EndFunc   ;==>_IsWinCM

Func _GetWin($type, $data)
    Local $hWndt = WinGetHandle($data), $text
    if Not $repeated Then
        If $hWndt Then
            $text = 'окно ' & $type & ' существует  ' & $hWndt & @CRLF
        Else
            $text = 'окно ' & $type & ' НЕ существует' & @CRLF
        EndIf
        ConsoleWrite($text)
    EndIf
    Return $hWndt
EndFunc   ;==>_GetWin

Func _ReadPosCM($type)
    If $type = 'main' And $hWndCM Then
        $aPosCM = WinGetPos($hWndCM)
    EndIf
    If $type = 'editor' And $hWndCMR Then
        $aPosCMR = WinGetPos($hWndCMR)
    EndIf
EndFunc   ;==>_ReadPosCM

Func _SetPosCM($type)
;~     WinMove("title", "text", x, y , width , height)
;~     _WinAPI_MoveWindow($hWnd, 10, 10, 200, 300)
EndFunc   ;==>_SetPosCM

Func _CheckINI()
    Local $temp
    $temp = IniRead($fileini, 'clickermann', 'program_name', 0)
    If @error Then
        MsgBox(4096, '', 'Произошла ошибка, отсутствует или повреждён файл settings_cme.ini', 2)
        ; FileInstall('CMTools\settings_cme_default.ini', @ScriptDir & '\settings_cme.ini', 1)
        Sleep(500)
        Exit
    EndIf
EndFunc   ;==>_CheckINI

Func _AllWindInfo()
    Local $aWindows, $s = Chr(1)
    Local $colnames = '№' & $s & _
                    'Дескриптор' & $s & _
                    'Класс' & $s & _
                    'Заголовок' & $s & _
                    'X' & $s & _
                    'Y' & $s & _
                    'Ширина' & $s & _
                    'Высота' & $s & _
                    'Наличие' & $s & _
                    'Скрыт' & $s & _
                    'Доступно' & $s & _
                    'Активно' & $s & _
                    'Свёрнуто' & $s & _
                    'На весь экран' & $s & _
                    'Процесс'

    _AddWinInfo(0, $hWndCMM)
    _AddWinInfo(1, $hWndCM)
    _AddWinInfo(2, $hWndCMR)
    _ArrayDisplay($aWindows2D, 'Окна', Default, 0, $s, $s, $colnames)
    ConsoleWrite('Мы здесь' & @CRLF)
EndFunc   ;==>_AllWindInf

Func _AddWinInfo($num, $hWndt)
    Local $aPos = WinGetPos($hWndt)
    Local $iState = WinGetState($hWndt)
    Local $aStat[6][2] = [['+', '-'], _
                        ['-', '+'], _
                        ['+', '-'], _
                        ['+', '-'], _
                        ['+', '-'], _
                        ['+', '-']]

    If $hWndt = '' Then
        For $i = 0 To 13
            $aWindows2D[$num][$i] = '.'
        Next
        Return
    EndIf
    
    $aWindows2D[$num][0] = $hWndt
    $aWindows2D[$num][1] = _WinAPI_GetClassName($hWndt)
    $aWindows2D[$num][2] = WinGetTitle($hWndt)
    $aWindows2D[$num][3] = $aPos[0]
    $aWindows2D[$num][4] = $aPos[1]
    $aWindows2D[$num][5] = $aPos[2]
    $aWindows2D[$num][6] = $aPos[3]

    For $i = 0 To 5
        If BitAND($iState, 2 ^ $i) Then
            $aWindows2D[$num][7+$i] = $aStat[$i][0]
        Else
            $aWindows2D[$num][7+$i] = $aStat[$i][1]
        EndIf
    Next

    $aWindows2D[$num][13] = WinGetProcess($hWndt)
    ;$aWindows2D[$num][100] = WinGetText($hWndt)
EndFunc   ;==>_WinInfo

Func _LogPos()
    Local $text
    $text = 'CM_X ' & $aPosCM[0] & '  CM_Y ' & $aPosCM[1]
    $text &= '  CM_W ' & $aPosCM[2] & '  CM_H ' & $aPosCM[3] & @CRLF
    $text &= 'CMR_X ' & $aPosCMR[0] & '  CMR_Y ' & $aPosCMR[1]
    $text &= '  CMR_W ' & $aPosCMR[2] & '  CMR_H ' & $aPosCMR[3] & @CRLF
    ConsoleWrite($text)
EndFunc   ;==>_LogPos


Func _Restart()
    Local $sAutoIt_File = @TempDir & "\~Au3_ScriptRestart_TempFile.au3"
    Local $sRunLine, $sScript_Content, $hFile

    $sRunLine = @ScriptFullPath
    If Not @Compiled Then $sRunLine = @AutoItExe & ' /AutoIt3ExecuteScript ""' & $sRunLine & '""'
    If $CmdLine[0] > 0 Then $sRunLine &= ' ' & $CmdLineRaw

    $sScript_Content &= '#NoTrayIcon' & @CRLF & _
            'While ProcessExists(' & @AutoItPID & ')' & @CRLF & _
            '   Sleep(10)' & @CRLF & _
            'WEnd' & @CRLF & _
            'Run("' & $sRunLine & '")' & @CRLF & _
            'FileDelete(@ScriptFullPath)' & @CRLF

    $hFile = FileOpen($sAutoIt_File, 2)
    FileWrite($hFile, $sScript_Content)
    FileClose($hFile)

    Run(@AutoItExe & ' /AutoIt3ExecuteScript "' & $sAutoIt_File & '"', @ScriptDir, @SW_HIDE)
    Sleep(1000)
    Exit
EndFunc   ;==>_restart

#CS
;~ GUIRegisterMsg(0x0232, 'WM_EXITSIZEMOVE')
;~ GUIRegisterMsg(0x0024, 'WM_GETMINMAXINFO')
;~ GUIRegisterMsg($WM_MOVE, 'WM_MOVE')
;~ GUIRegisterMsg($WM_SIZE, 'WM_SIZE')
;~ GUIRegisterMsg($WM_COMMAND, 'WM_COMMAND')


;~ _WinAPI_SetWindowsHookEx($WH_CALLWNDPROCRET, $lpfn, $hmod , $dwThreadId = 0)

Func WM_MOVE($hWnd, $Msg, $wParam, $lParam)
    #forceref $Msg, $wParam
    Local $w, $h

    $w = BitAND($lParam, 0xFFFF) ; _WinAPI_LoWord
    $h = BitShift($lParam, 16) ; _WinAPI_HiWord

    $k += 1
    ConsoleWrite('Вызов ' & $k & ' раз, w=' & $w & ', h=' & $h)

    Return $GUI_RUNDEFMSG
EndFunc

Func WM_EXITSIZEMOVE($hWnd, $MsgID, $WParam, $LParam)
    ConsoleWrite('WM_ENTERSIZEMOVE')
EndFunc
#CE

