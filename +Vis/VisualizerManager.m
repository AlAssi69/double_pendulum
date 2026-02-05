classdef VisualizerManager < handle
    % VisualizerManager  Observer: subscribes to Simulator, updates all added visualizers on update(sim).

    properties (Access = private)
        Visualizers = {}
    end

    methods
        function add(obj, viz)
            obj.Visualizers{end+1} = viz;
        end

        function update(obj, sim)
            for i = 1:numel(obj.Visualizers)
                obj.Visualizers{i}.update(sim);
            end
        end
    end
end
