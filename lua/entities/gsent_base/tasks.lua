



-- tasks.lua
-- Task system for gs_entmodule


gs_entmodule = gs_entmodule or {}
gs_entmodule.Task = gs_entmodule.Task or {}
local Task = gs_entmodule.Task

Task.Tasks = Task.Tasks or {}

local function prioritySorting(x, y)

    if not (x and y) then return end 

    x = Task.Tasks[x]
    y = Task.Tasks[y]

    if not (x and y) then return end

    return (x.Priority or 0) < (y.Priority or 0)
end

function Task.SortTasksByPriority(self)
    local tasks = self.ActiveTasks
    if not tasks then return end
    table.sort(tasks, prioritySorting)
end

function Task.CallHookFromTask(self, hookName, ...)
    if not self.ActiveTasks or #self.ActiveTasks == 0 then return end

    for i = #self.ActiveTasks, 1, -1 do
        local taskName = self.ActiveTasks[i]
        local hookFunc = Task.Tasks[taskName] and Task.Tasks[taskName][hookName]

        if hookFunc then
            local success, returns = xpcall(hookFunc, gs_aimodule.ThrowError, self, ...)
            if returns == true then break end
        end
    end
end


function Task.AddTask(self, taskName, ...)
    if not Task.Tasks[taskName] then gs_entmodule.ThrowError( "The task ".. taskName .. " does not exist!" ) return end

    self.ActiveTasks = self.ActiveTasks or {}

    
    local stateFlag = Task.Tasks[ taskName ].StateFlag 
    
    if table.HasValue(self.ActiveTasks, taskName) then return end
    
    table.insert(self.ActiveTasks, taskName)
    Task.SortTasksByPriority(self)

    self:PreTaskInitialization(taskName)
    if  Task.Tasks[taskName] and  Task.Tasks[taskName].OnTaskInitialization then 
     Task.Tasks[taskName].OnTaskInitialization(self, ...)   
    end
    self:PostTaskInitialization(taskName)

    if stateFlag then 
        local oldTask = self["TaskState_" .. tostring(stateFlag)]
        self:PreNewState( oldTask, taskName,  stateFlag)
        Task.RemoveTask( self,  self["TaskState_" .. tostring(stateFlag)] )
        self["TaskState_" .. tostring(stateFlag)] = taskName 
        self:PostNewState( oldTask, taskName,  stateFlag)
    end 

end

function Task.RemoveTask(self, taskName)
    if not self.ActiveTasks then return end

    for k, v in ipairs(self.ActiveTasks) do
        if v == taskName then
            if Task.Tasks[v].OnTaskTermination then
                Task.Tasks[v].OnTaskTermination(self)
            end
            self:PreTaskRemoval(self, taskName)
            table.remove(self.ActiveTasks, k)
            self:PostTaskRemoval(self, taskName)
            break
        end
    end


    Task.SortTasksByPriority(self)
end



function Task.RunPreferredTaskFor(self, goalName)
    local taskName = self["Preferred"..(goalName).."Task"]

    if istable(taskName) then 
        taskName = taskName[ math.random(#taskName) ]
    end 

    Task.AddTask(self, taskName) 
end 

include("entities/gsent_base/taskscontainer.lua")

