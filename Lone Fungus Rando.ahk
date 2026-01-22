; File: random_item_giver.ahk
#Requires AutoHotkey v2.0

; ============================================================
; Launch Lone Fungus
; ============================================================
if !WinExist("Lone Fungus")
    Run "C:\Users\Cherl\OneDrive\Desktop\Lone Fungus.url"

; Wait 1.5 minutes (90000ms) before starting to check if the game is closed
SetTimer(StartGameMonitoring, -90000)

StartGameMonitoring() {
    SetTimer(CheckGameStatus, 3000)
}

CheckGameStatus() {
    if !WinExist("Lone Fungus") {
        ; Game is closed, so close the script
        ExitApp
    }
}

; ============================================================
; Item-to-Boss Mapping
; ============================================================
global itemMap := Map(
    "forward_dash",         "Queen Evil Eye",
    "upwards_dash",         "Screw King",
    "meteor_strike",        "Goblin Chieftain",
    "mushmover_infusion",   "Warrior Statue",
    "mushmover_spell",      "Magus Statue",
    "spin_jump",            "Rogue Armadillo",
    "acid_sandals",         "Acid Weeper",
    "blue_key_infusion",    "Big Evil Flower",
    "crouch_jump",          "Screw Sentinel",
    "fire_bounce",          "Fire Wyrm",
    "magnetic_fungus",      "General Spikey",
    "wallbounce",           "Acid Queen Crawler",
    "groundbounce",         "Rocket Pengu",
    "magic_crouch_jump",    "Huge Wall Clinger",
    "great_slash",          "Ghost Lord",
    "great_spin_slash",     "Great Electro Hive",
    "silver_ornament",      "Arcane Master",
    "teleportation_wand",   "Red Queen Crawler",
    "boost_projectile",     "Big Butterfly",
    "bouncy_spore",         "The Big Germ",
    "vibrant_crystal",      "Ice Elemental Lord",
    "acid_hammer",          "Shelldon",
    "spicy_nut",            "Fire Elemental Lord",
    "spark_ball",           "Electric Elemental Lord",
    "golden_light",         "Big Mine Demon",
    "returning_contraption", "Corrupt Falafel",
    "bouncy_ball",          "Master Blockmonster",
    "berserker",            "Lord of Darkness"
)

; ============================================================
; Item Pool (main only)
; ============================================================
global allItems := [
    "sword","forward_dash","upwards_dash","meteor_strike","magic_dash",
    "mushmover_infusion","mushmover_spell","astral_mushmover","healing_fungus",
    "shield_cap","wallbounce","groundbounce","spin_jump","fire_bounce",
    "great_slash","great_spin_slash","crouch_jump","magic_crouch_jump",
    "silver_ornament","royal_ornament","teleportation_wand","blue_key_infusion",
    "water_breath","dash_crystal","magnetic_fungus","acid_sandals","power_extractor",
    "bouncy_spore","bouncy_ball","boost_projectile","acid_hammer","berserker",
    "spicy_nut","golden_light","returning_contraption","spark_ball","vibrant_crystal"
]

; ============================================================
; Logic Pool Setup
; ============================================================
global logicPoolPhase := 1
global logicPressCount := 0
global logicpool := [
    "sword","spin_jump","great_slash","bouncy_spore","bouncy_ball","boost_projectile",
    "acid_hammer","spicy_nut","golden_light","returning_contraption","spark_ball","vibrant_crystal"
]

; ============================================================
; Persistence
; ============================================================
global saveFile := A_ScriptDir . "\given_items.txt"
global logicSaveFile := A_ScriptDir . "\logic_pool.ini"
global givenItems := []
global remainingItems := []

global ItemImageDir := A_ScriptDir "\Rando Get"
global FadeSteps := 20
global FadeInTime := 300
global HoldTime := 1000
global FadeOutTime := 900

global ItemGui := 0
global FadeStep := 0
global FadeMode := ""
global CurrentFadeIn := 300
global CurrentFadeOut := 900
global CurrentHoldTime := 1000

; ============================================================
; Removal GUI Globals
; ============================================================
global RemoveGui := 0
global selectedIndex := 1
global availableRemoveItems := []
global removalGuiActive := false
global buttonRefs := []  ; Store button references with their commands
global currentItemsPerRow := 5

