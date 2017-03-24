%% detectAndTrackFaces
% Automatically detects and tracks multiple faces in a webcam-acquired
% video stream.
%
% Copyright 2013-2014 The MathWorks, Inc 

clear all;
close all;
clc;

%% Instantiate video device, face detector, and KLT object tracker
vidObj = webcam;

faceDetector = vision.CascadeObjectDetector(); % Finds faces by default
tracker = MultiObjectTrackerKLT;

%% Get a frame for frame-size information
frame = snapshot(vidObj);
frameSize = size(frame);

%% Create a video player instance
videoPlayer  = vision.VideoPlayer('Position',[200 100 fliplr(frameSize(1:2)+30)]);

%% Iterate until we have successfully detected a face
bboxes = [];
while isempty(bboxes)
    framergb = snapshot(vidObj);
    frame = rgb2gray(framergb);
    bboxes = faceDetector.step(frame);
end
tracker.addDetections(frame, bboxes);

%% And loop until the player is closed
frameNumber = 0;
keepRunning = true;
disp('Press Ctrl-C to exit...');
while keepRunning
    
    framergb = snapshot(vidObj);
    frame = rgb2gray(framergb);
    
    if mod(frameNumber, 10) == 0
        % (Re)detect faces.
        %
        % NOTE: face detection is more expensive than imresize; we can
        % speed up the implementation by reacquiring faces using a
        % downsampled frame:
        % bboxes = faceDetector.step(frame);
        bboxes = 2 * faceDetector.step(imresize(frame, 0.5));
        if ~isempty(bboxes)
            tracker.addDetections(frame, bboxes);
        end
    else
        % Track faces
        tracker.track(frame);
    end
    
    % Display bounding boxes and tracked points.
    displayFrame = insertObjectAnnotation(framergb, 'rectangle',...
        tracker.Bboxes, tracker.BoxIds);
    displayFrame = insertMarker(displayFrame, tracker.Points);
    
    % add the center point
    tb = tracker.Bboxes;
    for ii=1:size(tb,1)
        centerPoint = [tb(ii,1)+tb(ii,3)/2 tb(ii,2)+tb(ii,4)/2]
        displayFrame = insertMarker(displayFrame, centerPoint,'o','color','red','size',8);
    end
    
    videoPlayer.step(displayFrame);
    
    frameNumber = frameNumber + 1;
end

%% Clean up
release(videoPlayer);