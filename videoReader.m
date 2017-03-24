function r = videoReader(fname)
% videoReader - create a 'stateful' mmreader object.
%
% videoReader(fname) creates a mmreader object that uses the
% 'UserData' field of the structure to keep track of the current
% frame.
%
% See also: getFrame, nextFrame
    
r = VideoReader(fname);
set(r, 'UserData', 1);
return