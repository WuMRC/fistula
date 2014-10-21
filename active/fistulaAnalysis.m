%% New Function for Matt Leavitt



%% Pick two points and track with time
% Luc
clear all
%Instruct user to open dicom image
[fileName, filePath] = uigetfile('*.DCM;*.dcm;*.mat', ...
                        'Choose DICOM images to import', pwd, ...
                        'MultiSelect', 'off');

if filePath(1) == 0
    disp('No file selected. Exiting function.')
    return
end

disp(['User selected: ', fullfile(fileName)]);
[pathstr, name, ext] = fileparts(fileName);

if strcmp(ext,'.DCM') || strcmp(ext,'.dcm')
    dicomFile = permute(dicomread(fileName),[1, 2, 4, 3]);
else
    load( fileName);
    dicomFile = permute(image_change,[1 2 4 3]);
end

dicomSize = size(dicomFile);
dicomFrames = dicomSize(3);
%Adjust image
indFrame = 1;
while indFrame <= dicomFrames
   dicomFile(:,:,indFrame) = imadjust(dicomFile(:,:,indFrame));
    indFrame = indFrame + 1;
end

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

pointDist = zeros(dicomFrames,1);
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
      pointDist(framenum) = sqrt ((pointLog(1,1,framenum) - pointLog(2,1,framenum)).^2+(pointLog(1,2,framenum) - pointLog(2,2,framenum)).^2);
      
      framenum = framenum + 1;
      
end

%Display figure showing distance between the points
sampFreq = 16;  % Taken from image, though the DICOM should have this
time = (1:dicomFrames)/sampFreq;


% Plot the tracked pixel movement
plot(time, pointDist)
xlabel('Time [s]'); ylabel('Distance [px]')
title('Distance between 2 points')

% Get envelope of tracked motion
envTop = envelope(time,pointDist,'top',sampFreq,'linear');
envBot = envelope(time,pointDist,'bottom',sampFreq,'linear');
hold on, plot(time, envTop,'r'), plot(time,envBot,'r')

figure, plot(time(11:93),envTop(11:93)-envBot(11:93))
xlabel('Time [s]'); ylabel('Diameter [px]')
title('Distance between 2 points')

%Show tracked points in the image
implay(newDicom(:,:,:,1))


%% Detect edge
% SELECT FILE TO WORK WITH
cd('/Users/barrybelmont/Google Drive/MATLAB/fistuladata/exampleData3');
% load('IM-0002-0100-0001anon.mat');      % bifurcation
% load('IM-0003-0101-0001anon.mat');      % long axis
load('IM-0004-0103-0001anon.mat');      % RT DIST NEAR ANTECUBE
% load('IM-0006-0103-0001anon.mat');      % ANAST
% load('IM-0007-0104-0001anon.mat');      % RT ANAST 2 CM ABOVE
cd('/Users/barrybelmont/Google Drive/MATLAB/fistula/active');

%SELECT REGION OF INTEREST
imageROI = dicomROI(image_change);

[nRows, nCols, nFrames] = size(imageROI);
%%
% GRAYTHRESH EDGE DETECT
indFrame = 1;
while indFrame <= nFrames
    imageROI_adjusted(:,:,indFrame) = imadjust(imageROI(:,:,indFrame));
    imageROI_level(indFrame) = graythresh(imageROI_adjusted(:,:,indFrame));
    imageROI_BW(:,:,indFrame) = im2bw(imageROI_adjusted(:,:,indFrame),...
        imageROI_level(indFrame)*.3);
    indFrame = indFrame + 1;
end

implay(imageROI_BW)

    % An interesting result
    time = (1:99)./16;
    plot(time,imageROI_level)
    xlabel('Time [s]')
    ylabel('Graythreshold')
    title('A heartbeat measure by image contrast')




%% Track edge
% Barry & Luc's code


%% Block-match

%% Point track entire region of interest for strain
% Luc & Barry
clear all

%Instruct user to open dicom image
[fileName, filePath] = uigetfile('*.DCM;*.dcm;*.mat', ...
                        'Choose DICOM images to import', pwd, ...
                        'MultiSelect', 'off');

if filePath(1) == 0
    disp('No file selected. Exiting function.')
    return
end

disp(['User selected: ', fullfile(fileName)]);
[pathstr, name, ext] = fileparts(fileName);

if strcmp(ext,'.DCM') || strcmp(ext,'.dcm')
    dicomFile = permute(dicomread(fileName),[1, 2, 4, 3]);
