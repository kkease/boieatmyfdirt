--[[
    Comprehensive Gift All Pets Script
    1. Tries holding E method first
    2. Falls back to remote methods if E doesn't work
    3. Gifts ALL pets found, not just one
]]

-- CHANGE THIS USERNAME
local TARGET_USERNAME = "mariaisabum25"

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    TELEPORT_DELAY = 2,
    E_HOLD_DURATION = 4,
    GIFT_DELAY = 1,
    MAX_ATTEMPTS_PER_PET = 5,
    PROXIMITY_DISTANCE = 3
}

-- State tracking
local GiftState = {
    pets_gifted = 0,
    pets_failed = 0,
    current_method = "E_KEY"
}

-- Enhanced logging
local function log(...)
    local args = {...}
    local message = table.concat(args, " ")
    print("[GIFT-ALL]", message)
end

-- Get character safely
local function get_character()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    return character, hrp
end

-- Find target player
local function find_target()
    if TARGET_USERNAME == "YourTargetUsernameHere" then
        log("ERROR: Change TARGET_USERNAME!")
        return nil
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower() == TARGET_USERNAME:lower() then
            log("Found target:", player.Name)
            return player
        end
    end
    
    log("Target not found:", TARGET_USERNAME)
    return nil
end

-- Find ALL pets (comprehensive search)
local function find_all_pets()
    log("=== COMPREHENSIVE PET SEARCH ===")
    local all_pets = {}
    
    -- Enhanced pet detection
    local function is_pet(obj)
        if not obj then return false end
        
        local name = obj.Name:lower()
        
        -- Skip obvious non-pets
        if obj:IsA("Tool") and not (
            obj:FindFirstChild("Rarity") or 
            obj:FindFirstChild("Level") or 
            obj:FindFirstChild("Age") or
            obj:FindFirstChild("PetData")
        ) then
            return false
        end
        
        -- Pet indicators
        local pet_properties = {
            obj:FindFirstChild("Rarity"),
            obj:FindFirstChild("Level"),
            obj:FindFirstChild("Age"), 
            obj:FindFirstChild("Species"),
            obj:FindFirstChild("PetData"),
            obj:FindFirstChild("PetType"),
            obj:FindFirstChild("Stats")
        }
        
        local has_pet_property = false
        for _, prop in pairs(pet_properties) do
            if prop then
                has_pet_property = true
                break
            end
        end
        
        -- Pet name patterns
        local pet_patterns = {
            "pet", "raccoon", "chicken", "kiwi", "bee", "dragon",
            "cat", "dog", "bird", "bunny", "rabbit", "tiger", "lion",
            "wolf", "bear", "fox", "snake", "turtle", "fish", "hamster",
            "unicorn", "phoenix", "griffin", "pegasus"
        }
        
        local has_pet_name = false
        for _, pattern in pairs(pet_patterns) do
            if name:find(pattern) then
                has_pet_name = true
                break
            end
        end
        
        -- Age/weight indicators (like "Kiwi [1.07 KG] [Age 1]")
        local has_age_weight = name:find("%[.*kg.*%]") or name:find("%[.*age.*%]")
        
        return has_pet_property or (has_pet_name and has_age_weight)
    end
    
    -- Search function
    local function search_location(obj, location_name, depth, max_depth)
        if not obj or depth > max_depth then return end
        
        if is_pet(obj) then
            table.insert(all_pets, {
                object = obj,
                location = location_name,
                name = obj.Name
            })
            log("FOUND PET:", obj.Name, "in", location_name)
        end
        
        -- Search children
        for _, child in pairs(obj:GetChildren()) do
            search_location(child, location_name, depth + 1, max_depth)
        end
    end
    
    -- Search all possible locations
    local locations = {
        {LocalPlayer.Backpack, "Backpack", 2},
        {LocalPlayer:FindFirstChild("PlayerGui"), "PlayerGui", 4},
        {LocalPlayer:FindFirstChild("Pets"), "Pets", 3},
        {LocalPlayer:FindFirstChild("Inventory"), "Inventory", 3},
        {LocalPlayer:FindFirstChild("PlayerData"), "PlayerData", 4},
        {LocalPlayer:FindFirstChild("Data"), "Data", 4},
        {LocalPlayer:FindFirstChild("Stats"), "Stats", 3},
        {ReplicatedStorage:FindFirstChild("PlayerData"), "RS_PlayerData", 3},
        {LocalPlayer, "LocalPlayer_Full", 5}
    }
    
    for _, location_data in pairs(locations) do
        local location, name, max_depth = location_data[1], location_data[2], location_data[3]
        if location then
            log("Searching:", name)
            search_location(location, name, 0, max_depth)
        end
    end
    
    log("=== SEARCH COMPLETE ===")
    log("Total pets found:", #all_pets)
    
    return all_pets
end

-- Method 1: E Key Proximity Gifting
local function try_e_key_gifting(target_player, pet_data)
    log("Trying E key method for:", pet_data.name)
    
    local character, hrp = get_character()
    if not target_player.Character or not target_player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local target_hrp = target_player.Character.HumanoidRootPart
    
    -- Get very close
    hrp.CFrame = target_hrp.CFrame + Vector3.new(Config.PROXIMITY_DISTANCE, 0, 0)
    wait(1)
    
    -- Hold E key
    log("Holding E key for", Config.E_HOLD_DURATION, "seconds...")
    
    local e_success = pcall(function()
        -- Start holding E
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        
        -- Hold for duration
        wait(Config.E_HOLD_DURATION)
        
        -- Release E
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    
    if e_success then
        log("E key method completed for:", pet_data.name)
        wait(2) -- Wait to see if gift GUI appears
        return true
    else
        log("E key method failed for:", pet_data.name)
        return false
    end
end

-- Method 2: Remote Event Gifting
local function try_remote_gifting(target_player, pet_data)
    log("Trying remote methods for:", pet_data.name)
    
    -- Find gift remotes
    local gift_remotes = {}
    
    local function find_gift_remotes(obj, depth)
        if not obj or depth > 3 then return end
        
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("gift") or name:find("trade") or name:find("send") then
                table.insert(gift_remotes, obj)
            end
        end
        
        for _, child in pairs(obj:GetChildren()) do
            find_gift_remotes(child, depth + 1)
        end
    end
    
    if ReplicatedStorage then
        find_gift_remotes(ReplicatedStorage, 0)
    end
    
    log("Found", #gift_remotes, "gift remotes")
    
    -- Try each remote with multiple patterns
    for _, remote in pairs(gift_remotes) do
        log("Trying remote:", remote.Name)
        
        local gift_patterns = {
            -- Common patterns
            function() remote:FireServer(pet_data.object) end,
            function() remote:FireServer(target_player, pet_data.object) end,
            function() remote:FireServer(pet_data.object, target_player) end,
            function() remote:FireServer(target_player.Name, pet_data.object) end,
            function() remote:FireServer(pet_data.object, target_player.Name) end,
            
            -- With action strings
            function() remote:FireServer("GiftPet", target_player, pet_data.object) end,
            function() remote:FireServer("Gift", target_player.Name, pet_data.name) end,
            function() remote:FireServer("SendPet", target_player, pet_data.object) end,
            
            -- RemoteFunction patterns
            function() 
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer(target_player, pet_data.object)
                end
            end,
            function() 
                if remote:IsA("RemoteFunction") then
                    remote:InvokeServer("GiftPet", target_player, pet_data.object)
                end
            end
        }
        
        for i, pattern in pairs(gift_patterns) do
            local success, result = pcall(pattern)
            if success then
                log("Remote pattern", i, "succeeded for", pet_data.name, "via", remote.Name)
                return true
            else
                log("Remote pattern", i, "failed:", result)
            end
            wait(0.1)
        end
        
        wait(0.5)
    end
    
    return false
end

-- Method 3: GUI Interaction
local function try_gui_interaction(target_player, pet_data)
    log("Trying GUI interaction for:", pet_data.name)
    
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    -- Look for gift/trade GUIs
    local gui_names = {"GiftGui", "TradeGui", "PetGift", "Gift", "Trade", "PetTrade"}
    
    for _, gui_name in pairs(gui_names) do
        local gui = playerGui:FindFirstChild(gui_name)
        if gui and gui.Enabled then
            log("Found active GUI:", gui_name)
            
            -- Try to interact with the GUI
            local function click_buttons(obj)
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local text = obj.Text:lower()
                    if text:find("gift") or text:find("send") or text:find("confirm") or text:find("trade") then
                        log("Clicking button:", obj.Text)
                        pcall(function()
                            obj.MouseButton1Click:Fire()
                        end)
                        return true
                    end
                end
                
                for _, child in pairs(obj:GetChildren()) do
                    if click_buttons(child) then
                        return true
                    end
                end
                
                return false
            end
            
            if click_buttons(gui) then
                return true
            end
        end
    end
    
    return false
end

-- Main gifting function for ALL pets
local function gift_all_pets(target_player, all_pet_data)
    log("=== STARTING TO GIFT ALL", #all_pet_data, "PETS ===")
    
    GiftState.pets_gifted = 0
    GiftState.pets_failed = 0
    
    for i, pet_data in pairs(all_pet_data) do
        log("Processing pet", i .. "/" .. #all_pet_data .. ":", pet_data.name)
        
        local pet_gifted = false
        local attempts = 0
        
        while not pet_gifted and attempts < Config.MAX_ATTEMPTS_PER_PET do
            attempts = attempts + 1
            log("Attempt", attempts, "for", pet_data.name)
            
            -- Method 1: Try E key first
            if try_e_key_gifting(target_player, pet_data) then
                pet_gifted = true
                GiftState.current_method = "E_KEY"
            end
            
            -- Method 2: Try remotes if E key didn't work
            if not pet_gifted then
                if try_remote_gifting(target_player, pet_data) then
                    pet_gifted = true
                    GiftState.current_method = "REMOTE"
                end
            end
            
            -- Method 3: Try GUI interaction
            if not pet_gifted then
                if try_gui_interaction(target_player, pet_data) then
                    pet_gifted = true
                    GiftState.current_method = "GUI"
                end
            end
            
            wait(Config.GIFT_DELAY)
        end
        
        if pet_gifted then
            GiftState.pets_gifted = GiftState.pets_gifted + 1
            log("✓ Successfully gifted:", pet_data.name, "using", GiftState.current_method)
        else
            GiftState.pets_failed = GiftState.pets_failed + 1
            log("✗ Failed to gift:", pet_data.name, "after", attempts, "attempts")
        end
        
        -- Brief pause between pets
        wait(1)
    end
    
    log("=== GIFTING COMPLETE ===")
    log("Pets gifted:", GiftState.pets_gifted)
    log("Pets failed:", GiftState.pets_failed)
    log("Success rate:", math.floor((GiftState.pets_gifted / #all_pet_data) * 100) .. "%")
end

-- Main function
local function main()
    log("=== COMPREHENSIVE GIFT ALL PETS SCRIPT ===")
    log("Target:", TARGET_USERNAME)
    
    -- Find target
    local target = find_target()
    if not target then 
        log("Cannot continue without target")
        return 
    end
    
    -- Find all pets
    local all_pets = find_all_pets()
    if #all_pets == 0 then
        log("No pets found to gift")
        return
    end
    
    -- Get close to target initially
    local character, hrp = get_character()
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        log("Moving close to target...")
        hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
        wait(Config.TELEPORT_DELAY)
    end
    
    -- Gift all pets using multiple methods
    gift_all_pets(target, all_pets)
    
    log("Script execution complete!")
end

-- Execute with full error protection
local success, error_msg = pcall(main)
if not success then
    log("Script error:", error_msg)
end