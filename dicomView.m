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

%% Get the necessary sceen measurements to build GUI
% All handles and the image stack are stored in the struct SS

screenSize = get(0,'ScreenSize');
screenWidth = screenSize(3);
screenHeight = screenSize(4);

figScaling = 0.7;
figWidth = screenWidth*figScaling;
figHeight = screenHeight*figScaling;

pad = 10;

stepSmall = 1/(size(S.I,3)-1);
stepLarge = stepSmall*10;


%% Create the figure itself
S.figure    = figure('units', 'pixels', ...                                          
            'position', [figWidth/4, 50, figWidth, figHeight], ...
            'menubar', 'figure', ...
            'name', 'dicomSlider', ...
            'numbertitle', 'off', ...
            'resize', 'off');

%% Create the axes for image display. 
S.axes      = axes('units', 'pixels', ...                                            
            'position', [4*pad, 6*pad, figWidth-20*pad, figHeight-8*pad], ...
            'fontsize', 10, ...
            'nextplot', 'replacechildren');

%% Create a slider and an editbox for picking frames

% The slider itself
S.slider    = uicontrol('style','slide',...                                        
            'unit','pix',...                           
            'position',[5*pad, pad, figWidth-16*pad, 2*pad],...
            'min',1,'max',size(S.I,3),'val',1,...
            'SliderStep', [stepSmall, stepLarge]);
        
% The slice number
S.slideNum  = uicontrol('style', 'edit', ...                                         
            'unit', 'pix', ...
            'position', [figWidth-10*pad, pad, 4*pad, 2*pad], ...
            'fontsize', 12,...
            'string', '1');

% Textbox 
S.slideText = uicontrol('style', 'text', ...   
            'unit','pix', ...
            'position', [figWidth-13.5*pad, 3*pad, 10*pad, 2*pad],...
            'fontsize', 10, ...
            'string', 'Current frame:');
%Play button
S.play = uicontrol('style','togglebutton',...
            'unit', 'pix',...
            'position',[pad, pad, 4*pad, 2*pad],...
            'min',0,'max',1,...
            'value',0,...
            'string', 'Play');
            
        
%% Create a button group (for analysis eventually)

% The button group itself
S.butGrp    = uibuttongroup('unit','pix',...
            'position',[figWidth-13.5*pad, figHeight-40*pad, 10*pad, 20*pad]);
        
% Textbox describing the button group
S.someText = uicontrol('style','text',...
    'unit', 'pix', ...
    'position',[figWidth-13.5*pad, figHeight-18*pad+2, 10*pad, 3*pad], ...
    'fontsize', 10,...
    'string', 'Analysis Controls');

S.default = uicontrol('style','radio',...
    'parent', S.butGrp,...
    'position',[0.5*pad, 17*pad, 9*pad, 2*pad],...
    'fontsize', 8, ...    
    'string','Default button');

%% Create a button to export data

% Pushbutton to draw current view in separate figure
S.butExport = uicontrol('style', 'pushbutton', ...
    'unit', 'pix', ...
    'position', [figWidth-14*pad, figHeight-55*pad, 11*pad, 4*pad], ...
    'fontsize', 12, ...
    'string','Export data');

%% Draw the first frame of the stack
S.Clims=[0 max(S.I(:))];
imagesc(squeeze(S.I(:,:,1)),S.Clims); 
axis equal tight 
set(gca,'YDir','Reverse')
% setcm(S.cmpopup,[],S)  
colorbar

%% Set callback functions 
set([S.slideNum,S.slider,S.play],'call',{@switchframe,S});
% set(S.cmpopup,'Callback',{@setcm,S});        %Callback function for changing colormap
set(S.butGrp,'SelectionChangeFcn',{@analysis,S});
% set([S.smgausssize,S.smgausssigma,S.smdisksize],'call',{@smoothsize,S});
% set(S.resetbutton,'Callback', {@resetfunction,S});
set(S.butExport,'Callback',{@exportfunction,S});

end


%% Move slider or write in frame editbox callback function                
function [] = switchframe(varargin)

%Extract handle of calling object and the struct S
[h, S] = varargin{[1,3]};

switch h
    % A slice number was input manually
    case S.slideNum                     
        sliderState =  get(S.slider,{'min','max','value'});
        enteredValue = str2double(get(h,'string'));
        
        % Check for existence of slide number
        if enteredValue >= sliderState{1} && enteredValue <= sliderState{2}
            sliderValue=round(enteredValue);
            set(S.slider,'value',sliderValue)
        else % If it does not e
            set(h,'string',sliderState{3})
            return
        end
        
    % The slider was used
    case S.slider
        sliderValue=round(get(h,'value'));
        set(S.slideNum,'string',sliderValue)
    
    %Play button was used
    case S.play
        playValue= get(S.play,'value');
        sliderMax = get(S.slider,'max');
        while playValue == 1       %Plays the slides
            sliderValue =  round(get(S.slider,'value'));
            
            if sliderValue >= sliderMax;
                play.Value = 0;
                break;
            end
            %Increment the slider
            sliderValue=sliderValue+1; 
            set(S.slideNum,'string',sliderValue)
            set(S.slider,'value',sliderValue)
            
            % Check to see if the analysis button is set to 'none'
            if get(S.butGrp,'SelectedObject')==S.default
                % If it is, plot the new selected frame from the original stack
                imagesc(squeeze(S.I(:,:,sliderValue)),S.Clims)
                %     setcm(S.cmpopup,[],S)
            else
                % If it isn't, plot the new selected frame from the analyzed stack
                analysis(get(S.butGrp,'SelectedObject'),[],S)
            end
            pause(0.0001);
            
            %Check to see playvalue
            playValue= get(S.play,'value');
        end        
        sliderValue = get(S.slider,'value');  
end

% Check to see if the analysis button is set to 'none'
if get(S.butGrp,'SelectedObject')==S.default
    % If it is, plot the new selected frame from the original stack
    imagesc(squeeze(S.I(:,:,sliderValue)),S.Clims)
    %     setcm(S.cmpopup,[],S)
else
    % If it isn't, plot the new selected frame from the analyzed stack
    analysis(get(S.butGrp,'SelectedObject'),[],S)
end

end


%% Perform various analysis    
function [] = analysis(varargin)
[h,S] = varargin{[1,3]};
if h==S.smbutgrp  % If called by a radio button, the calling handle will be the button group
    h=varargin{2}.NewValue; % Set h to the handle of the selected radio button
end

currentFrame = round(get(S.sl,'value'));

switch h % Get handle of calling radio button
    case S.default
        imagesc(squeeze(S.I(:,:,currentFrame)),S.Clims)
%         setcm(S.cmpopup,[],S)
        return %  Return to caller function so no filtering is done
    case S.correlation
        % Make room for decorrleation analysis
        % Should be updated frame to frame (potentially for every pixel)
        
    case S.diameter
        % To take diameter measurements
        % Would love to be able to slect either two regions of the walls or
        % select a single line between two walls to measure
        
end

% S.Is=imfilter(S.I(:,:,currentFrame),smfilt,'replicate');
% imagesc(S.Is,S.Clims)    
% setcm(S.cmpopup,[],S)
end
