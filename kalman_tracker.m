function T = kalman_tracker(fname, gamma, tau, radius)
% KALMAN_TRACKER - A zero-order Kalman filter tracker.
%
% KALMAN_TRACKER(fname, g, tau, r) runs the tracker on video
% specified by fname, with background subtraction parameters g, tau
% and radius.
%
% Inputs:
%  fname   - filename of video to process.
%  gamma   - gamma parameter for background subtraction.
%  tau     - tau parameter for backgroun subtraction.
%  radius  - radius for closing in background subtraction.

% Initialize background model parameters
Segmenter.gamma   = gamma;
Segmenter.tau     = tau;
Segmenter.radius  = radius;
Segmenter.segment = @background_subtractor;

% Recognizer and representer is a simple blob finder.
Recognizer.recognize = @find_blob;
Representer.represent = @filter_blobs;

% The tracker module.
Tracker.H          = eye(4);        % System model
Tracker.Q          = 0.5 * eye(4);  % System noise
Tracker.F          = eye(4);        % Measurement model
Tracker.R          = 5 * eye(4);    % Measurement noise
Tracker.innovation = 0;
Tracker.track      = @kalman_step;

% A custom visualizer for the Kalman state.
Visualizer.visualize = @visualize_kalman;
Visualizer.paused    = false;

% Set up the global tracking system.
T.segmenter   = Segmenter;
T.recognizer  = Recognizer;
T.representer = Representer;
T.tracker     = Tracker;
T.visualizer  = Visualizer;

% And run the tracker on the video.
run_tracker(fname, T);
return
