clear all; %clc;


% functionList = {'sphere', 'rosen', 'ackley'};
% popSizeList = [5, 10, 20, 30];
% initPositionList = {'area'}; %{'area', 'rand'};
% inertiaWeightList = [0.3, 0.4, 0.5];
% startVelocityList = [0.0];
% riskValuesList = [0.0, 0.5, 1.0, Inf];
% iterationList = [100];

% functionList = {'rosen', 'ackley'};
% popSizeList = [5, 10, 20, 30];
% initPositionList = {'area', 'rand'}; %{'area', 'rand'};
% inertiaWeightList = [0.3, 0.4, 0.5];
% startVelocityList = [0.0];
% riskValuesList = [0.0, 0.5, 1.0, Inf];
% iterationList = [100];

functionList = {'sphere', 'rosen', 'ackley'};
popSizeList = [30];
initPositionList = {'area'};
inertiaWeightList = [0.5];
startVelocityList = [0.0];
riskValuesList = {'0.0', '0.5', '1.0', 'random'}; 
iterationList = [500];

funcValThreshold = 0.001;

for z = 1:1:30
    fprintf('loop = %i\n', z);
    for f = functionList

        for pS = popSizeList

            for iP = initPositionList

                for iW = inertiaWeightList

                    for sV = startVelocityList

                        for rV = riskValuesList
                            fprintf('risk = %s\n', char(rV));
                            for iter = iterationList

                                %clear classes; clear all; %clc;
                                clearvars swarmObj s;

                                global swarmObj;

                                s = struct('function', [], ...
                                           'popSize', [], ...
                                           'riskValues', [], ...
                                           'riskType', [], ...
                                           'task', [], ...
                                           'max_iterations', [], ...
                                           'funcVal_threshold', [], ...
                                           'w', [], ...
                                           'c1', [], ...
                                           'c2', [], ...
                                           'const_phi_simulation', [], ...
                                           'initPosition', [], ...
                                           'velocity_t0', [], ...
                                           'id', [] ...
                                );

                                s.function = char(f);
                                s.popSize = pS; 

                                s.riskType = rV;
                                if ~isnan(str2double(rV))
                                    s.riskValues = str2double(rV) * ones(1, s.popSize); 
                                else
                                    s.riskValues = [];
                                end
                                s.task = task(1, optFunc(s.function));  
                                s.max_iterations = iter; s.funcVal_threshold = funcValThreshold;
                                s.w = iW; s.c1 = 1.0; s.c2 = 1.0; s.const_phi_simulation = true;
                                s.initPosition = char(iP); s.velocity_t0 = sV;
                                s.id = string2hash([ datestr(datestr(clock, 0)) num2str(rand(1,1)) ]);

                                swarmObj = swarm(s); 

                                swarmObj.initParticles();

                                swarmObj.setLogger(false);

                                swarmObj.optimize();

                                swarmObj.saveSimulation(s.id);
                            end
                        end
                    end
                end
            end
        end
    end
end

clearvars



