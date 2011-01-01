;#=#INDEX#==================================================================#
;#  Title .........: _Error Handler.au3                                     #
;#  Description....: AutoIt3 Error Handler & Debugger                       #
;#  Date ..........: 7.9.08                                                 #
;#  Authors .......: jennico (jennicoattminusonlinedotde)                   #
;#                   @MrCreatoR                                             #
;#                   MadExcept (GUI inspiration by mrRevoked)               #
;#==========================================================================#

#include-once

Global Const $MHVersionInformation = "V1.04"

Global $MHSendDataToFunc = " _DefaultMsgFunc"
Global $MHhwmd_Receiver
Global $MHAdditionalIdentifier = "_CAL987qwerty2468";just to make the window titles a little bit more unique

; Windows Definitions;
Global Const $StructDef_COPYDATA = "dword none;dword count;ptr pointer"
Global Const $WM_COPYDATA_MH = 0x4A

;Message Queue Setup
Global $MHCallBackTimer = 700
Global $pTimerProc, $uiTimer
Global $aMessageQueue[1]=[0]

Global $last_config, $last_report,$sErrorMsg
Global  $last_actions[30] = [ "" , "" , "" ,"" , "" , "" ,"" , "" , "" , "","" , "" , "" ,"" , "" , "" ,"" , "" , "" , "","" , "" , "" ,"" , "" , "" ,"" , "" , "" , "" ]
Global $sending_status
Global $current_crashlog = @ScriptDir & "\logs\crash-report-" & @MDAY & "-" & @MON & "-" & @YEAR & " (" & @HOUR & "h" & @MIN & "s" & @SEC & ").log"
Global $current_logfile = @ScriptDir & "\logs\" & @MDAY & "-" & @MON & "-" & @YEAR&".log"
Global $user_system
Global $email_address,$problem_details,$report_gui

Global $oMyRet[2]
Global $oMyError,$crash_detected=0

Global $iPID
$lang = _Language()

; Apply proxy settings
$proxy_mode = ReadSetting( "Proxy", "proxy_mode")
$proxy_url = ReadSetting( "Proxy", "proxy_url")
$proxy_port = ReadSetting( "Proxy", "proxy_port")
$proxy_username = ReadSetting( "Proxy", "proxy_username")
$proxy_password = ReadSetting( "Proxy", "proxy_password")

if $proxy_mode =2 Then
	If $proxy_url <> "" AND  $proxy_port <> "" Then
		$proxy_url &= ":" & $proxy_port
		If $proxy_username <> "" Then
			If $proxy_password <> "" Then
				HttpSetProxy(2, $proxy_url, $proxy_username, $proxy_password)
			Else
				HttpSetProxy(2, $proxy_url, $proxy_username)
			EndIf
		Else
			HttpSetProxy(2, $proxy_url)
		EndIf
	EndIf
Else
	HttpSetProxy($proxy_mode)
EndIf

OnAutoItExitRegister( "CallBack_Exit" )

_OnAutoItError()

;#=#Function#===============================================================#
;#  Title .........: _OnAutoItError()                                       #
;#  Description....: AutoIt3 Error Handler & Debugger GUI                   #
;#  Parameters.....: (None)                                                 #
;#  Date ..........: 7.9.08                                                 #
;#  Authors .......: jennico (jennicoattminusonlinedotde)                   #
;#                   @MrCreatoR                                             #
;#==========================================================================#

