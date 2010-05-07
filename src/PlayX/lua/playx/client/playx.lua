-- PlayX
-- Copyright (c) 2009, 2010 sk89q <http://www.sk89q.com>
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- $Id$

require("datastream")

CreateClientConVar("playx_enabled", 1, true, false)
CreateClientConVar("playx_fps", 14, true, false)
CreateClientConVar("playx_volume", 80, true, false)
CreateClientConVar("playx_provider", "", false, false)
CreateClientConVar("playx_uri", "", false, false)
CreateClientConVar("playx_start_time", "0:00", false, false)
CreateClientConVar("playx_force_low_framerate", 0, false, false)
CreateClientConVar("playx_use_jw", 1, false, false)
CreateClientConVar("playx_ignore_length", 0, false, false)
CreateClientConVar("playx_use_chrome", 1, true, false)
CreateClientConVar("playx_error_windows", 1, true, false)

PlayX = {}

include("playx/functions.lua")
include("playx/client/bookmarks.lua")
include("playx/client/handlers.lua")
include("playx/client/panel.lua")
include("playx/client/ui.lua")
include("playx/client/engines/html.lua")
include("playx/client/engines/gm_chrome.lua")

PlayX.Enabled = GetConVar("playx_enabled"):GetBool()
PlayX.JWPlayerURL = "http://playx.googlecode.com/svn/jwplayer/player.swf"
PlayX.HostURL = "http://sk89q.github.com/playx/host/host.html"
PlayX.Providers = {}

--- Checks if a player instance exists in the game.
-- @return Whether a player exists
function PlayX.PlayerExists()
    return table.Count(ents.FindByClass("gmod_playx")) > 0
end

--- Get all the PlayX entities.
-- @return
function PlayX.GetInstances()
    return ents.FindByClass("gmod_playx")
end

function PlayX.HasMedia()
    for _, v in pairs(PlayX.GetInstances()) do
        if v:HasMedia() then return true end
    end
    
    return false
end

function PlayX.HasPlaying()
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsPlaying() then return true end
    end
    
    return false
end

function PlayX.GetPlayingCount()
    local count = 0
    
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsPlaying() then count = count + 1 end
    end
    
    return count
end

--- Checks whether any media being played can be resumed.
function PlayX.HasResumable()
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsResumable() then return true end
    end
    
    return false
end

function PlayX.GetResumableCount()
    local count = 0
    
    for _, v in pairs(PlayX.GetInstances()) do
        if v:IsResumable() then count = count + 1 end
    end
    
    return count
end

function PlayX.GetEngine(name)
    return list.Get("PlayXEngines")[name]
end

--- Converts handler and arguments into an appropriate engine.
-- @param handler
-- @param args
-- @param width
-- @param height
-- @param start
-- @param volume
function PlayX.ResolveHandler(handler, args, screenWidth, screenHeight,
                              start, volume)
    -- See if there is a hook for resolving handlers
    local result = hook.Call("PlayXResolveHandler", false, handler)
    
    if result then
        return result
    end
    
    local handlers = list.Get("PlayXHandlers")
    
    if handlers[handler] then
        return handlers[handler](args, screenWidth, screenHeight, start, volume)
    else
        Error("PlayX: Unknown handler: " .. tostring(handler))
    end
end

--- Resume playing of everything.
function PlayX.ResumePlay()
    if not PlayX.HasMedia() then
        PlayX.ShowError("Nothing is playing.")
    else
        local count = 0
        
        for _, v in pairs(PlayX.GetInstances()) do
            if v:IsResumable() then
                v:Start()
                count = count + 1
            end
        end
        
        if count == 0 then
            PlayX.ShowError("The media being played cannot be resumed.")
        end
    end
    
    PlayX.UpdatePanels()
end

--- Stops playing everything.
function PlayX.StopPlay()
    if not PlayX.HasMedia() then
        PlayX.ShowError("Nothing is playing.\n")
    else
        for _, v in pairs(PlayX.GetInstances()) do
            v:Stop()
        end
    end
    
    PlayX.UpdatePanels()
end
PlayX.HidePlayer = PlayX.StopPlay -- Legacy

--- Reset the render bounds of the projector screen.
function PlayX.ResetRenderBounds()
    if not PlayX.PlayerExists() then
        PlayX.ShowError("Nothing is playing.\n")
    elseif PlayX.Enabled then
        for _, v in pairs(PlayX.GetInstances()) do
            v:ResetRenderBounds()
        end
    end
end

--- Sends a request to the server to play something.
-- @param provider Name of provider, leave blank to auto-detect
-- @param uri URI to play
-- @param start Time to start the video at, in seconds
-- @param forceLowFramerate Force the client side players to play at 1 FPS
-- @param useJW True to allow the use of the JW player, false for otherwise, nil to default true
-- @param ignoreLength True to not check the length of the video (for auto-close)
-- @return The result generated by a provider, or nil and the error message
function PlayX.RequestOpenMedia(provider, uri, start, forceLowFramerate, useJW, ignoreLength)
    if useJW == nil then useJW = true end
    
    RunConsoleCommand("playx_open", uri, provider, start,
                      forceLowFramerate and 1 or 0, useJW and 1 or 0,
                      ignoreLength and 1 or 0)
