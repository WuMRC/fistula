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

dicomFrames = size(dicomFile,3);
pixelsX = size(dicomFile, 2); pixelsY = size(dicomFile, 1);

newDicomFile = dicomFile; 

% Get region of interest
framenum = 1;
objectFrame = dicomFile(:,:,framenum);
objectRegion = [0 0 dicomSize(1) dicomSize(2)];



% Show the points getting tracked
while framenum < dicomFrames
      
      
      IX = dicomFile(:,:,framenum);                %Frame 1
      IY = dicomFile(:,:,framenum+1);            %Frame 2
      FILT = [1 1 1; 1 1 1; 1 1 1];                      %Filter matrix
      KRNL_LMT = [2 2];                                 %Group of pixels you're trying to find in next image
      SRCH_LMT = [5 5];                                 %Region
      POS = [2 2];                                           %Origin of krnl and srch    
      
      [RHO]=corr2D(IX,IY,FILT,KRNL_LMT,SRCH_LMT,POS);
      
      newDicomFile(:,:,framenum) = out(:,:,1);
      framenum = framenum + 1;
end

implay(newDicomFile);
%Save as a new dicom with tracking objects embedded
%newDicomFile = dicomwrite(permute(newDicomFile, [1 2 4 3]), newFileName);