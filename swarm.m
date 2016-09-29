classdef swarm < handle
    
    properties (Constant)
        default_iterations = 100;
        colorMap = {
            '000000', 'FFFF00', '1CE6FF', 'FF34FF', 'FF4A46', '008941', '006FA6', 'A30059', ...
            'FFDBE5', '7A4900', '0000A6', '63FFAC', 'B79762', '004D43', '8FB0FF', '997D87', ...
            '5A0007', '809693', 'FEFFE6', '1B4400', '4FC601', '3B5DFF', '4A3B53', 'FF2F80', ...
            '61615A', 'BA0900', '6B7900', '00C2A0', 'FFAA92', 'FF90C9', 'B903AA', 'D16100', ...
            'DDEFFF', '000035', '7B4F4B', 'A1C299', '300018', '0AA6D8', '013349', '00846F', ...
            '372101', 'FFB500', 'C2FFED', 'A079BF', 'CC0744', 'C0B9B2', 'C2FF99', '001E09', ...
            '00489C', '6F0062', '0CBD66', 'EEC3FF', '456D75', 'B77B68', '7A87A1', '788D66', ...
            '885578', 'FAD09F', 'FF8A9A', 'D157A0', 'BEC459', '456648', '0086ED', '886F4C', ...
            '34362D', 'B4A8BD', '00A6AA', '452C2C', '636375', 'A3C8C9', 'FF913F', '938A81', ...
            '575329', '00FECF', 'B05B6F', '8CD0FF', '3B9700', '04F757', 'C8A1A1', '1E6E00', ...
            '7900D7', 'A77500', '6367A9', 'A05837', '6B002C', '772600', 'D790FF', '9B9700', ...
            '549E79', 'FFF69F', '201625', '72418F', 'BC23FF', '99ADC0', '3A2465', '922329', ...
            '5B4534', 'FDE8DC', '404E55', '0089A3', 'CB7E98', 'A4E804', '324E72', '6A3A4C', ...
            '83AB58', '001C1E', 'D1F7CE', '004B28', 'C8D0F6', 'A3A489', '806C66', '222800', ...
            'BF5650', 'E83000', '66796D', 'DA007C', 'FF1A59', '8ADBB4', '1E0200', '5B4E51', ...
            'C895C5', '320033', 'FF6832', '66E1D3', 'CFCDAC', 'D0AC94', '7ED379', '012C58'
        };
    end
    
    properties
        max_iterations;
        used_itertions = 0;
        funcVal_threshold;
        
        particles = particle;
        swarmQuantity;
        tasks;
        risk_lvls;
        
        swarm_size;
        
        save_energy_lvls = [];
        save_func_values = [];
        save_abs_global_best = [];
        save_particle_global_best = [];
        save_neighborhood_info = [];
        save_risk_lvls = [];
        
        
        logger = log4m.getLogger( 'logfile.txt' );
        
        initStruct;
    end
    
    methods
        function obj = swarm(initStruct)
        %function obj = swarm(swarmQuantity, tasks, risk_lvls)
            
            if ~isfield(initStruct, 'popSize') || isempty(initStruct.popSize)
                obj.swarmQuantity = 10;
            else
                obj.swarmQuantity = initStruct.popSize;
            end
            
            if ~isfield(initStruct, 'task') || isempty(initStruct.task)
                obj.tasks = task(1, optFunc('sphere'));  
            else
                obj.tasks = initStruct.task;
            end
            
            if ~isfield(initStruct, 'riskValues') || isempty(initStruct.riskValues)
                obj.risk_lvls = [];  
            else
                obj.risk_lvls = initStruct.riskValues;
            end
            
            if ~isfield(initStruct, 'max_iterations') || isempty(initStruct.max_iterations)
                obj.max_iterations = obj.default_iterations;  
            else
                obj.max_iterations = initStruct.max_iterations;
            end
            
            if ~isfield(initStruct, 'funcVal_threshold') || isempty(initStruct.funcVal_threshold)
                obj.funcVal_threshold = 0;  
            else
                obj.funcVal_threshold = initStruct.funcVal_threshold;
            end
            
            obj.logger.setCommandWindowLevel(obj.logger.OFF);
            obj.logger.setLogLevel(obj.logger.ALL);
            
            obj.initStruct = initStruct;
        end
        
        function setLogger(obj, bool)
           
            if bool == true
                obj.logger.setCommandWindowLevel(obj.logger.OFF);
                obj.logger.setLogLevel(obj.logger.ALL);
            else
                obj.logger.setCommandWindowLevel(obj.logger.OFF);
                obj.logger.setLogLevel(obj.logger.OFF);
            end
        end
        
        function obj = initParticles(obj)

            % init particles
            for idx = 1:1:obj.swarmQuantity
                
                if isempty(obj.risk_lvls)
                    risk_lvl = -1;
                else
                    risk_lvl = obj.risk_lvls(idx);
                end
                
                % particle(func, task, risk_lvl, const_simulation, id)
                obj.particles(idx) = particle(obj.tasks(1).id, risk_lvl, obj.initStruct, idx);
            end
            
            idxArray = obj.getParticleIdxArray();
            
            % announce particles
            for p = 1:1:size(obj.particles, 2)
                obj.particles(p).neighborhood = neighborhoodDefault(p, idxArray);
            end
        end
        
        function swarm_size = get.swarm_size(obj)
            swarm_size = size(obj.particles, 2);
        end
        
        function idx = addParticle(obj, particle)
            idx = obj.swarm_size + 1;
            
            obj.particles(idx) = particle;
            
            obj.particles(idx).id = idx;
        end
        
        function array = getParticleIdxArray(obj)
            
            array = zeros(1, size(obj.particles, 2));
            
            for p = 1:1:size(obj.particles, 2)
                array(p) = obj.particles(p).id;
            end
            
            if sum(array) ~= sum(1:obj.swarmQuantity)
                error('swarm/getParticleIdxArray: Index of particle array error');
            end
        end
        
        function pos = getPositions(obj)
            for p = 1:1:size(obj.particles, 2)
                pos(p,:) = obj.particles(p).position;
            end
        end
        
        function funcval = getFunctionValues(obj)
            for p = 1:1:size(obj.particles, 2)
                funcval(p,:) = obj.particles(p).funcval;
            end
        end
        
        function funcval = getFunctionValueByParticleId(obj, idx)
            funcval = obj.particles(idx).funcval;
        end
        
        function pos = getPositionsByParticleId(obj, idx)
        	pos = obj.particles(idx).position;
        end
        
        function energy = getEnergyValueByParticleId(obj, idx)
            energy = obj.particles(idx).energyval;
        end
        
        function particle = getParticleById(obj, idx)
            particle = obj.particles(idx);
        end
        
        function obj = findGlobalBest(obj)
            for p = 1:1:obj.swarmQuantity
                obj.particles(p).findGlobalBest();
            end
        end
        
        function obj = move(obj)
            for p = 1:1:obj.swarmQuantity
                obj.particles(p).simulateMove();
                obj.deleteSimParticles();
            end
            
            for p = 1:1:obj.swarmQuantity
                obj.particles(p).move();
            end
            
            obj.findGlobalBest();
            %obj.savePosAndFuncVal();
        end
        
        function obj = optimize(obj, iterations)
            
            if nargin < 2
                iterations = obj.max_iterations;
            end
            
            obj.deleteSimParticles();
            
            obj.save_energy_lvls(1, :) = obj.getEnergyLvls();
            obj.save_func_values(1, :) = obj.getFuncValues();
            obj.save_abs_global_best(1, 1) = obj.getAbsGlobalBest();
            obj.save_particle_global_best(1, :) = obj.getParticleGlobalBest();
            obj.save_neighborhood_info(1,:) = obj.getNeighborhoodInfo();
            obj.save_risk_lvls(1,:) = obj.getRiskInfo();

            %obj.printInfo();
            for i = 1:1:iterations
                %obj.logger.info('swarm/move', sprintf('################ iteration %i ##############', i));
                obj.move();
                %obj.printInfo();
                %obj.plotOverview(i); 
                %obj.plotParticleSpace();
                %pause(0.01);
                %obj.printPositions(); pause
                obj.save_energy_lvls(i+1, :) = obj.getEnergyLvls();
                obj.save_func_values(i+1, :) = obj.getFuncValues();
                obj.save_abs_global_best(i+1, 1) = obj.getAbsGlobalBest();
                obj.save_particle_global_best(i+1, :) = obj.getParticleGlobalBest();
                obj.save_neighborhood_info(i+1,:) = obj.getNeighborhoodInfo();
                obj.save_risk_lvls(i+1,:) = obj.getRiskInfo();
                
                %if min(obj.save_func_values(i,:)) <= obj.funcVal_threshold
                %    break;
                %end
                
                if mod(i, 100) == 0
                    fprintf('%i ... ', i);
                end
            end
            fprintf('\n');
            obj.used_itertions = i;
            
            %obj.printFuncValues();
        end
        
        function printFuncValues(obj)
            %fprintf('globalBest:  %f\n', obj.func.f(obj.globalBest.position));
            for p = 1:1:size(obj.particles, 2)
                fprintf('particle %2i: %f\n', p, obj.func.f(obj.particles(p).position));
            end
            fprintf('######################\n');
        end
        
        function printPositions(obj)
            fprintf('globalBest:  %f / %f\n', obj.globalBest.position(1), obj.globalBest.position(2));
            for p = 1:1:size(obj.particles, 2)
                fprintf('particle %2i: %f / %f\n', p, obj.particles(p).position(1), obj.particles(p).position(2));
            end
            fprintf('##################################\n');
        end
        
        function printStates(obj)
            for p = 1:1:size(obj.particles, 2)
                fprintf('particle %2i: %s\n', p, obj.particles(p).state.name);
            end
            fprintf('##################################\n');
        end
        
        function printInfo(obj)
            fprintf('%8s | %15s | %6s | %6s\n', 'particle', 'state', 'energy', 'func value');
            
            for p = 1:1:size(obj.particles, 2)
                fprintf('%8i | %15s | %3.3f | %3.3f\n', p, obj.particles(p).state.name, obj.particles(p).energy.value, obj.particles(p).funcval);
            end
            fprintf('#####################################\n');
        end
        
        function plotOverview(obj, step)
            
            if nargin < 2
                step = 0;
            end
     
            figure(1); clf; hold on
            
            energyLvl = zeros(1, size(obj.particles, 2));

            % ############## plot particle positions #####################
            for p = 1:1:size(obj.particles, 2)
                plot(obj.particles(p).position(1), obj.particles(p).position(2), 'or', 'MarkerSize', 5, 'MarkerEdgeColor', hex2rgb(obj.colorMap{p}), 'MarkerFaceColor', hex2rgb(obj.colorMap{p}));
                energyLvl(p) = (obj.particles(p).energy.value / 20) * 100;
            end
            
            title(['Iteration: ' num2str(step)]);
            axis(obj.tasks(1).func.space);
            xlabel('x1'); ylabel('x2');

            hold off
            

            figure(2); clf; hold on
            % ############## plot energy per particle #####################

            %subplot(1,2,2), 
            for i = 1:1:size(obj.particles,2)
                h = bar(i,energyLvl(i));
                set(h,'FaceColor', hex2rgb(obj.colorMap{i}));
            end
            
            axis([1 size(obj.particles,2) 0 100]);
            xlabel('particles'); ylabel('energy in percent'); 

            hold off
        end
        
        function plotParticleSpace(obj)
            
            figure(2);
            
            obj.tasks(1).func.plot;
            hold on
            
            for p = 1:1:size(obj.particles, 2)
                scatter3(obj.particles(p).position(1), obj.particles(p).position(2), obj.particles(p).funcval, 'filled');
                %axis(obj.func.space);
                hold on
            end
            
            % view(az, el);
            %view(-105, 55);
            
            hold off
        end
        
        function deleteSimParticles(obj)
            
            startLoop = obj.swarm_size;
            endLoop = obj.swarmQuantity+1;
            
            for p = startLoop:-1:endLoop
                obj.particles(p) = [];
            end
        end
        
        function vector = getEnergyLvls(obj)
            
            vector = ones(1, obj.swarm_size);
            
            for p = obj.particles
                vector(1, p.id) = p.energyval;
            end
        end
        
        function vector = getFuncValues(obj)
            
            vector = ones(1, obj.swarm_size);
            
            for p = obj.particles
                vector(1, p.id) = p.funcval;
            end
        end
        
