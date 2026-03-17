#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook True

GroupAdd("RAGE", "ahk_exe ragemp_v.exe")
GroupAdd("RAGE", "ahk_exe GTA5.exe")

class MemoUI {
    __New() {
        this.iniFile := A_ScriptDir "\memo_settings.ini"
        this.mapPath := A_MyDocuments "\ArmyHelper_Map.png"

        this.prefW := 1280
        this.prefH := 980
        this.minW  := 920
        this.minH  := 740

        this.gui := 0
        this.overlay := 0
        this.mapGui := 0
        this.alertGui := 0
        this.phrasePickerGui := 0
        this.shown := false
        this.dpi := A_ScreenDPI
        this.opacity := 245
        this.winPos := {x:0, y:0, w:0, h:0}

        this.savedNotes := ""
        this.reportTag := "[БОО]"
        this.reportName := "Рядовой Фамилия"
        this.patrolNum := "1"
        this.patrolCall := "Стражи"
        this.patrolCrew := "Фамилия, Фамилия"
        this.menuKey := "F2"
        this.currentTheme := "Штаб (Тёмная)"
        this.autoSend := 0
        this.recruitMode := 0

        this.timerEnd := 0
        this.lastCheckedTime := ""

        this.stratPoints := ["ЗМХ", "ВС/ГСМО", "Объект-7", "МС", "ЦМС", "РЛС Орбита"]

        this.ctrl := {}
        this.lv := {}
        this.rowColors := Map()

        this._wmNotify := this.WM_NOTIFY.Bind(this)
        this._wmDpi := this.WM_DPICHANGED.Bind(this)
        this._wmWheel := this.WM_MOUSEWHEEL.Bind(this)
        this._updateTimerFn := this.UpdateTimer.Bind(this)

        this.fnCondOpen := (*) => !this.shown
        this.fnCondClose := (*) => this.shown
        this.fnCondGame := (*) => WinActive("ahk_group RAGE")

        this.quickSlots := []
        this.quickHotkeys := Map()

        this.LoadSettings()
        this.ApplyThemePalette(this.currentTheme)

        this.dataKpp1 := this.GetKpp1Data()
        this.dataKpp2 := this.GetKpp2Data()
        this.dataUK := this.GetUKFullData()
        this.dataPK := this.GetPKFullData()
        this.dataFZ86 := this.GetFZ86FullData()
        this.dataFZ52 := this.GetFZ52FullData()
        this.dataFZ := this.dataFZ86
        this.dataPhrases := this.GetPhrasesData()
        this.dataTenCodes := this.GetTenCodesData()

        this.InitQuickPhraseSlots()

        this.Create()
        this.CreateOverlay()
        this.UpdateHotkey(this.menuKey)
        this.RegisterQuickPhraseHotkeys()

        SetTimer(this.CheckSchedule.Bind(this), 5000)
    }

    InitQuickPhraseSlots() {
        loop 5 {
            idx := A_Index
            slot := {
                key: "",
                listIndex: 1,
                customText: ""
            }

            try slot.key := IniRead(this.iniFile, "QuickPhrase" idx, "Key", "")
            try slot.listIndex := Integer(IniRead(this.iniFile, "QuickPhrase" idx, "ListIndex", 1))
            try slot.customText := IniRead(this.iniFile, "QuickPhrase" idx, "CustomText", "")

            if (slot.listIndex < 1 || slot.listIndex > this.dataPhrases.Length)
                slot.listIndex := 1

            this.quickSlots.Push(slot)
        }
    }

    ApplyThemePalette(themeName) {
        switch themeName {
            case "Полигон (Камуфляж)":
                this.C_GUI_BG       := "161A15"
                this.C_SURFACE      := "1E241C"
                this.C_SURFACE_2    := "252D23"
                this.C_BORDER       := "33402F"
                this.C_HEADER_BG    := "20271E"
                this.C_SEARCH_BG    := "121610"
                this.C_INPUT_BG     := "EEF2EA"
                this.C_BTN_BG       := "2B3628"
                this.C_BTN_HOVER    := "364332"
                this.C_TXT_MAIN     := "E4EBDD"
                this.C_TXT_MUTED    := "A5B29E"
                this.C_TXT_ACCENT   := "D7B24A"
                this.C_TXT_WARN     := "FFCB45"
                this.C_TXT_ERR      := "FF7A7A"
                this.C_SUCCESS      := "7FB069"

                this.BGR_DEF        := 0x001E241C
                this.BGR_GREEN      := 0x002C442B
                this.BGR_YELLOW     := 0x003A4A2D
                this.BGR_RED        := 0x00443333

            case "ВМФ (Тёмно-синяя)":
                this.C_GUI_BG       := "0E1420"
                this.C_SURFACE      := "141C2B"
                this.C_SURFACE_2    := "1A2436"
                this.C_BORDER       := "28354D"
                this.C_HEADER_BG    := "131B29"
                this.C_SEARCH_BG    := "0A1019"
                this.C_INPUT_BG     := "EEF4FF"
                this.C_BTN_BG       := "1C2940"
                this.C_BTN_HOVER    := "243552"
                this.C_TXT_MAIN     := "E5ECF7"
                this.C_TXT_MUTED    := "9FB1CC"
                this.C_TXT_ACCENT   := "67A4FF"
                this.C_TXT_WARN     := "FFD166"
                this.C_TXT_ERR      := "FF7373"
                this.C_SUCCESS      := "58C27D"

                this.BGR_DEF        := 0x00141C2B
                this.BGR_GREEN      := 0x001B3B2A
                this.BGR_YELLOW     := 0x00253A54
                this.BGR_RED        := 0x00402828

            default:
                this.C_GUI_BG       := "111315"
                this.C_SURFACE      := "171A1F"
                this.C_SURFACE_2    := "1D2127"
                this.C_BORDER       := "2B313A"
                this.C_HEADER_BG    := "171B20"
                this.C_SEARCH_BG    := "0D1014"
                this.C_INPUT_BG     := "F2F5F9"
                this.C_BTN_BG       := "21262D"
                this.C_BTN_HOVER    := "2A3038"
                this.C_TXT_MAIN     := "E8EDF3"
                this.C_TXT_MUTED    := "A2ACB8"
                this.C_TXT_ACCENT   := "62D26F"
                this.C_TXT_WARN     := "FFD166"
                this.C_TXT_ERR      := "FF7B7B"
                this.C_SUCCESS      := "6FD08C"

                this.BGR_DEF        := 0x00171A1F
                this.BGR_GREEN      := 0x00213328
                this.BGR_YELLOW     := 0x002A3340
                this.BGR_RED        := 0x00402A2A
        }

        this.BGR_TEXT_W := 0x00E8EDF3
    }

    ChangeTheme(*) {
        newT := this.ctrl.ddTheme.Text
        if (newT = this.currentTheme)
            return

        this.currentTheme := newT
        this.SaveSettings()

        if this.gui
            this.gui.GetPos(&x, &y, &w, &h)
        else
            x := 0, y := 0, w := this.prefW, h := this.prefH

        this.winPos := {x:x, y:y, w:w, h:h}

        try this.gui.Destroy()
        this.gui := 0
        this.ctrl := {}
        this.lv := {}
        this.rowColors := Map()

        this.ApplyThemePalette(this.currentTheme)
        this.Create()
        this.Show()
    }

    GetThemeIndex() {
        switch this.currentTheme {
            case "Полигон (Камуфляж)": return 2
            case "ВМФ (Тёмно-синяя)": return 3
            default: return 1
        }
    }

    GetMSKTime() {
        return DateAdd(A_NowUTC, 3, "Hours")
    }

    CheckSchedule() {
        fullMSK := this.GetMSKTime()
        currTime := FormatTime(fullMSK, "HH:mm")

        if (currTime = this.lastCheckedTime)
            return
        this.lastCheckedTime := currTime

        if (currTime = "15:00")
            this.ShowAlert("Внимание", "Начался обед. Выезд с ВЧ только со звания Старший Сержант и выше.")
        else if (currTime = "15:55")
            this.ShowAlert("Обед заканчивается", "До конца обеда осталось 5 минут. Всем вернуться на ВЧ.")
        else if (currTime = "16:00")
            this.ShowAlert("Конец обеда", "Обеденный перерыв окончен. Заступить на посты.")

        currWDay := Integer(FormatTime(fullMSK, "WDay"))
        schedule := Map(
            1, ["14:30", "19:00"],
            2, ["16:00", "20:30"],
            3, ["16:30", "21:00"],
            4, ["17:00", "21:30"],
            5, ["17:30", "22:00"],
            6, ["18:00", "22:30"],
            7, ["14:00", "18:30"]
        )

        for draftTime in schedule[currWDay] {
            if (currTime = draftTime)
                this.ShowAlert("Призыв в армию", "Начался призыв. Всем свободным на набор.")

            draftStamp := SubStr(fullMSK, 1, 8) . StrReplace(draftTime, ":", "") . "00"
            warnTimeMSK := DateAdd(draftStamp, -10, "Minutes")
            warnTime := FormatTime(warnTimeMSK, "HH:mm")

            if (currTime = warnTime)
                this.ShowAlert("Скоро призыв", "Через 10 минут начнётся призыв в Армию (" draftTime ").")
        }
    }

    ShowAlert(title, msg) {
        if this.alertGui {
            try this.alertGui.Destroy()
            this.alertGui := 0
        }

        SoundBeep(650, 180)
        Sleep 100
        SoundBeep(820, 220)

        this.alertGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border +E0x80000", "ArmyPopup")
        this.alertGui.BackColor := this.C_GUI_BG

        this.alertGui.AddText("x0 y0 w640 h8 Background" this.C_TXT_WARN)

        this.alertGui.SetFont("s16 Bold c" this.C_TXT_MAIN, "Segoe UI")
        this.alertGui.AddText("x20 y24 w600 h32 Center BackgroundTrans", title)

        this.alertGui.SetFont("s11 c" this.C_TXT_MAIN, "Segoe UI")
        this.alertGui.AddText("x20 y68 w600 h54 Center BackgroundTrans", msg)

        this.alertGui.SetFont("s9 c" this.C_TXT_MUTED, "Segoe UI")
        this.alertGui.AddText("x20 y128 w600 h20 Center BackgroundTrans", "Окно закроется автоматически")

        wa := this.GetPrimaryWorkArea()
        x := wa.L + ((wa.R - wa.L) - 640) // 2
        y := wa.T + ((wa.B - wa.T) - 160) // 2

        this.alertGui.Show("x" x " y" y " w640 h160 NoActivate")
        try WinSetTransparent(245, "ahk_id " this.alertGui.Hwnd)

        SetTimer((*) => this.SafeDestroyAlert(), -5000)
    }

    SafeDestroyAlert() {
        if this.alertGui {
            try this.alertGui.Destroy()
            this.alertGui := 0
        }
    }

    Toggle(*) => (this.shown ? this.Hide() : this.Show())

    Destroy(*) {
        try this.SaveSettings()
        SetTimer(this._updateTimerFn, 0)

        this.UnregisterQuickPhraseHotkeys()

        if this.gui
            try this.gui.Destroy()
        if this.overlay
            try this.overlay.Destroy()
        if this.mapGui
            try this.mapGui.Destroy()
        if this.alertGui
            try this.alertGui.Destroy()
        if this.phrasePickerGui
            try this.phrasePickerGui.Destroy()

        this.gui := 0
        this.overlay := 0
        this.mapGui := 0
        this.alertGui := 0
        this.phrasePickerGui := 0
    }

    Show(*) {
        if !this.gui
            this.Create()

        if this.overlay
            try this.overlay.Hide()

        isValidSize := IsObject(this.winPos) && this.winPos.w >= this.minW && this.winPos.h >= this.minH
        if isValidSize {
            x := this.winPos.x, y := this.winPos.y
            w := this.winPos.w, h := this.winPos.h
        } else {
            wa := this.GetPrimaryWorkArea()
            waW := wa.R - wa.L
            waH := wa.B - wa.T
            w := this.FitSize(this.prefW, this.minW, waW - 40)
            h := this.FitSize(this.prefH, this.minH, waH - 40)
            x := wa.L + (waW - w) // 2
            y := wa.T + (waH - h) // 2
        }

        this.gui.Show("x" x " y" y " w" w " h" h " NoActivate")
        try WinActivate("ahk_id " this.gui.Hwnd)
        try WinSetTransparent(this.opacity, "ahk_id " this.gui.Hwnd)

        this.shown := true

        try this.dpi := DllCall("User32\GetDpiForWindow", "ptr", this.gui.Hwnd, "uint")
        catch
            this.dpi := A_ScreenDPI

        this.gui.GetClientPos(, , &cw, &ch)
        this.Layout(cw, ch)
        this.OnTabChange()

        try this.ctrl.SearchEdit.Focus()
        try WinRedraw("ahk_id " this.gui.Hwnd)
    }

    Hide(*) {
        this.SaveSettings()
        if this.gui
            try this.gui.Hide()

        this.shown := false

        if (this.timerEnd > A_TickCount)
            this.ShowOverlay()
        else if this.overlay
            try this.overlay.Hide()

        try WinActivate("ahk_group RAGE")
    }

