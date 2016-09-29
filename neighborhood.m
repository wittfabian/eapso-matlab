classdef (Abstract) neighborhood < matlab.mixin.Copyable %handle
    
    properties (Abstract)
        name
    end
    
    properties
        particle;
        particles;
        globalBest;
        tempNeighborhood;
        
        particleObj;
        particlesObj;
        globalBestObj;
        tempNeighborhoodObj;
        
        particleIdx;
        particlesIdx;
        globalBestIdx;
        tempNeighborhoodIdx;
        
        ref_task_id;
        
        nh_size;
        
        logger %= log4m.getLogger( 'logfile.txt' );
    end
    
    methods (Abstract)
        findGlobalBest(obj)
        countParticleInNeighborhood(obj)
    end

    methods
        function obj = neighborhood(particle, particles)
            if nargin > 0
                obj.particle = particle;
                obj.particles = particles;
                
%                 newPos = 1;
%                 for p = 1:1:size(particles, 2)
%                     if particles(p) ~= particle
%                         obj.particles(newPos) = particles(p);
%                         newPos = newPos + 1;
%                     end
%                 end
                
                if size(particles, 2) == 0
                    error('create neighborhood: size(neighborhood) == 0');
                end
            end
        end
        
        function nh_size = get.nh_size(obj)
            nh_size = size(obj.particles, 2);
        end
        
        function logger = get.logger(~)
            global swarmObj;
            logger = swarmObj.logger;
        end
        
        function task_id = get.ref_task_id(obj)
            task_id = obj.particleObj.task_id;
        end
       
        
        function particle = get.particleObj(obj)
            
            global swarmObj;
            
            particle = swarmObj.particles(obj.particle);
        end
        
        function particles = get.particlesObj(obj)
            
            global swarmObj;
            
            for p = 1:1:size(obj.particles, 2)
                particles(p) = swarmObj.particles(obj.particles(p));
            end
        end
        
        function particle = get.globalBestObj(obj)
            
            global swarmObj;
            
            particle = swarmObj.particles(obj.globalBest);
        end
        
        function particles = get.tempNeighborhoodObj(obj)
            
            global swarmObj;
            
            for p = 1:1:size(obj.tempNeighborhood, 2)
                particles(p) = swarmObj.particles(obj.tempNeighborhood(p));
            end
        end
        
        
        function particle = get.particleIdx(obj)
            particle = obj.particle;
        end
        
        function particles = get.particlesIdx(obj)
            particles = obj.particles;
        end
        
        function particle = get.globalBestIdx(obj)
            particle = obj.globalBest;
        end
        
        function particles = get.tempNeighborhoodIdx(obj)
            particles = obj.tempNeighborhood;
        end
        
        
        function particle = getParticleById(~, idx)
            global swarmObj;
            
            particle = swarmObj.getParticleById(idx);
        end
        
        
        function pos = getPositions(obj)     
            
            global swarmObj;
            
            for p = 1:1:size(obj.particles, 2)
                pos(p,:) = swarmObj.particles(p).position;
            end
        end
        
        function funcval = getGlobalBestFuncVal(obj)
            funcval = obj.globalBestObj.taskFuncval(obj.particleObj.task_id);
        end
        
        function funcval = getFunctionValues(obj)
            
            global swarmObj;
            
            task_id = obj.particleObj.task_id;
            
            for p = 1:1:size(obj.particles, 2)
                funcval(p) = swarmObj.particles(p).taskFuncval(task_id);
            end
        end

        function landscapeMemoryMatrix = getParticleLandscapeMemory(obj)
            
            %landscapeMemoryMatrix = obj.tempNeighborhoodObj(1).landscape_memory;
            landscapeMemoryMatrix = obj.tempNeighborhoodObj(1).movement_memory;

            for i = 2:1:size(obj.tempNeighborhood, 2)
                %landscapeMemoryMatrix = [landscapeMemoryMatrix; obj.tempNeighborhoodObj(i).landscape_memory];
                landscapeMemoryMatrix = [landscapeMemoryMatrix; obj.tempNeighborhoodObj(i).movement_memory];
            end
            
            landscapeMemoryMatrix = unique(landscapeMemoryMatrix,'rows');
        end
    end
end
