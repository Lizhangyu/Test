function r = getFrame(reader)
% getFrame - read the next from from a stateful mmreader.
%
% getFrame(reader) will return the next frame in the stream
% corresponding to 'reader'.
%
% NOTE that this function will not work with a standard mmreader
% object, it MUST be created with the videoReader function so that the
% current frame is tracked.
% 
% See also: videoReader, nextFrame, mmreader
    frame = get(reader, 'UserData');
    r = read(reader, get(reader, 'UserData'));
    set(reader, 'UserData', frame + 1);
return