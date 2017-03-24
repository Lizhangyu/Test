function T = visualize_kalman(T, frame)
% VISUALIZE_KALMAN - a visualizer for a Kalman filter tracker.
%
% NOTE: This function is intended to be run as a VISUALIZER in the
% tracking framework.  See documentation for RUN_TRACKER.
%
% VISUALIZE_KALMAN(T, frame) displays the current image in 'frame',
% along with the measurement and current tracker estimate in a
% figure window.
%
% See also: kalman_tracker, run_tracker.

% Initialize the figure and setup pause callback.
if ~isfield(T.visualizer, 'init');
  figure;
  h = gcf;
  set(h, 'KeyPressFcn', {@pauseHandler, h});
  setappdata(h, 'paused', false);
  T.visualizer.init = true;
end

% Display the current frame.
image(frame);

% Draw the current measurement in red.
if isfield(T.representer, 'BoundingBox')
    tb = T.representer.BoundingBox;
    if tb
        rectangle('Position', tb, 'EdgeColor', 'r');
    end
end

% And the current prediction in green
if isfield(T.tracker, 'm_k1k1');
  rectangle('Position', T.tracker.m_k1k1, 'EdgeColor', 'g');
end
drawnow;

% If we're paused, wait (but draw).
while (getappdata(gcf, 'paused'))
  drawnow;
end
return

% This is a callback function that toggles the pause state.
function pauseHandler(a, b, h)
setappdata(h, 'paused', xor(getappdata(h, 'paused'), true));
return

