create schema test;

--the generic af udf
CREATE LUA SET SCRIPT af (func varchar(40), arg double, lower_bound double, upper_bound double, groupkey varchar(200), val varchar(2000)) 
EMITS (res double, groupkey varchar(200), val varchar(2000)) AS
-- analytical functions -------------------------------------------------------
local af_sum = function(window)
   local sum = 0
   for i,v in ipairs(window.data) do
       if v ~= null then
           sum = sum + v
       end
   end
   return sum
end
function af_geometric_mean(window)
    local root = 0
    local product = 1
    for i, v in ipairs(window.data) do
        if v ~= null then
            root = root + 1
            product = product * v
        end
    end
    return math.pow(product, 1/root)
end
-- Window ---------------------------------------------------------------------
Window = { 
    data ={},
    data_row=1,
    afunction,
    out_row=0,
    lower = 0,
    upper = 0,
    winsize = 0,
    partition_size=0
}
function Window:new ()
    o={data={}}
    setmetatable(o,self)
    self.__index = self
    return o
end
function Window:useTheseBoundaries(lower_bound, upper_bound, part_size)
    if ((math.floor(lower_bound) ~= lower_bound) or (math.floor(upper_bound) ~= upper_bound)) then
        error('window bound has to be integer')
    end
    if ((lower_bound < 0) or (upper_bound < 0)) then
        error('negative window bound')
    end
    self.lower = lower_bound
    self.upper = upper_bound
    self.winsize = lower_bound + upper_bound + 1
    self.partition_size = part_size
end
function Window:useThisFunction(f)
    self.afunction = f
end
function Window:checkBoundaries(lower_bound, upper_bound)
    if (self.lower ~= 0 and self.lower ~= lower_bound) then
        error('lower window bound is not constant')
    end
    if (self.upper ~= 0 and self.upper ~= upper_bound) then
        error('upper window bound is not constant')
    end
end
function Window:shrink()
    if self.data_row > self.winsize then
        table.remove(self.data, 1)
    end
end
function Window:grow(val)
    if (self.data_row <= self.partition_size) then
        table.insert(self.data, val)
        self.data_row = self.data_row+1
    end
    self.out_row = self.out_row+1
end
function Window:growInitial(val)
    table.insert(self.data, val)
    self.data_row = self.data_row+1
end
function Window:updateWindow(val)
    self:shrink()
    self:grow(val)
end
function Window:hasData()
    self:shrink()
    if (self.out_row < self.partition_size) then
        self.out_row = self.out_row+1
        return true
    else
       return false
    end
end
function Window:computeAF()
    return self.afunction(self)
end
-- main function --------------------------------------------------------------
function run(ctx)
local groupKey = ctx.groupkey
local valBuffer = {}
-- set up the window
local w = Window:new()
if ctx.func=='SUM' then
    w:useThisFunction(af_sum)
elseif ctx.func=='GEOMETRIC_MEAN' then
    w:useThisFunction(af_geometric_mean)
else
    error('unknown analytical function ' .. ctx.func .. ' in generic udf af')
end
w:useTheseBoundaries(ctx.lower_bound, ctx.upper_bound, ctx.size())
-- init Window
local window_position = 1
if window_position <= ctx.upper_bound then
    repeat
        w:checkBoundaries(ctx.lower_bound, ctx.upper_bound)
        w:growInitial(ctx.arg)
        window_position = window_position + 1
        table.insert(valBuffer, ctx.val)
    until (not ctx.next()) or (window_position > ctx.upper_bound )
end
-- compute Window
if (window_position <= ctx.size()) then
	repeat
        w:checkBoundaries(ctx.lower_bound, ctx.upper_bound)
        w:updateWindow(ctx.arg)
        table.insert(valBuffer, ctx.val)
        ctx.emit(w:computeAF(), groupKey, valBuffer[w.out_row])
    until (not ctx.next()) 
end
while(w:hasData()) do
    ctx.emit(w:computeAF(), groupKey, valBuffer[w.out_row])
end
end
/

--simple test data and queries
create table t(id int, x int);
insert into t values (1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(2,10),(2,20),(2,30),(3,100),(3,200),(4,1000);
insert into t values (1,NULL);
select af('SUM', x, 2, 2, id, x order by x asc) from t group by id;
select af('SUM', x, 0, 2, id, x order by x asc) from t group by id;
select af('SUM', x, 2, 0, id, x order by x asc) from t group by id;