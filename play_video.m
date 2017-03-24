function play_video(fname);
% PLAY_VIDEO - simple function to play a video in a Matlab figure.
%
% PLAY_VIDEO(fname) will play the video in the file specified by
% 'fname'.
%
% See also: videoReader, nextFrame, getFrame
vr = videoReader(fname);
while (nextFrame(vr))
  img = getFrame(vr);  
  imshow(img);
  pause(0.01);
end  
return