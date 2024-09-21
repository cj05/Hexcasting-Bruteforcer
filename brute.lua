staff = peripheral.wrap("left")
print(arg[1])
data = fs.open(arg[1] or "list.hexbrute","r").readAll()
patterns = textutils.unserializeJSON(data)
index = 1
total = #patterns
run = true
--print(patterns)
while run and index <= total do
    term.clear()
    term.setCursorPos(1,1)
    print(index,"/",total)
    local pattern = patterns[index]
    print("Clearing Stack")
    staff.clearStack()
    print("Executing")
    staff.runPattern(pattern[1],pattern[2])
    print("Retrieving Stack")
    local stack = staff.getStack()
    print("Checking")
    --print(stack)
    if(#stack==0) then
        run = false
        print("Found Pattern, ending BF")
        print(pattern[2])
    end
    index = index + 1
    sleep()
end
