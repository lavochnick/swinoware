repeat task.wait() until game:IsLoaded()

-- EXECUTOR COMPATIBILITY GUARD (Blocks Solara & Xeno)
local function checkExecutor()
    local exName = ""
    pcall(function()
        if identifyexecutor then
            exName = tostring(identifyexecutor())
        elseif getexecutorname then
            exName = tostring(getexecutorname())
        elseif whatexecutor then
            exName = tostring(whatexecutor())
        end
    end)

    local lowerName = string.lower(exName)
    local isBlocked = false
    local blockedReason = ""

    if string.find(lowerName, "solara") or getgenv().SOLARA_VERSION ~= nil or getgenv().SOLARA_LOADED ~= nil or getgenv().solara ~= nil or getgenv().Solara ~= nil then
        isBlocked = true
        blockedReason = "Solara is not supported! Please use a supported executor (Wave, Synapse Z, Macsploit, etc.)."
    elseif string.find(lowerName, "xeno") or getgenv().XENO_LOADED ~= nil or getgenv().xeno ~= nil or getgenv().Xeno ~= nil then
        isBlocked = true
        blockedReason = "Xeno is not supported! Please use a supported executor."
    end

    if isBlocked then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "SWINOWARE - Unsupported Executor",
                Text = blockedReason,
                Duration = 10
            })
        end)
        warn("[SWINOWARE] Blocked unsupported executor: " .. exName .. " | " .. blockedReason)
        return false
    end
    return true
end

if not checkExecutor() then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function CleanExistingGuis()
    local searchContainers = { CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }
    for _, container in pairs(searchContainers) do
        if container then
            for _, child in pairs(container:GetChildren()) do
                if child:IsA("ScreenGui") then
                    local name = string.lower(child.Name)
                    if name == "compkiller" 
                        or child:FindFirstChild("Main") 
                        or child:FindFirstChild("Watermark") 
                        or child:FindFirstChild("Holder")
                        or string.find(name, "mentality") 
                        or string.find(name, "swinoware")
                        or string.find(name, "bsmt") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end
    end
end

if getgenv().SwinowareUnload then
    pcall(getgenv().SwinowareUnload)
end
CleanExistingGuis()

local ScriptRunning = true
local ScriptConnections = {}

-- Respawn & Swim Fixer
if not getgenv()._respawnfixer then
    getgenv()._respawnfixer = true
    local repfirst = game:GetService("ReplicatedFirst")
    
    local function fixRespawn()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        pcall(function()
            local knit = require(ReplicatedStorage.Packages.Knit)
            local swim = knit.GetController("SwimController")
            if swim and swim.RootPart == char then swim.RootPart = hrp end
        end)

        pcall(function()
            local mapView = repfirst.Client.Controllers.InterfaceController.Views.HUD.Map
            local ms = require(mapView.MapState)
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            local content = pg and pg:FindFirstChild("UI") and pg.UI.Container.HUD.Map.Container.Minimap:FindFirstChild("Content")
            if content then
                if not ms.ScaleObject then ms.ScaleObject = content:FindFirstChild("UIScale") end
                if not ms.ContentFrame then ms.ContentFrame = content end
            end
        end)
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        pcall(fixRespawn)
        task.wait(1.5)
        pcall(fixRespawn)
    end)
    task.defer(fixRespawn)
end

-- Silent Aim (Acs Hook & Tracers)

getgenv().enablesga = false
getgenv().wallbang = false
getgenv().wallchecke4e = false
getgenv().tracers = false
getgenv().tracerColor = Color3.fromRGB(125, 120, 255)
getgenv().fov = false
getgenv().fovsize = 90

local currentTarget = nil
local activeTracers = {}

local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = false
    fovCircle.Thickness = 1.5
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.7
    fovCircle.Filled = false
    fovCircle.NumSides = 64
end)

-- Universal ScreenGui FOV Circle for Mobile & Delta iOS
local GuiFovHolder = Instance.new("ScreenGui")
GuiFovHolder.Name = "SwinowareFOV"
GuiFovHolder.ResetOnSpawn = false
GuiFovHolder.IgnoreGuiInset = true
pcall(function() GuiFovHolder.Parent = CoreGui end)
if not GuiFovHolder.Parent then
    pcall(function() GuiFovHolder.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
end

local GuiFovCircle = Instance.new("Frame")
GuiFovCircle.Name = "FOVCircle"
GuiFovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
GuiFovCircle.BackgroundTransparency = 1
GuiFovCircle.BorderSizePixel = 0
GuiFovCircle.Visible = false
GuiFovCircle.Parent = GuiFovHolder

local GuiFovCorner = Instance.new("UICorner", GuiFovCircle)
GuiFovCorner.CornerRadius = UDim.new(1, 0)

local GuiFovStroke = Instance.new("UIStroke", GuiFovCircle)
GuiFovStroke.Color = Color3.fromRGB(255, 255, 255)
GuiFovStroke.Transparency = 0.3
GuiFovStroke.Thickness = 1.5

local function createBeamTracer(startPos, endPos, color)
    if not getgenv().tracers then return end
    
    local part0 = Instance.new("Part")
    part0.Anchored, part0.CanCollide, part0.Transparency = true, false, 1
    part0.Size, part0.CFrame = Vector3.new(0.1, 0.1, 0.1), CFrame.new(startPos)
    part0.Parent = Camera
    
    local part1 = Instance.new("Part")
    part1.Anchored, part1.CanCollide, part1.Transparency = true, false, 1
    part1.Size, part1.CFrame = Vector3.new(0.1, 0.1, 0.1), CFrame.new(endPos)
    part1.Parent = Camera
    
    local a0 = Instance.new("Attachment", part0)
    local a1 = Instance.new("Attachment", part1)
    
    local beam = Instance.new("Beam", part0)
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color or getgenv().tracerColor),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, color or getgenv().tracerColor)
    })
    beam.Width0, beam.Width1 = 0.15, 0.08
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Segments = 1
    
    table.insert(activeTracers, {part0, part1, beam, tick()})
end

-- Whitelist System
getgenv().CombatWhitelist = {}

local function isWhitelisted(player)
    if not player then return false end
    local name = string.lower(player.Name)
    local display = string.lower(player.DisplayName)
    return getgenv().CombatWhitelist[name] == true or getgenv().CombatWhitelist[display] == true
end

local function tovec3(v)
    if typeof(v) == "Vector3" then return v end
    if typeof(v) == "vector" then return Vector3.new(v.X, v.Y, v.Z) end
    return nil
end

local function getSilentAimTarget()
    local closestTarget, minScreenDist = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myTeam = LocalPlayer.Team
    local camPos = Camera.CFrame.Position
    local fovRadius = tonumber(getgenv().fovsize) or 200
    
    -- 1. Check Player Characters
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (not myTeam or plr.Team ~= myTeam) and not isWhitelisted(plr) and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            
            if head and hum and hum.Health > 0 and not char:FindFirstChildOfClass("ForceField") then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                local valid = true
                
                if getgenv().fov then
                    if not onScreen or screenPos.Z <= 0 or screenDist > fovRadius then
                        valid = false
                    end
                elseif not getgenv().wallbang then
                    if screenPos.Z <= 0 then
                        valid = false
                    end
                end
                
                if valid and getgenv().wallchecke4e and not getgenv().wallbang then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, char}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local result = Workspace:Raycast(camPos, head.Position - camPos, rayParams)
                    if result then valid = false end
                end
                
                if valid and screenDist < minScreenDist then
                    minScreenDist = screenDist
                    closestTarget = head
                end
            end
        end
    end

    -- 2. Check Vehicles (Helicopters, Planes, Tanks, Boats)
    if not closestTarget and getgenv().cramTargetVehicles then
        local gs = Workspace:FindFirstChild("Game Systems")
        if gs then
            local vFolders = { "Helicopter Workspace", "Plane Workspace", "Vehicle Workspace", "Tank Workspace", "Boat Workspace", "Drone Workspace" }
            for _, name in ipairs(vFolders) do
                local f = gs:FindFirstChild(name)
                if f then
                    for _, v in ipairs(f:GetChildren()) do
                        local owner = tostring(v:GetAttribute("Owner")):lower()
                        if owner ~= LocalPlayer.Name:lower() and not getgenv().CombatWhitelist[owner] then
                            local p = v:IsA("Model") and (v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")) or v
                            if p and p:IsA("BasePart") then
                                local screenPos, onScreen = Camera:WorldToViewportPoint(p.Position)
                                local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                                local valid = true
                                if getgenv().fov and (not onScreen or screenPos.Z <= 0 or screenDist > fovRadius) then
                                    valid = false
                                end
                                if valid and screenDist < minScreenDist then
                                    minScreenDist = screenDist
                                    closestTarget = p
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end

local bulletSys = ReplicatedStorage:WaitForChild("BulletFireSystem", 10)
local firegunremote = bulletSys and bulletSys:WaitForChild("FireGun", 10)
local bullethitremote = bulletSys and bulletSys:WaitForChild("BulletHit", 10)
local turretHitEvent = bulletSys and bulletSys:WaitForChild("RegisterTurretHit", 10)

local function hookCanRayPierce()
    local char = LocalPlayer.Character
    local acsClient = char and char:FindFirstChild("ACS_Client")
    local fireMod = acsClient and acsClient:FindFirstChild("FireModuleClient")
    if fireMod then
        local ok, m = pcall(require, fireMod)
        if ok and type(m) == "table" and m.CanRayPierce then
            local oldPierce = m.CanRayPierce
            m.CanRayPierce = function(...)
                if getgenv().wallbang then
                    return true
                end
                return oldPierce(...)
            end
        end
    end
end

task.spawn(function()
    pcall(hookCanRayPierce)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        pcall(hookCanRayPierce)
    end)
end)

getgenv()._SilentAimHandler = function(self, method, ...)
    if not getgenv().enablesga or method ~= "FireServer" then return false, nil end

    if self == firegunremote then
        local tgt = getSilentAimTarget()
        currentTarget = tgt
        if tgt and tgt.Parent then
            local args = {...}
            local gunTool = args[2]
            local visualModel = args[3] or gunTool
            local realOrigin = tovec3(args[4]) or (gunTool and gunTool:FindFirstChild("Handle") and gunTool.Handle.Position) or Camera.CFrame.Position
            local delta = tgt.Position - realOrigin
            local dist = delta.Magnitude
            local dir = dist > 0 and delta.Unit or Vector3.new(0, 0, 1)

            -- Redirect direction in FireGun
            if type(args[1]) == "table" then
                local nd = {}
                for i = 1, math.max(#args[1], 1) do
                    nd[i] = dir
                end
                args[1] = nd
            end

            -- Wallbang origin shift
            if getgenv().wallbang then
                local spawnPos = tgt.Position - (dir * 1.5)
                args[4] = spawnPos
            end

            -- Automatically guarantee BulletHit delivery to the target
            if bullethitremote and gunTool then
                local gunSettings = getAcsGunSettings(gunTool)
                local bspeed = (gunSettings and tonumber(gunSettings.BSpeed)) or 2500
                local tt = math.clamp(dist / bspeed, 0.001, 0.4)
                local hitPos = tgt.Position
                local startOrigin = getgenv().wallbang and (hitPos - (dir * 1.2)) or realOrigin

                local bulletPath = {
                    [1] = { [1] = startOrigin, [2] = dir, [3] = 0 },
                    [2] = { [1] = hitPos, [2] = dir, [3] = tt }
                }

                task.spawn(function()
                    task.wait(0.01)
                    pcall(function()
                        bullethitremote:FireServer(gunTool, tgt, hitPos, bulletPath, Vector3.new(0, 1, 0), gunSettings)
                    end)
                end)
            end

            if getgenv().tracers then
                createBeamTracer(realOrigin, tgt.Position, getgenv().tracerColor)
            end

            return true, args
        end

    elseif self == bullethitremote and currentTarget and currentTarget.Parent then
        local args = {...}
        local tgt = currentTarget
        local hp = tgt.Position
        local realOrigin = Camera.CFrame.Position
        if type(args[4]) == "table" and args[4][1] and args[4][1][1] then
            realOrigin = tovec3(args[4][1][1]) or realOrigin
        end
        local delta = hp - realOrigin
        local dist = delta.Magnitude
        local dir = dist > 0 and delta.Unit or Vector3.new(0, 0, 1)

        local startOrigin = getgenv().wallbang and (hp - (dir * 1.2)) or realOrigin
        local startDist = (hp - startOrigin).Magnitude
        local tt = math.clamp(startDist / 2500, 0.001, 0.4)

        args[2] = tgt
        args[3] = hp
        args[4] = {
            [1] = { [1] = startOrigin, [2] = dir, [3] = 0 },
            [2] = { [1] = hp, [2] = dir, [3] = tt }
        }
        args[5] = Vector3.new(0, 1, 0)

        if getgenv().tracers then
            createBeamTracer(realOrigin, hp, getgenv().tracerColor)
        end
        return true, args
    end

    return false, nil
end


if not getgenv()._sgahooked then
    getgenv()._sgahooked = true

    local oldnamecall
    oldnamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if not checkcaller() and getgenv()._SilentAimHandler then
            local handled, newArgs = getgenv()._SilentAimHandler(self, method, ...)
            if handled and newArgs then
                setnamecallmethod(method)
                return oldnamecall(self, unpack(newArgs))
            end
        end

        return oldnamecall(self, ...)
    end))
end

-- Optimized Gun Mods (No-Lag Cache)

getgenv().gm_norecoil = false
getgenv().gm_nospread = false
getgenv().gm_fullauto = false
getgenv().gm_hitscan = false
getgenv().gm_fastreload = false

local acsguns = ReplicatedStorage:WaitForChild("Configurations"):WaitForChild("ACS_Guns")
local origGunSettings = {}

local EXPLOSIVE_GUN_NAMES = {
    ["rpg"] = true, ["stinger"] = true, ["javelin"] = true, 
    ["grenade launcher"] = true, ["mortar"] = true, ["c4"] = true, 
    ["mine"] = true, ["drone"] = true, ["tow"] = true
}

local function isExplosiveGun(gunName)
    local n = string.lower(tostring(gunName or ""))
    for k, _ in pairs(EXPLOSIVE_GUN_NAMES) do
        if n:find(k) then return true end
    end
    return false
end

local function applyGunMods(gunModel, s)
    if not origGunSettings[s] then
        origGunSettings[s] = {
            VPunchBase = s.VPunchBase, HPunchBase = s.HPunchBase, DPunchBase = s.DPunchBase,
            RecoilPunch = s.RecoilPunch, MinRecoilPower = s.MinRecoilPower, MaxRecoilPower = s.MaxRecoilPower,
            RecoilPowerStepAmount = s.RecoilPowerStepAmount, PunchRecover = s.PunchRecover, AimRecover = s.AimRecover,
            AimRecoilReduction = s.AimRecoilReduction,
            VRecoil = type(s.VRecoil) == "table" and { s.VRecoil[1], s.VRecoil[2] } or nil,
            HRecoil = type(s.HRecoil) == "table" and { s.HRecoil[1], s.HRecoil[2] } or nil,
            MinSpread = s.MinSpread, MaxSpread = s.MaxSpread, AimInaccuracyStepAmount = s.AimInaccuracyStepAmount,
            WalkMultiplier = s.WalkMultiplier, SwayBase = s.SwayBase, BDrop = s.BDrop,
            Mode = s.Mode, BSpeed = s.BSpeed, FastReload = s.FastReload, AutoChamber = s.AutoChamber,
            ChamberWhileAim = s.ChamberWhileAim, IncludeChamberedBullet = s.IncludeChamberedBullet,
            ReloadTime = s.ReloadTime, TacReloadTime = s.TacReloadTime, Cooldown = s.Cooldown
        }
    end
    local o = origGunSettings[s]
    local isExplosive = isExplosiveGun(gunModel and gunModel.Name)

    -- Recoil Mods
    if getgenv().gm_norecoil then
        if s.VRecoil then s.VRecoil[1] = 0 s.VRecoil[2] = 0 end
        if s.HRecoil then s.HRecoil[1] = 0 s.HRecoil[2] = 0 end
        s.VPunchBase, s.HPunchBase, s.DPunchBase, s.RecoilPunch = 0, 0, 0, 0
        s.MinRecoilPower, s.MaxRecoilPower, s.RecoilPowerStepAmount = 0, 0, 0
        s.PunchRecover, s.AimRecover, s.AimRecoilReduction = 1, 1, 20
    else
        if o.VRecoil and s.VRecoil then s.VRecoil[1], s.VRecoil[2] = o.VRecoil[1], o.VRecoil[2] end
        if o.HRecoil and s.HRecoil then s.HRecoil[1], s.HRecoil[2] = o.HRecoil[1], o.HRecoil[2] end
        s.VPunchBase, s.HPunchBase, s.DPunchBase, s.RecoilPunch = o.VPunchBase, o.HPunchBase, o.DPunchBase, o.RecoilPunch
        s.MinRecoilPower, s.MaxRecoilPower, s.RecoilPowerStepAmount = o.MinRecoilPower, o.MaxRecoilPower, o.RecoilPowerStepAmount
        s.PunchRecover, s.AimRecover, s.AimRecoilReduction = o.PunchRecover, o.AimRecover, o.AimRecoilReduction
    end

    -- Spread Mods
    if getgenv().gm_nospread then
        s.MinSpread, s.MaxSpread, s.AimInaccuracyStepAmount = 0, 0, 0
        s.WalkMultiplier, s.SwayBase, s.BDrop = 0, 0, 0
    else
        s.MinSpread, s.MaxSpread, s.AimInaccuracyStepAmount = o.MinSpread, o.MaxSpread, o.AimInaccuracyStepAmount
        s.WalkMultiplier, s.SwayBase, s.BDrop = o.WalkMultiplier, o.SwayBase, o.BDrop
    end

    -- Full Auto (Only for regular guns, NEVER for explosive weapons)
    if not isExplosive then
        s.Mode = getgenv().gm_fullauto and "Auto" or o.Mode
    else
        s.Mode = o.Mode
    end

    -- Hitscan Bullet Speed
    s.BSpeed = getgenv().gm_hitscan and 99999 or o.BSpeed

    -- Safe Fast Reload (Never brick ACS state machine)
    if getgenv().gm_fastreload and not isExplosive then
        s.FastReload, s.AutoChamber, s.ChamberWhileAim, s.IncludeChamberedBullet = true, true, true, true
        if o.ReloadTime ~= nil then s.ReloadTime = math.max(o.ReloadTime * 0.4, 0.45) end
        if o.TacReloadTime ~= nil then s.TacReloadTime = math.max(o.TacReloadTime * 0.4, 0.45) end
    else
        s.FastReload, s.AutoChamber = o.FastReload, o.AutoChamber
        s.ChamberWhileAim, s.IncludeChamberedBullet = o.ChamberWhileAim, o.IncludeChamberedBullet
        if o.ReloadTime ~= nil then s.ReloadTime = o.ReloadTime end
        if o.TacReloadTime ~= nil then s.TacReloadTime = o.TacReloadTime end
        if o.Cooldown ~= nil then s.Cooldown = o.Cooldown end
    end
