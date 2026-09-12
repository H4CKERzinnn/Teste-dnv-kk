--// =========================================================
--// ANIME BREAKER - FLUENT
--// =========================================================

local Fluent = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua"
))()

local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()

local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

--// =========================================================
--// SERVICES
--// =========================================================

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

--// =========================================================
--// WINDOW
--// =========================================================

local Window = Fluent:CreateWindow({
    Title = "Anime Breaker",
    SubTitle = "by H4CKERzinnn",

    Search = true,
    Icon = "star",

    TabWidth = 140,

    Size = UDim2.fromOffset(620, 400),

    Acrylic = true,
    Theme = "Dark",

    MinimizeKey = Enum.KeyCode.LeftControl,

    UserInfo = true,
    UserInfoTop = false,

    UserInfoTitle = LocalPlayer.DisplayName,
    UserInfoSubtitle = "FOUR",
    UserInfoSubtitleColor = Color3.fromRGB(255, 0, 0)
})

--// =========================================================
--// TABS
--// =========================================================

local Tabs = {

    Main = Window:AddTab({
        Title = "Main",
        Icon = "star"
    }),

    Gamemode = Window:AddTab({
        Title = "Gamemode",
        Icon = "gamepad-2"
    }),

    Misc = Window:AddTab({
        Title = "Misc",
        Icon = "package"
    }),

    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    })
}

--// =========================================================
--// MINIMIZER
--// =========================================================

local Minimizer = Fluent:CreateMinimizer({
    Icon = "home",

    Size = UDim2.fromOffset(44, 44),

    Position = UDim2.new(0, 320, 0, 24),

    Acrylic = true,
    Corner = 10,
    Transparency = 1,

    Draggable = true,
    Visible = true
})



local Options = Fluent.Options

--// =========================================================
--// MAIN
--// =========================================================

local MainSection = Tabs.Main:AddSection("Farm", "sword")

--// =========================================================
--// ENEMIES
--// =========================================================

local enemies = workspace:WaitForChild("_ENEMIES")
local serverFolder = enemies:WaitForChild("Server")
local clientFolder = enemies:WaitForChild("Client")
local inRangeFolder = enemies:WaitForChild("InRange")

--// =========================================================
--// GET MAPS
--// =========================================================

local function getMaps()
    local maps = {}
    for _, folder in pairs(serverFolder:GetChildren()) do
        if folder:IsA("Folder")
            and folder.Name ~= "Gamemode"
            and folder.Name ~= "GlobalBoss"
            and folder.Name ~= "Client" then
            table.insert(maps, folder.Name)
        end
    end
    table.sort(maps)
    return maps
end

local mapList = getMaps()
if #mapList == 0 then
    mapList = {"None"}
end

--// =========================================================
--// DROPDOWNS
--// =========================================================

local WorldDropdown = MainSection:AddDropdown("World", {
    Title = "World",
    Values = mapList,
    Multi = false,
    Default = 1
})

local TPModeDropdown = MainSection:AddDropdown("TPMode", {
    Title = "TP Mode",
    Values = {"Closest", "Center"},
    Multi = false,
    Default = 1
})

local NPCDropdown = MainSection:AddDropdown("NPC", {
    Title = "NPC",
    Values = {"All"},
    Multi = true,
    Default = {"All"}
})

local FarmToggle = MainSection:AddToggle("Farm", {
    Title = "Farm",
    Default = false
})

--// =========================================================
--// HELPERS
--// =========================================================

local function cleanNPCName(name)
    name = tostring(name or "")
    local start = string.find(name, " %(")
    if start then
        name = string.sub(name, 1, start - 1)
    end
    return name
end

-- Lê corretamente o Multi do Fluent
local function getSelectedNPCs()
    local value = NPCDropdown.Value
    local result = {}

    if typeof(value) == "table" then
        -- Fluent Multi pode vir como { ["Nome"] = true }
        for k, v in pairs(value) do
            if v == true or typeof(k) == "number" then
                local name = cleanNPCName(typeof(k) == "number" and v or k)
                if name ~= "" then
                    table.insert(result, name)
                end
            end
        end
    else
        local name = cleanNPCName(value)
        if name ~= "" then
            table.insert(result, name)
        end
    end

    -- Se tiver "All" ou lista vazia → All
    for _, name in ipairs(result) do
        if name == "All" then
            return {"All"}
        end
    end

    if #result == 0 then
        return {"All"}
    end

    return result