end

--- Sends a request to the server to stop playing.
function PlayX.RequestCloseMedia()
    RunConsoleCommand("playx_close")
end

--- Enables the player.
function PlayX.Enable()
    RunConsoleCommand("playx_enabled", "1")
end

--- Disables the player.
function PlayX.Disable()
    RunConsoleCommand("playx_enabled", "0")
end

--- Gets the player FPS.
-- @return
function PlayX.GetPlayerFPS()
    return math.Clamp(GetConVar("playx_fps"):GetInt(), 1, 30)
end

--- Sets the player FPS
-- @param fps
function PlayX.SetPlayerFPS(fps)
    RunConsoleCommand("playx_fps", fps)
end

--- Gets the player volume.
-- @return
function PlayX.GetPlayerVolume()
    return math.Clamp(GetConVar("playx_volume"):GetInt(), 0, 100)
end

--- Sets the player volume.
-- @return
function PlayX.SetPlayerVolume(vol)
    RunConsoleCommand("playx_volume", vol)
end

--- Called on PlayXBegin user message.
-- Sent when the server tell the client to play media. This may happen if the
-- user gets subscribed from a player.
local function HandleBeginMessage(_, id, encoded, decoded)
    local ent = decoded.Entity
    local handler = decoded.Handler
    local arguments = decoded.Arguments
    local playAge = decoded.PlayAge
    local resumable = decoded.Resumable
    local lowFramerate = decoded.LowFramerate
    local startTime = CurTime() - playAge
    
    MsgN("PlayX: Received PlayXBegin with handler " .. handler)
    
    if ValidEntity(ent) then
        ent:Begin(handler, arguments, resumable, lowFramerate, startTime)
        
        if PlayX.Enabled then
            ent:Start()
        end
    else
        Error("PlayXBegin message referred to non-existent entity")
    end
    
    PlayX.UpdatePanels()
end

local function HandleProvidersList(_, id, encoded, decoded)
    PlayX.Providers = decoded.List
end

--- Called on PlayXEnd user message.
-- Sent when the server tell the client to stop playing. This may happen if
-- the user gets unsubscribed from a player.
local function HandleEndMessage(um)
    local ent = um:ReadEntity()
    
    if ValidEntity(ent) then
        ent:End()
    else
        Error("PlayXEnd message referred to non-existent entity")
    end
    
    PlayX.UpdatePanels()
end

--- Called on PlayXError user message.
-- Sent when an error needs to be displayed.
local function HandleError(um)
    local err = um:ReadString()
    
    PlayX.ShowError(err)
end

datastream.Hook("PlayXBegin", HandleBeginMessage)
datastream.Hook("PlayXProvidersList", HandleProvidersList)
usermessage.Hook("PlayXEnd", HandleEndMessage)
usermessage.Hook("PlayXSpawnDialog", function() PlayX.OpenSpawnDialog() end)
usermessage.Hook("PlayXError", HandleError)

--- Called on playx_enabled change.
local function EnabledCallback(cvar, old, new)
    for _, instance in pairs(PlayX.GetInstances()) do
        if PlayX.Enabled then
            instance:Stop()
        else
            instance:Start()
        end
    end
    
    PlayX.UpdatePanels()
end

--- Called on playx_fps change.
local function FPSChangeCallback(cvar, old, new)
    for _, instance in pairs(PlayX.GetInstances()) do
        instance:UpdateFPS()
    end
end

--- Called on playx_volume change.
local function VolumeChangeCallback(cvar, old, new)
    hook.Call("PlayXVolumeChanged", nil, {PlayX.GetPlayerVolume()})
    
    for _, instance in pairs(PlayX.GetInstances()) do
        instance:UpdateVolume()
    end
end

cvars.AddChangeCallback("playx_enabled", EnabledCallback)
cvars.AddChangeCallback("playx_fps", FPSChangeCallback)
cvars.AddChangeCallback("playx_volume", VolumeChangeCallback)

--- Called for concmd playx_gui_open.
local function ConCmdGUIOpen()
    -- Let's handle bookmark keywords
    if GetConVar("playx_provider"):GetString() == "" then
        local bookmark = PlayX.GetBookmarkByKeyword(GetConVar("playx_uri"):GetString())
        if bookmark then
            bookmark:Play()
            return
        end
    end
    
    PlayX.RequestOpenMedia(GetConVar("playx_provider"):GetString(),
                           GetConVar("playx_uri"):GetString(),
                           GetConVar("playx_start_time"):GetString(),
                           GetConVar("playx_force_low_framerate"):GetBool(),
                           GetConVar("playx_use_jw"):GetBool(),
                           GetConVar("playx_ignore_length"):GetBool())
end

concommand.Add("playx_resume", function() PlayX.ResumePlay() end)
concommand.Add("playx_hide", function() PlayX.HidePlayer() end)
concommand.Add("playx_reset_render_bounds", function() PlayX.ResetRenderBounds() end)
concommand.Add("playx_gui_open", ConCmdGUIOpen)
concommand.Add("playx_gui_close", function() PlayX.RequestCloseMedia() end)
concommand.Add("playx_dump_html", function() PlayX.GetHTML() end)
concommand.Add("playx_update_window", function() PlayX.OpenUpdateWindow() end)