end

local function syncAllGunMods()
    for _, gun in ipairs(acsguns:GetChildren()) do
        local set = gun:FindFirstChild("Settings") or gun:FindFirstChild("GunSettings")
        if set then
            local ok, s = pcall(require, set)
            if ok and type(s) == "table" then
                pcall(applyGunMods, gun, s)
            end
        end
    end
end

-- Gun Kill Aura (Optimized Sweep)

local WarTycoonSettings = {
    GunKillAura = false,
    KillAuraRange = 2500,
    KillAuraDelay = 0.05,
    KillAuraHitPart = "Head"
}

local function getEquippedGun()
    local char = LocalPlayer.Character
    if char then
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Tool") and not string.find(string.lower(item.Name), "rpg") then
                return item, char:FindFirstChild("S" .. item.Name) or item
            end
        end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and not string.find(string.lower(item.Name), "rpg") then
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:EquipTool(item)
                end
                return item, char and char:FindFirstChild("S" .. item.Name) or item
            end
        end
    end
    return nil, nil
end

local function getAcsGunSettings(gunTool)
    if not gunTool then return nil end
    local configs = ReplicatedStorage:FindFirstChild("Configurations")
    local acsGuns = configs and configs:FindFirstChild("ACS_Guns")
    if acsGuns then
        local gunConfig = acsGuns:FindFirstChild(gunTool.Name)
        if gunConfig then
            local settingsMod = gunConfig:FindFirstChild("Settings") or gunConfig:FindFirstChild("GunSettings")
            if settingsMod and settingsMod:IsA("ModuleScript") then
                local ok, res = pcall(require, settingsMod)
                if ok and type(res) == "table" then return res end
            end
        end
    end
    return { ["FireRate"] = 750, ["MaxSpread"] = 40, ["Mode"] = "Auto", ["Distance"] = 3200, ["BSpeed"] = 2200 }
end

local function sendCompleteGunShot(targetPart, targetPosition)
    if not targetPart then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local gunTool, visualModel = getEquippedGun()
    if not gunTool then return end
    visualModel = visualModel or gunTool

    local bulletSys = ReplicatedStorage:FindFirstChild("BulletFireSystem")
    local fgRemote = bulletSys and bulletSys:FindFirstChild("FireGun")
    local bhRemote = bulletSys and bulletSys:FindFirstChild("BulletHit")
    if not bhRemote then return end

    local gunSettings = getAcsGunSettings(gunTool)
    local hitPos = targetPosition or targetPart.Position
    local origin = (gunTool:FindFirstChild("Handle") and gunTool.Handle.Position) 
        or (char:FindFirstChild("Head") and char.Head.Position) or root.Position
        
    local delta = hitPos - origin
    local dist = delta.Magnitude
    local dir = dist > 0 and delta.Unit or Vector3.new(0, 0, 1)

    if fgRemote then
        task.spawn(function()
            pcall(function()
                fgRemote:FireServer({ [1] = vector.create(dir.X, dir.Y, dir.Z) }, gunTool, visualModel, origin, false)
            end)
        end)
    end

    local bspeed = (gunSettings and tonumber(gunSettings.BSpeed)) or 2500
    local tt = dist / bspeed

    local bulletPath = {
        [1] = { [1] = vector.create(origin.X, origin.Y, origin.Z), [2] = vector.create(dir.X, dir.Y, dir.Z), [3] = 0 },
        [2] = { [1] = vector.create(hitPos.X, hitPos.Y, hitPos.Z), [2] = vector.create(dir.X, dir.Y, dir.Z), [3] = tt }
    }

    pcall(function()
        bhRemote:FireServer(gunTool, targetPart, vector.create(hitPos.X, hitPos.Y, hitPos.Z), bulletPath, vector.create(0, 1, 0), gunSettings)
    end)
end

task.spawn(function()
    while ScriptRunning do
        if WarTycoonSettings.GunKillAura then
            pcall(function()
                local myChar = LocalPlayer.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myTeam = LocalPlayer.Team

                if myRoot then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if not WarTycoonSettings.GunKillAura or not ScriptRunning then break end

                        if player ~= LocalPlayer and player.Team ~= myTeam and not isWhitelisted(player) then
                            local char = player.Character
                            if char and not char:FindFirstChildOfClass("ForceField") then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                local targetPart = char:FindFirstChild(WarTycoonSettings.KillAuraHitPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")

                                if targetPart and hum and hum.Health > 0 then
                                    local dist = (myRoot.Position - targetPart.Position).Magnitude
                                    if dist <= WarTycoonSettings.KillAuraRange then
                                        sendCompleteGunShot(targetPart, targetPart.Position)
                                        if WarTycoonSettings.KillAuraDelay > 0 then
                                            task.wait(WarTycoonSettings.KillAuraDelay)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.04)
        else
            task.wait(0.3)
        end
    end
end)

-- Rocket Spam & Manipulation

getgenv().spamrockets = false
getgenv().rocketmods = false
getgenv().rm_turnspeed = 0
getgenv().rm_velocity = 0
getgenv().rm_expradius = 0
getgenv().rm_accel = 0
getgenv().rm_nogravity = false
getgenv().rm_instanthoming = false
getgenv().rm_trackdist = 0
getgenv().rm_trackangle = 0
getgenv().rm_battery = 0
getgenv().rm_proxfuse = 0
getgenv().rm_ignorewalls = false
getgenv().instantrocketreload = false

local rocketsystem = ReplicatedStorage:WaitForChild("RocketSystem")
local firebindable = rocketsystem.Events:WaitForChild("FireRocketBindable")
local fireremote = rocketsystem.Events:WaitForChild("FireRocket")
local hithremote = rocketsystem.Events:WaitForChild("RocketHit")
local rocketsfolder = rocketsystem:WaitForChild("Rockets")
local rpgrocket = rocketsfolder:WaitForChild("RPG Rocket")

local spamconnection = nil
local rocketcount = 0
local primedTools = {}

local function getclosestrockettarget()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local origin = hrp.Position
    local closest, best = nil, math.huge
    local myTeam = LocalPlayer.Team
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= myTeam and not isWhitelisted(plr) and plr.Character then
            local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if thrp and hum and hum.Health > 0 then
                local d = (thrp.Position - origin).Magnitude
                if d < best then best = d closest = thrp end
            end
        end
    end
    return closest
end

local function getRPGTool()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and (string.find(tool.Name, "RPG") or string.find(tool.Name, "Stinger") or string.find(tool.Name, "Javelin")) then
            return tool
        end
    end
    return nil
end

local function getorigin(tool)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.Position + Vector3.new(0, 2, 0)
    end
    return Vector3.new(0, 0, 0)
end

local function primerocket(tool)
    if primedTools[tool] then return end
    local settings = nil
    pcall(function() settings = require(tool:WaitForChild("RocketSettings")) end)
    if not settings then return end
    
    local origin = getorigin(tool)
    local direction = Camera.CFrame.LookVector
    
    local rocketmodel = tool.Name == "RPG" and rpgrocket or rocketsfolder:FindFirstChild(tool.Name .. " G-Rocket")
    if tool.Name ~= "RPG" and rocketmodel and rocketmodel:IsA("ObjectValue") then
        rocketmodel = rocketmodel.Value
    end
    
    pcall(function()
        fireremote:InvokeServer({
            Direction = direction, Settings = settings, Origin = origin,
            RocketModel = rocketmodel, Vehicle = tool, PlrFired = LocalPlayer, Weapon = tool
        })
        primedTools[tool] = true
    end)
end

local function startspam()
    if spamconnection then return end

    spamconnection = RunService.Heartbeat:Connect(function()
        if not getgenv().spamrockets or not ScriptRunning then
            if spamconnection then spamconnection:Disconnect() spamconnection = nil end
            return
        end

        local tool = getRPGTool()
        if not tool then return end

        if not primedTools[tool] then
            primerocket(tool)
        end

        local origin = getorigin(tool)
        local direction = Camera.CFrame.LookVector
        local settings = nil
        pcall(function() settings = require(tool:WaitForChild("RocketSettings")) end)
        if not settings then return end

        local rocketmodel
        local target = nil
        if tool.Name == "RPG" then
            rocketmodel = rpgrocket
        else
            local obj = rocketsfolder:FindFirstChild(tool.Name .. " G-Rocket")
            rocketmodel = (obj and obj:IsA("ObjectValue")) and obj.Value or obj
            target = getclosestrockettarget()
        end

        if not rocketmodel then return end
        rocketcount = rocketcount + 1

        firebindable:Fire(LocalPlayer, {
            Origin = origin, Direction = direction, Settings = settings,
            RocketModel = rocketmodel, Vehicle = tool, Weapon = tool,
            PlrFired = LocalPlayer, Label = LocalPlayer.Name .. "Rocket" .. rocketcount, Target = target
        })
    end)
    table.insert(ScriptConnections, spamconnection)
end

task.spawn(function()
    while ScriptRunning do
        if getgenv().spamrockets and not spamconnection then
            startspam()
        elseif not getgenv().spamrockets and spamconnection then
            spamconnection:Disconnect()
            spamconnection = nil
        end
        task.wait(0.08)
    end
end)

-- Instant Rocket Reload & Rocket Mods
local origRocketSettings = {}
local rocketguns = { "RPG", "Stinger", "Javelin", "Grenade Launcher" }

local function syncRocketReload()
    for _, name in ipairs(rocketguns) do
        local g = acsguns:FindFirstChild(name)
        local set = g and (g:FindFirstChild("Settings") or g:FindFirstChild("GunSettings"))
        if set then
            local ok, s = pcall(require, set)
            if ok and type(s) == "table" then
                if not origRocketSettings[s] then
                    origRocketSettings[s] = {
                        Cooldown = s.Cooldown,
                        ReloadTime = s.ReloadTime,
                        TacReloadTime = s.TacReloadTime
                    }
                end
                local o = origRocketSettings[s]
                if getgenv().instantrocketreload then
                    s.Cooldown = 0.1
                    s.ReloadTime = 0.3
                    s.TacReloadTime = 0.3
                else
                    if o.Cooldown ~= nil then s.Cooldown = o.Cooldown end
                    if o.ReloadTime ~= nil then s.ReloadTime = o.ReloadTime end
                    if o.TacReloadTime ~= nil then s.TacReloadTime = o.TacReloadTime end
                end
            end
        end
    end
end

if not getgenv()._rocketmods_hooked then
    getgenv()._rocketmods_hooked = true
    local oldnc
    oldnc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local a = { ... }

        if getgenv().rocketmods and self == firebindable and method == "Fire" then
            local rargs = a[2]
            if type(rargs) == "table" and type(rargs.Settings) == "table" then
                local s = rargs.Settings
                if getgenv().rm_instanthoming then
                    if s.TurnSpeed ~= nil then s.TurnSpeed = 1 end
                    if s.WireTurnSpeed ~= nil then s.WireTurnSpeed = 1 end
                    if s.ActivateDistance ~= nil then s.ActivateDistance = 0 end
                elseif getgenv().rm_turnspeed and getgenv().rm_turnspeed > 0 then
                    local ts = getgenv().rm_turnspeed / 100
                    if s.TurnSpeed ~= nil then s.TurnSpeed = ts end
                    if s.WireTurnSpeed ~= nil then s.WireTurnSpeed = ts end
                end
                if getgenv().rm_velocity and getgenv().rm_velocity > 0 then
                    if s.velocity ~= nil then s.velocity = getgenv().rm_velocity end
                    if s.CloseVelocity ~= nil then s.CloseVelocity = getgenv().rm_velocity end
                end
                if getgenv().rm_accel and getgenv().rm_accel > 0 and s.Acceleration ~= nil then s.Acceleration = getgenv().rm_accel end
                if getgenv().rm_expradius and getgenv().rm_expradius > 0 and s.ExpRadius ~= nil then s.ExpRadius = getgenv().rm_expradius end
                if getgenv().rm_nogravity and s.gravity ~= nil then s.gravity = Vector3.new(0, 0, 0) end
                if getgenv().rm_trackdist and getgenv().rm_trackdist > 0 and s.TrackingDistance ~= nil then s.TrackingDistance = getgenv().rm_trackdist end
                if getgenv().rm_trackangle and getgenv().rm_trackangle > 0 and s.TrackingAngle ~= nil then s.TrackingAngle = getgenv().rm_trackangle end
                if getgenv().rm_battery and getgenv().rm_battery > 0 and s.BatteryLife ~= nil then s.BatteryLife = getgenv().rm_battery end
                if getgenv().rm_proxfuse and getgenv().rm_proxfuse > 0 and s.ProximityFuseRadius ~= nil then s.ProximityFuseRadius = getgenv().rm_proxfuse end
            end
            setnamecallmethod("Fire")
            return oldnc(self, unpack(a))
        end

        if getgenv().rm_ignorewalls and self == hithremote and method == "FireServer" then
            local t = a[1]
            if type(t) == "table" and typeof(t.Target) == "Instance" then
                local tgt, pos = t.Target, nil
                if tgt:IsA("BasePart") then pos = tgt.Position
                elseif tgt:IsA("Model") then
                    local part = tgt:FindFirstChild("HumanoidRootPart") or tgt.PrimaryPart
                    pos = part and part.Position or tgt:GetPivot().Position
                end
                if pos then t.Position = pos end
            end
            setnamecallmethod("FireServer")
            return oldnc(self, unpack(a))
        end

        return oldnc(self, ...)
    end))
end

-- Stinger Orbit
getgenv().stingerorbit = false
getgenv().so_radius = 45

local bait = Instance.new("Part")
bait.Name = "Swinoware_OrbitBait"
bait.Anchored, bait.CanCollide, bait.Transparency = true, false, 1
bait.Size = Vector3.new(2, 2, 2)
bait.Parent = Workspace

local orbitAng = 0
local orbitConn = RunService.Heartbeat:Connect(function(dt)
    if not getgenv().stingerorbit or not ScriptRunning then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local r = math.max(getgenv().so_radius or 45, 30)
    local center = hrp.Position + Vector3.new(0, 5, 0)
    orbitAng = orbitAng + dt * 2
    bait.Position = center + Vector3.new(math.cos(orbitAng) * r, 0, math.sin(orbitAng) * r)
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("Target") and tool.Target:IsA("ObjectValue") then
        tool.Target.Value = bait
    end
end)
table.insert(ScriptConnections, orbitConn)

-- CRAM Kill Aura
getgenv().cramKillAura = false
getgenv().cramTargetPlayers = true
getgenv().cramTargetVehicles = true
getgenv().cramMaxDistance = 3200

local turretHitEvent = ReplicatedStorage.BulletFireSystem:WaitForChild("RegisterTurretHit")
local cachedCram, cachedSmoke = nil, nil

local function getMyCram()
    if cachedCram and cachedCram.Parent and cachedSmoke and cachedSmoke.Parent then
        return cachedCram, cachedSmoke
    end
    if not LocalPlayer.Team then return nil, nil end
    local tycoon = Workspace.Tycoon.Tycoons:FindFirstChild(LocalPlayer.Team.Name)
    local cram = tycoon and tycoon:FindFirstChild("PurchasedObjects") and tycoon.PurchasedObjects:FindFirstChild("CRAM")
    if cram and cram:FindFirstChild("CRAM") then
        cachedCram = cram.CRAM
        cachedSmoke = cachedCram:FindFirstChild("SmokePart")
        return cachedCram, cachedSmoke
    end
    return nil, nil
end

