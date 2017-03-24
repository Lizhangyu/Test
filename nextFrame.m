function r = nextFrame(reader)
% nextFrame - return true if there are frames remaining in a videoReader stream.    
% 
% nextFrame(reader) will return true if there are still frames to be
% read from the stream corresponding to videoReader 'reader'.  NOTE
% that this function will not work with a standard mmreader object, it
% MUST be created with the videoReader function so that the current
% frame is tracked.
% 
% See also: videoReader, getFrame, mmreader

r = get(reader, 'UserData') <= get(reader, 'NumberOfFrames');
return;