;   this function is made to be customized !
Func _OnAutoItError()
    If StringInStr($CmdLineRaw,"/AutoIt3ExecuteScript") Then Return
    Opt("TrayIconHide",1)
    ;   run a second instance
    $iPID=Run(@AutoItExe&' /ErrorStdOut /AutoIt3ExecuteScript "'&@ScriptFullPath&'"',@ScriptDir,0,6)
    ProcessWait($iPID)
    $sErrorMsg=""
	$hwnd = _SetAsReceiver("lili-Reporter")
	$myFunc = _SetReceiverFunction("_ReceiveReport")

	$timer_check=TimerInit()
	$update_checked=0

	;   trap the error message
    While 1
        $sErrorMsg&=StdoutRead($iPID)
        If @error Then ExitLoop
		if TimerDiff($timer_check) > 10000 AND $update_checked=0 Then
			Check_for_compatibility_list_updates()
			$update_checked=1
		EndIf
        Sleep(1000)
    WEnd
    If StringStripWS($sErrorMsg, 8)="" Then
		ProcessClose("LiLi USB Creator.exe")
		Exit
	EndIf
	; Updating last log file with crash report
	$report=ConstructReport()
	_FileWriteLog($current_logfile,"!!!!!! Crash Detected : "&$sErrorMsg)
	_FileWriteLog($current_crashlog,$report)

	#cs
	GUICreate("LiLi USB Creator Automatic Bug Report",400,90,Default,Default,-2134376448);BitOR($WS_CAPTION,$WS_POPUP,$WS_SYSMENU)
    GUISetBkColor(0xE0DFE2)
        GUICtrlSetBkColor(GUICtrlCreateLabel("",1,1,398,1),0x41689E)
        GUICtrlSetBkColor(GUICtrlCreateLabel("",1,88,398,1),0x41689E)
        GUICtrlSetBkColor(GUICtrlCreateLabel("",1,1,1,88),0x41689E)
        GUICtrlSetBkColor(GUICtrlCreateLabel("",398,1,1,88),0x41689E)
        GUICtrlCreateIcon("user32.dll",103,11,21,32,32)
        GUICtrlSetBkColor(GUICtrlCreateLabel(Translate("An error occurred.") & @CRLF & Translate("An anonymous report was sent in order to fix this error as soon as possible")&"." ,52,8,190,60),-2)
		$sending_status = GUICtrlCreateLabel(Translate("Report status")& " : " & Translate("Pending"),52,58,195,20)
		GUICtrlSetBkColor($sending_status,-2)
		#cs
		GUICtrlSetBkColor(GUICtrlCreateLabel($last_report,52,41,175,15),-2)
        GUICtrlSetBkColor(GUICtrlCreateLabel("",10,60,110,22),0x706E63)
            GUICtrlSetState(-1,128)
        $send=GUICtrlCreateLabel("   send bug report",28,64,92,15)
            GUICtrlSetBkColor(-1,-2)
            GUICtrlSetColor(-1,0xFFFFFF)
            GUICtrlSetCursor(-1,0)
        $sen=GUICtrlCreateIcon("explorer.exe",254,13,63,16,16)
            GUICtrlSetCursor(-1,0)

		GUICtrlSetBkColor(GUICtrlCreateLabel("",246,8,141,22),0xEFEEF2)
            GUICtrlSetState(-1,128)
        $show=GUICtrlCreateLabel("    "& Translate("Show bug report"),265,12,115,15)
            If @Compiled=0 Then GUICtrlSetData(-1,"    Debugger")
            GUICtrlSetBkColor(-1,-2)
            GUICtrlSetCursor(-1,0)
			GUICtrlSetOnEvent(-1, "GUI_Err_Debug")
        $sho=GUICtrlCreateIcon("shell32.dll",290,249,11,16,16)
            If @Compiled=0 Then GUICtrlSetImage(-1,"shell32.dll",-81)
            GUICtrlSetCursor(-1,0)

		GUICtrlSetBkColor(GUICtrlCreateLabel("",246,34,141,22),0xEFEEF2)
            GUICtrlSetState(-1,128)
        $rest=GUICtrlCreateLabel("    "& Translate("Restart application"),265,38,115,15)
            GUICtrlSetBkColor(-1,-2)
            GUICtrlSetCursor(-1,0)
			GUICtrlSetOnEvent(-1, "GUI_Err_RunAgain")

        $res=GUICtrlCreateIcon("shell32.dll",255,249,37,16,16)
            GUICtrlSetCursor(-1,0)
		#ce

		GUICtrlSetBkColor(GUICtrlCreateLabel("",246,34,141,22),0xEFEEF2)
            GUICtrlSetState(-1,128)
        $show=GUICtrlCreateLabel("    "& Translate("Show bug report"),265,38,115,15)
            If @Compiled=0 Then GUICtrlSetData(-1,"    Debugger")
            GUICtrlSetBkColor(-1,-2)
            GUICtrlSetCursor(-1,0)
			GUICtrlSetOnEvent(-1, "GUI_Err_Debug")
        $sho=GUICtrlCreateIcon("shell32.dll",255,249,37,16,16)
            If @Compiled=0 Then GUICtrlSetImage(-1,"shell32.dll",-81)
            GUICtrlSetCursor(-1,0)


        GUICtrlSetBkColor(GUICtrlCreateLabel("",246,60,141,22),0xEFEEF2)
            GUICtrlSetState(-1,128)
        $close=GUICtrlCreateLabel("     "& Translate("Close application"),265,64,115,15)
            GUICtrlSetBkColor(-1,-2)
            GUICtrlSetCursor(-1,0)
			GUICtrlSetOnEvent(-1, "GUI_Err_Stop")
        $clos=GUICtrlCreateIcon("shell32.dll",240,249,63,16,16)
            GUICtrlSetCursor(-1,0)

    Opt("TrayIconHide",0)
    Opt("TrayAutoPause",0)

    TraySetToolTip("LiLi Creator Automatic Bug Report")
	TraySetIcon(@ScriptDir&"\tools\img\lili.ico")
    GUISetState()
    WinSetOnTop("LiLi USB Creator Automatic Bug Report","",1)
    ;   choose action to be taken
	If ReadSetting("Advanced", "skip_autoreport")<>"yes" Then
		If SendBug() <> "OK" Then
			GUICtrlSetData($sending_status,Translate("Report status")& " : " & Translate("Error (not sent)"))
		Else
			GUICtrlSetData($sending_status,Translate("Report status")& " : " & Translate("Sent"))
		EndIf

	Endif

    While 1
		Sleep(60000)
    Wend
	#ce
	Opt("TrayIconHide",0)
    Opt("TrayAutoPause",0)
	Opt("GUIOnEventMode",1)

	GUICreate("LiLi USB Creator Automatic Crash Report",461,401)
	GUISetOnEvent($GUI_EVENT_CLOSE,"GUI_Err_Stop")

	$group_welcome = GUICtrlCreateGroup("Welcome to the automatic crash reporter", 18, 12, 425, 89)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUICtrlCreateIcon("user32.dll", 103, 35, 45, 32, 32)
	GUICtrlCreateLabel(Translate("I'm sorry for the inconvenience but LiLi has crashed")&"."&@CRLF&@CRLF&Translate("Please enter an email address and a detailed comment about this crash."&@CRLF&"I will contact you as soon as I can."),90,35,340,60)

	$group_email = GUICtrlCreateGroup("Your Email address", 18, 112, 425, 57)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$email_address = GUICtrlCreateInput("", 108, 136, 249, 21)

	$group_details = GUICtrlCreateGroup("Problem Details", 18, 184, 425, 177)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$problem_details = GUICtrlCreateEdit("", 34, 208, 393, 137, BitOR($ES_AUTOVSCROLL,$ES_WANTRETURN,$WS_VSCROLL))

	$offx_b1=17
	$offy_b1=370

	GUICtrlCreateButton("  "&Translate("Show crash report"),  $offx_b1,$offy_b1, 120, 24)
	GUICtrlSetOnEvent(-1, "GUI_Err_Debug")
	GUICtrlSetImage(-1, "shell32.dll", -210,0)


	GUICtrlCreateButton("  "&Translate("Close (don't send)"),  $offx_b1+155,$offy_b1, 120, 24)
	GUICtrlSetOnEvent(-1,"GUI_Err_Stop")
	GUICtrlSetImage(-1, "shell32.dll", -132,0)


	GUICtrlCreateButton("  "&Translate("Send Report"),  $offx_b1+310,$offy_b1, 120, 24)
	GUICtrlSetOnEvent(-1,"SendCrashReport")
	GUICtrlSetImage(-1, "shell32.dll", -177,0)



    TraySetToolTip("LiLi USB Creator Automatic Crash Report")
	TraySetIcon(@ScriptDir&"\tools\img\lili.ico")
	GUISetState(@SW_SHOW)
    WinActivate("LiLi USB Creator Automatic Crash Report","")

    While 1
		Sleep(60000)
    Wend

