--[[
    SPY SCRIPT - Remote Spy Completo
    Funcionalidades:
    - Captura todos os Remotes (RemoteEvent, RemoteFunction, BindableEvent, BindableFunction)
    - Loga argumentos enviados/recebidos
    - Botão para baixar arquivo com todos os remotes
    - GUI moderna com filtros
--]]

-- // Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- // Verifica executor
if not syn and not secure_call and not KRNL_LOADED and not fluxus then
    warn("[Spy] Executor sem suporte total - algumas funções podem falhar")
end

-- // Configurações
local CONFIG = {
    MaxLogs = 200,
    FileName = "remotes_spy_" .. os.date("%Y%m%d_%H%M%S") .. ".txt",
}

-- // Tabelas
local Remotes = {}
local Logs = {}
local IgnoredRemotes = {}

-- // ============ GUI ============
local function CreateGUI()
    -- Remove GUI antiga
    if CoreGui:FindFirstChild("SpyGui") then
        CoreGui.SpyGui:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SpyGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 500, 0, 400)
    Main.Position = UDim2.new(0.5, -250, 0.5, -200)
    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(80, 80, 100)
    MainStroke.Thickness = 1
    MainStroke.Parent = Main
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    local TitleFix = Instance.new("Frame")
    TitleFix.Size = UDim2.new(1, 0, 0, 15)
    TitleFix.Position = UDim2.new(0, 0, 1, -15)
    TitleFix.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    TitleFix.BorderSizePixel = 0
    TitleFix.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Text = "🕵️ SPY - Remote Logger"
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(220, 220, 240)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Botões Title
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -33, 0, 3)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn
    
    -- Minimize
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -65, 0, 3)
    MinBtn.BackgroundColor3 = Color3.fromRGB(240, 180, 60)
    MinBtn.Text = "—"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 14
    MinBtn.Parent = TitleBar
    
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinBtn
    
    -- Toolbar
    local Toolbar = Instance.new("Frame")
    Toolbar.Size = UDim2.new(1, -20, 0, 40)
    Toolbar.Position = UDim2.new(0, 10, 0, 45)
    Toolbar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Toolbar.BorderSizePixel = 0
    Toolbar.Parent = Main
    
    local ToolbarCorner = Instance.new("UICorner")
    ToolbarCorner.CornerRadius = UDim.new(0, 8)
    ToolbarCorner.Parent = Toolbar
    
    -- Botão Download
    local DownloadBtn = Instance.new("TextButton")
    DownloadBtn.Size = UDim2.new(0, 150, 0, 30)
    DownloadBtn.Position = UDim2.new(0, 5, 0, 5)
    DownloadBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
    DownloadBtn.Text = "⬇ Baixar Remotes"
    DownloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DownloadBtn.Font = Enum.Font.GothamBold
    DownloadBtn.TextSize = 12
    DownloadBtn.Parent = Toolbar
    
    local DLCorner = Instance.new("UICorner")
    DLCorner.CornerRadius = UDim.new(0, 6)
    DLCorner.Parent = DownloadBtn
    
    -- Botão Limpar
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0, 100, 0, 30)
    ClearBtn.Position = UDim2.new(0, 165, 0, 5)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 60)
    ClearBtn.Text = "🗑 Limpar Logs"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.TextSize = 12
    ClearBtn.Parent = Toolbar
    
    local CLCorner = Instance.new("UICorner")
    CLCorner.CornerRadius = UDim.new(0, 6)
    CLCorner.Parent = ClearBtn
    
    -- Botão Scan
    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Size = UDim2.new(0, 120, 0, 30)
    ScanBtn.Position = UDim2.new(0, 275, 0, 5)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
    ScanBtn.Text = "🔍 Scan Remotes"
    ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ScanBtn.Font = Enum.Font.GothamBold
    ScanBtn.TextSize = 12
    ScanBtn.Parent = Toolbar
    
    local SBCorner = Instance.new("UICorner")
    SBCorner.CornerRadius = UDim.new(0, 6)
    SBCorner.Parent = ScanBtn
    
    -- Counter
    local Counter = Instance.new("TextLabel")
    Counter.Size = UDim2.new(0, 100, 0, 30)
    Counter.Position = UDim2.new(1, -105, 0, 5)
    Counter.BackgroundTransparency = 1
    Counter.Text = "Remotes: 0"
    Counter.TextColor3 = Color3.fromRGB(180, 180, 200)
    Counter.Font = Enum.Font.GothamBold
    Counter.TextSize = 12
    Counter.Parent = Toolbar
    
    -- Log Container
    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Size = UDim2.new(1, -20, 1, -145)
    LogScroll.Position = UDim2.new(0, 10, 0, 95)
    LogScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 6
    LogScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogScroll.Parent = Main
    
    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, 8)
    LogCorner.Parent = LogScroll
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Padding = UDim.new(0, 4)
    LogLayout.Parent = LogScroll
    
    local LogPadding = Instance.new("UIPadding")
    LogPadding.PaddingTop = UDim.new(0, 6)
    LogPadding.PaddingLeft = UDim.new(0, 6)
    LogPadding.PaddingRight = UDim.new(0, 6)
    LogPadding.PaddingBottom = UDim.new(0, 6)
    LogPadding.Parent = LogScroll
    
    -- Status Bar
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -20, 0, 20)
    Status.Position = UDim2.new(0, 10, 1, -25)
    Status.BackgroundTransparency = 1
    Status.Text = "Pronto"
    Status.TextColor3 = Color3.fromRGB(120, 200, 120)
    Status.Font = Enum.Font.Gotham
    Status.TextSize = 11
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main
    
    return {
        ScreenGui = ScreenGui,
        Main = Main,
        LogScroll = LogScroll,
        Counter = Counter,
        Status = Status,
        DownloadBtn = DownloadBtn,
        ClearBtn = ClearBtn,
        ScanBtn = ScanBtn,
        CloseBtn = CloseBtn,
        MinBtn = MinBtn,
    }