local function getCramTarget()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest, closestDist = nil, getgenv().cramMaxDistance
    local myTeam = LocalPlayer.Team

    if getgenv().cramTargetPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team ~= myTeam and not isWhitelisted(p) and p.Character then
                local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if phrp and hum and hum.Health > 0 then
                    local d = (hrp.Position - phrp.Position).Magnitude
                    if d < closestDist then closestDist = d closest = phrp end
                end
            end
        end
    end

    local gs = Workspace:FindFirstChild("Game Systems")
    if gs and getgenv().cramTargetVehicles then
        local vFolders = { "Helicopter Workspace", "Plane Workspace", "Vehicle Workspace", "Tank Workspace", "Boat Workspace", "Drone Workspace" }
        for _, name in ipairs(vFolders) do
            local f = gs:FindFirstChild(name)
            if f then
                for _, v in ipairs(f:GetChildren()) do
                    local owner = tostring(v:GetAttribute("Owner")):lower()
                    if owner ~= LocalPlayer.Name:lower() and not getgenv().CombatWhitelist[owner] then
                        local p = v:IsA("Model") and (v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")) or v
                        if p and p:IsA("BasePart") then
                            local d = (hrp.Position - p.Position).Magnitude
                            if d < closestDist then closestDist = d closest = p end
                        end
                    end
                end
            end
        end
    end

    return closest
end

task.spawn(function()
    while ScriptRunning do
        if getgenv().cramKillAura then
            pcall(function()
                local cram, smoke = getMyCram()
                if cram and smoke then
                    local target = getCramTarget()
                    if target then
                        local origin = smoke.Position
                        local targetPos = target.Position
                        turretHitEvent:FireServer(cram, smoke, cram, {
                            ["normal"] = Vector3.new(0, 1, 0), ["hitPart"] = target,
                            ["origin"] = origin, ["hitPoint"] = targetPos, ["direction"] = (targetPos - origin).Unit
                        }, {
                            ["OverheatCount"] = 150, ["CooldownTime"] = 4, ["BulletSpread"] = 0.8, ["FireRate"] = 1000
                        })
                    end
                end
            end)
            task.wait(0.08)
        else
            task.wait(0.4)
        end
    end
end)

-- Auto Build Tycoon
-- =========================================================================
-- HIGH-PERFORMANCE AUTO BUILD & COLLECTIBLES FARM ENGINE (UNDETECTED)
-- =========================================================================

getgenv().autobuy = false
getgenv().targetlowest = true
getgenv().targetrebirth = false
getgenv().prioritize_income = true
getgenv().autocollectcash = false

getgenv().autofarmcrates = false
getgenv().targetCrates = true
getgenv().targetOilBarrels = true
getgenv().targetResearch = true
getgenv().targetAirdrops = true
getgenv().targetMedalsCash = true

local function parseCashValue(text)
    if not text then return 0 end
    local str = tostring(text):gsub("%$", ""):gsub("%+", ""):gsub(",", ""):gsub("%s+", ""):upper()
    local num = tonumber(str:match("[%d%.]+")) or 0
    if str:find("B") then return num * 1000000000
    elseif str:find("M") then return num * 1000000
    elseif str:find("K") then return num * 1000 end
    return num
end

local function getStats()
    local cash = 0
    local rebirths = 0

    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local cVal = ls:FindFirstChild("Cash") or ls:FindFirstChild("Money") or ls:FindFirstChild("Currency")
        if cVal then
            if type(cVal.Value) == "number" then
                cash = cVal.Value
            else
                cash = parseCashValue(cVal.Value)
            end
        end
        local rVal = ls:FindFirstChild("Rebirths") or ls:FindFirstChild("Rebirth")
        if rVal then
            if type(rVal.Value) == "number" then
                rebirths = rVal.Value
            else
                rebirths = parseCashValue(rVal.Value)
            end
        end
    end

    if cash == 0 then
        pcall(function()
            for _, d in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if d:IsA("TextLabel") and d.Visible and #d.Text > 0 then
                    local pName = d.Parent and d.Parent.Name:lower() or ""
                    local dName = d.Name:lower()
                    if (pName:find("cash") or pName:find("currency") or dName:find("cash")) and (d.Text:find("%$") or d.Text:find("%d")) then
                        local c = parseCashValue(d.Text)
                        if c > cash then cash = c end
                    end
                end
            end
        end)
    end

    if cash == 0 then
        cash = 999999999
    end

    return cash, rebirths
end

local function getMyTycoon()
    local tycoons = Workspace:FindFirstChild("Tycoon") and Workspace.Tycoon:FindFirstChild("Tycoons")
    if not tycoons then return nil end
    local myName = string.lower(LocalPlayer.Name)
    local myTeam = LocalPlayer.Team

    if myTeam and myTeam.Name ~= "Loading" and myTeam.Name ~= "Neutral" then
        local teamTycoon = tycoons:FindFirstChild(myTeam.Name)
        if teamTycoon then return teamTycoon end
    end

    for _, t in ipairs(tycoons:GetChildren()) do
        local owner = t:FindFirstChild("Owner")
        if owner then
            if owner:IsA("ObjectValue") and (owner.Value == LocalPlayer or (owner.Value and string.lower(owner.Value.Name) == myName)) then
                return t
            elseif owner:IsA("StringValue") and string.lower(owner.Value) == myName then
                return t
            end
        end
        local ownerAttr = t:GetAttribute("Owner")
        if ownerAttr and string.lower(tostring(ownerAttr)) == myName then
            return t
        end
    end

    return nil
end

local function getTycoonPath()
    local tycoon = getMyTycoon()
    return tycoon and (tycoon:FindFirstChild("UnpurchasedButtons") or tycoon:FindFirstChild("Buttons"))
end

local function isIncomeButton(name)
    local n = string.lower(tostring(name or ""))
    return n:find("oil") 
        or n:find("extractor") 
        or n:find("generator") 
        or n:find("solar") 
        or n:find("factory") 
        or n:find("income") 
        or n:find("barrel") 
        or n:find("mine") 
        or n:find("collector") 
        or n:find("worker") 
        or n:find("dropper")
end

local function isNearAnyNPC(pos, maxDistance)
    if not pos then return false end
    maxDistance = maxDistance or 20
    local npcsFolder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Bots")
    if npcsFolder then
        for _, m in ipairs(npcsFolder:GetChildren()) do
            if m:IsA("Model") then
                local p = m:GetPivot().Position
                if (p - pos).Magnitude <= maxDistance then
                    return true
                end
            end
        end
    end
    return false
end

local function isButtonAttachedToNPC(model)
    if not model then return true end
    local cur = model
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and cur:FindFirstChildOfClass("Humanoid") then
            return true
        end
        local n = cur.Name:lower()
        if n:find("npc") or n:find("quest") or n:find("guard") or n:find("dealer") or n:find("soldier") or n:find("bot") then
            return true
        end
        cur = cur.Parent
    end
    if model:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return false
end

local function isItemAttachedToNPC(item)
    if not item then return true end
    local cur = item
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and cur ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(cur) then
            if cur:FindFirstChildOfClass("Humanoid") or cur:FindFirstChild("HumanoidRootPart") or cur:FindFirstChildOfClass("ForceField") then
                return true
            end
            local n = cur.Name:lower()
            if n:find("npc") or n:find("quest") or n:find("guard") or n:find("dealer") or n:find("soldier") or n:find("bot") or n:find("talk") then
                return true
            end
        end
        cur = cur.Parent
    end
    local p = item:IsA("BasePart") and item.Position or (item:IsA("Model") and item:GetPivot().Position or nil)
    if p and isNearAnyNPC(p, 25) then
        return true
    end
    return false
end

local function isIgnoredPrompt(prompt)
    if not prompt then return true end
    local text = string.lower(tostring(prompt.ActionText or "") .. " " .. tostring(prompt.ObjectText or ""))
    if text:find("talk") 
        or text:find("speak") 
        or text:find("quest") 
        or text:find("dialogue") 
        or text:find("interact") 
        or text:find("deliver")
        or text:find("operation")
        or text:find("bunker") then
        return true
    end
    return false
end

local BlacklistedButtons = {}

local function getTycoonButtons()
    local path = getTycoonPath()
    if not path then return {} end

    local now = tick()
    local cash, rebirths = getStats()
    local buttons = {}

    for _, model in ipairs(path:GetChildren()) do
        if model:IsA("Model") and not isButtonAttachedToNPC(model) then
            if not BlacklistedButtons[model] or now > BlacklistedButtons[model] then
                local bType = tostring(model:GetAttribute("ButtonType") or "Cash")
                local nameLower = string.lower(model.Name)
                
                -- Extract Price
                local priceNum = 0
                local priceAttr = model:GetAttribute("Price") or model:GetAttribute("Cost")
                if priceAttr then
                    priceNum = (type(priceAttr) == "number") and priceAttr or (parseCashValue(priceAttr))
                end
                if priceNum == 0 then
                    local pVal = model:FindFirstChild("Price") or model:FindFirstChild("Cost")
                    if pVal and pVal:IsA("ValueBase") then priceNum = parseCashValue(pVal.Value) end
                end

                -- Extract Rebirth Requirement
                local reqNum = 0
                local rebirthAttr = model:GetAttribute("RebirthRequirement") or model:GetAttribute("Rebirth")
                if rebirthAttr then
                    reqNum = (type(rebirthAttr) == "number") and rebirthAttr or (parseCashValue(rebirthAttr))
                end
                if reqNum == 0 then
                    local rVal = model:FindFirstChild("RebirthRequirement") or model:FindFirstChild("Rebirth")
                    if rVal and rVal:IsA("ValueBase") then reqNum = parseCashValue(rVal.Value) end
                end

                -- Scan BillboardGui/TextLabels for Rebirth Requirements
                for _, d in ipairs(model:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text and #d.Text > 0 then
                        local tLow = d.Text:lower()
                        if tLow:find("rebirth") or tLow:find("reb") then
                            local rMatch = tLow:match("rebirth%s*(%d+)") or tLow:match("(%d+)%s*rebirth") or tLow:match("reb%s*(%d+)")
                            if rMatch then
                                local rFound = tonumber(rMatch) or 0
                                if rFound > reqNum then reqNum = rFound end
                            end
                        end
                        if priceNum == 0 and (tLow:find("%$") or tLow:find("cost") or tLow:find("price")) then
                            local cFound = parseCashValue(d.Text)
                            if cFound > priceNum then priceNum = cFound end
                        end
                    end
                end

                -- Rebirth Filter: If button requires more rebirths than player has, or if targetrebirth is false
                local isBuyable = true
                if reqNum > 0 or bType == "Rebirth" or nameLower:find("rebirth") then
                    if not getgenv().targetrebirth or rebirths < reqNum then
                        isBuyable = false
                    end
                end

                -- Block non-buildable types (Gamepasses, Robux, Operations, Medals)
                if nameLower:find("giver") 
                    or nameLower:find("clothing") 
                    or nameLower:find("gamepass") 
                    or nameLower:find("operation")
                    or nameLower:find("medal")
                    or nameLower:find("robux")
                    or bType == "Reward" 
                    or bType == "Operation" 
                    or bType == "Clothing" 
                    or bType == "Gamepass" 
                    or bType == "Medal" 
                    or bType == "Robux" 
                    or bType == "DevProduct" then
                    isBuyable = false
                end

                if isBuyable then
                    local parts = {}
                    local mainPart = model:FindFirstChild("Neon") 
                        or model:FindFirstChild("Head") 
                        or model:FindFirstChild("Pad") 
                        or model:FindFirstChild("Hitbox") 
                        or model:FindFirstChild("Part") 
                        or model.PrimaryPart

                    for _, p in ipairs(model:GetDescendants()) do
                        if p:IsA("BasePart") then
                            table.insert(parts, p)
                            if not mainPart and (p.Name == "Neon" or p.Name == "Head" or p.Name == "Pad" or p.Name == "Hitbox") then
                                mainPart = p
                            end
                        end
                    end
                    mainPart = mainPart or parts[1]

                    if mainPart then
                        table.insert(buttons, {
                            model = model,
                            name = model.Name,
                            type = (reqNum > 0 or bType == "Rebirth") and "Rebirth" or "Cash",
                            mainPart = mainPart,
                            parts = parts,
                            isIncome = isIncomeButton(model.Name),
                            price = priceNum,
                            rebirthReq = reqNum
                        })
                    end
                end
            end
        end
    end
    return buttons
end

local function collectTycoonCash()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local tycoon = getMyTycoon()
    if not tycoon or not hrp then return end

    local ess = tycoon:FindFirstChild("Essentials")
    local cp = ess and (ess:FindFirstChild("CollectorParts") or ess:FindFirstChild("Collector") or ess:FindFirstChild("Oil Collector"))

    if cp or ess then
        for _, p in ipairs((cp or ess):GetDescendants()) do
            if p:IsA("BasePart") and (p.Name:lower():find("collect") or p.Name:lower():find("pad") or p.Name:lower():find("cash") or p.Name == "Part") then
                pcall(function()
                    if firetouchinterest then
                        firetouchinterest(hrp, p, 0)
                        task.wait(0.02)
                        firetouchinterest(hrp, p, 1)
                    end
                end)
            end
        end
    end
end

-- Auto Collect Cash loop
task.spawn(function()
    while ScriptRunning do
        if getgenv().autocollectcash then
            pcall(collectTycoonCash)
            task.wait(2.0)
        else
            task.wait(1.5)
        end
    end
end)

-- Safe & Active Auto Buy Tycoon with Anti-Stick Protection
task.spawn(function()
    while ScriptRunning do
        if getgenv().autobuy then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then return end

                local buttons = getTycoonButtons()
                if #buttons == 0 then
                    pcall(collectTycoonCash)
                    task.wait(1.0)
                    return
                end

                local incomeButtons = {}
                local normalButtons = {}
                for _, btn in ipairs(buttons) do
                    if btn.isIncome and getgenv().prioritize_income then
                        table.insert(incomeButtons, btn)
                    else
                        table.insert(normalButtons, btn)
                    end
                end

                local targetBtn = incomeButtons[1] or normalButtons[1]
                if targetBtn and targetBtn.model and targetBtn.model.Parent then
                    local targetPart = targetBtn.mainPart
                    if targetPart and targetPart.Parent then
                        -- Position character directly on button pad
                        local targetPos = targetPart.Position + Vector3.new(0, 1.2, 0)
                        hrp.CFrame = CFrame.new(targetPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero

                        -- Physical touch interest
                        if firetouchinterest then
                            pcall(function()
                                firetouchinterest(hrp, targetPart, 0)
                                task.wait(0.01)
                                firetouchinterest(hrp, targetPart, 1)
                            end)
                            for _, p in ipairs(targetBtn.parts or {}) do
                                if p ~= targetPart then
                                    pcall(function()
                                        firetouchinterest(hrp, p, 0)
                                        task.wait(0.01)
                                        firetouchinterest(hrp, p, 1)
                                    end)
                                end
                            end
                        end

                        for _, d in ipairs(targetBtn.model:GetDescendants()) do
                            if d:IsA("ProximityPrompt") and d.Enabled then
                                pcall(function()
                                    if fireproximityprompt then fireproximityprompt(d, 0) end
                                end)
                            end
                        end

                        task.wait(0.25)

                        -- Anti-Stick: If button was not bought (e.g. not enough cash/rebirth), blacklist for 45s so we move on!
                        if targetBtn.model and targetBtn.model.Parent then
                            BlacklistedButtons[targetBtn.model] = tick() + 45
                        end
                    end
                else
                    pcall(collectTycoonCash)
                    task.wait(0.8)
                end
            end)
            task.wait(0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- Collectibles & Airdrop Farm
local function collectibles()
    local gs = Workspace:FindFirstChild("Game Systems")
    return gs and gs:FindFirstChild("Collectibles Workspace")
end

local function carryingCrate()
    local char = LocalPlayer.Character
    if not char then return false end
    return char:FindFirstChild("CrateWeld") ~= nil 
        or char:FindFirstChild("Crate") ~= nil 
        or char:FindFirstChild("PartCrate") ~= nil
        or char:FindFirstChild("AirDrop") ~= nil
        or char:FindFirstChild("OilBarrel") ~= nil
        or char:FindFirstChild("ResearchPile") ~= nil
end

local function getCollectorPrompt()
    local myTycoon = getMyTycoon()
    if not myTycoon then return nil, nil end

    local ess = myTycoon:FindFirstChild("Essentials")
    local oil = ess and ess:FindFirstChild("Oil Collector")
    local per = oil and oil:FindFirstChild("Persistant")
    local part = per and per:FindFirstChild("CratePromptPart")
    if not part and ess then
        for _, d in ipairs(ess:GetDescendants()) do
            if d:IsA("BasePart") and (d.Name == "CratePromptPart" or d:FindFirstChild("DepositPrompt")) then
                part = d
                break
            end
        end
    end
    if not part then return nil, nil end

    local prompt = part:FindFirstChild("DepositPrompt")
    if not prompt then
        for _, d in ipairs(part:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d break end
        end
    end
    return prompt, part
end

local BlacklistedCrates = {}

local function getBestCollectible()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil, nil end

    local col = collectibles()
    if not col then return nil, nil, nil end

    local now = tick()
    for item, exp in pairs(BlacklistedCrates) do
        if now > exp then BlacklistedCrates[item] = nil end
    end

    local targets = {}
    local foldersToCheck = {}
    if getgenv().targetCrates then table.insert(foldersToCheck, "PartCrate") end
    if getgenv().targetOilBarrels then table.insert(foldersToCheck, "OilBarrel") end
    if getgenv().targetResearch then table.insert(foldersToCheck, "ResearchPile") end
    if getgenv().targetAirdrops then table.insert(foldersToCheck, "AirDrop") end
    if getgenv().targetMedalsCash then
        table.insert(foldersToCheck, "MedalBox")
        table.insert(foldersToCheck, "CashPile")
        table.insert(foldersToCheck, "ResearchDocument")
        table.insert(foldersToCheck, "MunitionBackpack")
    end

    for _, fName in ipairs(foldersToCheck) do
        local folder = col:FindFirstChild(fName)
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                if item:IsA("Model") and not item:GetAttribute("Disabled") and not BlacklistedCrates[item] and not isItemAttachedToNPC(item) then
                    local mainPart = item:FindFirstChild("MainPart") or item.PrimaryPart
                    local prompt = nil
                    for _, d in ipairs(item:GetDescendants()) do
                        if not mainPart and d:IsA("BasePart") then mainPart = d end
                        if not prompt and d:IsA("ProximityPrompt") then prompt = d end
                    end
                    if mainPart and prompt and prompt.Enabled and not isIgnoredPrompt(prompt) and not isItemAttachedToNPC(mainPart) then
                        local dist = (mainPart.Position - hrp.Position).Magnitude
                        table.insert(targets, {item = item, part = mainPart, prompt = prompt, dist = dist})
                    end
                end
            end
        end
    end

    if #targets == 0 then return nil, nil, nil end
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    local best = targets[1]
    return best.item, best.part, best.prompt
end

local function returnToSafeBase()
    pcall(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            local myTycoon = getMyTycoon()
            if myTycoon then
                local ess = myTycoon:FindFirstChild("Essentials")
                local spawnPart = (ess and (ess:FindFirstChild("BaseSpawn") or ess:FindFirstChild("Spawn Visualizer"))) 
                    or myTycoon:FindFirstChild("Floor") 
                    or (ess and ess:FindFirstChild("Part")) 
                    or myTycoon.PrimaryPart
                if spawnPart then
                    hrp.CFrame = CFrame.new(spawnPart.Position + Vector3.new(0, 3.5, 0))
                end
            end
        end
    end)
end

-- Safe Controlled NoClip (Never drops under map)
local cachedCharParts = {}
local function updateCachedParts()
    cachedCharParts = {}
    local char = LocalPlayer.Character
    if char then
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then 
                table.insert(cachedCharParts, p) 
            end
        end
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateCachedParts()
end)
updateCachedParts()

RunService.Stepped:Connect(function()
    if (getgenv().autofarmcrates or getgenv().noclip) and ScriptRunning then
        for i = 1, #cachedCharParts do
            local p = cachedCharParts[i]
            if p and p.CanCollide then p.CanCollide = false end
        end
    end
end)

-- Fast, Snappy, Lag-Free Transit (0 FPS Drop)
local function fastGlideTo(targetPos, duration)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    duration = duration or 0.35
    local startPos = hrp.Position
    local startT = tick()

    while tick() - startT < duration and ScriptRunning and getgenv().autofarmcrates do
        local alpha = math.clamp((tick() - startT) / duration, 0, 1)
        local curPos = startPos:Lerp(targetPos, alpha)
        hrp.CFrame = CFrame.new(curPos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
    end
    hrp.CFrame = CFrame.new(targetPos)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- Simple & Reliable Collectibles Farm with Post-Deposit Cooldown
local POST_DEPOSIT_COOLDOWN = 6.0 -- Cooldown in seconds after delivering a crate to base

task.spawn(function()
    local wasFarming = false
    while ScriptRunning do
        if getgenv().autofarmcrates then
            wasFarming = true
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if hrp and hum and hum.Health > 0 then
                    if carryingCrate() then
                        -- 1. DEPOSIT TO BASE
                        local depositPrompt, depositPart = getCollectorPrompt()
                        if depositPrompt and depositPart then
                            local destPos = depositPart.Position + Vector3.new(0, 2.0, 0)
                            fastGlideTo(destPos, 0.35)

                            task.wait(0.3)

                            local startT = tick()
                            while carryingCrate() and getgenv().autofarmcrates and ScriptRunning and (tick() - startT < 2.5) do
                                pcall(function()
                                    if fireproximityprompt then
                                        fireproximityprompt(depositPrompt, 0)
                                        fireproximityprompt(depositPrompt)
                                    end
                                end)
                                task.wait(0.3)
                            end

                            -- Crate delivered! Wait for safe cooldown so game conveyor resets
                            task.wait(POST_DEPOSIT_COOLDOWN)
                        else
                            returnToSafeBase()
                            task.wait(0.5)
                        end
                    else
                        -- 2. PICKUP NEXT CRATE
                        local targetItem, targetPart, targetPrompt = getBestCollectible()
                        if targetItem and targetPart and targetPrompt and not isItemAttachedToNPC(targetItem) then
                            local targetPos = targetPart.Position + Vector3.new(0, 2.0, 0)
                            fastGlideTo(targetPos, 0.35)

                            task.wait(0.2)

                            local startT = tick()
                            while not carryingCrate() and targetItem.Parent and not targetItem:GetAttribute("Disabled") and getgenv().autofarmcrates and ScriptRunning and (tick() - startT < 1.5) do
                                pcall(function()
                                    if fireproximityprompt then
                                        fireproximityprompt(targetPrompt, 0)
                                        fireproximityprompt(targetPrompt)
                                    end
                                end)
                                task.wait(0.25)
                            end

                            if not carryingCrate() and targetItem.Parent then
                                BlacklistedCrates[targetItem] = tick() + 30
                            end

                            task.wait(0.2)
                        end
                    end
                end
            end)
            task.wait(0.1)
        else
            if wasFarming then
                wasFarming = false
            end
            task.wait(0.4)
        end
    end
end)

-- Euphoria / Silentware 2D ScreenGui ESP Engine

local ESP = {
    Enabled = false,
    TeamCheck = false,
    MaxDistance = 3500,
    FontSize = 13,
    FadeOut = {
        OnDistance = true,
    },
    Options = {
        Friendcheck = false,
        FriendcheckRGB = Color3.fromRGB(50, 255, 120),
    },
    Drawing = {
        Chams = {
            Enabled = false,
            Thermal = false,
            FillRGB = Color3.fromRGB(170, 85, 255),
            OutlineRGB = Color3.fromRGB(255, 255, 255),
            Fill_Transparency = 50,
            Outline_Transparency = 0,
            AlwaysOnTop = true,
        },
        Names = {
            Enabled = true,
            RGB = Color3.fromRGB(255, 255, 255),
        },
        Distances = {
            Enabled = true,
            Position = "Bottom",
        },
        Weapons = {
            Enabled = true,
            WeaponTextRGB = Color3.fromRGB(170, 85, 255),
        },
        Healthbar = {
            Enabled = true,
            Width = 2.5,
            Lerp = true,
            HealthText = true,
            HealthTextRGB = Color3.fromRGB(255, 255, 255),
            Gradient = false,
            GradientRGB1 = Color3.fromRGB(0, 255, 0),
            GradientRGB2 = Color3.fromRGB(255, 255, 0),
            GradientRGB3 = Color3.fromRGB(255, 0, 0),
        },
        Boxes = {
            Animate = true,
            RotationSpeed = 250,
            Gradient = false,
            GradientRGB1 = Color3.fromRGB(170, 85, 255),
            GradientRGB2 = Color3.fromRGB(0, 0, 0), 
            GradientFill = true,
            GradientFillRGB1 = Color3.fromRGB(170, 85, 255),
            GradientFillRGB2 = Color3.fromRGB(0, 0, 0), 
            Filled = {
                Enabled = true,
                Transparency = 0.75,
                RGB = Color3.fromRGB(0, 0, 0),
            },
            Full = {
                Enabled = true,
                RGB = Color3.fromRGB(255, 255, 255),
            },
            Corner = {
                Enabled = false,
                RGB = Color3.fromRGB(255, 255, 255),
            },
        },
        Tracers = {
            Enabled = false,
            RGB = Color3.fromRGB(170, 85, 255),
        },
        HeadDot = {
            Enabled = false,
            RGB = Color3.fromRGB(255, 0, 0),
        }
    }
}

local RotationAngle, TickTime = -45, tick()

local ESPFunctions = {}
function ESPFunctions:Create(Class, Properties)
    local inst = typeof(Class) == "string" and Instance.new(Class) or Class
    for prop, val in pairs(Properties) do
        inst[prop] = val
    end
    return inst
end

local ESPHolder = ESPFunctions:Create("ScreenGui", {
    Parent = CoreGui,
    Name = "ESPHolder",
    ResetOnSpawn = false,
    IgnoreGuiInset = true
})

local PlayerESPEntries = {}
local WeaponCache = {}
local WeaponCacheTick = 0

local function getEquippedWeapon(plr)
    local cached = WeaponCache[plr]
    if cached then return cached end
    if plr.Character then
        local tool = plr.Character:FindFirstChildOfClass("Tool")
        if tool then
            WeaponCache[plr] = tool.Name
            return tool.Name
        end
    end
    return "none"
end

local function removePlayerESP(plr)
    local entry = PlayerESPEntries[plr]
    if entry then
        PlayerESPEntries[plr] = nil
        pcall(function() entry.PlayerContainer:Destroy() end)
        pcall(function() entry.TracerLine:Remove() end)
        pcall(function() entry.HeadDotCircle:Remove() end)
        pcall(function() entry.HeadDotOutline:Remove() end)
    end
end

local function createPlayerESP(plr)
    if plr == LocalPlayer then return end
    removePlayerESP(plr)

    local PlayerContainer = ESPFunctions:Create("Folder", {
        Parent = ESPHolder,
        Name = plr.Name
    })

    local Name = ESPFunctions:Create("TextLabel", {Parent = PlayerContainer, Size = UDim2.new(0, 140, 0, 18), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
    local Distance = ESPFunctions:Create("TextLabel", {Parent = PlayerContainer, Size = UDim2.new(0, 100, 0, 18), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
    local Weapon = ESPFunctions:Create("TextLabel", {Parent = PlayerContainer, Size = UDim2.new(0, 140, 0, 18), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = ESP.Drawing.Weapons.WeaponTextRGB, Font = Enum.Font.Code, TextSize = ESP.FontSize, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), RichText = true, Visible = false})
    
    local Box = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.75, BorderSizePixel = 0, Visible = false})
    local Gradient1 = ESPFunctions:Create("UIGradient", {Parent = Box, Enabled = ESP.Drawing.Boxes.GradientFill, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientFillRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientFillRGB2)}})
    local Outline = ESPFunctions:Create("UIStroke", {Parent = Box, Enabled = true, Transparency = 0, Color = Color3.fromRGB(255, 255, 255), LineJoinMode = Enum.LineJoinMode.Miter})
    local Gradient2 = ESPFunctions:Create("UIGradient", {Parent = Outline, Enabled = ESP.Drawing.Boxes.Gradient, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Boxes.GradientRGB1), ColorSequenceKeypoint.new(1, ESP.Drawing.Boxes.GradientRGB2)}})
    
    local Healthbar = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, BorderSizePixel = 0, Visible = false})
    local BehindHealthbar = ESPFunctions:Create("Frame", {Parent = PlayerContainer, ZIndex = -1, BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0, BorderSizePixel = 0, Visible = false})
    local HealthbarGradient = ESPFunctions:Create("UIGradient", {Parent = Healthbar, Enabled = ESP.Drawing.Healthbar.Gradient, Rotation = -90, Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ESP.Drawing.Healthbar.GradientRGB1), ColorSequenceKeypoint.new(0.5, ESP.Drawing.Healthbar.GradientRGB2), ColorSequenceKeypoint.new(1, ESP.Drawing.Healthbar.GradientRGB3)}})
    local HealthText = ESPFunctions:Create("TextLabel", {Parent = PlayerContainer, Size = UDim2.new(0, 60, 0, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.Code, TextSize = ESP.FontSize - 1, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(0, 0, 0), Visible = false})
    
    local Chams = ESPFunctions:Create("Highlight", {Parent = PlayerContainer, FillTransparency = 0.5, OutlineTransparency = 0, OutlineColor = ESP.Drawing.Chams.OutlineRGB, FillColor = ESP.Drawing.Chams.FillRGB, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false})
    
    local LeftTop = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})
    local LeftSide = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})
    local RightTop = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})
    local RightSide = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})
    local BottomSide = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})
    local BottomDown = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})
    local BottomRightSide = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})
    local BottomRightDown = ESPFunctions:Create("Frame", {Parent = PlayerContainer, BackgroundColor3 = ESP.Drawing.Boxes.Corner.RGB, BorderSizePixel = 0, Visible = false})

    local TracerLine = Drawing.new("Line")
    TracerLine.Thickness = 1
    TracerLine.Visible = false

    local HeadDotCircle = Drawing.new("Circle")
    HeadDotCircle.Radius = 3.5
    HeadDotCircle.Filled = true
    HeadDotCircle.Visible = false

    local HeadDotOutline = Drawing.new("Circle")
    HeadDotOutline.Radius = 4.5
    HeadDotOutline.Filled = false
    HeadDotOutline.Thickness = 1.5
    HeadDotOutline.Color = Color3.new(0,0,0)
    HeadDotOutline.Visible = false

    local isFriend = false
    pcall(function() isFriend = LocalPlayer:IsFriendsWith(plr.UserId) end)

    PlayerESPEntries[plr] = {
        Player = plr,
        PlayerContainer = PlayerContainer,
        Name = Name,
        Distance = Distance,
        Weapon = Weapon,
        Box = Box,
        Outline = Outline,
        Gradient1 = Gradient1,
        Gradient2 = Gradient2,
        Healthbar = Healthbar,
        BehindHealthbar = BehindHealthbar,
        HealthbarGradient = HealthbarGradient,
        HealthText = HealthText,
        Chams = Chams,
        LeftTop = LeftTop,
        LeftSide = LeftSide,
        RightTop = RightTop,
        RightSide = RightSide,
        BottomSide = BottomSide,
        BottomDown = BottomDown,
        BottomRightSide = BottomRightSide,
        BottomRightDown = BottomRightDown,
        TracerLine = TracerLine,
        HeadDotCircle = HeadDotCircle,
        HeadDotOutline = HeadDotOutline,
        IsFriend = isFriend,
        RotationAngle = -45,
        LastTick = tick(),
        IsHidden = true
    }
