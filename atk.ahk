﻿#NoEnv
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
; search?
; definitely need to get rid of ESC!
; change delete unselected to keep unselected
; should go to bottom entry (or keep same entry) on delete / keep
; need intellitype

/*
	Function: Anchor
		Defines how controls should be automatically positioned relative to the new dimensions of a window when resized.
	Parameters:
		cl - a control HWND, associated variable name or ClassNN to operate on
		a - (optional) one or more of the anchors: 'x', 'y', 'w' (width) and 'h' (height),
			optionally followed by a relative factor, e.g. "x h0.5"
		r - (optional) true to redraw controls, recommended for GroupBox and Button types
	Examples:
> "xy" ; bounds a control to the bottom-left edge of the window
> "w0.5" ; any change in the width of the window will resize the width of the control on a 2:1 ratio
> "h" ; similar to above but directrly proportional to height
	Remarks:
		To assume the current window size for the new bounds of a control (i.e. resetting) simply omit the second and third parameters.
		However if the control had been created with DllCall() and has its own parent window,
			the container AutoHotkey created GUI must be made default with the +LastFound option prior to the call.
		For a complete example see anchor-example.ahk.
	License:
		- Version 4.60a <http://www.autohotkey.net/~polyethene/#anchor>
		- Dedicated to the public domain (CC0 1.0) <http://creativecommons.org/publicdomain/zero/1.0/>
*/
Anchor(i, a = "", r = false) {
	static c, cs = 12, cx = 255, cl = 0, g, gs = 8, gl = 0, gpi, gw, gh, z = 0, k = 0xffff
	If z = 0
		VarSetCapacity(g, gs * 99, 0), VarSetCapacity(c, cs * cx, 0), z := true
	If (!WinExist("ahk_id" . i)) {
		GuiControlGet, t, Hwnd, %i%
		If ErrorLevel = 0
			i := t
		Else ControlGet, i, Hwnd, , %i%
	}
	VarSetCapacity(gi, 68, 0), DllCall("GetWindowInfo", "UInt", gp := DllCall("GetParent", "UInt", i), "UInt", &gi)
		, giw := NumGet(gi, 28, "Int") - NumGet(gi, 20, "Int"), gih := NumGet(gi, 32, "Int") - NumGet(gi, 24, "Int")
	If (gp != gpi) {
		gpi := gp
		Loop, %gl%
			If (NumGet(g, cb := gs * (A_Index - 1)) == gp) {
				gw := NumGet(g, cb + 4, "Short"), gh := NumGet(g, cb + 6, "Short"), gf := 1
				Break
			}
		If (!gf)
			NumPut(gp, g, gl), NumPut(gw := giw, g, gl + 4, "Short"), NumPut(gh := gih, g, gl + 6, "Short"), gl += gs
	}
	ControlGetPos, dx, dy, dw, dh, , ahk_id %i%
	Loop, %cl%
		If (NumGet(c, cb := cs * (A_Index - 1)) == i) {
			If a =
			{
				cf = 1
				Break
			}
			giw -= gw, gih -= gh, as := 1, dx := NumGet(c, cb + 4, "Short"), dy := NumGet(c, cb + 6, "Short")
				, cw := dw, dw := NumGet(c, cb + 8, "Short"), ch := dh, dh := NumGet(c, cb + 10, "Short")
			Loop, Parse, a, xywh
				If A_Index > 1
					av := SubStr(a, as, 1), as += 1 + StrLen(A_LoopField)
						, d%av% += (InStr("yh", av) ? gih : giw) * (A_LoopField + 0 ? A_LoopField : 1)
			DllCall("SetWindowPos", "UInt", i, "Int", 0, "Int", dx, "Int", dy
				, "Int", InStr(a, "w") ? dw : cw, "Int", InStr(a, "h") ? dh : ch, "Int", 4)
			If r != 0
				DllCall("RedrawWindow", "UInt", i, "UInt", 0, "UInt", 0, "UInt", 0x0101) ; RDW_UPDATENOW | RDW_INVALIDATE
			Return
		}
	If cf != 1
		cb := cl, cl += cs
	bx := NumGet(gi, 48), by := NumGet(gi, 16, "Int") - NumGet(gi, 8, "Int") - gih - NumGet(gi, 52)
	If cf = 1
		dw -= giw - gw, dh -= gih - gh
	NumPut(i, c, cb), NumPut(dx - bx, c, cb + 4, "Short"), NumPut(dy - by, c, cb + 6, "Short")
		, NumPut(dw, c, cb + 8, "Short"), NumPut(dh, c, cb + 10, "Short")
	Return, true
}
GetClientSize(hwnd, ByRef w, ByRef h)
{
    VarSetCapacity(rc, 16)
    DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
    w := NumGet(rc, 8, "int")
    h := NumGet(rc, 12, "int")
}

