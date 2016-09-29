classdef neighborhoodKnn < neighborhood
    
    properties
        name = 'KNN'
        default_k = 2;
        k
    end
    
    methods
        function obj = neighborhoodKnn(particle, particles, k)
            obj@neighborhood(particle, particles);
            
            if nargin < 3 || k <= 0
                obj.k = obj.default_k;
            else
                obj.k = k;
            end
            
            obj.findGlobalBest();
        end
        
        function nbr = countParticleInNeighborhood(obj)
            nbr = obj.k;
        end
        
        function obj = findGlobalBest(obj)
            
            obj.tempNeighborhood = [];
            
            [idx, ~] = knnsearch(obj.getPositions(), obj.particleObj.position, 'k', obj.k, 'distance', 'euclidean');
            
            obj.tempNeighborhood = obj.particlesIdx(idx);
            
            if ~isnumeric(obj.globalBest) || ~isinteger(obj.globalBest)
                obj.globalBest = obj.tempNeighborhoodIdx(1);
            end

            for p = 1:1:size(obj.tempNeighborhood, 2)    
                if obj.getParticleById(obj.tempNeighborhoodIdx(p)).taskFuncval(obj.ref_task_id) <= obj.globalBestObj.taskFuncval(obj.ref_task_id)
                    obj.globalBest = obj.tempNeighborhoodIdx(p);
                end
            end
        end
    end
    
end