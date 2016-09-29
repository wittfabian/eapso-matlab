classdef stateAir < state
    
    properties
        name
        action % hover, fly, land
    end
    
    methods
        function obj = stateAir(particle)
            obj@state(particle);
            
            obj.name = obj.STATE_AIR;
            obj.action = obj.ACTION_HOVER;
        end
        
        function name = get.name(obj)
            name = [obj.name ' (' obj.action ')'];
        end
        
        function obj = move(obj, simCont)
            
            if ~isa(simCont, 'simulateContainer')
                error('No simCont!!');
            end
            
            if strcmp(simCont.getState, obj.STATE_GROUND) % change to ground state
                
                if strcmp(simCont.getAction, obj.ACTION_LAND)
                    %obj.logger.info('stateAir/move', sprintf('p%i do: land', obj.particleIdx));
                    %fprintf('%i: land\n', obj.particleIdx);
                    obj.land();
                    return;
                end
                
            elseif strcmp(simCont.getState, obj.STATE_AIR) % stay in fly state
                
                if strcmp(simCont.getAction, obj.ACTION_FLY)
                    %obj.logger.info('stateAir/move', sprintf('p%i: fly | v = [%s]', obj.particleIdx, sprintf('%d; ', simCont.getVelocity)));
                    %fprintf('%i: fly | v = [%s]\n', obj.particleIdx, sprintf('%d; ', simCont.getVelocity));
                    
                    obj.fly(simCont);
                    return;
                elseif strcmp(simCont.getAction, obj.ACTION_HOVER)
                    %obj.logger.info('stateAir/move', sprintf('p%i do: hover', obj.particleIdx));
                    %fprintf('%i: hover\n', obj.particleIdx);
                    obj.hover();
                    return;
                end
            end
            
            error(['p' num2str(obj.particleIdx) ': does nothing at sate air']);
        end
        
        function ret = simulateMove(obj)
            
            %ret = obj.particleObj.simCont;
            
            % simulate land
            if obj.particleObj.energyval < obj.particleObj.energy.min_energy_fly
                obj.calculateLandingCost();
                ret = obj.particleObj.simCont;
                return;
            end
            
            % simulate fly
            if obj.simulateFly() == true
                ret = obj.particleObj.simCont;
                return;
            end
            
            % else simulate hover
            obj.calculateHoveringCost();
            ret = obj.particleObj.simCont;
        end
        
        function obj = land(obj)
            obj.action = obj.ACTION_LAND;
            obj.particleObj.energy.doAction(energy.ACTION_LAND);
            obj.particleObj.state = stateGround(obj.particle);
        end
        
        function [old_energy_value, energy_change, new_energy_value] = calculateLandingCost(obj)
            
            [old_energy_value, energy_change, new_energy_value] = obj.particleObj.energy.calculateByAction(energy.ACTION_LAND);

            obj.particleObj.setSaveSimulate(obj.STATE_GROUND, obj.ACTION_LAND, energy_change, [0 0], 0, 0, obj.particleObj.risk, 0);
        end
        
        function obj = hover(obj)
            obj.action = obj.ACTION_HOVER;
            obj.particleObj.energy.doAction(energy.ACTION_HOVER);
        end
        
        function [old_energy_value, energy_change, new_energy_value] = calculateHoveringCost(obj)
            
            [old_energy_value, energy_change, new_energy_value] = obj.particleObj.energy.calculateByAction(energy.ACTION_HOVER);

            obj.particleObj.setSaveSimulate(obj.STATE_AIR, obj.ACTION_HOVER, energy_change, [0 0], 0, 0, obj.particleObj.risk, 0);
        end

        function ret = simulateFly(obj)
            
            ret = false;

            if obj.particleObj.use_const_val_for_pso_sim == false
                obj.particleObj.phi1 = getRandom( 0, 1 ); 
                obj.particleObj.phi2 = getRandom( 0, 1 );
            end

            % components of velecity
            momentum_comp  = obj.particleObj.w * obj.particleObj.lastVelocity;
            cognitive_comp = obj.particleObj.phi1 * obj.particleObj.c1 * (obj.particleObj.personalBest - obj.particleObj.position);
            social_comp    = obj.particleObj.phi2 * obj.particleObj.c2 * (obj.particleObj.globalBest - obj.particleObj.position);

            newVelocity = momentum_comp + cognitive_comp + social_comp;

            %logtxt = sprintf('p%i sim: phi1=%f, phi2=%f, momentum_comp[%s], cognitive_comp=[%s], social_comp=[%s], position=[%s], personalBest=[%s], getGlobalBest=[%s]', obj.particleIdx, obj.particleObj.phi1, obj.particleObj.phi2, sprintf('%d;', momentum_comp), sprintf('%d;', cognitive_comp), sprintf('%d;', social_comp), sprintf('%d;', obj.particleObj.position), sprintf('%d;', obj.particleObj.personalBest), sprintf('%d;', obj.particleObj.globalBest));
            %obj.logger.info('stateAir/simulateFly', logtxt);
            
            if obj.particleObj.use_turbulence_factor == true
                newVelocity = obj.getTurbulence(newVelocity);
            end

            % shortening the fly if distance > max_distance
            move_distance = obj.calculateFlyDistance(newVelocity);

            if move_distance > obj.particleObj.energy.max_distance

                %obj.logger.info('stateAir/simulateFly', sprintf('velocity=[%s] with distance=%f exceeds max_distance=%f', sprintf('%d;', newVelocity), move_distance, obj.particleObj.energy.max_distance));

                scaleFactor = obj.particleObj.energy.max_distance / move_distance;    

                newVelocity = newVelocity * scaleFactor;

                %obj.logger.info('stateAir/simulateFly', sprintf('new velocity=[%s] with scaleFactor=%f', sprintf('%d;', newVelocity), scaleFactor));
            end

            % fly cost or energy decrease
            [~, energy_change, new_energy_value] = obj.calculateFlyCost(newVelocity);

            % if new energy is == 0, shortening the fly
            if new_energy_value <= obj.particleObj.energy.min_energy_fly

                %obj.logger.info('stateAir/simulateFly', sprintf('calculated fly not possible. energy decrease to big'));

                usableEnergy = obj.particleObj.energyval - obj.particleObj.energy.min_energy_fly;

                %obj.logger.info('stateAir/simulateFly', sprintf('velocity=[%s], usableEnergy=%f', sprintf('%d;', newVelocity), usableEnergy));

                % if usableEnergy <= 0.0 then do not fly
                if usableEnergy <= 0.0
                    %obj.logger.info('stateAir/simulateFly', 'usable energy to low: no fly');
                    return; % return without fly
                end 

                scaleFactor = usableEnergy / energy_change; 

                newVelocity = newVelocity * scaleFactor;

                % fly cost or energy decrease
                [~, energy_change, ~] = obj.calculateFlyCost(newVelocity);

                %obj.logger.info('stateAir/simulateFly', sprintf('NEW ROUTE: velocity=[%s], scaleFactor=%f', sprintf('%d;', newVelocity), scaleFactor));
            end

            % profit old function value minus new function value (after move)
            %calcFuncval = obj.particleObj.func.f(obj.particleObj.position + newVelocity);
            %obj.logger.info('stateAir/simulateFly', sprintf('calcFuncval=%f (real function value)', obj.particleObj.func.f(obj.particleObj.position + newVelocity)));
            [~, profit, approx_funcval] = obj.calculateProfit(newVelocity);

            obj.particleObj.setSaveSimulate(obj.STATE_AIR, obj.ACTION_FLY, energy_change, newVelocity, profit, approx_funcval, obj.particleObj.risk, obj.particleObj.getDistanceToGlobalBest());

            %logtxt = sprintf('p%i sim: state=%s, action=%s, energy_change=%f, newVelocity=[%s], profit=%f\n', obj.particleIdx, obj.STATE_AIR, obj.ACTION_FLY, energy_change, sprintf('%d;', newVelocity), profit);
            %obj.logger.info('stateAir/simulateFly', logtxt);

            ret = true;
        end
        
        function obj = fly(obj, simCont)
            
            %obj.logger.info('stateAir/fly', sprintf('p%i action=%s, movecost=%f', obj.particleIdx, simCont.getAction, simCont.getMovecost));
            
            if strcmp(simCont.getAction, obj.ACTION_HOVER)
                obj.action = obj.ACTION_HOVER;
                obj.particleObj.energy.doAction(energy.ACTION_HOVER);
                return;
            end
            
            % else if fly

            obj.action = obj.ACTION_FLY;
            
            % set new position with saved velocity
            %obj.logger.info('stateAir/fly', sprintf('p%i old position=[%s]; old funcval=%f', obj.particleIdx, sprintf('%f;', obj.particleObj.position), obj.particleObj.funcval));
            obj.particleObj.position = obj.particleObj.position + simCont.getVelocity;
            %obj.logger.info('stateAir/fly', sprintf('p%i new position=[%s]; new funcval=%f', obj.particleIdx, sprintf('%f;', obj.particleObj.position), obj.particleObj.funcval));
            
            % set saved velocity as lastVelocity
            obj.particleObj.lastVelocity = simCont.getVelocity; 

            % update personal best
            if obj.particleObj.funcval <= obj.particleObj.personalBestFuncval
                obj.particleObj.personalBest = obj.particleObj.position;
                %obj.logger.info('stateAir/fly', sprintf('p%i update personalBest to actual position', obj.particleIdx));
            end

            % set new energy level
            distance = obj.calculateFlyDistance(simCont.getVelocity);
            obj.particleObj.energy.doAction(energy.ACTION_FLY, distance);
        end
        
        function [old_energy_value, energy_change, new_energy_value] = calculateFlyCost(obj, movement)
 
             distance = obj.calculateFlyDistance(movement);
             
             [old_energy_value, energy_change, new_energy_value] = obj.particleObj.energy.calculateByAction(energy.ACTION_FLY, distance);
        end
        
        function distance = calculateFlyDistance(~, movement)
            distance = norm(movement); % Euclidean norm: (sqrt(movement(1)^2 + movement(2)^2))
        end
        
        function [old_funcval, profit, approx_funcval] = calculateProfit(obj, velocity)
            
            old_funcval = obj.particleObj.funcval;
            
            aktParticleNewPosition = obj.particleObj.position + velocity;
            
            [idx, ~] = knnsearch(obj.particleObj.landscape_memory(:,1:2), obj.particleObj.position, 'k', 20, 'distance', 'euclidean');
            
            landscape_map = obj.particleObj.landscape_memory(idx,:);

            approx_funcval = obj.bestFitQuadraticCurve(landscape_map, aktParticleNewPosition);
            
            profit = obj.particleObj.funcval - approx_funcval;
            %obj.logger.info('stateAir/calculateProfit', sprintf('old_funcval=%f, profit=%f; approx_funcval=%f;', old_funcval, profit, approx_funcval));
        end
        
        function funcval = bestFitQuadraticCurve(~, matrix, point)
            %C = [ones(size(matrix, 1),1) matrix(:,1:2) prod(matrix(:,1:2),2) matrix(:,1:2).^2] \ matrix(:,3);
            % mldivide, \ 
            % Solve systems of linear equations Ax = B for x
            
            % D = x2fx(x, 'quadratic')
            % Let x1 be the first column of x and x2 be the second.
            % Then the first column of D is the constant term, 
            % the second column is x1, the third column is x2, 
            % the fourth column is x1*x2, 
            % the fifth column is x1^2, and the last columns is x2^2.
            C = x2fx(matrix(:,1:2), 'quadratic') \ matrix(:,3);

            % zz = [ones(numel(xx),1) xx(:) yy(:) xx(:).*yy(:) xx(:).^2 yy(:).^2] * C;
            %funcval = [ones(size(point, 1),1) point(:,1) point(:,2) point(:,1).*point(:,2) point(:,1).^2 point(:,2).^2] * C;
            funcval = x2fx([point(:,1)  point(:,2)], 'quadratic') * C;
        end
    end
end