    Create() {
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize +E0x80000")
        this.gui.BackColor := this.C_GUI_BG

        this.gui.OnEvent("Escape", (*) => this.Hide())
        this.gui.OnEvent("Close", (*) => (this.Destroy(), ExitApp()))
        this.gui.OnEvent("Size", this.OnSize.Bind(this))

        this.ctrl.borderT := this.AddText("Background" this.C_BORDER, "")
        this.ctrl.borderB := this.AddText("Background" this.C_BORDER, "")
        this.ctrl.borderL := this.AddText("Background" this.C_BORDER, "")
        this.ctrl.borderR := this.AddText("Background" this.C_BORDER, "")

        this.SetFont("s10 w600 c" this.C_TXT_MAIN)
        this.ctrl.hBg := this.AddText("Background" this.C_HEADER_BG, "")
        this.SetFont("s14 Bold c" this.C_TXT_MAIN)
        this.ctrl.hTitle := this.AddText("BackgroundTrans +0x200", "ARMY HELPER • ПАМЯТКА v4.8 [" this.menuKey "]")
        this.ctrl.hBg.OnEvent("Click", this.Drag.Bind(this))
        this.ctrl.hTitle.OnEvent("Click", this.Drag.Bind(this))

        this.SetFont("s10 c" this.C_TXT_MUTED)
        this.ctrl.SearchIcon := this.AddText("BackgroundTrans +0x200 c" this.C_TXT_MUTED, "ПОИСК")
        this.ctrl.SearchEdit := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack -E0x200 +Border")
        this.ctrl.SearchEdit.OnEvent("Change", (*) => this.ApplyFilter(this.ctrl.SearchEdit.Value))

        this.SetFont("s13 Bold c" this.C_TXT_ERR)
        this.ctrl.hClose := this.AddText("Center Background" this.C_SURFACE_2 " +0x200", "✕")
        this.ctrl.hClose.OnEvent("Click", (*) => (this.Destroy(), ExitApp()))

        this.SetFont("s11 c" this.C_TXT_MAIN)
        this.ctrl.Tabs := this.gui.AddTab3(
            "x0 y0 w0 h0 -Theme Background" this.C_SURFACE,
            ["   КПП   ", "   Кодексы   ", "   Тен-коды   ", "   ФЗ   ", "   Служба   ", "   Патруль СВО   ", "   Строй   ", "   Расписание   ", "   Настройки   ", "   Блокнот   "]
        )
        this.ctrl.Tabs.OnEvent("Change", this.OnTabChange.Bind(this))

        ; TAB 1
        this.ctrl.Tabs.UseTab(1)
        this.SetFont("s10 c" this.C_TXT_MAIN)
        this.ctrl.infoCard := this.AddText("Background" this.C_SURFACE " +0x200 c" this.C_TXT_MUTED, "  ℹ Двойной клик по строке — скопировать или отправить.")
        this.SetFont("s11 Bold c" this.C_TXT_WARN)
        this.ctrl.idAlert := this.AddText("Center Background" this.C_SURFACE_2 " c" this.C_TXT_WARN " +0x200 +Border", "ПЕРЕД ПРОПУСКОМ: СВЕРЬ УДОСТОВЕРЕНИЕ ИЛИ ЖЕТОН")
        this.SetFont("s15 Bold c" this.C_TXT_ACCENT)
        this.ctrl.k1Hdr := this.AddText("+BackgroundTrans", "КПП №1 — Основной проход")
        this.SetFont("s11 c" this.C_TXT_MUTED)
        this.ctrl.k1Sub := this.AddText("+BackgroundTrans", "Допуск без пропуска:")
        this.SetFont("s12 c" this.C_TXT_MAIN)
        this.lv.lv1 := this.AddLV("-Multi -Hdr -Grid Background" this.C_SURFACE " c" this.C_TXT_MAIN, ["K", "V"])
        this.SetupLV(this.lv.lv1)
        this.lv.lv1.OnEvent("DoubleClick", this.OnLvClick.Bind(this))
        this.SetFont("s10 Bold c" this.C_TXT_WARN)
        this.ctrl.k1Warn := this.AddText("+BackgroundTrans +0x200", "Медики: только по вызову, по требованию обязаны покинуть территорию.")
        this.SetFont("s10 c" this.C_TXT_MUTED)
        this.ctrl.k1Note := this.AddText("+BackgroundTrans +0x200", "Остальные лица — только по установленному пропускному режиму.")
        this.SetFont("s15 Bold c" this.C_TXT_ERR)
        this.ctrl.k2Hdr := this.AddText("+BackgroundTrans", "КПП №2 — Режимный въезд")
        this.SetFont("s11 c" this.C_TXT_MUTED)
        this.ctrl.k2Sub := this.AddText("+BackgroundTrans", "Разрешён въезд только для:")
        this.SetFont("s12 c" this.C_TXT_MAIN)
        this.lv.lv2 := this.AddLV("-Multi -Hdr -Grid Background" this.C_SURFACE " c" this.C_TXT_MAIN, ["K", "V"])
        this.SetupLV(this.lv.lv2)
        this.lv.lv2.OnEvent("DoubleClick", this.OnLvClick.Bind(this))

        ; TAB 2
        this.ctrl.Tabs.UseTab(2)
        this.SetFont("s10 cBlack")
        this.ctrl.cbCodes := this.gui.AddDropDownList("Choose1 Background" this.C_INPUT_BG " cBlack", ["Уголовный Кодекс (УК)", "Процессуальный Кодекс (ПК)"])
        this.ctrl.cbCodes.OnEvent("Change", this.OnCodeLawChange.Bind(this))

        this.lv.codes := this.AddLV("-Multi -Hdr -Grid Background" this.C_SURFACE " c" this.C_TXT_MAIN " +0x4000000", ["Статья", "Название"])
        this.SetupLV(this.lv.codes)
        this.lv.codes.OnEvent("Click", this.OnCodeClick.Bind(this))
        this.lv.codes.OnEvent("DoubleClick", this.OnLvClick.Bind(this))

        this.SetFont("s11 c" this.C_TXT_MAIN)
        this.ctrl.codeFullText := this.gui.AddEdit("Multi VScroll ReadOnly Background" this.C_SURFACE " c" this.C_TXT_MAIN " -E0x200 +Border")
        this.ctrl.codeFullText.Value := "Выберите статью в списке сверху, чтобы прочитать её полный текст здесь..."

        ; TAB 3
        this.ctrl.Tabs.UseTab(3)
        this.lv.tenCodes := this.AddLV("-Multi -Hdr -Grid Background" this.C_SURFACE " c" this.C_TXT_MAIN, ["Код", "Расшифровка"])
        this.SetupLV(this.lv.tenCodes)
        this.lv.tenCodes.OnEvent("DoubleClick", this.OnLvClick.Bind(this))

        ; TAB 4
        this.ctrl.Tabs.UseTab(4)
        this.SetFont("s10 cBlack")
        this.ctrl.cbFzLaw := this.gui.AddDropDownList("Choose1 Background" this.C_INPUT_BG " cBlack", ["ФЗ-86", "ФЗ-52 Об Обороне"])
        this.ctrl.cbFzLaw.OnEvent("Change", this.OnFzLawChange.Bind(this))

        this.SetFont("s12 c" this.C_TXT_MAIN)
        this.lv.fz := this.AddLV("-Multi -Hdr -Grid Background" this.C_SURFACE " c" this.C_TXT_MAIN " +0x4000000", ["Статья", "Название"])
        this.SetupLV(this.lv.fz)
        this.lv.fz.OnEvent("Click", this.OnFzClick.Bind(this))
        this.lv.fz.OnEvent("DoubleClick", this.OnLvClick.Bind(this))

        this.SetFont("s11 c" this.C_TXT_MAIN)
        this.ctrl.fzFullText := this.gui.AddEdit("Multi VScroll ReadOnly Background" this.C_SURFACE " c" this.C_TXT_MAIN " -E0x200 +Border")
        this.ctrl.fzFullText.Value := "Выберите статью в списке сверху, чтобы прочитать её полный текст здесь..."
        ; TAB 5
        this.ctrl.Tabs.UseTab(5)
        this.SetFont("s14 Bold c" this.C_TXT_MAIN)
        this.ctrl.srvRepHdr := this.AddText("+BackgroundTrans", "Генератор доклада")

        this.SetFont("s11 c" this.C_TXT_MAIN)
        this.ctrl.lblTag := this.AddText("+BackgroundTrans +0x200", "Тэг:")
        this.ctrl.editTag := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border", this.reportTag)
        this.ctrl.lblName := this.AddText("+BackgroundTrans +0x200", "Звание/Имя:")
        this.ctrl.editName := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border", this.reportName)

        this.SetFont("s10 cBlack")
        this.ctrl.ddPost := this.gui.AddDropDownList("Choose1 Background" this.C_INPUT_BG " cBlack", ["КПП 1", "КПП 2", "Штаб", "ГС"])
        this.ctrl.ddState := this.gui.AddDropDownList("Choose1 Background" this.C_INPUT_BG " cBlack", ["Принял", "20 минут", "40 минут", "60 минут", "80 минут", "100 минут", "120 минут", "сдал"])
        this.ctrl.ddCode := this.gui.AddDropDownList("Choose1 Background" this.C_INPUT_BG " cBlack", ["Код-1", "Код-2", "Код-3"])
        this.ctrl.ddCount := this.gui.AddDropDownList("Choose1 Background" this.C_INPUT_BG " cBlack", ["Состав: 1", "Состав: 2", "Состав: 3", "Состав: 4", "Состав: 5"])

        this.SetFont("s10 Bold c" this.C_TXT_MAIN)
        this.ctrl.btnCopyRep := this.gui.AddButton("w250 h40", "Скопировать / Отправить")
        this.ctrl.btnCopyRep.OnEvent("Click", this.CopyReport.Bind(this))

        this.ctrl.srvLine1 := this.AddText("Background" this.C_BORDER, "")

        this.SetFont("s14 Bold c" this.C_TXT_MAIN)
        this.ctrl.srvTimeHdr := this.AddText("+BackgroundTrans", "Таймер напоминания")
        this.SetFont("s11 c" this.C_TXT_MUTED)
        this.ctrl.srvTimeDesc := this.AddText("+BackgroundTrans", "Введите нужное количество минут и нажмите запуск.")

        this.ctrl.editTimerMins := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border Center Number", "20")
        this.ctrl.btnTimerCustom := this.gui.AddButton("w150 h40", "Запустить")
        this.ctrl.btnTimerCustom.OnEvent("Click", (*) => this.StartTimer(this.ctrl.editTimerMins.Value))
        this.ctrl.btnStopTimer := this.gui.AddButton("w100 h40", "Стоп")
        this.ctrl.btnStopTimer.OnEvent("Click", (*) => this.StopTimer())

        this.SetFont("s16 Bold c" this.C_TXT_ACCENT)
        this.ctrl.lblTimer := this.AddText("+BackgroundTrans", "00:00")

        this.ctrl.srvLine2 := this.AddText("Background" this.C_BORDER, "")

        this.SetFont("s14 Bold c" this.C_TXT_MAIN)
        this.ctrl.srvPhrHdr := this.AddText("+BackgroundTrans", "Быстрые фразы")
        this.SetFont("s12 c" this.C_TXT_MAIN)
        this.lv.phrases := this.AddLV("-Multi -Hdr -Grid Background" this.C_SURFACE " c" this.C_TXT_MAIN " +0x4000000", ["Фраза"])
        this.SetupLV(this.lv.phrases)
        this.lv.phrases.OnEvent("DoubleClick", this.OnPhraseClick.Bind(this))

        ; TAB 6
        this.ctrl.Tabs.UseTab(6)
        this.SetFont("s14 Bold c" this.C_TXT_MAIN)
        this.ctrl.svoHdr := this.AddText("+BackgroundTrans", "Патруль стратегических объектов")

        this.SetFont("s11 c" this.C_TXT_MAIN)
        this.ctrl.svoLblNum := this.AddText("+BackgroundTrans +0x200", "№ Патруля:")
        this.ctrl.svoNum := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border Center Number", this.patrolNum)
        this.ctrl.svoLblCall := this.AddText("+BackgroundTrans +0x200", "Позывной:")
        this.ctrl.svoCall := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border Center", this.patrolCall)
        this.ctrl.svoLblCrew := this.AddText("+BackgroundTrans +0x200", "Состав:")
        this.ctrl.svoCrew := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border", this.patrolCrew)

        this.ctrl.svoLine := this.AddText("Background" this.C_BORDER, "")

        this.SetFont("s14 Bold c" this.C_TXT_ACCENT)
        this.ctrl.svoHdrLoc := this.AddText("+BackgroundTrans", "Текущий объект")
        this.SetFont("s11 cBlack")
        this.ctrl.ddSvoLoc := this.gui.AddDropDownList("Choose1 Background" this.C_INPUT_BG " cBlack", this.stratPoints)

        this.SetFont("s10 Bold c" this.C_TXT_MAIN)
        this.ctrl.btnSvoStart := this.gui.AddButton("h40", "Начать патруль")
        this.ctrl.btnSvoStart.OnEvent("Click", this.SvoAction.Bind(this, "start"))
        this.ctrl.btnSvoWatch := this.gui.AddButton("h40", "Начать наблюдение")
        this.ctrl.btnSvoWatch.OnEvent("Click", this.SvoAction.Bind(this, "watch"))
        this.ctrl.btnSvoCont := this.gui.AddButton("h40", "Всё спокойно")
        this.ctrl.btnSvoCont.OnEvent("Click", this.SvoAction.Bind(this, "cont"))
        this.ctrl.btnSvoMove := this.gui.AddButton("h40", "Следующий объект")
        this.ctrl.btnSvoMove.OnEvent("Click", this.SvoAction.Bind(this, "move"))
        this.ctrl.btnSvoEnd := this.gui.AddButton("h40", "Завершить патруль")
        this.ctrl.btnSvoEnd.OnEvent("Click", this.SvoAction.Bind(this, "end"))

        this.ctrl.btnShowMap := this.gui.AddButton("h40", "Открыть карту")
        this.ctrl.btnShowMap.OnEvent("Click", this.ShowMap.Bind(this))
        this.ctrl.btnChangeMap := this.gui.AddButton("h40", "Изменить карту")
        this.ctrl.btnChangeMap.OnEvent("Click", this.ChangeMap.Bind(this))

        this.SetFont("s14 Bold c" this.C_TXT_WARN)
        this.ctrl.svoHdrTime := this.AddText("+BackgroundTrans", "Таймер наблюдения")
        this.SetFont("s10 c" this.C_TXT_MUTED)
        this.ctrl.svoTimeDesc := this.AddText("+BackgroundTrans", "Укажите минуты и нажмите запуск:")

        this.SetFont("s14")
        this.ctrl.svoTimerMins := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border Center Number", "10")
        this.SetFont("s10 Bold c" this.C_TXT_MAIN)
        this.ctrl.btnSvoTimer := this.gui.AddButton("h40", "Запустить таймер")
        this.ctrl.btnSvoTimer.OnEvent("Click", (*) => this.StartTimer(this.ctrl.svoTimerMins.Value))

        ; TAB 7
        this.ctrl.Tabs.UseTab(7)
        this.SetFont("s14 Bold c" this.C_TXT_MAIN)
        this.ctrl.formHdr := this.AddText("Center +BackgroundTrans", "СХЕМА ВЕЧЕРНЕЙ ПОВЕРКИ (21:00)")

        C_CCO := "FFD700", C_VP := "B22222", C_BOO := "1E90FF", C_VK := "FFA500", C_KMB := "32CD32"
        this.ctrl.formBoxes := []
        this.AddFormationBox(C_CCO, "ССО")
        this.AddFormationBox(C_VP, "ВП")
        this.AddFormationBox(C_BOO, "БОО")
        this.AddFormationBox(C_VK, "ВК")
        this.AddFormationBox(C_KMB, "КМБ / УКМБ")

        this.ctrl.formLine := this.gui.AddProgress("BackgroundWhite", 0)
        this.ctrl.formTribBg := this.gui.AddProgress("BackgroundGray", 0)
        this.SetFont("s12 Bold cWhite")
        this.ctrl.formTribTxt := this.AddText("Center +BackgroundTrans +0x200", "ТРИБУНА (ПЛАЦ)")

        ; TAB 8
        this.ctrl.Tabs.UseTab(8)
        this.SetFont("s16 Bold c" this.C_TXT_ACCENT)
        this.ctrl.schHdr := this.AddText("+BackgroundTrans", "Расписание и уведомления")

        this.SetFont("s12 c" this.C_TXT_MAIN)
        schText := "
        (
        Скрипт автоматически синхронизирует время по МСК (Москве).
        Уведомления появятся прямо поверх игры со звуком.

        ОБЕДЕННЫЙ ПЕРЕРЫВ (ежедневно):
        Начало: 15:00 | Конец: 16:00
        Важно: покидать ВЧ на обед разрешено только со звания Старший Сержант и выше.
        Остальные остаются на территории части.

        ПРИЗЫВЫ В АРМИЮ:
        Понедельник: 16:00 и 20:30
        Вторник:       16:30 и 21:00
        Среда:         17:00 и 21:30
        Четверг:       17:30 и 22:00
        Пятница:       18:00 и 22:30
        Суббота:       14:00 и 18:30
        Воскресенье: 14:30 и 19:00

        Скрипт предупредит вас ровно за 10 минут до начала каждого призыва.
        )"
        this.ctrl.schInfo := this.AddText("+BackgroundTrans R25", schText)

        ; TAB 9
        this.ctrl.Tabs.UseTab(9)
        this.SetFont("s14 Bold c" this.C_TXT_MAIN)
        this.ctrl.setHdr := this.AddText("+BackgroundTrans", "Настройки")

        this.SetFont("s12 c" this.C_TXT_MAIN)
        this.ctrl.setLblKey := this.AddText("+BackgroundTrans +0x200", "Клавиша запуска:")
        this.ctrl.editKey := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border Center", this.menuKey)
        this.ctrl.btnSaveKey := this.gui.AddButton("", "Сохранить")
        this.ctrl.btnSaveKey.OnEvent("Click", this.OnKeyChange.Bind(this))

        this.SetFont("s10 c" this.C_TXT_MUTED)
        this.ctrl.lblKeyInfo := this.AddText("+BackgroundTrans", "Введи кнопку и нажми Сохранить. Работает везде.")

        this.ctrl.setLine := this.AddText("Background" this.C_BORDER, "")

        this.SetFont("s12 c" this.C_TXT_MAIN)
        this.ctrl.setLblTheme := this.AddText("+BackgroundTrans +0x200", "Дизайн скрипта:")
        this.ctrl.ddTheme := this.gui.AddDropDownList(
            "Choose" this.GetThemeIndex() " Background" this.C_INPUT_BG " cBlack",
            ["Штаб (Тёмная)", "Полигон (Камуфляж)", "ВМФ (Тёмно-синяя)"]
        )
        this.ctrl.btnTheme := this.gui.AddButton("", "Применить")
        this.ctrl.btnTheme.OnEvent("Click", this.ChangeTheme.Bind(this))

        this.ctrl.setLineRecruit := this.AddText("Background" this.C_BORDER, "")
        this.SetFont("s12 c" this.C_TXT_MAIN)
        this.ctrl.chkRecruitMode := this.gui.AddCheckbox("Checked" this.recruitMode, "Режим Новобранец")
        this.ctrl.chkRecruitMode.OnEvent("Click", this.OnRecruitModeToggle.Bind(this))
        this.SetFont("s10 c" this.C_TXT_MUTED)
        this.ctrl.lblRecruitInfo := this.AddText("+BackgroundTrans", "Показывает пояснения по вкладкам и помогает быстрее освоиться в скрипте.")

        this.ctrl.setLine2 := this.AddText("Background" this.C_BORDER, "")

        this.SetFont("s14 Bold c" this.C_TXT_ACCENT)
        this.ctrl.qpHdr := this.AddText("+BackgroundTrans", "Быстрые фразы по клавишам")
        this.SetFont("s10 c" this.C_TXT_MUTED)
        this.ctrl.qpInfo := this.AddText("+BackgroundTrans", "Если поле 'Своя фраза' заполнено — используется оно, иначе отправляется выбранная готовая фраза.")

        this.SetFont("s10 Bold c" this.C_TXT_MAIN)
        this.ctrl.qpColSlot := this.AddText("+BackgroundTrans", "Слот")
        this.ctrl.qpColKey := this.AddText("+BackgroundTrans", "Кнопка")
        this.ctrl.qpColReady := this.AddText("+BackgroundTrans", "Готовая фраза")
        this.ctrl.qpColPick := this.AddText("+BackgroundTrans", "Выбор")
        this.ctrl.qpColCustom := this.AddText("+BackgroundTrans", "Своя фраза")
        this.ctrl.qpColSave := this.AddText("+BackgroundTrans", "Сохранить")

        this.ctrl.quickRows := []

        loop 5 {
            i := A_Index
            this.SetFont("s11 c" this.C_TXT_MAIN)
            lbl := this.AddText("+BackgroundTrans +0x200", "Слот " i ":")

            keyEdit := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border Center", this.quickSlots[i].key)
            readyText := this.gui.AddEdit("ReadOnly Background" this.C_SURFACE " c" this.C_TXT_MAIN " +Border", this.GetQuickPhraseDisplayText(i))

            pickBtn := this.gui.AddButton("", "Выбрать")
            pickBtn.OnEvent("Click", this.OpenPhrasePicker.Bind(this, i))

            custom := this.gui.AddEdit("Background" this.C_INPUT_BG " cBlack +Border", this.quickSlots[i].customText)

            saveBtn := this.gui.AddButton("", "Сохранить")
            saveBtn.OnEvent("Click", this.SaveQuickPhraseSlot.Bind(this, i))

            this.ctrl.quickRows.Push({
                lbl: lbl,
                key: keyEdit,
                ready: readyText,
                pick: pickBtn,
                custom: custom,
                btn: saveBtn
            })
        }

        this.SetFont("s10 c" this.C_TXT_WARN)
        this.ctrl.qpWarn := this.AddText("+BackgroundTrans", "Совет: используйте F5–F9 или Ctrl+1..Ctrl+5, если они не заняты сервером или игрой.")

        ; TAB 10
        this.ctrl.Tabs.UseTab(10)
        this.ctrl.NotePad := this.gui.AddEdit("Multi VScroll Background" this.C_SURFACE " c" this.C_TXT_MAIN " -E0x200 +Border +0x4000000", this.savedNotes)

        this.ctrl.Tabs.UseTab()

        ; Нижняя панель подсказки новичку
        this.ctrl.recruitPanelBg := this.AddText("Background" this.C_SURFACE_2, "")
        this.SetFont("s11 Bold c" this.C_TXT_ACCENT)
        this.ctrl.recruitHdr := this.AddText("BackgroundTrans", "ПОДСКАЗКА НОВОБРАНЦУ")
        this.SetFont("s10 c" this.C_TXT_MAIN)
        this.ctrl.recruitText := this.AddText("BackgroundTrans", "")

        ; Footer
        this.SetFont("s11 Bold c" this.C_TXT_ERR)
        this.ctrl.bAlert1 := this.AddText("Center Background" this.C_SURFACE " c" this.C_TXT_ERR " +0x200", "Иные лица — проход запрещён")
        this.SetFont("s10 c" this.C_TXT_WARN)
        this.ctrl.chkAutoSend := this.gui.AddCheckbox("x0 y0 w120 h20 Checked" this.autoSend, "⚡ Auto-Enter")
        this.ctrl.chkAutoSend.OnEvent("Click", (*) => (this.autoSend := this.ctrl.chkAutoSend.Value))

        OnMessage(0x4E, this._wmNotify)
        OnMessage(0x02E0, this._wmDpi)
        OnMessage(0x020A, this._wmWheel)

        this.FillLV(this.lv.fz, this.dataFZ, [])
        this.FillLV(this.lv.phrases, this.dataPhrases, [])
        this.FillLV(this.lv.tenCodes, this.dataTenCodes, [])
        this.ApplyFilter("")
    }

    OnRecruitModeToggle(*) {
        this.recruitMode := this.ctrl.chkRecruitMode.Value
        this.SaveSettings()
        this.UpdateRecruitHint()
        this.gui.GetClientPos(, , &cw, &ch)
        this.Layout(cw, ch)
    }

