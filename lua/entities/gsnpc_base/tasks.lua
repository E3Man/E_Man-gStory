

-- tasks.lua
-- Task system for gs_aimodule

gs_aimodule = gs_aimodule or {}
gs_aimodule.Task = gs_aimodule.Task or {}
local Task = gs_aimodule.Task

Task.Tasks = Task.Tasks or {}

include("entities/gsnpc_base/taskcontainer.lua")

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



    if table.HasValue(self.ActiveTasks, taskName) then return end

    if Task.Tasks[ taskName ] and Task.Tasks[ taskName ].RunBehaviour then 
        if self.HasTaskWithRunBehaviour then 
            for taskIndex, taskName in ipairs( self.ActiveTasks ) do 
                local taskData = Task.Tasks[taskName]
                if taskData and taskData.RunBehaviour then 
                    Task.RemoveTask( self, taskName, true )
                end 
            end 
            self.HasTaskWithRunBehaviour = false  -- Clear the flag before setting it again
        end
        self.HasTaskWithRunBehaviour = true 
    end 


  
    
    table.insert(self.ActiveTasks, taskName)
    Task.SortTasksByPriority(self)

    self:PreTaskInitialization(taskName)
    if  Task.Tasks[taskName] and  Task.Tasks[taskName].OnTaskInitialization then 
     Task.Tasks[taskName].OnTaskInitialization(self, ...)   
    end
    self:PostTaskInitialization(taskName)
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

    self:TaskRemoval(taskName)
    Task.SortTasksByPriority(self)
end



function Task.RunPreferredTaskFor(self, goalName)
    local taskName = self["Preferred"..(goalName or "Idle").."Task"]

    if istable(taskName) then 
        taskName = taskName[ math.random(#taskName) ]
    end 

    Task.AddTask(self, taskName) 
end 

function Task.RunPIdleOrCombatTask(self)
    local hasEnemies = not table.IsEmpty(self.Enemies) 

    local goal = hasEnemies and "Combat" or "Idle"


    Task.RunPreferredTaskFor(self, goal)

end 

function Task.RunEssentialTasks(self)
    local tasks = Task.EssentialTasks 

    for _, task in ipairs(tasks) do 
        Task.AddTask( self, task )
    end 
end 

Task.EssentialTasks = {
    "SensoryAI_IdleOnNoEnemies",
    "SensoryAI_CombatOnEnemies",
    "SensoryAI_FlagIdle"
}

include("entities/gsnpc_base/enemy_tasks.lua")