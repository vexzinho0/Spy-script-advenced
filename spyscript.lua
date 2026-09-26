--[[
    SPY SCRIPT - Rayfield Edition (Delta Executor)
    - Interface moderna com Rayfield
    - Captura todos os Remotes
    - Salva relatório em Delta/Workspace/
--]]

-- // Carrega a Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // Serviços
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- // Configurações
local CONFIG = {
    MaxLogs = 200,
    FileName = "remotes_spy_" .. os.date("%Y%m%d_%H%M%S") .. ".txt",
    FolderPath = "Workspace/",
}

-- // Tabelas
local Remotes = {}
local Logs = {}
local IgnoredRemotes = {}

-- // ============ FUNÇÕES AUXILIARES ============
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
        })
    end)
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
    
    table.insert(Logs, 1, {
        Time = timestamp,
        Remote = remoteName,
        Type = remoteType,
        Direction = direction,
        Args = argsStr,
    })
    if #Logs > CONFIG.MaxLogs then
        table.remove(Logs)
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
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if self == remote and (method == "FireServer" or method == "fire") then
                AddLog(remoteName, remoteType, {...}, "OUT")
            end
            return oldNamecall(self, ...)
        end)
        
        if remoteType == "BindableEvent" then
            remote.Event:Connect(function(...)
                AddLog(remoteName, remoteType, {...}, "OUT")
            end)
        end
    elseif remoteType == "RemoteFunction" or remoteType == "BindableFunction" then
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if self == remote and (method == "InvokeServer" or method == "invoke") then
                AddLog(remoteName, remoteType, {...}, "OUT")
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
end

local function ScanRemotes()
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
    local total = 0
    for _ in pairs(Remotes) do total = total + 1 end
    return count, total
end

-- // ============ GERAR RELATÓRIO ============
local function BuildReport()
    local content = "===========================================\n"
    content = content .. "  REMOTE SPY - RELATÓRIO\n"
    content = content .. "  Data: " .. os.date("%d/%m/%Y %H:%M:%S") .. "\n"
    content = content .. "  PlaceId: " .. tostring(game.PlaceId) .. "\n"
    content = content .. "  JobId: " .. tostring(game.JobId) .. "\n"
    content = content .. "===========================================\n\n"
    
    content = content .. "[SEÇÃO 1] TODOS OS REMOTES\n"
    content = content .. "-------------------------------------------\n\n"
    
    local remoteList = {}
    for remote in pairs(Remotes) do
        if remote and remote.Parent then
            table.insert(remoteList, remote)
        end
    end
    table.sort(remoteList, function(a, b)
        return a:GetFullName() < b:GetFullName()
    end)
    
    local byType = {RemoteEvent={}, RemoteFunction={}, BindableEvent={}, BindableFunction={}}
    for _, r in ipairs(remoteList) do
        if byType[r.ClassName] then
            table.insert(byType[r.ClassName], r)
        end
    end
    
    for t, list in pairs(byType) do
        if #list > 0 then
            content = content .. string.format("--- %s (%d) ---\n", t, #list)
            for _, r in ipairs(list) do
                content = content .. "  • " .. r:GetFullName() .. "\n"
            end
            content = content .. "\n"
        end
    end
    content = content .. "TOTAL: " .. #remoteList .. " remotes\n\n"
    
    content = content .. "[SEÇÃO 2] HISTÓRICO DE CHAMADAS\n"
    content = content .. "-------------------------------------------\n\n"
    
    if #Logs == 0 then
        content = content .. "Nenhuma chamada capturada.\n"
    else
        for i, log in ipairs(Logs) do
            content = content .. string.format("[%d] [%s] %s %s\n", i, log.Time, log.Direction, log.Type)
            content = content .. "  Remote: " .. log.Remote .. "\n"
            content = content .. "  Args: " .. log.Args .. "\n\n"
        end
    end
    
    content = content .. "===========================================\n"
    content = content .. "  FIM\n"
    content = content .. "===========================================\n"
    
    return content, #remoteList
end

-- // ============ CRIAR JANELA RAYFIELD ============
local Window = Rayfield:CreateWindow({
    Name = "🕵️ Spy - Delta Edition",
    LoadingTitle = "Spy Script",
    LoadingSubtitle = "by DeepSeek",
    ConfigurationSaving = {
        Enabled = false,
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- // Aba Principal
local MainTab = Window:CreateTab("Principal", 4483362458) -- Ícone de "eye"

-- // Botão de Scan
local ScanSection = MainTab:CreateSection("Remotes")
local ScanButton = ScanSection:CreateButton({
    Name = "🔍 Escanear Remotes",
    Callback = function()
        local count, total = ScanRemotes()
        Notify("Spy", string.format("✓ %d novos remotes encontrados (Total: %d)", count, total), 5)
    end,
})

-- // Botão de Download
local DownloadButton = ScanSection:CreateButton({
    Name = "⬇ Baixar Relatório Completo",
    Callback = function()
        local content, totalRemotes = BuildReport()
        local fullPath = CONFIG.FolderPath .. CONFIG.FileName
        
        local success, err = pcall(function()
            writefile(fullPath, content)
        end)
        
        if success then
            Notify("Spy", "✅ Arquivo salvo em: " .. fullPath, 5)
            print("========================================")
            print("✅ ARQUIVO SALVO COM SUCESSO!")
            print("📁 Caminho: " .. fullPath)
            print("📊 Remotes: " .. totalRemotes)
            print("📝 Logs: " .. #Logs)
            print("========================================")
        else
            Notify("Spy", "❌ Erro ao salvar: " .. tostring(err), 5)
            warn("[Spy] Erro ao salvar:", err)
        end
    end,
})

-- // Botão de Limpar Logs
local ClearButton = ScanSection:CreateButton({
    Name = "🗑 Limpar Logs",
    Callback = function()
        Logs = {}
        Notify("Spy", "Logs limpos!", 3)
    end,
})

-- // Aba de Informações
local InfoTab = Window:CreateTab("Info", 4483362458)
local InfoSection = InfoTab:CreateSection("Sobre")
InfoSection:CreateLabel("Spy Script - Captura todos os Remotes")
InfoSection:CreateLabel("Salva relatório em: Delta/Workspace/")
InfoSection:CreateLabel("Use o botão 'Baixar Relatório' para gerar o arquivo.")

-- // Monitorar novos remotes
game.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
       or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
        task.wait(0.1)
        if not Remotes[obj] then
            SpyRemote(obj)
            local total = 0
            for _ in pairs(Remotes) do total = total + 1 end
            -- Atualiza notificação (opcional)
        end
    end
end)

-- // Scan inicial
task.spawn(function()
    task.wait(1)
    ScanRemotes()
    Notify("Spy", "Script carregado! Clique em 'Escanear Remotes' para começar.", 5)
end)

print([[
========================================
  🕵️ SPY (RAYFIELD EDITION) CARREGADO
========================================
  📁 Pasta: Delta/Workspace/
  📄 Arquivo: ]] .. CONFIG.FileName .. [[
========================================
]])