end

local function hideSingleESP(entry)
    if entry.IsHidden then return end
    entry.IsHidden = true
    entry.Box.Visible = false
    entry.Name.Visible = false
    entry.Distance.Visible = false
    entry.Weapon.Visible = false
    entry.Healthbar.Visible = false
    entry.BehindHealthbar.Visible = false
    entry.HealthText.Visible = false
    entry.LeftTop.Visible = false
    entry.LeftSide.Visible = false
    entry.BottomSide.Visible = false
    entry.BottomDown.Visible = false
    entry.RightTop.Visible = false
    entry.RightSide.Visible = false
    entry.BottomRightSide.Visible = false
    entry.BottomRightDown.Visible = false
    entry.Chams.Enabled = false
    entry.TracerLine.Visible = false
    entry.HeadDotCircle.Visible = false
    entry.HeadDotOutline.Visible = false
end

-- Fast Batch ESP Render Loop (Zero Lag / 1 Unified Connection)
local espWasEnabled = false
local espBatchConn = RunService.RenderStepped:Connect(function()
    if not ScriptRunning then return end

    if not ESP.Enabled then
        if espWasEnabled then
            espWasEnabled = false
            for _, entry in pairs(PlayerESPEntries) do
                hideSingleESP(entry)
            end
        end
        return
    end
    espWasEnabled = true

    local now = tick()
    if now - WeaponCacheTick > 0.4 then
        WeaponCache = {}
        WeaponCacheTick = now
    end

    local camPos = Camera.CFrame.Position
    local viewX = Camera.ViewportSize.X
    local viewY = Camera.ViewportSize.Y
    local maxDist = ESP.MaxDistance

    for plr, entry in pairs(PlayerESPEntries) do
        local char = plr.Character
        if not char or not plr.Parent then
            hideSingleESP(entry)
        else
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")

            if hrp and hum and hum.Health > 0 then
                local dist = (camPos - hrp.Position).Magnitude

                if dist > maxDist or (ESP.TeamCheck and plr.Team == LocalPlayer.Team) then
                    hideSingleESP(entry)
                else
                    local topPos = head and (head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.35, 0)) or (hrp.Position + Vector3.new(0, 2.4, 0))
                    local bottomPos = hrp.Position - Vector3.new(0, 3.0, 0)

                    local topScreen, topVis = Camera:WorldToViewportPoint(topPos)
                    local bottomScreen, botVis = Camera:WorldToViewportPoint(bottomPos)
                    local hrpScreen, hrpVis = Camera:WorldToViewportPoint(hrp.Position)

                    if topScreen.Z > 0 and (topVis or botVis or hrpVis) then
                        entry.IsHidden = false
                        local h = math.abs(bottomScreen.Y - topScreen.Y)
                        local w = math.clamp(h * 0.52, 8, 700)
                        local centerX = hrpScreen.X
                        local topY = math.min(topScreen.Y, bottomScreen.Y)
                        local bottomY = topY + h

                        local alpha = ESP.FadeOut.OnDistance and math.max(0.05, 1 - (dist / maxDist)) or 1
                        local invAlpha = 1 - alpha

                        -- 1. Full Box
                        if ESP.Drawing.Boxes.Full.Enabled then
                            entry.Box.Position = UDim2.new(0, centerX - w / 2, 0, topY)
                            entry.Box.Size = UDim2.new(0, w, 0, h)
                            entry.Box.Visible = true
                            entry.Outline.Color = ESP.Drawing.Boxes.Full.RGB or Color3.fromRGB(255, 255, 255)
                            entry.Outline.Transparency = invAlpha
                            if ESP.Drawing.Boxes.Filled.Enabled then
                                entry.Box.BackgroundTransparency = math.clamp(ESP.Drawing.Boxes.Filled.Transparency + invAlpha, 0, 1)
                            else
                                entry.Box.BackgroundTransparency = 1
                            end
                        else
                            entry.Box.Visible = false
                        end

                        -- 2. Corner Boxes
                        local isCorner = ESP.Drawing.Boxes.Corner.Enabled
                        if isCorner then
                            local cornerCol = ESP.Drawing.Boxes.Corner.RGB or Color3.fromRGB(255, 255, 255)
                            local cornerLen = math.clamp(w * 0.25, 3, 20)
                            local thick = 1
                            local lt, ls = entry.LeftTop, entry.LeftSide
                            local rt, rs = entry.RightTop, entry.RightSide
                            local bs, bd = entry.BottomSide, entry.BottomDown
                            local brs, brd = entry.BottomRightSide, entry.BottomRightDown

                            lt.Visible = true; lt.Position = UDim2.new(0, centerX - w / 2, 0, topY); lt.Size = UDim2.new(0, cornerLen, 0, thick); lt.BackgroundColor3 = cornerCol; lt.BackgroundTransparency = invAlpha
                            ls.Visible = true; ls.Position = UDim2.new(0, centerX - w / 2, 0, topY); ls.Size = UDim2.new(0, thick, 0, cornerLen); ls.BackgroundColor3 = cornerCol; ls.BackgroundTransparency = invAlpha
                            rt.Visible = true; rt.Position = UDim2.new(0, centerX + w / 2 - cornerLen, 0, topY); rt.Size = UDim2.new(0, cornerLen, 0, thick); rt.BackgroundColor3 = cornerCol; rt.BackgroundTransparency = invAlpha
                            rs.Visible = true; rs.Position = UDim2.new(0, centerX + w / 2 - thick, 0, topY); rs.Size = UDim2.new(0, thick, 0, cornerLen); rs.BackgroundColor3 = cornerCol; rs.BackgroundTransparency = invAlpha
                            bs.Visible = true; bs.Position = UDim2.new(0, centerX - w / 2, 0, bottomY - thick); bs.Size = UDim2.new(0, cornerLen, 0, thick); bs.BackgroundColor3 = cornerCol; bs.BackgroundTransparency = invAlpha
                            bd.Visible = true; bd.Position = UDim2.new(0, centerX - w / 2, 0, bottomY - cornerLen); bd.Size = UDim2.new(0, thick, 0, cornerLen); bd.BackgroundColor3 = cornerCol; bd.BackgroundTransparency = invAlpha
                            brs.Visible = true; brs.Position = UDim2.new(0, centerX + w / 2 - cornerLen, 0, bottomY - thick); brs.Size = UDim2.new(0, cornerLen, 0, thick); brs.BackgroundColor3 = cornerCol; brs.BackgroundTransparency = invAlpha
                            brd.Visible = true; brd.Position = UDim2.new(0, centerX + w / 2 - thick, 0, bottomY - cornerLen); brd.Size = UDim2.new(0, thick, 0, cornerLen); brd.BackgroundColor3 = cornerCol; brd.BackgroundTransparency = invAlpha
                        else
                            entry.LeftTop.Visible = false; entry.LeftSide.Visible = false
                            entry.RightTop.Visible = false; entry.RightSide.Visible = false
                            entry.BottomSide.Visible = false; entry.BottomDown.Visible = false
                            entry.BottomRightSide.Visible = false; entry.BottomRightDown.Visible = false
                        end

                        -- 3. Healthbar
                        if ESP.Drawing.Healthbar.Enabled then
                            local hp = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            local barOffset = 5
                            local barW = ESP.Drawing.Healthbar.Width

                            entry.Healthbar.Visible = true
                            entry.Healthbar.Position = UDim2.new(0, centerX - w / 2 - barOffset - barW, 0, bottomY - h * hp)
                            entry.Healthbar.Size = UDim2.new(0, barW, 0, h * hp)
                            entry.Healthbar.BackgroundTransparency = invAlpha
                            entry.BehindHealthbar.Visible = true
                            entry.BehindHealthbar.Position = UDim2.new(0, centerX - w / 2 - barOffset - barW - 1, 0, topY - 1)
                            entry.BehindHealthbar.Size = UDim2.new(0, barW + 2, 0, h + 2)
                            entry.BehindHealthbar.BackgroundTransparency = invAlpha

                            if ESP.Drawing.Healthbar.HealthText and hp < 1 then
                                entry.HealthText.Text = string.format("%d", math.floor(hp * 100))
                                entry.HealthText.Position = UDim2.new(0, centerX - w / 2 - barOffset - barW - 14, 0, bottomY - h * hp)
                                entry.HealthText.Visible = true
                                entry.HealthText.TextTransparency = invAlpha
                                entry.HealthText.TextStrokeTransparency = invAlpha
                            else
                                entry.HealthText.Visible = false
                            end

                            if ESP.Drawing.Healthbar.Lerp then
                                entry.Healthbar.BackgroundColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), hp)
                            else
                                entry.Healthbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            end
                        else
                            entry.Healthbar.Visible = false
                            entry.BehindHealthbar.Visible = false
                            entry.HealthText.Visible = false
                        end

                        -- 4. Names
                        if ESP.Drawing.Names.Enabled then
                            entry.Name.Visible = true
                            entry.Name.TextSize = ESP.FontSize
                            entry.Name.Position = UDim2.new(0, centerX, 0, topY - 10)
                            entry.Name.TextTransparency = invAlpha
                            entry.Name.TextStrokeTransparency = invAlpha
                            if ESP.Options.Friendcheck and entry.IsFriend then
                                entry.Name.Text = "[F] " .. plr.Name
                                entry.Name.TextColor3 = ESP.Options.FriendcheckRGB or Color3.fromRGB(50, 255, 120)
                            else
                                entry.Name.Text = plr.Name
                                entry.Name.TextColor3 = ESP.Drawing.Names.RGB or Color3.fromRGB(255, 255, 255)
                            end
                        else
                            entry.Name.Visible = false
                        end

                        -- 5. Distance
                        if ESP.Drawing.Distances.Enabled then
                            entry.Distance.Visible = true
                            if ESP.Drawing.Distances.Position == "Bottom" then
                                entry.Distance.Position = UDim2.new(0, centerX, 0, bottomY + 10)
                            else
                                entry.Distance.Position = UDim2.new(0, centerX, 0, topY - 24)
                            end
                            entry.Distance.TextSize = ESP.FontSize
                            entry.Distance.TextColor3 = ESP.Drawing.Names.RGB or Color3.fromRGB(255, 255, 255)
                            entry.Distance.Text = string.format("%d studs", math.floor(dist))
                            entry.Distance.TextTransparency = invAlpha
                            entry.Distance.TextStrokeTransparency = invAlpha
                        else
                            entry.Distance.Visible = false
                        end

                        -- 6. Weapon
                        if ESP.Drawing.Weapons.Enabled then
                            local wep = getEquippedWeapon(plr)
                            entry.Weapon.Text = "[" .. wep .. "]"
                            entry.Weapon.TextSize = ESP.FontSize
                            entry.Weapon.TextColor3 = ESP.Drawing.Weapons.WeaponTextRGB or Color3.fromRGB(170, 85, 255)
                            local weaponY = (ESP.Drawing.Distances.Enabled and ESP.Drawing.Distances.Position == "Bottom") and (bottomY + 22) or (bottomY + 10)
                            entry.Weapon.Position = UDim2.new(0, centerX, 0, weaponY)
                            entry.Weapon.Visible = true
                            entry.Weapon.TextTransparency = invAlpha
                            entry.Weapon.TextStrokeTransparency = invAlpha
                        else
                            entry.Weapon.Visible = false
                        end

                        -- 7. Chams
                        if ESP.Drawing.Chams.Enabled then
                            entry.Chams.Adornee = char
                            entry.Chams.Enabled = true
                            local chamColor = ESP.Drawing.Chams.FillRGB
                            if hasForceField and hasForceField(char) then
                                chamColor = Color3.fromRGB(0, 255, 0)
                            elseif plr.Team and plr.Team.TeamColor then
                                chamColor = plr.Team.TeamColor.Color
                            end
                            entry.Chams.FillColor = chamColor
                            entry.Chams.OutlineColor = ESP.Drawing.Chams.OutlineRGB
                            entry.Chams.FillTransparency = math.clamp(ESP.Drawing.Chams.Fill_Transparency / 100 + invAlpha * 0.5, 0, 1)
                            entry.Chams.OutlineTransparency = math.clamp(ESP.Drawing.Chams.Outline_Transparency / 100 + invAlpha * 0.5, 0, 1)
                            entry.Chams.DepthMode = ESP.Drawing.Chams.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                        else
                            entry.Chams.Enabled = false
                        end

                        -- 8. Tracers
                        if ESP.Drawing.Tracers.Enabled then
                            entry.TracerLine.From = Vector2.new(viewX / 2, viewY)
                            entry.TracerLine.To = Vector2.new(centerX, bottomY)
                            entry.TracerLine.Color = ESP.Drawing.Tracers.RGB
                            entry.TracerLine.Transparency = alpha
                            entry.TracerLine.Visible = true
                        else
                            entry.TracerLine.Visible = false
                        end

                        -- 9. Head Dot
                        if ESP.Drawing.HeadDot.Enabled and head then
                            local hScr, hVis = Camera:WorldToViewportPoint(head.Position)
                            if hVis and hScr.Z > 0 then
                                entry.HeadDotCircle.Position = Vector2.new(hScr.X, hScr.Y)
                                entry.HeadDotCircle.Color = ESP.Drawing.HeadDot.RGB
                                entry.HeadDotCircle.Transparency = alpha
                                entry.HeadDotCircle.Visible = true

                                entry.HeadDotOutline.Position = Vector2.new(hScr.X, hScr.Y)
                                entry.HeadDotOutline.Transparency = alpha
                                entry.HeadDotOutline.Visible = true
                            else
                                entry.HeadDotCircle.Visible = false
                                entry.HeadDotOutline.Visible = false
                            end
                        else
                            entry.HeadDotCircle.Visible = false
                            entry.HeadDotOutline.Visible = false
                        end

                    else
                        hideSingleESP(entry)
                    end
                end
            else
                hideSingleESP(entry)
            end
        end
    end
