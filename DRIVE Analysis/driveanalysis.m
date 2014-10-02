

%% INITIAL SELECTION OF DATA FOR ANALYSIS
% SELECT PATIENT FOLDER
WORKING_DIRECTORY = uigetdir('','Select the patient directory');
ULTRASOUND_DIRECTORY = strcat(WORKING_DIRECTORY,'/ultrasound/');

addpath(genpath(WORKING_DIRECTORY));
cd(WORKING_DIRECTORY);
patientID = WORKING_DIRECTORY((end-7):end);
disp(horzcat('Working on subject: ',patientID))

% SELECT RELEVANT ULTRASOUND IMAGES
ultrasoundFileArrayInfo = dir(ULTRASOUND_DIRECTORY);
ultrasoundFileArray = ultrasoundFileArrayInfo(arrayfun(@(x) x.name(1), ...
    ultrasoundFileArrayInfo) ~= '.');

% SELECT RELEVANT BIOIMPEDANCE DATA
bioimpedanceFileArrayInfo = dir(WORKING_DIRECTORY);
bioimpedanceFileArray = bioimpedanceFileArrayInfo(arrayfun(@(x) x.name(1), ...
    bioimpedanceFileArrayInfo) ~= '.');
bioimpedanceFileArray = bioimpedanceFileArray(arrayfun(@(x) x.isdir, ...
    bioimpedanceFileArray) ~= 1);

%% SELECT ONLY THOSE ULTRASOUND TRIALS FOR ANALYSIS
% Look for viable trials
trialCheckArray = zeros(1,size(ultrasoundFileArray,1));

% Select only those files large enough to contain good trials
minFileSize = 50*1024*1024; % 50MB

for trial = 1:size(ultrasoundFileArray,1)
    ultrasoundFileInfo = dir(strcat(ULTRASOUND_DIRECTORY,...
        ultrasoundFileArray(trial).name));
    if ultrasoundFileInfo.bytes > minFileSize
        trialCheckArray(trial) = true;
    else 
        trialCheckArray(trial) = false;
    end
end

% Remove all nonrelavent ultrasound images
trialCheckArray = logical(trialCheckArray);
ultrasoundFileArray = ultrasoundFileArray(trialCheckArray);

% Time of file
timeMarkerUltrasound = zeros(1,size(ultrasoundFileArray,1));
for nTrials = 1:size(ultrasoundFileArray,1)
    x = str2double(ultrasoundFileArray(nTrials).name(9:14));
    timeMarkerUltrasound(nTrials) = x;
    timeMarkerUltrasoundSec(nTrials) = ...
        str2double(ultrasoundFileArray(nTrials).name(9:10))*60*60 ...
        + str2double(ultrasoundFileArray(nTrials).name(11:12))*60 ...
        + str2double(ultrasoundFileArray(nTrials).name(13:14));
end
% clear x;

%%
% Bioimpedance

bioimpedanceFile = bioimpedanceFileArray(1).name; % Select  file
acq = load_acq(bioimpedanceFile);

bioimpedanceArm = acq.data(:,1);
bioimpedanceLeg = acq.data(:,2);
biomipedanceChest = acq.data(:,3);
bioimpedanceForearm = acq.data(:,4);

dtBioimpedance = acq.hdr.graph.sample_time;
timeStartBioimpedance = acq.hdr.graph.first_time_offset/1000;

day = 60*60*24;
timeStartBioimpedance6 = str2double(datestr(timeStartBioimpedance/day,'HHMMSS'));

shift = 0;
% Find markers in ACQKnowledge data
timeMarkerBioimpedance = zeros(1,length(acq.markers.lSample));
timeMarkerBioimpedanceInd = zeros(1,length(acq.markers.lSample));
for nMarkers = 1:length(acq.markers.lSample)
    if acq.markers.lSample(nMarkers) == 0
        shift = shift + 1;
    else
        x = str2double(datestr(timeStartBioimpedance/day+...
            (double(acq.markers.lSample(nMarkers)/200)/day),'HHMMSS'));
        timeMarkerBioimpedance(nMarkers-shift) = x;
        clipName{1,nMarkers-shift} = acq.markers.szText{1,nMarkers}(11:end);
        timeMarkerBioimpedanceInd(nMarkers-shift) = acq.markers.lSample(nMarkers);
    end
