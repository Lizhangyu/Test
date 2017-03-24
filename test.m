%%
%   By ZhangyuLi,1/7/2017
%   object tracking test in webcam
%
%%
% clear all;
close all;
clc;
dbstop if error

gamma = 0.05;tau = 50;radius = 3;
% vid = videoinput('winvideo', 1, 'MJPG_640x480');
% preview(vid);
% start(vid);
    
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
C = 2;%1Ϊ�ʼǱ����� 2Ϊ�ƶ�����ͷ����
[~,instructs] = runTracker(T,C,0.3,30);

% while true     %�ж��Ƿ���Ч��ͼ�������
%     frame=getsnapshot (vid);     % ����ͼ��
%     flushdata(vid);     %������ݻ�ȡ������������ݡ�������SamplesAvailableΪ0
% %     imshow(frame);             %��ʾͼ��
% %     drawnow;                   %ʵʱ����ͼ��
% end;
% delete(vid);

% kalman_tracker(frame, 0.05, 50, 3)
