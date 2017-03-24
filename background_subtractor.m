function T = background_subtractor(T, frame)
% BACKGROUND_SUBTRACTOR - simple image differencing foreground segmentation.
%
% NOTE: This function is intended to be run as a SEGMENTER in the
% tracking framework.  See documentation for RUN_TRACKER.
%
% BACKGROUND_SUBTRACTOR(T, frame) processes image 'frame',
% segmenting it and storing the segmented image in
% T.segmenter.segmented.  The background model in T.segmenter is
% updated and the current background image stored in
% T.segmenter.background.
%
% Parameters used from T.segmenter:
%  T.segmenter.gamma  - update rate for background model.
%  T.segmenter.tau    - threshold for fore/background segmentation.
%  T.segmenter.radius - radius of closing used on foreground mask.
%
% Inputs:
%  T     - tracker state structure.
%  frame - image to process.

% Do everything in grayscale.
frame_grey = double(rgb2gray(frame));

% Check to see if we're initialized
if ~isfield(T.segmenter, 'background');
  T.segmenter.background = frame_grey
end

% Pull local state out.
gamma  = T.segmenter.gamma;
tau    = T.segmenter.tau;
radius = T.segmenter.radius;

% Rolling average update.
T.segmenter.background = gamma * frame_grey + (1 - gamma) * ...
    T.segmenter.background;

% And threshold to get the foreground.
T.segmenter.segmented = abs(T.segmenter.background - frame_grey) > tau;
T.segmenter.segmented = imclose(T.segmenter.segmented, strel('disk', radius));

return