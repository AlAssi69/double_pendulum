classdef PoincareMap < handle
    % PoincareMap  Phase-plane plot with continuous lines (point a to b to c...); configurable X/Y (theta1, theta2, omega1, omega2).

    properties
        XVar (1,1) string = "theta1"
        YVar (1,1) string = "theta2"
    end

    properties (Access = private)
        Fig
        Ax
        LinePlot   % line connecting points in order (continuous phase trajectory)
        Scatter    % points colored by time (gradient)
        StateHistory = []   % Nx4
        TimeHistory = []    % Nx1
        DropdownX
        DropdownY
        AngleUnit (1,1) string = "radian"
    end

    methods
        function obj = PoincareMap(varargin)
            for i = 1:2:numel(varargin)-1
                if strcmpi(varargin{i}, 'XVar'), obj.XVar = string(varargin{i+1}); end
                if strcmpi(varargin{i}, 'YVar'), obj.YVar = string(varargin{i+1}); end
                if strcmpi(varargin{i}, 'AngleUnit'), obj.AngleUnit = string(varargin{i+1}); end
            end
            vars = ["theta1", "theta2", "omega1", "omega2"];
            obj.Fig = figure('Color', [1 1 1], 'Name', 'Poincaré Map', 'Position', [920, 320, 420, 420]);
            obj.Ax = axes(obj.Fig, 'Position', [0.12 0.2 0.75 0.7], 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            obj.Ax.XGrid = 'on';
            obj.Ax.YGrid = 'on';
            obj.Ax.Box = 'on';
            hold(obj.Ax, 'on');
            % Time gradient colormap (red at t=0 -> blue at t end)
            colormap(obj.Ax, [1 0 0; 1 0.3 0; 0.2 0.4 0.8; 0 0 1]);
            obj.Ax.CLim = [0 1];
            % Continuous line from point to point (phase trajectory)
            obj.LinePlot = plot(obj.Ax, NaN, NaN, '-', 'Color', [0.3 0.3 0.35], 'LineWidth', 1);
            % Scatter for gradient color by time (red = start, blue = end)
            obj.Scatter = scatter(obj.Ax, NaN, NaN, 8, 0.5, 'filled');
            obj.updateAxisLabels();
            uicontrol(obj.Fig, 'Style', 'text', 'String', 'X:', 'Units', 'normalized', 'Position', [0.02 0.05 0.04 0.04]);
            obj.DropdownX = uicontrol(obj.Fig, 'Style', 'popup', 'String', vars, 'Value', 1, 'Units', 'normalized', 'Position', [0.07 0.04 0.12 0.06], 'Callback', @(~,~) obj.syncAxis(1));
            uicontrol(obj.Fig, 'Style', 'text', 'String', 'Y:', 'Units', 'normalized', 'Position', [0.22 0.05 0.04 0.04]);
            obj.DropdownY = uicontrol(obj.Fig, 'Style', 'popup', 'String', vars, 'Value', 2, 'Units', 'normalized', 'Position', [0.27 0.04 0.12 0.06], 'Callback', @(~,~) obj.syncAxis(2));
        end

        function updateAxisLabels(obj)
            xlab = obj.axisLabel(obj.XVar);
            ylab = obj.axisLabel(obj.YVar);
            xlabel(obj.Ax, xlab);
            ylabel(obj.Ax, ylab);
        end

        function lab = axisLabel(obj, name)
            if name == "theta1" || name == "theta2"
                if strcmpi(obj.AngleUnit, 'degree')
                    lab = name + " (°)";
                else
                    lab = name + " (rad)";
                end
            elseif name == "omega1" || name == "omega2"
                if strcmpi(obj.AngleUnit, 'degree')
                    lab = name + " (°/s)";
                else
                    lab = name + " (rad/s)";
                end
            else
                lab = name;
            end
        end

        function update(obj, sim)
            state = sim.CurrentState(:)';
            obj.StateHistory = [obj.StateHistory; state];
            obj.TimeHistory = [obj.TimeHistory; sim.Time];
            [xd, yd] = obj.xyFromHistory();
            set(obj.LinePlot, 'XData', xd, 'YData', yd);
            set(obj.Scatter, 'XData', xd, 'YData', yd, 'CData', obj.timeColor());
            grid(obj.Ax, 'on');
            drawnow;
        end

        function c = timeColor(obj)
            if isempty(obj.TimeHistory)
                c = 0.5;
            else
                t = obj.TimeHistory;
                tRange = max(t) - min(t);
                c = (t - min(t)) / (tRange + 1e-10);  % 0 at start (red), 1 at end (blue)
            end
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
            % theta1 = first arm from vertical; theta2 (display) = second arm from vertical = theta1 + theta2_rel
            th1 = unwrap(states(:, 1));
            th2_rel = unwrap(states(:, 2));
            if name == "theta1"
                v = th1;
            elseif name == "theta2"
                % Display absolute angle of second arm (so 90° and 90° = straight)
                v = th1 + th2_rel;
            else
                idx = obj.varIndex(name);
                v = states(:, idx);
            end
            % Convert to display unit
            if (name == "theta1" || name == "theta2") && strcmpi(obj.AngleUnit, 'degree')
                v = v * 180 / pi;
            elseif (name == "omega1" || name == "omega2") && strcmpi(obj.AngleUnit, 'degree')
                v = v * 180 / pi;
            end
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
            set(obj.LinePlot, 'XData', xd, 'YData', yd);
            set(obj.Scatter, 'XData', xd, 'YData', yd, 'CData', obj.timeColor());
            grid(obj.Ax, 'on');
            obj.updateAxisLabels();
        end
    end
end
