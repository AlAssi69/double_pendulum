classdef ConfigWindow < handle
    % ConfigWindow  GUI for config: params, initial state, time span, controller toggle. Block until Start.

    properties
        Params        struct
        InitialState  (4,1) double
        TimeSpan      (1,2) double
        EnableControl (1,1) logical = false
        Q             (4,4) double
        R             (1,1) double
    end

    properties
        Fig    % uifigure handle; use waitfor(app.Fig) to block until window closes
    end

    methods
        function obj = ConfigWindow(config)
            if nargin < 1, config = Utils.ConfigLoader.loadDefault(); end
            obj.Params = config.Params;
            obj.InitialState = config.InitialState(:);
            obj.TimeSpan = config.TimeSpan;
            obj.EnableControl = config.EnableControl;
            obj.Q = config.Q;
            obj.R = config.R;

            obj.Fig = uifigure('Name', 'Double Pendulum Config', 'Position', [100 100 380 420]);
            y = 380;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'm1');
            obj.addEdit(140, y, num2str(obj.Params.m1), @(v) setP(obj, 'm1', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'm2');
            obj.addEdit(140, y, num2str(obj.Params.m2), @(v) setP(obj, 'm2', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'L1');
            obj.addEdit(140, y, num2str(obj.Params.L1), @(v) setP(obj, 'L1', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'L2');
            obj.addEdit(140, y, num2str(obj.Params.L2), @(v) setP(obj, 'L2', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial θ1');
            obj.addEdit(140, y, num2str(obj.InitialState(1)), @(v) setState(obj, 1, v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial θ2');
            obj.addEdit(140, y, num2str(obj.InitialState(2)), @(v) setState(obj, 2, v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Time span [t0 tEnd]');
            obj.addEdit(140, y, mat2str(obj.TimeSpan), @(v) setTS(obj, v));
            y = y - 32;
            obj.addCheckbox(20, y, 'Enable LQR control', obj.EnableControl, @(v) set(obj, 'EnableControl', v));
            y = y - 36;
            uibutton(obj.Fig, 'Position', [120 y 140 32], 'Text', 'Start', 'ButtonPushedFcn', @(~,~) obj.doClose());
        end

        function addEdit(obj, x, y, val, setter)
            h = uieditfield(obj.Fig, 'text', 'Position', [x y 100 22], 'Value', val);
            addlistener(h, 'ValueChanged', @(src,~) obj.editCallback(setter, src));
        end

        function editCallback(obj, setter, src)
            v = str2double(src.Value);
            if ~isnan(v)
                setter(v);
            end
        end

        function addCheckbox(obj, x, y, text, val, setter)
            uicheckbox(obj.Fig, 'Position', [x y 200 22], 'Text', text, 'Value', val, 'ValueChangedFcn', @(src,~) setter(src.Value));
        end

        function setP(obj, name, v)
            if isnan(v), return; end
            obj.Params.(name) = v;
        end

        function setState(obj, i, v)
            if isnan(v), return; end
            obj.InitialState(i) = v;
        end

        function setTS(obj, v)
            ts = str2num(v);
            if numel(ts) >= 2, obj.TimeSpan = [ts(1) ts(2)]; end
        end

        function doClose(obj)
            delete(obj.Fig);
        end
    end
end
