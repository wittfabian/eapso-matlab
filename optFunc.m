classdef optFunc < matlab.mixin.Copyable %handle
    
    properties
        dimensions
        space
        startarea
        f
        view
    end
    
    methods        
        function obj = optFunc(func)
            switch func
                case 'ackley' % min = [0 0]
                    obj.init(@obj.ackley, 2, [-10 10 -10 10], [-10 10 -10 -8], [-105, 55]);
                case 'sphere' % min = [0 0]
                    obj.init(@obj.sphere, 2, [-10 10 -10 10], [-10 10 -10 -8], [-105, 55]);
                case 'sphere2'
                    obj.init(@obj.sphere2, 2, [-10 10 -10 10], [-10 10 -10 -8], [-105, 55]);
                case 'rosen' % min = [1 1]
                    %obj.init(@obj.rosen, 2, [-10 10 -10 10], [-10 -8 -10 10], [-162, 25]);
                    obj.init(@obj.rosen, 2, [-10 10 -10 10], [-10 10 -10 -8], [-162, 25]);
                    %obj.init(@obj.rosen, 2, [-2 2 -2 2], [-5 -4.5 -5 -4.5], [0 0]);
                case 'beale' % min = [3 0.5]
                    obj.init(@obj.beale, 2, [-10 10 -10 10], [-10 10 -10 -8], [0 0]);
                case 'levy13' % min = [1 1]
                    obj.init(@obj.levy13, 2, [-10 10 -10 10], [-10 10 -10 -8], [0 0]);
                otherwise
                    error(['optFunc function name not known: "' func '"']);
            end
        end
        
        function obj = init(obj, func, dimensions, space, startarea, view)
            obj.f = func;
            obj.dimensions = dimensions;
            obj.space = space;
            obj.startarea = startarea;
            obj.view = view;
        end
        
        function ret = plot(obj, viewaxis)
            
            if nargin < 2
                viewaxis = [obj.view(1), obj.view(2)];
            end
            
            
            delta = 0.5;
            
            [X,Y] = meshgrid(obj.space(1):delta:obj.space(2), obj.space(3):delta:obj.space(4));
            
            Z = arrayfun(@(x,y) obj.f([x y]), X, Y);
            
            ret = surf(X,Y,Z, 'FaceAlpha', 0.5);
            
            axis(obj.space);
            
            xlabel('x1'); ylabel('x2');
            
            view(viewaxis(1), viewaxis(2));
        end
        
        function [y] = ackley(~, xx, a, b, c)
            
            d = size(xx, 2);

            if (nargin < 5)
                c = 2*pi;
            end
            if (nargin < 4)
                b = 0.2;
            end
            if (nargin < 3)
                a = 20;
            end

            sum1 = 0;
            sum2 = 0;
            for ii = 1:d
                xi = xx(:, ii);
                sum1 = sum1 + xi.^2;
                sum2 = sum2 + cos(c*xi);
            end

            term1 = -a * exp(-b*sqrt(sum1/d));
            term2 = -exp(sum2/d);

            y = term1 + term2 + a + exp(1);

        end
        function [y] = sphere(~, xx)
            y = sum( arrayfun(@(x) x.^2, xx), 2 );
        end
        function [y] = rosen(~, xx)

            d = size(xx, 2);
            sum = zeros( size(xx, 1), 1 );
            for ii = 1:(d-1)
                xi = xx(:,ii);
                xnext = xx(:,ii+1);
                new = 100*(xnext-xi.^2).^2 + (xi-1).^2;
                sum = sum + new;
            end

            y = sum;

        end
        function [y] = levy13(~, xx)

            x1 = xx(:,1);
            x2 = xx(:,2);

            term1 = (sin(3*pi*x1)).^2;
            term2 = (x1-1).^2 .* (1+(sin(3*pi*x2)).^2);
            term3 = (x2-1).^2 .* (1+(sin(2*pi*x2)).^2);

            y = term1 + term2 + term3;

        end
        function [y] = beale(~, xx)

            x1 = xx(:, 1);
            x2 = xx(:, 2);

            term1 = (1.5 - x1 + x1.*x2).^2;
            term2 = (2.25 - x1 + x1.*x2.^2).^2;
            term3 = (2.625 - x1 + x1.*x2.^3).^2;

            y = term1 + term2 + term3;

        end
        function [y] = sphere2(obj, xx, point)

            if nargin < 3 
                point = zeros(1, obj.dimensions);
            end

            y = sum( arrayfun(@(x, p) (x-p)^2, xx, point) );
        end
    end
    
end

