classdef StatePlotter < handle
    % StatePlotter  Time-series: angles, angular velocities, control input.

    properties (Access = private)
        Fig
        AxTh
        AxVel
        AxU
        TData = []
        Th1Data = []
        Th2Data = []
        W1Data = []
        W2Data = []
        UData = []
    end

    methods
        function obj = StatePlotter()
            obj.Fig = figure('Color', [1 1 1], 'Name', 'State & Control');
            obj.AxTh  = subplot(3,1,1, 'Parent', obj.Fig, 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            obj.AxVel = subplot(3,1,2, 'Parent', obj.Fig, 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            obj.AxU   = subplot(3,1,3, 'Parent', obj.Fig, 'Color', [1 1 1], 'XColor', [0 0 0], 'YColor', [0 0 0]);
            hold(obj.AxTh, 'on'); hold(obj.AxVel, 'on'); hold(obj.AxU, 'on');
            plot(obj.AxTh,  NaN, NaN, 'Color', [0 0.5 0.6], 'DisplayName', '\theta_1');
            plot(obj.AxTh,  NaN, NaN, 'Color', [0.6 0 0.6], 'DisplayName', '\theta_2');
            plot(obj.AxVel, NaN, NaN, 'Color', [0 0.5 0.6], 'DisplayName', '\omega_1');
            plot(obj.AxVel, NaN, NaN, 'Color', [0.6 0 0.6], 'DisplayName', '\omega_2');
            plot(obj.AxU,   NaN, NaN, 'Color', [0.6 0.6 0], 'DisplayName', 'u');
            legend(obj.AxTh, 'Location', 'northeast');
            legend(obj.AxVel, 'Location', 'northeast');
            legend(obj.AxU, 'Location', 'northeast');
            ylabel(obj.AxTh, 'Angle (rad)');
            ylabel(obj.AxVel, 'Ang. vel (rad/s)');
            ylabel(obj.AxU, 'Torque');
            xlabel(obj.AxU, 'Time (s)');
        end

        function update(obj, sim)
            t = sim.Time;
            state = sim.CurrentState;
            u = sim.Controller.computeControl(t, state);
            obj.TData   = [obj.TData; t];
            obj.Th1Data = [obj.Th1Data; state(1)];
            obj.Th2Data = [obj.Th2Data; state(2)];
            obj.W1Data  = [obj.W1Data; state(3)];
            obj.W2Data  = [obj.W2Data; state(4)];
            obj.UData   = [obj.UData; u];
            kidsTh = get(obj.AxTh, 'Children');
            kidsVel = get(obj.AxVel, 'Children');
            kidsU = get(obj.AxU, 'Children');
            set(kidsTh(2), 'XData', obj.TData, 'YData', obj.Th1Data);
            set(kidsTh(1), 'XData', obj.TData, 'YData', obj.Th2Data);
            set(kidsVel(2), 'XData', obj.TData, 'YData', obj.W1Data);
            set(kidsVel(1), 'XData', obj.TData, 'YData', obj.W2Data);
            set(kidsU(1), 'XData', obj.TData, 'YData', obj.UData);
            drawnow;
        end
    end
end
