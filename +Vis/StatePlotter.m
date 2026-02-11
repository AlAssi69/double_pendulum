classdef StatePlotter < handle
    % StatePlotter  Time-series: angles (continuous/unwrapped), angular velocities, control input.

    properties (Access = private)
        Fig
        AxTh
        AxVel
        AxU
        LineTh1    % line handle for theta1
        LineTh2    % line handle for theta2
        LineW1     % line handle for omega1
        LineW2     % line handle for omega2
        LineU      % line handle for control input
        TData = []
        Th1Unwrapped = []   % pre-unwrapped theta1 for display
        Th2Unwrapped = []   % pre-unwrapped theta2_rel for display
        W1Data = []
        W2Data = []
        UData = []
        MaxPoints = 5000    % cap history length for performance
        AngleUnit (1,1) string = "radian"
    end

    methods
        function obj = StatePlotter(angleUnit)
            if nargin >= 1 && ~isempty(angleUnit)
                obj.AngleUnit = string(angleUnit);
            end
            obj.Fig = figure('Color', [1 1 1], 'Name', 'State & Control', 'Position', [480, 320, 420, 520]);
            obj.AxTh  = subplot(3,1,1, 'Parent', obj.Fig, 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            obj.AxVel = subplot(3,1,2, 'Parent', obj.Fig, 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            obj.AxU   = subplot(3,1,3, 'Parent', obj.Fig, 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            hold(obj.AxTh, 'on'); hold(obj.AxVel, 'on'); hold(obj.AxU, 'on');
            grid(obj.AxTh, 'on'); grid(obj.AxVel, 'on'); grid(obj.AxU, 'on');
            obj.LineTh1 = plot(obj.AxTh,  NaN, NaN, 'Color', [1 0 0], 'LineWidth', 2, 'DisplayName', '\theta_1');
            obj.LineTh2 = plot(obj.AxTh,  NaN, NaN, 'Color', [0 0 1], 'LineWidth', 2, 'DisplayName', '\theta_2');
            obj.LineW1  = plot(obj.AxVel, NaN, NaN, 'Color', [1 0 0], 'LineWidth', 2, 'DisplayName', '\omega_1');
            obj.LineW2  = plot(obj.AxVel, NaN, NaN, 'Color', [0 0 1], 'LineWidth', 2, 'DisplayName', '\omega_2');
            obj.LineU   = plot(obj.AxU,   NaN, NaN, 'Color', [0 0 0], 'LineWidth', 2, 'DisplayName', 'u');
            legend(obj.AxTh, 'Location', 'northeast');
            legend(obj.AxVel, 'Location', 'northeast');
            legend(obj.AxU, 'Location', 'northeast');
            obj.updateAxisLabels();
        end

        function updateAxisLabels(obj)
            if strcmpi(obj.AngleUnit, 'degree')
                ylabel(obj.AxTh, 'Angle (°)');
                ylabel(obj.AxVel, 'Ang. vel (°/s)');
            else
                ylabel(obj.AxTh, 'Angle (rad)');
                ylabel(obj.AxVel, 'Ang. vel (rad/s)');
            end
            ylabel(obj.AxU, 'Torque');
            xlabel(obj.AxU, 'Time (s)');
        end

        function update(obj, sim)
            if ~isvalid(obj.Fig), return; end
            t = sim.Time;
            state = sim.CurrentState;
            u = sim.Controller.computeControl(t, state);

            % Incremental unwrap: unwrap new sample relative to last stored value (O(1) per step)
            if isempty(obj.Th1Unwrapped)
                th1u = state(1);
                th2u = state(2);
            else
                th1u = obj.Th1Unwrapped(end) + mod(state(1) - obj.Th1Unwrapped(end) + pi, 2*pi) - pi;
                th2u = obj.Th2Unwrapped(end) + mod(state(2) - obj.Th2Unwrapped(end) + pi, 2*pi) - pi;
            end

            obj.TData        = [obj.TData; t];
            obj.Th1Unwrapped = [obj.Th1Unwrapped; th1u];
            obj.Th2Unwrapped = [obj.Th2Unwrapped; th2u];
            obj.W1Data       = [obj.W1Data; state(3)];
            obj.W2Data       = [obj.W2Data; state(4)];
            obj.UData        = [obj.UData; u];

            % Cap history length for performance
            if numel(obj.TData) > obj.MaxPoints
                excess = numel(obj.TData) - obj.MaxPoints;
                obj.TData        = obj.TData(excess+1:end);
                obj.Th1Unwrapped = obj.Th1Unwrapped(excess+1:end);
                obj.Th2Unwrapped = obj.Th2Unwrapped(excess+1:end);
                obj.W1Data       = obj.W1Data(excess+1:end);
                obj.W2Data       = obj.W2Data(excess+1:end);
                obj.UData        = obj.UData(excess+1:end);
            end

            % theta1 = first arm from vertical; theta2 (display) = second arm from vertical
            th1Plot = obj.Th1Unwrapped;
            th2Plot = obj.Th1Unwrapped + obj.Th2Unwrapped;
            w1Plot = obj.W1Data;
            w2Plot = obj.W2Data;
            if strcmpi(obj.AngleUnit, 'degree')
                th1Plot = th1Plot * 180 / pi;
                th2Plot = th2Plot * 180 / pi;
                w1Plot = w1Plot * 180 / pi;
                w2Plot = w2Plot * 180 / pi;
            end
            set(obj.LineTh1, 'XData', obj.TData, 'YData', th1Plot);
            set(obj.LineTh2, 'XData', obj.TData, 'YData', th2Plot);
            set(obj.LineW1, 'XData', obj.TData, 'YData', w1Plot);
            set(obj.LineW2, 'XData', obj.TData, 'YData', w2Plot);
            set(obj.LineU, 'XData', obj.TData, 'YData', obj.UData);
            drawnow;
        end
    end
end
