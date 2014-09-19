%% Dicom Point Tracker
clear all
close all

delete 'temp.avi'
delete 'tracker.avi'

%Instruct user to open dicom image
[fileName, filePath] = uigetfile('*.DCM;*.dcm', ...
                        'Choose DICOM images to import', pwd, ...
                        'MultiSelect', 'off');

if filePath(1) == 0
    disp('No file selected. Exiting function.')
    return
end
disp(['User selected: ', fullfile(fileName)]);
dicomFile = permute(dicomread(fileName),[1, 2, 4, 3]);
dicomSize = size(dicomFile);
dicomFrames = dicomSize(3);

%Create a temporary working folder to store image sequence
workingDir = tempname;
mkdir(workingDir);
mkdir(workingDir,'images');

%Create Image Sequence from DICOM file
for i = 1:dicomFrames
    img = dicomFile(:,:,i);
    imwrite(img,fullfile(workingDir,'images',sprintf('img%d.jpg',i)));
end

%Read and Sort Image Sequence
imageNames = dir(fullfile(workingDir,'images','*.jpg'));
imageNames = {imageNames.name}';

imageStrings = regexp([imageNames{:}],'(\d*)','match');
imageNumbers = str2double(imageStrings);

[~,sortedIndices] = sort(imageNumbers);
sortedImageNames = imageNames(sortedIndices);

%Construct a video object
outputVideo = VideoWriter(fullfile('temp.avi'));
outputVideo.FrameRate = 5;
open(outputVideo);

%Loop through DICOM images and write to video

for ii = 1:dicomFrames
    img = imread(fullfile(workingDir,'images',sortedImageNames{ii}));
    writeVideo(outputVideo,img);
end

%Finalize the video file
close(outputVideo);


%Read in video to be analyzed
videoFileReader = vision.VideoFileReader('temp.avi');
%videoPlayer = vision.VideoPlayer('Position', [100, 100, 680, 520]);
objectFrame = step(videoFileReader);
trackerVideo = 'tracker.avi';
videoFWriter = vision.VideoFileWriter(trackerVideo);


% Get region of interest
%figure; imshow(objectFrame);
%objectRegion=round(getPosition(imrect));

%objectImage = insertShape(objectFrame, 'Rectangle', objectRegion,'Color', 'red'); 
%figure; imshow(objectImage); title('Red box shows object region');

% Declare points to track in the image
points = detectMinEigenFeatures(rgb2gray(objectFrame));
pointImage = insertMarker(objectFrame, points.Location, '+', 'Color', 'white');
%figure, imshow(pointImage), title('Detected interest points');

% Create object tracker
tracker = vision.PointTracker('MaxBidirectionalError', 1);

% Initialize object tracker
initialize(tracker, points.Location, objectFrame);

% Show the points getting tracked
while ~isDone(videoFileReader)
      frame = step(videoFileReader);
      [points, validity] = step(tracker, frame);
      out = insertMarker(frame, points(validity, :), '+');
      %step(videoPlayer, out);
      step(videoFWriter, out);
end
delete 'temp.avi'
%release(videoPlayer);
release(videoFileReader);
release(videoFWriter);

implay('tracker.avi');