end)
table.insert(ScriptConnections, espBatchConn)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createPlayerESP(p)
    end
end

table.insert(ScriptConnections, Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        createPlayerESP(p)
    end
end))

table.insert(ScriptConnections, Players.PlayerRemoving:Connect(function(p)
    removePlayerESP(p)
end))



-- Custom Crosshair (Smooth No-Flicker & Dynamic Bloom)

getgenv().customcrosshair = false
getgenv().cross_color = Color3.fromRGB(0, 255, 170)
getgenv().cross_thickness = 2
getgenv().cross_size = 8
getgenv().cross_gap = 4
getgenv().cross_dot = true
getgenv().cross_dotsize = 2
getgenv().cross_outline = true
getgenv().cross_tstyle = false
getgenv().cross_always = false

local function getGameCrosshair()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local statusUI = pg and pg:FindFirstChild("StatusUI")
    return statusUI and statusUI:FindFirstChild("Crosshair")
end

local function getDynamicSpread(gameCross)
    if not gameCross then return 0 end
    local up = gameCross:FindFirstChild("Up")
    local right = gameCross:FindFirstChild("Right")
    local spreadY = (up and up.Position.Y.Offset ~= 0) and math.abs(up.Position.Y.Offset) or 0
    local spreadX = (right and right.Position.X.Offset ~= 0) and math.abs(right.Position.X.Offset) or 0
    return math.max(spreadY, spreadX)
end

local function suppressGameCrosshair(gameCross)
    if not gameCross then return end
    for _, name in ipairs({"Up", "Down", "Left", "Right", "Center"}) do
        local part = gameCross:FindFirstChild(name)
        if part then
            part.Size = UDim2.new(0, 0, 0, 0)
            if part:IsA("Frame") then part.BackgroundTransparency = 1 end
            if part:IsA("ImageLabel") then part.ImageTransparency = 1 end
        end
    end
end

local CrossLines = {
    Top = Drawing.new("Line"), Bottom = Drawing.new("Line"), Left = Drawing.new("Line"), Right = Drawing.new("Line"),
    TopOutline = Drawing.new("Line"), BottomOutline = Drawing.new("Line"), LeftOutline = Drawing.new("Line"), RightOutline = Drawing.new("Line"),
    CenterDot = Drawing.new("Circle"), CenterDotOutline = Drawing.new("Circle")
}

-- Unified High-Performance Render Loop (Fps Optimized)
local crosshairWasVisible = false
local fovWasVisible = false

local mainRenderConn = RunService.RenderStepped:Connect(function()
    if not ScriptRunning then return end

    -- Fov Circle (Universal PC + Mobile / Delta iOS Fallback)
    local shouldFov = getgenv().fov == true
    if shouldFov then
        fovWasVisible = true
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local radius = tonumber(getgenv().fovsize) or 90
        if fovCircle then
            pcall(function()
                fovCircle.Visible = true
                fovCircle.Radius = radius
                fovCircle.Position = center
            end)
        end
        if GuiFovCircle then
            GuiFovCircle.Visible = true
            GuiFovCircle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
            GuiFovCircle.Position = UDim2.new(0, center.X, 0, center.Y)
        end
    elseif fovWasVisible then
        fovWasVisible = false
        if fovCircle then pcall(function() fovCircle.Visible = false end) end
        if GuiFovCircle then GuiFovCircle.Visible = false end
    end


    -- Custom Crosshair
    if getgenv().customcrosshair then
        local gameCross = getGameCrosshair()
        local spreadOffset = 0
        if gameCross then
            spreadOffset = getDynamicSpread(gameCross)
            suppressGameCrosshair(gameCross)
        end

        local isHoldingGun = gameCross and gameCross.Visible
        local shouldShow = getgenv().cross_always or isHoldingGun

        if shouldShow then
            crosshairWasVisible = true
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local s, g, t = getgenv().cross_size, getgenv().cross_gap + spreadOffset, getgenv().cross_thickness

            if getgenv().cross_dot then
                if getgenv().cross_outline then
                    CrossLines.CenterDotOutline.Visible = true
                    CrossLines.CenterDotOutline.Radius = getgenv().cross_dotsize + 1
                    CrossLines.CenterDotOutline.Position = center
                    CrossLines.CenterDotOutline.Color = Color3.fromRGB(0, 0, 0)
                    CrossLines.CenterDotOutline.Filled = true
                else
                    CrossLines.CenterDotOutline.Visible = false
                end
                CrossLines.CenterDot.Visible = true
                CrossLines.CenterDot.Radius = getgenv().cross_dotsize
                CrossLines.CenterDot.Position = center
                CrossLines.CenterDot.Color = getgenv().cross_color
                CrossLines.CenterDot.Filled = true
            else
                CrossLines.CenterDot.Visible = false
                CrossLines.CenterDotOutline.Visible = false
            end

            local positions = {
                Top = { From = center - Vector2.new(0, g), To = center - Vector2.new(0, g + s) },
                Bottom = { From = center + Vector2.new(0, g), To = center + Vector2.new(0, g + s) },
                Left = { From = center - Vector2.new(g, 0), To = center - Vector2.new(g + s, 0) },
                Right = { From = center + Vector2.new(g, 0), To = center + Vector2.new(g + s, 0) }
            }

            for name, pos in pairs(positions) do
                local line = CrossLines[name]
                local outline = CrossLines[name .. "Outline"]

                if name == "Top" and getgenv().cross_tstyle then
                    line.Visible = false
                    outline.Visible = false
                else
                    if getgenv().cross_outline then
                        outline.Visible = true
                        outline.From = pos.From
                        outline.To = pos.To
                        outline.Color = Color3.fromRGB(0, 0, 0)
                        outline.Thickness = t + 2
                    else
                        outline.Visible = false
                    end
                    line.Visible = true
                    line.From = pos.From
                    line.To = pos.To
                    line.Color = getgenv().cross_color
                    line.Thickness = t
                end
            end
        else
            if crosshairWasVisible then
                crosshairWasVisible = false
                for _, obj in pairs(CrossLines) do obj.Visible = false end
            end
        end
    else
        if crosshairWasVisible then
            crosshairWasVisible = false
            for _, obj in pairs(CrossLines) do obj.Visible = false end
        end
    end
end)
table.insert(ScriptConnections, mainRenderConn)

-- Tracers Cleaner
local tracerCleanConn = RunService.Heartbeat:Connect(function()
    if #activeTracers == 0 then return end
    local now = tick()
    for i = #activeTracers, 1, -1 do
        local t = activeTracers[i]
        if now - t[4] > 0.6 then
            pcall(function() t[1]:Destroy() t[2]:Destroy() end)
            table.remove(activeTracers, i)
        end
    end
end)
table.insert(ScriptConnections, tracerCleanConn)

-- Hitsounds Audio Engine & Playergui.SOUND BLOCKER

getgenv().hitsounds = false
getgenv().hitsound_choice = "Skeet"
getgenv().hitsound_volume = 3
getgenv().hitsound_pitch = 1.0
getgenv().hitsound_custom_id = ""
getgenv().block_game_sound = true

local function checkBlockPlayerGuiSound(child)
    if getgenv().block_game_sound and child and child:IsA("Sound") and child.Name == "Sound" then
        child.Volume = 0
        child:Stop()
        pcall(function() child:Destroy() end)
    end
end

local function bindSoundBlocker()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    for _, ch in ipairs(pg:GetChildren()) do checkBlockPlayerGuiSound(ch) end
    pg.ChildAdded:Connect(checkBlockPlayerGuiSound)
end
task.spawn(function()
    pcall(bindSoundBlocker)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        pcall(bindSoundBlocker)
    end)
end)

local HitSoundMap = {
    ["Skeet"] = "rbxassetid://4817809188",
    ["Neverlose"] = "rbxassetid://6534544923",
    ["Rust Headshot"] = "rbxassetid://5043539554",
    ["Call of Duty"] = "rbxassetid://160432334",
    ["TF2 Critical"] = "rbxassetid://296102734",
    ["Minecraft Hit"] = "rbxassetid://4018616850",
    ["Bell"] = "rbxassetid://6534544923"
}

local function playHitSound()
    if not getgenv().hitsounds or not ScriptRunning then return end
    local assetId = HitSoundMap[getgenv().hitsound_choice] or getgenv().hitsound_choice
    if getgenv().hitsound_choice == "Custom" and #getgenv().hitsound_custom_id > 0 then
        assetId = getgenv().hitsound_custom_id:find("rbxassetid://") and getgenv().hitsound_custom_id or ("rbxassetid://" .. getgenv().hitsound_custom_id)
    end
    if not assetId or assetId == "" then assetId = HitSoundMap["Skeet"] end

    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = assetId
        sound.Volume = tonumber(getgenv().hitsound_volume) or 3
        sound.PlaybackSpeed = tonumber(getgenv().hitsound_pitch) or 1.0
        sound.Parent = Workspace
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
        task.delay(2, function()
            if sound and sound.Parent then sound:Destroy() end
        end)
    end)
end

local function bindHitMarker()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local statusUI = pg and pg:FindFirstChild("StatusUI")
    local cross = statusUI and statusUI:FindFirstChild("Crosshair")
    if not cross then return end

    local hm = cross:FindFirstChild("HitMarker")
    local ohm = cross:FindFirstChild("ObjectHitMarker")

    local function setupMarker(marker)
        if not marker then return end
        marker:GetPropertyChangedSignal("Visible"):Connect(function()
            if marker.Visible then playHitSound() end
        end)
    end
    setupMarker(hm)
    setupMarker(ohm)
end
task.spawn(function()
    pcall(bindHitMarker)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        pcall(bindHitMarker)
    end)
end)

-- Flight & Bypasses

getgenv().fly = false
getgenv().flyspeed = 50
getgenv().noclip = false

local cachedCharacterParts = {}
local function updateNoclipParts()
    cachedCharacterParts = {}
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                table.insert(cachedCharacterParts, part)
            end
        end
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateNoclipParts()
end)
updateNoclipParts()

local noclipConn = RunService.Stepped:Connect(function()
    if not ScriptRunning or not getgenv().noclip then return end
    for i = 1, #cachedCharacterParts do
        local p = cachedCharacterParts[i]
        if p and p.Parent and p.CanCollide then
            p.CanCollide = false
        end
    end
end)
table.insert(ScriptConnections, noclipConn)

local flying = false
local flyVel, flyGyro
local flyKeys = {w = false, a = false, s = false, d = false, space = false, shift = false}

local function startFly()
    if flying then return end
    flying = true
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    flyVel = Instance.new("BodyVelocity")
    flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVel.Velocity = Vector3.zero
    flyVel.Parent = hrp
    
    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.P = 10000
    flyGyro.CFrame = hrp.CFrame
    flyGyro.Parent = hrp
end

local function stopFly()
    flying = false
    if flyVel then flyVel:Destroy() flyVel = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
end

local flyRender = RunService.RenderStepped:Connect(function()
    if not flying or not flyVel or not flyGyro or not ScriptRunning then return end
    local dir = Vector3.zero
    if flyKeys.w then dir = dir + Camera.CFrame.LookVector end
    if flyKeys.s then dir = dir - Camera.CFrame.LookVector end
    if flyKeys.a then dir = dir - Camera.CFrame.RightVector end
    if flyKeys.d then dir = dir + Camera.CFrame.RightVector end
    if flyKeys.space then dir = dir + Vector3.new(0, 1, 0) end
    if flyKeys.shift then dir = dir - Vector3.new(0, 1, 0) end
    if dir.Magnitude > 0 then dir = dir.Unit * getgenv().flyspeed end
    flyVel.Velocity = dir
    flyGyro.CFrame = Camera.CFrame
end)
table.insert(ScriptConnections, flyRender)

local flyInputB = UserInputService.InputBegan:Connect(function(key, gp)
    if gp then return end
    if key.KeyCode == Enum.KeyCode.W then flyKeys.w = true end
    if key.KeyCode == Enum.KeyCode.A then flyKeys.a = true end
    if key.KeyCode == Enum.KeyCode.S then flyKeys.s = true end
    if key.KeyCode == Enum.KeyCode.D then flyKeys.d = true end
    if key.KeyCode == Enum.KeyCode.Space then flyKeys.space = true end
    if key.KeyCode == Enum.KeyCode.LeftShift then flyKeys.shift = true end
end)
local flyInputE = UserInputService.InputEnded:Connect(function(key)
    if key.KeyCode == Enum.KeyCode.W then flyKeys.w = false end
    if key.KeyCode == Enum.KeyCode.A then flyKeys.a = false end
    if key.KeyCode == Enum.KeyCode.S then flyKeys.s = false end
    if key.KeyCode == Enum.KeyCode.D then flyKeys.d = false end
    if key.KeyCode == Enum.KeyCode.Space then flyKeys.space = false end
    if key.KeyCode == Enum.KeyCode.LeftShift then flyKeys.shift = false end
end)
table.insert(ScriptConnections, flyInputB)
table.insert(ScriptConnections, flyInputE)

task.spawn(function()
    while ScriptRunning do
        if getgenv().fly and not flying then startFly()
        elseif not getgenv().fly and flying then stopFly() end
        task.wait(0.1)
    end
end)

-- Ui Initialization (Mentality Ui)

local Library

