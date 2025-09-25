#Requires AutoHotkey v2.0

#Include XInput.ahk
XInput_Init()  ; Load XInput (if available)

; ============================================================
; Joystick Logger (AHK v2)
; - Listens to controller input
; - On 'Y' button press: capture/log left stick (X/Y) position
; - Always shows: current left stick + last Y-press position
; ------------------------------------------------------------
; Notes
; - Uses XInput for global input (works without script focus).
; - Targets controller index 0 (first controller). Change if needed.
; - Left stick raw range is -32768..+32767. This script shows:
;     - normalized (-1..+1) and a 0..100 scale (50 = center).
; ============================================================

; -------------------------
; Configuration
; -------------------------
ControllerIndex := 0        ; XInput user index (0..3)
PollIntervalMs := 16        ; GUI refresh rate (~60 FPS)

; Optionally, write a text log on each Y press. Set to '' to disable.
LogFile := '.\\joystick_log.txt'               ; e.g. A_ScriptDir "\\joystick_log.txt" to enable

; -------------------------
; State
; -------------------------
LastY_X := ''               ; Last captured X at Y press (0..100)
LastY_Y := ''               ; Last captured Y at Y press (0..100)
LastY_Timestamp := ''       ; Timestamp of last Y press (yyyyMMddHHmmss)
_prevYPressed := false      ; Edge detection for Y button

; -------------------------
; GUI Setup
; -------------------------
appGui := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox", "Joystick Logger")
appGui.SetFont("s10", "Segoe UI")

appGui.AddText("w420 Section", "Current Left Stick (X/Y)")
txtCurrent := appGui.AddText("w420 vtxtCurrent", "X: --  Y: --  (center=50)")

appGui.AddText("xs w420", "Last 'Y' Press (X/Y)")
txtLast := appGui.AddText("w420 vtxtLast", "X: --  Y: --  at --")

appGui.AddText("xs w420 cGray", "Tip: Change ControllerIndex at top if needed.")

appGui.Show("AutoSize")

; Exit when the GUI is closed
appGui.OnEvent("Close", (*) => ExitApp())

; -------------------------
; Hotkeys
; -------------------------
; Provide a quick exit hotkey
Hotkey("Esc", (*) => ExitApp())

; -------------------------
; Timers
; -------------------------
; Periodically poll the controller and update the GUI.
SetTimer(TickPoll, PollIntervalMs)

return  ; End of auto-execute section in AHK v2

; ============================================================
; Functions
; ============================================================

TickPoll(*) {
	; Poll controller state via XInput and update GUI.
	global ControllerIndex, txtCurrent, txtLast, LastY_X, LastY_Y, LastY_Timestamp, LogFile, _prevYPressed, XINPUT_GAMEPAD_Y

	state := 0
	try {
		state := XInput_GetState(ControllerIndex)
	} catch {
		state := 0
	}

	if (state = 0) {
		txtCurrent.Text := "X: --  Y: --  (controller not detected)"
		_prevYPressed := false
		return
	}

	; Left stick raw values from XInput: -32768..+32767
	lx := state.sThumbLX
	ly := state.sThumbLY

	; Normalize to -1..+1 accounting for asymmetry of signed range
	xNorm := NormalizeThumb(lx)
	yNorm := NormalizeThumb(ly)

	; Map to 0..100 (50 = center)
	x01 := Round((xNorm + 1) * 50)
	y01 := Round((yNorm + 1) * 50)

	txtCurrent.Text := Format("X: {1:03d}  Y: {2:03d}  |  norm X: {3:.2f}  norm Y: {4:.2f}", x01, y01, xNorm, yNorm)

	; Detect Y button press (rising edge)
	yPressed := (state.wButtons & XINPUT_GAMEPAD_X) != 0
	if (yPressed && !_prevYPressed) {
		LastY_X := x01
		LastY_Y := y01
		LastY_Timestamp := A_Now
		humanTime := FormatTime(LastY_Timestamp, "yyyy-MM-dd HH:mm:ss")
		txtLast.Text := Format("X: {1:03d}  Y: {2:03d}  at {3}", LastY_X, LastY_Y, humanTime)
		if (LogFile) {
			FileAppend(Format("{1}, X={2}, Y={3}`n", humanTime, LastY_X, LastY_Y), LogFile, "UTF-8")
		}
		; Optional cue
		; SoundBeep(1500, 30)
	}
	_prevYPressed := yPressed
}

NormalizeThumb(val) {
	; Normalize XInput thumb value to -1..+1 with correct denominator.
	if (val >= 0)
		return Round(val / 32767, 4)
	else
		return Round(val / 32768, 4)
}

; (No utility wrappers needed; using built-in FormatTime directly.)