EndFunc

#cs
Func CheckIfRunningOrphaned()
	If @Compiled Then
		$list = ProcessList("LiLi USB Creator.exe")
	Else
		$list = ProcessList("AutoIT3.exe")
	EndIf

	if $crash_detected=0 AND $list[0][0]<2 Then
		_ArrayDisplay($list)
		Exit
	EndIf
EndFunc
#ce

Func GUI_Err_Debug()
	;If @Compiled=0 Then MsgBox(270400,Translate("Show bug report"),ConstructReport())
	;If @Compiled Then MsgBox(270400,Translate("Show bug report"),ConstructReport())
	$report_gui=GUICreate("Crash Report",400,300)
	GUISetOnEvent($GUI_EVENT_CLOSE,"GUI_Close_Report",$report_gui)
	GUICtrlCreateEdit(ConstructReport(), 0,0,400,300,$WS_VSCROLL+$ES_READONLY)
	GUISetState(@SW_SHOW,$report_gui)
EndFunc

Func GUI_Close_Report()
	GUIDelete($report_gui)
	WinActivate(WinActivate("LiLi USB Creator Automatic Crash Report",""))
EndFunc

Func GUI_Err_RunAgain()
	Run(@AutoItExe&' "'&@ScriptFullPath&'"',@ScriptDir,0,6)
