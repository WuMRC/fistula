%% Dicom Point Tracker
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

newFileName = ['tracker_' fullfile(fileName)];
newDicomFile = dicomFile; 

% Get region of interest
framenum = 1;
objectFrame = dicomFile(:,:,framenum);
objectRegion = [0 0 dicomSize(1) dicomSize(2)];

% Declare points to track in the image
points = detectMinEigenFeatures(objectFrame);
pointImage = insertMarker(objectFrame, points.Location, '+', 'Color', 'white');

% Create object tracker
tracker = vision.PointTracker('MaxBidirectionalError', 1);

% Initialize object tracker
initialize(tracker, points.Location, objectFrame);

% Show the points getting tracked
while framenum < dicomFrames
      
      framenum = framenum + 1;
      frame = dicomFile(:,:,framenum);
      [points, validity] = step(tracker, frame);
      out = insertMarker(frame, points(validity, :), '+', 'Color', 'white');
      newDicomFile(:,:,framenum) = out(:,:,1);
      
end

%Save as a new dicom with tracking objects embedded
newDicomFile = dicomwrite(permute(newDicomFile, [1 2 4 3]), newFileName);