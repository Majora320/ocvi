local math = require("math")

local Rope = {}
Rope.__index = Rope
setmetatable(Rope, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

-- Non-leaf nodes are represented by empty strings in the `string` field.
local RopeNode = {}
RopeNode.__index = RopeNode
setmetatable(RopeNode, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function RopeNode.new(string, left, right)
    local self = setmetatable({}, RopeNode)

    self.string = string
    self.weight = #string

    self.sum_weights = RopeNode.sum_weights
    self.concat = RopeNode.concat

    if left then
        self.left = left
        self.left.parent = self
        self.weight = self.weight + self.left:sum_weights()
    end

    if right then
        self.right = right
        self.right.parent = self
    end

    return self
end

function RopeNode:sum_weights()
    local sum = #self.string

    if self.left then
        if self.left.right then
            sum = sum + self.left.weight + self.left.right:sum_weights()
        else
            sum = sum + self.left.weight
        end
    end

    if self.right then
        if self.right.right then
            sum = sum + self.right.weight + self.right.right:sum_weights()
        else
            sum = sum + self.right.weight
        end
    end

    return sum
end

function RopeNode.concat(left, right)
    return RopeNode.new("", left, right)
end

function Rope.new(initial)
    local self = setmetatable({}, Rope)

    if type(initial) == "string" then
        self.root = RopeNode.new(initial)
    else
        self.root = initial
    end

    self.get_node_and_index = Rope.get_node_and_index
    self.concat = Rope.concat
    self.append = Rope.append
    self.split = Rope.split
    self.insert = Rope.insert
    self.delete = Rope.delete
    self.report_until = Rope.report_until
    self.report = Rope.report

    return self
end

function Rope:get_node_and_index(i)
    local function index_node(node, i)
        if node.weight <= i then
            return index_node(node.right, i - node.weight)
        elseif node.left then
            return index_node(node.left, i)
        else
            return node, i
        end
    end

    local node, i = index_node(self.root, i - 1)
    return node, i + 1
end

function Rope:__len()
    return self.root:sum_weights()
end

function Rope:__index(i)
    local node, i = self:get_node_and_index(i)
    return node.string:sub(i, i)
end

function Rope.concat(left, right)
     return Rope.new(RopeNode.concat(left.root, right.root))

    -- TODO: rebalance tree
end

function Rope:append(s)
    self.root = RopeNode.concat(self.root, RopeNode.new(s))
end

function Rope:split(i)
    local node, i = self:get_node_and_index(i)

    local detatched_nodes = {}
    local sub_weight

    if  i ~= #node.string then
        local left = RopeNode.new(node.string:sub(1, i))

        detatched_nodes[#detatched_nodes+1] = RopeNode.new(node.string:sub(i + 1))
        sub_weight = detatched_nodes[1].weight
        
        node.string = left.string
        node.weight = left.weight
    end

    local last = node
    node = node.parent
    
    while node ~= nil do
        if node.left == last then
            local detatch = node.right
            detatched_nodes[#detatched_nodes+1] = detatch

            node.string = last.string
            node.weight = last.weight
            node.left = last.left
            node.right = last.right

            
            if node.string == "" then -- non-leaf node
                --node.weight = node.weight - sub_weight
                -- TODO: optimize this if possible
                node.weight = node.left:sum_weights()
            end
        end
		
        last = node
        node = node.parent
    end

    -- Processes in reverse order because our list of nodes is reversed
    local function balanced_bst(nodes, start, end_)
        if start == end_ then
            return nodes[start]
        else
            return RopeNode.concat(
                balanced_bst(nodes, start, end_ - math.floor((end_ - start) / 2) - 1),
                balanced_bst(nodes, end_ - math.floor((end_ - start) / 2), end_)
            )
        end
    end
    
    if #detatched_nodes == 0 then
        return Rope.new("")
    else
        return Rope.new(balanced_bst(detatched_nodes, 1, #detatched_nodes))
    end

    -- TODO: rebalance tree
end

function Rope:insert(i, s)
    if i == 0 then
        self.root = RopeNode.concat(RopeNode.new(s), self.root)
    elseif i == #self then
        self.root = RopeNode.concat(self.root, RopeNode.new(s))
    else
        local t = self:split(i)
        t = RopeNode.concat(RopeNode.new(s), t.root)
        self.root = RopeNode.concat(self.root, t)
    end
end

function Rope:delete(i, j)
    if i == 1 then
        local t = self:split(j)
        self.root = t.root
    elseif j == #self then
        self:split(i - 1)
    else
        local t = self:split(j)
        self:split(i - 1)
        self.root = RopeNode.concat(self.root, t.root)
    end
end

-- Term is a function that takes two parameters: The current index, and the full reported string (it can find the most
-- recent character by just doing `s.sub(i, i)`). The returned string excludes the last element (e.g. the one that was
-- added on the round that `term` returned false)
function Rope:report_until(start, term)
    local node, _ = self:get_node_and_index(start)
    local current_index = 1
    local res = ""

    -- TODO: in-order traversal from `node`
end

function Rope:report(start, end_)
    return Rope:report_until(start, function(i, _) return i == end_ end)
end

return { Rope = Rope, RopeNode = RopeNode }
