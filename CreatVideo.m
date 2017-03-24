function CreatVideo(filaname)
vid = videoinput('winvideo', 1, 'MJPG_640x480');
writerObj = VideoWriter( [filaname '.avi'] );
writerObj.FrameRate = 20;
open(writerObj);
figure;
for ii = 1: 10
    frame = getsnapshot(vid);
    imshow(frame);
    f.cdata = frame;
    f.colormap = [];
    writeVideo(writerObj,f);
end
close(writerObj);