classdef PoincareMap < handle
    % PoincareMap  Phase-space scatter; configurable X/Y variables (theta1, theta2, omega1, omega2).

    properties
        XVar (1,1) string = "theta1"
        YVar (1,1) string = "theta2"
    end

    properties (Access = private)
        Fig
        Ax
        Scatter
        StateHistory = []   % Nx4
        TimeHistory = []    % Nx1, for color gradient (t=0 red -> blue)
        DropdownX
        DropdownY
    end

    methods
        function obj = PoincareMap(varargin)
            for i = 1:2:numel(varargin)-1
                if strcmpi(varargin{i}, 'XVar'), obj.XVar = string(varargin{i+1}); end
                if strcmpi(varargin{i}, 'YVar'), obj.YVar = string(varargin{i+1}); end
            end
            vars = ["theta1", "theta2", "omega1", "omega2"];
            obj.Fig = figure('Color', [1 1 1], 'Name', 'Poincaré Map', 'Position', [920, 320, 420, 420]);
            obj.Ax = axes(obj.Fig, 'Position', [0.12 0.2 0.75 0.7], 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            grid(obj.Ax, 'on');
            colormap(obj.Ax, [1 0 0; 1 0.3 0; 0.2 0.4 0.8; 0 0 1]);  % red (t=0) -> blue (t end)
            obj.Ax.CLim = [0 1];
            obj.Scatter = scatter(obj.Ax, NaN, NaN, 6, 0.5, 'filled');
            xlabel(obj.Ax, obj.XVar);
            ylabel(obj.Ax, obj.YVar);
            uicontrol(obj.Fig, 'Style', 'text', 'String', 'X:', 'Units', 'normalized', 'Position', [0.02 0.05 0.04 0.04]);
            obj.DropdownX = uicontrol(obj.Fig, 'Style', 'popup', 'String', vars, 'Value', 1, 'Units', 'normalized', 'Position', [0.07 0.04 0.12 0.06], 'Callback', @(~,~) obj.syncAxis(1));
            uicontrol(obj.Fig, 'Style', 'text', 'String', 'Y:', 'Units', 'normalized', 'Position', [0.22 0.05 0.04 0.04]);
            obj.DropdownY = uicontrol(obj.Fig, 'Style', 'popup', 'String', vars, 'Value', 2, 'Units', 'normalized', 'Position', [0.27 0.04 0.12 0.06], 'Callback', @(~,~) obj.syncAxis(2));
        end

        function update(obj, sim)
            state = sim.CurrentState(:)';
            obj.StateHistory = [obj.StateHistory; state];
            obj.TimeHistory = [obj.TimeHistory; sim.Time];
            [xd, yd] = obj.xyFromHistory();
            if isempty(obj.TimeHistory)
                c = 0.5;
            else
                t = obj.TimeHistory;
                tRange = max(t) - min(t);
                c = (t - min(t)) / (tRange + 1e-10);  % 0 at start (red), 1 at end (blue)
            end
            set(obj.Scatter, 'XData', xd, 'YData', yd, 'CData', c);
            drawnow;
        end

        function [xd, yd] = xyFromHistory(obj)
            if isempty(obj.StateHistory)
                xd = NaN; yd = NaN;
                return
            end
            xd = obj.getVarVec(obj.StateHistory, obj.XVar);
            yd = obj.getVarVec(obj.StateHistory, obj.YVar);
        end

        function v = getVarVec(obj, states, name)
            idx = obj.varIndex(name);
            v = states(:, idx);
        end

        function v = getVar(~, state, name)
            idx = obj.varIndex(name);
            v = state(idx);
        end

        function idx = varIndex(~, name)
            switch name
                case "theta1", idx = 1; case "theta2", idx = 2;
                case "omega1", idx = 3; case "omega2", idx = 4;
                otherwise,     idx = 1;
            end
        end

        function syncAxis(obj, which)
            vars = ["theta1", "theta2", "omega1", "omega2"];
            if which == 1
                obj.XVar = vars(get(obj.DropdownX, 'Value'));
            else
                obj.YVar = vars(get(obj.DropdownY, 'Value'));
            end
            [xd, yd] = obj.xyFromHistory();
            if isempty(obj.TimeHistory)
                c = 0.5;
            else
                t = obj.TimeHistory;
                tRange = max(t) - min(t);
                c = (t - min(t)) / (tRange + 1e-10);
            end
            set(obj.Scatter, 'XData', xd, 'YData', yd, 'CData', c);
            xlabel(obj.Ax, obj.XVar);
            ylabel(obj.Ax, obj.YVar);
        end
    end
end
