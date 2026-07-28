---@class OverworldSoul : OverworldSoul
local OverworldSoul, super = Class("OverworldSoul")


function OverworldSoul:update()
    -- Bullet collision !!! Yay
    if Game.inv_frames > 0 then
        Game.inv_frames = Utils.approach(Game.inv_frames, 0, DT)
    end

    self.sprite.alpha = 1 -- ??????

    Object.startCache()
    for _,bullet in ipairs(Game.stage:getObjects(WorldBullet)) do
        if bullet:collidesWith(self.collider) then
            self:onCollide(bullet)
        end
    end
    Object.endCache()

    if Game.inv_frames > 0 then
        self.inv_flash_timer = self.inv_flash_timer + DT
        local amt = math.floor(self.inv_flash_timer / (4/30))
        if (amt % 2) == 1 then
            self.sprite:setColor(0.5, 0.5, 0.5)
        else
            self.sprite:setColor(1, 1, 1)
        end
    else
        self.inv_flash_timer = 0
        self.sprite:setColor(1, 1, 1)
    end

    local sx, sy = self.x, self.y
    local progress = 0

    local soul_party = Game:getSoulPartyMember()
    if soul_party then
        local soul_character = Game.world:getPartyCharacterInParty(soul_party)
        if soul_character then
            sx, sy = soul_character:getRelativePos(soul_character.actor:getSoulOffset())
            sy = sy - (soul_character.z*2)
        end
    end

    local tx, ty = sx, sy

    if Game.world.player and Game.world.player.battle_alpha > 0 then
        tx, ty = Game.world.player:getRelativePos(Game.world.player.actor:getSoulOffset())
        ty = ty - (Game.world.player.z*2)
        progress = Game.world.player.battle_alpha * 2
    end

    self.x = Utils.lerp(sx, tx, progress * 1.5)
    self.y = Utils.lerp(sy, ty, progress * 1.5)
    self.alpha = progress

    Object.update(self)
end

return OverworldSoul
