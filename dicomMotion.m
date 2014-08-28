%% Tracking DICOM image movement

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
outputVideo = VideoWriter(fullfile('movement.avi'));
outputVideo.FrameRate = 1;
open(outputVideo);

%Loop through DICOM images and write to video

for ii = 1:dicomFrames
    img = imread(fullfile(workingDir,'images',sortedImageNames{ii}));
    writeVideo(outputVideo,img);
end

%Finalize the video file
close(outputVideo);

%Read in the video file
videoReader = vision.VideoFileReader(...
    'movement.avi','ImageColorSpace',...
    'Intensity','VideoOutputDataType','uint8');
converter = vision.ImageDataTypeConverter; 
shapeInserter = vision.ShapeInserter('Shape','Lines',...
    'BorderColor','Custom', 'CustomBorderColor', 255);
videoPlayer = vision.VideoPlayer('Name','Motion Vector');

% Track the movement of the image. This is the key function to understand here
opticalFlow = vision.OpticalFlow('ReferenceFrameDelay', 1);
opticalFlow.OutputValue = ...
    'Horizontal and vertical components in complex form';

while ~isDone(videoReader)
    frame = step(videoReader);
    im = step(converter, frame);
    of = step(opticalFlow, im);
    lines = videooptflowlines(of, 100);
    if ~isempty(lines)
      out =  step(shapeInserter, im, lines); 
      step(videoPlayer, out);
    end
end

%Delete temporary video file
delete 'movement.avi'

release(videoPlayer);
release(videoReader);



