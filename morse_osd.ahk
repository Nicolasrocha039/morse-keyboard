#Requires AutoHotkey v2.0

global MONO_FONT := "Consolas"

FormatForCard(val) {
    if val = "{Space}"
        return "Espaço"
    if val = "{Enter}"
        return "Enter"
    if val = "{Backspace}"
        return "Bksp"
    if val = "{Delete}"
        return "Del"
    if val = "{Tab}"
        return "Tab"
    if val = "{Escape}"
        return "Esc"
    if val = "{Up}"
        return "▲"
    if val = "{Down}"
        return "▼"
    if val = "{Left}"
        return "◀"
    if val = "{Right}"
        return "▶"
    if val = "{Home}"
        return "Home"
    if val = "{End}"
        return "End"
    if val = "{PgUp}"
        return "PgUp"
    if val = "{PgDn}"
        return "PgDn"
    if val = "{Insert}"
        return "Ins"
    if SubStr(val, 1, 1) = "^"
        return "Ctrl+" . Format("{:U}", SubStr(val, 2))
    if SubStr(val, 1, 1) = "{" && SubStr(val, -1) = "}" {
        return SubStr(val, 2, -1)
    }
    return val
}

CreateKeyCard(guiObj, keyName, x, y) {
    card := guiObj.AddText("x" . x . " y" . y . " w50 h50 +Background0x1c1c2e +Border", "")
    label := guiObj.AddText("x" . (x + 2) . " y" . (y + 2) . " w46 h15 Center +BackgroundTrans c0x9999bb", keyName)
    label.SetFont("s8 Bold", "Segoe UI")
    val := guiObj.AddText("x" . (x + 2) . " y" . (y + 18) . " w46 h30 Center +BackgroundTrans cWhite", "")
    val.SetFont("s10 Bold", "Consolas")
    return { card: card, label: label, val: val }
}

UpdateCard(key, valText, isActive) {
    global cards
    cardObj := cards[key]

    if isActive {
        cardObj.card.Opt("+Background0x1c1c2e")
        cardObj.label.Opt("c0x9999bb")
        cardObj.val.Opt("c0x00FFCC")
        cardObj.val.Text := valText
    } else {
        cardObj.card.Opt("+Background0x0b0b14")
        cardObj.label.Opt("c0x222233")
        cardObj.val.Opt("c0x222233")
        cardObj.val.Text := "-"
    }
    cardObj.card.Redraw()
    cardObj.label.Redraw()
    cardObj.val.Redraw()
}

UpdateKeyGuide(seq) {
    global traditionalMode
    keyMapping := Map("Q", "Q", "A", "A", "R", "R")
    if (traditionalMode) {
        cards["A"].label.Text := "."
        cards["R"].label.Text := "-"
    } else {
        cards["A"].label.Text := "A"
        cards["R"].label.Text := "R"
    }

    for k, cardKey in keyMapping {
        nextSeq := seq . k
        global morseMap
        val := morseMap.Has(nextSeq) ? morseMap[nextSeq] : "NOT_FOUND"

        if (val != "NOT_FOUND" && val != "") {
            formattedVal := FormatForCard(val)
            UpdateCard(cardKey, formattedVal, true)
        } else {
            ; Como o mapa de atalhos não fica mais na memória para consultar os prefixos,
            ; exibimos "-" (inativo) sempre que não for o atalho exato.
            UpdateCard(cardKey, "-", false)
        }
    }
    UpdateCard("Ent", "Conf", true)
}

global osdPosX := IniRead(A_ScriptDir . "\osd_pos.ini", "Position", "X", 10)
global osdPosY := IniRead(A_ScriptDir . "\osd_pos.ini", "Position", "Y", 10)
global osdFullW := IniRead(A_ScriptDir . "\osd_pos.ini", "Size", "FullW", 950)
global osdFullH := IniRead(A_ScriptDir . "\osd_pos.ini", "Size", "FullH", 550)
global osdMiniW := IniRead(A_ScriptDir . "\osd_pos.ini", "Size", "MiniW", 250)
global osdMiniH := IniRead(A_ScriptDir . "\osd_pos.ini", "Size", "MiniH", 195)
global osdOffW := IniRead(A_ScriptDir . "\osd_pos.ini", "Size", "OffW", "Auto")
global osdOffH := IniRead(A_ScriptDir . "\osd_pos.ini", "Size", "OffH", "Auto")

OnMessage(0x0201, WM_LBUTTONDOWN)
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global osd, osdMini
    if (hwnd == osd.Hwnd || hwnd == osdMini.Hwnd) {
        SendMessage(0xA1, 2, , , "ahk_id " hwnd)
    }
}

