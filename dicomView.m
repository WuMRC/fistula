function [fileName] = dicomView(varargin)

%% Input/Error Check
inputsMax = 1;

if nargin > inputsMax
    disp('Error in dicomView: Too many input arguments');
    return
end

switch nargin
    case 0
        [fileName, filePath] = uigetfile('*.DCM;*.dcm',... 
            'Choose DICOM images to import',pwd,...
            'MultiSelect','off');
        if filePath(1) == 0
            disp('Error in dicomSlider: No files chosen');
            return
        end
        S.I = permute(dicomread(fileName),[1 2 4 3]);
%         dicomSize 
    case 1
        S.I = permute(dicomread(fileName),[1 2 4 3]);
end

%% Build the figure for the GUI.                                          
% All handles and the image stack are stored in the struct SS             %

screenSize = get(0,'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);

figFactor = 0.9;
figWidth = screenWidth*figFactor;
figHeight = screenHeight*figFactor;

pad = 10;

stepSmall = 1/(size(S.I,3)-1);
stepLarge = stepSmall*10;
