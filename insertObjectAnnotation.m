function RGB = insertObjectAnnotation(I, shape, position, label, varargin)
%insertObjectAnnotation Insert annotation in image or video stream.
%  This function inserts labels and corresponding circles or rectangles
%  into an image or video. You can use it with either a grayscale or 
%  truecolor image input.
%
%  RGB = insertObjectAnnotation(I, SHAPE, POSITION, LABEL) returns a
%  truecolor image annotated with SHAPE and LABEL. The input image, I, can
%  be either a truecolor or grayscale image. The shape can be set to
%  'rectangle' or 'circle' and inserted at the location specified by the
%  matrix, POSITION. The input LABEL can be a numeric vector of length M or
%  a cell array of ASCII strings of length M, where M is the number of
%  shape positions. A single label can also be specified for all shapes as
%  a numeric scalar or string.
%
%  insertObjectAnnotation(I, 'rectangle', POSITION, LABEL) inserts
%  rectangles and corresponding labels at the location indicated by the
%  position matrix. The POSITION must be an M-by-4 matrix, where each row,
%  M, specifies a rectangle as a four-element vector, [x y width height].
%  The elements, x and y indicate the upper-left corner of the rectangle,
%  and the width and height specify the size.
%
%  insertObjectAnnotation(I, 'circle', POSITION, LABEL) inserts circles and
%  corresponding labels at the location indicated by the position matrix.
%  The POSITION must be an M-by-3 matrix, where each row specifies a
%  three-element vector [x y r].  The elements, x and y indicate the center
%  of the circle and r specifies the radius.
%
%  RGB = insertObjectAnnotation(I, SHAPE, POSITION, LABEL, Name, Value)
%  specifies additional name-value pair arguments described below:
% 
%  'Color'           Color for the shape and label text box. You can
%                    specify a different color for each shape, or one color
%                    for all the shapes.
%                    - To specify a color for each shape, set 'Color' to a
%                      cell array of M strings or an M-by-3 matrix of RGB
%                      values.
%                    - To specify one color for all shapes, set 'Color' to
%                      either a string or an [R G B] vector.
%                    RGB values must be in the range of the image data
%                    type. Supported color strings are, 'blue', 'green',
%                    'red', 'cyan', 'magenta', 'yellow', 'black', 'white'
%
%                    Default: 'yellow'
% 
%  'TextColor'       Color of text labels. Specify the color of text labels
%                    in the same way as the 'Color' input.
%   
%                    Default: 'black'
%
%  'TextBoxOpacity'  A scalar defining the opacity of the background of the
%                    label text box. Specify this value in the range of 0
%                    to 1.
%                         
%                    Default: 0.6
%
%  'FontSize'        Font size, specified in points, as an integer in the
%                    range of 8 to 72.
%
%                    Default: 12
%
%  Class Support
%  -------------
%  The class of input I can be uint8, uint16, int16, double, single. Output
%  RGB matches the class of I.
%
%  Example 1: Object annotation with integer numbers
%  -------------------------------------------------
%  I = imread('coins.png');
%  position = [96 146 31;236 173 26];% center (x,y) and radius of the circle
%  label = [5 10]; % U.S. 5-cent and 10-cent coins
% 
%  RGB = insertObjectAnnotation(I, 'circle', position, label, ...
%           'Color', {'cyan', 'yellow'}, 'TextColor', 'black');
%  figure, imshow(RGB), title('Annotated coins');
%
%  Example 2: Object annotation with numbers and strings
%  -----------------------------------------------------
%  I = imread('board.tif');
%  % Create labels with floating point numbers
%  label_str = cell(3,1);
%  conf_val = [85.212 98.76 78.342];% Detection confidence
%  for ii=1:3
%     label_str{ii} = ['Confidence: ' num2str(conf_val(ii),'%0.2f') '%'];
%  end
%  position = [23 373 60 66;35 185 77 81;77 107 59 26];%[x y width height]
% 
%  RGB = insertObjectAnnotation(I, 'rectangle', position, label_str, ...
%        'TextBoxOpacity', 0.9, 'FontSize', 18);
%  figure, imshow(RGB), title('Annotated chips');
%
%  See also insertText, insertShape, insertMarker

%%
persistent cache % cache for storing System Objects

%% == Parse inputs and validate ==
narginchk(4,12);
 
