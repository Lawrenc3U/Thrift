local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(ReplicatedStorage.Shared.Config)
local remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = ReplicatedStorage
local event = Instance.new("RemoteEvent"); event.Name = "Game"; event.Parent = remotes
local DataService = require(script.Parent.DataService)
local World = require(script.Parent.World)
local GameService = require(script.Parent.GameService)
local data = DataService.new()
local world = World.new()
local service = GameService.new(data, world, event)
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
        event:FireClient(player, "Open", {Page = action, Slot = prompt:GetAttribute("Slot")})
    end)
end
for _, prompt in ipairs(CollectionService:GetTagged("ThriftInteractable")) do connectPrompt(prompt) end
CollectionService:GetInstanceAddedSignal("ThriftInteractable"):Connect(connectPrompt)
Players.PlayerAdded:Connect(function(player) service:join(player) end)
Players.PlayerRemoving:Connect(function(player) service:leave(player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(function() service:join(player) end) end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
    local theme = Config.CosmeticPasses[passId]
    local profile = service:profile(player)
    if purchased and theme and profile then profile.Themes[theme] = true; service:snapshot(player) end
end)
task.spawn(function()
    while not service.Closing do task.wait(1); service:tick() end
end)
task.spawn(function()
    while not service.Closing do
        task.wait(Config.AutosaveSeconds)
        for _, player in ipairs(Players:GetPlayers()) do
            if service:profile(player) then
                task.spawn(function()
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
