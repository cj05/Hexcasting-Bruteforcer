N=11
M=11

import numpy
import time

masterpattern = numpy.zeros((M,N,M,N))

stack = []

permutation = []

total_edge = 0

import tkinter

m = tkinter.Tk()

canvas=tkinter.Canvas(m, width=500, height=300)

canvas.pack()

def walk(masterpattern,x,y,dir):
    newx = x + (1 if dir == 0 else 0 if dir < 2 else -1 if dir < 5 else 0) + y%2 * (0 if (dir == 0 or dir == 3)else 1)
    newy = y + (0 if (dir == 0 or dir == 3) else 1 if dir < 3 else -1)

    return newx,newy

def add(masterpattern,x,y,dir):
    newx,newy = walk(masterpattern,x,y,dir)
    masterpattern[y][x][newy][newx] = 1
    masterpattern[newy][newx][y][x] = 1

    return newx,newy

def cangoto(masterpattern,x,y,dir):
    newx,newy = walk(masterpattern,x,y,dir)
    if newx<0 or newy<0 or newx>=M or newy>=N:
        return False
    if masterpattern[y][x][newy][newx] == 1:
        return True
    return False

def goto(masterpattern,x,y,dir):
    newx,newy = walk(masterpattern,x,y,dir)
    if masterpattern[y][x][newy][newx] == 1:
        masterpattern[y][x][newy][newx] = 2
        masterpattern[newy][newx][y][x] = 2
        return True
    return False

def revoke(masterpattern,x,y,dir):
    newx,newy = walk(masterpattern,x,y,dir)
    if masterpattern[y][x][newy][newx] == 2:
        masterpattern[y][x][newy][newx] = 1
        masterpattern[newy][newx][y][x] = 1
        return True
    return False

def getWalkable(masterpattern,x,y,dir):
    o = []
    for i in range(6):
        if(cangoto(masterpattern,x,y,(dir+i)%6)):
            o.append(i)

    return o

def realx(x,y):
    return x*50+y%2*25 +20
def realy(y):
    return y*40 +20

def out(pattern):
    canvas.delete("all")
    for i1 in range(M): # y
        for j1 in range(N): # x
            for i2 in range(M): # y
                for j2 in range(N): # x
                    if(pattern[i1][j1][i2][j2]==1):
                        # print(i1,j1,i2,j2)
                        canvas.create_line(realx(j1,i1),realy(i1),realx(j2,i2),realy(i2), fill="green", width=2)
                    if(pattern[i1][j1][i2][j2]==2):
                        # print(i1,j1,i2,j2)
                        canvas.create_line(realx(j1,i1),realy(i1),realx(j2,i2),realy(i2), fill="blue", width=2)
    for i in range(M): # y
        for j in range(N): # x
            canvas.create_oval(realx(j,i),realy(i),realx(j,i),realy(i),fill="black", width=3)
    m.update()



def generate(walk,dir,sx,sy):
    if dir == "EAST":
        dir = 0
    if dir == "SOUTH_EAST":
        dir = 1
    if dir == "SOUTH_WEST":
        dir = 2
    if dir == "WEST":
        dir = 3
    if dir == "NORTH_WEST":
        dir = 4
    if dir == "NORTH_EAST":
        dir = 5

    x = sx
    y = sy

    x,y = add(masterpattern,x,y,dir)
    global total_edge
    total_edge = len(walk)
    for c in walk:
        if c == "q":
            dir = dir - 1
        if c == "a":
            dir = dir - 2
        if c == "e":
            dir = dir + 1
        if c == "d":
            dir = dir + 2
        dir = dir % 6
        x,y = add(masterpattern,x,y,dir)

def getOriginPoint():
    o = []
    for i in range(M): # y
        for j in range(N): # x
            if len(getWalkable(masterpattern,i,j,0))%2 == 1:
                o.append((i,j))
    if len(o) > 0:
        return o

    for i in range(M): # y
        for j in range(N): # x
            if len(getWalkable(masterpattern,i,j,0)) >= 1:
                o.append((i,j))
    return o

