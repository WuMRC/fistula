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
            'position',[2*pad, pad, figWidth-16*pad, 2*pad],...
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
        
        
%% Create a button group (for analysis eventually)

% The button group itself
S.butGrp    = uibuttongroup('unit','pix',...
            'position',[figWidth-13.5*pad, figHeight-40*pad, 10*pad, 20*pad]);
        
% Textbox describing the button group
S.someText = uicontrol('style','text',...
    'unit', 'pix', ...
    'position',[figWidth-13.5*pad, figHeight-20*pad+2, 10*pad, 2*pad], ...
    'fontsize', 10,...
    'string', 'Analysis Controls');

S.nothing = uicontrol('style','radio',...                                      %Radio button for no smoothing
    'parent', S.butGrp,...
    'position',[0.5*pad, 17*pad, 9*pad, 2*pad],...
    'fontsize', 8, ...    
    'string','Nothing');

%% Create a button to export data

% Pushbutton to draw current view in separate figure
S.butExport = uicontrol('style', 'pushbutton', ...
    'unit', 'pix', ...
    'position', [figWidth-14*pad, figHeight-60*pad, 11*pad, 4*pad], ...
    'fontsize', 12, ...
    'string','Export data');

%% Draw the first frame of the stack%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
S.Clims=[0 max(S.I(:))];                                                    %Color limits for the plotting and colorbar. Needs to be done before callbacks are assigned
imagesc(squeeze(S.I(:,:,1)),S.Clims);                                       %Display the first frame
axis equal tight                                                            %Make sure it's to scale
set(gca,'YDir','Reverse')
% setcm(S.cmpopup,[],S)                                                            %Set colormap
colorbar                                                                    %Display a colorbar

%%%%%%Set callback functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set([S.slideNum,S.slider],'call',{@switchframe,S});                                   %Shared callback function for fram selection slider and editbar
% set(S.cmpopup,'Callback',{@setcm,S});                                       %Callback function for changing colormap
set(S.butGrp,'SelectionChangeFcn',{@smoothing,S});                        %Callback function for smoothing radio buttons
% set([S.smgausssize,S.smgausssigma,S.smdisksize],'call',{@smoothsize,S});    %Callback function for the smoothing edit boxes
% set(S.resetbutton,'Callback', {@resetfunction,S});                          %Callback function for the reset button
set(S.butExport,'Callback',{@exportfunction,S});

end


%% Move slider or write in frame editbox callback function                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = switchframe(varargin)                                         %varargin is {calling handle, eventdata, struct S}, where eventdata is empty (currently unused) when called as callback
[h,S] = varargin{[1,3]};                                                    %Extract handle of calling object and the struct S

switch h                                                                    %Who called?
    case S.ed                                                               %The editbox called...
        sliderState =  get(S.slider,{'min','max','value'});                     % Get the slider's info
        enteredValue = str2double(get(h,'string'));                         % The new frame number
        
        if enteredValue >= sliderState{1} && enteredValue <= sliderState{2} %Check if the new frame number actually exists
            sliderValue=round(enteredValue);
            set(S.slider,'value',sliderValue)                                   %If it does, move the slider there
        else
            set(h,'string',sliderState{3})                                  %User tried to set slider out of range, keep value
            return
        end
    case S.sl                                                               %The slider called...
        sliderValue=round(get(h,'value'));                                  % Get the new slider value
        set(S.slideNum,'string',sliderValue)                                      % Set editbox to current slider value
end

if get(S.butGrp,'SelectedObject')==S.nothing                              %Check if the smoothing is set to 'none'
    imagesc(squeeze(S.I(:,:,sliderValue)),S.Clims)                         % If it is, plot the new selected frame from the original stack
%     setcm(S.cmpopup,[],S)
else
    smoothing(get(S.butGrp,'SelectedObject'),[],S)                       % If it isn't, plot the new selected frame from the smoothed stack
end

end
