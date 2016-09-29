classdef stateGround < state
    
    properties
        name
        action  % wait, charge, start
    end
    
    methods
        function obj = stateGround(particle)
            obj@state(particle);
            
            obj.name = obj.STATE_GROUND;
            obj.action = obj.ACTION_CHARGE;
        end
        
        function obj = move(obj, simCont)
            
            if ~isa(simCont, 'simulateContainer')
                error('No simCont!!');
            end
            
            if strcmp(simCont.getState, obj.STATE_AIR)
                obj.start();
                return;
            elseif strcmp(simCont.getState, obj.STATE_GROUND)
                if strcmp(simCont.getAction, obj.ACTION_CHARGE)
                    obj.charge();
                    return;
                else
                    obj.wait();
                    return;
                end
            end
            
            error(['particle ' num2str(obj.particleIdx) ' does nothing at state ground'])
        end
        
        function ret = simulateMove(obj)
            
            %ret = obj.particleObj.simCont;
            
            % if the individual has enough energy he can start
            if obj.particleObj.energyval >= obj.particleObj.energy.min_energy_start
                obj.calculateStartingCost();
                ret = obj.particleObj.simCont;
                return;
            end
            
            % else: the individual is charging
            obj.particleObj.setSaveSimulate(obj.STATE_GROUND, obj.ACTION_CHARGE, 0, [0 0], 0, 0, obj.particleObj.risk, 0);
            
            ret = obj.particleObj.simCont;
        end
        
        function name = get.name(obj)
            name = [obj.name ' (' obj.action ')'];
        end
        
        function charge(obj)
            obj.action = obj.ACTION_CHARGE;
            obj.particleObj.energy.doAction(energy.ACTION_CHARGE);
        end
        
        function obj = start(obj)
            obj.particleObj.energy.doAction(energy.ACTION_START);
            obj.particleObj.state = stateAir(obj.particle);
        end
        
        function obj = wait(obj)
            obj.action = obj.ACTION_WAIT;
        end
        
        function [old_energy_value, energy_change, new_energy_value] = calculateStartingCost(obj)
            [old_energy_value, energy_change, new_energy_value] = obj.particleObj.energy.calculateByAction(energy.ACTION_CHARGE);

            obj.particleObj.setSaveSimulate(obj.STATE_AIR, obj.ACTION_FLY, energy_change, [0 0], 0, 0, obj.particleObj.risk, 0);
        end
    end
    
end