OnMessage(0x0232, WM_EXITSIZEMOVE)
WM_EXITSIZEMOVE(wParam, lParam, msg, hwnd) {
    global osd, osdMini, showMaps, morseActive
    global osdPosX, osdPosY, osdFullW, osdFullH, osdMiniW, osdMiniH, osdOffW, osdOffH

    if (hwnd == osd.Hwnd) {
        osd.GetPos(&X, &Y, &W, &H)
        IniWrite(X, A_ScriptDir . "\osd_pos.ini", "Position", "X")
        IniWrite(Y, A_ScriptDir . "\osd_pos.ini", "Position", "Y")
        osdPosX := X
        osdPosY := Y

        if showMaps {
            IniWrite(W, A_ScriptDir . "\osd_pos.ini", "Size", "FullW")
            IniWrite(H, A_ScriptDir . "\osd_pos.ini", "Size", "FullH")
            osdFullW := W
            osdFullH := H
        } else {
            IniWrite(W, A_ScriptDir . "\osd_pos.ini", "Size", "MiniW")
            IniWrite(H, A_ScriptDir . "\osd_pos.ini", "Size", "MiniH")
            osdMiniW := W
            osdMiniH := H
        }
        try osdMini.Move(X, Y)
    } else if (hwnd == osdMini.Hwnd) {
        osdMini.GetPos(&X, &Y, &W, &H)
        IniWrite(X, A_ScriptDir . "\osd_pos.ini", "Position", "X")
        IniWrite(Y, A_ScriptDir . "\osd_pos.ini", "Position", "Y")
        osdPosX := X
        osdPosY := Y

        IniWrite(W, A_ScriptDir . "\osd_pos.ini", "Size", "OffW")
        IniWrite(H, A_ScriptDir . "\osd_pos.ini", "Size", "OffH")
        osdOffW := W
        osdOffH := H

        try osd.Move(X, Y)
    }
}

; ── GUI pequena (OFF) ──
global osdMini := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize")
osdMini.Opt("+MinSize180x120")
osdMini.Show("Hide x" . osdPosX . " y" . osdPosY)
osdMini.BackColor := "0x12121e"
osdMini.MarginX := 10
osdMini.MarginY := 6

global miniStatus := osdMini.AddText("cWhite w200 h50 Center", "⌨ MORSE KB: OFF")
miniStatus.SetFont("s10 Bold", "Segoe UI")

global miniHint := osdMini.AddText("c0x555577 w200 h50 Center", "CapsLock para ativar")
miniHint.SetFont("s8", "Segoe UI")

osdMini.Show("NoActivate")
WinSetTransparent(220, osdMini)

osdMini.OnEvent("Size", osdMini_Size)
osdMini_Size(guiObj, MinMax, Width, Height) {
    if MinMax = -1
        return
    global miniStatus, miniHint
    try miniStatus.Opt("w" . (Width - 20))
    try miniHint.Opt("w" . (Width - 20))
}

; ── GUI completa (ON) ──
global osd := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize", "MorseGuideOSD")
osd.Opt("+MinSize720x450")
osd.Show("Hide x" . osdPosX . " y" . osdPosY)
osd.BackColor := "0x0b0b14"
osd.MarginX := 10
osd.MarginY := 10

osd.OnEvent("Size", osd_Size)
osd_Size(guiObj, MinMax, Width, Height) {
    if MinMax = -1
        return

    global statusText, seqText, hintText, sepLine, t1c1, t1c2, t1c3, showMaps

    try statusText.Opt("w" . (Width - 40))
    try seqText.Opt("w" . (Width - 400))
    try hintText.Move(Width - 300)
    try sepLine.Opt("w" . (Width - 40))

    if (showMaps) {
        availableW := Width - 140
        if (availableW > 100) {
            col1W := 280
            try t1c1.Move(140, , col1W, Height - 125)
            try t1c2.Move(140 + col1W, , availableW - col1W, Height - 125)
            try t1c1.Redraw()
            try t1c2.Redraw()
        }
    }
}

; Status e Informações da Sequência
global statusText := osd.AddText("x15 y10 w1260 h28 c0x00FFCC", "⌨ MORSE KEYBOARD: ATIVO")
statusText.SetFont("s14 Bold", "Segoe UI")

global seqLabel := osd.AddText("x15 y38 w80 h24 c0x8888aa", "Sequência:")
seqLabel.SetFont("s11", "Segoe UI")

global seqText := osd.AddText("x100 y34 w800 h65 c0x00d4ff", "aguardando...")
seqText.SetFont("s17 Bold", MONO_FONT)

global hintText := osd.AddText("x1000 y38 w260 h24 Right c0x666688", "1 / Enter para confirmar")
hintText.SetFont("s11 Italic", "Segoe UI")

global sepLine := osd.AddText("x15 y105 w1260 h1 +Background0x222233", "")

global cards := Map()
CreateKeyCards() {
    global osd, cards
    cards["Q"] := CreateKeyCard(osd, "Q", 15, 115)
    cards["A"] := CreateKeyCard(osd, "A", 70, 115)
    cards["R"] := CreateKeyCard(osd, "R", 15, 170)
    cards["Ent"] := CreateKeyCard(osd, "Enter", 70, 170)
}
CreateKeyCards()

