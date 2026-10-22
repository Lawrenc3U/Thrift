local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Assets = require(Shared.AssetConfig)
local Audio = {}
Audio.__index = Audio
function Audio.new()
    local self = setmetatable({Music = true, Effects = true, Tracks = {}, Last = {}, Zone = "shop"}, Audio)
    self.Group = Instance.new("SoundGroup"); self.Group.Name = "ThriftAudio"; self.Group.Parent = SoundService
    self.MusicGroup = Instance.new("SoundGroup"); self.MusicGroup.Name = "ThriftMusic"; self.MusicGroup.Parent = self.Group
    self.EffectsGroup = Instance.new("SoundGroup"); self.EffectsGroup.Name = "ThriftEffects"; self.EffectsGroup.Parent = self.Group
    for name, id in pairs(Assets.Audio) do
        if type(id) == "number" and id > 0 then
            local music = name == "shop" or name == "town" or name == "auction_music"
            local sound = Instance.new("Sound"); sound.Name = name; sound.SoundId = "rbxassetid://" .. id
            sound.Looped = music; sound.Volume = if music then Assets.MusicVolume else Assets.EffectsVolume
            sound.SoundGroup = if music then self.MusicGroup else self.EffectsGroup
            sound.Parent = SoundService; self.Tracks[name] = sound
        end
    end
    self:setZone("shop")
    return self
end
function Audio:setEnabled(music, effects)
    self.Music = music ~= false; self.Effects = effects ~= false
    self.MusicGroup.Volume = if self.Music then 1 else 0
    self.EffectsGroup.Volume = if self.Effects then 1 else 0
end
function Audio:setZone(zone)
    if self.Zone == zone and self.Current then return end
    self.Zone = zone
    local nextTrack = self.Tracks[zone]
    if self.Current == nextTrack then return end
    local previous = self.Current
    if previous then
        TweenService:Create(previous, TweenInfo.new(1), {Volume = 0}):Play()
        task.delay(1.1, function() if self.Current ~= previous and previous.Parent then previous:Stop() end end)
    end
    self.Current = nextTrack
    if nextTrack then
        nextTrack.Volume = 0; nextTrack:Play()
        TweenService:Create(nextTrack, TweenInfo.new(1.2), {Volume = Assets.MusicVolume}):Play()
    end
end
function Audio:play(name)
    if not self.Effects then return end
    local sound = self.Tracks[name]
    if not sound then return end
    local now = os.clock()
    if now - (self.Last[name] or -10) < 0.07 then return end
    self.Last[name] = now; sound:Play()
end
function Audio:destroy()
    for _, sound in pairs(self.Tracks) do sound:Destroy() end
    self.Group:Destroy()
end
return Audio
