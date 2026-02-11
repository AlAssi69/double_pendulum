% playback_saved  Load a saved simulation from the results folder and run smooth playback.
% Use this to visualize a previous run without re-running the simulation.

clc;
clear;
close all force;

config = Utils.ConfigLoader.loadDefault();
resultsDir = config.ResultsDir;
if isempty(resultsDir) || ~isfolder(resultsDir)
    error('Results folder not found: %s. Run a simulation first to create it.', resultsDir);
end

% Find .mat files (most recent first)
d = dir(fullfile(resultsDir, 'double_pendulum_*.mat'));
if isempty(d)
    error('No saved results found in %s', resultsDir);
end
[~, ord] = sort([d.datenum], 'descend');
d = d(ord);
% Load most recent
fpath = fullfile(d(1).folder, d(1).name);
fprintf('Loading: %s\n', fpath);
results = load(fpath);

runSmoothPlayback(results, config);
