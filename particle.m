classdef particle < handle
    
    properties
        id = 1;
        position; % position vector
        energy; % energy class
        energyval;
        doNotCopy = {'last_positions', 'last_funcvals', 'profitApprPenalty', 'risk', 'movement_memory', 'landscape_memory', 'simCont'};
       
        % PSO parameters
        phi1 = -1; % value
        phi2 = -1; % value
        c1; % value
        c2; % value
        w; % value
        lastVelocity;

        movement_memory;
        landscape_memory;
        use_const_val_for_pso_sim = false;
        personalBest; % position vector
        personalBestFuncval;
        func;
        funcval;
        neighborhood; % neighborhood class
        globalBest;
        globalBestFuncval;
        use_turbulence_factor = true;
        task_id;
        task; 
        state; % state class
        risk; % value
        
        save_approximation_values;
        
        simCont;

        logger;
    end
    
    methods
        function obj = particle(task_id, risk_lvl, initStruct, id)
            if nargin > 0

                if nargin == 4
                    obj.id = id;
                end
                
                obj.task_id = task_id;
                
                if ~isfield(initStruct, 'initPosition') || isempty(initStruct.initPosition)
                    obj.initPosition('area'); % rand or area
                else
                    obj.initPosition(initStruct.initPosition); % rand or area
                end
                
                obj.personalBest = obj.position;
                obj.energy = energy();
                obj.simCont = simulateContainer();
                
                if ~isfield(initStruct, 'c1') || isempty(initStruct.c1)
                    obj.c1 = 1.0; 
                else
                    obj.c1 = initStruct.c1;
                end
                
                if ~isfield(initStruct, 'c2') || isempty(initStruct.c2)
                    obj.c2 = 1.0; 
                else
                    obj.c2 = initStruct.c2; 
                end
                
                if ~isfield(initStruct, 'w') || isempty(initStruct.w)
                    obj.w = 0.5; 
                else
                    obj.w = initStruct.w; 
                end

                obj.phi1 = getRandom(0, 1);
                obj.phi2 = getRandom(0, 1);
                
                if ~isfield(initStruct, 'velocity_t0') || isempty(initStruct.velocity_t0)
                    obj.lastVelocity = 0.0; 
                else
                    obj.lastVelocity = initStruct.velocity_t0 * ones(1, obj.func.dimensions);
                end

                %obj.lastVelocity = rand(1,2) * getRandom(1, 5);
                %obj.lastVelocity(1,1) = getRandom(5,15);
                %obj.lastVelocity(1,2) = getRandom(5,15);
                obj.state = stateGround(obj.id);
                
                if ~isfield(initStruct, 'const_phi_simulation') || isempty(initStruct.const_phi_simulation)
                    obj.use_const_val_for_pso_sim = false;
                else
                    obj.use_const_val_for_pso_sim = initStruct.const_phi_simulation;
                end
                
                obj.movement_memory = [obj.position obj.funcval];
                obj.landscape_memory = obj.movement_memory;
                obj.save_approximation_values = [0, 0];
                
                 if risk_lvl ~= -1
                     obj.risk = risk_lvl;
                 else
                     obj.risk = getRandom(0, 1);
                 end
            end
        end
        
                
%        function riskVal = get.risk(obj) % energy dependent
%            riskVal = obj.energyval / obj.energy.max;
%        end
        
        function logger = get.logger(~)
            global swarmObj;
            logger = swarmObj.logger;
        end
        
        function obj = initPosition(obj, type)
            
            if nargin < 2
                type = 'area';
            end
            
            %task = obj.task.

            for d = 1:1:obj.func.dimensions
                s1 = d * 2 - 1;
                s2 = d * 2;
           
                if isequal(type, 'rand')
                    obj.position(d) = getRandom( obj.func.space(s1), obj.func.space(s2) );
                elseif isequal(type, 'area')
                    obj.position(d) = getRandom( obj.func.startarea(s1), obj.func.startarea(s2) );
                end
            end 
        end
        
        function funcval = get.funcval(obj)
            global swarmObj;
            
            funcval = swarmObj.tasks(obj.task_id).funcval(obj.position);
        end
        
        function func = get.func(obj)
            global swarmObj;
            
            func = swarmObj.tasks(obj.task_id).task_function;
        end
        
        function value = taskFuncval(obj, task_id)
            global swarmObj;
            
            value = swarmObj.tasks(task_id).funcval(obj.position);
        end
        
        function task = get.task(obj)
            global swarmObj;
            
            task = swarmObj.tasks(obj.task_id);
        end
        
        function energyval = get.energyval(obj)
            energyval = obj.energy.value;
        end
        
        function funcval = get.personalBestFuncval(obj)
            funcval = obj.task.funcval(obj.personalBest);
        end
        
        function pos = get.globalBest(obj)
            pos = obj.neighborhood.globalBestObj.position;
        end
        
        function funcval = get.globalBestFuncval(obj)
            funcval = obj.task.funcval(obj.neighborhood.globalBestObj.position);
        end
        
        function simulateMove(obj)
            
            global swarmObj;

            bestParticle = obj.makeDecision();
            
            swarmObj.getParticleById(bestParticle).simCont.particle = swarmObj.getParticleById(bestParticle);
            
            obj.simCont = swarmObj.getParticleById(bestParticle).simCont;

            swarmObj.deleteSimParticles();
        end
        
        function move(obj)
            
            obj.updateLandscapeMemory();
            
            bestParticle = obj.simCont.particle;
            
            %bestParticle.copyPropertiesInto(obj);
            
            obj.neighborhood = bestParticle.neighborhood;
            
            obj.neighborhood.particle = obj.id;
            
            obj.state.particle = obj.id;
            
            obj.state.move( obj.simCont );

            obj.generateNewPhi();
            
            obj.save_approximation_values(end+1,:) = [obj.simCont.calcFuncval, obj.funcval];
            
            obj.saveMovement();
        end
        
        function generateNewPhi(obj)
            if obj.use_const_val_for_pso_sim == true
                obj.phi1 = getRandom( 0, 1 ); 
                obj.phi2 = getRandom( 0, 1 );
            end
        end

        function bool = performTask(obj)
            bool = true;
            
            % check stimulus
            if obj.energyval <= obj.energy.min_energy_fly
                bool = false;
                return; % return without fly
            end
        end
        
        function obj = findGlobalBest(obj)
            obj.neighborhood.findGlobalBest();
        end
        
        function bestParticle = makeDecision(obj)
            
            global swarmObj;
            
            nh_knn = [];     % neighborhoodKnn
            
            % neighborhoodKnn
            for i = 1:1:obj.neighborhood.nh_size
                nh_knn(i) = obj.copy;
                swarmObj.getParticleById(nh_knn(i)).neighborhood = neighborhoodKnn(nh_knn(i), swarmObj.getParticleById(nh_knn(i)).neighborhood.particlesIdx, i);
              
                swarmObj.getParticleById(nh_knn(i)).state.simulateMove();
            end
            
            % Distance Based Ranking
            Rank = LeaderSelection(LeaderSelection.RT_RS);
            
            Rank.addParticleArray(nh_knn);
            
            Rank.riskval = obj.risk;
            
            bestParticle = Rank.run();
            