end
clear x

timeMarkerBioimpedance = unique(timeMarkerBioimpedance);
clipName = unique(clipName);

%%
% Placeholding code for figuring out how the two sets of data correspond
timeErr = 2;
if size(timeMarkerUltrasound,2) > size(timeMarkerBioimpedance,2)
    rowArray = [];
    for nMarkers = 1:length(timeMarkerBioimpedance)
        row = find(timeMarkerBioimpedance(nMarkers) > (timeMarkerUltrasound-timeErr) ...
            & timeMarkerBioimpedance(nMarkers) < (timeMarkerUltrasound+timeErr));
        rowArray = [rowArray, row(1)];
    end
    timeMarkerUltrasound = timeMarkerUltrasound(rowArray);
end

%%
% Should endeavor to change above code so that all you need is the
% ultrasound filename to get the corresponding bioimpedance data


%%

for DATA_TO_ANALYZE = 1;
% %%
% for DATA_TO_ANALYZE = 1:1%length(timeMarkerBioimpedance)
clear rowMove colMove rowMove_total colMove_total posNew posOriginal
clear rowKernel colKernel rowSearch colSearch

%%
ultrasoundFile = ultrasoundFileArray(DATA_TO_ANALYZE).name;
ultrasoundFileInfo = dicominfo(ultrasoundFile);
% ultrasoundFrameRate = ultrasoundFileInfo.CineRate;

image = dicomread(ultrasoundFile);
image_new = imageperm(image);
image_roi = double(selectroi(image_new));
% image_roi = image_new(:,:,:,1);

image_roiNORM = image_roi./max(max(max(image_roi)));

[nRows, nCols, nFrames] = size(image_roi);


%% Select points

[poiX, poiY,nPoints] = selectPoints(image_roiNORM(:,:,1,1));


%%
% Eventually the vessel edge will be detected automatically and then
% subsequently tracked


level = graythresh(image_roiNORM(:,:,1));
imageTrackBW = im2bw(image_roiNORM(:,:,1),level);
imageTrackFILT = image_roiNORM(:,:,1).*imageTrackBW;
imagesc(imageTrackFILT)


%%
% Placeholder for function to optimize kernel and search window size
rowKernel   = 5; colKernel   = 5;   % KERNEL SIZE
rowSearch   = 5; colSearch   = 5;   % SEARCH WINDOW

% Select filter

% Eventually on the GUI this will be a menu to select which sort of
% filtering the user wants to use.

%     filterType = 'gaussian';            % Should I prompt the user to select
% at the time?

filterType = 'average';
if strcmp(filterType,'average')
    filt = fspecial(filterType,[rowKernel, colKernel]);
elseif strcmp(filterType,'disc')
    filt = fspecial(filterType,rowKernel);
elseif strcmp(filterType,'gaussian')
    sigma = 0.5;
    filt = fspecial(filterType,[rowKernel, colKernel],sigma);
elseif strcmp(filterType,'laplacian')
    alpha = 0.5;
    filt = fspecial(filterType,[rowKernel, colKernel],alpha);
elseif strcmp(filterType,'log') % Laplacian Of Gaussian (LOG)
    sigma = 0.2;
    filt = fspecial(filterType,[rowKernel, colKernel],sigma);
    
    % It is this motion filter that might ultimately benefit us the most
    % Need to determine the angle of the vessel to implement wall motion
    % filter design
elseif strcmp(filterType,'motion')
    len = 9;
    theta = 0;
    filt = fspecial(filterType,len,theta);
elseif strcmp(filterType,'prewitt')
    filt = fspecial(filterType);
elseif strcmp(filterType,'sobel')
    filt = fspecial(filterType);
