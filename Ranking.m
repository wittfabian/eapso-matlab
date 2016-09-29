classdef Ranking < handle
    
    properties
        particles = [];
        dimensions = [];
        riskval = 0.5;
        
        type;
        
        dimensionDescription;
        
        bestIdx = 0;
        
        logger %= log4m.getLogger( 'logfile.txt' );
    end
    
    properties (Constant)
        RT_STD = 'standard';
        RT_RS  = 'risk_selection';
    end
    
    methods (Abstract)
        run(obj);
    end
    
    methods
        function obj = Ranking(type)
            
            if nargin == 0
                obj.type = obj.RT_STD;
            else 
                obj.type = type;
            end
            
            obj.dimensionDescription{1} = 'movecost';
            obj.dimensionDescription{2} = 'profit * -1';
        end
        
        function logger = get.logger(~)
            global swarmObj;
            logger = swarmObj.logger;
        end
        
        function addParticle(obj, particle)
            obj.particles = [obj.particles particle];
        end
        
        function addParticleArray(obj, particles)
            for i = 1:1:size(particles, 2)
                obj.particles = [obj.particles particles(i)];
                %obj.logger.info('DistanceBasedRanking/addParticleArray', sprintf('simcont=%s', obj.getParticleById(particles(i)).simCont.printShortValues));
            end
        end
        
        function createDimensions(obj)
            
            obj.dimensions = zeros(size(obj.particles, 2), 2);
            
            for p = 1:1:size(obj.particles, 2)
                
                % riskval (value of risk) for the riskSelectionRanking
                %obj.riskval = obj.getParticleById(obj.particles(p)).simCont.getRisk;
                
                % minimize movecost
                obj.dimensions(p,1) = obj.getParticleById(obj.particles(p)).simCont.getMovecost;
                obj.dimensionDescription{1} = 'movecost';
                % maximize profit => minimize (profit * -1)
                obj.dimensions(p,2) = -1 * obj.getParticleById(obj.particles(p)).simCont.getProfit;
                obj.dimensionDescription{2} = 'profit * -1';
                
                obj.logger.info('Ranking/createDimensions', sprintf('p%i=[%s]', p, sprintf('%f;',obj.dimensions(p,:))));
            end
            
        end
        
        function particle = getBestParticle(obj)
            [~,idx] = max(obj.DR);
            
            particle = obj.particles(idx);
        end
        
        function particle = getParticleById(~, idx)
            global swarmObj;
            
            particle = swarmObj.particles(idx);
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
            
            scatter(obj.dimensions(:,d1), obj.dimensions(:,d2), 'filled', 'LineWidth', 2);
            hold on;
            
            title(['risk=' num2str(obj.riskval)]);
            xlabel(obj.dimensionDescription{d1}); 
            ylabel(obj.dimensionDescription{d2}); 
            
            if obj.bestIdx > 0
                scatter(obj.dimensions(obj.bestIdx, d1), obj.dimensions(obj.bestIdx, d2), 'markerfacecolor', 'r');
            end
            
            hold off;
        end
    end
    
end

