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
    case 1
        S.I = permute(dicomread(fileName),[1 2 4 3]);
end