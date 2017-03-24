%%
%   By ZhangyuLi,1/18/2017
%   Moving Head Tracking System Based on Target Recognition
%
%%
clear all;
close all;
clc;
dbstop if error

angle = 30;
interval = 0.3;

%% initialization
video = webcam(2);%初始化摄像头对象
s = serial('com4');
fopen(s);
fwrite(s,'15001500');%初始化云台状态

faceDetector = vision.CascadeObjectDetector(); % Finds faces by default
tracker = MultiObjectTrackerKLT;%初始化目标检测与追踪方法

frame = snapshot(video);
frameSize = size(frame);

videoPlayer  = vision.VideoPlayer('Position',[200 100 ...
    fliplr(frameSize(1:2)+30)]);%初始化视频播放窗口对象
height = frameSize(1);width = frameSize(2);
screenCenter = [width/2 height/2];

%% Iterate until we have successfully detected a face
bboxes = [];
while isempty(bboxes)
    framergb = snapshot(video);
    frame = rgb2gray(framergb);
    bboxes = faceDetector.step(frame);
end
tracker.addDetections(frame, bboxes);

%% And loop until the player is closed
xPara = 1500;yPara = 1500;%初始化舵机参数
para = 2000/180;%初始化角度转换比例
distance = (width/2)/tan((angle/2)*pi/180);%摄像头到目标的映射距离,angle为摄像头角度

frameNumber = 0;
currentTime = cputime;

while frameNumber<500
    frameNumber = frameNumber + 1;
    framergb = snapshot(video);%循环读取视频帧
    frame = rgb2gray(framergb);
    
    if mod(frameNumber, 10) == 0
        bboxes = 2 * faceDetector.step(imresize(frame, 0.5));
        if ~isempty(bboxes)
            tracker.addDetections(frame, bboxes);
        end
    else
        % Track faces
        tracker.track(frame);%运行目标识别算法
    end
    
    % only tracking the bigger face
    tb = tracker.Bboxes;%获取所有目标的boundingBoxes
    if size(tb,1)>1
        tt = tb(:,3) .* tb(:,4);
        id = tt==max(tt);
        tb = tb(id,:);%选取最大目标作为对象
    end
    
    % Display bounding boxes and tracker.
    tb_nb = size(tb,1);%boundingBoxes number
    if tb_nb==1 %显示最大目标的 boundingBoxes
        displayFrame = insertObjectAnnotation(framergb, 'rectangle',tb, 1);
    else
        displayFrame = insertObjectAnnotation(framergb, 'rectangle',...
            tracker.Bboxes, tracker.BoxIds);
    end

    % Display objectCenter piont with 'o'
    objectCenter = zeros(tb_nb,2);objectCoordinate = zeros(tb_nb,2);
    for ii=1:tb_nb
        %计算目标中心位置
        objectCenter(ii,:) = [tb(ii,1)+tb(ii,3)/2 tb(ii,2)+tb(ii,4)/2];
        %转化为基于图像中心点为原点的坐标
        objectCoordinate(ii,:) = [objectCenter(ii,1)-screenCenter(1) ...
            screenCenter(2)-objectCenter(ii,2)];
        %显示为红圆圈
        displayFrame = insertMarker(displayFrame, objectCenter(ii,:),...
            'o','color','red','size',8);
    end
    
    % relative pisition. Xrange[500 1500 2500] Yrange[500 1000 1500]
    if (cputime-currentTime)>interval%set the time interval 
        %根据目标坐标转换舵机参数
        if objectCoordinate
            x = objectCoordinate(:,1);y = objectCoordinate(:,2);
            if abs(x)>30%横坐标30px内就不要移动了
                xAngle = atan(x/distance) * 180 / pi;
                xPara = round(xPara - xAngle * para);
            end
            if abs(y)>20%横坐标20px内就不要移动了
                yAngle = atan(y/distance) * 180 / pi;
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
                instructs,'FontSize',10);%显示指令
            fwrite(s,instructs);%传输指令给舵机
        end

        currentTime = cputime;%更新当前时间
    end
    
    displayFrame = insertMarker(displayFrame, screenCenter,'+',...
        'color','red','size',8);%显示图像中心点
    videoPlayer.step(displayFrame);%输出图像
end

%% Clean up
release(videoPlayer)
fclose(s)
delete(s)
clear s