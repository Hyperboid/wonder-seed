---@class World : World
local World, super = Class("World")
---@cast super World

function World:checkCollision(collider, ...)
    Object.startCache()
    do
        local collided, with = super.checkCollision(self, collider, ...)
        if collided then
            Object.endCache()
            return true, with
        end
    end
    if not self.stage then
        Object.endCache()
        return false
    end
    local floor_found = false
    if self.map.data and self.map.data.properties and self.map.data.properties.floor then
        floor_found = true
    end
    for _, plane in ipairs(self.stage:getObjects()) do
        ---@cast plane GroundPlane
        if plane.getHeightFor and plane:collidesWith(collider) then
            floor_found = true
            if plane:getHeightFor(collider.parent) > ((collider.parent.z)+3) then
                Object.endCache()
                return true, plane
            end
        end
    end
    Object.endCache()
    return not floor_found
end

function World:init(map)
    super.init(self, map)
    self.buttonprompt = MNLButtonPrompt()
    self.buttonprompt:setParallax(0)
    self.buttonprompt.layer = WORLD_LAYERS["below_ui"] - 1
    self.buttonprompt.persistent = true
    self.buttonprompt.world = self
    self:addChild(self.buttonprompt)
end

function World:setupMap(map, ...)
    super.setupMap(self, map, ...)
    self.action_pages = self:getActionPages()
    self.action_index = 1
end

function World:toggleActions()
    self.action_pages = self:getActionPages()
    local action_count = #self.action_pages
    if action_count > 1 then
        self.action_index = Utils.clampWrap(self.action_index + 1, 1, action_count)
        Assets.playSound("noise")
    end
end

function World:getActionPages()
    local pages = {"jump"}
    if Game:getFlag("has_hammers") then table.insert(pages, "hammer") end
    return pages
end
---@return "jump"|"hammer"
function World:getActionPage()
    return self.action_pages[self.action_index]
end

function World:sortChildren()
    Object.startCache()
    local positions = {}
    for _,child in ipairs(self.children) do
        local x, y = child:getSortPosition()
        positions[child] = {x = x, y = y}
    end
    table.stable_sort(self.children, function(a, b)
        local a_pos, b_pos = positions[a], positions[b]
        local ax, ay = a_pos.x, a_pos.y
        local bx, by = b_pos.x, b_pos.y
        if a.layer == b.layer then
            if a:includes(GroundPlane) and b:includes(GroundPlane) then
                return ((b.y-b.target_z)) > ((a.y-a.target_z))
            end
        end
        -- Sort children by Y position, or by follower index if it's a follower/player (so the player is always on top)
        return a.layer < b.layer or
              (a.layer == b.layer and (math.floor(ay) < math.floor(by) or
              (math.floor(ay) == math.floor(by) and (b == self.player or
              (a:includes(Follower) and b:includes(Follower) and b.index < a.index)
            ))))
    end)
    Object.endCache()
end

function World:spawnFollower(chara, options)
    local f = super.spawnFollower(self, chara, options)
    local dx, dy = Utils.getFacingVector(f.facing)
    local dist = (((self.player.walk_speed * 15) * FOLLOW_DELAY))
    f.x = f.x - (dx*dist)
    f.y = f.y - (dy*dist)
    f:interpolateHistory()
    return f
end

function World:onKeyPressed(key)
    if Input.is("actionswap", key) then
        self:toggleActions()
    elseif Input.is("menu", key) and not (self.player and self.player.state_manager.state == "WALK") then
        return
    end
    return super.onKeyPressed(self, key)
end

return World