local function safeLoadLibrary(url)
    local ok, src = pcall(function()
        return game:HttpGet(url .. "?t=" .. tostring(tick()))
    end)
    if ok and type(src) == "string" and #src > 100 and not src:find("404: Not Found") then
        local parseOk, fn = pcall(loadstring, src)
        if parseOk and type(fn) == "function" then
            local execOk, res = pcall(fn)
            if execOk and type(res) == "table" then
                return res
            end
        end
    end
    return nil
end

local function getMentalityLibrary()
    if getgenv().Library and type(getgenv().Library) == "table" and getgenv().Library.Window then
        return getgenv().Library
    end

    local lib = safeLoadLibrary("https://raw.githubusercontent.com/namecoraline03/swinoware/refs/heads/main/lib.luau")
    if lib then return lib end

    lib = safeLoadLibrary("https://cdn.fentoras.com/swin/library.luau")
    if lib then return lib end

    return nil
end

Library = getMentalityLibrary()

if not Library then
    warn("[SWINOWARE] Failed to initialize Mentality UI Library!")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SWINOWARE",
            Text = "Failed to load UI Library!",
            Duration = 5
        })
    end)
    return
end

local function Notify(title, desc, duration)
    pcall(function()
        if Library and Library.Notification then
            Library:Notification({
                Title = tostring(title or "SWINOWARE"),
                Description = tostring(desc or ""),
                Duration = tonumber(duration) or 4
            })
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = tostring(title or "SWINOWARE"),
                Text = tostring(desc or ""),
                Duration = tonumber(duration) or 4
            })
        end
    end)
end

Library.FadeSpeed = 0

Library.Round = function(self, Number, Float)
    if not Float or Float <= 0 then Float = 1 end
    local Multiplier = 1 / Float
    return math.floor(Number * Multiplier + 0.5) / Multiplier
end

if Library and Library.Instances then
    Library.Instances.FadeItem = function(self, Visibility, Speed)
        local Item = self.Instance
        if Item then
            Item.Visible = (Visibility == true)
        end
    end
end

if Library and Library.Page then
    local origPageFn = Library.Page
    Library.Page = function(self, Data)
        local Page = origPageFn(self, Data)
        -- Ultra-fast zero-lag instant tab switching
        function Page:Turn(Bool)
            Page.Active = Bool
            local pageInst = Page.Items and Page.Items["Page"] and Page.Items["Page"].Instance
            local inactiveBtn = Page.Items and Page.Items["Inactive"] and Page.Items["Inactive"].Instance

            if pageInst then
                pageInst.Visible = Bool
                pageInst.Parent = Bool and (Page.Window.Items["Content"] and Page.Window.Items["Content"].Instance or Page.Window.Items["MainFrame"].Instance) or Library.UnusedHolder.Instance
                pageInst.Position = UDim2.new(0, 0, 0, 0)
            end

            if inactiveBtn then
                inactiveBtn.BackgroundTransparency = Bool and 0.25 or 1
            end
        end
        return Page
    end
end

-- Universal Cross-Platform Config System
Library.Folders = {
    Directory = "swinoware",
    Configs = "swinoware/Configs",
    Assets = "swinoware/Assets"
}

if makefolder and isfolder then
    pcall(function()
        if not isfolder("swinoware") then makefolder("swinoware") end
        if not isfolder("swinoware/Configs") then makefolder("swinoware/Configs") end
        if not isfolder("swinoware/Assets") then makefolder("swinoware/Assets") end
    end)
end

local function sanitizeConfigName(name)
    if not name then return nil end
    local clean = tostring(name):gsub("%.json$", ""):gsub("[^%w_%-%s]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return (#clean > 0) and clean or nil
end

Library.GetConfig = function(self)
    local Config = {}
    pcall(function()
        for Index, Value in pairs(Library.Flags) do
            if type(Value) == "table" and Value.Key then
                Config[Index] = { Key = tostring(Value.Key), Mode = Value.Mode }
            elseif type(Value) == "table" and Value.Color then
                Config[Index] = { Color = "#" .. tostring(Value.HexValue or "ffffff"), Alpha = Value.Alpha }
            elseif type(Value) == "table" and type(Value.Value) ~= "nil" then
                Config[Index] = Value.Value
            else
                Config[Index] = Value
            end
        end
    end)
    return HttpService:JSONEncode(Config)
end

Library.LoadConfig = function(self, ConfigRaw)
    local ok, Decoded = pcall(function()
        return HttpService:JSONDecode(ConfigRaw)
    end)
    if not ok or type(Decoded) ~= "table" then return false end

    for Index, Value in pairs(Decoded) do
        local SetFunction = Library.SetFlags[Index]
        if SetFunction then
            pcall(function()
                if type(Value) == "table" and Value.Key then
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                else
                    SetFunction(Value)
                end
            end)
        end
    end
    return true
end

Library.DeleteConfig = function(self, ConfigName)
    local clean = sanitizeConfigName(ConfigName)
    if not clean then return end
    local path = Library.Folders.Configs .. "/" .. clean .. ".json"
    if isfile and isfile(path) and delfile then
        pcall(delfile, path)
    end
end

Library.RefreshConfigsList = function(self, Element)
    local list = {}
    if listfiles and isfolder and isfolder(Library.Folders.Configs) then
        local ok, files = pcall(listfiles, Library.Folders.Configs)
        if ok and type(files) == "table" then
            for _, filePath in ipairs(files) do
                local normalized = tostring(filePath):gsub("\\", "/")
                local name = normalized:match("([^/]+)%.json$")
                if name then
                    table.insert(list, name)
                end
            end
        end
    end
    table.sort(list)
    if Element and Element.Refresh then
        Element:Refresh(list)
    end
    return list
end

Library.CreateSettingsPage = function(self, Window, KeybindList)
    Window:Category("Settings & Configs")

    local Page = Window:Page({
        Name = "Settings",
        Icon = "103180437044643",
        Columns = 2
    })

    -- Column 1: Menu Configurations
    local MenuSec = Page:Section({
        Name = "Menu Customization",
        Description = "UI theme, colors & watermark",
        Icon = "103180437044643",
        Side = 1
    })

    MenuSec:Toggle({
        Name = "Watermark",
        Flag = "UI_Watermark",
        Default = true,
        Callback = function(val)
            if Library.Watermark then
                Library.Watermark:SetVisibility(val)
            end
        end
    })

    MenuSec:Toggle({
        Name = "Keybinds List",
        Flag = "UI_KeybindList",
        Default = true,
        Callback = function(val)
            if KeybindList and KeybindList.Items and KeybindList.Items["KeybindsList"] then
                KeybindList.Items["KeybindsList"].Instance.Visible = val
            end
        end
    })

    -- Column 2: Configs Manager
    local ConfigsSection = Page:Section({
        Name = "Configuration Manager",
        Description = "Save, load & share script presets",
        Icon = "138827881557940",
        Side = 2
    })

    local ConfigName = ""
    local ConfigSelected = nil

    local ConfigsDropdown = ConfigsSection:Listbox({
        Flag = "ConfigsList",
        Items = Library:RefreshConfigsList(),
        Multi = false,
        Callback = function(val)
            ConfigSelected = val
        end
    })

    ConfigsSection:Textbox({
        Flag = "ConfigsName",
        Placeholder = "Config name (e.g. Rage / Legit)",
        Numeric = false,
        Finished = true,
        Callback = function(val)
            ConfigName = val
        end
    })

    ConfigsSection:Button({
        Name = "Create Config",
        Callback = function()
            local clean = sanitizeConfigName(ConfigName)
            if clean and writefile then
                local path = Library.Folders.Configs .. "/" .. clean .. ".json"
                local content = Library:GetConfig()
                local ok, err = pcall(writefile, path, content)
                if ok then
                    Notify("Configs", "Created & saved config: " .. clean, 3)
                    Library:RefreshConfigsList(ConfigsDropdown)
                else
                    Notify("Configs Error", "Failed to write file!", 3)
                end
            else
                Notify("Configs", "Enter a valid config name first!", 3)
            end
        end
    })

    ConfigsSection:Button({
        Name = "Save Selected",
        Callback = function()
            local clean = sanitizeConfigName(ConfigSelected)
            if clean and writefile then
                local path = Library.Folders.Configs .. "/" .. clean .. ".json"
                local content = Library:GetConfig()
                local ok, err = pcall(writefile, path, content)
                if ok then
                    Notify("Configs", "Saved config: " .. clean, 3)
                    Library:RefreshConfigsList(ConfigsDropdown)
                else
                    Notify("Configs Error", "Failed to save file!", 3)
                end
            else
                Notify("Configs", "Select a config to save!", 3)
            end
        end
    })

    ConfigsSection:Button({
        Name = "Load Selected",
        Callback = function()
            local clean = sanitizeConfigName(ConfigSelected)
            if clean and readfile and isfile then
                local path = Library.Folders.Configs .. "/" .. clean .. ".json"
                if isfile(path) then
                    local ok, content = pcall(readfile, path)
                    if ok and content then
                        local loadOk = Library:LoadConfig(content)
                        if loadOk then
                            Notify("Configs", "Loaded config: " .. clean, 3)
                        else
                            Notify("Configs Error", "Corrupted config file!", 3)
                        end
                    end
                else
                    Notify("Configs Error", "Config file not found!", 3)
                end
            else
                Notify("Configs", "Select a config to load!", 3)
            end
        end
    })

    ConfigsSection:Button({
        Name = "Delete Selected",
        Callback = function()
            local clean = sanitizeConfigName(ConfigSelected)
            if clean then
                Library:DeleteConfig(clean)
                Notify("Configs", "Deleted config: " .. clean, 3)
                Library:RefreshConfigsList(ConfigsDropdown)
            else
                Notify("Configs", "Select a config to delete!", 3)
            end
        end
    })

    ConfigsSection:Button({
        Name = "Refresh List",
        Callback = function()
            Library:RefreshConfigsList(ConfigsDropdown)
            Notify("Configs", "Config list refreshed!", 2)
        end
    })

    -- Auto refresh on creation
    task.spawn(function()
        task.wait(0.2)
        Library:RefreshConfigsList(ConfigsDropdown)
    end)

    return Page
end




local Window = Library:Window({
    Name = "SWINOWARE",
    SubName = "War Tycoon",
    Logo = "120959262762131"
})

if Window and Window.Items and Window.Items["MainFrame"] then
    local mf = Window.Items["MainFrame"].Instance
    mf.Size = UDim2.new(0, 715, 0, 790)

    mf:GetPropertyChangedSignal("Size"):Connect(function()
        local curW = mf.Size.X.Offset
        local curH = mf.Size.Y.Offset
        if curW < 715 or curH < 790 then
            mf.Size = UDim2.new(0, math.max(curW, 715), 0, math.max(curH, 790))
        end
    end)
end

-- Hardcoded Active-Only KeybindList with 1-Click Removal
local origKeybindListFn = Library.KeybindList
Library.KeybindList = function(self, Title)
    local list = origKeybindListFn(self, Title)
    list.ItemsList = {}

    local listFrame = nil
    if list.Items and list.Items["KeybindsList"] then
        listFrame = list.Items["KeybindsList"].Instance
    end

    function list:Refresh()
        local activeCount = 0
        for _, item in ipairs(list.ItemsList) do
            if item and item.UpdateVisibility then
                if item:UpdateVisibility() then
                    activeCount = activeCount + 1
                end
            end
        end

        if listFrame then
            listFrame.Visible = (activeCount > 0)
        end
    end

    local origAdd = list.Add
    function list:Add(Name, Key)
        local item = origAdd(list, Name, Key)
        local btn = item.Instance

        item.KeyName = Name or ""
        item.BindKey = Key or "None"
        item.IsToggled = false

        function item:UpdateVisibility()
            local keyStr = tostring(item.BindKey or "None")
            local hasKey = (keyStr ~= "None" and keyStr ~= "Unknown" and keyStr ~= "" and keyStr ~= "nil")
            local shouldShow = hasKey and (item.IsToggled == true)

            btn.Visible = shouldShow
            return shouldShow
        end

        local origSet = item.Set
        function item:Set(newName, newKeyVal)
            item.KeyName = newName or item.KeyName
            item.BindKey = newKeyVal or item.BindKey
            if origSet then origSet(item, item.KeyName, item.BindKey) end
            item:UpdateVisibility()
            list:Refresh()
        end

        local origSetStatus = item.SetStatus
        function item:SetStatus(Bool)
            item.IsToggled = (Bool == true)
            if origSetStatus then origSetStatus(item, Bool) end
            item:UpdateVisibility()
            list:Refresh()
        end

        -- Capture parent list frame
        if not listFrame and btn and btn.Parent and btn.Parent.Parent then
            listFrame = btn.Parent.Parent
        end

        table.insert(list.ItemsList, item)
        item:UpdateVisibility()
        list:Refresh()
        return item
    end

    Library.KeyList = list
    return list
end

local KeybindList = Library:KeybindList("Keybinds")

local function toggleMenuUI()
    if Window and Window.SetOpen then
        Window:SetOpen(not Window.IsOpen)
    elseif Window and Window.Items and Window.Items["MainFrame"] then
        local mainFrame = Window.Items["MainFrame"].Instance
        mainFrame.Visible = not mainFrame.Visible
        Window.IsOpen = mainFrame.Visible
    end
end

local menuToggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.RightShift 
            or input.KeyCode == Enum.KeyCode.Insert 
            or input.KeyCode == Enum.KeyCode.RightControl
            or input.KeyCode == Enum.KeyCode.Z then
            toggleMenuUI()
        end
    end
end)
table.insert(ScriptConnections, menuToggleConn)

