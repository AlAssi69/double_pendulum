classdef StatePlotter < handle
    % StatePlotter  Time-series: angles (continuous/unwrapped), angular velocities, control input.

    properties (Access = private)
        Fig
        AxTh
        AxVel
        AxU
        TData = []
        Th1Data = []   % raw rad, unwrapped for display
        Th2Data = []
        W1Data = []
        W2Data = []
        UData = []
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
            plot(obj.AxTh,  NaN, NaN, 'Color', [1 0 0], 'LineWidth', 2, 'DisplayName', '\theta_1');
            plot(obj.AxTh,  NaN, NaN, 'Color', [0 0 1], 'LineWidth', 2, 'DisplayName', '\theta_2');
            plot(obj.AxVel, NaN, NaN, 'Color', [1 0 0], 'LineWidth', 2, 'DisplayName', '\omega_1');
            plot(obj.AxVel, NaN, NaN, 'Color', [0 0 1], 'LineWidth', 2, 'DisplayName', '\omega_2');
            plot(obj.AxU,   NaN, NaN, 'Color', [0 0 0], 'LineWidth', 2, 'DisplayName', 'u');
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
            t = sim.Time;
            state = sim.CurrentState;
            u = sim.Controller.computeControl(t, state);
            obj.TData   = [obj.TData; t];
            % Store raw angles; we unwrap for display so trajectories are continuous
            obj.Th1Data = [obj.Th1Data; state(1)];
            obj.Th2Data = [obj.Th2Data; state(2)];
            obj.W1Data  = [obj.W1Data; state(3)];
            obj.W2Data  = [obj.W2Data; state(4)];
            obj.UData   = [obj.UData; u];
            th1Plot = unwrap(obj.Th1Data);
            th2Plot = unwrap(obj.Th2Data);
            w1Plot = obj.W1Data;
            w2Plot = obj.W2Data;
            if strcmpi(obj.AngleUnit, 'degree')
                th1Plot = th1Plot * 180 / pi;
                th2Plot = th2Plot * 180 / pi;
                w1Plot = w1Plot * 180 / pi;
                w2Plot = w2Plot * 180 / pi;
            end
            kidsTh = get(obj.AxTh, 'Children');
            kidsVel = get(obj.AxVel, 'Children');
            kidsU = get(obj.AxU, 'Children');
            set(kidsTh(2), 'XData', obj.TData, 'YData', th1Plot);
            set(kidsTh(1), 'XData', obj.TData, 'YData', th2Plot);
            set(kidsVel(2), 'XData', obj.TData, 'YData', w1Plot);
            set(kidsVel(1), 'XData', obj.TData, 'YData', w2Plot);
            set(kidsU(1), 'XData', obj.TData, 'YData', obj.UData);
            drawnow;
        end
    end
end
