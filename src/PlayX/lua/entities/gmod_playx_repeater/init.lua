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

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
resource.AddFile("materials/vgui/entities/gmod_playx_repeater.vmt")

include("shared.lua")

--- Initialize the entity.
-- @hidden
function ENT:Initialize()
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
    self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
    self.Entity:SetSolid(SOLID_VPHYSICS)
    self.Entity:DrawShadow(false)
    
    self:SetUseType(SIMPLE_USE)
end

--- Set the PlayX entity to be the source. Pass nil or NULL to clear.
-- @param src Source
function ENT:SetSource(src)
    src = src or NULL
    self.dt.Source = src
end

--- Get the server-side set source entity. May return nil.
-- @return Source
function ENT:GetSource()
    return ValidEntity(self.dt.Source) and self.dt.Source or nil
end

--- Do nothing UpdateTransmitState (the entity doesn't need to
-- always be known by the client).
-- @hidden
function ENT:UpdateTransmitState()
end

--- Spawn function.
-- @hidden
function ENT:SpawnFunction(ply, tr)
    if hook.Call("PlayXRepeaterSpawnFunction", GAMEMODE, ply, tr) == false then return end
    
    PlayX.SendSpawnDialog(ply, true)
end

--- When the entity is used.
-- @hidden
function ENT:OnUse(activator, caller)
    hook.Call("PlayXRepeaterUse", GAMEMODE, self, activator, caller) 
end

--- Removal function.
-- @hidden
function ENT:OnRemove()
end

--- Duplication function.
-- @hidden
local function PlayXRepeaterEntityDuplicator(ply, model, pos, ang)
    if not PlayX.IsPermitted(ply) then
        return nil
    end
    
    local ent = ents.Create("gmod_playx_repeater")
    ent:SetModel(model)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    
    if ply.AddCleanup then
        ply:AddCleanup("gmod_playx_repeater", ent)
    end
    
    return ent
end

duplicator.RegisterEntityClass("gmod_playx_repeater", PlayXRepeaterEntityDuplicator, "Model", "Pos", "Ang")