EndFunc

Func GUI_Err_Stop()
	Exit
EndFunc

; sending the Crash report using HTTPS
Func SendCrashReport()
	$hw_open = _WinHttpOpen()
	; Options to avoid checking SSL certificate
	_WinHttpSetOption($hw_open, $WINHTTP_OPTION_SECURITY_FLAGS, BitOR($SECURITY_FLAG_IGNORE_UNKNOWN_CA, $SECURITY_FLAG_IGNORE_CERT_CN_INVALID,$SECURITY_FLAG_IGNORE_CERT_DATE_INVALID,$SECURITY_FLAG_IGNORE_CERT_WRONG_USAGE))

	$hw_connect = _WinHttpConnect($hw_open, "www.linuxliveusb.com",$INTERNET_DEFAULT_HTTPS_PORT)
	$h_openRequest = _WinHttpOpenRequest($hw_connect, "POST", "/bugs/automatic-bug-report.php","","","",$WINHTTP_FLAG_SECURE)

	_WinHttpAddRequestHeaders($h_openRequest,"LiLi USB Creator " & $software_version)
	_WinHttpAddRequestHeaders($h_openRequest, "Content-Type: multipart/form-data; boundary=" & $HTTP_POST_BOUNDARY)

	InitPostData()
	AddPostData("REPORTER_ID",ReadSetting( "General", "unique_ID"))
	AddPostData("ERROR_MSG",$sErrorMsg)
	AddPostData("SOFTWARE_VERSION",$software_version)
	AddPostData("OS_VERSION",@OSVersion)
	AddPostData("ARCH",@OSArch)
	AddPostData("SERVICE_PACK",@OSServicePack)
	AddPostData("LANGUAGE",_Language_for_stats())
	AddPostData("TEN_LAST_ACTIONS",_ArrayToString($last_actions,@CRLF & "--> "))
	AddPostData("LAST_CONFIG",$last_config)
	AddPostData("PROBLEM_DETAILS",GUICtrlRead($problem_details))
	AddPostData("EMAIL_ADDRESS",GUICtrlRead($email_address))
	ClosePostData()

	_WinHttpAddRequestHeaders($h_openRequest,"Content-Length: "& StringLen($post_data))
	_WinHttpSendRequest($h_openRequest, $WINHTTP_NO_ADDITIONAL_HEADERS,$post_data)

	_WinHttpReceiveResponse($h_openRequest)

	If _WinHttpQueryDataAvailable($h_openRequest) Then
		$header = StringLeft(_WinHttpQueryHeaders($h_openRequest),50)
		$source_return = _WinHttpReadData($h_openRequest)
		;debug purpose :
		;MsgBox(0, "Header", $header &@CRLF&"---------------------------------"&@CRLF&$source_return)
		_WinHttpCloseHandle($h_openRequest)
		_WinHttpCloseHandle($hw_connect)
		_WinHttpCloseHandle($hw_open)

		; Checking if status is OK
		if StringInStr($source_return,"CRASH_SUCCESSFULLY_RECORDED") Then
			MsgBox(64,"","You crash report has been sent."&@CRLF&@CRLF&"Thank you !")
		Else
			MsgBox(48,"ERROR","Could not send crash report."&@CRLF&@CRLF&"Please contact debug@linuxliveusb.com")
		EndIf
	Else
		_WinHttpCloseHandle($h_openRequest)
		_WinHttpCloseHandle($hw_connect)
		_WinHttpCloseHandle($hw_open)
		MsgBox(48,"ERROR","Could not send crash report."&@CRLF&@CRLF&"Please check your internet connection.")
	EndIf

EndFunc