; Colunas dinâmicas (2 colunas lado a lado)
LoadColumns() {
    global t1c1 := osd.AddText("x140 y115 w250 h280 c0xaaaacc -Wrap", "")
    t1c1.SetFont("s11 Bold", MONO_FONT)
    global t1c2 := osd.AddText("x420 y115 w255 h280 c0xaaaacc -Wrap", "")
    t1c2.SetFont("s11 Bold", MONO_FONT)
}
LoadColumns()

ToggleMaps() {
    global showMaps, osd, t1c1, t1c2
    showMaps := !showMaps

    if showMaps {
        t1c1.Visible := true
        t1c2.Visible := true
    } else {
        t1c1.Visible := false
        t1c2.Visible := false
    }
    UpdateOSD()
}

ToggleBrowserMode() {
    global USE_BROWSER_OSD, osd, osdMini
    USE_BROWSER_OSD := !USE_BROWSER_OSD
    if USE_BROWSER_OSD {
        osd.Hide()
        osdMini.Hide()
        ToolTip("Modo Navegador ATIVO ─ http://localhost:8766", A_ScreenWidth / 2 - 200, A_ScreenHeight / 2 - 30)
    } else {
        ToolTip("Modo OSD ATIVO", A_ScreenWidth / 2 - 100, A_ScreenHeight / 2 - 30)
    }
    SetTimer(() => ToolTip(), -1800)
    UpdateOSD()
}

UpdateOSD() {
    global morseActive, currentSequence, statusText, seqText, hintText, showMaps, visualBuffer
    global osd, osdMini, miniStatus, sepLine, USE_BROWSER_OSD

    displayText := ""
    if morseActive {
        if currentSequence != "" {
            if visualBuffer != "" {
                displayText := visualBuffer . " + [ " . FormatSequence(currentSequence) . " ]"
            } else {
                displayText := "[ " . FormatSequence(currentSequence) . " ]"
            }
        } else {
            if visualBuffer != "" {
                suggestion := GetAutocompleteSuggestion(visualBuffer)
                if (suggestion != "") {
                    displayText := "Acumulado: " . visualBuffer . "`n-> [Enter: " . suggestion . "]"
                } else {
                    displayText := "Acumulado: " . visualBuffer
                }
            } else {
                displayText := "aguardando..."
            }
        }
    }

    if USE_BROWSER_OSD {
        osd.Hide()
        osdMini.Hide()
    } else {
        if morseActive {
            osdMini.Hide()
            seqText.Text := displayText
            if currentSequence != "" {
                hintText.Text := GetPossibleMatches(currentSequence)
            } else {
                hintText.Text := "Confirmar: Enter | Mapas: d"
            }
            UpdateKeyGuide(currentSequence)

            if showMaps {
                global osdGeral1, osdGeral2, osdAdb1, osdAdb2, adbMode

                if adbMode {
                    t1c1.Text := osdAdb1
                    t1c2.Text := osdAdb2
                    statusText.Text := "⌨ MORSE KEYBOARD: ANDROID (ADB) ATIVO"
                } else {
                    t1c1.Text := osdGeral1
                    t1c2.Text := osdGeral2
                    statusText.Text := "⌨ MORSE KEYBOARD: WINDOWS ATIVO"
                }

                curW := Max(osdFullW, 750)
                curH := Max(osdFullH, 450)

                statusText.Opt("w" . (curW - 40))
                seqText.Opt("w" . (curW - 400))
                hintText.Move(curW - 300, , 280)
                hintText.Visible := true
                sepLine.Opt("w" . (curW - 40))
                try osd.Show("w" . curW . " h" . curH . " NoActivate")
                try WinSetTransparent(220, osd)
            } else {
                global adbMode
                statusText.Opt("w" . (osdMiniW - 30))
                if adbMode {
                    statusText.Text := "⌨ MORSE: ANDROID"
                } else {
                    statusText.Text := "⌨ MORSE: WINDOWS"
                }
                seqText.Opt("w" . (osdMiniW - 110))
                hintText.Visible := false
                sepLine.Opt("w" . (osdMiniW - 30))
                try osd.Show("w" . osdMiniW . " h" . osdMiniH . " NoActivate")
                try WinSetTransparent(220, osd)
            }
            statusText.Redraw()
            seqText.Redraw()
            sepLine.Redraw()
        } else {
            osd.Hide()
            miniStatus.Text := "⌨ MORSE KB: OFF"
            if (osdOffW = "Auto" || osdOffH = "Auto") {
                try osdMini.Show("NoActivate")
            } else {
                try osdMini.Show("w" . osdOffW . " h" . osdOffH . " NoActivate")
            }
        }
    }
    SendStateToPython()
}