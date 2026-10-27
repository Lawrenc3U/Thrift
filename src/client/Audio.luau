local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Assets = require(Shared.AssetConfig)
local Audio = {}
Audio.__index = Audio
local MUSIC_NAMES = {"town", "auction_music"}
local function validAudioId(id)
    -- Reject the sample sequence shown in setup documentation. This prevents a
    -- copied example from producing thirteen ContentProvider errors in Studio.
    return type(id) == "number" and id > 0 and id % 1 == 0
        and not (id >= 12345678901 and id <= 12345678913)
end
function Audio.new()
    local self = setmetatable({Music = true, Effects = true, TownMusic = true, AuctionMusic = true,
        Tracks = {}, Last = {}, Zone = "town"}, Audio)
    self.Group = Instance.new("SoundGroup"); self.Group.Name = "ThriftAudio"; self.Group.Parent = SoundService
    self.MusicGroup = Instance.new("SoundGroup"); self.MusicGroup.Name = "ThriftMusic"; self.MusicGroup.Parent = self.Group
    self.EffectsGroup = Instance.new("SoundGroup"); self.EffectsGroup.Name = "ThriftEffects"; self.EffectsGroup.Parent = self.Group
    for name, id in pairs(Assets.Audio) do
        if validAudioId(id) then
            local music = name == "shop" or name == "town" or name == "auction_music"
            local sound = Instance.new("Sound"); sound.Name = name; sound.SoundId = "rbxassetid://" .. id
            sound.Looped = music; sound.Volume = if music then Assets.MusicVolume else Assets.EffectsVolume
            sound.SoundGroup = if music then self.MusicGroup else self.EffectsGroup
            sound.Parent = SoundService; self.Tracks[name] = sound
        end
    end
    local missingMusic = {}
    for _, name in ipairs(MUSIC_NAMES) do
        if not self.Tracks[name] then table.insert(missingMusic, name) end
    end
    if #missingMusic > 0 then
        warn("[THRIFT AUDIO] Music is not configured: " .. table.concat(missingMusic, ", ")
            .. ". Upload the matching WAV files and enter their real Audio asset IDs in AssetConfig.")
    end
    task.delay(8, function()
        for _, name in ipairs(MUSIC_NAMES) do
            local sound = self.Tracks[name]
            if sound and sound.Parent and not sound.IsLoaded then
                warn("[THRIFT AUDIO] " .. name .. " did not load. Verify that " .. sound.SoundId
                    .. " is an Audio asset and that the experience has permission to use it.")
            end
        end
    end)
    self:setZone("town")
    return self
end
function Audio:setEnabled(music, effects, townMusic, auctionMusic)
    local nextMusic, nextTown, nextAuction = music ~= false, townMusic ~= false, auctionMusic ~= false
    local musicChanged = self.Music ~= nextMusic or self.TownMusic ~= nextTown or self.AuctionMusic ~= nextAuction
    self.Music = nextMusic; self.TownMusic = nextTown; self.AuctionMusic = nextAuction; self.Effects = effects ~= false
    self.MusicGroup.Volume = if self.Music then 1 else 0
    self.EffectsGroup.Volume = if self.Effects then 1 else 0
    if musicChanged then self:setZone(self.Zone, true) end
end
function Audio:setZone(zone, force)
    if self.Zone == zone and self.Current and not force then return end
    self.Zone = zone
    local zoneEnabled = zone ~= "town" or self.TownMusic
    zoneEnabled = zoneEnabled and (zone ~= "auction_music" or self.AuctionMusic)
    local nextTrack = if self.Music and zoneEnabled then self.Tracks[zone] else nil
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