%         function savePosAndFuncVal(obj)
%             for p = obj.particles
%                 p.saveMovement();
%             end
%         end
        
        function saveSimulation(obj, fname)
            
            if nargin < 2
                fname = string2hash(['swarmPSOsimulation_' datestr(datetime('now'))]);
            end
            
            fileID = fname;
            
            %fname = ['experiment_results/' fname '__' datestr(datetime('now')) '.mat'];
            fname = ['experiment_results/' fname '.mat'];
            
            var_swarm = obj;
            
            save(fname, 'var_swarm', 'fileID');
            
            var_save_energy_lvls = obj.save_energy_lvls;
            var_save_func_values = obj.save_func_values;
            var_particles = obj.particles;
            
            save(fname, 'var_save_energy_lvls', '-append');
            save(fname, 'var_save_func_values', '-append');
            save(fname, 'var_particles', '-append');
            
            movementMemoryMatrix = [];
            
            for p = obj.particles
                movementMemoryMatrix(:,:,p.id) = p.movement_memory;
            end
            
            save(fname, 'movementMemoryMatrix', '-append');
        end
        
        function plotFunctionCurve(obj, type)
            
            figure;
            
            if nargin < 2
                type = 'mean';
            end
            
            xVal = [1:1:size(obj.save_func_values, 1)]';
            
            values = log(obj.save_func_values);
            %values = obj.save_func_values;
            
            switch type
                case 'mean'
                    yVal = mean(values, 2);
                    plot(xVal, yVal);
                    legend('mean');
                case 'min'
                    yVal = min(values, [], 2);
                    plot(xVal, yVal);
                    legend('min');
                case 'max'
                    yVal = max(values, [], 2);
                    plot(xVal, yVal);
                    legend('max');
                case 'all'
                    yValMean = mean(values, 2);
                    yValMax = max(values, [], 2);
                    yValMin = min(values, [], 2);
                    plot(xVal, yValMean, xVal, yValMax, xVal, yValMin);
                    legend('mean', 'max', 'min');
                otherwise 
                    yVal = mean(values, 2);
                    plot(xVal, yVal);
                    legend('mean');
            end
            
            title('function curve');
            xlabel iterations;
            ylabel('function value');
        end
        
        function plotEnergyCurve(obj, type)
            
             figure;
            
            if nargin < 2
                type = 'mean';
            end
            
            xVal = [1:1:size(obj.save_energy_lvls, 1)]';
            
            switch type
                case 'mean'
                    yVal = mean(obj.save_energy_lvls, 2);
                    plot(xVal, yVal);
                    legend('mean');
                case 'min'
                    yVal = min(obj.save_energy_lvls, [], 2);
                    plot(xVal, yVal);
                    legend('min');
                case 'max'
                    yVal = max(obj.save_energy_lvls, [], 2);
                    plot(xVal, yVal);
                    legend('max');
                case 'all'
                    yValMean = mean(obj.save_energy_lvls, 2);
                    yValMax = max(obj.save_energy_lvls, [], 2);
                    yValMin = min(obj.save_energy_lvls, [], 2);
                    plot(xVal, yValMean, xVal, yValMax, xVal, yValMin);
                    legend('mean', 'max', 'min');
                otherwise 
                    yVal = mean(obj.save_energy_lvls, 2);
                    plot(xVal, yVal);
                    legend('mean');
            end

            title('energy curve');
            xlabel iterations;
            ylabel('energy value');
        end
        
        function [globalBestId, globalBestFuncVal] = getAbsGlobalBest(obj)
            
            globalBestId = obj.particles(1).id;
            globalBestFuncVal = obj.particles(1).funcval;
            
            for p = 2:1:obj.swarmQuantity
                if obj.particles(p).funcval < globalBestFuncVal
                    globalBestId = obj.particles(p).id;
                    globalBestFuncVal = obj.particles(p).funcval;
                end
            end
        end
        
        function globalBestVector = getParticleGlobalBest(obj) 
            
            globalBestVector = [];
            
            for p = 1:1:obj.swarmQuantity
                globalBestVector = [globalBestVector, obj.particles(p).neighborhood.globalBest];
            end
        end
        
        function neighborhoodInfo = getNeighborhoodInfo(obj)
            
            neighborhoodInfo = [];
            
            for p = 1:1:obj.swarmQuantity
                neighborhoodInfo = [neighborhoodInfo, obj.particles(p).neighborhood.countParticleInNeighborhood()];
            end
        end
        
        function riskInfo = getRiskInfo(obj)
            
            riskInfo = [];
            
            for p = 1:1:obj.swarmQuantity
                riskInfo = [riskInfo, obj.particles(p).risk];
            end
        end
    end
end