    GetRecruitHintText(tabIdx := 0) {
        if (tabIdx = 0)
            tabIdx := this.ctrl.Tabs.Value

        switch tabIdx {
            case 1:
                return "Проверь документы и основание прохода. Если ситуация спорная — не принимай решение в одиночку, запроси старшего и сверь допуск по спискам КПП."
            case 2:
                return "Выбери нужный кодекс, затем статью в списке сверху. Полный текст статьи откроется в нижнем поле, а поиск работает по номеру, названию и содержимому статьи. Сейчас доступны УК и Процессуальный кодекс."
            case 3:
                return "Тен-коды помогают быстро общаться в рации. Если не уверен в коде — сначала сверь расшифровку, а потом используй его в докладе."
            case 4:
                return "Здесь собраны федеральные законы. Сначала выбери нужный закон, затем статью в списке сверху, после чего прочитай её полный текст в нижнем поле."
            case 5:
                return "Сначала заполни тэг, имя и пост. Затем выбери состояние, код и состав, после чего нажми кнопку генерации доклада."
            case 6:
                return "Укажи номер патруля, позывной и состав. Затем выбери объект и используй кнопки действий по порядку: начать, наблюдать, продолжить, переместиться, закончить."
            case 7:
                return "Эта вкладка помогает ориентироваться по расположению подразделений на вечерней поверке и не перепутать своё место в строю."
            case 8:
                return "Следи за временем обеда и призыва. Скрипт сам предупредит заранее, но полезно держать расписание перед глазами и знать его вручную."
            case 9:
                return "Здесь можно сменить клавишу открытия, включить режим Новобранец, настроить быстрые фразы и выбрать удобный дизайн скрипта."
            case 10:
                return "Используй блокнот для личных заметок: позывные, указания старших, время докладов, маршруты или важные служебные напоминания."
            default:
                return "Используй вкладки по назначению и не спеши. Если сомневаешься — сначала сверь информацию, затем действуй."
        }
    }

    UpdateRecruitHint() {
        if !this.gui || !this.ctrl.HasOwnProp("recruitText")
            return

        if this.recruitMode {
            this.ctrl.recruitText.Value := ""
            this.ctrl.recruitText.Text := this.GetRecruitHintText()
            this.ctrl.recruitPanelBg.Visible := true
            this.ctrl.recruitHdr.Visible := true
            this.ctrl.recruitText.Visible := true
        } else {
            this.ctrl.recruitPanelBg.Visible := false
            this.ctrl.recruitHdr.Visible := false
            this.ctrl.recruitText.Visible := false
        }
    }

    GetQuickPhraseDisplayText(slotIndex) {
        idx := this.quickSlots[slotIndex].listIndex
        if (idx < 1 || idx > this.dataPhrases.Length)
            idx := 1
        return this.dataPhrases[idx][1]
    }

    OpenPhrasePicker(slotIndex, *) {
        if this.phrasePickerGui
            try this.phrasePickerGui.Destroy()

        this.phrasePickerGui := Gui("+AlwaysOnTop +ToolWindow -MinimizeBox -MaximizeBox", "Выбор готовой фразы")
        this.phrasePickerGui.BackColor := this.C_GUI_BG

        this.phrasePickerGui.AddText("x0 y0 w544 h48 Background" this.C_HEADER_BG, "")
        this.phrasePickerGui.SetFont("s11 Bold c" this.C_TXT_MAIN, "Segoe UI")
        this.phrasePickerGui.AddText("x16 y13 w500 h22 BackgroundTrans", "Выберите готовую фразу для слота " slotIndex)

        lbItems := []
        for row in this.dataPhrases
            lbItems.Push(row[1])

        this.phrasePickerGui.SetFont("s10 cBlack", "Segoe UI")
        lb := this.phrasePickerGui.AddListBox("x16 y62 w512 h228 Background" this.C_INPUT_BG " cBlack +Border", lbItems)
        lb.Value := this.quickSlots[slotIndex].listIndex

        this.phrasePickerGui.SetFont("s10 Bold c" this.C_TXT_MAIN, "Segoe UI")
        btnOk := this.phrasePickerGui.AddButton("x16 y306 w140 h36", "Выбрать")
        btnCancel := this.phrasePickerGui.AddButton("x168 y306 w140 h36", "Отмена")

        chooseFn := (*) => this.ApplyPickedPhrase(slotIndex, lb.Value)

        btnOk.OnEvent("Click", chooseFn)
        btnCancel.OnEvent("Click", (*) => this.phrasePickerGui.Destroy())
        lb.OnEvent("DoubleClick", chooseFn)

        this.phrasePickerGui.OnEvent("Close", (*) => this.phrasePickerGui.Destroy())
        this.phrasePickerGui.Show("w544 h358 Center")
    }

    ApplyPickedPhrase(slotIndex, pickedIndex) {
        if (pickedIndex < 1 || pickedIndex > this.dataPhrases.Length)
            return

        this.quickSlots[slotIndex].listIndex := pickedIndex

        if this.ctrl.HasOwnProp("quickRows") {
            try this.ctrl.quickRows[slotIndex].ready.Value := this.dataPhrases[pickedIndex][1]
        }

        if this.phrasePickerGui
            try this.phrasePickerGui.Destroy()

        this.phrasePickerGui := 0
    }

    SaveQuickPhraseSlot(slotIndex, *) {
        row := this.ctrl.quickRows[slotIndex]
        key := Trim(row.key.Value)
        customText := Trim(row.custom.Value)
        listIndex := this.quickSlots[slotIndex].listIndex

        if (listIndex < 1 || listIndex > this.dataPhrases.Length)
            listIndex := 1

        if (key = "") {
            MsgBox("Укажите клавишу для слота " slotIndex ".", "Быстрые фразы")
            return
        }

        if (StrLower(key) = StrLower(this.menuKey)) {
            MsgBox("Нельзя использовать клавишу меню (" this.menuKey ") для быстрой фразы.", "Конфликт клавиш")
            return
        }

        for i, slot in this.quickSlots {
            if (i != slotIndex && slot.key != "" && StrLower(slot.key) = StrLower(key)) {
                MsgBox("Клавиша '" key "' уже используется в другом слоте быстрых фраз.", "Конфликт клавиш")
                return
            }
        }

        this.quickSlots[slotIndex].key := key
        this.quickSlots[slotIndex].listIndex := listIndex
        this.quickSlots[slotIndex].customText := customText

        row.ready.Value := this.GetQuickPhraseDisplayText(slotIndex)

        this.SaveSettings()
        this.RegisterQuickPhraseHotkeys()

        ToolTip("Слот " slotIndex " сохранён")
        SetTimer(() => ToolTip(), -1500)
    }

    RegisterQuickPhraseHotkeys() {
        this.UnregisterQuickPhraseHotkeys()

        HotIf(this.fnCondGame)
        for idx, slot in this.quickSlots {
            key := Trim(slot.key)
            if (key = "")
                continue

            try {
                fn := this.SendQuickPhrase.Bind(this, idx)
                Hotkey("*" key, fn, "On")
                this.quickHotkeys[key] := fn
            } catch {
            }
        }
        HotIf()
    }

    UnregisterQuickPhraseHotkeys() {
        if (this.quickHotkeys.Count = 0)
            return

        HotIf(this.fnCondGame)
        for key, fn in this.quickHotkeys {
            try Hotkey("*" key, "Off")
        }
        HotIf()

        this.quickHotkeys := Map()
    }

    SendQuickPhrase(slotIndex, *) {
        if (slotIndex < 1 || slotIndex > this.quickSlots.Length)
            return

        slot := this.quickSlots[slotIndex]
        txt := Trim(slot.customText)

        if (txt = "") {
            idx := slot.listIndex
            if (idx < 1 || idx > this.dataPhrases.Length)
                idx := 1
            txt := this.dataPhrases[idx][1]
        }

        if (txt = "")
            return

        this.SendOrCopy(txt)
    }

    AddFormationBox(color, title) {
        p1 := this.gui.AddProgress("c" color, 100)
        p2 := this.gui.AddProgress("Background" this.C_GUI_BG, 0)
        this.SetFont("s16 Bold c" color)
        t := this.AddText("Center +BackgroundTrans +0x200", title)
        this.ctrl.formBoxes.Push({p1:p1, p2:p2, t:t})
    }

    ChangeMap(*) {
        selFile := FileSelect(3, , "Выберите картинку карты на вашем ПК", "Images (*.png; *.jpg; *.jpeg; *.bmp)")
        if (selFile = "")
            return

        try {
            if FileExist(this.mapPath)
                FileDelete(this.mapPath)
            FileCopy(selFile, this.mapPath, 1)
            MsgBox("Карта успешно обновлена и сохранена.", "Успех", "Iconi")
        } catch {
            MsgBox("Произошла ошибка при сохранении файла.", "Ошибка", "Iconx")
        }
    }

    ShowMap(*) {
        if !FileExist(this.mapPath) {
            res := MsgBox(
                "Карта патруля не найдена.`n`nНажмите 'ОК', чтобы выбрать скачанную картинку карты с вашего ПК. Скрипт запомнит её.",
                "Карта СВО",
                "OKCancel IconInfo"
            )
            if (res = "Cancel")
                return

            this.ChangeMap()
            if !FileExist(this.mapPath)
                return
        }

        if this.mapGui
            try this.mapGui.Destroy()

        this.mapGui := Gui("+AlwaysOnTop +ToolWindow -Caption +Border", "Карта СВО")
        this.mapGui.BackColor := "0B0D10"

        try {
            targetH := Round(A_ScreenHeight * 0.88)
            pic := this.mapGui.AddPicture("x12 y12 h" targetH " w-1 -E0x200", this.mapPath)
            pic.OnEvent("Click", (*) => this.mapGui.Destroy())

            this.mapGui.SetFont("s10 c" this.C_TXT_MUTED, "Segoe UI")
            this.mapGui.AddText("x12 y+8 w900 Center BackgroundTrans", "Нажмите на карту, чтобы закрыть окно")
            this.mapGui.Show("AutoSize Center NoActivate")
        } catch {
            try this.mapGui.Destroy()
            this.mapGui := 0
            try FileDelete(this.mapPath)
            MsgBox("Файл поврежден или это не картинка. Выберите другой файл.", "Ошибка", "Iconx")
        }
    }

    UpdateHotkey(newKey) {
        if (newKey = "")
            return

        if (this.menuKey != "") {
            HotIf(this.fnCondOpen)
            try Hotkey("~*" this.menuKey, "Off")

            HotIf(this.fnCondClose)
            try Hotkey("*" this.menuKey, "Off")
            HotIf()
        }

        this.menuKey := newKey

        try {
            HotIf(this.fnCondOpen)
            Hotkey("~*" newKey, this.Toggle.Bind(this), "On")

            HotIf(this.fnCondClose)
            Hotkey("*" newKey, this.Toggle.Bind(this), "On")
            HotIf()

            if this.ctrl.HasOwnProp("hTitle")
                this.ctrl.hTitle.Text := "ARMY HELPER • ПАМЯТКА v4.8 [" this.menuKey "]"

            this.SaveSettings()
            this.RegisterQuickPhraseHotkeys()
        } catch {
            MsgBox("Ошибка. Клавиша '" newKey "' недопустима.", "Ошибка")
        }
    }

    OnKeyChange(*) {
        newK := Trim(this.ctrl.editKey.Value)
        this.UpdateHotkey(newK)
        ToolTip("Успешно сохранено: " newK)
        SetTimer(() => ToolTip(), -2500)
    }

    SendOrCopy(text) {
        if this.autoSend {
            this.Hide()
            Sleep 150

            if WinActive("ahk_group RAGE") {
                SendInput "{t}"
                Sleep 100
                SendInput "{Text}" text
                Sleep 50
                SendInput "{Enter}"
            } else {
                A_Clipboard := text
                ToolTip("Игра не активна. Скопировано в буфер.")
                SetTimer(() => ToolTip(), -1500)
            }
        } else {
            A_Clipboard := text
            ToolTip("Скопировано: " text)
            SetTimer(() => ToolTip(), -1500)
        }
    }

    CopyReport(*) {
        tag := this.ctrl.editTag.Value
        name := this.ctrl.editName.Value
        post := this.ctrl.ddPost.Text
        stat := this.ctrl.ddState.Text
        code := this.ctrl.ddCode.Text
        count := this.ctrl.ddCount.Text

        if InStr(stat, "минут")
            report := tag " Докладывает: " name " | Пост: " post " | " stat " | " code " | " count " | Доклад окончен."
        else
            report := tag " Докладывает: " name " | Пост: " post " " stat " | " code " | " count " | Доклад окончен."

        this.SendOrCopy(report)
    }

    StartTimer(minutes, *) {
        try {
            minVal := Integer(minutes)
            if (minVal <= 0)
                throw Error()
        } catch {
            ToolTip("Ошибка: укажите корректное число минут.")
            SetTimer(() => ToolTip(), -2500)
            return
        }

        this.timerEnd := A_TickCount + minVal * 60000
        SetTimer(this._updateTimerFn, 1000)
        this.UpdateTimer()

        if !this.shown
            this.ShowOverlay()

        ToolTip("Таймер запущен на " minVal " мин.")
        SetTimer(() => ToolTip(), -2000)
    }

    StopTimer() {
        this.timerEnd := 0
        SetTimer(this._updateTimerFn, 0)
        this.UpdateTimer()

        if this.overlay
            try this.overlay.Hide()
    }

    UpdateTimer() {
        if (this.timerEnd = 0) {
            txt := "00:00"
        } else {
            remaining := this.timerEnd - A_TickCount
            if (remaining <= 0) {
                this.StopTimer()
                try SoundPlay("*64")
                Sleep 150
                SoundBeep(450, 200)
                this.ShowAlert("Таймер", "Время делать доклад.")
                return
            }

            secs := Floor(remaining / 1000)
            mins := Floor(secs / 60)
            secs := Mod(secs, 60)
            txt := Format("{:02}:{:02}", mins, secs)
        }

        if this.ctrl.HasOwnProp("lblTimer")
            this.ctrl.lblTimer.Text := txt

        if this.overlay {
            this.overlay.lbl.Text := txt
            if (!this.shown && this.timerEnd > A_TickCount)
                this.ShowOverlay()
        }
    }

    OnPhraseClick(lvObj, rowNum) {
        if (rowNum = 0)
            return
        this.SendOrCopy(lvObj.GetText(rowNum, 1))
    }

    GetCurrentCodeData() {
    return (this.ctrl.cbCodes.Value = 1) ? this.dataUK : this.dataPK
}

    OnCodeLawChange(*) {
        if this.ctrl.HasOwnProp("codeFullText")
            this.ctrl.codeFullText.Value := "Выберите статью в списке сверху, чтобы прочитать её полный текст здесь..."
        this.ApplyFilter(this.ctrl.SearchEdit.Value)
    }

    OnCodeClick(lvObj, rowNum) {
        if (rowNum = 0)
            return

        artNum := lvObj.GetText(rowNum, 1)
        srcData := this.GetCurrentCodeData()

        for row in srcData {
            if (row[1] = artNum) {
                fullTxt := row.Length >= 3 ? row[3] : row[2]
                this.ctrl.codeFullText.Value := "====== " row[1] ". " row[2] " ======`n`n" fullTxt
                break
            }
        }
    }

    OnFzLawChange(*) {
        if (this.ctrl.cbFzLaw.Value = 2)
            this.dataFZ := this.dataFZ52
        else
            this.dataFZ := this.dataFZ86

        this.ctrl.fzFullText.Value := "Выберите статью в списке сверху, чтобы прочитать её полный текст здесь..."
        this.ApplyFilter(this.ctrl.SearchEdit.Value)
    }

    OnFzClick(lvObj, rowNum) {
        if (rowNum = 0)
            return

        artNum := lvObj.GetText(rowNum, 1)
        for row in this.dataFZ {
            if (row[1] = artNum) {
                this.ctrl.fzFullText.Value := "====== " row[1] ". " row[2] " ======`n`n" row[3]
                break
            }
        }
    }

    SvoAction(act, *) {
        pNum := this.ctrl.svoNum.Value
        pCall := this.ctrl.svoCall.Value
        pCrew := this.ctrl.svoCrew.Value
        pTag := this.ctrl.editTag.Value

        header := pTag " Докладывает: Патруль №" pNum
        if (pCall != "")
            header .= ' "' pCall '"'
        header .= " в составе: " pCrew " | "

        currentPoint := this.ctrl.ddSvoLoc.Text
        msg := ""

        switch act {
            case "start":
                msg := header "Начинаем патрулирование по Стратегическим Объектам РФ."
            case "watch":
                msg := header "Прибыли на объект " currentPoint ". Начинаем наблюдение."
            case "cont":
                msg := header "Состояние объекта " currentPoint " : Код-1 | Продолжаем наблюдение."
            case "move":
                idx := this.ctrl.ddSvoLoc.Value
                nextPoint := (idx < this.stratPoints.Length) ? this.stratPoints[idx + 1] : "Завершение маршрута"
                msg := header "Состояние объекта " currentPoint " : Код-1 | Выдвигаемся на следующий объект " nextPoint "."
                if (idx < this.stratPoints.Length)
                    this.ctrl.ddSvoLoc.Value := idx + 1
            case "end":
                msg := header "Закончили цикл патрулирования по Стратегическим Объектам РФ."
        }

        this.SendOrCopy(msg)
    }

