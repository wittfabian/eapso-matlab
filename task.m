classdef task < matlab.mixin.Copyable
    
    properties
        id = 1;
        task_function;
        goal_position = [];
        
        func
    end
    
    properties (Constant)
        alpha = 0.8;
        delta = 0.5;
    end
    
    methods
        function obj = task(id, task_function, goal_position)
            
            if nargin < 3 || isempty(goal_position)
                goal_position = [];
            end
            
            obj.id = id;
            obj.task_function = task_function;
            obj.goal_position = goal_position;
        end
        
        function value = funcval(obj, position)
            if ~isempty(obj.goal_position)
                value = obj.task_function.f(position, obj.goal_position);
            else
                value = obj.task_function.f(position);
            end
        end
        
        function f = get.func(obj)
            f = obj.task_function;
        end
    end
end