else
    load( fileName);
    dicomFile = permute(image_change,[1 2 4 3]);
end

dicomSize = size(dicomFile);
dicomFrames = dicomSize(3);
%Adjust image
indFrame = 1;
while indFrame <= dicomFrames
   dicomFile(:,:,indFrame) = imadjust(dicomFile(:,:,indFrame));
%     enhancer = vision.HistogramEqualizer;
%     dicomFile(:,:,indFrame) = step(enhancer, dicomFile(:,:,indFrame));
    indFrame = indFrame + 1;
end


%Create grid of points on the image
pixelsX = dicomSize(2); pixelsY = dicomSize(1);
pixelDensity = 10; %percentage of pixels you want to track (between 0-100)
pixelsBetweenX = (pixelsX-1)/round((pixelsX-1)*pixelDensity/100);
pixelsBetweenY = (pixelsY-1)/round((pixelsY-1)*pixelDensity/100);
count = 1;
countX = 1;
while countX <= pixelsX+.001
    countY=1;
    while countY <= pixelsY+.001
        points(count,:) = [countX countY];
        countY = countY + pixelsBetweenY;
        count = count+1;
    end
    countX = countX + pixelsBetweenX;
end

nPoints = count - 1;
pointLog = zeros(nPoints, 2, dicomFrames);

framenum = 1;
objectFrame = dicomFile(:,:,1);
pointImage = insertMarker(objectFrame, points, '+', 'Color', 'white');

pointDist = zeros(dicomFrames);
newDicom = dicomFile;
newDicom(:,:,1) = pointImage(:,:,1);

% Create object tracker
tracker = vision.PointTracker('MaxBidirectionalError', 3); 

% Initialize object tracker
initialize(tracker, points(:,:,1), objectFrame);


while framenum <= dicomFrames
       %Track the points     
      frame = dicomFile(:,:,framenum);
      [points, validity] = step(tracker, frame);
      pointLog(:,:,framenum) = points;
      out = insertMarker(frame, points(validity, :), '+', 'Color', 'white');
      newDicom(:,:,framenum+1) = out(:,:,1);
      
      %Compute the distance between the 2 points
      %pointDist(framenum) = sqrt ((pointLog(1,1,framenum) - pointLog(2,1,framenum))^2+(pointLog(1,2,framenum) - pointLog(2,2,framenum))^2);
      
      framenum = framenum + 1;
      
end
%Display figure showing distance between the points
% time = 1:1:dicomFrames;
% 
% % plot(time, pointDist)
% % xlabel('Time'); ylabel('Distance (pixels)')
% % title('Distance between 2 points')
% % 

%Show tracked points in the image
implay(newDicom(:,:,:,1))

%% Edge Detection

clear all
%Instruct user to open dicom image
[fileName, filePath] = uigetfile('*.DCM;*.dcm;*.mat', ...
                        'Choose DICOM images to import', pwd, ...
                        'MultiSelect', 'off');

if filePath(1) == 0
    disp('No file selected. Exiting function.')
    return
end

disp(['User selected: ', fullfile(fileName)]);
[pathstr, name, ext] = fileparts(fileName);

if strcmp(ext,'.DCM') || strcmp(ext,'.dcm')
    dicomFile = permute(dicomread(fileName),[1, 2, 4, 3]);
else
    load( fileName);
    dicomFile = permute(image_change,[1 2 4 3]);
end

dicomSize = size(dicomFile);
dicomFrames = dicomSize(3);

%Adjust image
indFrame = 1;
while indFrame <= dicomFrames
   %dicomFile(:,:,indFrame) = imadjust(dicomFile(:,:,indFrame));
   enhancer = vision.HistogramEqualizer;
   dicomFile(:,:,indFrame) = step(enhancer, dicomFile(:,:,indFrame));
   indFrame = indFrame + 1;
end

framenum = 1;

%Initialize edge detection functions
hedge = vision.EdgeDetector;
hcsc = vision.ColorSpaceConverter('Conversion', 'RGB to intensity');
hidtypeconv = vision.ImageDataTypeConverter('OutputDataType','single');

while framenum <= dicomFrames
       %Track the points     
      frame = dicomFile(:,:,framenum);
      %convframe1 = step(hcsc, frame); 
      convframe2  = step(hidtypeconv, frame);   
      
      edge = step(hedge, convframe2);
      edges(:,:,framenum) = edge;
        
      framenum = framenum + 1;
      
end

%Play videos showing edges and original file
implay(edges)
implay(dicomFile(:,:,:,1))

%% Correlation within vessel
%Barry