Func ConstructReport()
	$temp = "REPORTER_ID : "&ReadSetting( "General", "unique_ID") _
	&@CRLF& "ERROR_MSG : "&$sErrorMsg _
	&@CRLF&"SOFTWARE_VERSION : "&$software_version _
	&@CRLF&"OS_VERSION : "&@OSVersion _
	&@CRLF&"ARCH : "&@OSArch _
	&@CRLF&"SERVICE_PACK : "&@OSServicePack _
	&@CRLF&"LANGUAGE : "&_Language_for_stats() _
	&@CRLF&"LAST ACTION : "&@CRLF&_ArrayToString($last_actions,@CRLF & "--> ") _
	&@CRLF&"LAST CONFIG : "&@CRLF&$last_config
	Return $temp
EndFunc

Func ConstructHTMLReport()
	$temp = "<html><head></head><body><center><h3>Report ID : "& ReadSetting( "General", "unique_ID") & "</h3></center><br/><h3><u>Error :</u></h3><br/><pre>" & $sErrorMsg & "</pre><br/><h3><u>30 last actions : </u></h3><pre>" & _
	_ArrayToString($last_actions,@CRLF & "--> ")  &  "</pre><br/><h3><u>System configuration :</u></h3><pre>" & $last_config  & "</pre></body></html>"
	Return $temp
EndFunc

Func SendReportToMain($report)
	UpdateLog("Sending report to main GUI :"&$report)
	_SendData($report, "lili-main")
EndFunc   ;==>SendReport

Func _ReceiveReport($report)
	If StringLeft($report, 12) = @CRLF & "----------" Then
		$last_config = $report
	ElseIf StringLeft($report, 6) = "stats-" Then
		$stats = StringTrimLeft($report, 6)
		InetGet("https://www.linuxliveusb.com/stats/?"&$stats,"",3,1)
	;ElseIf StringLeft($report, 8) = "logfile-" Then
	;	$current_logfile = StringTrimLeft($report, 6)
	ElseIf StringLeft($report, 8) = "distrib-" Then
		$distrib= StringTrimLeft($report, 8)
		InetGet("https://www.linuxliveusb.com/stats/?distrib="&$distrib&"&id="&$anonymous_id,"",3,1)
	ElseIf StringLeft($report, 17) = "check_for_updates" Then
		Check_for_updates()
		;Check_for_compatibility_list_updates()
	ElseIf StringLeft($report, 12) = "End-GUI_Exit" Then
		Exit
	Else
		ConsoleWrite($report & @CRLF)
		$last_report = $report
		_ArrayPush($last_actions,$report)
	EndIf
EndFunc

Func MyErrFunc()
    $HexNumber = Hex($oMyError.number, 8)
    $oMyRet[0] = $HexNumber
    $oMyRet[1] = StringStripWS($oMyError.description,3)
    ;ConsoleWrite("### COM Error !  Number: " & $HexNumber & "   ScriptLine: " & $oMyError.scriptline & "   Description:" & $oMyRet[1] & @LF)
    SetError(1); something to check for when this function returns
    Return
EndFunc;==>MyErrFunc

;#=#Function#===============================================================#
;#  Name ..........: __Debug ( $txt )                                       #
;#  Description....: Debug Function for _ErrorHandler.au3                   #
;#  Parameters.....: $txt = Error Message Text from StdoutRead              #
;#  Date ..........: 7.9.08                                                 #
;#  Authors .......: jennico (jennicoattminusonlinedotde)                   #
;#==========================================================================#

