

-- tasks.lua
-- Task system for gs_aimodule

gs_aimodule = gs_aimodule or {}
gs_aimodule.Task = gs_aimodule.Task or {}
local Task = gs_aimodule.Task

Task.Tasks = Task.Tasks or {}

local function prioritySorting(x, y)
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

local function InterruptCoroutine(self)
    self.CoroutineInterrupted = true 
    timer.Simple( 0.1, function() 
        if IsValid( self ) then 
            self.CoroutineInterrupted = false 
        end 
    end )
end 



function Task.AddTask(self, taskName, ...)
    self.ActiveTasks = self.ActiveTasks or {}



    if table.HasValue(self.ActiveTasks, taskName) then  print("SHI") return end

    if Task.Tasks[ taskName ] and Task.Tasks[ taskName ].RunBehaviour then 
        self.HasTaskWithRunBehaviour = true 
        if self.HasTaskWithRunBehaviour then 
            for taskIndex, taskName in ipairs( self.ActiveTasks ) do 
                local taskData = Task.Tasks[taskName]
                if taskData and taskData.RunBehaviour then 
                    Task.RemoveTask( self, taskName, true )
                end 
            end 
        end
    end 


  
    
    table.insert(self.ActiveTasks, taskName)
    Task.SortTasksByPriority(self)

    if not Task.Tasks[taskName] or not Task.Tasks[taskName].OnTaskInitialization then return end
    Task.Tasks[taskName].OnTaskInitialization(self, ...)
end

function Task.RemoveTask(self, taskName, dontClearRunBehaviourFlag)
    if not self.ActiveTasks then return end

    local taskData = Task.Tasks[ taskName ]

    if taskData and taskData.RunBehaviour then  
        InterruptCoroutine( self )
        if not dontClearRunBehaviourFlag then 
        self.HasTaskWithRunBehaviour = false 
        end 
    end 

    for k, v in ipairs(self.ActiveTasks) do
        if v == taskName then
            if Task.Tasks[v].OnTaskTermination then
                Task.Tasks[v].OnTaskTermination(self)
            end
            table.remove(self.ActiveTasks, k)
            break
        end
    end

    Task.SortTasksByPriority(self)
end

include("entities/gsnpc_base/enemy_tasks.lua")