function [T,instructs] = runTracker(T,C,interval,angle)
% RUN_TRACKER - toplevel function for starting a tracker on a video.
%
% RUN_TRACKER(fname, T) will start the tracker represented by the
% structure T running on the video in the file specified by
% 'fname'. This function handles all video I/O and the threading of
% state through all of the tracking stages.
%
% In the structure T you may set components to be run:
%  T.segmenter   - the SEGMENTER for detecting foreground objects.
%  T.recognizer  - for recognizing targets among foreground objects.
%  T.representer - to represent the recognized target.
%  T.tracker     - to do the actual tracking.
%  T.visualizer  - to visualize the results.
%
% See kalman_tracker for a complete example.
%
% See also: kalman_tracker, find_blob, filter_blobs, kalman_step,
% visualize_kalman.

% vr = videoReader(fname);
if C==1
    video = webcam(1);
elseif C==2
    video = webcam(2);%��ʼ������ͷ����
    % instrfind
    s = serial('com4');
    fopen(s);
    fwrite(s,'15001500');%��ʼ����̨״̬
end

%% Face Detection and Tracking
faceDetector = vision.CascadeObjectDetector(); % Finds faces by default
tracker = MultiObjectTrackerKLT;%��ʼ��Ŀ������׷�ٷ���

%% Get a frame for frame-size information
frame = snapshot(video);
frameSize = size(frame);

%% Create a video player instance.
videoPlayer  = vision.VideoPlayer('Position',[200 100 fliplr(frameSize(1:2)+30)]);
% set(gcf,'keypress','k=get(gcf,''currentchar'');'); % listen keypress
height = frameSize(1);width = frameSize(2);
screenCenter = [width/2 height/2];

%% Iterate until we have successfully detected a face
bboxes = [];
while isempty(bboxes)
    framergb = snapshot(video);
    framegray = rgb2gray(framergb);
    bboxes = faceDetector.step(framegray);
end
tracker.addDetections(framegray, bboxes);

%%
% T.time         = 0;
T.frame_number = 0;
% T.fps          = getfield(get(vr), 'FrameRate');
% T.num_frames   = getfield(get(vr), 'NumberOfFrames');

% disp('Press q on any figure to exit')
% k=[];

xPara = 1500;yPara = 1500;%��ʼ���������
% xpara = 2000/width;ypara = 1000/height;
% xpara = (2000*(90/180))/width;ypara = 1000/height;%��ʼ������ת������
para = 2000/180;%��ʼ���Ƕ�ת������
distance = (width/2)/tan((angle/2)*pi/180);%����ͷ��Ŀ���ӳ�����,angleΪ����ͷ�Ƕ�
currentTime = cputime;

% while nextFrame(vr)
while T.frame_number<10000
    T.frame_number = T.frame_number + 1;
%     frame = getFrame(vr);
    frame = snapshot (video);%ѭ����ȡ��Ƶ֡

    if isfield(T, 'segmenter')
%         T = T.segmenter.segment(T, frame);
    end

    if isfield(T, 'recognizer')
%         T = T.recognizer.recognize(T, frame);
    end

    if isfield(T, 'representer')