else
    filt = ones(rowKernel, colKernel);
    
end


%%

imageTrack = image_roi;

h = waitbar(0 ,'Progress');
frameIncrement = 1;

for indPoints = 1:nPoints
    posOriginal = [poiY(indPoints), poiX(indPoints)];
    %     posNew = posOriginal;
    posNew = posOriginal;
    
    total = nFrames-1;
    for ind = 1:frameIncrement:total
        
        % Get the frames of data
        currentFrameData = image_roiNORM(:,:,ind);
        nextFrameData = image_roiNORM(:,:,ind+1);
        
%         % Function to track frame-to-frame motion
%         pos(:,:,ind+1) = perPixelTrack(currentFrameData, nextFrameData, filt,...
%             [rowKernel, colKernel], [rowSearch, colKernel], pos(:,:,ind));
%         %
%         %             [poiRow(ind,indPoints), poiCol(ind,indPoints)] = ...
%         %                 perPixelTrack(currentFrameData, nextFrameData, filt,...
%         %                 [rowKernel, colKernel], [rowSearch, colKernel], pos(:,:,ind));
%         
                % Calculate the correlation
        [rho_c(:,:,ind)] = corr2D(currentFrameData, nextFrameData, filt, ...
            [rowKernel, colKernel], [rowSearch, colKernel], posNew);
        rho_n(:,:,ind) = rho_c(:,:,ind)./max(max(rho_c(:,:,ind)));
   
        % Calculate movement based on max correlation
        [rowMove(ind,indPoints), colMove(ind,indPoints)] = find(rho_n(:,:,ind) ... 
            == max(max(rho_n(:,:,ind))));
        
        % Need to compenate for drift and net motion of the image
%         cornerOffset = 20;
 
%         
%         [rho_c(:,:,ind)] = corr2D(currentFrameData, nextFrameData, filt, ...
%             [rowKernel, colKernel], [rowSearch, colKernel], posNew);
%         rho_n(:,:,ind) = rho_c(:,:,ind)./max(max(rho_c(:,:,ind)));
        
        
    
        rowMove(ind,indPoints) = rowMove(ind,indPoints) - (rowSearch + 1);
        colMove(ind,indPoints) = colMove(ind,indPoints) - (colKernel + 1);
    
        rowMove_total = sum(rowMove(:,indPoints));
        colMove_total = sum(colMove(:,indPoints));
    
        poiRow(ind,indPoints) = posOriginal(1) + rowMove_total;
        poiCol(ind,indPoints) = posOriginal(2) + colMove_total;
    
        posNew = [poiRow(ind,indPoints), poiCol(ind,indPoints)];
    
        % Track single pixel in image
        imageTrack(poiRow(ind,indPoints),poiCol(ind,indPoints),ind) = 400;
        
%         imageTrack(pos(1,1,ind),pos(1,2,ind),ind) = 400;
        
        
        prog = (ind+(indPoints-1)*ind)/(total*nPoints);
        waitbar(prog,h,'Progress')
    end
    
end

close(h)
% implay(imageTrack./max(max(max(imageTrack))))


%%
% Ultrasound analysis
% ERROR, POIROW NO LONGER EXISTS 
diameter = sqrt((poiRow(:,1)-poiRow(:,2)).^2 + (poiCol(:,1)-poiCol(:,2)).^2);
diameterSMOOTH = smooth(diameter,35/2);
diameterSMOOTHER = smooth(diameterSMOOTH,25);


PIXELS_PER_CM = 27;

diameterSMOOTH = diameterSMOOTH/PIXELS_PER_CM;
diameterSMOOTHER = diameterSMOOTHER/PIXELS_PER_CM;


timeFrames = 0:(1/35):(size(diameterSMOOTH,1)-1)/35;

plot(timeFrames(1:349),diameterSMOOTHER(1:349))

[diameterMax, diMax, diameterMin, diMin] = extrema(diameterSMOOTHER(1:349));

% hold on, plot(timeFrames(diMax),diameterMax,'g.', timeFrames(diMin),diameterMin,'r*'),