Func __Debug($txt)
    WinSetState(@ScriptName,"",@SW_HIDE)
    $a=StringSplit($txt,@CRLF,1)
    Dim $b=StringSplit($a[1],") : ==> ",1),$number=StringMid($b[1],StringInStr($b[1],"(")+1)
    Dim $code="Error Code: "&@TAB&StringTrimRight($b[2],2),$line="Line: "&@TAB&$number&" => "&$a[3]
    Dim $file="File: "&@TAB&StringReplace($b[1]," ("&$number,""),$count=StringLen($code),$height=180
    If StringLen($file)>$count Then $count=StringLen($file)
    If StringLen($line)>$count Then $count=StringLen($line)
    If StringLen($a[2])>$count Then $count=StringLen($a[2])
    If $count*6>@DesktopWidth-50 Then Dim $count=(@DesktopWidth-50)/6,$height=240
    Run(RegRead("HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\SciTE.exe","")& _
        ' "'&@ScriptFullPath&'" /goto:'&$number&","&StringLen($a[2])-1)
    $x=InputBox(" Please Correct this line:",$code&@CRLF&@CRLF&$file&@CRLF&@CRLF& _
        $line,StringTrimRight($a[2],1),"",$count*6,$height)
    WinSetState(@ScriptName,"",@SW_SHOW)
    If $x="" Or $x=StringTrimRight($a[2],1) Then Return
    $t=StringSplit(FileRead(@ScriptFullPath),@CRLF,1)
    $t[$number]=StringReplace($t[$number],StringTrimRight($a[2],1),$x)
    $open=FileOpen(@ScriptFullPath,2)
    For $i=1 to $t[0]
        FileWriteLine($open,$t[$i])
    Next
    FileClose($open)
    ControlSend(@ScriptDir,"","ToolbarWindow32","^R")
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _MHVersion
; Description ...: Gets Message Handler Version information
; Syntax.........: _MHVersion()
; Parameters ....: None
; Return values .: Message Handler Version Number
; Author ........: ChrisL
; ===============================================================================================================================
Func _MHVersion()

	Return $MHVersionInformation

EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _SetCallBackTimerInterval
; Description ...: Sets the script up to accept messages
; Syntax.........: _SetCallBackTimerInterval(nnn)
; Parameters ....: $iTime     - Callback timer in milliseconds to process each message in the queue
; Return values .: Success    - The new callback timer
;                  Failure    - @error is set and the previous callback timer setting is used. Default is 200ms
; Information ...: The timer must be changed before _SetAsReceiver() is called
; Author ........: ChrisL
; ===============================================================================================================================
Func _SetCallBackTimerInterval($iTime = 200)
	If Not IsInt($iTime) then Return SetError(1,0,$MHCallBackTimer) ;not an integer so set error and return current setting
	If $MHhwmd_Receiver <> "" then Return SetError(1,0,$MHCallBackTimer) ;the receiver function is already set so the timer can not be changed
	If $iTime = 0 then Return $MHCallBackTimer ;Return existing value
	If $iTime < 50 then $iTime = 50
	$MHCallBackTimer = $iTime
	Return SetError(0,0,$iTime)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _CALLBACKQUEUE
; Description ...: Process any messages that are queued and adjust the message queue
; Syntax.........: None
; Parameters ....: None
; Return values .: None
; Author ........: ChrisL
; ===============================================================================================================================
Func _CALLBACKQUEUE()

	Local $vMessage
	Local $queueLen = $aMessageQueue[0]

	If $queueLen > 0 then
		$vMessage = $aMessageQueue[1]
		$aMessageQueue[1] = ""
		For $i = 1 to $queueLen -1
			$aMessageQueue[$i] = $aMessageQueue[$i +1]
		Next

		Redim $aMessageQueue[$queueLen]

		$aMessageQueue[0] = $queueLen - 1
		Call($MHSendDataToFunc,$vMessage)
	EndIf

EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _QueueMessage
; Description ...: Queues messages to prevent script slowdown
; Syntax.........: _QueueMessage($vText)
; Parameters ....: $vText    - The text to queue from the remote script
; Return values .: None
; Author ........: ChrisL
; ===============================================================================================================================
Func _QueueMessage($vText)
	Redim $aMessageQueue[$aMessageQueue[0] +2]
	$aMessageQueue[$aMessageQueue[0] +1] = $vText
	$aMessageQueue[0]+=1
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _SetAsReceiver
; Description ...: Sets the script up to accept messages
; Syntax.........: _SetAsReceiver($vTitle)
; Parameters ....: $vTitle    - The Local_ReceiverID_Name
; Return values .: Success    - Handle to the receiver window
;                  Failure    - @error is set and the relevant message is displayed
; Author ........: ChrisL
; ===============================================================================================================================
Func _SetAsReceiver($vTitle)

	If StringLen($vTitle) = 0 then
		Msgbox(16 + 262144,"Message Handler Error","A Local_ReceiverID_Name must be specified." & @crlf & _
			"Messages will not be received unless a unique Local_ReceiverID_Name is used!")
		Return SetError(1,1,-1);Make sure the user has specified a title
	EndIf

	$vTitle &= $MHAdditionalIdentifier;add on our additionalIdentifier which is unlikely to be used exept by scripts using this UDF

	If WInExists($vtitle) and WinGetHandle($vTitle) <> $MHhwmd_Receiver then ;already a window exists with this title and it's not ours highly unlikely unless 2 copies of the script are running
		;Msgbox(16 + 262144,"ERROR", "Only run one LiLi USB Creator at a time please - PID :"&$iPID&"PID reporter:"&@AutoItPID )
		if $iPID Then ProcessClose($iPID)
		Exit
		#cs
		Msgbox(16 + 262144,"Message Handler Error","The Local_ReceiverID_Name " & StringTrimRight($vTitle,StringLen($MHAdditionalIdentifier)) & " already exists." & @crlf & _
			"A unique Local_ReceiverID_Name must be specified." & @crlf & _
			"Messages will not be received unless a unique Local_ReceiverID_Name is used!")
		#ce
		Return SetError(1,2,-1)
	EndIf

	$MHhwmd_Receiver = GUICreate($vTitle)
	GUIRegisterMsg($WM_COPYDATA_MH, "_GUIRegisterMsgProc")
	$pTimerProc = DllCallbackRegister("_CALLBACKQUEUE", "none", "")
	$uiTimer = DllCall("user32.dll", "uint", "SetTimer", "hwnd", 0, "uint", 0, "int", $MHCallBackTimer, "ptr", DllCallbackGetPtr($pTimerProc))
	$uiTimer = $uiTimer[0]
	Return $MHhwmd_Receiver

EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _SetAsReceiver
; Description ...: Sets the script up to accept messages
; Syntax.........: _SetAsReceiver($vTitle)
; Parameters ....: $vTitle    - The Local_ReceiverID_Name
; Return values .: Success    - Handle to the receiver window
;                  Failure    - @error is set and the relevant message is displayed
; Author ........: ChrisL
; ===============================================================================================================================
Func _SetAsReceiverNoCallback($vTitle)

	If StringLen($vTitle) = 0 then
		Msgbox(16 + 262144,"Message Handler Error","A Local_ReceiverID_Name must be specified." & @crlf & _
			"Messages will not be received unless a unique Local_ReceiverID_Name is used!")
		Return SetError(1,1,-1);Make sure the user has specified a title
	EndIf

	$vTitle &= $MHAdditionalIdentifier;add on our additionalIdentifier which is unlikely to be used exept by scripts using this UDF

	If WInExists($vtitle) and WinGetHandle($vTitle) <> $MHhwmd_Receiver then ;already a window exists with this title and it's not ours highly unlikely unless 2 copies of the script are running
		;Msgbox(16 + 262144,"ERROR", "Only run one LiLi USB Creator at a time please - PID :"&$iPID&"PID reporter:"&@AutoItPID )
		if $iPID Then ProcessClose($iPID)
		Exit
		#cs
		Msgbox(16 + 262144,"Message Handler Error","The Local_ReceiverID_Name " & StringTrimRight($vTitle,StringLen($MHAdditionalIdentifier)) & " already exists." & @crlf & _
			"A unique Local_ReceiverID_Name must be specified." & @crlf & _
			"Messages will not be received unless a unique Local_ReceiverID_Name is used!")
		#ce
		Return SetError(1,2,-1)
	EndIf

	$MHhwmd_Receiver = GUICreate($vTitle)
	GUIRegisterMsg($WM_COPYDATA_MH, "_GUIRegisterMsgProc")
	;$pTimerProc = DllCallbackRegister("_CALLBACKQUEUE", "none", "")
	;$uiTimer = DllCall("user32.dll", "uint", "SetTimer", "hwnd", 0, "uint", 0, "int", $MHCallBackTimer, "ptr", DllCallbackGetPtr($pTimerProc))
	;$uiTimer = $uiTimer[0]
	Return $MHhwmd_Receiver

EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _SetReceiverFunction
; Description ...: Sets the function to call on receiving data
; Syntax.........: _SetReceiverFunction($vString)
; Parameters ....: $vString   - The string of data to send
; Return values .: Success    - The users function name to call
;                  Failure    - @error is set and "" is returned
; Author ........: ChrisL
; ===============================================================================================================================
Func _SetReceiverFunction($vString)
	If $vString = "" then return SetError(1,1,$vString)
	$MHSendDataToFunc = $vString
	Return SetError(0,0,$MHSendDataToFunc)
EndFunc