%         T = T.representer.represent(T, frame);

        % Face Detection and Tracking
        framegray = rgb2gray(frame);
        if mod(T.frame_number, 10) == 0
            bboxes = 2 * faceDetector.step(imresize(framegray, 0.5));
            if ~isempty(bboxes)
                tracker.addDetections(framegray, bboxes);
            end
        else
            % Track faces
            tracker.track(framegray);%����Ŀ��ʶ���㷨
        end
        
        % only tracking the bigger face
        tb = tracker.Bboxes;%��ȡ����Ŀ���boundingBoxes
        if size(tb,1)>1
            tt = tb(:,3) .* tb(:,4);
            id = tt==max(tt);
            tb = tb(id,:);%ѡȡ���Ŀ����Ϊ����
        end

        % Display bounding boxes and tracker.Bboxes number and instruction.
        tb_nb = size(tb,1);%boundingBoxes number
        if tb_nb==1 %��ʾ���Ŀ��� boundingBoxes
            displayFrame = insertObjectAnnotation(frame, 'rectangle',tb, 1);
        else
            displayFrame = insertObjectAnnotation(frame, 'rectangle',...
                tracker.Bboxes, tracker.BoxIds);
        end
        
        % Display objectCenter piont with 'o'
        objectCenter = zeros(tb_nb,2);objectCoordinate = zeros(tb_nb,2);
        for ii=1:tb_nb
            %����Ŀ������λ��
            objectCenter(ii,:) = [tb(ii,1)+tb(ii,3)/2 tb(ii,2)+tb(ii,4)/2];
            %ת��Ϊ����ͼ�����ĵ�Ϊԭ�������
            objectCoordinate(ii,:) = [objectCenter(ii,1)-screenCenter(1) ...
                screenCenter(2)-objectCenter(ii,2)];
            %��ʾΪ��ԲȦ
            displayFrame = insertMarker(displayFrame, objectCenter(ii,:),...
                'o','color','red','size',8);
%             displayFrame = insertText(displayFrame,objectCenter(ii,:),...
%                 num2str(roundn(instruction(ii,:),-2)),'FontSize',10);
        end
        
        % relative pisition. Xrange[500 1500 2500] Yrange[500 1000 1500]
        if (cputime-currentTime)>interval%�ж�ʱ���Ƿ���ڼ��
            %����Ŀ������ת���������
            if objectCoordinate
                x = objectCoordinate(:,1);y = objectCoordinate(:,2);
                if abs(x)>30%������30px�ھͲ�Ҫ�ƶ���
%                     xPara = round(xPara - x * xpara/3);
                    xAngle = atan(x/distance)*180/pi;
                    xPara = round(xPara - xAngle * para);
                end
                if abs(y)>20%������20px�ھͲ�Ҫ�ƶ���
%                     yPara = round(yPara + y * ypara/3);
                    yAngle = atan(y/distance)*180/pi;
                    yPara = round(yPara + yAngle * para);
                end
            end

            % set the range in xPara and yPara 
            if xPara<500; xPara=500; end
            if xPara>2500; xPara=2500; end
            if yPara<500; yPara=500; end
            if yPara>1500; yPara=1500; end
            yPara=1500;

            % set the instructs
            if (xPara<1000) && (yPara<1000)
                instructs = ['0' num2str(xPara) '0' num2str(yPara)];
            elseif (xPara<1000) && (yPara>=1000)
                instructs = ['0' num2str(xPara) num2str(yPara)];
            elseif (xPara>=1000) && (yPara<1000)
                instructs = [num2str(xPara) '0' num2str(yPara)];
            elseif (xPara<=2500) && (yPara<=1500)
                instructs = [num2str(xPara) num2str(yPara)];
            end

            % if have objectCoordinate then give the instructs.
            if objectCoordinate
                displayFrame = insertText(displayFrame,objectCenter(ii,:),...
                    instructs,'FontSize',10);%��ʾָ��
                if C==2;fwrite(s,instructs);end %����ָ������
            end
            
            currentTime = cputime;%���µ�ǰʱ��
        end
        %��ʾͼ�����ĵ�
        displayFrame = insertMarker(displayFrame, screenCenter,'+',...
            'color','red','size',8);
        %���ͼ��
        videoPlayer.step(displayFrame);

        T.representer.BoundingBox = tb;
    end

    if isfield(T, 'tracker')
%         T = T.tracker.track(T, frame);
    end

    if isfield(T, 'visualizer')
%         T = T.visualizer.visualize(T, frame);
    end

%     T.time = T.time + 1/T.fps;

%     % If presses 'q', exit loop
%     if ~isempty(k)
%         if strcmp(k,'q'); break; end;
%     end
end

release(videoPlayer);
if C==2
    fclose(s)
    delete(s)
    clear s
end
