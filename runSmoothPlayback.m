function runSmoothPlayback(results, config)
% runSmoothPlayback(results, config)  Visualize saved/in-memory time series at config.PlaybackFps.
% results: struct with .t, .states, .u, .params, and optionally .angleUnit.
% config: struct with .PlaybackFps, .PoincareXVar, .PoincareYVar.

    fps = 30;
    if nargin >= 2 && isfield(config, 'PlaybackFps') && config.PlaybackFps > 0
        fps = config.PlaybackFps;
    end
    dtFrame = 1 / fps;
    tVec = results.t;
    if isempty(tVec)
        return
    end
    tStart = tVec(1);
    tEnd = tVec(end);
    angleUnit = 'radian';
    if isfield(results, 'angleUnit') && ~isempty(results.angleUnit)
        angleUnit = results.angleUnit;
    end
    totalReach = results.params.L1 + results.params.L2;
    poincareX = 'theta1';
    poincareY = 'theta2';
    if nargin >= 2 && isfield(config, 'PoincareXVar'), poincareX = config.PoincareXVar; end
    if nargin >= 2 && isfield(config, 'PoincareYVar'), poincareY = config.PoincareYVar; end

    vizManager = Vis.VisualizerManager();
    vizManager.add(Vis.PendulumAnimator(angleUnit, totalReach));
    vizManager.add(Vis.StatePlotter(angleUnit));
    vizManager.add(Vis.PoincareMap('XVar', poincareX, 'YVar', poincareY, 'AngleUnit', angleUnit));

    playbackSim = Core.PlaybackSim(results);
    nFrames = max(1, round((tEnd - tStart) / dtFrame));
    for k = 0 : nFrames
        tPlay = tStart + (tEnd - tStart) * k / nFrames;
        if tPlay > tEnd, tPlay = tEnd; end
        playbackSim.Time = tPlay;
        vizManager.update(playbackSim);
        drawnow limitrate;
        if k < nFrames
            pause(dtFrame);
        end
    end
end
