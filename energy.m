classdef energy < matlab.mixin.Copyable %handle
    
    properties (Constant)
        ACTION_FLY = 'fly';
        ACTION_HOVER = 'hover';
        ACTION_START = 'start';
        ACTION_LAND = 'land';
        ACTION_GROUND = 'ground';
        ACTION_CHARGE = 'charge';
    end
    
    properties
        min = 0
        max = 20
        value
        
        unit = 1; % maximum usable energy per time unit
        
        min_energy_lvl;
            
        max_cost = 0.8;         % percentage
        hover_cost = 0.38;      % percentage
        ground_cost = 0.0;      % percentage
        charge_profit = 1; %0.10;   % percentage
        
        start_hover_diff = 0.10;
        land_hover_diff = -0.10;
        
        start_cost;             % percentage / hover_cost + start_hover_diff (0.10)
        land_cost;              % percentage / hover_cost + land_hover_diff (-0.10)
        
        max_distance = 1;

        min_energy_start
        min_energy_fly
    end
    
    methods
        function obj = energy(value)
            if nargin > 0
                obj.value = value;
            else
            	obj.value = getRandom( obj.max - 5, obj.max );
            end
        end
        
        function val = get.start_cost(obj) 
            val = obj.unit * (obj.hover_cost + obj.start_hover_diff);
        end
        
        function val = get.land_cost(obj)
            val = obj.unit * (obj.hover_cost + obj.land_hover_diff);
        end
        
        function val = get.min_energy_start(obj)
            % val = obj.unit * (obj.start_cost + obj.hover_cost * 2 + obj.max_cost * 4);
            val = obj.unit * (obj.max * 0.5);
        end
        
        function val = get.min_energy_fly(obj)
            val = obj.unit * (obj.max_cost + obj.land_cost);
        end
        
        function val = get.min_energy_lvl(obj)
            % val = obj.unit;
            val = obj.land_cost;
        end
        
        function increase(obj, value, is_percentage)
            
            if nargin < 3
                is_percentage = false;
            end
            
            if is_percentage == true
                energy_increase = obj.value * value;
            else
                energy_increase = value;
            end
            
            if (obj.value + energy_increase) >= obj.max
                obj.value = obj.max;
            else
                obj.value = obj.value + energy_increase;
            end
        end
        
        function [old_energy_value, energy_decrease, new_energy_value] = decrease(obj, value, is_percentage)
            
            if nargin < 3
                is_percentage = false;
            end
            
            old_energy_value = obj.value;
            
            if is_percentage == true
                energy_decrease = obj.value * value;
            else
                energy_decrease = value;
            end
            
            if (obj.value - energy_decrease) <= obj.min
                obj.value = obj.min;
            else
                obj.value = obj.value - energy_decrease;
            end
            
            new_energy_value = obj.value;
        end
        
        function [old_energy_value, energy_change, new_energy_value] = calculateByAction(obj, action, distance)
            
            if nargin < 3
                distance = 0;
            end
            
            old_energy_value = obj.value;
            
            switch action
                case obj.ACTION_FLY
                    energy_change = obj.unit * (((distance / obj.max_distance) * (obj.max_cost - obj.hover_cost)) + obj.hover_cost);
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_HOVER
                    energy_change = obj.unit * obj.hover_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_START
                    energy_change = obj.unit * obj.start_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_LAND
                    energy_change = obj.unit * obj.land_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_GROUND
                    energy_change = obj.unit * obj.ground_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_CHARGE
                    energy_change = obj.unit * obj.charge_profit;
                    new_energy_value = obj.value + energy_change;
                otherwise
                    error(['energy action not known: "' action '"']);
            end
        end
        
        function [old_energy_value, energy_change, new_energy_value] = doAction(obj, action, distance)
            
            if nargin < 3
                distance = 0;
            end
            
            old_energy_value = obj.value;
            
            switch action
                case obj.ACTION_FLY
                    energy_change = obj.unit * (((distance / obj.max_distance) * (obj.max_cost - obj.hover_cost)) + obj.hover_cost);
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_HOVER
                    energy_change = obj.unit * obj.hover_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_START
                    energy_change = obj.unit * obj.start_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_LAND
                    energy_change = obj.unit * obj.land_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_GROUND
                    energy_change = obj.unit * obj.ground_cost;
                    new_energy_value = obj.value - energy_change;
                case obj.ACTION_CHARGE
                    energy_change = obj.unit * obj.charge_profit;
                    new_energy_value = obj.value + energy_change;
                otherwise
                    error(['energy action not known: "' action '"']);
            end
            
            obj.value = new_energy_value;
            
            if obj.value < obj.min
                obj.value = obj.min;
            end
            
            if obj.value > obj.max
                obj.value = obj.max;
            end
        end
    end
end