end

local function isNPCAllowed(realName, selectedList)
    if not realName then return false end
    for _, selected in ipairs(selectedList) do
        if selected == "All" or selected == realName then
            return true
        end
    end
    return false
end

--// =========================================================
--// UPDATE NPC LIST
--// =========================================================

local function updateNPCDropdown(selectedMap)
    local unique = {}
    local list = {"All"}

    local mapFolder = serverFolder:FindFirstChild(selectedMap)
    if mapFolder then
        for _, data in pairs(mapFolder:GetChildren()) do
            local name = data:GetAttribute("Name")
            local rarity = data:GetAttribute("Rarity") or "Common"
            if name and not unique[name] then
                unique[name] = true
                table.insert(list, name .. " (" .. rarity .. ")")
            end
        end
    end

    table.sort(list, function(a, b)
        if a == "All" then return true end
        if b == "All" then return false end
        return a < b
    end)

    pcall(function()
        NPCDropdown:SetValues(list)
        NPCDropdown:SetValue({"All"})
    end)
end

WorldDropdown:OnChanged(function(value)
    if value then
        updateNPCDropdown(value)
    end
end)

task.spawn(function()
    task.wait(0.6)
    local current = WorldDropdown.Value or mapList[1]
    if current then
        updateNPCDropdown(current)
    end
end)

--// =========================================================
--// CHARACTER
--// =========================================================

local player = LocalPlayer
local character = player.Character
local hrp

local function updateCharacter()
    character = player.Character
    if not character then
        hrp = nil
        return
    end
    hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        pcall(function()
            hrp = character:WaitForChild("HumanoidRootPart", 5)
        end)
    end
end

updateCharacter()
player.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateCharacter()
end)

--// =========================================================
--// NOME REAL DO NPC
--// =========================================================

local function getRealName(guid)
    for _, mapFolder in pairs(serverFolder:GetChildren()) do
        if mapFolder:IsA("Folder") then
            local data = mapFolder:FindFirstChild(guid)
            if data then
                return data:GetAttribute("Name")
            end
        end
    end
    return nil
end

local function getEnemyRealName(model)
    if not model then return nil end
    return getRealName(model.Name) or model:GetAttribute("Name")
end

--// =========================================================
--// IN RANGE
--// =========================================================

local function hasSelectedNPCInRange(selectedList)
    for _, model in pairs(inRangeFolder:GetChildren()) do
        if model:IsA("Model") then
            local realName = getEnemyRealName(model)
            if isNPCAllowed(realName, selectedList) then
                return true
            end
        end
    end
    return false
end

--// =========================================================
--// GET TARGET
--// =========================================================