    CreateOverlay() {
        if this.overlay
            try this.overlay.Destroy()

        this.overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "TimerOverlay")
        this.overlay.BackColor := this.C_SURFACE_2
        this.overlay.SetFont("s11 Bold c" this.C_TXT_ACCENT, "Segoe UI")
        this.overlay.lbl := this.overlay.AddText("x0 y0 w130 h32 Center BackgroundTrans", "00:00")
        try WinSetTransparent(235, "ahk_id " this.overlay.Hwnd)
    }

    ShowOverlay() {
        if !this.overlay
            this.CreateOverlay()

        wa := this.GetPrimaryWorkArea()
        x := wa.R - 145
        y := wa.T + 20

        this.overlay.Show("x" x " y" y " w130 h32 NoActivate")
        try WinSetAlwaysOnTop(1, "ahk_id " this.overlay.Hwnd)
    }

    OnTabChange(*) {
        idx := this.ctrl.Tabs.Value

        this.ctrl.NotePad.Visible := (idx = 10)
        if this.ctrl.HasOwnProp("fzFullText")
            this.ctrl.fzFullText.Visible := (idx = 4)
        if this.ctrl.HasOwnProp("codeFullText")
            this.ctrl.codeFullText.Visible := (idx = 2)

        this.ctrl.SearchEdit.Value := ""
        this.ApplyFilter("")
        this.UpdateRecruitHint()
    }
    ApplyFilter(txt) {
        needle := StrLower(Trim(txt))
        tabIdx := this.ctrl.Tabs.Value

        switch tabIdx {
            case 1:
                f1 := [], f2 := []
                for row in this.dataKpp1
                    if (needle = "" || InStr(StrLower(row[1] " " row[2]), needle))
                        f1.Push(row)
                for row in this.dataKpp2
                    if (needle = "" || InStr(StrLower(row[1] " " row[2]), needle))
                        f2.Push(row)

                this.FillLV(this.lv.lv1, f1, this.BuildRowColorsLv1(f1))
                this.FillLV(this.lv.lv2, f2, this.BuildRowColorsLv2(f2))

            case 2:
                srcData := this.GetCurrentCodeData()
                fCodes := []
                for row in srcData {
                    hay := row[1] " " row[2]
                    if (row.Length >= 3)
                        hay .= " " row[3]

                    if (needle = "" || InStr(StrLower(hay), needle))
                        fCodes.Push([row[1], row[2]])
                }

                colors := []
                for _ in fCodes
                    colors.Push(this.BGR_DEF)
                this.FillLV(this.lv.codes, fCodes, colors)

            case 3:
                fTen := []
                for row in this.dataTenCodes
                    if (needle = "" || InStr(StrLower(row[1] " " row[2]), needle))
                        fTen.Push(row)

                colors := []
                for _ in fTen
                    colors.Push(this.BGR_DEF)
                this.FillLV(this.lv.tenCodes, fTen, colors)

            case 4:
                fFZ := []
                for row in this.dataFZ
                    if (needle = "" || InStr(StrLower(row[1] " " row[2] " " row[3]), needle))
                        fFZ.Push(row)

                colors := []
                for _ in fFZ
                    colors.Push(this.BGR_DEF)
                this.FillLV(this.lv.fz, fFZ, colors)

            case 5:
                fPhr := []
                for row in this.dataPhrases
                    if (needle = "" || InStr(StrLower(row[1]), needle))
                        fPhr.Push(row)

                colors := []
                for _ in fPhr
                    colors.Push(this.BGR_DEF)
                this.FillLV(this.lv.phrases, fPhr, colors)
        }

        this.gui.GetClientPos(, , &cw, &ch)
        this.Layout(cw, ch)
    }

    OnLvClick(lvObj, rowNum) {
        if (rowNum = 0)
            return

        if (lvObj = this.lv.codes || lvObj = this.lv.fz || lvObj = this.lv.tenCodes)
            textToCopy := lvObj.GetText(rowNum, 1) " " lvObj.GetText(rowNum, 2)
        else
            textToCopy := lvObj.GetText(rowNum, 2)

        this.SendOrCopy(textToCopy)

        try this.ctrl.SearchEdit.Focus()
        try SendMessage(0x00B1, 0, -1, this.ctrl.SearchEdit.Hwnd)
    }

    ChangeOpacity(step) {
        this.opacity += step
        this.opacity := Max(50, Min(255, this.opacity))

        try WinSetTransparent(this.opacity, "ahk_id " this.gui.Hwnd)
        ToolTip("Прозрачность: " Round((this.opacity / 255) * 100) "%")
        SetTimer(() => ToolTip(), -800)
    }

    LoadSettings() {
        try {
            if FileExist(this.iniFile) {
                this.winPos.x := IniRead(this.iniFile, "Window", "X", 0)
                this.winPos.y := IniRead(this.iniFile, "Window", "Y", 0)
                this.winPos.w := IniRead(this.iniFile, "Window", "W", 0)
                this.winPos.h := IniRead(this.iniFile, "Window", "H", 0)
                this.opacity := IniRead(this.iniFile, "Window", "Opacity", 245)

                this.autoSend := IniRead(this.iniFile, "Settings", "AutoSend", 0)
                this.recruitMode := IniRead(this.iniFile, "Settings", "RecruitMode", 0)
                this.menuKey := IniRead(this.iniFile, "Settings", "MenuKey", "F2")
                this.currentTheme := IniRead(this.iniFile, "Settings", "Theme", "Штаб (Тёмная)")

                this.reportTag := IniRead(this.iniFile, "Report", "Tag", "[БОО]")
                this.reportName := IniRead(this.iniFile, "Report", "Name", "Рядовой Фамилия")

                this.patrolNum := IniRead(this.iniFile, "SVO", "Num", "1")
                this.patrolCall := IniRead(this.iniFile, "SVO", "Call", "Стражи")
                this.patrolCrew := IniRead(this.iniFile, "SVO", "Crew", "Фамилия, Фамилия")

                savedRaw := IniRead(this.iniFile, "Data", "Notes", "")
                this.savedNotes := StrReplace(savedRaw, "¶", "`n")
            }
        }
    }

    SaveSettings() {
        try {
            if this.gui {
                this.gui.GetPos(&x, &y, &w, &h)
                if (w >= this.minW) {
                    IniWrite(x, this.iniFile, "Window", "X")
                    IniWrite(y, this.iniFile, "Window", "Y")
                    IniWrite(w, this.iniFile, "Window", "W")
                    IniWrite(h, this.iniFile, "Window", "H")
                    IniWrite(this.opacity, this.iniFile, "Window", "Opacity")
                }
            }

            if this.ctrl.HasOwnProp("NotePad") {
                noteTxt := StrReplace(this.ctrl.NotePad.Value, "`n", "¶")
                IniWrite(noteTxt, this.iniFile, "Data", "Notes")
            }

            if this.ctrl.HasOwnProp("editTag") {
                this.reportTag := this.ctrl.editTag.Value
                this.reportName := this.ctrl.editName.Value
                IniWrite(this.reportTag, this.iniFile, "Report", "Tag")
                IniWrite(this.reportName, this.iniFile, "Report", "Name")
            }

            if this.ctrl.HasOwnProp("svoNum") {
                this.patrolNum := this.ctrl.svoNum.Value
                this.patrolCall := this.ctrl.svoCall.Value
                this.patrolCrew := this.ctrl.svoCrew.Value
                IniWrite(this.patrolNum, this.iniFile, "SVO", "Num")
                IniWrite(this.patrolCall, this.iniFile, "SVO", "Call")
                IniWrite(this.patrolCrew, this.iniFile, "SVO", "Crew")
            }

            for i, slot in this.quickSlots {
                IniWrite(slot.key, this.iniFile, "QuickPhrase" i, "Key")
                IniWrite(slot.listIndex, this.iniFile, "QuickPhrase" i, "ListIndex")
                IniWrite(slot.customText, this.iniFile, "QuickPhrase" i, "CustomText")
            }

            IniWrite(this.autoSend, this.iniFile, "Settings", "AutoSend")
            IniWrite(this.recruitMode, this.iniFile, "Settings", "RecruitMode")
            IniWrite(this.menuKey, this.iniFile, "Settings", "MenuKey")
            IniWrite(this.currentTheme, this.iniFile, "Settings", "Theme")
        }
    }

    OnSize(guiObj, minMax, w, h) {
        if ((minMax = 1) || !this.gui)
            return
        this.Layout(w, h)
    }

    Drag(*) {
        try DllCall("ReleaseCapture")
        try PostMessage(0xA1, 2, 0, , "ahk_id " this.gui.Hwnd)
    }

    SetFont(spec, face := "Segoe UI") => this.gui.SetFont(spec, face)
    AddText(opts, text := "") => this.gui.AddText("x0 y0 w10 h10 " opts, text)
    AddLV(opts, columns) => this.gui.AddListView("x0 y0 w10 h10 " opts, columns)

    Layout(cw, ch) {
        if !this.gui
            return

        dpi := this.dpi ? this.dpi : A_ScreenDPI
        s := dpi / 96.0

        pad := Round(12 * s)
        gap := Round(10 * s)
        hHdr := Round(42 * s)
        hInfo := Round(30 * s)
        hTxt := Round(24 * s)
        hLgTxt := Round(28 * s)

        this.ctrl.borderT.Move(0, 0, cw, 1)
        this.ctrl.borderB.Move(0, ch - 1, cw, 1)
        this.ctrl.borderL.Move(0, 0, 1, ch)
        this.ctrl.borderR.Move(cw - 1, 0, 1, ch)

        y := 1
        btnSize := hHdr

        this.ctrl.hBg.Move(1, y, cw - btnSize - 2, hHdr)
        this.ctrl.hClose.Move(cw - btnSize - 1, y, btnSize, hHdr)

        titleW := Round(360 * s)
        this.ctrl.hTitle.Move(pad, y, titleW, hHdr)

        searchX := pad + titleW + gap
        searchW := cw - searchX - btnSize - gap
        editH := Round(26 * s)
        editY := y + (hHdr - editH) // 2
        searchLblW := Round(60 * s)
        this.ctrl.SearchIcon.Move(searchX, y, searchLblW, hHdr)
        this.ctrl.SearchEdit.Move(searchX + searchLblW, editY, searchW - searchLblW, editH)

        y += hHdr

        hFooter := Round(40 * s)
        hRecruit := this.recruitMode ? Round(72 * s) : 0
        hAlert1 := Round(28 * s)

        footerY := ch - hFooter - 1
        recruitY := footerY - (this.recruitMode ? (hRecruit + gap) : 0)

        chkW := Round(120 * s)
        this.ctrl.chkAutoSend.Move(cw - chkW - pad, footerY + (hFooter - 20) // 2, chkW, 20)
        this.ctrl.bAlert1.Move(pad, footerY + (hFooter - hAlert1) // 2, cw - chkW - pad * 3, hAlert1)

        if this.recruitMode {
            this.ctrl.recruitPanelBg.Visible := true
            this.ctrl.recruitHdr.Visible := true
            this.ctrl.recruitText.Visible := true

            this.ctrl.recruitPanelBg.Move(pad, recruitY, cw - pad * 2, hRecruit)
            this.ctrl.recruitHdr.Move(pad + 10, recruitY + 8, cw - pad * 2 - 20, 22)
            this.ctrl.recruitText.Move(pad + 10, recruitY + 30, cw - pad * 2 - 20, hRecruit - 36)
        } else {
            this.ctrl.recruitPanelBg.Visible := false
            this.ctrl.recruitHdr.Visible := false
            this.ctrl.recruitText.Visible := false
        }

        tabH := recruitY - gap - y
        this.ctrl.Tabs.Move(1, y, cw - 2, tabH)

        tabHeadH := Round(34 * s)
        tabInnerH := tabH - tabHeadH
        contentY := y + tabHeadH + gap
        W := cw - (pad * 2) - 8

        ; TAB 1
        tY := contentY
        this.ctrl.infoCard.Move(pad, tY, W, hInfo)
        alertH := Round(36 * s)
        this.ctrl.idAlert.Move(pad, tY + hInfo + gap, W, alertH)
        k1Y := tY + hInfo + gap + alertH + gap

        availH := tabInnerH - (k1Y - tabHeadH - y) - gap
        hHeadSection := hLgTxt + hTxt + gap
        hFootSection := hTxt + hTxt + gap
        pureListSpace := availH - (hHeadSection * 2) - hFootSection
        lv1H := Round(pureListSpace * 0.5)
        lv2H := pureListSpace - lv1H
        if (lv1H < 100)
            lv1H := 100, lv2H := 100

        cy := k1Y
        this.ctrl.k1Hdr.Move(pad, cy, W, hLgTxt), cy += hLgTxt
        this.ctrl.k1Sub.Move(pad, cy, W, hTxt), cy += hTxt
        this.lv.lv1.Move(pad, cy, W, lv1H), cy += lv1H + gap
        this.ctrl.k1Warn.Move(pad, cy, W, hTxt), cy += hTxt
        this.ctrl.k1Note.Move(pad, cy, W, hTxt), cy += hTxt + gap
        this.ctrl.k2Hdr.Move(pad, cy, W, hLgTxt), cy += hLgTxt
        this.ctrl.k2Sub.Move(pad, cy, W, hTxt), cy += hTxt
        this.lv.lv2.Move(pad, cy, W, lv2H)

        c1 := Round((W - 4) * 0.45)
        this.lv.lv1.ModifyCol(1, c1), this.lv.lv1.ModifyCol(2, "AutoHdr")
        this.lv.lv2.ModifyCol(1, c1), this.lv.lv2.ModifyCol(2, "AutoHdr")

        ; TAB 2
        tY := contentY
        cbH := Round(30 * s)
        this.ctrl.cbCodes.Move(pad, tY, W)
        tY += cbH + gap

        halfH := Round((tabInnerH - cbH - gap * 4) * 0.35)
        textH := tabInnerH - cbH - halfH - gap * 4
        if (halfH < 100)
            halfH := 100

        this.lv.codes.Move(pad, tY, W, halfH)
        this.lv.codes.ModifyCol(1, Round(80 * s))
        this.lv.codes.ModifyCol(2, "AutoHdr")
        tY += halfH + gap
        this.ctrl.codeFullText.Move(pad, tY, W, textH)

        ; TAB 3
        tY := contentY
        this.lv.tenCodes.Move(pad, tY, W, tabInnerH - gap * 2)
        this.lv.tenCodes.ModifyCol(1, Round(90 * s))
        this.lv.tenCodes.ModifyCol(2, "AutoHdr")

        ; TAB 4
        tY := contentY
        cbH := Round(30 * s)
        this.ctrl.cbFzLaw.Move(pad, tY, W)
        tY += cbH + gap

        halfH := Round((tabInnerH - cbH - gap * 4) * 0.35)
        textH := tabInnerH - cbH - halfH - gap * 4
        if (halfH < 100)
            halfH := 100

        this.lv.fz.Move(pad, tY, W, halfH)
        this.lv.fz.ModifyCol(1, Round(80 * s))
        this.lv.fz.ModifyCol(2, "AutoHdr")
        tY += halfH + gap
        this.ctrl.fzFullText.Move(pad, tY, W, textH)

        ; TAB 5
        tY := contentY
        this.ctrl.srvRepHdr.Move(pad, tY, W, hLgTxt), tY += hLgTxt + gap

        fH := Round(26 * s)
        tagSecW := Round(W * 0.35)
        nameSecW := W - tagSecW - gap
        labelW1 := Round(50 * s)
        labelW2 := Round(90 * s)

        this.ctrl.lblTag.Move(pad, tY, labelW1, fH)
        this.ctrl.editTag.Move(pad + labelW1, tY, tagSecW - labelW1, fH)
        this.ctrl.lblName.Move(pad + tagSecW + gap, tY, labelW2, fH)
        this.ctrl.editName.Move(pad + tagSecW + gap + labelW2, tY, nameSecW - labelW2, fH)
        tY += fH + gap

        halfW := (W - gap) // 2
        this.ctrl.ddPost.Move(pad, tY, halfW)
        this.ctrl.ddState.Move(pad + halfW + gap, tY, halfW)
        tY += Round(30 * s) + gap

        this.ctrl.ddCode.Move(pad, tY, halfW)
        this.ctrl.ddCount.Move(pad + halfW + gap, tY, halfW)
        tY += Round(30 * s) + gap

        this.ctrl.btnCopyRep.Move(pad, tY, W, Round(40 * s)), tY += Round(40 * s) + gap
        this.ctrl.srvLine1.Move(pad, tY, W, 2), tY += 2 + gap
        this.ctrl.srvTimeHdr.Move(pad, tY, W, hLgTxt), tY += hLgTxt
        this.ctrl.srvTimeDesc.Move(pad, tY, W, hTxt), tY += hTxt + gap

        editW := 50
        this.ctrl.editTimerMins.Move(pad, tY, editW, 40)
        this.ctrl.btnTimerCustom.Move(pad + editW + gap, tY, 150, 40)
        this.ctrl.btnStopTimer.Move(pad + editW + gap + 160, tY, 100, 40)
        this.ctrl.lblTimer.Move(pad + editW + gap + 270, tY, 200, 40)
        tY += 40 + gap

        this.ctrl.srvLine2.Move(pad, tY, W, 2), tY += 2 + gap
        this.ctrl.srvPhrHdr.Move(pad, tY, W, hLgTxt), tY += hLgTxt + gap

        listH := recruitY - gap - tY
        if (listH < 100)
            listH := 100
        this.lv.phrases.Move(pad, tY, W, listH)
        this.lv.phrases.ModifyCol(1, "AutoHdr")

        ; TAB 6
        tY := contentY
        this.ctrl.svoHdr.Move(pad, tY, W, hLgTxt), tY += hLgTxt + gap

        this.ctrl.svoLblNum.Move(pad, tY, 80, fH)
        this.ctrl.svoNum.Move(pad + 80, tY, 50, fH)
        this.ctrl.svoLblCall.Move(pad + 140, tY, 80, fH)
        this.ctrl.svoCall.Move(pad + 220, tY, 120, fH)
        this.ctrl.svoLblCrew.Move(pad + 350, tY, 60, fH)
        this.ctrl.svoCrew.Move(pad + 410, tY, W - 410, fH)
        tY += fH + gap

        this.ctrl.svoLine.Move(pad, tY, W, 2), tY += 2 + gap
        this.ctrl.svoHdrLoc.Move(pad, tY, W, hLgTxt), tY += hLgTxt + gap
        this.ctrl.ddSvoLoc.Move(pad, tY, W)
        tY += 30 + gap

        btnH := Round(40 * s)
        leftW := Round((W - gap) * 0.5)
        rightW := W - leftW - gap
        rightX := pad + leftW + gap
        startY := tY

        this.ctrl.btnSvoStart.Move(pad, tY, leftW, btnH), tY += btnH + gap
        this.ctrl.btnSvoWatch.Move(pad, tY, leftW, btnH), tY += btnH + gap
        this.ctrl.btnSvoCont.Move(pad, tY, leftW, btnH), tY += btnH + gap
        this.ctrl.btnSvoMove.Move(pad, tY, leftW, btnH), tY += btnH + gap
        this.ctrl.btnSvoEnd.Move(pad, tY, leftW, btnH)

        rY := startY
        this.ctrl.btnShowMap.Move(rightX, rY, rightW, btnH), rY += btnH + gap
        this.ctrl.btnChangeMap.Move(rightX, rY, rightW, btnH), rY += btnH + gap * 2
        this.ctrl.svoHdrTime.Move(rightX, rY, rightW, hLgTxt), rY += hLgTxt
        this.ctrl.svoTimeDesc.Move(rightX, rY, rightW, hTxt), rY += hTxt + gap
        this.ctrl.svoTimerMins.Move(rightX, rY, 60, 40)
        this.ctrl.btnSvoTimer.Move(rightX + 60 + gap, rY, rightW - 60 - gap, 40)

        ; TAB 7
        tY := contentY
        this.ctrl.formHdr.Move(pad, tY, W, hLgTxt)
        tY += hLgTxt + gap * 2

        boxW := Round(140 * s), boxH := Round(140 * s), spc := Round(10 * s)
        totalW := (boxW * 5) + (spc * 4)
        startX := pad + (W - totalW) // 2

        for idx, obj in this.ctrl.formBoxes {
            bx := startX + (idx - 1) * (boxW + spc)
            obj.p1.Move(bx, tY, boxW, boxH)
            obj.p2.Move(bx + 4, tY + 4, boxW - 8, boxH - 8)
            obj.t.Move(bx, tY, boxW, boxH)
        }

        tY += boxH + Round(30 * s)
        this.ctrl.formLine.Move(startX, tY, totalW, 4)
        tY += Round(30 * s)
        this.ctrl.formTribBg.Move(pad + (W - 200) // 2, tY, 200, 100)
        this.ctrl.formTribTxt.Move(pad + (W - 200) // 2, tY, 200, 100)

        ; TAB 8
        tY := contentY
        this.ctrl.schHdr.Move(pad, tY, W, hLgTxt * 1.5), tY += hLgTxt * 1.5 + gap
        this.ctrl.schInfo.Move(pad, tY, W, tabInnerH - gap * 3)

        ; TAB 9
        tY := contentY
        this.ctrl.setHdr.Move(pad, tY, W, hLgTxt), tY += hLgTxt + gap
        this.ctrl.setLblKey.Move(pad, tY, 130, 30)
        this.ctrl.editKey.Move(pad + 140, tY, 100, 30)
        this.ctrl.btnSaveKey.Move(pad + 250, tY, 130, 30)
        tY += 30 + gap
        this.ctrl.lblKeyInfo.Move(pad, tY, W, 24), tY += 24 + gap

        this.ctrl.setLine.Move(pad, tY, W, 2), tY += 2 + gap * 2
        this.ctrl.setLblTheme.Move(pad, tY, 130, 30)
        this.ctrl.ddTheme.Move(pad + 140, tY, 220)
        this.ctrl.btnTheme.Move(pad + 370, tY, 130, 30)
        tY += 30 + gap

        this.ctrl.setLineRecruit.Move(pad, tY, W, 2), tY += 2 + gap
        this.ctrl.chkRecruitMode.Move(pad, tY, 220, 24)
        this.ctrl.lblRecruitInfo.Move(pad + 230, tY, W - 230, 24)
        tY += 24 + gap * 2

        this.ctrl.setLine2.Move(pad, tY, W, 2), tY += 2 + gap
        this.ctrl.qpHdr.Move(pad, tY, W, hLgTxt), tY += hLgTxt
        this.ctrl.qpInfo.Move(pad, tY, W, hTxt), tY += hTxt + gap

        rowH := Round(26 * s)
        colSlotW := 60
        colKeyW := 95
        colPickW := 85
        colBtnW := 95
        colCustomW := Round(W * 0.22)
        if (colCustomW < 150)
            colCustomW := 150

        colReadyW := W - (colSlotW + colKeyW + colPickW + colCustomW + colBtnW + gap * 5)
        if (colReadyW < 220) {
            colReadyW := 220
            colCustomW := W - (colSlotW + colKeyW + colPickW + colReadyW + colBtnW + gap * 5)
        }
        if (colCustomW < 110)
            colCustomW := 110

        x := pad
        this.ctrl.qpColSlot.Move(x, tY, colSlotW, rowH), x += colSlotW + gap
        this.ctrl.qpColKey.Move(x, tY, colKeyW, rowH), x += colKeyW + gap
        this.ctrl.qpColReady.Move(x, tY, colReadyW, rowH), x += colReadyW + gap
        this.ctrl.qpColPick.Move(x, tY, colPickW, rowH), x += colPickW + gap
        this.ctrl.qpColCustom.Move(x, tY, colCustomW, rowH), x += colCustomW + gap
        this.ctrl.qpColSave.Move(x, tY, colBtnW, rowH)
        tY += rowH + Round(8 * s)

        for i, row in this.ctrl.quickRows {
            x := pad
            row.lbl.Move(x, tY, colSlotW, rowH), x += colSlotW + gap
            row.key.Move(x, tY, colKeyW, rowH), x += colKeyW + gap
            row.ready.Move(x, tY, colReadyW, rowH), x += colReadyW + gap
            row.pick.Move(x, tY, colPickW, rowH), x += colPickW + gap
            row.custom.Move(x, tY, colCustomW, rowH), x += colCustomW + gap
            row.btn.Move(x, tY, colBtnW, rowH)
            tY += rowH + gap
        }

        this.ctrl.qpWarn.Move(pad, tY, W, hTxt)

        ; TAB 10
        this.ctrl.NotePad.Move(pad, contentY, cw - pad * 2 - 8, tabInnerH - gap * 2)
    }

    WM_MOUSEWHEEL(wParam, lParam, msg, hwnd) {
        if !this.gui
            return

        CoordMode "Mouse", "Client"
        MouseGetPos(, &mY)

        if (mY > 45)
            return

        delta := (wParam >> 16)
        if (delta > 32767)
            delta -= 65536

        this.ChangeOpacity(delta > 0 ? 10 : -10)
        return 1
    }

    WM_NOTIFY(wParam, lParam, msg, hwnd) {
        static CDDS_PREPAINT := 1
        static CDDS_ITEMPREPAINT := 0x10001
        static CDDS_SUBITEMPREPAINT := 0x30001
        static CDRF_NOTIFYITEMDRAW := 0x20
        static CDRF_NEWFONT := 0x2
        static CDRF_DODEFAULT := 0x0

        if (!this.gui || !this.lv.HasOwnProp("lv1"))
            return

        hwndFrom := NumGet(lParam, 0, "ptr")
        try {
            if (hwndFrom != this.lv.lv1.Hwnd
             && hwndFrom != this.lv.lv2.Hwnd
             && hwndFrom != this.lv.codes.Hwnd
             && hwndFrom != this.lv.fz.Hwnd
             && hwndFrom != this.lv.phrases.Hwnd
             && hwndFrom != this.lv.tenCodes.Hwnd)
                return
        } catch {
            return
        }

        code := NumGet(lParam, A_PtrSize * 2, "int")
        if (code != -12)
            return

        off := (A_PtrSize = 8)
            ? {st:24, is:56, ct:80, cb:84}
            : {st:12, is:36, ct:48, cb:52}

        stage := NumGet(lParam, off.st, "uint")
        if (stage = CDDS_PREPAINT || stage = CDDS_ITEMPREPAINT)
            return CDRF_NOTIFYITEMDRAW

        if (stage = CDDS_SUBITEMPREPAINT) {
            row0 := NumGet(lParam, off.is, "ptr")
            arr := this.rowColors.Has(hwndFrom) ? this.rowColors[hwndFrom] : 0
            bk := (arr && (row0 + 1) <= arr.Length) ? arr[row0 + 1] : this.BGR_DEF
            NumPut("uint", this.BGR_TEXT_W, lParam, off.ct)
            NumPut("uint", bk, lParam, off.cb)
            return CDRF_NEWFONT
        }

        return CDRF_DODEFAULT
    }

    WM_DPICHANGED(wParam, lParam, msg, hwnd) {
        if !this.gui
            return
        try {
            if (hwnd != this.gui.Hwnd)
                return
        } catch {
            return
        }

        this.dpi := wParam & 0xFFFF
        L := NumGet(lParam, 0, "int")
        T := NumGet(lParam, 4, "int")
        R := NumGet(lParam, 8, "int")
        B := NumGet(lParam, 12, "int")
        this.gui.Move(L, T, R - L, B - T)
    }

    FitSize(pref, minVal, maxAvail) {
        if (maxAvail <= 0)
            return pref
        return Max(Min(pref, maxAvail), minVal)
    }

    GetPrimaryWorkArea() {
        rc := Buffer(16, 0)
        DllCall("user32\SystemParametersInfoW", "uint", 0x0030, "uint", 0, "ptr", rc, "uint", 0)
        return {
            L: NumGet(rc, 0, "int"),
            T: NumGet(rc, 4, "int"),
            R: NumGet(rc, 8, "int"),
            B: NumGet(rc, 12, "int")
        }
    }

    SetupLV(lv) {
        static LVS_EX_FULLROWSELECT := 0x20
        static LVS_EX_DOUBLEBUFFER := 0x10000
        try DllCall("uxtheme\SetWindowTheme", "ptr", lv.Hwnd, "str", "Explorer", "ptr", 0)
        try SendMessage(0x1036, LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER, LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER, lv.Hwnd)
    }

    FillLV(lv, data, colorsArr) {
        lv.Delete()
        for row in data
            lv.Add(, row*)
        this.rowColors[lv.Hwnd] := colorsArr
    }

    BuildRowColorsLv1(data) {
        colors := []
        for row in data {
            cond := row[2]
            if RegExMatch(cond, "i)(при|если|только|вызов|меропр|процесс)")
                colors.Push(this.BGR_YELLOW)
            else
                colors.Push(this.BGR_GREEN)
        }
        return colors
    }

    BuildRowColorsLv2(data) {
        colors := []
        for row in data {
            cond := row[2]
            if InStr(cond, "ТОЛЬКО")
                colors.Push(this.BGR_RED)
            else if RegExMatch(cond, "i)реестр")
                colors.Push(this.BGR_YELLOW)
            else
                colors.Push(this.BGR_GREEN)
        }
        return colors
    }

    GetTenCodesData() => [
        ["10-4", "Принято"],
        ["10-0", "Отмена"],
        ["10-6", "Не принято"],
        ["10-7", "Ожидайте"],
        ["10-15", "Проводится арест"],
        ["10-20", "Локация (местонахождение)"],
        ["10-21", "Запрос ситуации и местонахождения"],
        ["10-22", "Направляюсь в ..."],
        ["10-25", "Нарушение юрисдикции"],
        ["10-27", "Меняю маркировку патруля"],
        ["10-30", "ДТП"],
        ["10-40", "Большое скопление людей"],
        ["10-46", "Провожу обыск"],
        ["10-52", "Запрос сотрудников ЕМS"],
        ["10-55", "Траффик-стоп"],
        ["10-57 VICTOR", "Преследование транспорта"],
        ["10-57 FOXTROT", "Пешая погоня"],
        ["10-60", "Информация/ориентировка об автомобиле"],
        ["10-61", "Информация о пешем подозреваемом"],
        ["10-66", "Остановка повышенного риска"],
        ["10-71", "Запрос одного патрульного крузера"],
        ["10-72", "Запрос двух патрульных крузеров"],
        ["10-73", "Запрос трех патрульных крузеров"],
        ["10-99", "Ситуация урегулирована"]
    ]

    GetKpp1Data() => [
        ["Военнослужащие части", "Свободный проход"],
        ["Первые лица (ПП, ЗПП)", "Беспрепятственно"],
        ["Министр обороны", "Беспрепятственно"],
        ["Аппарат МО РФ", "По удостоверению"],
        ["Следователи СК РФ", "При открытом уг. деле на в/с"],
        ["Руководство СК", "Беспрепятственно"],
        ["Прокуратура", "Для следств. мероприятий"],
        ["МВД / ФСБ", "Только процессуальные действия"],
        ["Медики (EMS)", "Только по вызову"],
        ["ФСО", "Сопровождение первых лиц"]
    ]

    GetKpp2Data() => [
        ["Офицеры (Майор+)", "ТОЛЬКО на СЛУЖЕБНОМ а/м"],
        ["Майор ВС РФ на ЛТС", "При наличии в РЕЕСТРЕ"],
        ["Сбор на поставку", "Допуск всем при предъявлении удостоверения или жетона перед проездом"],
        ["Первые лица", "Беспрепятственно"]
    ]

   GetUKFullData() {
    return [
        ["Ст. 1", "Уголовное законодательство Российской Федерации", "Уголовное законодательство Российской Федерации состоит из настоящего Кодекса. Новые законы, предусматривающие уголовную ответственность, подлежат включению в настоящий Кодекс."],
        ["Ст. 2", "Задачи Уголовного кодекса Российской Федерации", "2.1. Задачами настоящего Кодекса являются: охрана прав и свобод человека и гражданина, собственности, общественного порядка и общественной безопасности, окружающей среды, конституционного строя Российской Федерации от преступных посягательств, обеспечение мира и безопасности человечества, а также предупреждение преступлений.`n2.2. Для осуществления этих задач настоящий Кодекс устанавливает основание и принципы уголовной ответственности, определяет, какие опасные для личности, общества или государства деяния признаются преступлениями, и устанавливает виды наказаний и иные меры уголовно-правового характера за совершение преступлений."],
        ["Ст. 3", "Принцип законности", "3.1. Преступность деяния, а также его наказуемость и иные уголовно-правовые последствия определяются только настоящим Кодексом.`n3.2. Применение уголовного закона по аналогии не допускается."],
        ["Ст. 4", "Принцип равенства граждан перед законом", "Лица, совершившие преступления, равны перед законом и подлежат уголовной ответственности независимо от пола, расы, национальности, языка, происхождения, имущественного и должностного положения, места жительства, отношения к религии, убеждений, принадлежности к общественным объединениям, а также других обстоятельств."],
        ["Ст. 5", "Принцип вины", "5.1. Лицо подлежит уголовной ответственности только за те общественно опасные действия (бездействие) и наступившие общественно опасные последствия, в отношении которых установлена его вина.`n5.2. Объективное вменение, то есть уголовная ответственность за невиновное причинение вреда, не допускается."],
        ["Ст. 6", "Принцип справедливости и гуманизма", "6.1. Наказание и иные меры уголовно-правового характера, применяемые к лицу, совершившему преступление, должны быть справедливыми, то есть соответствовать характеру и степени общественной опасности преступления, обстоятельствам его совершения и личности виновного.`n6.2. Никто не может нести уголовную ответственность дважды за одно и то же преступление.`n6.3. Наказание и иные меры уголовно-правового характера, применяемые к лицу, совершившему преступление, не могут иметь своей целью причинение физических страданий или унижение человеческого достоинства."],
        ["Ст. 7", "Основание уголовной ответственности", "Основанием уголовной ответственности является совершение деяния, содержащего все признаки состава преступления, предусмотренного настоящим Кодексом."],
        ["Ст. 8", "Действие уголовного закона во времени", "Преступность и наказуемость деяния определяются уголовным законом, действовавшим во время совершения этого деяния."],
        ["Ст. 9", "Действие уголовного закона в отношении лиц, совершивших преступление", "Лицо, совершившее преступление на территории Российской Федерации, подлежит уголовной ответственности по настоящему Кодексу."],
        ["Ст. 10", "Понятие преступления", "Преступлением признается виновно совершенное общественно опасное деяние, запрещенное настоящим Кодексом под угрозой наказания."],
        ["Ст. 11", "Рецидив преступлений", "Рецидивом преступлений признается совершение умышленного преступления лицом, имеющим судимость за ранее совершенное умышленное преступление."],
        ["Ст. 12", "Категории преступлений", "Преступления подразделяются на небольшой тяжести, средней тяжести, тяжкие и особо тяжкие."],
        ["Ст. 13", "Совокупность преступлений", "Совокупностью преступлений признается совершение двух или более преступлений, ни за одно из которых лицо не было осуждено."],
        ["Ст. 14", "Понятие соучастия в преступлении", "Соучастием в преступлении признается умышленное совместное участие двух или более лиц в совершении умышленного преступления."],
        ["Ст. 15", "Виды соучастников преступления", "Соучастниками преступления наряду с исполнителем признаются организатор, подстрекатель и пособник."],
        ["Ст. 16", "Ответственность соучастников преступления", "Ответственность соучастников преступления определяется характером и степенью фактического участия каждого из них."],
        ["Ст. 17", "Необходимая оборона", "Не является преступлением причинение вреда посягающему лицу в состоянии необходимой обороны."],
        ["Ст. 18", "Причинение вреда при задержании лица, совершившего преступление", "Не является преступлением причинение вреда лицу, совершившему преступление, при его задержании."],
        ["Ст. 19", "Исполнение приказа или распоряжения", "Не является преступлением причинение вреда охраняемым интересам лицом, действующим во исполнение обязательных для него приказа или распоряжения."],
        ["Ст. 20", "Понятие и цели наказания", "Наказание есть мера государственного принуждения, назначаемая по приговору суда."],
        ["Ст. 21", "Виды наказаний", "Видами наказаний являются штраф, лишение права занимать должности, лишение звания и арест (лишение свободы)."],
        ["Ст. 22", "Штраф", "Штраф есть денежное взыскание, назначаемое в пределах, предусмотренных настоящим Кодексом."],
        ["Ст. 23", "Лишение права занимать определенные должности или заниматься определенной деятельностью", "Состоит в запрещении занимать должности на государственной службе либо заниматься определенной деятельностью."],
        ["Ст. 24", "Лишение специального, воинского или почетного звания, классного чина и государственных наград", "При осуждении за тяжкое или особо тяжкое преступление уполномоченное лицо вправе лишить специального, воинского звания, классного чина."],
        ["Ст. 25", "Арест (лишение свободы)", "Лишение свободы заключается в изоляции осужденного от общества."],
        ["Ст. 26", "Общие начала назначения наказания", "Лицу, признанному виновным в совершении преступления, назначается справедливое наказание в пределах, предусмотренных соответствующей статьей."],
        ["Ст. 27", "Обстоятельства, смягчающие наказание", "Смягчающими наказание признаются, в частности, раскаяние лица, добровольное прекращение противоправного поведения, сообщение о преступлении и содействие следствию."],
        ["Ст. 28", "Обстоятельства, отягчающие наказание", "Отягчающими признаются, в частности, продолжение противоправного поведения, повторное совершение преступления, совершение преступления группой лиц и иные обстоятельства."],
        ["Ст. 29", "Назначение наказания за преступление, совершенное в соучастии", "При назначении наказания учитываются характер и степень фактического участия лица в совершении преступления."],
        ["Ст. 30", "Назначение наказания по совокупности преступлений", "При совокупности преступлений наказание назначается согласно настоящей статье."],
        ["Ст. 31", "Освобождение лица, впервые совершившего преступление судом", "Лицо, впервые совершившее преступление небольшой или средней тяжести, может быть освобождено судом от уголовной ответственности."],
        ["Ст. 32", "Освобождение от уголовной ответственности в связи с истечением сроков давности", "Лицо освобождается от уголовной ответственности, если со дня совершения преступления истекли установленные сроки."],
        ["Ст. 33", "Освобождение или сокращение срока отбывания наказания под залог", "Адвокат вправе освободить или сократить срок лица, отбывающего наказание, под установленный Кодексом залог."],
        ["Ст. 34", "Меры медицинского характера", "Принудительные меры медицинского характера могут быть назначены судом лицам в случаях, предусмотренных законом."],
        ["Ст. 35", "Назначение судебного штрафа", "Судебный штраф есть денежное взыскание, назначаемое судом при освобождении лица от уголовной ответственности."],
        ["Ст. 36", "Конфискация имущества", "Конфискация имущества есть принудительное безвозмездное изъятие имущества и обращение его в собственность государства."],
        ["Ст. 37", "Убийство", "Убийство — умышленное причинение смерти другому человеку."],
        ["Ст. 38", "Причинение тяжкого вреда здоровью", "Причинение тяжкого вреда здоровью, опасного для жизни человека."],
        ["Ст. 39", "Угроза убийством или причинением тяжкого вреда здоровью", "Угроза убийством или причинением тяжкого вреда здоровью."],
        ["Ст. 40", "Изнасилование", "Изнасилование, то есть половое сношение с применением насилия или с угрозой его применения."],
        ["Ст. 41", "Похищение человека", "Похищение человека."],
        ["Ст. 42", "Незаконное лишение свободы", "Незаконное лишение человека свободы."],
        ["Ст. 43", "Нарушение неприкосновенности жилища", "Незаконное проникновение в жилище против воли проживающего в нем лица."],
        ["Ст. 44", "Кража", "Кража, то есть тайное хищение чужого имущества."],
        ["Ст. 45", "Присвоение или растрата", "Присвоение, растрата или мошенничество."],
        ["Ст. 46", "Грабеж", "Грабеж, то есть открытое хищение чужого имущества."],
        ["Ст. 47", "Разбой", "Разбой, то есть нападение в целях хищения чужого имущества с применением насилия."],
        ["Ст. 48", "Уничтожение или повреждение имущества", "Уничтожение или повреждение чужого имущества."],
        ["Ст. 49", "Неправомерное завладение автомобилем или иным транспортным средством", "Неправомерное завладение транспортным средством без цели хищения (угон)."],
        ["Ст. 53", "Террористический акт", "Совершение взрыва, поджога или иных действий, устрашающих население."],
        ["Ст. 54", "Несообщение о преступлении", "Несообщение в органы власти о готовящемся или совершенном преступлении."],
        ["Ст. 55", "Захват заложника", "Захват или удержание лица в качестве заложника."],
        ["Ст. 56", "Заведомо ложное сообщение об акте терроризма", "Заведомо ложное сообщение о готовящемся акте терроризма."],
        ["Ст. 57", "Организация незаконного вооруженного формирования или участие в нем", "Создание вооруженного формирования, не предусмотренного федеральным законом."],
        ["Ст. 58", "Бандитизм", "Создание устойчивой вооруженной группы в целях нападения на граждан или организации."],
        ["Ст. 60", "Массовые беспорядки", "Организация массовых беспорядков."],
        ["Ст. 61", "Хулиганство", "Грубое нарушение общественного порядка."],
        ["Ст. 62", "Незаконное проникновение или нахождение на закрытом объекте", "Незаконное проникновение или нахождение на закрытом объекте."],
        ["Ст. 63", "Незаконный оборот оружия", "Незаконный оборот оружия и запрещённых средств индивидуальной защиты."],
        ["Ст. 64", "Незаконные действия с наркотическими средствами", "Незаконные действия с наркотическими средствами, психотропными веществами или их аналогами."],
        ["Ст. 65", "Организация или вовлечение в занятие проституцией", "Организация или вовлечение в занятие проституцией."],
        ["Ст. 66", "Жестокое обращение с животными", "Жестокое обращение с животными."],
        ["Ст. 67", "Неуплата или отказ от уплаты штрафа", "Неуплата или отказ от уплаты штрафа."],
        ["Ст. 68", "Нарушение правил дорожного движения и эксплуатации транспортных средств", "Нарушение правил дорожного движения и эксплуатации транспортных средств."],
        ["Ст. 69", "Государственная измена", "Государственная измена."],
        ["Ст. 70", "Посягательство на жизнь государственного или общественного деятеля", "Посягательство на жизнь государственного или общественного деятеля."],
        ["Ст. 71", "Вооруженный мятеж", "Организация вооруженного мятежа либо активное участие в нем."],
        ["Ст. 72", "Экстремизм", "Экстремизм и публичные призывы к экстремистской деятельности."],
        ["Ст. 73", "Публичные призывы против безопасности государства", "Публичные призывы к осуществлению деятельности, направленной против безопасности государства."],
        ["Ст. 74", "Разглашение государственной тайны", "Разглашение сведений, составляющих государственную тайну."],
        ["Ст. 75", "Незаконное получение сведений, составляющих государственную тайну", "Незаконное получение сведений, составляющих государственную тайну."],

        ["Ст. 76", "Злоупотребление должностными полномочиями", "76.1. Использование должностным лицом своих служебных полномочий вопреки интересам службы, если это деяние совершено из корыстной или иной личной заинтересованности и повлекло существенное нарушение прав и законных интересов граждан или организаций либо охраняемых законом интересов общества или государства, –`n`nнаказываются штрафом в размере пятисот тысяч (500.000) рублей или лишением свободы на срок трёх лет (СПРП «★★»).`n`n76.2. То же деяние, совершенное лицом, занимающим должность руководителя, заместителя руководителя органа государственной власти, –`n`nнаказываются штрафом в размере одного миллиона (1.000.000) рублей или лишением свободы на срок шести лет (СПРП «★★★»).`n`n76.3. Деяния, предусмотренные частями первой или второй настоящей статьи, повлекшие тяжкие последствия, –`n`nнаказываются лишением свободы на срок семи лет (СПРП «★★★★»)."],

        ["Ст. 77", "Превышение должностных полномочий", "77.1. Совершение должностным лицом действий, явно выходящих за пределы его полномочий, вопреки установленному законом или иным нормативным правовым актом порядку совершение каких-либо действий и повлекших существенное нарушение прав и законных интересов граждан или организаций либо охраняемых законом интересов общества или государства, –`n`nнаказываются штрафом в размере шестиста тысяч (600.000) рублей или лишением свободы на срок трёх лет (СПРП «★★»).`n`n77.2. То же деяние, совершенное лицом, занимающим должность руководителя, заместителя руководителя органа государственной власти, а равно главой органа местного самоуправления, –`n`nнаказываются штрафом в размере двух миллионов (2.000.000) рублей или лишением свободы на срок шести лет (СПРП «★★★»).`n`n77.3. Деяния, предусмотренные частями первой или второй настоящей статьи, если они совершены:`nа) с применением насилия или угрозой применения насилия;`nб) с применением оружия или специальных средств;`nв) с причинением тяжких последствий;`nг) группой лиц по предварительному сговору или организованной группой;`nд) из корыстной или иной личной заинтересованности, –`n`nнаказываются лишением свободы от трёх до семи лет (СПРП «★★★»).`n`n77.4. Производство сотрудником правоохранительного органа задержания в отсутствии оснований для задержаний в соответствии с процессуальным законодательством, –`n`nнаказываются штрафом в размере семиста тысяч (700.000) рублей или лишением свободы на срок трёх лет (СПРП «★★★»).`n`n77.5. Незаконные требования сотрудника правоохранительного органа –`n`nнаказываются штрафом в размере восьмиста тысяч (800.000) рублей или лишением свободы на срок трёх лет (СПРП «★★★»)."],

        ["Ст. 78", "Неисполнение приказа", "Умышленное неисполнение сотрудником государственного органа приказа начальника, руководителя или иного лица, уполномоченного на управление либо осуществление руководства государственного органа, отданного в установленном порядке и не противоречащего закону, –`n`nнаказывается штрафом в размере пятиста тысяч (500.000) рублей или лишением свободы на срок трёх лет (СПРП «★★★»)."],

        ["Ст. 79", "Получение или дача взятки", "Получение или дача должностным лицом или должностным лицам лично или через посредника взятки виде денег, ценных бумаг, иного имущества либо в виде незаконных оказаниях ему услуг имущественного характера, предоставления иных имущественных прав за совершение действий (бездействий) в пользу взяткодателя или представляемых им лиц, если указанные действия входят в служебные полномочия должностного лица либо если оно в силу должностного положения может способствовать указанным действиям (бездействию), а равно за общее покровительство или попустительство по службе, –`n`nнаказывается лишением свободы на срок восьми лет (СПРП «★★★★★★»)."],

        ["Ст. 80", "Халатность", "80.1. Ненадлежащее исполнение должностным лицом своих обязанностей вследствие недобросовестного или небрежного отношения к службе либо обязанностей по должности, если это повлекло причинения ущерба или существенного нарушения прав и законных интересов граждан или организаций либо охраняемых законом интересов общества или государства, –`n`nнаказывается штрафом в размере восьмиста тысяч (800.000) рублей или лишением свободы на срок в два года (СПРП «★»).`n`n80.2. Не исполнение должностным лицом своих обязанностей вследствие недобросовестного или небрежного отношения к службе либо обязанностей по должности, если это повлекло причинения ущерба или существенного нарушения прав и законных интересов граждан или организаций либо охраняемых законом интересов общества или государства, –`n`nнаказывается лишением свободы на срок шести лет (СПРП «★★★»).`n`n80.3. Нарушение установленных процессуальных норм о содержании действий при производстве задержания и ареста сотрудником правоохранительного органа, –`n`nнаказывается штрафом в размере одного миллона (1.000.000) рублей или лишением свободы на срок в три года (СПРП «★★»).`n`n80.4. Отказ от реализации прав задержанного или их реализация ненадлежащим образом в нарушение процессуального законодательства Российской Федерации, –`n`nнаказывается штрафом в размере одного миллиона двухсот пятидесяти тысяч (1.250.000) рублей или лишением свободы на срок в три года (СПРП «★★»)."],

        ["Ст. 81", "Воспрепятствование осуществлению правосудия и производству предварительного расследования", "81.1. Вмешательство в какой бы то ни было форме в деятельность суда в целях воспрепятствования осуществлению правосудия, –`n`nнаказывается лишением свободы на срок шесть лет (СПРП «★★★★»).`n`n81.2. Вмешательство в какой бы то ни было форме в деятельность прокурора, следователя или лица, производящего дознание, в целях воспрепятствования всестороннему, полному и объективному расследованию дела, –`n`nнаказывается лишением свободы на срок трех лет (СПРП «★★★»).`n`n81.3. Деяния, предусмотренные частями первой или второй настоящей статьи, совершенные лицом с использованием своего служебного положения –`n`nнаказываются лишением свободы на срок пяти лет (СПРП «★★★»)."],

        ["Ст. 82", "Влияние на уголовное дело", "Оказание давления на следователя, дознавателя с целью изменения или манипулирования окончательным результатом, подменой улик или манипулированием фактами в деле, –`n`nнаказывается лишением свободы на срок шесть лет (СПРП «★★★★»)."],

        ["Ст. 83", "Влияние на судебное дело", "Влияние на судебное дело или судью с целью изменения или манипулирования окончательным приговором в судебном деле, –`n`nнаказывается лишением свободы на срок шести лет (СПРП «★★★★»)."],

        ["Ст. 84", "Неуважение к суду", "Неуважение к суду, выразившееся в оскорблении судьи, присяжного заседателя или иного лица, участвующего в отправлении правосудия, а равно нарушение порядка, предусмотренного на судебном заседании –`n`nнаказываются штрафом в размере двухсот пятидесяти тысяч (250.000) рублей или лишением свободы на срок двух лет (СПРП «★★»)."],

        ["Ст. 85", "Привлечение заведомо невиновного к уголовной ответственности", "Привлечение заведомо невиновного к уголовной ответственности –`n`nнаказываются лишением свободы на срок десяти лет (СПРП «★★★★»)."],

        ["Ст. 86", "Заведомо ложный донос", "Заведомо ложный донос о совершении преступления –`n`nнаказываются штрафом в размере трехста тысяч (300.000) рублей или лишением свободы на срок четырех лет (СПРП «★★★★»)."],

        ["Ст. 86-1", "Заведомо ложные показание, заключение эксперта, специалиста или неправильный перевод", "Заведомо ложные показание свидетеля, потерпевшего либо заключение или показание эксперта, показание специалиста, а равно заведомо неправильный перевод в суде либо в ходе досудебного производства, –`n`nнаказывается лишением свободы на срок шесть лет (СПРП «★★★»)."],

        ["Ст. 87", "Побег из места лишения свободы, из-под ареста, задержания или из-под стражи", "Побег из места лишения свободы, из-под ареста, задержания или из-под стражи, совершенный лицом, отбывающим наказание или находящимся в предварительном заключении, –`n`nнаказывается лишением свободы на срок восьми лет (СПРП «★★★★★★»)."],

        ["Ст. 88", "Неисполнение приговора суда, решения суда или иного судебного акта", "Злостное неисполнение вступивших в законную силу приговора суда, решения суда или иного судебного акта, а равно воспрепятствование их исполнению лицом, подвергнутым наказанию, –`n`nнаказывается лишением свободы на срок двенадцати лет (СПРП «★★★★»)."],

        ["Ст. 88-1", "Неисполнение решения сотрудника органов прокуратуры или следственного комитета", "Неисполнение государственным служащим (работником), являющимся субъектом процессуальных действий, решения сотрудника органов прокуратуры или следственного комитета, вынесенного в соответствии с процессуальным законодательством Российской Федерации, –`n`nнаказывается лишением свободы на срок десяти лет (СПРП «★★★★»)."],

        ["Ст. 88-2", "Неисполнение представления, а равно игнорирование или неисполнение вынесенного в законном порядке органами прокуратуры протеста или решений принятых в рамках прокурорской проверки", "Неисполнение представления, а равно игнорирование или неисполнение вынесенного в законном порядке органами прокуратуры протеста или решений принятых в рамках прокурорской проверки. –`n`nнаказывается лишением свободы на срок шесть лет (СПРП «★★★★»)."],

        ["Ст. 89", "Посягательство на жизнь сотрудника правоохранительного органа", "Посягательство на жизнь сотрудника правоохранительного органа, военнослужащего, а равно их близких в целях воспрепятствования законной деятельности указанных лиц по охране общественного порядка и обеспечению общественной безопасности либо из мести за такую деятельность, –`n`nнаказывается лишением свободы на срок шести лет (СПРП «★★★★»)."],

        ["Ст. 90", "Применение насилия в отношении представителя власти", "90.1. Применение насилия, не опасного для жизни или здоровья в отношении представителя власти или его близких в связи с исполнением им своих должностных обязанностей –`n`nнаказывается лишением свободы на срок четырех лет (СПРП «★★★»).`n`n90.2. Применение насилия, опасного для жизни или здоровья в отношении лиц, указанных в части первой настоящей статьи, –`n`nнаказывается лишением свободы на срок шести лет (СПРП «★★★★»).`n`n90.3. Угроза применения насилия в отношении лиц, указанных в части первой настоящей статьи, –`n`nнаказывается лишением свободы на срок двух лет (СПРП «★★»).`n`nПримечание: Представителем власти в настоящей статье и других статьях настоящего Кодекса признается должностное лицо правоохранительного или контролирующего органа, а также иное должностное лицо, наделенное в установленном законом порядке распорядительными полномочиями в отношении лиц, не находящихся от него в служебной зависимости."],

        ["Ст. 91", "Оскорбление представителя власти", "Публичное оскорбление представителя власти при исполнении им своих должностных обязанностей или в связи с их исполнением –`n`nнаказывается штрафом в размере пятидесяти тысяч (50.000) рублей или лишением свободы на срок трех лет (СПРП «★★»)."],

        ["Ст. 92", "Подделка, изготовление или оборот поддельных документов, государственных наград, штампов, печатей или бланков", "92.1. Изготовление или оборот документов (паспортов, удостоверений, иных документов, удостоверяющих личность) с поддельной фотографией –`n`nнаказывается штрафом в размере от двухсот пятидесяти тысяч (250.000) рублей до пятисот тысяч (500.000) рублей.`n`n92.2. Подделка, изготовление или оборот поддельных документов (паспортов, удостоверений, жетонов и т.д.), государственных наград, штампов, печатей или бланков –`n`nнаказывается лишением свободы на срок шесть лет (СПРП «★★★★»)."],

        ["Ст. 93", "Помеха в осуществлении деятельности сотрудника государственной власти", "Оказание помех в исполнении его служебных обязанностей, предусмотренных его должностными полномочиями, выражающееся в намеренных попытках отвлечь после вынесения сотрудником государственной власти предупреждения о недопустимости осуществления помех, –`n`nнаказывается штрафом в размере двадцати пяти тысяч (25.000) рублей или лишением свободы на срок трех лет (СПРП «★★»)."],

        ["Ст. 94", "Присвоение полномочий должностного лица", "Присвоение лицом, не являющимся должностным, полномочий должностного лица и совершение им в связи с этим действий, которые могли повлечь существенное нарушение прав и законных интересов граждан или организаций, –`n`nнаказывается штрафом в размере трехсот пятидесяти тысяч (350.000) рублей или лишением свободы на срок шести лет (СПРП «★★★»)."],

        ["Ст. 95", "Надругательство над Государственным гербом Российской Федерации или Государственным флагом Российской Федерации", "Надругательство над Государственным гербом Российской Федерации или Государственным флагом Российской Федерации, –`n`nнаказывается штрафом в размере ста тысяч (100.000) рублей или лишением свободы на срок двух лет (СПРП «★»)."],

        ["Ст. 96", "Уничтожение или повреждение объектов культурного наследия (памятников истории и культуры) народов Российской Федерации, выявленных объектов культурного наследия, природных комплексов, объектов или культурных ценностей", "96.1. Уничтожение или повреждение объектов культурного наследия (памятников истории и культуры) народов Российской Федерации, выявленных объектов культурного наследия, природных комплексов, объектов или культурных ценностей, –`n`nнаказывается штрафом в размере ста пятидесяти тысяч (150.000) рублей или лишением свободы на срок двух лет (СПРП «★★»).`n`n96.2. Деяния, предусмотренные частью первой настоящей статьи, совершенные группой лиц, группой лиц по предварительному сговору, организованной группой или преступным сообществом (преступной организацией), –`n`nнаказываются штрафом в размере трехсот тысяч (300.000) рублей или лишением свободы на срок шести лет (СПРП «★★★»)."],

        ["Ст. 97", "Надругательство, уничтожение либо повреждение воинских захоронений, а также памятников, стел, обелисков, других мемориальных сооружений или объектов, увековечивающих память погибших при защите Отечества или его интересов либо посвященных дням воинской славы России", "97.1. Надругательство, уничтожение либо повреждение расположенных на территории Российской Федерации воинских захоронений, а также памятников, стел, обелисков, других мемориальных сооружений или объектов, увековечивающих память погибших при защите Отечества или его интересов либо посвященных дням воинской славы России (в том числе мемориальных музеев или памятных знаков на местах боевых действий), а равно памятников, других мемориальных сооружений или объектов, посвященных лицам, защищавшим Отечество или его интересы, в целях причинения ущерба историко-культурному значению таких объектов, –`n`nнаказывается штрафом в размере двухсот пятидесяти тысяч (250.000) рублей или лишением свободы на срок четырех лет (СПРП «★★★★»).`n`n97.2. Деяния, предусмотренные частью первой настоящей статьи, совершенные:`nа) группой лиц по предварительному сговору или организованной группой;`nб) в отношении воинских захоронений, а также памятников, стел, обелисков, других мемориальных сооружений или объектов, увековечивающих память погибших при защите Отечества или его интересов в период Великой Отечественной войны либо посвященных дням воинской славы России в этот период (в том числе мемориальных музеев или памятных знаков на местах боевых действий), а равно памятников, других мемориальных сооружений или объектов, посвященных лицам, защищавшим Отечество или его интересы в период Великой Отечественной войны;`nв) с применением насилия или с угрозой его применения, –`n`nнаказывается штрафом в размере пятисот тысяч (500.000) рублей или лишением свободы на срок семи лет (СПРП «★★★★»)."],

        ["Ст. 98", "Надругательство над телами умерших и местами их захоронения", "98.1. Надругательство над телами умерших либо уничтожение, повреждение или осквернение мест захоронения, надмогильных сооружений или кладбищенских зданий, предназначенных для церемоний в связи с погребением умерших или их поминовением, за исключением случаев, предусмотренных статьей 98 настоящего Кодекса, –`n`nнаказывается штрафом в размере пятидесяти тысяч (50.000) рублей или лишением свободы на срок одного года (СПРП «★»).`n`n98.2. Деяния, предусмотренные частью первой настоящей статьи, совершенные:`nа) группой лиц по предварительному сговору или организованной группой;`nб) по мотивам политической, идеологической, расовой, национальной или религиозной ненависти или вражды либо по мотивам ненависти или вражды в отношении какой-либо социальной группы;`nв) с применением насилия или с угрозой его применения, –`n`nнаказываются штрафом в размере ста тысяч (100.000) рублей или лишением свободы на срок трех лет (СПРП «★★»)."],

        ["Ст. 99", "Подкуп избирателей, участников референдума", "99.1. Оказание или предложение оказания имущественных выгод избирателям, участникам референдума, иным гражданам в целях их собственного голосования либо отказа от голосования в пользу или против определенного кандидата (кандидатов), избирательного объединения, инициативы на выборах любого уровня либо референдуме, –`n`nнаказывается лишением свободы на срок шести лет (СПРП «★★★★★★»).`n`n99.2. То же деяние, совершенное:`nа) группой лиц по предварительному сговору или организованной группой;`nб) с использованием поддельных документов, обмана, угроз или иными способами ограничения свободного волеизъявления;`nв) лицом с использованием своего служебного положения, –`n`nнаказывается лишением свободы на срок восьми лет (СПРП «★★★★★★»)."]
    ]
}

    GetPKFullData() {
    return [
        ["Ст. 1", "Процессуальное законодательство", "Процессуальный кодекс - является источником процессуального права, устанавливающий и регулирующий основные общественные отношения в области уголовного, административного делопроизводства и судопроизводства. Порядок делопроизводства и судопроизводства на территории Российской Федерации устанавливается настоящим Кодексом, основанным на Конституции Российской Федерации. Настоящий Кодекс является обязательным для судов, органов прокуратуры, органов предварительного следствия и органов дознания, органов исполнительной и законодательной власти, органов государственной власти, а также иных участников делопроизводства и судопроизводства."],

        ["Ст. 2", "Действие процессуального закона в пространстве", "Производство по делу на территории Российской Федерации независимо от места совершения преступления ведется в соответствии с настоящим Кодексом и Уголовно-процессуальным кодексом Российской Федерации. При производстве по делу применяется процессуальный закон, действующий во время производства соответствующего процессуального действия или принятия процессуального решения, если иное не установлено настоящим Кодексом."],

        ["Ст. 3", "Основные понятия, используемые в настоящем Кодексе", "Если не оговорено иное, основные понятия, используемые в настоящем Кодексе, имеют следующие значения:`n1) алиби - наличие объективных обстоятельств, свидетельствующих о непричастности обвиняемого или подозреваемого к преступлению;`n2) задержание подозреваемого - мера процессуального принуждения, применяемая правоохранительным органом, органом дознания, дознавателем, следователем на небольшой срок не более 60 минут с момента фактического задержания лица по подозрению в совершении преступления;`n3) момент фактического задержания - момент производимого в порядке, установленном настоящим Кодексом, фактического лишения свободы передвижения лица, подозреваемого в совершении преступления;`n4) неотложные следственные действия - действия, осуществляемые органом дознания после возбуждения уголовного дела, по которому производство предварительного следствия обязательно, в целях обнаружения и фиксации следов преступления, а также доказательств, требующих незамедлительного закрепления, изъятия и исследования;`n5) применение меры пресечения - процессуальные действия, осуществляемые с момента принятия решения об избрании меры пресечения до ее отмены или изменения;`n6) процессуальное действие - следственное, судебное или иное действие, предусмотренное настоящим Кодексом;`n7) розыскные меры - меры, принимаемые дознавателем, следователем, а также органом дознания для установления лица, подозреваемого в совершении преступления;`n8) делопроизводство - досудебное следствие по делу, проводимое органами следствия или правоохранительными органами;`n9) судопроизводство - деятельность суда по рассмотрению уголовного дела, гражданского дела, или дела об административном правонарушении;`n10) правоохранительные органы - правоохранительными органами в Российской Федерации являются следующие органы: органы внутренних дел, войска национальной гвардии, органы государственной безопасности, органы государственной охраны, органы прокуратуры, органы следственного комитета, органы уголовно-исполнительной системы, органы Военной полиции Вооруженных сил Российской Федерации;`n11) органы следствия и или дознания - органами следствия и дознания в Российской Федерации признаются подразделения органов внутренних дел, оперативно-следственная служба Федеральной службы безопасности, следственный комитет Российской Федерации, оперативно-следственные отделы Федеральной службы исполнения наказаний."],

        ["Ст. 4", "Принципы используемые в настоящем Кодексе", "4.1. Делопроизводство имеет своим назначением:`nа) защиту прав и законных интересов лиц и организаций, потерпевших от правонарушений;`nб) защиту личности от незаконного и необоснованного обвинения, осуждения, ограничения ее прав и свобод.`n4.2. Утратила силу.`n4.3. В ходе делопроизводства запрещаются осуществление действий и принятие решений, унижающих честь участника делопроизводства, а также обращение, унижающее его человеческое достоинство либо создающее опасность для его жизни и здоровья.`n4.4. Никто не может быть задержан по подозрению в совершении преступления или заключен под стражу при отсутствии на то законных оснований, предусмотренных настоящим Кодексом. До принятия решения лицо не может быть подвергнуто задержанию на небольшой срок не более 60 минут.`n4.5. Обвиняемый считается невиновным, пока его виновность в совершении преступления не будет доказана в предусмотренном настоящим Кодексом порядке. Все сомнения в виновности обвиняемого, которые не могут быть устранены в порядке, установленном настоящим Кодексом, толкуются в пользу обвиняемого. Обвинительный приговор не может быть основан на предположениях.`n4.6. Не допускается применение доказательств при принятии решения о виновности обвиняемого или задержанного, если данные доказательства были получены с нарушением норм настоящего Кодекса либо иных нормативно-правовых актов.`n4.7. Не допускается двойное вменение за совершение одного и того же действия по логике применения."],

        ["Ст. 5", "Меры процессуального принуждения, уголовного, административного или иного воздействия", "Меры уголовного, административного и иного воздействия применяемые к гражданам Российской Федерации:`n1) вынесение предупреждения;`n2) штраф;`n3) задержание;`n4) арест;`n5) иные меры, предусмотренные уголовным и административным законодательством."],

        ["Ст. 6", "Задержание", "Задержание подозреваемого - мера процессуального принуждения, носящая внесудебный характер и не являющаяся наказанием, применяемая сотрудником правоохранительного органа, на небольшой срок не более 60 минут с момента фактического задержания лица по подозрению в совершении правонарушения."],

        ["Ст. 7", "Основания для задержания", "Сотрудники правоохранительных органов вправе задержать лицо при наличии оснований, прямо предусмотренных настоящей статьей, в том числе при задержании на месте правонарушения, указании очевидцев, наличии следов правонарушения, ориентировки, видеофиксации, розыска и иных предусмотренных случаях."],

        ["Ст. 8", "Права задержанного", "Задержанный обладает следующими правами: не свидетельствовать против себя самого, требовать государственного адвоката, требовать присутствия адвоката, консультации с адвокатом и одного телефонного звонка. Права реализуются в процессе задержания до перехода к процессу ареста."],

        ["Ст. 9", "Реализация прав задержанного", "Права задержанного реализуются последовательно. Очередность устанавливается сотрудником правоохранительного органа, проводящего задержание. Право на государственного адвоката реализуется в камерах предварительного заключения. Иные права задержанного, за исключением права не свидетельствовать против себя самого, реализуются также в помещениях следственного изолятора, камерах предварительного заключения и исправительного учреждения. Настоящая статья также регулирует порядок вызова адвоката, ожидания, телефонного звонка и конфиденциальной беседы."],

        ["Ст. 10", "Порядок проведения задержания", "Сотрудник правоохранительного органа проводит задержание в свободном порядке, но обязан применить специальные средства при необходимости, идентифицировать себя, огласить перечень статей, произвести личный обыск и доставить гражданина в орган следствия, дознания или правоохранительный орган. Кодекс также предусматривает особенности задержания сотрудника государственной организации и обязанность хранить видеофиксацию 72 часа."],

        ["Ст. 11", "Допуск на место проведения процессуальных действий", "Не допускается присутствие посторонних во время проведения процессуальных действий. Свободный проход допускается только для субъектов процессуальных действий, перечень которых установлен настоящей статьей."],

        ["Ст. 12", "Особенности проведения задержания адвокатов, работников государственных органов", "Настоящая статья регулирует особенности задержания адвокатов, государственных служащих и работников государственных органов, перечень преступлений, по которым допускается их задержание, а также основания увольнения и порядок участия СК России, прокуратуры и руководства соответствующих органов."],

        ["Ст. 13", "Полномочия субъектов процессуальных действий в рамках задержания и ареста", "Настоящая статья регулирует полномочия сотрудников правоохранительных органов, СК России, прокуратуры, ФСБ России, оперативных групп и государственных адвокатов в рамках задержания и ареста без судебного решения."],

        ["Ст. 14", "Основания для окончания задержания и освобождения", "Основаниями для окончания задержания и освобождения являются недостаточность доказательств, отсутствие санкции в виде лишения свободы либо истечение максимально допустимого времени задержания."],

        ["Ст. 15", "Доказательства и доступ к доказательствам", "Сотрудник, производящий задержание, обязан предоставить доступ к доказательствам в объеме и порядке, установленном настоящей статьей, адвокату, суду, органам СК России, прокуратуры и иным уполномоченным субъектам."],

        ["Ст. 16", "Задержание и арест сотрудниками оперативно-следственной службы при сокрытии причастности к Федеральной службе безопасности", "Сотрудники оперативно-следственной службы Федеральной службы безопасности при сокрытии причастности к ФСБ вправе проводить задержание и арест в случаях, предусмотренных настоящей статьей."],

        ["Ст. 17", "Статус неприкосновенности и правовой защиты", "Лицо, обладающее статусом неприкосновенности или правовой защиты, не может быть задержано или подвергнуто мерам принуждения, кроме случаев, прямо предусмотренных настоящим Кодексом."],

        ["Ст. 18", "Арест", "Арест - мера лишения свободы с момента установления факта вины и начала содержания преступника в следственном изоляторе, камере предварительного заключения либо исправительной колонии. Настоящая статья также устанавливает порядок проведения ареста и требования к личному делу."],

        ["Ст. 19", "Личный обыск", "Личный обыск производится при наличии достаточных оснований полагать, что у лица могут находиться предметы или документы, имеющие значение для установления факта вины или невиновности. Настоящая статья также регулирует конфискацию отдельных предметов и случаи проведения личного обыска."],

        ["Ст. 20", "Обыск жилища и транспортного средства", "Проведение обыска жилища или транспортного средства допускается при наличии ордера либо в иных случаях, прямо предусмотренных настоящей статьей."],

        ["Ст. 21", "Законное требование", "Перед выдвижением законного требования сотрудник обязан обозначить свою принадлежность к государственному органу и представиться в установленном порядке. Законное требование или распоряжение - это требование, основанное на нормативных правовых актах, выраженное в устной или письменной форме."],

        ["Ст. 22", "Передача процессуальных действий", "Если сотрудник по объективным причинам не может или не уполномочен продолжать задержание, он обязан передать его уполномоченному сотруднику с изложением обстоятельств и передачей видеоматериалов."],

        ["Ст. 23", "Отстранение государственного служащего от занимаемой должности", "Отстранение работника государственной организации от занимаемой должности производит сотрудник органов СК России, сотрудник органов прокуратуры или суд в соответствии с законодательством Российской Федерации."],

        ["Ст. 24", "Право на применение физической силы, специальных средств и огнестрельного оружия", "Сотрудник государственного органа имеет право на применение физической силы, специальных средств и огнестрельного оружия лично или в составе подразделения в случаях и порядке, предусмотренных законодательством."],

        ["Ст. 25", "Применение физической силы, специальных средств и вооружения", "Сотрудник государственного органа имеет право на применение физической силы, специального снаряжения и вооружения для целей задержания, ареста и защиты жизни и здоровья в рамках действующего законодательства."],

        ["Ст. 26", "Право на ношение, хранение и применение огнестрельного оружия", "Сотрудники полиции, ФСИН, Росгвардии, ФСБ, ФСО, Вооруженных Сил Российской Федерации, прокуратуры, Следственного комитета и иные лица в соответствии с законодательством имеют право на ношение, хранение и применение огнестрельного оружия при исполнении служебных обязанностей."],

        ["Ст. 56", "Причины остановки транспортных средств", "Перечень причин остановки транспортных средств: нарушение уголовного или административного законодательства, нарушение правил дорожного движения, проверка документов."],

        ["Ст. 57", "Порядок остановки транспортных средств", "Настоящая статья устанавливает порядок остановки транспортных средств уполномоченными представителями ГИБДД и в отдельных случаях иными сотрудниками государственных органов, включая использование специальных сигналов, рупора и применение имеющихся сил и средств для остановки преступника."],

        ["Ст. 58", "Процессуальные действия сотрудников ГИБДД", "Настоящая статья устанавливает порядок действий сотрудников ГИБДД и ЦОДД при обращении к водителю, проверке документов, сообщении причины остановки и продолжении процессуальных действий."],

        ["Ст. 59", "Предписания сотрудников ГИБДД", "Уполномоченный сотрудник ГИБДД оформляет протокол об административном правонарушении, дополнительно заполняет бланк предписания и передает его адресату. На исполнение предписания отводится 24 часа."],

        ["Ст. 60", "Задержание транспортных средств", "Использование эвакуационных средств допускается уполномоченными сотрудниками ГИБДД и ЦОДД. Причины и ограничения задержания транспортных средств устанавливаются настоящей статьей."],

        ["Ст. 61", "Судьи и органы, уполномоченные рассматривать дела об административных правонарушениях", "Настоящая статья устанавливает перечень судов и органов, уполномоченных рассматривать дела об административных правонарушениях в пределах своей компетенции."],

        ["Ст. 62", "Протокол об административном правонарушении", "О совершении административного правонарушения составляется протокол, за исключением случаев, прямо предусмотренных законом. Настоящая статья устанавливает порядок оформления протокола."],

        ["Ст. 63", "Ведение дела об административном правонарушении", "Сотрудник государственного органа, уполномоченный на ведение дел об административных правонарушениях, вправе требовать предоставления документов, имеющих отношение к делу, в порядке, установленном настоящей статьей."],

        ["Ст. 64", "Положение об использовании приборов выявления содержания алкогольной продукции в крови", "Использование алкотестеров допускается только сотрудниками правоохранительных или медицинских органов. Настоящая статья определяет порядок и цели использования алкотестеров."]
    ]
}
    GetPhrasesData() => [
        ["Здравия желаю! Рядовой [Фамилия]. Предъявите документы."],
        ["Гражданин, вы находитесь на охраняемой территории. Покиньте её."],
        ["Отойдите от КПП на 15 метров, это Желтая Зона."],
        ["Считаю до десяти! Если не покинете — открою огонь!"],
        ["Покиньте транспортное средство для досмотра."],
        ["Цель вашего визита?"],
        ["Ожидайте, я доложу старшему по званию."],
        ["Порядок действий при провокации: сохранять спокойствие, не вступать в конфликт, зафиксировать нарушение и доложить старшему по званию."]
    ]

    GetFZ86FullData() {
        return [
            ["Ст. 1", "Основные понятия", "1.1. Для целей настоящего Федерального закона используются следующие основные понятия:`n1) охраняемая территория - это место, находящееся под охраной той или иной структуры, с ограниченным или запрещенным доступом гражданским лицам;`n2) закрытая территория - это место с закрытым доступом для гражданских лиц, а также с частично ограниченным доступом для государственных сотрудников. Каждое подобное место обладает своими ограничениями;`n3) государственные территории - это области, закрепленные за государственными организациями, в которых регулируются правовые нормы поведения и соблюдения техники безопасности на том или ином объекте;`n4) зеленая зона - определяет свободное передвижение граждан, является зоной общего порядка;`n5) зона ограниченного доступа - охраняемая территория;`n6) зона строгого режима - закрытая для общего пользования территория.`n`n1.2. Названия структур:`n1) Управление ФСБ`n2) Управление ФСВНГ`n3) Вооруженные Силы РФ`n4) Управление внутренних дел по ЦАО`n5) УГИБДД`n6) ФСО России`n7) ВГТРК Москва Live`n8) ГБУЗ ЦГБ № 3 и № 7."],
            ["Ст. 2", "Государственная собственность", "2.1. Государственной собственностью в Российской Федерации является имущество, принадлежащее на праве собственности Российской Федерации (федеральная собственность).`n2.2. Земля и другие ресурсы и объекты, не находящиеся в собственности граждан, юридических лиц, являются государственной собственностью.`n2.3. От имени Российской Федерации права собственника осуществляют органы и лица, установленные актами Председателя Правительства Российской Федерации."],
            ["Ст. 3", "Об объектах в собственности РФ", "3.1. От имени Российской Федерации Председатель Правительства РФ, Правительство РФ осуществляют права собственника в отношении государственной собственности.`n3.2. Председатель Правительства РФ, Правительство РФ через нормативные акты определяют допуск к государственной собственности.`n3.3. Они вправе присваивать статус охраняемой и (или) закрытой территории."],
            ["Ст. 4", "Допуск к закрытой и охраняемой территории", "4.1. Председатель Правительства РФ, Председатель СФ, Председатель ГД имеют право проходить на все закрытые и охраняемые территории. Такими же правами наделены Заместители Председателя, судьи РФ, Генпрокурор и его замы, Председатель СК и его замы.`n4.2. Федеральные министры обладают правом на прохождение на закрепленные за ними территории.`n4.3. Во время проведения проверок, сотрудники, осуществляющие проверку, вправе проходить на закрытые территории.`n4.4. Во время надзорных мероприятий сотрудники органов прокуратуры вправе проходить на закрытые территории.`n4.5. Сотрудники ФСО вправе проходить на закрытые территории в сопровождении лиц, наделенных таким правом.`n4.6. Сотрудники ГБУЗ вправе проходить на закрытые территории с целью оказания медицинской помощи с обязательной фиксацией веской причины. При первом требовании обязаны покинуть территорию.`n4.7. Следователи при осуществлении следственных действий или в целях задержания имеют право проходить на закрытые территории."],
            ["Ст. 5", "Регламент допуска закрытых и охраняемых территорий", "5.1. Допуск к закрытым и охраняемым территориям устанавливается настоящим ФЗ.`n5.2. Во время исполнения служебных обязанностей по служебной необходимости сотрудники гос. организаций вправе проходить на закрытые и охраняемые территории.`n5.3. Сотрудник гос. организации, прошедший на территорию по служебной необходимости, обязан ее озвучить по первому требованию, если она не составляет гостайну."],
            ["Ст. 6", "О закреплении государственных территорий", "6.1. Государственные территории регулируются Правительством РФ.`n6.2. Правительство устанавливает право допуска для государственных структур.`n6.3. Государственными территориями являются: Московский Кремль; УФСБ; МВД; УФСВНГ; ВГТРК; ГБУЗ; Войсковые части; склады; казенные учреждения."],
            ["Ст. 7", "Право прохождения сотрудников на закрепленные территории", "7.1. Сотрудники государственных организаций имеют свободный доступ к закрепленным за ними территориям.`n7.2. Сотрудники федеральных органов исполнительной власти имеют свободный доступ к закрепленным за ними территориям."],
            ["Ст. 8", "Московский Кремль", "8.1. Закрытыми для общего пользования являются:`n1) кабинеты Правительства РФ;`n2) кабинеты СК РФ;`n3) кабинеты Прокуратуры;`n4) кабинеты ФСО.`n8.2. Охраняемыми территориями являются: общая территория Кремля и холлы указанных зданий."],
            ["Ст. 9", "Допуск к территории Московского Кремля", "Описывает правила доступа на территорию Московского Кремля для первых лиц, депутатов и сотрудников ФСО, а также право распоряжения имуществом Кремля."],
            ["Ст. 10", "Территория Управления ФСБ", "10.1. Закрытыми являются: внутренний двор, кабинеты, блоки камер предварительного содержания УФСБ.`n10.2. Охраняемыми являются: холл и подъезд к внутреннему двору."],
            ["Ст. 11", "Допуск к территории ФСБ", "Допуск имеют Председатель Правительства, сотрудники ФСБ и иные лица по приглашению. Нарушение правил влечет ответственность."],
            ["Ст. 12", "Территория УФСВНГ (Росгвардия)", "12.1. Вся территория управления является закрытой.`n12.2. Охраняемой территорией является прилегающая территория."],
            ["Ст. 13", "Допуск к территории УФСВНГ", "Пропускной режим определяется настоящим законом. Нарушение правил влечет ответственность."],
            ["Ст. 14", "Территории органов МВД", "Описывает закрытые территории (дворы, кабинеты, КПЗ) и охраняемые территории (парковки, холлы) УВД по ЦАО и УГИБДД."],
            ["Ст. 15", "Допуск к территории МВД", "Доступ имеют сотрудники соответствующих отделов МВД, руководство Правительства и лица по приглашению."],
            ["Ст. 16", "Территория ВГТРК Москва Live", "Закрытыми являются кабинеты и помещения, охраняемой - холл ВГТРК."],
            ["Ст. 17", "Допуск к территории ВГТРК", "Доступ для сотрудников ВГТРК, министерства социальной политики и лиц по приглашению."],
            ["Ст. 18", "Территории ГБУЗ (Больницы)", "Кабинеты ГБУЗ №3 и №7 являются закрытыми. Холлы, парковки и проходы к палатам - охраняемыми."],
            ["Ст. 19", "Допуск к территории ГБУЗ", "Доступ для медработников и министерства соц. политики."],
            ["Ст. 19-1", "Территории ЦОДД", "Описывает закрытые (внутренний двор, склад, кабинеты) и охраняемые (холл, парковка) территории ЦОДД."],
            ["Ст. 19-2", "Допуск к территории ЦОДД", "Доступ имеют сотрудники ЦОДД, Министерства Транспорта и первые лица государства."],
            ["Ст. 20", "Территория Вооруженных Сил РФ", "20.1. Территории войсковых частей, огражденные сплошным периметром забора, являются ЗАКРЫТЫМИ.`n20.2. ОХРАНЯЕМЫМИ территориями являются: КПП и парковочные комплексы перед ними, а также военные комиссариаты.`n20.3. Призывные пункты закрыты на период их функционирования."],
            ["Ст. 21", "Допуск к территориям войсковых частей", "21.3. Допуск к закрытой территории определяется пропускным режимом.`n21.4. На охраняемую территорию (КПП) вправе проходить любые лица при соблюдении правил.`n21.5. Допуск разрешается сотрудникам гос. структур с целью общего сбора для оказания снабжения по предварительному озвучиванию в рацию."],
            ["Ст. 22", "Территория КПЗ", "Закрытыми являются помещения, кабинеты, блоки камер предварительного заключения и содержания."],
            ["Ст. 23", "Допуск к территории КПЗ", "Допуск имеют субъекты задержания при проведении процессуальных действий."],
            ["Ст. 24", "Территория учреждений исполнения наказаний", "Вся территория тюрем - закрытая. Охраняемая - парковка и прилегающая территория 15 метров от забора."],
            ["Ст. 25", "Допуск к территории тюрем", "Допуск имеют Минюст, Прокурор, начальник ФСБ. Остальные гос. сотрудники - по разовому пропуску."],
            ["Ст. 26", "Проход адвокатов", "Адвокат обязан предъявить удостоверение, паспорт и назвать клиента. Сотрудники ФСИН сопровождают его в комнату свиданий. Свободное перемещение запрещено."],
            ["Ст. 27", "Проход родственников", "Посетитель обязан предъявить паспорт и документ родственных связей. Перемещение только в сопровождении до комнаты свиданий."],
            ["Ст. 28", "Территории государственных хранилищ и складов", "28.1. Территория всех страт. объектов закрыта.`n28.2. Объекты: ЗМХ, ГСМО, МС, Объект №7, РЛС Орбита, Зарайский кремль, ЦМС.`n28.4. Охрана осуществляется ФСБ и ФСО (при содействии Армии и МВД)."],
            ["Ст. 29", "Допуск к хранилищам", "Допуск к закрытой территории стратегически важных объектов имеют сотрудники всех гос. организаций."],
            ["Ст. 30", "О пропускном режиме", "Пропускной режим – это совокупность мер для контроля доступа лиц и транспорта."],
            ["Ст. 31", "Виды пропусков", "31.1. Виды: Постоянный, Служебный, Временный, Разовый, Материальный.`n31.3. При пропускном режиме сотрудники уполномочены: проверять документы, проводить личный обыск и обыск авто. При отказе - отказать в посещении и потребовать покинуть территорию."]
        ]
    }

    GetFZ52FullData() {
        return [
            ["Ст. 1", "Основы обороны", "1.1. В настоящем Федеральном законе под обороной понимается система политических, экономических, военных, социальных, правовых и иных мер по подготовке к вооруженной защите и вооруженная защита Российской Федерации, целостности и неприкосновенности ее территории.`n1.2. Оборона организуется и осуществляется в соответствии с Конституцией Российской Федерации, федеральными конституционными законами, федеральными законами, настоящим Федеральным законом, законами Российской Федерации и иными нормативными правовыми актами.`n1.3. В целях обороны создаются Вооруженные Силы Российской Федерации.`n1.4. Создание и существование формирований, имеющих военную организацию или вооружение и военную технику либо в которых предусматривается прохождение военной службы, не предусмотренных федеральными законами, запрещаются и преследуются по закону."],
            ["Ст. 2", "Законодательство Российской Федерации в области обороны", "Законодательство Российской Федерации в области обороны основывается на Конституции Российской Федерации и включает в себя федеральные конституционные законы, федеральные законы, настоящий Федеральный закон."],
            ["Ст. 3", "Руководство и управление Вооруженными Силами Российской Федерации", "3.1. Общее руководство Вооруженными Силами Российской Федерации осуществляет Председатель Правительства Российской Федерации.`n3.2. Руководство Вооруженными Силами Российской Федерации осуществляет Министр обороны Российской Федерации и его заместители. Министр обороны Российской Федерации подчиняется непосредственно Председателю Правительства Российской Федерации и его заместителям.`n3.3. Управление территориальными органами Вооруженными Силами Российской Федерации (войсковыми частями) осуществляют командиры бригад. Командиры бригад подчинены Председателю Правительства Российской Федерации и его заместителям, Министру обороны и его заместителям.`n3.4. Правительство Российской Федерации утверждает Устав территориальных органов Вооруженными Силами Российской Федерации (войсковых частей); знамя и Вооруженными Силами Российской Федерации, положения о них, их описания и рисунки в соответствии с актами Председателя Правительства Российской Федерации."],
            ["Ст. 4", "Вооруженные Силы Российской Федерации и их предназначение", "Вооруженные Силы Российской Федерации являются составной частью военной организации государства и предназначены для вооруженной защиты национальных интересов, суверенитета, целостности и неприкосновенности территории Российской Федерации военными методами, а также для выполнения задач в соответствии с актами Председателя Правительства Российской Федерации."],
            ["Ст. 5", "Правовая основа деятельности Вооруженных Сил Российской Федерации", "Правовую основу деятельности Вооруженных Сил Российской Федерации составляют Конституция Российской Федерации, настоящий Федеральный закон, другие федеральные законы, нормативные правовые акты Председателя Правительства Российской Федерации, Правительства Российской Федерации, а также нормативные правовые акты федерального органа исполнительной власти в сфере обороны и иные нормативные правовые акты Российской Федерации, регулирующие деятельность Вооруженных Сил Российской Федерации."],
            ["Ст. 6", "Основные задачи Вооруженных Сил Российской Федерации", "6.1. Основными задачами Вооруженных Сил Российской Федерации являются:`n1) предотвращение и отражение агрессии против Российской Федерации и ее союзников;`n2) участие в защите государственной границы Российской Федерации и ее охрана в воздушном пространстве и подводной среде;`n3) обеспечение национальных интересов Российской Федерации;`n4) организация и ведение территориальной обороны, участие в обеспечении режимов военного и чрезвычайного положений;`n5) организация на подведомственной территории вооруженных сил Российской Федерации патрульно-постовой службы и блокпостов на дорогах идущих из городской части в областную с целью обеспечения безопасности гражданского населения и военнослужащих в области.`n6.2. Иные задачи Вооруженных Сил Российской Федерации устанавливаются нормативными актами Председателя Правительства Российской Федерации."],
            ["Ст. 7", "Привлечение Вооруженных Сил Российской Федерации к выполнению задач с использованием вооружения не по их предназначению", "7.1. Вооруженные Силы Российской Федерации могут привлекаться к выполнению задач с использованием вооружения не по их предназначению на основании решения Председателя Правительства Российской Федерации.`n7.2. Вооруженные Силы Российской Федерации для выполнения поставленных задач могут применять имеющиеся в их распоряжении силы и средства, при этом физическая сила, специальные средства, оружие, боевая и специальная техника применяются в случаях и порядке, установленном федеральными законами и иными нормативными правовыми актами Российской Федерации."],
            ["Ст. 8", "Имущество Вооруженных Сил Российской Федерации", "8.1. Имущество Вооруженных Сил Российской Федерации является федеральной собственностью и может находится в Вооруженных Силах Российской Федерации в оперативном управлении или на правах хозяйственного ведения и вооруженной охране.`n8.2. Порядок пользования имуществом Вооруженных Сил Российской Федерации определяется в соответствии с законодательством о государственном имуществе."],
            ["Ст. 9", "Соблюдение и уважение прав и свобод человека", "9.1. При обращению к лицу, при обращении лица к военнослужащему Вооруженных Сил Российской Федерации военнослужащий Вооруженных Сил Российской Федерации обязан назвать свои должность, звание, фамилию, предъявить по просьбе гражданина служебное удостоверения.`n9.2. Сотрудники, находящиеся при исполнении обязанностей, предусматривающих засекречивание своей личности обязаны предоставить жетон и назвать позывной и номер жетона обратившемуся. Образцы жетонов устанавливаются Правительством Российской Федерации."],
            ["Ст. 10", "Основы деятельности Вооруженных Сил Российской Федерации", "10.1. Деятельность Вооруженных Сил Российской Федерации включает: комплектование личным составом, размещение (дислокацию) войск (сил), поддержание боевой и мобилизационной готовности, боевое дежурство, боевую службу и службу оперативных дежурных, оперативную, боевую и мобилизационную подготовку войск (сил), разведывательную деятельность, службу войск, подготовку кадров и выполнение возложенных задач, а также всестороннее обеспечение войск (сил).`n10.2. Комплектование Вооруженных Сил Российской Федерации осуществляется в соответствии с законодательством Российской Федерации военнослужащими путем добровольного поступления граждан на военную службу по контракту.`n10.3. Ответственность за призыв на военную службу, направление в Вооруженные Силы Российской Федерации несет Военный Комиссариат."],
            ["Ст. 11", "Обязанности Вооруженных Сил Российской Федерации", "11.1. На Вооруженные Силы Российской Федерации возлагаются следующие обязанности:`n1) обеспечивать безопасность на охраняемых в соответствии с законодательством Российской Федерации объектах;`n2) обеспечивать правоохранительные структуры Российской Федерации вооружением и боеприпасами;`n3) поддерживать боеготовность и обороноспособность Российской Федерации;`n4) обеспечивать безопасность и сохранение режимности войсковых частей;`n5) принимать меры по организации деятельности органов военной полиции, предупреждения правонарушений среди военнослужащих;`n6) участвовать в обеспечении режима военного положения и режима чрезвычайного положения в случае их введения на территории Российской Федерации или в отдельных ее местностях.`n11.2. Иные обязанности возлагаются на Вооруженные Силы Российской Федерации в соответствии с законодательством Российской Федерации, нормативными правовыми актами Председателя Правительства Российской Федерации.`n11.3. Порядок выполнения возложенных на Вооруженные Силы Российской Федерации обязанностей определяется Министерством обороны."],
            ["Ст. 12", "Права Вооруженных Сил Российской Федерации", "Вооруженным Силам Российской Федерации для выполнения возложенных на них обязанностей предоставляются права, предусмотренные настоящим Федеральным законом и иными нормативными правовыми актами."],
            ["Ст. 13", "Поддержание боевой и мобилизационной готовности Вооруженных Сил Российской Федерации", "Министерство обороны Российской Федерации осуществляет планирование боевой и мобилизационной готовности Вооруженных Сил Российской Федерации."],
            ["Ст. 14", "Ускоренная военная подготовка", "Гражданин Российской Федерации, находящийся на службе в правоохранительных структурах и годный к военной службе, вправе заключить договор об ускоренной военной подготовке."],
            ["Ст. 15", "Права и обязанности гражданина, проходящего ускоренную военную подготовку", "На гражданина, проходящего ускоренную военную подготовку, распространяются права и обязанности военнослужащего по контракту."],
            ["Ст. 16", "Служба войск", "Служба войск регламентирует повседневную деятельность Вооруженных Сил Российской Федерации по поддержанию внутреннего порядка, безопасности военной службы и условий жизни военнослужащих."],
            ["Ст. 17", "Применение оружия, специальных средств и физической силы", "Военнослужащие Вооруженных Сил Российской Федерации имеют право на хранение, применение и использование оружия и специальных средств, а также применение физической силы."],
            ["Ст. 18", "Порядок пользования воздушным пространством", "Пользование воздушным пространством Российской Федерации Вооруженными Силами Российской Федерации осуществляется в соответствии с законодательством."],
            ["Ст. 19", "Обеспечение вооружением, военной техникой и другими материальными средствами", "Обеспечение Вооруженных Сил Российской Федерации вооружением, военной техникой и другими материальными средствами организует командир войсковой части."],
            ["Ст. 20", "Ответственность за препятствование Вооруженным Силам Российской Федерации в выполнении задач в области обороны", "Препятствование Вооруженным Силам Российской Федерации в выполнении задач в области обороны не допускается."],
            ["Ст. 21", "Физическая форма военнослужащих", "Военнослужащие Вооруженных Сил Российской Федерации обязаны следить за своим состоянием здоровья и регулярно проходить медицинский осмотр."],
            ["Ст. 22", "Судебный, прокурорский надзор", "Судебный и прокурорский надзор за деятельностью Вооруженных Сил Российской Федерации осуществляется в соответствии с федеральными законами."],
            ["Ст. 23", "Государственный контроль", "Государственный контроль за деятельностью Вооруженных Сил Российской Федерации осуществляют Председатель Правительства Российской Федерации, его заместители, Правительство Российской Федерации и Министр обороны."]
        ]
    }
}

global ui := MemoUI()
ShowWelcomeScreen(ui)
OnExit(ui.Destroy.Bind(ui))

ShowWelcomeScreen(uiObj) {
    shouldShow := IniRead(uiObj.iniFile, "Settings", "ShowWelcome", 1)
    if (shouldShow = 0)
        return

    wGui := Gui("-MinimizeBox -MaximizeBox +AlwaysOnTop", "Информация | Army Helper")
    wGui.BackColor := "111315"
    wGui.SetFont("s10 cE8EDF3", "Segoe UI")

    wGui.AddText("x0 y0 w820 h58 Background171B20", "")
    wGui.SetFont("s16 Bold cE8EDF3", "Segoe UI")
    wGui.AddText("x22 y16 w420 h24 BackgroundTrans", "ARMY HELPER • Памятка")
    wGui.SetFont("s10 cA2ACB8", "Segoe UI")
    wGui.AddText("x22 y36 w420 h18 BackgroundTrans", "Быстрый справочник и служебные инструменты")

    tabs := wGui.AddTab3("x18 y74 w784 h498 -Theme Background171A1F", ["   Описание   "])
    tabs.UseTab(1)

    rawText := "
    (
    ГОРЯЧИЕ КЛАВИШИ
    [{KEY}] — открыть / скрыть главное меню
    [Esc] — быстро скрыть меню

    ЧТО НОВОГО
    • Добавлен режим «Новобранец».
    • Во вкладке законов есть ФЗ-86 и ФЗ-52.
    • Во вкладке Кодексы теперь можно читать статьи в расширенном режиме.
    • Внизу окна появились подсказки по текущей вкладке.
    • Быстрые фразы по клавишам настраиваются через отдельное окно выбора.

    ОСНОВНЫЕ ВОЗМОЖНОСТИ
    • Быстрый доступ к правилам КПП, кодексам, ФЗ и тен-кодам.
    • Полные тексты статей можно читать прямо в окне скрипта.
    • Генератор докладов, таймеры, уведомления и патрульный блок.
    • Напоминания об обеде и призывах поверх игры.
    )"

    finalText := StrReplace(rawText, "{KEY}", uiObj.menuKey)

    wGui.SetFont("s11 cE8EDF3", "Segoe UI")
    wGui.AddText("x38 y110 w744 R19 BackgroundTrans", finalText)

    wGui.AddText("x38 y440 w744 h1 0x10")
    wGui.SetFont("s10 cA2ACB8", "Segoe UI")
    wGui.AddText("x38 y454 w360 h34 BackgroundTrans", "Разработка и идея: Корвинус Даниил`nВерсия скрипта: 4.8")

    chkShow := wGui.AddCheckbox("x38 y515 Checked1 cE8EDF3", "Показывать это окно при запуске")

    wGui.SetFont("s10 Bold cBlack", "Segoe UI")
    btn := wGui.AddButton("x618 y504 w150 h38", "Начать работу")
    btn.OnEvent("Click", (*) => (
        IniWrite(chkShow.Value, uiObj.iniFile, "Settings", "ShowWelcome"),
        wGui.Destroy()
    ))

    wGui.Show("w820 h560 Center")
}

#HotIf ui.shown
Esc::ui.Hide()
#HotIf