FileRead, Data, autotextkeeper.log
FileRead, Options, autotextkeeper.opt
StringSplit, Options, Options,|
InsertLineBreak:=Options0>=1? Options1 : 1
min_chars:=Options0>=2? Options2 : 20
width:=Options0>=3? Options3 : 300
height:=Options0>=4? Options4 : 380
Log=
(
1.2.0 First public release
1.2.1 Can now send multiple lines (multi-select and press enter or type multiple entries)
1.2.3 Made gui resizable via the 'anchor' (http://www.autohotkey.net/~polyethene/#anchor)
1.2.4 Option (default on) to insert line breaks when sending multiple log entries
1.2.5 Added Edit > Delete Selected
1.2.6 Options now saved (in separate file autotextkeeper.opt), option to set minimum length added
1.2.7 Scrolls to last entry
1.2.8 Gui size saved
)
controlwidth:=width>40? width-20 : 20
controlheight:=height>50? height-30 : 20
Gui, +Delimiter`n
Gui, Add, ListBox, gListBoxEvent vTextChoice w%controlwidth% h%controlheight% multi,%Data%
Gui, Add, Edit, w%controlwidth% vInputRow,
Gui, Add, Button, x+5 w0 gSend Default vSendButton, send
Menu, FileMenu, Add, &Pause keylogging,MenuFilePause
Menu, FileMenu, Add, &Linebreaks when sending multiple entries,MenuFileInsertLinebreak
Menu, FileMenu, Add, &Ignores lines shorter than...,MenuFileIgnore
Menu, FileMenu, Add,
Menu, FileMenu, Add, &Save	Ctrl+S,MenuFileSave
Menu, FileMenu, Add, &Exit, MenuFileExit
Menu, EditMenu, Add, &Delete Selected	Ctrl+D, MenuFileDelete
Menu, EditMenu, Add, Delete &Unselected	Ctrl+K, MenuFileKeep
Menu, EditMenu, Add, &Edit Entry	Ctrl+E, MenuFileEdit
Menu, HelpMenu, Add, &Help, MenuFileHelp
Menu, HelpMenu, Add, &Changelog, MenuChangeLog
Menu, MyMenuBar, Add, &File, :FileMenu
Menu, MyMenuBar, Add, &Edit, :EditMenu
Menu, MyMenuBar, Add, &Help, :HelpMenu
Gui, Menu, MyMenuBar
GuiControl, Focus, InputRow
Gui, +Resize
Gui, show,w%width%,AutotextKeeper 
Guicontrol, +altsubmit, TextChoice
ControlGet, LB, List,,ListBox1,AutotextKeeper
If InsertLinebreak
	Menu, FileMenu, Check, &Linebreaks when sending multiple entries
PostMessage, 0x115,7,,ListBox1,AutotextKeeper
GoSub, StartLog
return

MenuFileIgnore:
InputBox, Val,Minumum Lengte,,,150,100,,,,,%min_chare%
if Val is integer
{
	if Val>0
		min_chars:=Val
}
return

MenuFileInsertLinebreak:
	Menu, FileMenu, Check, &Linebreaks when sending multiple entries
InsertLinebreak:=!InsertLinebreak
return

GuiSize:
Anchor("TextChoice","wh")
Anchor("InputRow","wy")
return

MenuChangeLog:
MsgBox, %Log%
Return

MenuFilePause:
Menu, FileMenu, Check, &Pause keylogging
Pause
Menu, FileMenu, Uncheck, &Pause keylogging
Return

MenuFileExit:
MsgBox, 4, Save, Save log?
IfMsgBox, YES 
	GoSub, MenuFileSave
ExitApp

!f3::GoSub, Send3
!f2::GoSub, Send2
!f1::GoSub,Send1

Send6:
Button+=1
Send5:
Button+=1
Send4:
Button+=1
Send3:
Button+=1
Send2:
Button+=1
Send1:
Button+=1
Send0:
ControlGet, Try, List,,ListBox1,AutotextKeeper
if !ErrorLevel
	LB:=Try
Gui, Hide
Sleep, 300
StringSplit, Fields, LB, `n
multiselect=0
Loop, Parse, Button, `n%A_Space%%A_Tab%
{
	if A_LoopField is not integer
		Continue
	else if (A_LoopField>0 && A_LoopField<=Fields0)
	{
		Send, % (multiselect && InsertLinebreak? "{Enter}" : "") . Fields%A_LoopField%
		multiselect=1
	}
	else if (A_LoopField<=0 && -A_LoopField<=Fields0)
	{
		Actual:=Fields0+A_LoopField
		Send, % (multiselect && InsertLinebreak? "{Enter}" : "") . Fields%Actual%
		multiselect=1
	}
}
Button=""
return

Send:
SendPressed=1
ListBoxEvent:
if (A_GuiEvent="DoubleClick" || SendPressed)
{
	If SendPressed
	{
		GuiControlGet, InputRow
		Button:=InputRow
		SendPressed=0
		GoSub, Send0
	} else {
		Guicontrol, -altsubmit, TextChoice
		Gui, Submit
		Guicontrol, +altsubmit, TextChoice
		Sleep, 300
		Send, %TextChoice%
	}
} else {
	Gui, Submit, Nohide
	GuiControl,,InputRow,%TextChoice%
}
return

#s::
Gui, show
PostMessage, 0x115,7,,ListBox1,AutotextKeeper
GuiControl, Focus, InputRow
if (StrLen(Entries)>min_chars)
	GuiControl,,TextChoice,%Entries%
Entries=
return

GuiEscape:
ControlGet, LB, List,,ListBox1,AutotextKeeper
Gui, hide
return

StartLog:
Entries=
while 1 {
	Input, k, V M, {enter}{esc}{tab}
	if (ErrorLevel = "EndKey:Enter" and  StrLen(k)>min_chars)
	{
		;StringReplace,k,k,!,{!},All
		;Entries.=k . "`n"
		out=
		Loop,Parse,k
		{
			if (A_LoopField = "")
			{
				out := RTrim(out)
				StringGetPos,pos,out,%A_Space%,R1
				if !ErrorLevel
					StringLeft,out,out,% pos+1
				;StringTrimRight,out,out,1
			}
			else if (A_LoopField = "!")
				out.="{!}"
			else
				out.=A_LoopField
		}
		Entries.=out . "`n"
	}
}
return

