staff = peripheral.wrap("left")
--print(arg[1])
if arg[1] == "-o" then
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
            wait = false
        end
        term.setCursorPos(1,1)
        term.clear()
        print("Invalid Selection, Please Try Again")
    end
    response = http.get(selection)
    data = response.readAll()
    print(data)
else
    data = fs.open(arg[1] or "list.hexbrute","r").readAll()
end
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
end
