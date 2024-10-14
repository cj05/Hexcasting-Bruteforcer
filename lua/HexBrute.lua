local HexcastCC = require "Hex"

local expect = require("cc.expect")
local expect, field = expect.expect, expect.field
local wrap = require("cc.strings").wrap    



local sub, find, match, concat, tonumber = string.sub, string.find, string.match, table.concat, tonumber

    --- Skip any whitespace
    local function skip(str, pos)
        local _, last = find(str, "^[ \n\r\t]+", pos)
        if last then return last + 1 else return pos end
    end

    local escapes = {
        ["b"] = '\b', ["f"] = '\f', ["n"] = '\n', ["r"] = '\r', ["t"] = '\t',
        ["\""] = "\"", ["/"] = "/", ["\\"] = "\\",
    }

    local mt = {}

    local function error_at(pos, msg, ...)
        if select('#', ...) > 0 then msg = msg:format(...) end
        error(setmetatable({ pos = pos, msg = msg }, mt))
    end

    local function expected(pos, actual, exp)
        if actual == "" then actual = "end of input" else actual = ("%q"):format(actual) end
        error_at(pos, "Unexpected %s, expected %s.", actual, exp)
    end

    local function parse_string(str, pos, terminate)
        local buf, n = {}, 1

        -- We attempt to match all non-special characters at once using Lua patterns, as this
        -- provides a significant speed boost. This is all characters >= " " except \ and the
        -- terminator (' or ").
        local char_pat = "^[ !#-[%]^-\255]+"
        if terminate == "'" then char_pat = "^[ -&(-[%]^-\255]+" end

        while true do
            local c = sub(str, pos, pos)
            if c == "" then error_at(pos, "Unexpected end of input, expected '\"'.") end
            if c == terminate then break end

            if c == "\\" then
                -- Handle the various escapes
                c = sub(str, pos + 1, pos + 1)
                if c == "" then error_at(pos, "Unexpected end of input, expected escape sequence.") end

                if c == "u" then
                    local num_str = match(str, "^%x%x%x%x", pos + 2)
                    if not num_str then error_at(pos, "Malformed unicode escape %q.", sub(str, pos + 2, pos + 5)) end
                    buf[n], n, pos = utf8.char(tonumber(num_str, 16)), n + 1, pos + 6
                else
                    local unesc = escapes[c]
                    if not unesc then error_at(pos + 1, "Unknown escape character %q.", c) end
                    buf[n], n, pos = unesc, n + 1, pos + 2
                end
            elseif c >= " " then
                local _, finish = find(str, char_pat, pos)
                buf[n], n = sub(str, pos, finish), n + 1
                pos = finish + 1
            else
                error_at(pos + 1, "Unescaped whitespace %q.", c)
            end
        end

        return concat(buf, "", 1, n - 1), pos + 1
    end

    local num_types = { b = true, B = true, s = true, S = true, l = true, L = true, f = true, F = true, d = true, D = true }
    local function parse_number(str, pos, opts)
        local _, last, num_str = find(str, '^(-?%d+%.?%d*[eE]?[+-]?%d*)', pos)
        local val = tonumber(num_str)
        if not val then error_at(pos, "Malformed number %q.", num_str) end

        if opts.nbt_style and num_types[sub(str, last + 1, last + 1)] then return val, last + 2 end

        return val, last + 1
    end

    local function parse_ident(str, pos)
        local _, last, val = find(str, '^([%a][%w_]*)', pos)
        return val, last + 1
    end

    local arr_types = { I = true, L = true, B = true }

_G.last_yield = 0

local function decode_impl(str, pos, opts)
	if os.epoch("local") - _G.last_yield > 5000 then
            print(".")
	    sleep()
            _G.last_yield = os.epoch("local")
        end
        local c = sub(str, pos, pos)
        if c == '"' then return parse_string(str, pos + 1, '"')
        elseif c == "'" and opts.nbt_style then return parse_string(str, pos + 1, "\'")
        elseif c == "-" or c >= "0" and c <= "9" then return parse_number(str, pos, opts)
        elseif c == "t" then
            if sub(str, pos + 1, pos + 3) == "rue" then return true, pos + 4 end
        elseif c == 'f' then
            if sub(str, pos + 1, pos + 4) == "alse" then return false, pos + 5 end
        elseif c == 'n' then
            if sub(str, pos + 1, pos + 3) == "ull" then
                if opts.parse_null then
                    return json_null, pos + 4
                else
                    return nil, pos + 4
                end
            end
        elseif c == "{" then
            local obj = {}

            pos = skip(str, pos + 1)
            c = sub(str, pos, pos)

            if c == "" then return error_at(pos, "Unexpected end of input, expected '}'.") end
            if c == "}" then return obj, pos + 1 end

            while true do
                local key, value
                if c == "\"" then key, pos = parse_string(str, pos + 1, "\"")
                elseif opts.nbt_style then key, pos = parse_ident(str, pos)
                else return expected(pos, c, "object key")
                end

                pos = skip(str, pos)

                c = sub(str, pos, pos)
                if c ~= ":" then return expected(pos, c, "':'") end

                value, pos = decode_impl(str, skip(str, pos + 1), opts)
                obj[key] = value

                -- Consume the next delimiter
                pos = skip(str, pos)
                c = sub(str, pos, pos)
                if c == "}" then break
                elseif c == "," then pos = skip(str, pos + 1)
                else return expected(pos, c, "',' or '}'")
                end

                c = sub(str, pos, pos)
            end

            return obj, pos + 1

        elseif c == "[" then
            local arr, n = {}, 1

            pos = skip(str, pos + 1)
            c = sub(str, pos, pos)

            if arr_types[c] and sub(str, pos + 1, pos + 1) == ";" and opts.nbt_style then
                pos = skip(str, pos + 2)
                c = sub(str, pos, pos)
            end

            if c == "" then return expected(pos, c, "']'") end
            if c == "]" then
                if opts.parse_empty_array ~= false then
                    return empty_json_array, pos + 1
                else
                    return {}, pos + 1
                end
            end

            while true do
                n, arr[n], pos = n + 1, decode_impl(str, pos, opts)

                -- Consume the next delimiter
                pos = skip(str, pos)
                c = sub(str, pos, pos)
                if c == "]" then break
                elseif c == "," then pos = skip(str, pos + 1)
                else return expected(pos, c, "',' or ']'")
                end
            end

            return arr, pos + 1
        elseif c == "" then error_at(pos, 'Unexpected end of input.')
        end

        error_at(pos, "Unexpected character %q.", c)
    end

local unserializeJson = function(s, options)
        expect(1, s, "string")
        expect(2, options, "table", "nil")

        if options then
            field(options, "nbt_style", "boolean", "nil")
            field(options, "parse_null", "boolean", "nil")
            field(options, "parse_empty_array", "boolean", "nil")
        else
            options = {}
        end

        local ok, res, pos = pcall(decode_impl, s, skip(s, 1), options)
        if not ok then
            if type(res) == "table" and getmetatable(res) == mt then
                return nil, ("Malformed JSON at position %d: %s"):format(res.pos, res.msg)
            end

            error(res, 0)
        end

        pos = skip(s, pos)
        if pos <= #s then
            return nil, ("Malformed JSON at position %d: Unexpected trailing character %q."):format(pos, sub(s, pos, pos))
        end
        return res

end
_G.textutils.unserializeJson = unserializeJson
_G.textutils.unserialiseJson = unserializeJson


local staff = HexcastCC:new(nil,200)

staff.clearStack()

--start of the program
local name = "qwerty"
local write = true
local online = false

for index, a in ipairs(arg) do
    if a == "-o" then
        online = true
    end
    
    if a == "-nw" then
        write = false
    end
end


if not online then
    if fs.exists("list.hexbrute") then
        data = fs.open(arg[1] or "list.hexbrute","r").readAll()
        name = arg[1] or "list.hexbrute","r"
    else
        online = true
    end
end


--print(arg[1])
if online then
    print("Entering Online Mode")
    local repo = "https://raw.githubusercontent.com/cj05/Hexcasting-Bruteforcer/refs/heads/main/registry.json"
    local response = http.get(repo)
    local resdata = response.readAll()
    local repoinfo = textutils.unserializeJSON(resdata)
    local wait = true
    local selection
    while wait do
        print("Available Pattern Datas")
        for i,_ in pairs(repoinfo) do
        print(i)
        end
        local sel = read()
        if repoinfo[sel] ~= nil then
            selection = repoinfo[sel]
            name = sel
            wait = false
            break
        end
        term.setCursorPos(1,1)
        term.clear()
        print("Invalid Selection, Please Try Again")
    end
    print("Fetching....")
    if type(selection) == "table" then
        data = ""
        for i,v in pairs(selection) do
            response = http.get(v)
            data = data .. response.readAll()
            print("Done ",i,"/",#selection)
            sleep()
        end
    else
        response = http.get(selection)
        data = response.readAll()
    end
    --print(data)
end
print("Formatting....")
patterns = unserializeJson(data)
term.setCursorPos(1,1)
term.clear()
print("Bruteforcing",name)
print("Casting....")
output = staff:evalNotGarbage(patterns)


local focal_port = peripheral.find("focal_port")
if focal_port then
    if write then
        focal_port.writeIota({startDir=output[1],angles=output[2]})
    end
end

if pocket then
    if write then
        print("Will Be Writing to offhand focus, press anything to continue")
        os.pullEvent("key")
        staff.clearStack()
        staff.pushStack({startDir=output[1],angles=output[2]})
        staff.runPattern("EAST","deeeee")
    end
end