#IfWinActive AutotextKeeper ahk_class AutoHotkeyGUI
^s::
MenuFileSave:
ControlGet, LB, List,,ListBox1,AutotextKeeper
FileDelete, autotextkeeper.log
FileAppend, % LB, autotextkeeper.log
FileDelete, autotextkeeper.opt
GetClientSize(WinExist("AutotextKeeper"), w, h)
FileAppend, % InsertLinebreak . "|" . min_chars . "|" . w . "|" . h, autotextkeeper.opt
MsgBox, Saved!
Return

MenuFileHelp:
MsgBox,
(
WELCOME TO TEXTKEEPER!
Textkeeper allows you to store, retreive, and edit everything you have typed. Press WIN-S to open the main window. Every time you press ENTER the text you just typed will be stored in the history. Only lines longer than %min_chars% characters will be stored. Delete, backspace, select-all, etc are also logged so don't worry about not making any mistakes.

You can press ALT-F1, ALT-F2, ALT-F3 to quickly send the first (earliest) 3 lines. You can also use the main window. Double click on a line to send it. Send multiple lines by ctrl-clicking those entries and pressing enter. You can also use the input box. Examples: '8' will send the 8th line, '0' to send the last line, '-4' to send the 5th to last line, "1 -2 9" will send multiple lines.

Edit > Edit (Ctrl-E) edits a single entry.  Use "{Enter}" to send a line break. You must use "{!}" to send "!" since the "!" is reserved for alt.
)
return

^e::
MenuFileEdit:
Gui, Submit, Nohide
ifInString, TextChoice, `n
	StringLeft, TextChoice, TextChoice, % InStr(TextChoice,"`n")
if TextChoice is not integer
	return
if TextChoice<=0
	return
TextChoiceM1:=TextChoice-1
ControlGet, LB, List,,ListBox1,AutotextKeeper
if TextChoiceM1=0
	start=1	
else {
	StringGetPos, start, LB, `n,L%TextChoiceM1%
	start+=1
}
StringGetPos, end, LB, `n,L%TextChoice%
if end=-1
	len:=StrLen(LB)-start+1
else
	len:=end-start+1
StringMid, extract, LB, %start%, %len%
InputBox, NewInput, % "Row " . TextChoice . ":",,,,100,,,,,%extract%
if !ErrorLevel
{
	if start!=1
		TextChoice:=SubStr(LB,1,start) . NewInput . SubStr(LB,start+len)
	else
		TextChoice:=NewInput . SubStr(LB,start+len)
	GuiControl,,TextChoice,% "`n" . TextChoice
}
return

^k::
MenuFileKeep:
Guicontrol, -altsubmit, TextChoice
Gui, Submit, Nohide
Guicontrol, +altsubmit, TextChoice
GuiControl,,TextChoice,% "`n" . TextChoice
return

^d::
MenuFileDelete:
Gui, Submit, Nohide
ControlGet, LB, List,,ListBox1,AutotextKeeper
StringSplit, Fields, TextChoice, `n
i=1
NewContents=
Loop, parse, LB, `n
{
	if (A_Index != Fields%i%)
		NewContents:=NewContents . "`n" . A_LoopField
	else
		i+=1
}
GuiControl,,TextChoice, %NewContents%
return
