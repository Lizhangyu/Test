function T = find_blob(T, frame)
% FIND_BLOBS - simple recognizer of targets largest foreground bounding boxes.
%
% NOTE: This function is intended to be run as a RECOGNIZER in the
% tracking framework.  See documentation for RUN_TRACKER.
%
% FIND_BLOBS(T, frame) will recognize foreground objects in the
% current image 'frame'.  The blobs detected in the image are
% stored in T.recognizer.blobs.
%
% Parameters set in T.recognizer:
%  T.recognizer.blobs - the blobs detected in the foreground of frame.
% 
% Inputs:
%  T     - tracker state structure.
%  frame - image to process.
% 
% See also: run_tracker
%
T.recognizer.blobs = bwlabel(T.segmenter.segmented);
return