; #FUNCTION# ====================================================================================================================
; Name...........: _SendData
; Description ...: Sends data to the registered window
; Syntax.........: _SendData($vData,$ReceiverTitle)
; Parameters ....: $vData           - The string of data to send
;                  $ReceiverTitle   - Remote_ReceiverID_Name specified in the script you wish to communicate to
; Return values .: Success      - The count of the string length sent
;                  Failure      - @error is set and 0 is returned
; Author ........: martin, piccaso and ChrisL
; ===============================================================================================================================
Func _SendData($vData,$ReceiverTitle)
	Local $strLen,$CDString,$vs_cds,$pCDString,$pStruct,$hwndRec

	If StringLen($ReceiverTitle) = 0 then Return SetError(1,1,0);Make sure the user has specified a title
	$ReceiverTitle&= $MHAdditionalIdentifier

	$strLen = StringLen($vData)
	$CDString = DllStructCreate("char var1[" & $strLen +1 & "]");the array to hold the string we are sending
	DllStructSetData($CDString,1,$vData)

	$pCDString = DllStructGetPtr($CDString);the pointer to the string

	$vs_cds = DllStructCreate($StructDef_COPYDATA);create the message struct
	DllStructSetData($vs_cds,"count",$strLen + 1);tell the receiver the length of the string +1
	DllStructSetData($vs_cds,"pointer",$pCDString);the pointer to the string

	$pStruct = DllStructGetPtr($vs_cds)

	$hwndRec = WinGetHandle($ReceiverTitle)
	If $hwndRec = "" then
		$vs_cds = 0;free the struct
		$CDString = 0;free the struct
		Return SetError(1,2,0)
	EndIf


	DllCall("user32.dll", "lparam", "SendMessage", "hwnd", $hwndRec, "int", $WM_COPYDATA_MH, "wparam", 0, "lparam", $pStruct)
	If @error then
		$vs_cds = 0;free the struct
		$CDString = 0;free the struct
		return SetError(1, 3, 0) ;return 0 no data sent
	EndIf


	$vs_cds = 0;free the struct
	$CDString = 0;free the struct
	Return $strLen
EndFunc

; #FUNCTION# ====================================================================================================================
; Name...........: _GUIRegisterMsgProc
; Description ...: Called when a messae is sent to the registered window
; Syntax.........: _GUIRegisterMsgProc($hWnd, $MsgID, $wParam, $lParam)
; Parameters ....: $hWnd       - Window/control handle
;                  $iMsg       - Message ID received
;                  $wParam     - Could specify additional message-specific information
;                  $lParam     - Specifies a pointer to the message
; Return values .: None        - Calls user specified function
; Author ........: piccaso
; Modified.......: ChrisL and martin
; ===============================================================================================================================
Func _GUIRegisterMsgProc($hWnd, $MsgID, $WParam, $LParam)
	Local $vs_cds,$vs_msg

    If $MsgID = $WM_COPYDATA_MH Then ; We Recived a WM_COPYDATA Message
       ; $LParam = Poiter to a COPYDATA Struct
        $vs_cds = DllStructCreate($StructDef_COPYDATA, $LParam)
       ; Member No. 3 of COPYDATA Struct (PVOID lpData;) = Pointer to Custom Struct
        $vs_msg = DllStructCreate("char[" & DllStructGetData($vs_cds, "count") & "]", DllStructGetData($vs_cds, "pointer"))
       ; Call the function to queue the received data
		_QueueMessage(DllStructGetData($vs_msg, 1))
		$vs_cds = 0
		$vs_msg = 0
    EndIf

EndFunc  ;==>_GUIRegisterMsgProc


; #FUNCTION# ====================================================================================================================
; Name...........: _DefaultMsgFunc
; Description ...: If no user function is specified this function i used to receive data
; Syntax.........: _DefaultMsgFunc($vText)
; Parameters ....: $vText     - The data sent be the other script
; Return values .: None
; Author ........: ChrisL
; ===============================================================================================================================
Func _DefaultMsgFunc($vText)
	Msgbox(0," _DefaultMsgFunc",$vText)
EndFunc  ;==>_DefaultMsgFunc


;Release the CallBack resources
Func CallBack_Exit()
	If $MHhwmd_Receiver <> "" then
		DllCallbackFree($pTimerProc)
		DllCall("user32.dll", "int", "KillTimer", "hwnd", 0, "uint", $uiTimer)
	EndIf
EndFunc