; ============================================================
; Input Blocking System
; ============================================================
global inputBlocked := false

blockInput(duration := 1000) {
    global inputBlocked
    inputBlocked := true
    SetTimer(unblockInput, -duration)
}

unblockInput() {
    global inputBlocked
    inputBlocked := false
}

; ============================================================
; Helpers
; ============================================================
findIndex(arr, val) {
    for i, v in arr
        if (v = val)
            return i
    return 0
}

arrayContains(arr, val) => findIndex(arr, val) != 0

; ----------------------------
; Logic pool persistence (INI)
; ----------------------------
saveLogicState() {
    global logicSaveFile, logicpool, logicPoolPhase, logicPressCount
    global starterKitPhase, dashFlip

    try {
        ; Store scalar state
        IniWrite(logicPoolPhase, logicSaveFile, "LogicPool", "Phase")
        IniWrite(logicPressCount, logicSaveFile, "LogicPool", "PressCount")
        IniWrite(starterKitPhase, logicSaveFile, "LogicPool", "StarterKitPhase")
        IniWrite(dashFlip, logicSaveFile, "LogicPool", "DashFlip")

        ; Store pool as a single delimited string
        poolStr := ""
        for _, v in logicpool {
            poolStr .= (poolStr = "" ? "" : "|") . v
        }
        IniWrite(poolStr, logicSaveFile, "LogicPool", "Pool")
    }
}

loadLogicState() {
    global logicSaveFile, logicpool, logicPoolPhase, logicPressCount
    global starterKitPhase, dashFlip

    if !FileExist(logicSaveFile)
        return false

    try {
        logicPoolPhase := Integer(IniRead(logicSaveFile, "LogicPool", "Phase", "1"))
        logicPressCount := Integer(IniRead(logicSaveFile, "LogicPool", "PressCount", "0"))
        starterKitPhase := Integer(IniRead(logicSaveFile, "LogicPool", "StarterKitPhase", "1"))
        dashFlip := Integer(IniRead(logicSaveFile, "LogicPool", "DashFlip", "0"))
        poolStr := IniRead(logicSaveFile, "LogicPool", "Pool", "")

        if (Trim(poolStr) = "")
            return false

        logicpool := []
        for _, part in StrSplit(poolStr, "|") {
            p := Trim(part)
            if (p != "")
                logicpool.Push(p)
        }

        return logicpool.Length > 0
    }
}

writeGiven(item) {
    global saveFile
    file := FileOpen(saveFile, "a", "UTF-8")
    if file {
        file.Write(item . "`n")
        file.Close()
    }
}

showTooltip(text, duration := 1200) {
    ToolTip(text)
    SetTimer(() => ToolTip(""), -duration)
}