def dfs(masterpattern,x,y,dir):
    #print(x,y)
    wkb = getWalkable(masterpattern,x,y,dir)
    #print(wkb)
    if len(wkb) == 0:
        #print(len(stack),total_edge,stack)
        if total_edge+1 == len(stack):
            #print(stack)
            permutation.append(stack.copy())
        return
    for k in wkb:
        xt,yt = walk(masterpattern,x,y,(dir+k)%6)
        goto(masterpattern,x,y,(dir+k)%6)
        stack.append(k)
        #out(masterpattern)   
        #time.sleep(0.3)
        dfs(masterpattern,xt,yt,(dir+k)%6)
        revoke(masterpattern,x,y,(dir+k)%6)
        stack.pop()
        #out(masterpattern)   
        #time.sleep(0.2)
        
def map_array_to_string(int_array):
    mapping = {0: 'w', 1: 'e', 2: 'd', 3: 's', 4: 'a', 5: 'q'}
    return ''.join(mapping[i] for i in int_array)

# https://github.com/FallingColors/HexMod/blob/6ca01051cdb7fe2e2a97e5a13a2dc274fed03f53/Common/src/main/java/at/petrak/hexcasting/common/lib/hex/HexActions.java#L295

print("Generating")

# Put Template Hex Here

# generate("aqqqaqwwaqqqqqeqaqqqawwqwqwqwqwqw", "SOUTH_WEST",1,2) # Phial, a few million lmao
# generate("eaqawqadaqd", "EAST",5,5) # Lava
# generate("eawwaeawawaa", "NORTH_WEST",5,5) # Altiora

# generate("qqqqaawawaedd", "NORTH_WEST",5,5) # White Sun Zenith (Regen)  144  permutation
# generate("qqqaawawaeqdd", "WEST",5,5) # Blue Sun Zenith (Night Vision)  72  permutation
# generate("qqaawawaeqqdd", "SOUTH_WEST",2,2)  # Black Sun Zenith (Absorbtion)  72  permutation
# generate("qaawawaeqqqdd","SOUTH_EAST",2,2)  # Red Sun Zenith (Haste)  72  permutation
generate("aawawaeqqqqdd", "EAST",2,2)  # Green Sun Zenith (Strength)  72  permutation

# generate("waeawaeqqqwqwqqwq", "EAST",5,5) # Greater Sentinel  1440  permutation
# generate("eadqqdaqadqqdaawwwwewawqwawdwqwwwqwwwdwewdwwwqwwwqw","WEST",8,3) # Mind Flay  46288  permutation (Not Recommended, Too Big, also you should have found it already, turtle needs mindsplice)



out(masterpattern)



for x1,y1 in getOriginPoint():
    print(x1,y1)
    dfs(masterpattern,x1,y1,0)

print("end")
# print(permutation)
print("there are ",len(permutation)," permutation")

print("Formatting")

ot = "["
i = 0
for pattern in permutation:
    if pattern[0] == 0:
        os = "[\"EAST\""
    if pattern[0] == 1:
        os = "[\"SOUTH_EAST\""
    if pattern[0] == 2:
        os = "[\"SOUTH_WEST\""
    if pattern[0] == 3:
        os = "[\"WEST\""
    if pattern[0] == 4:
        os = "[\"NORTH_WEST\""
    if pattern[0] == 5:
        os = "[\"NORTH_EAST\""
    os = os+",\""
    os = os + map_array_to_string(pattern[1:len(pattern)])
    os = os+"\"]"
    if i > 0:
        ot = ot + " ,"

    ot = ot + os
    
    i = i + 1
ot = ot + "]"
print("Generated, saving to list.hexbrute")
f = open("list.hexbrute", "w")
f.write(ot)
f.close()

m.mainloop()       
