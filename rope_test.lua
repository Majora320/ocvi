local rope = require("rope")
local Rope = rope.Rope
local RopeNode = rope.RopeNode
local lu = require("luaunit")

function test_basic()
    local r = Rope.new("Hello, world!")
    ensure_equal(r, "Hello, world!")
end

function test_concat()
    local r = Rope.new("Hello, ")
    r:append("world!")
    ensure_equal(r, "Hello, world!")
    r:append(" Test String")
    ensure_equal(r, "Hello, world! Test String")
end

function test_split()
    local r = Rope.new("Test")
    local t = r:split(2)
    ensure_equal(r, "Te")
    ensure_equal(t, "st")


    local r = Rope.new("test")
    r:append("ing")

    local t = r:split(1)
    ensure_equal(r, "t")
    ensure_equal(t, "esting")

    local r = Rope.new("H")
    r:append("el")
    r:append("lo")
    r:append(" wor")
    r:append("ld!")

    local t = r:split(6)
    ensure_equal(r, "Hello ")
    ensure_equal(t, "world!")

    local r1 = Rope.new("Hello,")
    r1:append(" world!")
    local r2 = Rope.new(" Test ")
    r2:append("String")
    local r = Rope.concat(r1, r2)

    ensure_equal(r, "Hello, world! Test String")

    local t = r:split(15)

    ensure_equal(r, "Hello, world! T")
    ensure_equal(t, "est String")

    local r = Rope.new("FOO")
    local t = r:split(3)
    ensure_equal(r, "FOO")
    ensure_equal(t, "")
end

function test_insert()
    local r = Rope.new("OOBAR2000")
    r:insert(0, "F")
    ensure_equal(r, "FOOBAR2000")

    local r = Rope.new("FOOBAR")
    r:insert(6, "2000")
    ensure_equal(r, "FOOBAR2000")

    local r = Rope.new("Hello world")
    r:insert(5, ",")
    r:insert(12, "!")
    ensure_equal(r, "Hello, world!")
end

function test_delete()
    local r = Rope.new("FOOBAR2000")
    r:delete(1, 1)
    ensure_equal(r, "OOBAR2000")

    local r = Rope.new("FOOBAR2000")
    r:delete(7, 10)
    ensure_equal(r, "FOOBAR")

    local r = Rope.new("Hello, world!")
    r:delete(1, 1)
    r:insert(0, "h")
    r:delete(6, 7)
    r:delete(11, 11)
    ensure_equal(r, "helloworld")
end

function test_report()
    local r = Rope.new("Florb")
    lu.assertEquals(r:report(1, 5), "Florb")
    lu.assertEquals(r:report(2, 5), "lorb")
    lu.assertEquals(r:report(3, 4), "or")
    lu.assertEquals(r:report(1, 1), "F")
    lu.assertEquals(r:report(3, 3), "o")
    lu.assertEquals(r:report(5, 5), "b")
    
    local r = Rope.new("Hello")
    r:append(", ")
    r:append("world!")
    lu.assertEquals(r:report(1, 13), "Hello, world!")
    lu.assertEquals(r:report(3, 10), "llo, wor")
    lu.assertEquals(r:report(5, 5), "o")
    
    local r = Rope.new("int main() {\n")
    r:append("public static void main() {\n")
    r:append("}}\n")
    lu.assertEquals(r:report_until(1, function(i, s) return s:sub(i, i) == "\n" end), "int main() {")
    lu.assertEquals(r:report_until(21, function(i, s) return s:sub(i, i) == "\n" end), "static void main() {")
end

function ensure_equal(r, expected)
    local maxi

    for i = 1, #expected do
        lu.assertEquals(r[i], expected:sub(i, i))
        maxi = i
    end

    lu.assertErrorMsgContains("nil", function() return r[maxi + 1] end)
end

function print_weights(t, indent)
    if t.root ~= nil then t = t.root end

    if indent == nil then
        indent = 0
    end

    local space = " "
    print(space:rep(indent) .. "\"" .. t.string .. "\" " .. t.weight)

    if t.left then
        print_weights(t.left, indent + 4)
    end

    if t.right then
        print_weights(t.right, indent + 4)
    end
end

os.exit(lu.LuaUnit:run())