[RGB, shape, position, label, color, textColor, ...
    textBoxOpacity, fontSize, isEmpty, isLabelNumeric] = ...
    validateAndParseInputs(I, shape, position, label, varargin{:});

% handle empty I or empty position
if isEmpty    
    return;
end
%% == Setup System Objects ==
[textInserter, boxInserter, cache] = getSystemObjects(shape, ...
    textBoxOpacity, fontSize, class(I), isLabelNumeric, cache);

%% == Output ==
% insert shape
RGB = boxInserter.step(RGB, position, color);
% insert text and its background
tuneOpacity(textInserter, textBoxOpacity);
textAndTextBoxColor = [textColor color];
textLocAndWidth = getTextLocAndWidth(shape, position);
textLocWidthAlignment = appendAlignment(textLocAndWidth); 
RGB = textInserter.step(RGB,label,textAndTextBoxColor,textLocWidthAlignment);

%==========================================================================
% Parse inputs and validate
%==========================================================================
function [RGB, shape,position,outLabel,color,textColor,...
    textBoxOpacity,fontSize,isEmpty,isLabelNumeric] = ...
    validateAndParseInputs(I, shape, position, label, varargin)

%--input image--
checkImage(I);
RGB = convert2RGB(I);
inpClass = class(I);

%--shape--
shape = validatestring(shape,{'rectangle','circle'}, mfilename,'SHAPE', 2);

%--position--
% position data type does not depend on input data type
validateattributes(position, {'numeric'}, ...
    {'real','nonsparse', '2d', 'finite'}, mfilename,'POSITION', 3);
position = int32(position);
numShapes = size(position, 1);

%--isEmpty--
isEmpty = isempty(I) || isempty(position);

if isEmpty    
    [outLabel,color,textColor,textBoxOpacity,fontSize,isLabelNumeric] = ...
                                                  deal([],[],[],[],[],[]);
else
    %--label--
    checkLabel(label);
    isLabelNumeric = isnumeric(label);
    % label conversion:
    %    string label is converted to uint8 vector required by
    %    vision.TextInserter
    %    scalar label is repeated
    [numLabels, outLabel] = getLabels(label, numShapes);

    %--other optional parameters--
    [color, textColor, textBoxOpacity, fontSize] = ...
                         validateAndParseOptInputs(inpClass,varargin{:});     
    crossCheckInputs(shape, position, numLabels, color, textColor);
    color = getColorMatrix(inpClass, numShapes, color);
    textColor = getColorMatrix(inpClass, numShapes, textColor);
end

%==========================================================================
function [color, textColor, textBoxOpacity, fontSize] = ...
                               validateAndParseOptInputs(inpClass,varargin)
% Validate and parse optional inputs

defaults = getDefaultParameters(inpClass);
% Setup parser
parser = inputParser;
parser.CaseSensitive = false;
parser.FunctionName  = mfilename;

parser.addParamValue('Color', defaults.Color);
parser.addParamValue('TextColor', defaults.TextColor);
parser.addParamValue('TextBoxOpacity', defaults.TextBoxOpacity, ...
                     @checkTextBoxOpacity);
parser.addParamValue('FontSize', defaults.FontSize, @checkFontSize);

%Parse input
parser.parse(varargin{:});

color          = checkColor(parser.Results.Color, 'Color');
textColor      = checkColor(parser.Results.TextColor, 'TextColor');
textBoxOpacity = double(parser.Results.TextBoxOpacity);
fontSize       = double(parser.Results.FontSize);

%==========================================================================
function checkImage(I)
% Validate input image

validateattributes(I,{'uint8', 'uint16', 'int16', 'double', 'single'}, ...
    {'real','nonsparse'}, mfilename, 'I', 1)
% input image must be 2d or 3d (with 3 planes)
if (ndims(I) > 3) || ((size(I,3) ~= 1) && (size(I,3) ~= 3))
    error(message('vision:dims:imageNot2DorRGB'));
end

%==========================================================================
function checkLabel(label)
% Validate label

if isnumeric(label)
   validateattributes(label, {'numeric'}, ...
       {'real', 'nonsparse', 'nonnan', 'finite', 'nonempty', 'vector'}, ...
       mfilename, 'LABEL');  
