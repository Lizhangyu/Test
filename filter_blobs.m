function T = filter_blobs(T, frame_)
% FILTER_BLOBS - simple representer of targets as largest foreground bounding box.
%
% NOTE: This function is intended to be run as a REPRESENTER in the
% tracking framework.  See documentation for RUN_TRACKER.
%
% FILTER_BLOBS(T, frame) will represent the measurement for the
% frame in image 'frame' as the bounding box of the largest
% detected blob in the foreground of the frame.
%
% Parameters used from T.recognizer:
%  T.recognizer.blobs - the blobs detected in the foreground of frame.
% 
% Inputs:
%  T     - tracker state structure.
%  frame - image to process.
% 
% See also: run_tracker

% Make sure at lease one blob was recognized
if sum(sum(T.recognizer.blobs))
  % Extract the BoundingBox and Area of all blobs
  R = regionprops(T.recognizer.blobs, 'BoundingBox', 'Area');
  
  % And only keep the biggest one
  [I, IX] = max([R.Area]);
  T.representer.BoundingBox = R(IX(size(IX,2))).BoundingBox;
end

% %%
% faceDetector = vision.CascadeObjectDetector(); % Finds faces by default
% tracker = MultiObjectTrackerKLT;
% 
% bboxes = [];
% while isempty(bboxes)
%     framergb = frame_;
%     frame = rgb2gray(framergb);
%     bboxes = faceDetector.step(frame);
% end
% 
% tracker.addDetections(frame, bboxes);
% tt = sum(tracker.Bboxes(:,3:4),2);
% tt = find(tt==max(tt));
% T.representer.BoundingBox = tracker.Bboxes(tt,:);

return