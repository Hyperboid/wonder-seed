---@class Event.qblock : Event
local event, super = Class(Event, "qblock")

---@param data table
function event:init(data)
    super.init(self,data)
    local properties = data.properties or {}
    self.sprite = Sprite("world/events/qblock/default")
    self:addChild(self.sprite)
    self.sprite.path = "world/events/qblock"
    self.sprite:setScale(2)
    self.solid = true
    local h = self.height/2
    self.ground_collider = Hitbox(self, 1,h+11,self.width-2,h-1)
    self.ground_collider.thickness = 30
    self:setHitbox(1,h+11,self.width-2,h-1)
    self.collider.thickness = 15
    self.collider.z = -20
    self.reusable = false
end

function event:postLoad()
    if self.world.map.side then
        self.sprite.path = self.sprite.path .. "/side"
        self:setHitbox(0,0,self.width,self.height)
    else
        self.z = self.z + 10
        self.y = self.y + 20
        self:move(0,10)
        self.sprite:move(0,10)
        self:setOrigin(0,1)
    end
    self.sprite:set("default")
    if not self.reusable and self:getFlag("used_once") then
        self.sprite:set("used")
    end
    self.init_z = self.z
    self.target_z = self.z + 10
end

function event:onHit(object, hit_type)
    if hit_type == "hammer" or (not self.world.map.side and object.z < (self.z-10)) or (self.world.map.side and object.y > (self.y+20)) then
        Assets.playSound("bump")
        -- if self.bumping then return end
        local resume
        resume = coroutine.wrap(function ()
            self.bumping = true
            self.sprite.z = 0
            if self.timer_handle then self.world.map.timer:cancel(self.timer_handle) end
            self.timer_handle = self.world.map.timer:tween(.1, self.sprite, {
                z = 0 + 10
            }, "out-quad", resume)
            coroutine.yield()
            if not self.reusable and self:getFlag("used_once", false) then
                self.world.timer:after(.1,resume)
                coroutine.yield()
            else
                self:setFlag("used_once", true)
                self:doItem(resume)
            end
            self.timer_handle = self.world.map.timer:tween(.1, self.sprite, {
                z = 0
            }, "in-quad", resume)
            if not self.reusable then
                self.sprite:set("used")
            end
            coroutine.yield()
            self.bumping = false
        end)
        resume()
    end
end

function event:doItem(resume)
    -- TODO: spawn a coin sprite here
    Assets.playSound("bell")
    Game.money = Game.money + 1
    self.world.timer:after(.1,resume)
    coroutine.yield()
end

function event:getDebugRectangle()
    return {0, self.height/4, self.width, self.height*1.5}
end

function event:drawShadow()
    if self.world.map.side then return end
    Draw.setColor(COLORS.black(.2))
    love.graphics.ellipse("fill", (self.width/2), self.height + self:getGroundLevel() * -2, 16,8)
end

function event:getSortPosition()
    return self.x, self.y-8
end

return event