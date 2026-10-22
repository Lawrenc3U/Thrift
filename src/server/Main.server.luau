local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent"); event.Name = "Game"; event.Parent = remotes
local DataService = require(script.Parent.DataService)
local World = require(script.Parent.World)
local GameService = require(script.Parent.GameService)
local ExchangeService = require(script.Parent.ExchangeService)
local LiveService = require(script.Parent.LiveService)
local data = DataService.new()
local world = World.new()
local service = GameService.new(data, world, event)
service.Exchange = ExchangeService.new(data, service)
service.Live = LiveService.new(data, service)
MarketplaceService.ProcessReceipt = function(receipt) return service.Live:processReceipt(receipt) end
task.spawn(function() service.Live:loadProductInfo() end)
event.OnServerEvent:Connect(function(player, action, payload) service:request(player, action, payload) end)
local function connectPrompt(prompt)
    prompt.Triggered:Connect(function(player)
        if not service:profile(player) then return end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root or not prompt.Parent:IsA("BasePart") or (root.Position - prompt.Parent.Position).Magnitude > 16 then return end
        local action, owner = prompt:GetAttribute("Action"), prompt:GetAttribute("Owner")
        if owner ~= 0 and owner ~= player.UserId then
            event:FireClient(player, "Open", {Page = "Visit", Owner = owner}); return
        end
        if action == "Teleport" then
            service:request(player, "Teleport", {Destination = prompt:GetAttribute("Destination")})
        else
            event:FireClient(player, "Open", {Page = action, Slot = prompt:GetAttribute("Slot")})
        end
    end)
end
for _, prompt in ipairs(CollectionService:GetTagged("ThriftInteractable")) do connectPrompt(prompt) end
CollectionService:GetInstanceAddedSignal("ThriftInteractable"):Connect(connectPrompt)
Players.PlayerAdded:Connect(function(player) service:join(player) end)
Players.PlayerRemoving:Connect(function(player) service:leave(player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() service:join(player) end) end
if RunService:IsStudio() then
    local function studioChat(player)
        player.Chatted:Connect(function(message)
            local query = string.match(message, "^[/!]legendary%s*(.*)$")
            if query then
                local ok, result = service:studioLegendary(player, query)
                if not ok then service:notify(player, result) end
            end
        end)
    end
    Players.PlayerAdded:Connect(studioChat)
    for _, player in ipairs(Players:GetPlayers()) do studioChat(player) end
    local command = Instance.new("BindableFunction"); command.Name = "ThriftStudioLegendary"; command.Parent = ServerStorage
    command.OnInvoke = function(playerOrName, query)
        local player = if typeof(playerOrName) == "Instance" and playerOrName:IsA("Player") then playerOrName else Players:FindFirstChild(tostring(playerOrName))
        if not player then return false, "Player not found" end
        return service:studioLegendary(player, query)
    end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    service.Live:passPurchased(player, passId, purchased)
end)
task.spawn(function()
    while not service.Closing do task.wait(1); service:tick() end
end)
task.spawn(function()
    while not service.Closing do
        task.wait(Config.AutosaveSeconds)
        for _, player in ipairs(Players:GetPlayers()) do
            if service:profile(player) and not data.Busy[player.UserId] then
                task.spawn(function()
                    if not service:profile(player) or data.Busy[player.UserId] then return end
                    if not data:save(player.UserId, false) and player.Parent then
                        -- Stop mutations when the lease cannot be renewed. A failed save
                        -- cannot safely coexist with another server acquiring the profile.
                        service.Ready[player.UserId] = nil
                        player:Kick("Save connection interrupted. Please rejoin to protect your progress.")
                    end
                end)
            end
        end
    end
end)
game:BindToClose(function()
    service.Closing = true
    local remaining = 0
    for userId in pairs(data.Profiles) do
        remaining += 1
        task.spawn(function()
            if not data.Closing[userId] then data:release(userId) end
            remaining -= 1
        end)
    end
    local deadline = os.clock() + 25
    while remaining > 0 and os.clock() < deadline do task.wait(0.1) end
end)