local function UnloadScript()
    ScriptRunning = false
    
    for _, conn in pairs(ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(ScriptConnections)

    pcall(function() fovCircle:Remove() end)
    pcall(function() bait:Destroy() end)
    for _, obj in pairs(CrossLines) do pcall(function() obj:Remove() end) end
    pcall(function() ESPHolder:Destroy() end)
    

    pcall(function() Library:Unload() end)
    CleanExistingGuis()
    if ChatState.Socket then pcall(function() ChatState.Socket:Close() end) end
    getgenv().SwinowareUnload = nil
end

getgenv().SwinowareUnload = UnloadScript

-- ==============================================================================
-- CLEAN & INTUITIVE UI TABS & CONTROLS
-- ==============================================================================

local function BuildCheatTabs(Window, KeybindList)
-- 1. COMBAT & WEAPONS
Window:Category("Combat")

local CombatPage = Window:Page({
    Name = "Combat",
    Icon = "108839695397679",
    Columns = 2
})

-- Column 1: Silent Aim & Wallbang + Whitelist
local SilentSec = CombatPage:Section({
    Name = "Silent Aim & Wallbang",
    Description = "Bullet redirection & wall penetration",
    Icon = "134236649319095",
    Side = 1
})

local SilentToggle = SilentSec:Toggle({
    Name = "Silent Aim",
    Flag = "SilentAim",
    Default = false,
    Callback = function(state) getgenv().enablesga = state end
})

SilentSec:Keybind({
    Name = "Silent Aim Keybind",
    Flag = "SilentAimKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() SilentToggle:Set(not getgenv().enablesga) end
})

SilentSec:Toggle({
    Name = "Wallbang",
    Flag = "Wallbang",
    Default = false,
    Callback = function(state) getgenv().wallbang = state end
})

SilentSec:Toggle({
    Name = "Show FOV Circle",
    Flag = "ShowFOV",
    Default = false,
    Callback = function(state) getgenv().fov = state end
})

SilentSec:Slider({
    Name = "FOV Radius",
    Flag = "FOVRadius",
    Min = 50,
    Max = 400,
    Default = 90,
    Suffix = " px",
    Decimals = 1,
    Callback = function(val) getgenv().fovsize = val end
})

SilentSec:Toggle({
    Name = "Bullet Tracers",
    Flag = "Tracers",
    Default = false,
    Callback = function(state) getgenv().tracers = state end
})

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    if #list == 0 then table.insert(list, "No Players") end
    return list
end

local WhitelistSec = CombatPage:Section({
    Name = "Combat Whitelist",
    Description = "Exclude players from all combat features",
    Icon = "100050851789190",
    Side = 1
})

local WhitelistDropdown = WhitelistSec:Dropdown({
    Name = "Whitelisted Players",
    Flag = "CombatWL_MultiDropdown",
    Items = getPlayerList(),
    Multi = true,
    Default = {},
    Callback = function(selectedList)
        table.clear(getgenv().CombatWhitelist)
        if type(selectedList) == "table" then
            for _, name in ipairs(selectedList) do
                if name and name ~= "No Players" then
                    local clean = string.lower(name):gsub("%s+", "")
                    getgenv().CombatWhitelist[clean] = true
                end
            end
        elseif type(selectedList) == "string" and selectedList ~= "No Players" then
            local clean = string.lower(selectedList):gsub("%s+", "")
            getgenv().CombatWhitelist[clean] = true
        end
    end
})

WhitelistSec:Button({
    Name = "Refresh Player List",
    Callback = function()
        if WhitelistDropdown and WhitelistDropdown.Refresh then
            WhitelistDropdown:Refresh(getPlayerList())
        end
    end
})

WhitelistSec:Button({
    Name = "Clear Whitelist",
    Callback = function()
        table.clear(getgenv().CombatWhitelist)
        if WhitelistDropdown and WhitelistDropdown.Set then
            WhitelistDropdown:Set({})
        end
    end
})

-- Column 2: Gun Mods + Kill Aura & Artillery
local GunModSec = CombatPage:Section({
    Name = "Gun Modifications",
    Description = "Zero recoil, no spread, hitscan & fast reload",
    Icon = "134236649319095",
    Side = 2
})

GunModSec:Toggle({
    Name = "No Recoil",
    Flag = "GM_NoRecoil",
    Default = false,
    Callback = function(state) getgenv().gm_norecoil = state syncAllGunMods() end
})

GunModSec:Toggle({
    Name = "No Spread",
    Flag = "GM_NoSpread",
    Default = false,
    Callback = function(state) getgenv().gm_nospread = state syncAllGunMods() end
})

GunModSec:Toggle({
    Name = "Instant Bullet Speed",
    Flag = "GM_Hitscan",
    Default = false,
    Callback = function(state) getgenv().gm_hitscan = state syncAllGunMods() end
})

GunModSec:Toggle({
    Name = "Always Full Auto",
    Flag = "GM_FullAuto",
    Default = false,
    Callback = function(state) getgenv().gm_fullauto = state syncAllGunMods() end
})

GunModSec:Toggle({
    Name = "Fast Reload",
    Flag = "GM_FastReload",
    Default = false,
    Callback = function(state) getgenv().gm_fastreload = state syncAllGunMods() end
})

local OffensiveSec = CombatPage:Section({
    Name = "Kill Aura & Rockets",
    Description = "Auto bullet attacker & RPG homing minigun",
    Icon = "123554105934637",
    Side = 2
})

local GunAuraToggle = OffensiveSec:Toggle({
    Name = "Gun Kill Aura",
    Flag = "GunKillAura",
    Default = false,
    Callback = function(state) WarTycoonSettings.GunKillAura = state end
})

OffensiveSec:Keybind({
    Name = "Gun Kill Aura Keybind",
    Flag = "GunAuraKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() GunAuraToggle:Set(not WarTycoonSettings.GunKillAura) end
})

OffensiveSec:Dropdown({
    Name = "Target Hitbox",
    Flag = "GunHitPart",
    Items = { "Head", "HumanoidRootPart", "UpperTorso" },
    Default = "Head",
    Callback = function(val) WarTycoonSettings.KillAuraHitPart = val end
})

OffensiveSec:Slider({
    Name = "Attack Range",
    Flag = "GunRange",
    Min = 100,
    Max = 4000,
    Default = 2500,
    Suffix = " studs",
    Decimals = 1,
    Callback = function(val) WarTycoonSettings.KillAuraRange = val end
})

local CombatRocketSpamToggle = OffensiveSec:Toggle({
    Name = "Rocket Spam",
    Flag = "CombatSpamRockets",
    Default = false,
    Callback = function(state) getgenv().spamrockets = state end
})

OffensiveSec:Keybind({
    Name = "Rocket Spam Keybind",
    Flag = "CombatRocketSpamKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() CombatRocketSpamToggle:Set(not getgenv().spamrockets) end
})

OffensiveSec:Toggle({
    Name = "Instant Rocket Reload",
    Flag = "CombatInstantReload",
    Default = false,
    Callback = function(state) getgenv().instantrocketreload = state syncRocketReload() end
})

local StingerOrbitToggle = OffensiveSec:Toggle({
    Name = "Stinger Orbit",
    Flag = "StingerOrbit",
    Default = false,
    Callback = function(state) getgenv().stingerorbit = state end
})

OffensiveSec:Keybind({
    Name = "Stinger Orbit Keybind",
    Flag = "StingerOrbitKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() StingerOrbitToggle:Set(not getgenv().stingerorbit) end
})

OffensiveSec:Toggle({
    Name = "Enable Guided Rocket Mods",
    Flag = "RocketMods",
    Default = false,
    Callback = function(state) getgenv().rocketmods = state end
})

OffensiveSec:Toggle({
    Name = "Instant Homing",
    Flag = "InstantHoming",
    Default = false,
    Callback = function(state) getgenv().rm_instanthoming = state end
})

OffensiveSec:Slider({
    Name = "Rocket Speed",
    Flag = "RocketSpeed",
    Min = 0,
    Max = 2000,
    Default = 500,
    Decimals = 1,
    Callback = function(val) getgenv().rm_velocity = val end
})

OffensiveSec:Toggle({
    Name = "Rockets Ignore Walls",
    Flag = "RocketIgnoreWalls",
    Default = false,
    Callback = function(state) getgenv().rm_ignorewalls = state end
})


-- 2. VISUALS & ESP
Window:Category("Visuals")

local VisualsPage = Window:Page({
    Name = "Visuals",
    Icon = "100050851789190",
    Columns = 2
})

-- Column 1: Player ESP Boxes & Snaplines
local BoxSec = VisualsPage:Section({
    Name = "Player ESP & Boxes",
    Icon = "100050851789190",
    Side = 1
})

local ESPToggle = BoxSec:Toggle({
    Name = "Enable ESP",
    Flag = "Town_ESP_Enabled",
    Default = false,
    Callback = function(val) ESP.Enabled = val end
})

BoxSec:Keybind({
    Name = "ESP Keybind",
    Flag = "Town_ESP_Key",
    Default = Enum.KeyCode.Unknown,
    Callback = function() ESPToggle:Set(not ESP.Enabled) end
})

BoxSec:Toggle({
    Name = "Team Check",
    Flag = "Town_ESP_TeamCheck",
    Default = false,
    Callback = function(val) ESP.TeamCheck = val end
})

BoxSec:Toggle({
    Name = "Fade Out on Distance",
    Flag = "Town_ESP_FadeOut",
    Default = true,
    Callback = function(val) ESP.FadeOut.OnDistance = val end
})

BoxSec:Slider({
    Name = "Max Render Distance",
    Flag = "Town_ESP_MaxDist",
    Min = 50,
    Max = 5000,
    Default = 3500,
    Float = 50,
    Callback = function(val) ESP.MaxDistance = val end
})

BoxSec:Slider({
    Name = "ESP Font Size",
    Flag = "Town_ESP_FontSize",
    Min = 8,
    Max = 20,
    Default = 13,
    Float = 1,
    Callback = function(val) ESP.FontSize = val end
})

BoxSec:Toggle({
    Name = "2D Full Box",
    Flag = "Town_ESP_FullBox",
    Default = true,
    Callback = function(val) ESP.Drawing.Boxes.Full.Enabled = val end
})

BoxSec:Label("Full Box Color"):Colorpicker({
    Flag = "Town_FullBox_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) ESP.Drawing.Boxes.Full.RGB = color end
})

BoxSec:Toggle({
    Name = "Corner Box",
    Flag = "Town_ESP_CornerBox",
    Default = false,
    Callback = function(val) ESP.Drawing.Boxes.Corner.Enabled = val end
})

BoxSec:Label("Corner Box Color"):Colorpicker({
    Flag = "Town_CornerBox_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) ESP.Drawing.Boxes.Corner.RGB = color end
})

BoxSec:Toggle({
    Name = "Box Filled Gradient",
    Flag = "Town_ESP_BoxFill",
    Default = true,
    Callback = function(val) ESP.Drawing.Boxes.Filled.Enabled = val end
})

BoxSec:Label("Fill Color 1"):Colorpicker({
    Flag = "Town_BoxFill_Color1",
    Default = Color3.fromRGB(170, 85, 255),
    Callback = function(color) ESP.Drawing.Boxes.GradientFillRGB1 = color end
})

BoxSec:Label("Fill Color 2"):Colorpicker({
    Flag = "Town_BoxFill_Color2",
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(color) ESP.Drawing.Boxes.GradientFillRGB2 = color end
})

BoxSec:Slider({
    Name = "Fill Transparency",
    Flag = "Town_ESP_FillTrans",
    Min = 0,
    Max = 100,
    Default = 75,
    Float = 5,
    Callback = function(val) ESP.Drawing.Boxes.Filled.Transparency = val / 100 end
})

BoxSec:Toggle({
    Name = "Animate Box Gradient",
    Flag = "Town_ESP_BoxAnim",
    Default = true,
    Callback = function(val) ESP.Drawing.Boxes.Animate = val end
})

BoxSec:Slider({
    Name = "Rotation Speed",
    Flag = "Town_ESP_RotSpeed",
    Min = 50,
    Max = 600,
    Default = 250,
    Float = 25,
    Callback = function(val) ESP.Drawing.Boxes.RotationSpeed = val end
})

local TracerSec = VisualsPage:Section({
    Name = "Tracers & Head Dot",
    Icon = "100050851789190",
    Side = 1
})

TracerSec:Toggle({
    Name = "Snaplines / Tracers",
    Flag = "Town_ESP_Tracers",
    Default = false,
    Callback = function(val) ESP.Drawing.Tracers.Enabled = val end
})

TracerSec:Label("Tracer Color"):Colorpicker({
    Flag = "Town_Tracer_Color",
    Default = Color3.fromRGB(170, 85, 255),
    Callback = function(color) ESP.Drawing.Tracers.RGB = color end
})

TracerSec:Toggle({
    Name = "Head Dot",
    Flag = "Town_ESP_HeadDot",
    Default = false,
    Callback = function(val) ESP.Drawing.HeadDot.Enabled = val end
})

TracerSec:Label("Head Dot Color"):Colorpicker({
    Flag = "Town_HeadDot_Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color) ESP.Drawing.HeadDot.RGB = color end
})

-- Column 2: Player Info & Chams + Crosshair & Hitsounds
local ChamsInfoSec = VisualsPage:Section({
    Name = "Player Info & Chams",
    Icon = "100050851789190",
    Side = 2
})

ChamsInfoSec:Toggle({
    Name = "Healthbar",
    Flag = "Town_ESP_Healthbar",
    Default = true,
    Callback = function(val) ESP.Drawing.Healthbar.Enabled = val end
})

ChamsInfoSec:Slider({
    Name = "Healthbar Width",
    Flag = "Town_ESP_HealthWidth",
    Min = 1.5,
    Max = 6.0,
    Default = 2.5,
    Float = 0.5,
    Callback = function(val) ESP.Drawing.Healthbar.Width = val end
})

ChamsInfoSec:Toggle({
    Name = "Health Dynamic Color (Lerp)",
    Flag = "Town_ESP_HealthLerp",
    Default = true,
    Callback = function(val) ESP.Drawing.Healthbar.Lerp = val end
})

ChamsInfoSec:Toggle({
    Name = "Health Text (%)",
    Flag = "Town_ESP_HealthText",
    Default = true,
    Callback = function(val) ESP.Drawing.Healthbar.HealthText = val end
})

ChamsInfoSec:Label("Health Text Color"):Colorpicker({
    Flag = "Town_HealthText_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) ESP.Drawing.Healthbar.HealthTextRGB = color end
})

ChamsInfoSec:Toggle({
    Name = "Player Names",
    Flag = "Town_ESP_Names",
    Default = true,
    Callback = function(val) ESP.Drawing.Names.Enabled = val end
})

ChamsInfoSec:Label("Names Color"):Colorpicker({
    Flag = "Town_Names_Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) ESP.Drawing.Names.RGB = color end
})

ChamsInfoSec:Toggle({
    Name = "Equipped Weapon",
    Flag = "Town_ESP_Weapons",
    Default = true,
    Callback = function(val) ESP.Drawing.Weapons.Enabled = val end
})

ChamsInfoSec:Label("Weapon Color"):Colorpicker({
    Flag = "Town_Weapon_Color",
    Default = Color3.fromRGB(170, 85, 255),
    Callback = function(color) ESP.Drawing.Weapons.WeaponTextRGB = color end
})

ChamsInfoSec:Toggle({
    Name = "Distance Display",
    Flag = "Town_ESP_Distances",
    Default = true,
    Callback = function(val) ESP.Drawing.Distances.Enabled = val end
})

ChamsInfoSec:Dropdown({
    Name = "Distance Position",
    Flag = "Town_ESP_DistPos",
    Items = { "Bottom", "Top" },
    Default = "Bottom",
    Callback = function(val) ESP.Drawing.Distances.Position = val end
})

ChamsInfoSec:Toggle({
    Name = "Friend Check",
    Flag = "Town_ESP_FriendCheck",
    Default = false,
    Callback = function(val) ESP.Options.Friendcheck = val end
})

ChamsInfoSec:Label("Friend Color"):Colorpicker({
    Flag = "Town_Friend_Color",
    Default = Color3.fromRGB(50, 255, 120),
    Callback = function(color) ESP.Options.FriendcheckRGB = color end
})

ChamsInfoSec:Toggle({
    Name = "Player Chams (Highlight)",
    Flag = "Town_ESP_Chams",
    Default = false,
    Callback = function(val) ESP.Drawing.Chams.Enabled = val end
})

ChamsInfoSec:Label("Chams Fill Color"):Colorpicker({
    Flag = "Town_Chams_FillColor",
    Default = Color3.fromRGB(170, 85, 255),
    Callback = function(color) ESP.Drawing.Chams.FillRGB = color end
})

ChamsInfoSec:Label("Chams Outline Color"):Colorpicker({
    Flag = "Town_Chams_OutlineColor",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) ESP.Drawing.Chams.OutlineRGB = color end
})

ChamsInfoSec:Toggle({
    Name = "Always Visible Through Walls",
    Flag = "Town_ESP_ChamsWall",
    Default = true,
    Callback = function(val) ESP.Drawing.Chams.AlwaysOnTop = val end
})

ChamsInfoSec:Slider({
    Name = "Chams Fill Transparency",
    Flag = "Town_ESP_ChamsFillTrans",
    Min = 0,
    Max = 100,
    Default = 50,
    Float = 5,
    Callback = function(val) ESP.Drawing.Chams.Fill_Transparency = val end
})

ChamsInfoSec:Slider({
    Name = "Chams Outline Transparency",
    Flag = "Town_ESP_ChamsOutTrans",
    Min = 0,
    Max = 100,
    Default = 0,
    Float = 5,
    Callback = function(val) ESP.Drawing.Chams.Outline_Transparency = val end
})

local CrossSec = VisualsPage:Section({
    Name = "Crosshair & Hitsounds",
    Description = "Dynamic crosshair & audio hit markers",
    Icon = "126497581491926",
    Side = 2
})

local CrosshairToggle = CrossSec:Toggle({
    Name = "Enable Custom Crosshair",
    Flag = "CustomCrosshair",
    Default = false,
    Callback = function(state) getgenv().customcrosshair = state end
})

CrossSec:Keybind({
    Name = "Crosshair Keybind",
    Flag = "CrosshairKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() CrosshairToggle:Set(not getgenv().customcrosshair) end
})

CrossSec:Toggle({
    Name = "Always Visible",
    Flag = "CrossAlways",
    Default = false,
    Callback = function(state) getgenv().cross_always = state end
})

CrossSec:Toggle({
    Name = "Center Dot",
    Flag = "CrossDot",
    Default = true,
    Callback = function(state) getgenv().cross_dot = state end
})

CrossSec:Toggle({
    Name = "Black Outline",
    Flag = "CrossOutline",
    Default = true,
    Callback = function(state) getgenv().cross_outline = state end
})

CrossSec:Toggle({
    Name = "T-Style Crosshair",
    Flag = "CrossTStyle",
    Default = false,
    Callback = function(state) getgenv().cross_tstyle = state end
})

CrossSec:Slider({
    Name = "Crosshair Size",
    Flag = "CrossSize",
    Min = 2,
    Max = 30,
    Default = 8,
    Suffix = " px",
    Decimals = 1,
    Callback = function(val) getgenv().cross_size = val end
})

CrossSec:Slider({
    Name = "Crosshair Gap",
    Flag = "CrossGap",
    Min = 0,
    Max = 25,
    Default = 4,
    Suffix = " px",
    Decimals = 1,
    Callback = function(val) getgenv().cross_gap = val end
})

CrossSec:Slider({
    Name = "Line Thickness",
    Flag = "CrossThickness",
    Min = 1,
    Max = 6,
    Default = 2,
    Suffix = " px",
    Decimals = 1,
    Callback = function(val) getgenv().cross_thickness = val end
})

local HitSoundToggle = CrossSec:Toggle({
    Name = "Enable Hit Sounds",
    Flag = "HitSounds",
    Default = false,
    Callback = function(state) getgenv().hitsounds = state end
})

CrossSec:Toggle({
    Name = "Mute Default Hit Sound",
    Flag = "MuteDefaultSound",
    Default = true,
    Callback = function(state) getgenv().block_game_sound = state end
})

CrossSec:Dropdown({
    Name = "Sound Effect",
    Flag = "HitSoundEffect",
    Items = { "Skeet", "Neverlose", "Rust Headshot", "Call of Duty", "TF2 Critical", "Minecraft Hit", "Bell", "Custom" },
    Default = "Skeet",
    Callback = function(val) getgenv().hitsound_choice = val end
})

CrossSec:Slider({
    Name = "Sound Volume",
    Flag = "HitSoundVol",
    Min = 1,
    Max = 10,
    Default = 3,
    Decimals = 1,
    Callback = function(val) getgenv().hitsound_volume = val end
})

CrossSec:Slider({
    Name = "Pitch Speed",
    Flag = "HitSoundPitch",
    Min = 0.5,
    Max = 2.0,
    Default = 1.0,
    Decimals = 2,
    Callback = function(val) getgenv().hitsound_pitch = val end
})

CrossSec:Textbox({
    Name = "Custom Sound ID",
    Flag = "HitSoundCustom",
    Default = "",
    Placeholder = "e.g. 4817809188",
    Callback = function(val) getgenv().hitsound_custom_id = val end
})


-- 3. AUTOMATION & FARMING
Window:Category("Automation")

local AutoPage = Window:Page({
    Name = "Tycoon & Farm",
    Icon = "138827881557940",
    Columns = 2
})

-- Column 1: Auto Build & Base Defense
local AutoBuildSec = AutoPage:Section({
    Name = "Auto Build Tycoon",
    Description = "Automated button purchasing & cash collection",
    Icon = "124500005755075",
    Side = 1
})

local AutoBuildToggle = AutoBuildSec:Toggle({
    Name = "Enable Auto Build",
    Flag = "AutoBuild",
    Default = false,
    Callback = function(state) getgenv().autobuy = state end
})

AutoBuildSec:Keybind({
    Name = "Auto Build Keybind",
    Flag = "AutoBuildKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() AutoBuildToggle:Set(not getgenv().autobuy) end
})

AutoBuildSec:Toggle({
    Name = "Auto Collect Cash",
    Flag = "AutoCollectCash",
    Default = false,
    Callback = function(state) getgenv().autocollectcash = state end
})

AutoBuildSec:Toggle({
    Name = "Prioritize Income Buttons",
    Flag = "IncomePriority",
    Default = true,
    Callback = function(state) getgenv().prioritize_income = state end
})

AutoBuildSec:Toggle({
    Name = "Target Lowest Price",
    Flag = "LowestPrice",
    Default = true,
    Callback = function(state) getgenv().targetlowest = state end
})

AutoBuildSec:Toggle({
    Name = "Target Rebirth Buttons",
    Flag = "RebirthButtons",
    Default = false,
    Callback = function(state) getgenv().targetrebirth = state end
})

local CRAMSec = AutoPage:Section({
    Name = "CRAM Base Defense",
    Description = "Base turret automated defense",
    Icon = "134236649319095",
    Side = 1
})

local CRAMToggle = CRAMSec:Toggle({
    Name = "Enable CRAM Kill Aura",
    Flag = "CRAMAura",
    Default = false,
    Callback = function(state) getgenv().cramKillAura = state end
})

CRAMSec:Keybind({
    Name = "CRAM Kill Aura Keybind",
    Flag = "CRAMKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() CRAMToggle:Set(not getgenv().cramKillAura) end
})

CRAMSec:Toggle({
    Name = "Target Players",
    Flag = "CRAMPlayers",
    Default = true,
    Callback = function(state) getgenv().cramTargetPlayers = state end
})

CRAMSec:Toggle({
    Name = "Target Vehicles",
    Flag = "CRAMVehicles",
    Default = true,
    Callback = function(state) getgenv().cramTargetVehicles = state end
})