%             nh_knn(1) = obj.copy;
%             swarmObj.getParticleById(nh_knn(1)).neighborhood = neighborhoodKnn(nh_knn(1), swarmObj.getParticleById(nh_knn(1)).neighborhood.particlesIdx, obj.neighborhood.nh_size);
%             swarmObj.getParticleById(nh_knn(1)).state.simulateMove();
%             bestParticle = nh_knn(1);
        end
        
        function idx = copy(this)
            global swarmObj;
            
            new = feval(class(this));

            p = properties(this); % for hidden properties: p = fieldnames(struct(this));
            for i = 1:length(p)
                
                if isa(this.(p{i}), 'handle')
                     new.(p{i}) = this.(p{i}).copy;
                else
                    new.(p{i}) = this.(p{i});
                end
            end
            
            idx = swarmObj.addParticle(new); 
            
            swarmObj.particles(idx).neighborhood.particle = idx;
            swarmObj.particles(idx).state.particle = idx;
        end
        
        function copyFromParticle(obj, idx)
            
            global swarmObj;
            
            particle = swarmObj.getParticleById(idx);
            
            obj.neighborhood = particle.neighborhood;
            
            obj.neighborhood.particle = obj.id;
            
            obj.state.simCont = particle.state.simCont;
        end
        
        function copyPropertiesInto(obj, particle)
            
            org_id = particle.id;
            
            p = properties(obj); % for hidden properties: p = fieldnames(struct(this));
            for i = 1:length(p)
                
                if ~isa(obj.(p{i}), 'handle') && ~ismember(p{i}, obj.doNotCopy)
                    particle.(p{i}) = obj.(p{i});
                end
            end
            particle.id = org_id;
        end
        
        function bool = isAtGroundState(obj)
            bool = isa(obj.state, 'stateGround');
        end
        
        function bool = isAtAirState(obj)
            bool = isa(obj.state, 'stateAir');
        end
        
        function saveMovement(obj)
        	obj.movement_memory(end+1, :) = [obj.position obj.funcval];
        end
        
        function updateLandscapeMemory(obj)
            %tic
            subindex = @(A,r,c) A(r,c);   
            dist = @(point, pointlist) subindex(pdist([point; pointlist]), 1, 1:size(pointlist,1)-1);
            
            newLandscapePoints = [[obj.position obj.funcval]; obj.neighborhood.getParticleLandscapeMemory()];
            
            for i = 1:1:size(newLandscapePoints,1)
                if sum(dist(newLandscapePoints(i,1:2), obj.landscape_memory(:,1:2)) < 0.10) == 0
                    obj.landscape_memory = [obj.landscape_memory; newLandscapePoints(i,:)];
                end
            end
            
            %newLandscapeMemoryMatrix = [obj.landscape_memory; obj.movement_memory; obj.neighborhood.getParticleLandscapeMemory()];

            obj.landscape_memory = unique(obj.landscape_memory,'rows');
            %toc
        end
        
        function setSaveSimulate(obj, state, action, movecost, velocity, profit, calcFuncval, risk, distanceToGlobalBest)
            obj.simCont.setProperties(state, action, movecost, velocity, profit, calcFuncval, risk, distanceToGlobalBest);
        end
        
        function distance = getDistanceToGlobalBest(obj)
            distance = norm(obj.position - obj.neighborhood.globalBestObj.position);
        end
    end 
end