end

local GUI = CreateGUI()

-- // ============ FUNÇÕES ============
local function SetStatus(text, color)
    GUI.Status.Text = text
    GUI.Status.TextColor3 = color or Color3.fromRGB(120, 200, 120)
end

local function FormatValue(val)
    local t = typeof(val)
    if t == "Instance" then
        return val:GetFullName()
    elseif t == "string" then
        return string.format("%q", val)
    elseif t == "table" then
        local ok, encoded = pcall(function() return HttpService:JSONEncode(val) end)
        if ok then return encoded end
        return "{table}"
    elseif t == "Vector3" or t == "CFrame" or t == "Color3" then
        return tostring(val)
    else
        return tostring(val)
    end
end

local function AddLog(remoteName, remoteType, args, direction)
    local timestamp = os.date("%H:%M:%S")
    local argsStr = ""
    
    for i, v in ipairs(args) do
        argsStr = argsStr .. FormatValue(v) .. (i < #args and ", " or "")
    end
    
    local logData = {
        Time = timestamp,
        Remote = remoteName,
        Type = remoteType,
        Direction = direction,
        Args = argsStr,
    }
    
    table.insert(Logs, 1, logData)
    if #Logs > CONFIG.MaxLogs then
        table.remove(Logs)
    end
    
    -- Criar entry visual
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1, -4, 0, 50)
    Entry.BackgroundColor3 = direction == "OUT" and Color3.fromRGB(50, 40, 40) or Color3.fromRGB(40, 50, 45)
    Entry.BorderSizePixel = 0
    Entry.Parent = GUI.LogScroll
    
    local EntryCorner = Instance.new("UICorner")
    EntryCorner.CornerRadius = UDim.new(0, 6)
    EntryCorner.Parent = Entry
    
    -- Header
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, -10, 0, 18)
    Header.Position = UDim2.new(0, 5, 0, 3)
    Header.BackgroundTransparency = 1
    Header.Text = string.format("[%s] %s %s  →  %s", 
        timestamp, 
        direction == "OUT" and "📤" or "📥",
        remoteType,
        remoteName
    )
    Header.TextColor3 = direction == "OUT" and Color3.fromRGB(255, 150, 100) or Color3.fromRGB(100, 255, 150)
    Header.Font = Enum.Font.GothamBold
    Header.TextSize = 11
    Header.TextXAlignment = Enum.TextXAlignment.Left
    Header.TextTruncate = Enum.TextTruncate.AtEnd
    Header.Parent = Entry
    
    -- Args
    local ArgsLabel = Instance.new("TextLabel")
    ArgsLabel.Size = UDim2.new(1, -10, 0, 25)
    ArgsLabel.Position = UDim2.new(0, 5, 0, 21)
    ArgsLabel.BackgroundTransparency = 1
    ArgsLabel.Text = argsStr ~= "" and argsStr or "(sem argumentos)"
    ArgsLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    ArgsLabel.Font = Enum.Font.Code
    ArgsLabel.TextSize = 10
    ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ArgsLabel.TextWrapped = true
    ArgsLabel.TextTruncate = Enum.TextTruncate.AtEnd
    ArgsLabel.Parent = Entry
    
    -- Limita logs visuais
    local children = {}
    for _, child in ipairs(GUI.LogScroll:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(children, child)
        end
    end
    
    if #children > CONFIG.MaxLogs then
        for i = 1, #children - CONFIG.MaxLogs do
            children[#children - i + 1]:Destroy()
        end
    end
end

-- // ============ SPY ============
local function SpyRemote(remote)
    if IgnoredRemotes[remote] then return end
    IgnoredRemotes[remote] = true
    
    local remoteType = remote.ClassName
    local remoteName = remote:GetFullName()
    
    Remotes[remote] = true
    
    if remoteType == "RemoteEvent" or remoteType == "BindableEvent" then
        -- Hook FireServer
        local oldFireServer
        oldFireServer = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if self == remote and (method == "FireServer" or method == "fire") then
                local args = {...}
                AddLog(remoteName, remoteType, args, "OUT")
            end
            return oldFireServer(self, ...)
        end)
        
        -- Hook Fire (Bindable)
        if remoteType == "BindableEvent" then
            remote.Event:Connect(function(...)
                local args = {...}
                AddLog(remoteName, remoteType, args, "OUT")
            end)
        end
        
    elseif remoteType == "RemoteFunction" or remoteType == "BindableFunction" then
        -- Hook InvokeServer
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if self == remote and (method == "InvokeServer" or method == "invoke") then
                local args = {...}
                AddLog(remoteName, remoteType, args, "OUT")
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end

local function ScanRemotes()
    SetStatus("Escaneando remotes...", Color3.fromRGB(255, 200, 100))
    
    local count = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") 
           or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
            if not Remotes[obj] then
                SpyRemote(obj)
                count = count + 1
            end
        end
    end
    
    -- Conta total
    local total = 0
    for _ in pairs(Remotes) do total = total + 1 end
    
    GUI.Counter.Text = "Remotes: " .. total
    SetStatus(string.format("✓ %d novos remotes encontrados (Total: %d)", count, total), Color3.fromRGB(120, 200, 120))
    
    return count, total
end

-- // ============ DOWNLOAD ============
local function DownloadRemotes()
    SetStatus("Gerando arquivo...", Color3.fromRGB(255, 200, 100))
    
    local content = "===========================================\n"
    content = content .. "  REMOTE SPY - RELATÓRIO COMPLETO\n"
    content = content .. "  Gerado em: " .. os.date("%d/%m/%Y %H:%M:%S") .. "\n"
    content = content .. "  Jogo: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "\n"
    content = content .. "  PlaceId: " .. tostring(game.PlaceId) .. "\n"
    content = content .. "  JobId: " .. tostring(game.JobId) .. "\n"
    content = content .. "===========================================\n\n"
    
    -- ====== SEÇÃO 1: TODOS OS REMOTES ======
    content = content .. "===========================================\n"
    content = content .. "  [SEÇÃO 1] TODOS OS REMOTES DETECTADOS\n"
    content = content .. "===========================================\n\n"
    
    local remoteList = {}
    for remote in pairs(Remotes) do
        if remote and remote.Parent then
            table.insert(remoteList, remote)
        end
    end
    
    table.sort(remoteList, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)
    
    -- Agrupa por tipo
    local byType = {
        RemoteEvent = {},
        RemoteFunction = {},
        BindableEvent = {},
        BindableFunction = {},
    }
    
    for _, remote in ipairs(remoteList) do
        local t = remote.ClassName
        if byType[t] then
            table.insert(byType[t], remote)
        end
    end
    
    for remoteType, list in pairs(byType) do
        if #list > 0 then
            content = content .. string.format("--- %s (%d) ---\n", remoteType, #list)
            for _, remote in ipairs(list) do
                content = content .. "  • " .. remote:GetFullName() .. "\n"
            end
            content = content .. "\n"
        end
    end
    
    content = content .. "TOTAL DE REMOTES: " .. #remoteList .. "\n\n"
    
    -- ====== SEÇÃO 2: LOGS DE CHAMADAS ======
    content = content .. "===========================================\n"
    content = content .. "  [SEÇÃO 2] HISTÓRICO DE CHAMADAS\n"
    content = content .. "===========================================\n\n"
    
    if #Logs == 0 then
        content = content .. "Nenhuma chamada capturada ainda.\n\n"
    else
        for i, log in ipairs(Logs) do
            content = content .. string.format("[%d] [%s] %s %s\n", 
                i, log.Time, log.Direction, log.Type)
            content = content .. "    Remote: " .. log.Remote .. "\n"
            content = content .. "    Args: " .. log.Args .. "\n"
            content = content .. "    -----------------------------------\n"
        end
    end
    
    -- ====== SEÇÃO 3: SCRIPT DE REPRODUÇÃO ======
    content = content .. "\n===========================================\n"
    content = content .. "  [SEÇÃO 3] SCRIPT DE USO DOS REMOTES\n"
    content = content .. "===========================================\n\n"
    
    content = content .. "-- Exemplo de uso:\n"
    content = content .. "-- game:GetService(\"ReplicatedStorage\"):FindFirstChild(\"RemoteName\"):FireServer(...)\n\n"
    
    for _, remote in ipairs(remoteList) do
        local path = remote:GetFullName()
        path = path:gsub("^game%.", "")
        path = path:gsub("%.([%w_]+)", ':FindFirstChild("%1")')
        
        if remote:IsA("RemoteEvent") then
            content = content .. string.format('game:%s:FireServer() -- RemoteEvent\n', path)
        elseif remote:IsA("RemoteFunction") then
            content = content .. string.format('game:%s:InvokeServer() -- RemoteFunction\n', path)
        end
    end
    
    content = content .. "\n===========================================\n"
    content = content .. "  FIM DO RELATÓRIO\n"
    content = content .. "===========================================\n"
    
    -- Salvar arquivo
    local success, err = pcall(function()
        if writefile then
            writefile(CONFIG.FileName, content)
        else
            error("Executor sem suporte a writefile")
        end
    end)
    
    if success then
        SetStatus("✓ Arquivo salvo: " .. CONFIG.FileName, Color3.fromRGB(120, 200, 120))
        
        -- Notificação
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Spy - Download",
                Text = "Salvo como: " .. CONFIG.FileName,
                Duration = 5,
            })
        end)
        
        print("[Spy] Arquivo salvo em: " .. CONFIG.FileName)
    else
        SetStatus("✗ Erro: " .. tostring(err), Color3.fromRGB(255, 100, 100))
        warn("[Spy] Erro ao salvar:", err)
    end
end

-- // ============ CONEXÕES GUI ============
GUI.DownloadBtn.MouseButton1Click:Connect(function()
    DownloadRemotes()
end)

GUI.ClearBtn.MouseButton1Click:Connect(function()
    Logs = {}
    for _, child in ipairs(GUI.LogScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    SetStatus("Logs limpos", Color3.fromRGB(255, 200, 100))
end)

GUI.ScanBtn.MouseButton1Click:Connect(function()
    ScanRemotes()
end)

GUI.CloseBtn.MouseButton1Click:Connect(function()
    GUI.ScreenGui:Destroy()
end)

local minimized = false
GUI.MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        GUI.LogScroll.Visible = false
        GUI.Main.Size = UDim2.new(0, 500, 0, 95)
    else
        GUI.LogScroll.Visible = true
        GUI.Main.Size = UDim2.new(0, 500, 0, 400)
    end
end)

-- // ============ MONITORAMENTO ============
-- Detecta novos remotes adicionados
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
       or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
        task.wait(0.1)
        if not Remotes[obj] then
            SpyRemote(obj)
            local total