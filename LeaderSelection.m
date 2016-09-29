classdef LeaderSelection < Ranking
    
    properties
        AR = []; % rank vector
        riskRank = []; % risk-rank vector
        nonDomIdxAR = [];
        
        nonDomDimension = [];
    end
    
    methods
        function obj = LeaderSelection(type)
            obj@Ranking(type);

            %obj.logger.info('LeaderSelection', '############### start LeaderSelection #######################');
        end
        
        function retMatrix = normalizeDimensions(~, matrix)
            
            % move cost is always in [0, 1];
            for k = 1:1:size(matrix, 2)
                
                if min(matrix(:, k)) == max(matrix(:, k))
                    retMatrix(:, k) = matrix(:, k);
                    continue;
                end
                
                retMatrix(:, k) = (matrix(:, k) - min(matrix(:, k))) / (max(matrix(:, k)) - min(matrix(:, k)));
            end
        end
        
        function particle = run(obj)
            
            if isempty(obj.dimensions)
                obj.createDimensions();
            end
            
            %obj.calculateRanks();
            
            if sum( range( obj.dimensions ) ) == 0
                
                obj.bestIdx = round(getRandom(1, size(obj.dimensions, 1)));
                
                %obj.logger.info('LeaderSelection/run', sprintf('pick (random): p%i', obj.bestIdx));

            elseif strcmp(obj.type, obj.RT_STD)
                
                %obj.logger.info('LeaderSelection/run', 'standard ranking');
                
                obj.standardRanking();
              
            elseif strcmp(obj.type, obj.RT_RS)
                
                %obj.logger.info('LeaderSelection/run', ['risk ranking with risk = ' num2str(obj.riskval)]);
                
                %obj.standardRanking();
                obj.riskSelectionRanking();
                
            else
                error(['Ranking type not known: '  obj.type]);
            end
            
            if size(obj.particles, 2) > 0
                particle = obj.particles(obj.bestIdx);
            end
        end
        
        function calculateRanks(obj)
            
            N = size(obj.dimensions, 1); % N = number of solutions
            nbrDim = size(obj.dimensions, 2); % nbrDim = number of dimensions
            
            obj.AR = ones(N, 1);
            
            for i = 1:1:N
                for j = 1:1:N

                    if i == j
                        continue;
                    end

                    % j is dominated by i
                    j_is_dominated = true;

                    for k = 1:1:nbrDim
                        if obj.dimensions(i, k) >= obj.dimensions(j, k)
                            j_is_dominated = false;          
                        end
                    end

                    if j_is_dominated == true
                        %fprintf('%i is dominated by %i\n', j, i);
                        obj.AR(j) = obj.AR(j) + 1;
                    end
                end
            end
        end
        
        function calculateRiskRank(obj)
            
            obj.riskRank = zeros(size(obj.dimensions, 1), 1);
            
            normDimensions = obj.normalizeDimensions(obj.dimensions);

            for i = 1:1:size(normDimensions, 1)   
                % rank = risk * profit + (1 - risk) * movecost 
                % => profit is a negativ value
                obj.riskRank( i, 1 ) = obj.riskval * normDimensions(i, 2) + (1 - obj.riskval) * normDimensions(i, 1);

                %obj.logger.info('LeaderSelection/calcualteRiskRank', sprintf('AR(%i)=%f, riskRank(%i)=%f', i, obj.AR(i), i, obj.riskRank(i)));
            end
        end
        
        function standardRanking(obj)
            
            obj.calculateRanks();
            
            if size(obj.AR, 1) == 0
                error('No AR array for standard ranking!');
            end
            
            [valMinAR, idxMinAR] = min(obj.AR);
            
            if sum(obj.AR == valMinAR) == 1 % only one min-element
                
                obj.bestIdx = idxMinAR;
                
            else % more than one min-element
                
                % idx´s of min-values from obj.AR
                obj.nonDomIdxAR = obj.getMinIdx(obj.AR);
                
                obj.bestIdx = obj.nonDomIdxAR( round( getRandom(1, size(obj.nonDomIdxAR, 1)) ), 1 );
            end
            
            %obj.logger.info('LeaderSelection/run', sprintf('pick p%i: dim=[%s], rank=%f', obj.bestIdx, sprintf('%f;', obj.dimensions(obj.bestIdx,:)), obj.AR(obj.bestIdx)));
        end
        
        function riskSelectionRanking(obj)
           
            obj.calculateRiskRank();

            [valMinRiskRank, idxMinRiskRank] = min(obj.riskRank);

            if sum(obj.riskRank == valMinRiskRank) == 1 % only one min-element

                obj.bestIdx = idxMinRiskRank;

            else % more than one min-element

                % idx´s of min-values from obj.riskRank
                minIdxRiskRanks = obj.getMinIdx(obj.riskRank);

                obj.bestIdx = minIdxRiskRanks( round( getRandom(1, size(minIdxRiskRanks, 1)) ), 1);
            end
            
            logtxt = sprintf('pick p%i: dim=[%s], riskRank=%f', obj.bestIdx,  sprintf('%f;', obj.dimensions(obj.bestIdx,:)), obj.riskRank(obj.bestIdx));
            obj.logger.info('LeaderSelection/run', logtxt);
        end
        
        function minIdx = getMinIdx(~, elements, minVal)
            
            if nargin < 3
                [minVal, ~] = min(elements);
            end
            
            minIdx = [];
            nextIdx = 1;
            for i = 1:1:size(elements, 1) % get all non-dominated solutions
                if elements(i, 1) == minVal
                    minIdx(nextIdx, 1) = i;
                    nextIdx = nextIdx + 1;
                end
            end 
        end
        
        function printResult(obj)
            
            if isempty(obj.AR)
                error('Distance Rank is not computed!');
            end
            
            for d = 1:1:size(obj.dimensions, 1)
                fprintf('dimension = [%s] ', sprintf('%f;',obj.dimensions(d,:)));
                fprintf('Rank = %f\n', obj.AR(d));
            end
        end
        
        function plotDimensions2D(obj, d1, d2, newfigure)
            
            if nargin < 4
                newfigure = false;
            end
            
            if nargin < 3
                d2 = 2;
            end
            
            if nargin < 2
                d1 = 1;
            end
            
            if newfigure == true
                figure;
            end
            
            %color = linspace(min(obj.dimensions(:,d1)),max(obj.dimensions(:,d1)),length(obj.dimensions(:,d1)));
            
            scatter(obj.dimensions(:,d1), obj.dimensions(:,d2), 'filled', 'LineWidth', 0.5, 'markerfacecolor', 'b', 'MarkerEdgeColor', 'k');
            hold on;
            
            title(['risk=' num2str(obj.riskval)]);
            xlabel(obj.dimensionDescription{d1}); 
            ylabel(obj.dimensionDescription{d2}); 

            if size(obj.nonDomIdxAR, 1) > 0
                for i = obj.nonDomIdxAR
                     scatter(obj.dimensions(i, d1), obj.dimensions(i, d2), 'markerfacecolor', 'g', 'MarkerEdgeColor', 'k');
                end
            end
            
            if obj.bestIdx > 0
                scatter(obj.dimensions(obj.bestIdx, d1), obj.dimensions(obj.bestIdx, d2), 'markerfacecolor', 'r', 'MarkerEdgeColor', 'r');
            end
            
            hold off;
        end
    
        function plotDimensions3D(obj, d1, d2, d3, newfigure)
            
            if nargin < 5
                newfigure = false;
            end

            if nargin < 4
                d3 = 3;
            end

            if nargin < 3
                d2 = 2;
            end

            if nargin < 2
                d1 = 1;
            end

            if newfigure == true
                figure;
            end

            %color = linspace(min(obj.dimensions(:,d1)),max(obj.dimensions(:,d1)),length(obj.dimensions(:,d1)));

            scatter3(obj.dimensions(:,d1), obj.dimensions(:,d2), obj.dimensions(:,d3), 'filled', 'LineWidth', 0.5, 'markerfacecolor', 'b', 'MarkerEdgeColor', 'k');
            hold on;

            title(['risk=' num2str(obj.riskval)]);
            xlabel(obj.dimensionDescription{d1}); 
            ylabel(obj.dimensionDescription{d2}); 

            if size(obj.nonDomIdxAR, 1) > 0
                for i = obj.nonDomIdxAR
                     scatter3(obj.dimensions(i, d1), obj.dimensions(i, d2), obj.dimensions(i, d3), 'markerfacecolor', 'g', 'MarkerEdgeColor', 'k');
                end
            end

            if obj.bestIdx > 0
                scatter3(obj.dimensions(obj.bestIdx, d1), obj.dimensions(obj.bestIdx, d2), obj.dimensions(obj.bestIdx, d3), 'markerfacecolor', 'r', 'MarkerEdgeColor', 'r');
            end

            hold off;
        end
    end
    
end