ShowItemOverlay(item, dir := "", ext := "jpg", fadeIn := 300, fadeOut := 900, hold := 1000) {
    global ItemImageDir, ItemGui, FadeStep, FadeMode
    global CurrentFadeIn, CurrentFadeOut, CurrentHoldTime, FadeSteps

    ; Prevent interruption during GUI creation
    Critical

    ; Stop any active fade timer immediately
    SetTimer(FadeTick, 0)
    
    ; Mark as in-setup so any stray timer ticks abort
    FadeMode := "setup"

    ; Set current timing for this overlay
    CurrentFadeIn := fadeIn
    CurrentFadeOut := fadeOut
    CurrentHoldTime := hold

    ; Default to global ItemImageDir if not specified (legacy behavior)
    useDir := (dir != "") ? dir : ItemImageDir

    imgPath := useDir "\" item "." ext
    if !FileExist(imgPath)
        return

    if IsObject(ItemGui)
        ItemGui.Destroy()

    ItemGui := Gui("+AlwaysOnTop -Caption -DPIScale +E0x20")
    ItemGui.BackColor := "Black"

    pic := ItemGui.AddPicture("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight, imgPath)

    ItemGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NoActivate")

    WinSetTransparent(0, ItemGui.Hwnd)

    FadeStep := 0
    FadeMode := "in"
    SetTimer(FadeTick, CurrentFadeIn / FadeSteps)
    Critical("Off")
}

FadeTick() {
    global ItemGui, FadeStep, FadeMode, FadeSteps, CurrentHoldTime
    global CurrentFadeIn, CurrentFadeOut

    if !IsObject(ItemGui) || (FadeMode = "setup")
        return

    if (FadeMode = "in") {
        FadeStep++
        try {
            WinSetTransparent(Round(FadeStep * (255 / FadeSteps)), ItemGui.Hwnd)
        } catch {
            return
        }

        if (FadeStep >= FadeSteps) {
            SetTimer(FadeTick, 0)
            FadeMode := "hold"
            SetTimer(FadeTick, -CurrentHoldTime)
        }

    } else if (FadeMode = "hold") {
        FadeMode := "out"
        FadeStep := FadeSteps
        SetTimer(FadeTick, CurrentFadeOut / FadeSteps)

    } else if (FadeMode = "out") {
        FadeStep--
        try {
            WinSetTransparent(Round(FadeStep * (255 / FadeSteps)), ItemGui.Hwnd)
        } catch {
            return
        }

        if (FadeStep <= 0) {
            SetTimer(FadeTick, 0)
            ItemGui.Destroy()
            ItemGui := 0
        }
    }
}

; ============================================================
; Core Macro Function
; ============================================================
giveCommand(item) {
    ShowItemOverlay(item) ; Uses default Rando Get .jpg
    Sleep(240)
    SendEvent("{Ctrl down}")
    Sleep(40)
    SendEvent("{Shift down}")
    Sleep(40)
    SendEvent("{Enter down}")
    Sleep(60)
    SendEvent("{Enter up}")
    Sleep(40)
    SendEvent("{Shift up}")
    Sleep(40)
    SendEvent("{Ctrl up}")
    Sleep(60)

    SendText("give " . item)
    Sleep(300)
    SendEvent("{Enter down}")
    Sleep(60)
    SendEvent("{Enter up}")
    Sleep(60)

    SendEvent("{Escape down}")
    Sleep(60)
    SendEvent("{Escape up}")
    Sleep(100)

    SendEvent("{Ctrl down}")
    Sleep(40)
    SendEvent("{Shift down}")
    Sleep(40)
    SendEvent("{Enter down}")
    Sleep(60)
    SendEvent("{Enter up}")
    Sleep(40)
    SendEvent("{Shift up}")
    Sleep(40)
    SendEvent("{Ctrl up}")
    Sleep(60)
}

; ============================================================
; Pool Management
; ============================================================
resetAll() {
    global givenItems, remainingItems, allItems, saveFile
    global logicpool, logicPoolPhase, logicPressCount, logicSaveFile
    global starterKitPhase, dashFlip
    FileDelete(saveFile)
    FileDelete(logicSaveFile)
    givenItems := []
    refreshPools()

    logicPoolPhase := 1
    logicPressCount := 0
    starterKitPhase := 1
    dashFlip := 0
    logicpool := [
        "sword","spin_jump","great_slash","bouncy_spore","forward_dash","upwards_dash","boost_projectile","acid_hammer","spicy_nut","golden_light","returning_contraption","spark_ball","vibrant_crystal"
    ]
    saveLogicState()
}

refreshPools() {
    global allItems, givenItems, remainingItems
    remainingItems := []
    for i in allItems
        if !arrayContains(givenItems, i)
            remainingItems.Push(i)
}

loadGivenFromFile() {
    global saveFile, givenItems
    givenItems := []
    if !FileExist(saveFile)
        return
    content := FileRead(saveFile)
    if (content = "")
        return
    for line in StrSplit(content, "`n") {
        item := Trim(line)
        if (item != "")
            givenItems.Push(item)
    }
}

; ============================================================
; Removal GUI Functions
; ============================================================

ShowRemovalGUI() {
    global RemoveGui, givenItems, itemMap, selectedIndex, availableRemoveItems
    global A_ScreenWidth, A_ScreenHeight, removalGuiActive, buttonRefs, currentItemsPerRow
    
    ; Build list of removable items (ALL items now)
    availableRemoveItems := []
    for itemCmd, bossName in itemMap {
        availableRemoveItems.Push({cmd: itemCmd, name: bossName})
    }
    
    if (availableRemoveItems.Length = 0) {
        showTooltip("No items available to remove", 1500)
        return
    }
    
    selectedIndex := 1
    buttonRefs := []
    
    ; Create fullscreen GUI
    if IsObject(RemoveGui)
        RemoveGui.Destroy()
    
    RemoveGui := Gui("+AlwaysOnTop -Caption -DPIScale")
    
    bgPath := A_ScriptDir "\Rando Bosses\Removal Background.jpg"
    if FileExist(bgPath)
        RemoveGui.AddPicture("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight, bgPath)
    else
        RemoveGui.BackColor := "Black"
    
    
    
    ; Calculate grid layout
    totalItems := availableRemoveItems.Length
    itemsPerRow := (totalItems > 15) ? 8 : 5
    currentItemsPerRow := itemsPerRow ; Store for navigation
    
    boxSize := 180           ; Creating a larger fixed box for the item
    iconMaxWidth := 160      ; Max width for the icon inside
    borderThickness := 4     ; Gold border thickness
    spacing := 40
    textHeight := 30
    rowSpacing := spacing + textHeight  ; Extra space for text below box
    
    actualCols := (totalItems < itemsPerRow) ? totalItems : itemsPerRow
    numRows := Ceil(totalItems / itemsPerRow)
    
    totalWidth := (boxSize * actualCols) + (spacing * (actualCols - 1))
    totalHeight := (numRows * (boxSize + rowSpacing)) - spacing ; approximate height
    
    startX := (A_ScreenWidth - totalWidth) // 2
    startY := (A_ScreenHeight - totalHeight) // 2
    
    ; Create icon buttons
    row := 0
    col := 0
    
    for i, itemData in availableRemoveItems {
        xPos := startX + (col * (boxSize + spacing))
        yPos := startY + (row * (boxSize + rowSpacing))
        
        itemCmd := itemData.cmd
        bossName := itemData.name
        iconPath := A_ScriptDir "\Rando Bosses\" bossName ".png"
        
        ; 1. Draw Gold Border (Outer Box) using a Text control with background color
        ;    Using 0x200 (SS_CENTER) or similar text styles isn't needed for just a color block,
        ;    but +BackgroundFFD700 sets the color.
        RemoveGui.SetFont() ; Reset font to avoid carrying over
        border := RemoveGui.AddText("x" xPos " y" yPos " w" boxSize " h" boxSize " +BackgroundFFD700")
        
        ; 2. Draw Inner Background (Black) to create the hollow effect
        innerSize := boxSize - (borderThickness * 2)
        innerX := xPos + borderThickness
        innerY := yPos + borderThickness
        innerBg := RemoveGui.AddText("x" innerX " y" innerY " w" innerSize " h" innerSize " +Background000000")
        
        ; 3. Add Clickable Picture (Centered inside the inner box)
        ;    We let the picture find its own size but constrain it if it's too huge? 
        ;    User asked for "original size" previously, but now wants a box "bigger than the largest".
        ;    Safest bet is to center the image within the box.
        
        ; To center, we load it, get size, then position. Use a dummy object to check size first?
        ; AutoHotkey v2 doesn't have a simple "LoadImage" without adding it. 
        ; We'll add it hidden/autosized first? No, that's slow.
        ; We will add it at the top-center of the inner box, enabling the click on the picture.
        
        ; Let's assume we want to preserve original size but center it in the top portion of our box.
        ; We can't center it perfectly without knowing dimensions.
        ; However, if we simply add it, we can get dimensions, then move (Move) it.
        
        pic := RemoveGui.AddPicture("x" innerX " y" innerY " +Background000000 +AltSubmit", iconPath)

        ; Actually, remove border flag, we made our own.
        pic.Opt("-Border")
        
        pic.GetPos(,, &w, &h)
        
        scaleFactor := 1.0
        if (bossName = "Rocket Pengu" || bossName = "Goblin Chieftain" || bossName = "Fire Wyrm" || bossName = "Rogue Armadillo")
            scaleFactor := 2.5

        picW := w * scaleFactor
        picH := h * scaleFactor

        ; Constrain to box size (minus padding)
        maxSize := innerSize - 10
        if (picW > maxSize || picH > maxSize) {
            ratio := Min(maxSize / picW, maxSize / picH)
            picW *= ratio
            picH *= ratio
        }
        
        ; If image is massive (larger than our box), scale it down?
        ; User said "make a box a bit bigger than that", implying we should size the box to the image.
        ; But we have a grid... so we must pick a Fixed Box Size that is "Large Enough".
        ; 180x180 is likely consistent.
        
        newPicX := innerX + ((innerSize - picW) / 2)
        newPicY := innerY + ((innerSize - picH) / 2)
        
        ; Move the picture to centered position
        pic.Move(newPicX, newPicY, picW, picH)
        
        ; Bind Click to everything in the box for better UX?
        ; Binding to the Border and InnerBg allows clicking the "box" not just the transparent pixels of the icon.
        border.OnEvent("Click", ButtonClicked.Bind(i))
        innerBg.OnEvent("Click", ButtonClicked.Bind(i))
        pic.OnEvent("Click", ButtonClicked.Bind(i))
        
        buttonRefs.Push({btn: pic, border: border, cmd: itemCmd, index: i})
        
        ; 4. Add Label (Centered below the box)
        RemoveGui.SetFont("s14 cWhite", "Segoe UI")
        labelY := yPos + boxSize + 5
        
        ; Ensure label is centered relative to the box width
        RemoveGui.AddText("x" xPos " y" labelY " w" boxSize " h" textHeight " Center BackgroundTrans", bossName)
        
        col++
        if (col >= itemsPerRow) {
            col := 0
            row++
        }
    }
    
    ; Show GUI
    RemoveGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight " NoActivate")
    removalGuiActive := true
    
    UpdateSelectionVisuals()
}

ButtonClicked(index, *) {
    global buttonRefs
    RemoveItemHandler(buttonRefs[index].cmd)
}

BlockKey(*) {
    return
}

NavigateGridUp(*) {
    NavigateGrid("up")
}

NavigateGridDown(*) {
    NavigateGrid("down")
}

NavigateGridLeft(*) {
    NavigateGrid("left")
}

NavigateGridRight(*) {
    NavigateGrid("right")
}

NavigateGrid(direction) {
    global selectedIndex, availableRemoveItems, currentItemsPerRow
    
    oldIndex := selectedIndex

    switch direction {
        case "up":
            if (selectedIndex > currentItemsPerRow)
                selectedIndex -= currentItemsPerRow
        case "down":
            if (selectedIndex + currentItemsPerRow <= availableRemoveItems.Length)
                selectedIndex += currentItemsPerRow
        case "left":
            if (selectedIndex > 1)
                selectedIndex--
        case "right":
            if (selectedIndex < availableRemoveItems.Length)
                selectedIndex++
    }
    
    ; Visual feedback via highlighting (optimized)
    if (selectedIndex != oldIndex && selectedIndex > 0 && selectedIndex <= availableRemoveItems.Length) {
        UpdateSelectionVisuals(oldIndex, selectedIndex)
    }
}

UpdateSelectionVisuals(oldIdx := 0, newIdx := 0) {
    global buttonRefs, selectedIndex
    
    ; If no args, initialize all (or full refresh)
    if (oldIdx = 0 && newIdx = 0) {
        for i, ref in buttonRefs {
            if (i = selectedIndex)
                ref.border.Opt("+Background00FF00") ; Green for selected
            else
                ref.border.Opt("+BackgroundFFD700") ; Gold for others
            ref.border.Redraw()
        }
        return
    }

    ; Incremental update
    if (oldIdx > 0 && oldIdx <= buttonRefs.Length) {
        buttonRefs[oldIdx].border.Opt("+BackgroundFFD700")
        buttonRefs[oldIdx].border.Redraw()
    }
    
    if (newIdx > 0 && newIdx <= buttonRefs.Length) {
        buttonRefs[newIdx].border.Opt("+Background00FF00")
        buttonRefs[newIdx].border.Redraw()
    }
}

SelectCurrentItem(*) {
    global selectedIndex, availableRemoveItems
    if (selectedIndex > 0 && selectedIndex <= availableRemoveItems.Length)
        RemoveItemHandler(availableRemoveItems[selectedIndex].cmd)
}

RemoveItemHandler(itemCmd) {
    ExecuteRemoveCommand(itemCmd)
    ; No blockInput here - player regains control as soon as menu closes
}

ExecuteRemoveCommand(item) {
    ; Close the GUI first - this returns control to the player
    CloseRemovalGUI()
    
    ; Small delay for hotkeys to release
    Sleep(100)

    ; Activate game window FIRST to ensure focus
    if WinExist("Lone Fungus") {
        Loop 3 {
            WinActivate "Lone Fungus"
            if WinActive("Lone Fungus")
                break
            Sleep(100)
        }
        WinWaitActive("Lone Fungus", , 2)
        Sleep(100)
    }

    ; Show removal overlay AFTER game is focused
    ; FadeIn 75ms, FadeOut 1400ms
    ShowItemOverlay(item, A_ScriptDir "\Rando Remove", "jpg", 75, 1400)
    
    ; Delay to let overlay start appearing (matching giveCommand)
    Sleep(240)
    
    ; Open console with Ctrl+Shift+Enter
    SendEvent("{Ctrl down}")
    Sleep(40)
    SendEvent("{Shift down}")
    Sleep(40)
    SendEvent("{Enter down}")
    Sleep(60)
    SendEvent("{Enter up}")
    Sleep(40)
    SendEvent("{Shift up}")
    Sleep(40)
    SendEvent("{Ctrl up}")
    Sleep(60)

    ; Type the remove command
    SendText("remove " . item)
    Sleep(300)
    SendEvent("{Enter down}")
    Sleep(60)
    SendEvent("{Enter up}")
    Sleep(60)

    ; Close console
    SendEvent("{Escape down}")
    Sleep(60)
    SendEvent("{Escape up}")
    Sleep(100)

    ; Reopen console to close it fully
    SendEvent("{Ctrl down}")
    Sleep(40)
    SendEvent("{Shift down}")
    Sleep(40)
    SendEvent("{Enter down}")
    Sleep(60)
    SendEvent("{Enter up}")
    Sleep(40)
    SendEvent("{Shift up}")
    Sleep(40)
    SendEvent("{Ctrl up}")
    Sleep(60)
}

CloseRemovalGUI(*) {
    global RemoveGui, removalGuiActive, buttonRefs
    
    ; Mark as inactive first
    removalGuiActive := false
    buttonRefs := []
    
    ; Destroy the GUI first
    if IsObject(RemoveGui) {
        RemoveGui.Destroy()
        RemoveGui := 0
    }
    
    ; Small delay to ensure state is registered
    Sleep(50)
}

; ============================================================
; Initialization
; ============================================================
loadGivenFromFile()
refreshPools()

; Restore logic pool state if available; otherwise keep defaults
if !loadLogicState()
    saveLogicState()

showTooltip("Macro active – press F10 to exit", 1500)

; ============================================================
; Hotkeys
; ============================================================

; Conditional hotkeys only active when the Removal Menu is open
#HotIf removalGuiActive
Escape::CloseRemovalGUI()
Enter::SelectCurrentItem()
Space::SelectCurrentItem()
w::NavigateGridUp()
a::NavigateGridLeft()
s::NavigateGridDown()
d::NavigateGridRight()
Up::NavigateGridUp()
Left::NavigateGridLeft()
Down::NavigateGridDown()
Right::NavigateGridRight()
; Block all other potential macro/game keys while menu is open
LShift::return
RShift::return
LCtrl::return
RCtrl::return
Alt::return
Tab::return
e::return
r::return
f::return
q::return
z::return
x::return
c::return
v::return
0::return
1::return
2::return
3::return
4::return
5::return
6::return
7::return
8::return
9::return
#HotIf

; ============================================================
; Key "9" = Give random unique item (with upgrade dependencies)
; ============================================================
9::
{
    global remainingItems, givenItems, inputBlocked
    
    if inputBlocked
        return
    
    if (remainingItems.Length = 0)
        return

    validPool := []
    for item in remainingItems {
        canGive := true

        switch item {
            case "magic_dash":
                if !arrayContains(givenItems, "shield_cap")
                    canGive := false
            case "meteor_strike", "fire_bounce", "great_spin_slash":
                if !arrayContains(givenItems, "spin_jump")
                    canGive := false
            case "astral_mushmover":
                if !arrayContains(givenItems, "mushmover_spell")
                    canGive := false
            case "magic_crouch_jump":
                if !arrayContains(givenItems, "crouch_jump")
                    canGive := false
            case "mushmover_infusion":
                if !(arrayContains(givenItems, "sword")
                    || arrayContains(givenItems, "forward_dash")
                    || arrayContains(givenItems, "upwards_dash"))
                    canGive := false
            case "dash_crystal":
                if !(arrayContains(givenItems, "forward_dash")
                    && arrayContains(givenItems, "upwards_dash"))
                    canGive := false
        }

        if (canGive)
            validPool.Push(item)
    }

    if (validPool.Length = 0)
        return

    idx := Random(1, validPool.Length)
    item := validPool[idx]
    remainingItems.RemoveAt(findIndex(remainingItems, item))

    if !arrayContains(givenItems, item) {
        givenItems.Push(item)
        writeGiven(item)
        giveCommand(item)
        blockInput(1000)
    } else {
        refreshPools()
        if (remainingItems.Length > 0)
            Send("{F6}")
    }
}

; ============================================================
; Key "8" = Logic item pool (with upgrade dependencies)
; ============================================================
8::
{
    global logicpool, logicPoolPhase, logicPressCount
    global givenItems, remainingItems, inputBlocked

    if inputBlocked
        return

    if (logicpool.Length = 0)
        return

    logicPressCount += 1

    if (logicPressCount = 3 && !arrayContains(givenItems, "sword")) {
        logicItem := "sword"
    } else {
        validLogicPool := []
        for item in logicpool {
            canGive := true
            switch item {
                case "mushmover_infusion":
                    if !(arrayContains(givenItems, "sword")
                        || arrayContains(givenItems, "forward_dash")
                        || arrayContains(givenItems, "upwards_dash"))
                        canGive := false
            }

            if (canGive)
                validLogicPool.Push(item)
        }

        if (validLogicPool.Length = 0)
            return

        idx := Random(1, validLogicPool.Length)
        logicItem := validLogicPool[idx]
    }

    if !arrayContains(givenItems, logicItem) {
        givenItems.Push(logicItem)
        writeGiven(logicItem)
        giveCommand(logicItem)
        blockInput(1000)
    }

    Sleep(200)
    if findIndex(logicpool, logicItem)
        logicpool.RemoveAt(findIndex(logicpool, logicItem))
    if findIndex(remainingItems, logicItem)
        remainingItems.RemoveAt(findIndex(remainingItems, logicItem))

    Sleep(250)

    if (logicPoolPhase = 1) {
        logicPoolPhase := 2
        logicpool := [
            "sword","spin_jump","bouncy_spore","forward_dash","upwards_dash",
            "mushmover_infusion","mushmover_spell","wallbounce","groundbounce","crouch_jump","shield_cap"
        ]
        if findIndex(logicpool, logicItem)
            logicpool.RemoveAt(findIndex(logicpool, logicItem))
    }
    
    saveLogicState()
}

; ============================================================
; Key "0" = Open Item Removal GUI
; ============================================================
0::
{
    global removalGuiActive
    
    ; Guard against reopening while GUI is active or being processed
    if removalGuiActive
        return
    
    ShowRemovalGUI()
}

; ============================================================
; Key "7" = Give starting kit (two phases)
; Phase 1: sword, healing_fungus, shield_cap
; Phase 2: mushmover_spell, mushmover_infusion
; ============================================================
global starterKitPhase := 1

7::
{
    global givenItems, remainingItems, inputBlocked, starterKitPhase, logicpool

    if inputBlocked
        return

    if (starterKitPhase = 1) {
        ; Phase 1: Give essentials
        essentials := ["sword", "healing_fungus", "shield_cap"]
        gaveAny := false

        for item in essentials {
            if !arrayContains(givenItems, item) {
                givenItems.Push(item)
                writeGiven(item)

                idx := findIndex(remainingItems, item)
                if (idx)
                    remainingItems.RemoveAt(idx)

                giveCommand(item)
                gaveAny := true
                Sleep(400)
            }
        }

        ; Update logic pool and advance to phase 2
        logicpool := [
            "spin_jump","forward_dash","upwards_dash",
            "mushmover_infusion","mushmover_spell",
            "wallbounce","groundbounce"
        ]
        starterKitPhase := 2
        saveLogicState()

    } else if (starterKitPhase = 2) {
        ; Phase 2: Give mushmovers
        mushmovers := ["mushmover_spell", "mushmover_infusion"]

        for item in mushmovers {
            if !arrayContains(givenItems, item) {
                givenItems.Push(item)
                writeGiven(item)

                idx := findIndex(remainingItems, item)
                if (idx)
                    remainingItems.RemoveAt(idx)

                idx := findIndex(logicpool, item)
                if (idx)
                    logicpool.RemoveAt(idx)

                giveCommand(item)
                Sleep(400)
            }
        }

        ; Stay at phase 2 (no more phases)
        saveLogicState()
    }
    
    blockInput(1000)
}

; =====================================
; 6 = Toggle-setting macro (Variable Dash Height)
; =====================================

global dashFlip := 0   ; 0 = Left/Set, 1 = Right/Variable (loaded from saveLogicState)

6::
{
    global dashFlip, inputBlocked

    if inputBlocked
        return
    
    blockInput(1300)

    ; Calculate new state and show popup immediately
    ; FadeIn 75ms, FadeOut 1400ms
    dashFlip := !dashFlip
    if dashFlip {
        ShowItemOverlay("Variable Dash", A_ScriptDir "\Rando Dash", "png", 20, 1400, 1300)
    } else {
        ShowItemOverlay("Set Dash", A_ScriptDir "\Rando Dash", "png", 20, 1400, 1300)
    }

    SendEvent("{Escape down}")
    Sleep(40)
    SendEvent("{Escape up}")
    Sleep(40)

    SendEvent("{5 down}")
    Sleep(40)
    SendEvent("{5 up}")
    Sleep(40)

    SendEvent("{Down down}")
    Sleep(40)
    SendEvent("{Down up}")
    Sleep(40)

    SendEvent("{Enter down}")
    Sleep(100)
    SendEvent("{Enter up}")
    Sleep(100)

    SendEvent("{Enter down}")
    Sleep(100)
    SendEvent("{Enter up}")
    Sleep(100)

    ; Press W and Up together (3 times)
    SendEvent("{W down}{Up down}")
    Sleep(40)
    SendEvent("{W up}{Up up}")
    Sleep(40)
    SendEvent("{W down}{Up down}")
    Sleep(40)
    SendEvent("{W up}{Up up}")
    Sleep(40)
    SendEvent("{W down}{Up down}")
    Sleep(40)
    SendEvent("{W up}{Up up}")
    Sleep(40)

    if dashFlip {
        ; Press D and Right together
        SendEvent("{D down}{Right down}")
        Sleep(40)
        SendEvent("{D up}{Right up}")
        Sleep(40)
    } else {
        ; Press A and Left together
        SendEvent("{A down}{Left down}")
        Sleep(40)
        SendEvent("{A up}{Left up}")
        Sleep(40)
    }

    SendEvent("{Escape down}")
    Sleep(60)
    SendEvent("{Escape up}")
    Sleep(60)
    SendEvent("{Escape down}")
    Sleep(60)
    SendEvent("{Escape up}")
    Sleep(40)
    
    ; Save dashFlip state for persistence
    saveLogicState()
}

dashTooltip(msg, duration := 1000) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -duration)
}

; ============================================================
; F9 = Reset (with confirmation)
; ============================================================
F9::
{
    result := MsgBox("Are you sure you want to reset all progress?", "Confirm Reset", 4)
    if (result = "Yes") {
        resetAll()
        saveLogicState()
        showTooltip("Item pool and logic pool have been reset.")
    }
}

; ============================================================
; F10 = Exit
; ============================================================
F10::
{
    MsgBox "Macro stopped."
    ExitApp
}