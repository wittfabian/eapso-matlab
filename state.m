classdef (Abstract) state < matlab.mixin.Copyable %handle
    
    properties (Abstract)
        name;
        action;    
    end
    
    properties
        particle;
        particleIdx;
        particleObj;
        
        logger; %= log4m.getLogger( 'logfile.txt' );
    end
    
    properties (Constant)
        ACTION_START = 'start';
        ACTION_LAND = 'land';
        ACTION_HOVER = 'hover';
        ACTION_FLY = 'fly';
        ACTION_CHARGE = 'charge';
        ACTION_WAIT = 'wait';
        
        STATE_GROUND = 'ground';
        STATE_AIR = 'air';
    end
    
    methods (Abstract)
        move(obj)
        simulateMove(obj)
    end
    
    methods
        function obj = state(particle)
            if nargin > 0
                obj.particle = particle;
            end
        end
        
        function particle = get.particleObj(obj)
            
            global swarmObj;
            
            particle = swarmObj.getParticleById(obj.particle);
        end
        
        function particle = get.particleIdx(obj)
            particle = obj.particle;
        end
        
        function logger = get.logger(~)
            global swarmObj;
            logger = swarmObj.logger;
        end
        
        function velocity_new = getTurbulence(~, velocity_old)
            
            if sum(velocity_old < 0.0001) == length(velocity_old)
                
                velocity_new = arrayfun(@(x) getRandom(-0.5, 0.5), velocity_old);
                
                %obj.logger.info('getTurbulence', sprintf('p%i: from [%s] to [%s] velocity', obj.particleIdx, sprintf('%d;', velocity_old), sprintf('%d;', velocity_new)));
            else 
                velocity_new = velocity_old;
            end
       end
        
%         function velocity_new = getTurbulence(obj, velocity_old)
%             %velocity_new = arrayfun(@(x) x + getRandom(-0.5, 0.5), velocity_old);
%             velocity_new = arrayfun(@(x) x + ( obj.particleObj.risk * getRandom(-0.5, 0.5) ), velocity_old);
%         end
    end
end