% for indExtrema = 1:(size(diMax)-2) % get rid of the two extrema values
%     peak2peak(indExtrema) = diameterMax(indExtrema) - diameterMin(indExtrema)
% end

peak2peakUS(DATA_TO_ANALYZE) = max(diameterSMOOTHER(1:349)) - min(diameterSMOOTHER(1:349));

end
%%
% Impedance analysis
Fs = 200;
dt = 1/Fs;
timeBioimpedance = 0:dt:10;
bioimpedanceLegSMOOTH = smooth(bioimpedanceLeg,Fs/2).*20;
bioimpedanceLegSMOOTH = smooth(bioimpedanceLegSMOOTH, 20);
respLegSMOOTH = smooth(bioimpedanceLegSMOOTH, 200);

bioimpedanceArmSMOOTH = smooth(bioimpedanceArm,Fs/2).*20;
bioimpedanceArmSMOOTH = smooth(bioimpedanceArmSMOOTH, 20);

figure, plot(timeBioimpedance, bioimpedanceArmSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE):...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+200*10)))
%
% figure, plot(timeBioimpedance, bioimpedanceArmSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE):...
%     (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+200*10)))
%
% figure, plot(timeBioimpedance, respLegSMOOTH(timeMarkerBioimpedance(DATA_TO_ANALYZE):...
%     (timeMarkerBioimpedance(DATA_TO_ANALYZE)+200*10)))

% % FFT
% NFFT = 2^nextpow2(length(timeBioimpedance));
% B = fft(bioimpedanceLegSMOOTH(timeMarkerBioimpedance(1):...
%     (timeMarkerBioimpedance(DATA_TO_ANALYZE)+200*10)), NFFT)/length(timeBioimpedance);
% f = Fs/2*linspace(0,1,NFFT/2+1);
%
% plot(f,abs(B(1:NFFT/2+1)))

peak2peakBI(DATA_TO_ANALYZE) = max(bioimpedanceArmSMOOTH(...
    timeMarkerBioimpedanceInd(DATA_TO_ANALYZE):...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+200*10))) - ...
    min(bioimpedanceArmSMOOTH(...
    timeMarkerBioimpedanceInd(DATA_TO_ANALYZE):...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+200*10)));


%%

splineUltrasound = spline(timeFrames(1:349),diameterSMOOTH(1:349),timeBioimpedance);

h(1) = figure;
plot3(timeBioimpedance, splineUltrasound,...
    bioimpedanceLegSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE):...
    (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+200*10)))
grid on

title(strcat(clipName{DATA_TO_ANALYZE},' - Leg'))
xlabel('Time [s]'),     ylabel('IVC Diameter [cm]'),    zlabel('Impedance [\Omega]')

saveas(h,horzcat('z',patientID,clipName{DATA_TO_ANALYZE},' - Leg','.fig'))

% figure, plot3(timeBioimpedance, splineUltrasound,...
%     bioimpedanceArmSMOOTH(timeMarkerBioimpedanceInd(DATA_TO_ANALYZE):...
%     (timeMarkerBioimpedanceInd(DATA_TO_ANALYZE)+200*10)))
% grid on
%
% title(strcat(clipName{DATA_TO_ANALYZE},' - Arm'))
% xlabel('Time [s]'),     ylabel('IVC Diameter [cm]'),    zlabel('Impedance [\Omega]')


% [bioimpedanceMax,biMax,bioimpedanceMin,biMin] = extrema(...
%     bioimpedanceLegSMOOTH(timeMarkerBioimpedance(1):...
%     (timeMarkerBioimpedance(1)+200*10)));
% figure, plot(timeBioimpedance(biMax), bioimpedanceMax,'g*')

%     %%
% end

%%
% Using microblock analysis function
% total = nFrames-1;
blockSize = 15;
frame2frame = 1;
[ctotal, rowMove, colMove] = ...
    microblockanalysis(image_roiNORM,blockSize,frame2frame);



%%
clear, close, clc


