classdef PendulumAnimator < handle
    % PendulumAnimator  Renders 2D double-pendulum; white theme, black text, trace for mass 2.

    properties (Access = private)
        Fig
        Ax
        Line1
        Line2
        Mass1
        Mass2
        Trace
        TraceData = zeros(0, 2)
        MaxTracePoints = 500
        AngleUnit (1,1) string = "radian"   % for consistency with other visualizers
    end

    methods
        function obj = PendulumAnimator(angleUnit)
            if nargin >= 1 && ~isempty(angleUnit)
                obj.AngleUnit = string(angleUnit);
            end
            obj.Fig = figure('Color', [1 1 1], 'Name', 'Double Pendulum', 'Position', [40, 320, 420, 420]);
            obj.Ax = axes(obj.Fig, 'Position', [0.05 0.05 0.9 0.9], 'Color', [1 1 1], ...
                'XColor', [0 0 0], 'YColor', [0 0 0]);
            hold(obj.Ax, 'on');
            grid(obj.Ax, 'on');
            axis(obj.Ax, 'equal');
            obj.Trace = plot(obj.Ax, NaN, NaN, 'Color', [0 0 1 0.5], 'LineWidth', 1.5);
            obj.Line1 = plot(obj.Ax, [0 0], [0 0], 'Color', [1 0 0], 'LineWidth', 4);
            obj.Line2 = plot(obj.Ax, [0 0], [0 0], 'Color', [0 0 1], 'LineWidth', 4);
            obj.Mass1 = plot(obj.Ax, 0, 0, 'o', 'MarkerSize', 12, 'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 1.5);
            obj.Mass2 = plot(obj.Ax, 0, 0, 'o', 'MarkerSize', 12, 'MarkerFaceColor', [0 0 1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 1.5);
            L = 2.2;
            xlim(obj.Ax, [-L L]);
            ylim(obj.Ax, [-L L]);
        end

        function update(obj, sim)
            state = sim.CurrentState;
            model = sim.Model;
            L1 = model.L1;
            L2 = model.L2;
            th1 = state(1);
            th2 = state(2);
            x1 = L1*sin(th1);
            y1 = -L1*cos(th1);
            x2 = x1 + L2*sin(th1+th2);
            y2 = y1 - L2*cos(th1+th2);

            set(obj.Line1, 'XData', [0 x1], 'YData', [0 y1]);
            set(obj.Line2, 'XData', [x1 x2], 'YData', [y1 y2]);
            set(obj.Mass1, 'XData', x1, 'YData', y1);
            set(obj.Mass2, 'XData', x2, 'YData', y2);

            obj.TraceData = [obj.TraceData; x2 y2];
            if size(obj.TraceData, 1) > obj.MaxTracePoints
                obj.TraceData = obj.TraceData(end-obj.MaxTracePoints+1:end, :);
            end
            set(obj.Trace, 'XData', obj.TraceData(:,1), 'YData', obj.TraceData(:,2));
            drawnow;
        end
    end
end