else
    if ischar(label)
        validateattributes(label,{'char'}, {'nonempty'}, ...
                                                      mfilename, 'LABEL');        
        label = {label};
    else
        validateattributes(label,{'cell'}, {'nonempty', 'vector'}, ...
                                                      mfilename, 'LABEL');
        allLabelCellsChar = all(cellfun(@ischar,label));
        if  ~allLabelCellsChar
          error(message('vision:insertObjectAnnotation:labelCellNonChar'));
        end                                                  
    end
    % 'my\nname' is fine; sprintf('my\nname') is not accepted
    newLineIdx = strfind(label, sprintf('\n'));
    hasNewLine = ~isempty([newLineIdx{1:end}]);
    %
    carriageRetIdx = strfind(label, sprintf('\r'));    
    hasCarriageRet = ~isempty([carriageRetIdx{1:end}]);
    
    if (hasNewLine || hasCarriageRet)
        error(message('vision:insertObjectAnnotation:labelNewLineCR'));
    end
end

%==========================================================================
function crossCheckInputs(shape, position, numLabels, color, textColor)
% Cross validate inputs

[numRowsPositions, numColsPositions] = size(position); 
numPtsForShape = getNumPointsForShape(shape);
numShapeColors = getNumColors(color);
numTextColors  = getNumColors(textColor);

% cross check shape and position (cols)
if (numPtsForShape ~= numColsPositions)
    % size of position: for rectangle Mx4, for circle Mx3
    error(message('vision:insertObjectAnnotation:invalidNumColPos'));
end    

% cross check label and position (rows)
if (numLabels ~=1) && (numLabels ~= numRowsPositions)
    error(message('vision:insertObjectAnnotation:invalidNumLabels'));
end

% cross check color and position (rows). Empty color is caught here
if (numShapeColors ~= 1) && (numRowsPositions ~= numShapeColors)
    error(message('vision:insertObjectAnnotation:invalidNumPosNumColor'));
end

% cross check text color and position (rows). Empty color is caught here
if (numTextColors ~= 1) && (numRowsPositions ~= numTextColors)
    error(message('vision:insertObjectAnnotation:invalidNumPosNumColor'));
end

%==========================================================================
function color = getColorMatrix(inpClass, numShapes, color)

color = colorRGBValue(color, inpClass);
if (size(color, 1)==1)
    color = repmat(color, [numShapes 1]);
end

%==========================================================================
function numPts = getNumPointsForShape(shape)
switch shape
    case 'rectangle'
        numPts = 4;% rectangle: [x y width height]
    case 'circle'
        numPts = 3;% circle: [x y radius]
end

%==========================================================================
function numColors = getNumColors(color)

% Get number of colors
numColors = 1;
if isnumeric(color)
    numColors = size(color,1);
elseif iscell(color) % if color='red', it is converted to cell earlier
    numColors = length(color);
end

%==========================================================================
function defaults = getDefaultParameters(inpClass)

% Get default values for optional parameters
% default color 'black', default text color 'yellow'
black = [0 0 0]; 
switch inpClass
   case {'double', 'single'}
       yellow = [1 1 0];  
   case 'uint8'
       yellow = [255 255 0];  
   case 'uint16'
       yellow = [65535  65535  0];          
   case 'int16'
       yellow = [32767  32767 -32768];
       black = [-32768  -32768  -32768];         
end
       
defaults = struct(...
    'Color', yellow, ... 
    'TextColor',  black, ... 
    'TextBoxOpacity', 0.6,...
    'FontSize', 12);

%==========================================================================
function colorOut = checkColor(color, paramName) 
% Validate 'Color' or 'TextColor'

% Validate color
if isnumeric(color)
   % must have 6 columns
   validateattributes(color, ...
       {'uint8','uint16','int16','double','single'},...
       {'real','nonsparse','nonnan', 'finite', '2d', 'size', [NaN 3]}, ...
       mfilename, paramName);
   colorOut = color;
else
   if ischar(color)
       colorCell = {color};
   else
       validateattributes(color, {'cell'}, {}, mfilename, 'Color');
       colorCell = color;
   end
   supportedColorStr = {'blue','green','red','cyan','magenta', ...
                        'yellow','black','white'};
   numCells = length(colorCell);
   colorOut = cell(1, numCells);
   for ii=1:numCells
       colorOut{ii} =  validatestring(colorCell{ii}, ...
                                  supportedColorStr, mfilename, paramName);
   end
end

%==========================================================================
function tf = checkTextBoxOpacity(opacity)
% Validate 'TextBoxOpacity'