-- Column 2: Collectibles & Crates Farm
local CrateSec = AutoPage:Section({
    Name = "Collectibles & Crates Farm",
    Description = "Automatic high-speed crate & drop collector",
    Icon = "138827881557940",
    Side = 2
})

local CratesFarmToggle = CrateSec:Toggle({
    Name = "Auto Farm Crates",
    Flag = "AutoFarmCrates",
    Default = false,
    Callback = function(state)
        getgenv().autofarmcrates = state
    end
})

CrateSec:Keybind({
    Name = "Crates Farm Keybind",
    Flag = "CratesFarmKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() CratesFarmToggle:Set(not getgenv().autofarmcrates) end
})

CrateSec:Toggle({
    Name = "Target Part Crates",
    Flag = "TargetPartCrates",
    Default = true,
    Callback = function(state) getgenv().targetCrates = state end
})

CrateSec:Toggle({
    Name = "Target Oil Barrels",
    Flag = "TargetOilBarrels",
    Default = true,
    Callback = function(state) getgenv().targetOilBarrels = state end
})

CrateSec:Toggle({
    Name = "Target Research & Pallets",
    Flag = "TargetResearch",
    Default = true,
    Callback = function(state) getgenv().targetResearch = state end
})

CrateSec:Toggle({
    Name = "Target Airdrops",
    Flag = "TargetAirdrops",
    Default = true,
    Callback = function(state) getgenv().targetAirdrops = state end
})

CrateSec:Toggle({
    Name = "Target Medals & Cash Piles",
    Flag = "TargetMedalsCash",
    Default = true,
    Callback = function(state) getgenv().targetMedalsCash = state end
})


-- 4. MOVEMENT & MOBILITY
Window:Category("Movement")

local MovePage = Window:Page({
    Name = "Movement",
    Icon = "134806693472248",
    Columns = 1
})

local MoveSec = MovePage:Section({
    Name = "Flight & Bypasses",
    Description = "Smooth flight controls & bypassed noclip",
    Icon = "134806693472248",
    Side = 1
})

local FlyToggle = MoveSec:Toggle({
    Name = "Fly",
    Flag = "FlyToggle",
    Default = false,
    Callback = function(state) getgenv().fly = state end
})

MoveSec:Keybind({
    Name = "Flight Keybind",
    Flag = "FlyKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() FlyToggle:Set(not getgenv().fly) end
})

MoveSec:Slider({
    Name = "Fly Speed",
    Flag = "FlySpeed",
    Min = 20,
    Max = 300,
    Default = 50,
    Suffix = " studs/s",
    Decimals = 1,
    Callback = function(val) getgenv().flyspeed = val end
})

local NoclipToggle = MoveSec:Toggle({
    Name = "Bypassed Noclip",
    Flag = "NoclipToggle",
    Default = false,
    Callback = function(state) getgenv().noclip = state end
})

MoveSec:Keybind({
    Name = "Noclip Keybind",
    Flag = "NoclipKey",
    Default = Enum.KeyCode.Unknown,
    Callback = function() NoclipToggle:Set(not getgenv().noclip) end
})


-- Community & Global Chat
Window:Category("Community & Chat")

local ChatPage = Window:Page({
    Name = "Global Chat",
    Icon = "100050851789190",
    Columns = 1
})

local GlobalChat = ChatPage:GlobalChat(1)

getgenv().chat_server_url = "wss://cdn.fentoras.com/chat"
getgenv().chat_notifications = true
getgenv().chat_sound = true

local ChatSessionId = game:GetService("HttpService"):GenerateGUID(false)

local ChatState = {
    Connected = false,
    OnlineCount = 0,
    Socket = nil,
    Connecting = false,
    LastSendTime = 0
}

-- Admin Roblox Accounts Whitelist
local AdminRobloxAccounts = {
    ["345a18381"] = true,
    ["skibidirizzlerrwz"] = true,
    ["skibidirizzlerrwz1"] = true,
    ["kis9m9667"] = true,
    ["marina3082"] = true,
    ["lypit679y7"] = true,
    ["brooklc200"] = true,
    ["serg3082"] = true,
    ["lavochnick"] = true
}

local isCurrentPlayerAdmin = AdminRobloxAccounts[string.lower(LocalPlayer.Name)] == true

-- Roblox Account-Bound Nickname & Avatar System
local function getSavedChatNickname()
    local saveFile = "swinoware_nick_" .. tostring(LocalPlayer.UserId) .. ".txt"
    if isfile and isfile(saveFile) then
        local ok, content = pcall(readfile, saveFile)
        if ok and content and #content:gsub("%s+", "") > 0 then
            return content:gsub("^%s+", ""):gsub("%s+$", "")
        end
    end
    -- Default to Roblox account username
    return LocalPlayer.Name
end

local function getSavedChatAvatar()
    local saveFile = "swinoware_avatar_" .. tostring(LocalPlayer.UserId) .. ".txt"
    if isfile and isfile(saveFile) then
        local ok, content = pcall(readfile, saveFile)
        if ok and content and #content:gsub("%s+", "") > 0 then
            local clean = content:gsub("^%s+", ""):gsub("%s+$", "")
            if not clean:find("rbxassetid://") and not clean:find("http") then
                clean = "rbxassetid://" .. clean
            end
            return clean
        end
    end
    return isCurrentPlayerAdmin and "rbxassetid://120959262762131" or nil
end

getgenv().chat_nickname = getSavedChatNickname()
getgenv().chat_custom_avatar = getSavedChatAvatar()

local AnonymousAvatars = {
    "rbxassetid://120959262762131", -- Swinoware Diamond
    "rbxassetid://134236649319095", -- Scope
    "rbxassetid://108839695397679", -- Crosshair
    "rbxassetid://100050851789190", -- Shield
    "rbxassetid://126497581491926", -- Lighting
    "rbxassetid://103180437044643", -- Gear
    "rbxassetid://138827881557940"  -- Package
}

local function getAvatarForUser(username, customAvatar)
    if customAvatar and #customAvatar > 0 then
        return customAvatar
    end
    local hash = 0
    username = tostring(username or "User")
    for i = 1, #username do
        hash = (hash + string.byte(username, i)) % #AnonymousAvatars + 1
    end
    return AnonymousAvatars[hash] or AnonymousAvatars[1]
end

local myAvatar = getAvatarForUser(getgenv().chat_nickname, getgenv().chat_custom_avatar)
GlobalChat:SetStatus("Connecting...", Color3.fromRGB(255, 210, 62))

local function clearAllChatBubbles()
    if GlobalChat and GlobalChat.Items and GlobalChat.Items["Messages"] then
        for _, child in ipairs(GlobalChat.Items["Messages"].Instance:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
end

-- Link detector
local function containsForbiddenLink(str)
    local s = str:lower()
    if s:find("http://") or s:find("https://") or s:find("www%.") or s:find("discord%.gg") or s:find("t%.me") or s:find("bit%.ly") then
        return true
    end
    local extensions = {"%.com", "%.ru", "%.net", "%.org", "%.xyz", "%.io", "%.me", "%.app", "%.gg", "%.site", "%.online", "%.su", "%.top", "%.link"}
    for _, ext in ipairs(extensions) do
        if s:find(ext) then return true end
    end
    return false
end

local CHAT_LOGS_WEBHOOK = "https://discord.com/api/webhooks/1541451845615222977/rkHml2PJzkyCBSFrgy7c1O58jRQ4lNlqpRa_zopIkZRrDRcmwveNy_dFcmXnPQR7IABo"

local function logGlobalChatMessageToDiscord(sender, text, role, robloxAccount)
    task.spawn(function()
        local http = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
        if not http then return end

        local rUser = robloxAccount and tostring(robloxAccount) or "Unknown"
        local authorName = tostring(sender or "User")
        local isOwner = (role == "Owner") or authorName:find("%[OWNER%]")
        if isOwner and not authorName:find("%[OWNER%]") then
            authorName = "[OWNER] " .. authorName
        end

        local data = {
            ["username"] = "Swinoware Global Chat Logs",
            ["embeds"] = {{
                ["title"] = "💬 Global Chat: " .. authorName,
                ["description"] = tostring(text or ""),
                ["color"] = isOwner and 16766720 or 5793266,
                ["fields"] = {
                    { ["name"] = "👤 Nickname", ["value"] = "`" .. authorName .. "`", ["inline"] = true },
                    { ["name"] = "🎮 Roblox User", ["value"] = "`@" .. rUser .. "`", ["inline"] = true }
                },
                ["footer"] = { ["text"] = "swinoware global chat • live logs" },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }

        pcall(function()
            http({
                Url = CHAT_LOGS_WEBHOOK,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = game:GetService("HttpService"):JSONEncode(data)
            })
        end)
    end)
end

local function handleIncomingChatMessage(data)
    if not data then return end
    if data.type == "init" then
        local count = data.online or 1
        GlobalChat:SetStatus(tostring(count) .. " Active | Connected", Color3.fromRGB(62, 255, 91))
        if data.history and type(data.history) == "table" then
            clearAllChatBubbles()
            for _, item in ipairs(data.history) do
                local sender = tostring(item.user or "User")
                local isMe = (item.sessionId and item.sessionId == ChatSessionId) or false
                local avatar = (item.avatar and #item.avatar > 0) and item.avatar or getAvatarForUser(sender, nil)
                if item.role == "Owner" and not sender:find("%[OWNER%]") then
                    sender = "[OWNER] " .. sender
                end
                GlobalChat:SendMessage(avatar, sender, tostring(item.text or ""), isMe)
            end
        end

    elseif data.type == "online_update" then
        local count = data.online or 1
        GlobalChat:SetStatus(tostring(count) .. " Active | Connected", Color3.fromRGB(62, 255, 91))

    elseif data.type == "wipe_all" then
        clearAllChatBubbles()
        GlobalChat:SendMessage(myAvatar, "System", tostring(data.text or "Chat history was wiped by Administrator."), false)

    elseif data.type == "chat" then
        local isFromThisClient = (data.sessionId and data.sessionId == ChatSessionId)
        if not isFromThisClient then
            local sender = tostring(data.user or "User")
            local avatar = (data.avatar and #data.avatar > 0) and data.avatar or getAvatarForUser(sender, nil)
            if data.role == "Owner" and not sender:find("%[OWNER%]") then
                sender = "[OWNER] " .. sender
            end
            GlobalChat:SendMessage(avatar, sender, tostring(data.text or ""), false)
            logGlobalChatMessageToDiscord(data.user or sender, data.text, data.role, data.robloxUser)

            if getgenv().chat_notifications then
                Notify("[SWINO CHAT] " .. sender, tostring(data.text or ""), 4)
            end

            if getgenv().chat_sound then
                pcall(function()
                    local s = Instance.new("Sound", Workspace)
                    s.SoundId = "rbxassetid://4590662766"
                    s.Volume = 1.5
                    s:Play()
                    game:GetService("Debris"):AddItem(s, 2)
                end)
            end
        end
    end
end

local function connectGlobalChat()
    if ChatState.Connecting then return end
    ChatState.Connecting = true

    local wsConnect = (WebSocket and WebSocket.connect) 
        or (syn and syn.websocket and syn.websocket.connect) 
        or (websocket and websocket.connect) 
        or (Krnl and Krnl.WebSocket and Krnl.WebSocket.connect)

    if not wsConnect then
        ChatState.Connecting = false
        GlobalChat:SetStatus("WS Not Supported", Color3.fromRGB(255, 80, 80))
        return
    end

    if ChatState.Socket then
        pcall(function() ChatState.Socket:Close() end)
        ChatState.Socket = nil
    end

    task.spawn(function()
        GlobalChat:SetStatus("Connecting...", Color3.fromRGB(255, 210, 62))
        local ok, socket = pcall(wsConnect, getgenv().chat_server_url)
        ChatState.Connecting = false

        if ok and socket then
            ChatState.Socket = socket
            ChatState.Connected = true
            GlobalChat:SetStatus("1 Active | Connected", Color3.fromRGB(62, 255, 91))

            socket.OnMessage:Connect(function(msgRaw)
                pcall(function()
                    local HttpService = game:GetService("HttpService")
                    local data = HttpService:JSONDecode(msgRaw)
                    handleIncomingChatMessage(data)
                end)
            end)

            socket.OnClose:Connect(function()
                ChatState.Connected = false
                ChatState.Socket = nil
                GlobalChat:SetStatus("Disconnected", Color3.fromRGB(255, 80, 80))
            end)
        else
            ChatState.Connected = false
            GlobalChat:SetStatus("Offline / Retrying...", Color3.fromRGB(255, 140, 40))
        end
    end)
end

local function processUserSendMessage()
    local text = GlobalChat:GetTypedMessage()
    if text and #text:gsub("%s+", "") > 0 then
        GlobalChat:ClearText()

        local now = tick()

        -- /help command
        if text:lower() == "/help" then
            if isCurrentPlayerAdmin then
                GlobalChat:SendMessage(myAvatar, "System", "Commands: /nick <name> | /avatar <id> | /wipe (clear for all) | /announce <text> | /clear", false)
            else
                GlobalChat:SendMessage(myAvatar, "System", "Commands: /nick <name> | /avatar <id> | /clear", false)
            end
            return
        end

        -- /clear command (local)
        if text:lower() == "/clear" then
            clearAllChatBubbles()
            GlobalChat:SendMessage(myAvatar, "System", "Chat cleared locally.", false)
            return
        end

        -- /nick command
        if text:sub(1, 6):lower() == "/nick " then
            local newNick = text:sub(7):gsub("^%s+", ""):gsub("%s+$", "")
            if #newNick >= 2 and #newNick <= 24 then
                getgenv().chat_nickname = newNick
                local saveFile = "swinoware_nick_" .. tostring(LocalPlayer.UserId) .. ".txt"
                if writefile then pcall(writefile, saveFile, newNick) end
                myAvatar = getAvatarForUser(newNick, getgenv().chat_custom_avatar)
                GlobalChat:SendMessage(myAvatar, "System", "Nickname set to: " .. newNick, false)
            else
                GlobalChat:SendMessage(myAvatar, "System", "Nickname must be 2-24 chars.", false)
            end
            return
        end

        -- /avatar command
        if text:sub(1, 8):lower() == "/avatar " then
            local newAv = text:sub(9):gsub("^%s+", ""):gsub("%s+$", "")
            if #newAv > 0 then
                if not newAv:find("rbxassetid://") and not newAv:find("http") then
                    newAv = "rbxassetid://" .. newAv
                end
                getgenv().chat_custom_avatar = newAv
                local saveFile = "swinoware_avatar_" .. tostring(LocalPlayer.UserId) .. ".txt"
                if writefile then pcall(writefile, saveFile, newAv) end
                myAvatar = newAv
                GlobalChat:SendMessage(myAvatar, "System", "Avatar updated!", false)
            else
                GlobalChat:SendMessage(myAvatar, "System", "Usage: /avatar <RobloxAssetId>", false)
            end
            return
        end

        -- Admin command /wipe
        if text:lower() == "/wipe" or text:lower() == "/clearall" then
            if not isCurrentPlayerAdmin then
                GlobalChat:SendMessage(myAvatar, "System", "Access denied: The /wipe command is restricted to Owners.", false)
                return
            end

            if ChatState.Connected and ChatState.Socket then
                local HttpService = game:GetService("HttpService")
                local payload = {
                    type = "wipe",
                    sessionId = ChatSessionId,
                    robloxUser = LocalPlayer.Name,
                    user = getgenv().chat_nickname or LocalPlayer.Name
                }
                pcall(function()
                    ChatState.Socket:Send(HttpService:JSONEncode(payload))
                end)
            end
            return
        end

        -- Admin command /announce
        if text:sub(1, 10):lower() == "/announce " then
            if not isCurrentPlayerAdmin then
                GlobalChat:SendMessage(myAvatar, "System", "Access denied: The /announce command is restricted to Owners.", false)
                return
            end

            if ChatState.Connected and ChatState.Socket then
                local HttpService = game:GetService("HttpService")
                local payload = {
                    type = "chat",
                    sessionId = ChatSessionId,
                    robloxUser = LocalPlayer.Name,
                    user = getgenv().chat_nickname or LocalPlayer.Name,
                    avatar = myAvatar,
                    text = text
                }
                pcall(function()
                    ChatState.Socket:Send(HttpService:JSONEncode(payload))
                end)
            end
            return
        end

        -- Non-admin rate limits and link checks
        if not isCurrentPlayerAdmin then
            if now - ChatState.LastSendTime < 1.5 then
                GlobalChat:SendMessage(myAvatar, "System", "Slow down! Wait 1.5s before sending another message.", false)
                return
            end

            if containsForbiddenLink(text) then
                GlobalChat:SendMessage(myAvatar, "System", "Posting links is prohibited in global chat.", false)
                return
            end
        end

        ChatState.LastSendTime = now

        local currentNick = getgenv().chat_nickname or LocalPlayer.Name
        myAvatar = getAvatarForUser(currentNick, getgenv().chat_custom_avatar)
        local displayName = isCurrentPlayerAdmin and ("[OWNER] " .. currentNick) or currentNick
        GlobalChat:SendMessage(myAvatar, displayName, text, true)
        logGlobalChatMessageToDiscord(currentNick, text, isCurrentPlayerAdmin and "Owner" or "User", LocalPlayer.Name)

        if ChatState.Connected and ChatState.Socket then
            local HttpService = game:GetService("HttpService")
            local payload = {
                type = "chat",
                sessionId = ChatSessionId,
                robloxUser = LocalPlayer.Name,
                user = currentNick,
                avatar = myAvatar,
                role = isCurrentPlayerAdmin and "Owner" or "User",
                text = text
            }
            pcall(function()
                ChatState.Socket:Send(HttpService:JSONEncode(payload))
            end)
        else
            connectGlobalChat()
        end
    end
end

GlobalChat:OnMessageSendPressed(processUserSendMessage)

task.spawn(function()
    task.wait(1)
    connectGlobalChat()
end)

-- Utilities & Settings
Window:Category("Utilities & Settings")

local MiscPage = Window:Page({
    Name = "Misc",
    Icon = "103180437044643",
    Columns = 1
})

local ServerSection = MiscPage:Section({
    Name = "Server Controls",
    Description = "Quick Server Actions",
    Icon = "126497581491926",
    Side = 1
})

ServerSection:Button({
    Name = "Toggle Menu",
    Callback = toggleMenuUI
})

ServerSection:Button({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

ServerSection:Button({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        end
    end
})

ServerSection:Button({
    Name = "Unload Script",
    Callback = UnloadScript
})


Library:CreateSettingsPage(Window, KeybindList)
    return CombatPage
end

BuildCheatTabs(Window, KeybindList)
