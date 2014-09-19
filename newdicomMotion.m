%% Tracking DICOM image movement
clear all
close all

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

newFileName = ['motion_' fullfile(fileName)];
newDicomFile = dicomFile; 

% Get region of interest
framenum = 1;
objectFrame = dicomFile(:,:,framenum);
objectRegion = [0 0 dicomSize(1) dicomSize(2)];

%Assign motion vector functions
converter = vision.ImageDataTypeConverter; 
shapeInserter = vision.ShapeInserter('Shape','Lines',...
    'BorderColor','Custom', 'CustomBorderColor', 255);

% Track the movement of the image. This is the key function to understand here
opticalFlow = vision.OpticalFlow('ReferenceFrameDelay', 1);
opticalFlow.OutputValue = ...
    'Horizontal and vertical components in complex form';

while framenum < dicomFrames
    
    framenum = framenum + 1;
    frame = dicomFile(:,:,framenum);
    
    im = step(converter, frame);
    of = step(opticalFlow, im);
    lines = videooptflowlines(of, 100); %(velocity value, scale factor)
    if ~isempty(lines)
      out =  step(shapeInserter, im, lines); 
      newDicomFile(:,:,framenum) = out(:,:,1);
    end
    
end

%Save as a new dicom with motion vectors embedded
newDicomFile = dicomwrite(permute(newDicomFile, [1 2 4 3]), newFileName);