validateattributes(opacity, {'numeric'}, {'nonempty', 'nonnan', ...
    'finite', 'nonsparse', 'real', 'scalar', '>=', 0, '<=', 1}, ...
    mfilename, 'TextBoxOpacity');
tf = true;

%==========================================================================
function tf = checkFontSize(FontSize)
% Validate 'FontSize'

validateattributes(FontSize, {'numeric'}, ...
    {'nonempty', 'integer', 'nonsparse', 'scalar', '>=', 8, '<=', 72}, ...
    mfilename, 'FontSize');
tf = true;

%==========================================================================
function sizeTI = getCacheSizeForTextInserter()
% Text inserter object needs to be created for the following
% parameters:
% first: input data types: 'double','single','uint8','uint16','int16'
% second: font size: 8:72 (length(8:72) = 65)
% third: label type: number or string

numInDTypes   = 5;
numFontSizes  = 65; 
numLabelTypes = 2;

sizeTI = [numInDTypes numFontSizes numLabelTypes];

%==========================================================================
function sizeBI = getCacheSizeForBoxInserter()
% Shape inserter object needs to be created for the following
% parameters:
% first: input data types: 'double','single','uint8','uint16','int16'
% second: shape type: 'rectangle' or 'circle'

numInDTypes = 5;
numShapes   = 2;
sizeBI = [numInDTypes numShapes];  
  
%==========================================================================  
function textLocAndWidth = getTextLocAndWidth(shape, position)
% This function computes the text location and the width of the shape
% Text location:
%   * It is the bottom-left corner (x,y) of the label text box
%   * Label text box is left aligned with shape
%   * Since label text box is placed above the shape (i.e., bottom border
%     of the label text box touches the top-most point of the shape), 
%     (x, y) is computed as follows:
%     For 'rectangle' shape, (x, y) is the top-left corner of the shape
%     For 'circle' shape, (x, y) is the top-left corner of the rectangle
%     that encloses the shape (circle)
% Width of label text box:
%   * For 'rectangle' shape, Width of label text box = width of rectangle
%   * For 'circle' shape, Width of label text box = diameter of circle

switch shape
    case 'rectangle'
        % position must not be a column vector
        % [x y width]
        textLocAndWidth = position(:,1:4);         
        textLocAndWidth(:,2) = textLocAndWidth(:,2) - int32(1);
    case 'circle'
        % [x y width] = [center_x-radius center_y-radius-1 2*radius+1]
        textLocAndWidth = [position(:,1)-position(:,3) ...
                           position(:,2)-position(:,3) - int32(1) ...
                           2*position(:,3)+1, ...
                           2*position(:,3)+1];
        
end

%==========================================================================  
function textLocWidthAlignment = appendAlignment(textLocAndWidth)

% reference position is LEFT_BOTTOM =2 (in S-function)
lastCol = repmat(cast(2, class(textLocAndWidth)),[size(textLocAndWidth,1) 1]);
textLocWidthAlignment = [textLocAndWidth lastCol];

%========================================================================== 
function tuneOpacity(textInserter, textBoxOpacity)

if (textBoxOpacity ~= textInserter.Opacity(2))
    textInserter.Opacity = [1 textBoxOpacity];
end

%========================================================================== 
function inRGB = convert2RGB(I)

if ismatrix(I)
    inRGB = cat(3, I , I, I);
else
    inRGB = I;
end

%==========================================================================
function outColor = colorRGBValue(inColor, inpClass)

if isnumeric(inColor)
    outColor = cast(inColor, inpClass);
else    
    if iscell(inColor)
        textColorCell = inColor;
    else
        textColorCell = {inColor};
    end

   numColors = length(textColorCell);
   outColor = zeros(numColors, 3, inpClass);

   for ii=1:numColors
    supportedColorStr = {'blue','green','red','cyan','magenta','yellow',...
                         'black','white'};  
    % http://www.mathworks.com/help/techdoc/ref/colorspec.html
    colorValuesFloat = [0 0 1;0 1 0;1 0 0;0 1 1;1 0 1;1 1 0;0 0 0;1 1 1];                    
    idx = strcmp(textColorCell{ii}, supportedColorStr);
    switch inpClass
       case {'double', 'single'}
           outColor(ii, :) = colorValuesFloat(idx, :);
       case {'uint8', 'uint16'} 
           colorValuesUint = colorValuesFloat*double(intmax(inpClass));
           outColor(ii, :) = colorValuesUint(idx, :);
       case 'int16'
           colorValuesInt16 = im2int16(colorValuesFloat);
           outColor(ii, :) = colorValuesInt16(idx, :);           
    end
   end
