--- Type annotations for default minetest types

---@class ObjectRef

---@class Pos
---@field x number
---@field y number
---@field z number

---@class PointedThing
---@field type PointedThingType
---@field under Pos
---@field above Pos
---@field ref ObjectRef

---@alias PointedThingType "nothing" | "node" | "object"

---@class NodeTable
---@field name string
---@field param1 number
---@field param2 number

---@class NodeDef
---@field description string
---@field short_description string|nil

---@class MetaDataRef
