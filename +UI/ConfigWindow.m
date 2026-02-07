classdef ConfigWindow < handle
    % ConfigWindow  GUI for config: params, initial state, time span, controller toggle. Block until Start.

    properties
        Params        struct
        InitialState  (4,1) double
        TimeSpan      (1,2) double
        SolverType    (1,1) string = "rk4"   % "euler" | "rk4" | "ode45"
        StepSize      (1,1) double = 0.02
        EnableControl (1,1) logical = false
        Q             (4,4) double
        R             (1,1) double
        AngleUnit     (1,1) string = "radian"   % "radian" | "degree" for all GUIs and plots
    end

    properties
        Fig    % uifigure handle; use waitfor(app.Fig) to block until window closes
    end

    properties (Access = private)
        SolverDropdown   % uidropdown handle – read on Start
        StepSizeEdit     % uieditfield handle – read on Start
        TimeSpanEdit     % uieditfield handle – read on Start
        ParamEdits       % struct with fields m1, m2, L1, L2 – read on Start
        StateEdits       % struct with fields th1, th2 – read on Start
        AngleUnitDropdown   % uidropdown – read on Start
    end

    methods
        function obj = ConfigWindow(config)
            if nargin < 1, config = Utils.ConfigLoader.loadDefault(); end
            obj.Params = config.Params;
            obj.InitialState = config.InitialState(:);
            obj.TimeSpan = config.TimeSpan;
            obj.SolverType = string(config.SolverType);
            obj.StepSize = config.StepSize;
            obj.EnableControl = config.EnableControl;
            obj.Q = config.Q;
            obj.R = config.R;
            if isfield(config, 'AngleUnit'), obj.AngleUnit = string(config.AngleUnit); end

            obj.Fig = uifigure('Name', 'Double Pendulum Config', 'Position', [100 100 380 520]);
            y = 440;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'm1');
            obj.ParamEdits.m1 = obj.addEditWithHandle(140, y, num2str(obj.Params.m1), @(v) setP(obj, 'm1', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'm2');
            obj.ParamEdits.m2 = obj.addEditWithHandle(140, y, num2str(obj.Params.m2), @(v) setP(obj, 'm2', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'L1');
            obj.ParamEdits.L1 = obj.addEditWithHandle(140, y, num2str(obj.Params.L1), @(v) setP(obj, 'L1', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'L2');
            obj.ParamEdits.L2 = obj.addEditWithHandle(140, y, num2str(obj.Params.L2), @(v) setP(obj, 'L2', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial θ1 (rad)');
            obj.StateEdits.th1 = obj.addEditWithHandle(140, y, num2str(obj.InitialState(1)), @(v) setState(obj, 1, v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial θ2 (rad)');
            obj.StateEdits.th2 = obj.addEditWithHandle(140, y, num2str(obj.InitialState(2)), @(v) setState(obj, 2, v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Time span [t0 tEnd]');
            obj.TimeSpanEdit = obj.addEditWithHandle(140, y, mat2str(obj.TimeSpan), @(v) setTS(obj, v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Solver');
            obj.SolverDropdown = obj.addSolverDropdown(140, y);
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Step size dt');
            obj.StepSizeEdit = obj.addEditWithHandle(140, y, num2str(obj.StepSize), @(v) setStepSize(obj, v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Angle unit');
            obj.AngleUnitDropdown = uidropdown(obj.Fig, 'Position', [140 y 100 22], ...
                'Items', ["radian", "degree"], 'Value', obj.AngleUnit, ...
                'ValueChangedFcn', @(src,~) set(obj, 'AngleUnit', string(src.Value)));
            y = y - 32;
            obj.addCheckbox(20, y, 'Enable LQR control', obj.EnableControl, @(v) set(obj, 'EnableControl', v));
            y = y - 36;
            uibutton(obj.Fig, 'Position', [120 y 140 32], 'Text', 'Start', 'ButtonPushedFcn', @(~,~) obj.doClose());
        end

        function h = addEdit(obj, x, y, val, setter)
            h = uieditfield(obj.Fig, 'text', 'Position', [x y 100 22], 'Value', val);
            addlistener(h, 'ValueChanged', @(src,~) obj.editCallback(setter, src));
        end

        function h = addEditWithHandle(obj, x, y, val, setter)
            h = obj.addEdit(x, y, val, setter);
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

        function h = addSolverDropdown(obj, x, y)
            items = ["euler", "rk4", "ode45"];
            h = uidropdown(obj.Fig, 'Position', [x y 100 22], 'Items', items, ...
                'Value', obj.SolverType, 'ValueChangedFcn', @(src,~) obj.assignSolverType(src.Value));
        end

        function assignSolverType(obj, val)
            obj.SolverType = string(val);
        end

        function setStepSize(obj, v)
            if ~isnan(v) && v > 0, obj.StepSize = v; end
        end

        function doClose(obj)
            % Read current GUI values into properties before figure is destroyed (so main gets selection)
            obj.SolverType = string(obj.SolverDropdown.Value);
            obj.AngleUnit = string(obj.AngleUnitDropdown.Value);
            stepVal = str2double(obj.StepSizeEdit.Value);
            if ~isnan(stepVal) && stepVal > 0
                obj.StepSize = stepVal;
            end
            ts = str2num(obj.TimeSpanEdit.Value);
            if numel(ts) >= 2
                obj.TimeSpan = [ts(1) ts(2)];
            end
            for fn = {'m1', 'm2', 'L1', 'L2'}
                v = str2double(obj.ParamEdits.(fn{1}).Value);
                if ~isnan(v), obj.Params.(fn{1}) = v; end
            end
            v1 = str2double(obj.StateEdits.th1.Value);
            if ~isnan(v1), obj.InitialState(1) = v1; end
            v2 = str2double(obj.StateEdits.th2.Value);
            if ~isnan(v2), obj.InitialState(2) = v2; end
            delete(obj.Fig);
        end
    end
end
