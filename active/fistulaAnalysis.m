%% New Function for Matt Leavitt



%% Pick two points and track with time
% Luc
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

% Get region of interest
framenum = 1;
objectFrame = dicomFile(:,:,framenum);
objectRegion = [0 0 dicomSize(1) dicomSize(2)];

imshow(objectFrame)
title('Select 2 points along the edge of the vessel, then hit "Enter"')
figHandle = gcf;
[poiX, poiY] = getpts(figHandle);
close

poiX = round(poiX);     poiY = round(poiY);
nPoints = size(poiX,1);
pointLog = zeros(nPoints, 2, dicomFrames);
points = [poiX, poiY];
pointImage = insertMarker(objectFrame, points, '+', 'Color', 'white');

pointDist = zeros(dicomFrames);
newDicom = dicomFile;

% Create object tracker
tracker = vision.PointTracker('MaxBidirectionalError', 1);

% Initialize object tracker
initialize(tracker, points(:,:,1), objectFrame);


while framenum <= dicomFrames
       %Track the points     
      frame = dicomFile(:,:,framenum);
      [points, validity] = step(tracker, frame);
      pointLog(:,:,framenum) = points;
      out = insertMarker(frame, points(validity, :), '+', 'Color', 'white');
      newDicom(:,:,framenum) = out(:,:,1);
      
      %Compute the distance between the 2 points
      pointDist(framenum) = sqrt ((pointLog(1,1,framenum) - pointLog(2,1,framenum))^2+(pointLog(1,2,framenum) - pointLog(2,2,framenum))^2);
      
      framenum = framenum + 1;
      
end
%Display figure showing distance between the points
time = 1:1:dicomFrames;

plot(time, pointDist)
xlabel('Time'); ylabel('Distance (pixels)')
title('Distance between 2 points')

%Show tracked points in the image
implay(newDicom)


%% Detect edge
% Barry


%% Track edge
% Barry


%% Block-match/point track entire region of interest for strain




%% Correlation within vessel