local function getTarget(selectedList, mode)
    if not hrp then return nil end

    local parts = {}

    for _, model in pairs(clientFolder:GetChildren()) do
        if model:IsA("Model") then
            local leg = model:FindFirstChild("Right Leg")
            if leg and leg:IsA("BasePart") then
                local realName = getEnemyRealName(model)
                if isNPCAllowed(realName, selectedList) then
                    table.insert(parts, leg)
                end
            end
        end
    end

    if #parts == 0 then
        return nil
    end

    -- CLOSEST
    if mode == "Closest" then
        local closest = nil
        local shortest = math.huge
        for _, part in ipairs(parts) do
            local dist = (hrp.Position - part.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = part
            end
        end
        if closest then
            return closest.CFrame + Vector3.new(0, 2.5, 0)
        end
        return nil
    end

    -- CENTER
    if mode == "Center" then
        local maxDist = 45

        if #parts == 1 then
            return parts[1].CFrame + Vector3.new(0, 2.5, 0)
        end

        local bestCenter = nil
        local bestCount = 0

        for i, centerPart in ipairs(parts) do
            local sum = centerPart.Position
            local count = 1

            for j, other in ipairs(parts) do
                if i ~= j then
                    if (centerPart.Position - other.Position).Magnitude <= maxDist then
                        sum = sum + other.Position
                        count = count + 1
                    end
                end
            end

            if count > bestCount then
                bestCount = count
                bestCenter = sum / count
            end
        end

        if bestCenter then
            return CFrame.new(bestCenter + Vector3.new(0, 2.5, 0))
        end
    end

    return nil
end

--// =========================================================
--// FARM LOOP
--// =========================================================

local lastKey = nil

task.spawn(function()
    while true do
        task.wait(0.12)

        if not character or not character.Parent then
            updateCharacter()
        end

        if not hrp or not hrp.Parent then
            if character then
                hrp = character:FindFirstChild("HumanoidRootPart")
            end
            continue
        end

        if FarmToggle.Value then
            local selectedList = getSelectedNPCs()
            local mode = TPModeDropdown.Value or "Closest"

            local key = table.concat(selectedList, "|") .. "|" .. tostring(mode)
            local changed = key ~= lastKey
            lastKey = key

            local inRange = hasSelectedNPCInRange(selectedList)

            if changed or not inRange then
                local cf = getTarget(selectedList, mode)
                if cf then
                    pcall(function()
                        hrp.CFrame = cf
                    end)
                end
            end
        else
            lastKey = nil
        end
    end
end)

--// =========================================================
--// GAMEMODE
--// =========================================================

--// =========================================================
--// TRIAL
--// =========================================================

local TrialSection =
    Tabs.Gamemode:AddSection(
        "Trial",
        "swords"
    )

TrialSection:AddDropdown(
    "TrialDifficulty",
    {

        Title = "Difficulty",

        Values = {
            "Easy",
            "Normal",
            "Hard"
        },

        Multi = false,

        Default = 1

    }
)

TrialSection:AddSlider(
    "TrialWave",
    {

        Title = "Wave",

        Default = 0,

        Min = 0,

        Max = 100,

        Rounding = 0

    }
)

TrialSection:AddToggle(
    "TrialLeave",
    {

        Title = "Leave",

        Default = false

    }
)

TrialSection:AddToggle(
    "TrialFarm",
    {

        Title = "Farm",

        Default = false

    }
)

--// =========================================================
--// RAID
--// =========================================================

local RaidSection =
    Tabs.Gamemode:AddSection(
        "Raid",
        "skull"
    )

RaidSection:AddDropdown(
    "RaidDifficulty",
    {

        Title = "Difficulty",

        Values = {
            "Easy",
            "Normal",
            "Hard"
        },

        Multi = false,

        Default = 1

    }
)

RaidSection:AddSlider(
    "RaidWave",
    {

        Title = "Wave",

        Default = 0,

        Min = 0,

        Max = 100,

        Rounding = 0

    }
)

RaidSection:AddToggle(
    "RaidLeave",
    {

        Title = "Leave",

        Default = false

    }
)

RaidSection:AddToggle(
    "RaidFarm",
    {

        Title = "Farm",

        Default = false

    }
)

--// =========================================================
--// MISC
--// =========================================================

local MiscSection =
    Tabs.Misc:AddSection(
        "Misc",
        "package"
    )

--// =========================================================
--// AUTO MULTI CHEST
--// =========================================================

local coords = {

    CFrame.new(
        -500,
        145,
        -808
    ),

    CFrame.new(
        -491,
        145,
        -808
    ),

    CFrame.new(
        -300,
        140,
        -700
    )

}

local running = false

MiscSection:AddToggle(
    "AutoMultiChest",
    {

        Title = "Auto Multi Chest",

        Default = false

    }
):OnChanged(function(Value)

    running = Value

    if not Value then
        return
    end

    task.spawn(function()

        local char =
            player.Character
            or player.CharacterAdded:Wait()

        local root =
            char:WaitForChild(
                "HumanoidRootPart",
                5
            )

        if not root then

            running = false

            return

        end

        -- Salva posição
        local origin =
            root.CFrame

        for _, pos in ipairs(coords) do

            if not running then
                break
            end

            pcall(function()

                root.CFrame = pos

            end)

            task.wait(2)

        end

        -- Volta
        if origin
            and root
            and root.Parent then

            pcall(function()

                root.CFrame = origin

            end)

        end

    end)

end)

--// =========================================================
--// CLIENT
--// =========================================================

local ClientSection =
    Tabs.Misc:AddSection(
        "Client",
        "monitor"
    )

--// =========================================================
--// BLACK SCREEN
--// =========================================================

local BlackScreenToggle =
    ClientSection:AddToggle(
        "BlackScreen",
        {

            Title = "Black Screen",

            Default = false

        }
    )

local blackScreen = nil

local function createBlackScreen()

    if blackScreen then
        return
    end

    blackScreen =
        Instance.new("ScreenGui")

    blackScreen.Name =
        "BlackScreenOverlay"

    blackScreen.ResetOnSpawn =
        false

    blackScreen.IgnoreGuiInset =
        true

    blackScreen.DisplayOrder =
        999999

    blackScreen.ZIndexBehavior =
        Enum.ZIndexBehavior.Global

    local frame =
        Instance.new("Frame")

    frame.Name =
        "BlackFrame"

    frame.Size =
        UDim2.new(1, 0, 1, 0)

    frame.Position =
        UDim2.new(0, 0, 0, 0)

    frame.BackgroundColor3 =
        Color3.fromRGB(
            0,
            0,
            0
        )

    frame.BackgroundTransparency =
        0

    frame.BorderSizePixel =
        0

    frame.ZIndex =
        999999

    frame.Parent =
        blackScreen

    blackScreen.Parent =
        player:WaitForChild(
            "PlayerGui"
        )

end

BlackScreenToggle:OnChanged(
    function(enabled)

        if enabled then

            createBlackScreen()

            if blackScreen then
                blackScreen.Enabled = true
            end

        else

            if blackScreen then
                blackScreen.Enabled = false
            end

        end

    end
)

--// =========================================================
--// ANTI AFK
--// =========================================================

getgenv().AntiAFK = true

local function ClickJumpButton()

    local playerGui =
        player:FindFirstChild(
            "PlayerGui"
        )

    if not playerGui then
        return
    end

    local touchGui =
        playerGui:FindFirstChild(
            "TouchGui",
            true
        )

    if not touchGui then
        return
    end

    local touchControlFrame =
        touchGui:FindFirstChild(
            "TouchControlFrame",
            true
        )

    if not touchControlFrame then
        return
    end

    local jumpButton =
        touchControlFrame:FindFirstChild(
            "JumpButton"
        )

    if not jumpButton then
        return
    end

    if not jumpButton:IsA(
        "GuiObject"
    ) then
        return
    end

    local absolutePos =
        jumpButton.AbsolutePosition

    local size =
        jumpButton.AbsoluteSize

    local center =
        absolutePos
        + (size / 2)

    pcall(function()

        VirtualInputManager:
            SendMouseButtonEvent(

                center.X,
                center.Y,

                0,

                true,

                game,

                0

            )

        task.wait(0.05)

        VirtualInputManager:
            SendMouseButtonEvent(

                center.X,
                center.Y,

                0,

                false,

                game,

                0

            )

    end)

end

--// Idled
player.Idled:Connect(
    function()

        if not getgenv().AntiAFK then
            return
        end

        ClickJumpButton()

    end
)

--// Backup
task.spawn(function()

    while true do

        task.wait(150)

        if getgenv().AntiAFK then

            ClickJumpButton()

        end

    end

end)

--// =========================================================
--// ANTI AFK TOGGLE
--// =========================================================

ClientSection:AddToggle(
    "AntiAFK",
    {

        Title = "Anti-AFK",

        Default = true

    }
):OnChanged(function(Value)

    getgenv().AntiAFK = Value

end)

--// =========================================================
--// SETTINGS
--// =========================================================

SaveManager:SetLibrary(Fluent)

InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()

SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder(
    "FluentScriptHub"
)

SaveManager:SetFolder(
    "FluentScriptHub/animeastral"
)

InterfaceManager:BuildInterfaceSection(
    Tabs.Settings
)

SaveManager:BuildConfigSection(
    Tabs.Settings
)

--// =========================================================
--// START
--// =========================================================

Window:SelectTab(1)

Fluent:Notify({

    Title = "Anime Breaker",

    Content =
        "Script carregado com sucesso!",

    Duration = 8

})

pcall(function()

    SaveManager:LoadAutoloadConfig()

end)