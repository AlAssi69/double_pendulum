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
        ParamEdits       % struct with fields m1, m2, L1, L2, g, beta1, beta2 – read on Start
        StateEdits       % struct with fields th1, th2, w1, w2 – read on Start
        StateLabels      % struct with th1, th2, w1, w2 – uilabel handles for angle unit
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

            obj.Fig = uifigure('Name', 'Double Pendulum Config', 'Position', [100 100 380 660]);
            y = 580;
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
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'g (gravity)');
            obj.ParamEdits.g = obj.addEditWithHandle(140, y, num2str(obj.Params.g), @(v) setP(obj, 'g', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'beta1 (damping)');
            obj.ParamEdits.beta1 = obj.addEditWithHandle(140, y, num2str(obj.Params.beta1), @(v) setP(obj, 'beta1', v));
            y = y - 28;
            uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'beta2 (damping)');
            obj.ParamEdits.beta2 = obj.addEditWithHandle(140, y, num2str(obj.Params.beta2), @(v) setP(obj, 'beta2', v));
            y = y - 28;
            % θ1, θ2 = angles from vertical (both absolute); stored as state(1), state(2)=θ2_rel=θ2_abs−θ1
            obj.StateLabels.th1 = uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial θ1 (rad, from vertical)');
            obj.StateEdits.th1 = obj.addEditWithHandle(140, y, num2str(obj.angleToDisplay(obj.InitialState(1))), @(v) setState(obj, 1, v));
            y = y - 28;
            th2Abs = obj.InitialState(1) + obj.InitialState(2);  % display absolute second angle
            obj.StateLabels.th2 = uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial θ2 (rad, from vertical)');
            obj.StateEdits.th2 = obj.addEditWithHandle(140, y, num2str(obj.angleToDisplay(th2Abs)), @(v) setState(obj, 2, v));
            y = y - 28;
            obj.StateLabels.w1 = uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial ω1 (rad/s)');
            obj.StateEdits.w1 = obj.addEditWithHandle(140, y, num2str(obj.velToDisplay(obj.InitialState(3))), @(v) setVelState(obj, 3, v));
            y = y - 28;
            obj.StateLabels.w2 = uilabel(obj.Fig, 'Position', [20 y 120 22], 'Text', 'Initial ω2 (rad/s)');
            obj.StateEdits.w2 = obj.addEditWithHandle(140, y, num2str(obj.velToDisplay(obj.InitialState(4))), @(v) setVelState(obj, 4, v));
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
                'ValueChangedFcn', @(src,~) obj.setAngleUnit(string(src.Value)));
            obj.refreshStateDisplay();   % sync labels and state edits to AngleUnit
            y = y - 32;
            obj.addCheckbox(20, y, 'Enable LQR control', obj.EnableControl, @(v) obj.setEnableControl(v));
            y = y - 36;
            uibutton(obj.Fig, 'Position', [120 y 140 32], 'Text', 'Start', 'ButtonPushedFcn', @(~,~) obj.doClose());
        end

    end

    methods (Access = private)
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
            vRad = obj.angleFromDisplay(v);
            if i == 1
                obj.InitialState(1) = vRad;
                % Keep θ2 display as absolute: θ2_abs = θ1 + θ2_rel
                obj.StateEdits.th2.Value = num2str(obj.angleToDisplay(vRad + obj.InitialState(2)));
            else
                % v = θ2 from vertical (absolute) → θ2_rel = v − θ1
                obj.InitialState(2) = vRad - obj.InitialState(1);
            end
        end

        function setVelState(obj, i, v)
            if isnan(v), return; end
            obj.InitialState(i) = obj.velFromDisplay(v);
        end

        function setTS(obj, v)
            ts = sscanf(v, '%f', [1 2]);
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

        function setAngleUnit(obj, val)
            obj.AngleUnit = val;
            obj.refreshStateDisplay();
        end

        function setEnableControl(obj, v)
            obj.EnableControl = v;
        end

        function setStepSize(obj, v)
            if ~isnan(v) && v > 0, obj.StepSize = v; end
        end

        function d = angleToDisplay(obj, rad)
            % Convert internal angle (rad) to the value shown in the GUI.
            if strcmpi(obj.AngleUnit, 'degree')
                d = rad * 180 / pi;
            else
                d = rad;
            end
        end

        function r = angleFromDisplay(obj, displayVal)
            % Convert GUI value to internal angle (rad).
            if strcmpi(obj.AngleUnit, 'degree')
                r = displayVal * pi / 180;
            else
                r = displayVal;
            end
        end

        function d = velToDisplay(obj, radPerSec)
            % Convert internal angular velocity (rad/s) to display unit.
            if strcmpi(obj.AngleUnit, 'degree')
                d = radPerSec * 180 / pi;
            else
                d = radPerSec;
            end
        end

        function r = velFromDisplay(obj, displayVal)
            % Convert GUI angular velocity to internal (rad/s).
            if strcmpi(obj.AngleUnit, 'degree')
                r = displayVal * pi / 180;
            else
                r = displayVal;
            end
        end

        function refreshStateDisplay(obj)
            % Update state edit fields and labels to current AngleUnit (InitialState always in rad).
            if strcmpi(obj.AngleUnit, 'degree')
                obj.StateLabels.th1.Text = 'Initial θ1 (°, from vertical)';
                obj.StateLabels.th2.Text = 'Initial θ2 (°, from vertical)';
                obj.StateLabels.w1.Text = 'Initial ω1 (°/s)';
                obj.StateLabels.w2.Text = 'Initial ω2 (°/s)';
            else
                obj.StateLabels.th1.Text = 'Initial θ1 (rad, from vertical)';
                obj.StateLabels.th2.Text = 'Initial θ2 (rad, from vertical)';
                obj.StateLabels.w1.Text = 'Initial ω1 (rad/s)';
                obj.StateLabels.w2.Text = 'Initial ω2 (rad/s)';
            end
            obj.StateEdits.th1.Value = num2str(obj.angleToDisplay(obj.InitialState(1)));
            th2Abs = obj.InitialState(1) + obj.InitialState(2);
            obj.StateEdits.th2.Value = num2str(obj.angleToDisplay(th2Abs));
            obj.StateEdits.w1.Value = num2str(obj.velToDisplay(obj.InitialState(3)));
            obj.StateEdits.w2.Value = num2str(obj.velToDisplay(obj.InitialState(4)));
        end

        function doClose(obj)
            % Read current GUI values into properties before figure is destroyed (so main gets selection)
            obj.SolverType = string(obj.SolverDropdown.Value);
            obj.AngleUnit = string(obj.AngleUnitDropdown.Value);
            stepVal = str2double(obj.StepSizeEdit.Value);
            if ~isnan(stepVal) && stepVal > 0
                obj.StepSize = stepVal;
            end
            ts = sscanf(obj.TimeSpanEdit.Value, '%f', [1 2]);
            if numel(ts) >= 2
                obj.TimeSpan = [ts(1) ts(2)];
            end
            for fn = {'m1', 'm2', 'L1', 'L2', 'g', 'beta1', 'beta2'}
                v = str2double(obj.ParamEdits.(fn{1}).Value);
                if ~isnan(v), obj.Params.(fn{1}) = v; end
            end
            % Both fields are angles from vertical (absolute), in current display unit; convert to rad for dynamics
            v1 = str2double(obj.StateEdits.th1.Value);
            v2 = str2double(obj.StateEdits.th2.Value);
            if ~isnan(v1), obj.InitialState(1) = obj.angleFromDisplay(v1); end
            if ~isnan(v2), obj.InitialState(2) = obj.angleFromDisplay(v2) - obj.InitialState(1); end
            % Read initial angular velocities
            vw1 = str2double(obj.StateEdits.w1.Value);
            vw2 = str2double(obj.StateEdits.w2.Value);
            if ~isnan(vw1), obj.InitialState(3) = obj.velFromDisplay(vw1); end
            if ~isnan(vw2), obj.InitialState(4) = obj.velFromDisplay(vw2); end
            delete(obj.Fig);
        end
    end
end