end

%==========================================================================
function label = cell2labels(origLabels, numShapes)
% This function converts the string to uint8 vector required by
% vision.TextInserter System Object

label = uint8(origLabels{1});
if (length(origLabels)==1)
    for i = 2: numShapes   
        label = [uint8(label) 0 uint8(origLabels{1})];
    end    
else
    for i = 2: length(origLabels)    
        label = [uint8(label) 0 uint8(origLabels{i})];
    end
end

%==========================================================================
function [numLabels, label] = getLabels(label, numShapes)

numLabels = length(label);
if isnumeric(label)
   if (numLabels==1)
       label = repmat(double(label), [1  numShapes]);
   else
       label = double((label(:))');        
   end
else
   if ischar(label)
       label = {label};
       numLabels = 1;
   end
   label = cell2labels(label, numShapes);
end

%==========================================================================
% Setup System Objects
%==========================================================================
function [textInserter, boxInserter, cache] = getSystemObjects(shape, ...
    textBoxOpacity, fontSize, inpClass, isLabelNumeric, cache)

if isempty(cache)
    cache.textInserterObjects = cell(getCacheSizeForTextInserter());
    cache.boxInserterObjects  = cell(getCacheSizeForBoxInserter());
end

fontSizeIdx  = fontSize-8+1;% 8=supportedFontSizes(1)
inDTypeIdx   = getDTypeIdx(inpClass);
shapeIdx     = getShapeIdx(shape);
labelTypeIdx = getLabelTypeIdx(isLabelNumeric);

if isempty(cache.textInserterObjects{inDTypeIdx,fontSizeIdx,labelTypeIdx})
    if (labelTypeIdx==1)
        % integer vector
        formatSpecifier = '%0.5g'; 
    else
        % strings (in fact, uint8-separated by uint8('0')=48)
        formatSpecifier = '%s';  
    end
        
    % create the TextInserter
    textInserter = vision.TextInserter( ...
                     'Text',formatSpecifier,'Antialiasing',true, ...
                     'ColorSource', 'Input port', ...
                     'LocationSource','Input port',...
                     'OpacitySource', 'Property', ...
                     'Opacity', [1 double(textBoxOpacity)], ...
                     'FontSize', double(fontSize), ...
                     'isTextBackgroundMode', 1);
    
    % cache the TextInserter object in cell array
    cache.textInserterObjects{inDTypeIdx, fontSizeIdx, labelTypeIdx} = ...
        textInserter;
else
    % point to the existing object
    textInserter = cache.textInserterObjects{inDTypeIdx, fontSizeIdx, ...
                                              labelTypeIdx};
end

if isempty(cache.boxInserterObjects{inDTypeIdx, shapeIdx})
    shapeForSI = mapShapeForShapeInserter(shape);
    % create the ShapeInserter object
    boxInserter  = vision.ShapeInserter('Shape', shapeForSI, ...
        'BorderColorSource','Input port');
    % cache the ShapeInserter object in cell array
    cache.boxInserterObjects{inDTypeIdx, shapeIdx} = boxInserter;
else
    % point to the existing object
    boxInserter = cache.boxInserterObjects{inDTypeIdx, shapeIdx};    
end

%==========================================================================
function dtIdx = getDTypeIdx(dtClass)

switch dtClass
    case 'double',
        dtIdx = 1;
    case 'single',
        dtIdx = 2;
    case 'uint8',
        dtIdx = 3;
    case 'uint16',
        dtIdx = 4;
    case 'int16',
        dtIdx = 5;
end

%==========================================================================
function shapeIdx = getShapeIdx(shape)

switch shape
    case 'rectangle'
        shapeIdx = 1;
    case 'circle'
        shapeIdx = 2;
end

%==========================================================================
function shapeForSI = mapShapeForShapeInserter(shape)

switch shape
    case 'rectangle'
        shapeForSI = 'Rectangles';
    case 'circle'
        shapeForSI = 'Circles';
end

%==========================================================================
function labelTypeIdx = getLabelTypeIdx(isLabelNumeric)

if (isLabelNumeric)
    labelTypeIdx = 1;
else
    labelTypeIdx = 2;
end
