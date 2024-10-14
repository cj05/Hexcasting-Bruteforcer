local pretty = require "cc.pretty"

local Queue = {}
Queue.__index = Queue

-- Constructor
function Queue:new()
    local obj = setmetatable({
        items = {},
        front = 1,
        back = 0
    }, Queue)
    return obj
end

-- Enqueue: Add an item to the end of the queue
function Queue:enqueue(item)
    self.back = self.back + 1
    self.items[self.back] = item
end

-- Dequeue: Remove and return the item from the front of the queue
function Queue:dequeue()
    if self:isEmpty() then
        return nil  -- Return nil if the queue is empty
    end
    local item = self.items[self.front]
    self.items[self.front] = nil  -- Remove reference to the item
    self.front = self.front + 1
    return item
end

-- Check if the queue is empty
function Queue:isEmpty()
    return self.front > self.back
end

function Queue:length()
    return self.back - self.front + 1
end

-- Peek: Return the item at the front without removing it
function Queue:peek()
    if self:isEmpty() then
        return nil
    end
    return self.items[self.front]
end



-- Define the class
local Hex = {}
Hex.__index = function(t, key)
    if Hex[key] ~= nil then
        return Hex[key]  -- Check first default table
    elseif t.staff[key] ~= nil then
        return t.staff[key]  -- Check second default table
    end
end

-- Constructor
function Hex:new(staff,threadcnt)
    local o = setmetatable({}, Hex)
    o.staff = staff or peripheral.find("wand")
    o.threadcnt = threadcnt or 10
    o.queue = Queue:new()
    setmetatable({}, Hex)
    o.__index = staff
    return o
end

function Hex:enqueue(pattern)
    self.queue:enqueue(pattern)
end

function Hex:execute(thread,pre,post)
    local x,y = term.getCursorPos()
    local startlen = self.queue:length()
    local start = os.epoch('local')
    thread = thread or function ()
        if self.queue:isEmpty() then
            return
        end
        self.staff.runPattern(unpack(self.queue:dequeue()))
    end

    pre = pre or function ()

    end

    post = post or function ()

    end


    threadlist = {}
    for i = 1, self.threadcnt, 1 do
        table.insert(threadlist,thread)
    end
    while not self.queue:isEmpty() do
        pre()
        parallel.waitForAll(unpack(threadlist))
        post()
        
        print("\r",self.queue:length(),"/",startlen,string.format("%.2f",(startlen-self.queue:length())/(os.epoch('local')-start)*1000),"P/S           ")

        term.setCursorPos(x,y)

        sleep()
    end
    print(string.format("Took %.2f seconds      ",(os.epoch('local')-start)/1000))
    print(string.format("Ran %.0f patterns      ",(startlen-self.queue:length())))
end


function Hex:runPatterns(patternlist)
    for _, pattern in ipairs(patternlist) do
        self:enqueue(pattern)
    end
    
    self:execute()
end

function Hex:evalNotGarbage(patternlist)
    --if self.enlightened() then
    --    print("Requires an unenlightened turtle")
    --    return
    --end
    print("Broad Scanning")
    local x,y = term.getCursorPos()
    print("Processing Pattern Data...")
    term.setCursorPos(x,y)
    for _, pattern in ipairs(patternlist) do
        self:enqueue(pattern)
    end

    local out_region_start,out_region_end

    function thread()
        if self.queue:isEmpty() then
            return
        end
        self.staff.clearStack()
        self.staff.runPattern(unpack(self.queue:dequeue()))
    end
    function pre()
        self.expected = math.min(self.queue:length(),self.threadcnt)
        self.staff.clearStack()
    end
    function post()
        if #self.staff.getStack() ~= self.expected then
            out_region_start = math.max(1,#patternlist - (self.queue:length()+self.threadcnt) + 1)
            out_region_end = #patternlist - self.queue:length()

            while not self.queue:isEmpty() do self.queue:dequeue() end
        end
    end
    print("Running.....                                         ")
    term.setCursorPos(x,y)
    
    self:execute(thread,pre,post)

    print("Completed, target in range [",out_region_start,",",out_region_end,"]               ")
    print("Narrow Scanning")
    local x,y = term.getCursorPos()
    print(x,y)
    print("Casting.....")
    term.setCursorPos(x,y)

    local outpattern

    for i = out_region_start,out_region_end do
        print("Casting..... ",i-out_region_start+1,"/",out_region_end-out_region_start+1,"          ")
        term.setCursorPos(x,y)
        self.clearStack()
	--print(unpack(patternlist[i]))
        self.runPattern(unpack(patternlist[i]))
        --pretty.pretty_print(self.getStack())
        if #self.getStack() == 0 then
            outpattern = patternlist[i]
            break
        end
    end
    print("Completed, found",outpattern[2])
    return outpattern
end


return Hex