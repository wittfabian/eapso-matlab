classdef simulateContainer < matlab.mixin.Copyable
    
    properties
%         state = '';
%         action = '';
%         movecost = 0.0;
%         velocity = [];
%         profit = 0.0;
%         calcFuncval = 0.0;
%         risk = 0.0;
%         
%         particle = particle();
        state;
        action;
        movecost;
        velocity;
        profit;
        calcFuncval;
        risk;
        distanceToGlobalBest;
        
        particle;
    end
    
    methods
        function obj = simulateContainer()
            obj.state = '';
            obj.action = '';
            obj.movecost = 0.0;
            obj.velocity = [];
            obj.profit = 0.0;
            obj.calcFuncval = 0.0;
            obj.risk = 0.0;
            obj.distanceToGlobalBest = 0.0;

            obj.particle = particle();
        end
        
        function ret = getState(obj)
            ret = obj.state;
        end
        
        function ret = getAction(obj)
            ret = obj.action;
        end
        
        function ret = getMovecost(obj)
            ret = obj.movecost;
        end
        
        function ret = getVelocity(obj)
            ret = obj.velocity;
        end
        
        function ret = getProfit(obj)
            ret = obj.profit;
        end
        
        function ret = getRisk(obj)
            ret = obj.risk;
        end
        
        function ret = getdistanceToGlobalBest(obj)
            ret = obj.distanceToGlobalBest;
        end
        
        function obj = setProperties(obj, state, action, movecost, velocity, profit, calcFuncval, risk, distanceToGlobalBest)
            obj.state = state;
            obj.action = action;
            obj.movecost = movecost;
            obj.velocity = velocity;
            obj.profit = profit;
            obj.calcFuncval = calcFuncval;
            obj.risk = risk;
            obj.distanceToGlobalBest = distanceToGlobalBest;
        end
        
        function ret = printShortValues(obj)
            ret = sprintf('[movecost=%f; profit=%f; calcFuncval=%f]', obj.getMovecost, obj.getProfit, obj.calcFuncval);
        end
    end
    
end

