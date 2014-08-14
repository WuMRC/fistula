

%% Quick optical flow example
videoReader = vision.VideoFileReader(...
    'viptraffic.avi','ImageColorSpace',...
    'Intensity','VideoOutputDataType','uint8');
converter = vision.ImageDataTypeConverter; 
shapeInserter = vision.ShapeInserter('Shape','Lines',...
    'BorderColor','Custom', 'CustomBorderColor', 255);
videoPlayer = vision.VideoPlayer('Name','Motion Vector');

% This is the key function to understand here
opticalFlow = vision.OpticalFlow('ReferenceFrameDelay', 1);
opticalFlow.OutputValue = ...
    'Horizontal and vertical components in complex form';

while ~isDone(videoReader)
    frame = step(videoReader);
    im = step(converter, frame);
    of = step(opticalFlow, im);
    lines = videooptflowlines(of, 20);
    if ~isempty(lines)
      out =  step(shapeInserter, im, lines); 
      step(videoPlayer, out);
    end
end

release(videoPlayer);
release(videoReader);


%% Quick point tracker example 
videoFileReader = vision.VideoFileReader('visionface.avi');
videoPlayer = vision.VideoPlayer('Position', [100, 100, 680, 520]);
objectFrame = step(videoFileReader);
objectRegion = [264, 122, 93, 93];

% Get region of interest
figure; imshow(objectFrame);
objectRegion=round(getPosition(imrect));

objectImage = insertShape(objectFrame, 'Rectangle', objectRegion,'Color', 'red'); 
figure; imshow(objectImage); title('Yellow box shows object region');

% Here we are detecting points automatically
% In the code we write we will declare these points either manually or
% through a selected region of interest
points = detectMinEigenFeatures(rgb2gray(objectFrame), 'ROI', objectRegion);
pointImage = insertMarker(objectFrame, points.Location, '+', 'Color', 'white');
figure, imshow(pointImage), title('Detected interest points');

% Create object tracker
tracker = vision.PointTracker('MaxBidirectionalError', 1);

% Initialize object tracker
initialize(tracker, points.Location, objectFrame);

% Show the points getting tracked
while ~isDone(videoFileReader)
      frame = step(videoFileReader);
      [points, validity] = step(tracker, frame);
      out = insertMarker(frame, points(validity, :), '+');
      step(videoPlayer, out);
end

release(videoPlayer);
release(videoFileReader);


%% Quick block matching example

% Get an image
img1 = im2double(rgb2gray(imread('onion.png')));

% Be able to translate the object
htran = vision.GeometricTranslator('Offset', [5 5], 'OutputSize', 'Same as input image');

% Create the block matching handle
blockSize = 35;
hbm = vision.BlockMatcher('ReferenceFrameSource', ...
    'Input port', 'BlockSize', [blockSize blockSize]);
hbm.OutputValue = ...
    'Horizontal and vertical components in complex form';

% Offset the first image to create the second one
img2 = step(htran, img1);

% Determine the motion between by the two images
motion = step(hbm, img1, img2);

% Blend the image
halphablend = vision.AlphaBlender;
img12 = step(halphablend, img2, img1);

% Show the 
[X, Y] = meshgrid(1:blockSize:size(img1, 2), 1:blockSize:size(img1, 1));
imshow(img12); hold on;
quiver(X(:), Y(:), real(motion(:)), imag(motion(:)), 0); hold off;



