function plot_dist
% change_graph
% select a data set from the pop-up menu to plot the selected data in the axes. 
clear all
global h
global minima
%Instruct user to open dicom image
[fileName, filePath] = uigetfile('*.DCM;*.dcm;*.mat', ...
                        'Choose DICOM images to import', pwd, ...
                        'MultiSelect', 'off');

if filePath(1) == 0
    disp('No file selected. Exiting function.')
    return
end

disp(['User selected: ', fullfile(fileName)]);
[~, ~, ext] = fileparts(fileName);

if strcmp(ext,'.DCM') || strcmp(ext,'.dcm')
    dicomFile = permute(dicomread(fileName),[1, 2, 4, 3]);
else
    load( fileName);
    dicomFile = permute(image_change,[1 2 4 3]);
end

dicomFile = uint8(dicomFile);
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
sampFreq = 1;  % Taken from image, though the DICOM should have this
time = (1:dicomFrames)/sampFreq;

%Convert pixels to cm and percent
calibration = 5;
pointDistCm = pointDist/calibration;
pointDistPercent = pointDist.*100./max(max(pointDist));

%Initialize global variables
h  = struct;
minima = zeros(1);
% Plot the tracked pixel movement in a switchable GUI
% Create and then hide the GUI as it is being constructed. 
f = figure('Visible','off','Position',[360,500,475,350]); %Left bottom width height

% Construct the components. 

hpopup = uicontrol('Style','popupmenu',... 
    'String',{'Distance [cm]','Distance [%]'},... 
    'Position',[25,320,100,25],...
    'Callback',{@popup_menu_Callback});

hdrawmin = uicontrol('Style','pushbutton',... 
    'String','Find Local Minima','Position',[150,320,110,25],...
    'Callback',{@drawmin_button_Callback});

hsetmin = uicontrol('Style','pushbutton',... 
    'String','Set Minima','Position',[285,320,70,25],...
    'Callback',{@setmin_button_Callback});

ha = axes('Units','pixels','Position',[25,25,425,270]); 

% Change units to normalized so components resize automatically. 
set([f,ha,hpopup,hdrawmin,hsetmin],'Units','normalized');

% Create a plot in the axes. 
plot(time, pointDistCm)
xlabel('Time [s]'); ylabel('Distance [cm]')
title('Distance between 2 points')

% Assign the GUI a name to appear in the window title. 
set(f,'Name','Distance Between 2 Points')
% Move the GUI to the center of the screen. 
movegui(f,'center')
% Make the GUI visible. 
set(f,'Visible','on');

% Pop-up menu callback. Read the pop-up menu and display property

    function popup_menu_Callback(source,eventdata) 
        % Determine the selected data set. 
        str = get(source, 'String'); 
        val = get(source,'Value'); 

        % Set current data to the selected data set.
        switch str{val}; 
            case 'Distance [cm]' % User selects cm
                plot(time, pointDistCm)
                xlabel('Time [s]'); ylabel('Distance [cm]')
                title('Distance between 2 points')
            case 'Distance [%]'   % User selects percent
                plot(time, pointDistPercent)
                xlabel('Time [s]'); ylabel('Distance [%]')
                title('Distance between 2 points')
        end
    end

    function [lmval,indd]=lmin(xx,filt)
        %Find the local minima in a data set, excludes the first
        %and last points.
        % Created by Serge Koptenko, Guigne International Ltd.
        x=xx;
        len_x = length(x);
            fltr=[1 1 1]/3;
          if nargin <2, filt=0; 
            else
        x1=x(1); x2=x(len_x); 

            for jj=1:filt,
            c=conv(fltr,x);
            x=c(2:len_x+1);
            x(1)=x1;  
                x(len_x)=x2; 
            end
          end

        lmval=[];
        indd=[];
        i=2;		% start at second data point in time series

            while i < len_x-1,
            if x(i) < x(i-1)
               if x(i) < x(i+1)	% definite min
        lmval =[lmval x(i)];
        indd = [ indd i];

               elseif x(i)==x(i+1)&x(i)==x(i+2)	% 'long' flat spot
        %lmval =[lmval x(i)];	%1   comment these two lines for strict case 
        %indd = [ indd i];	%2 when only  definite min included
        i = i + 2;  		% skip 2 points

               elseif x(i)==x(i+1)	% 'short' flat spot
        %lmval =[lmval x(i)];	%1   comment these two lines for strict case
        %indd = [ indd i];	%2 when only  definite min included
        i = i + 1;		% skip one point
               end
            end
            i = i + 1;
            end

        if filt>0 & ~isempty(indd),
            if (indd(1)<= 3)|(indd(length(indd))+2>length(xx)), 
               rng=1;	%check if index too close to the edge
            else rng=2;
            end

               for ii=1:length(indd), 
                [val(ii) iind(ii)] = min(xx(indd(ii) -rng:indd(ii) +rng));
                iind(ii)=indd(ii) + iind(ii)  -rng-1;
               end
          indd=iind; lmval=val;
        else
        end
    end

    function drawmin_button_Callback(source,eventdata)
        %Draw vertical lines indicating the location of local minima
        %Find local minima
       
        [lmval,indd]=lmin(pointDistCm,1);
        minima = indd;
        buffer = (max(pointDistCm)-min(pointDistCm))/4;
        count = 1;
        %Create lines
        while count <= length(lmval)
            x = [indd(count), indd(count)];
            y = [lmval(count)-buffer, lmval(count)+buffer];
            strcount = strcat('a',num2str(count));
            h.(strcount) = imline(gca, x, y);
            count = count + 1;
        end
    end

    function setmin_button_Callback(source, eventdata)
        %Set location of local minimum
        %Information is used to calculate strain from the minimal vessel
        %dialation.
        if exist('h','var')
            count = 1;
            strcount = strcat('a',num2str(count));
            while isfield(h, strcount)
                pos =getPostion(h.(strcount));
                minima(count) = pos(1,1);
                count = count + 1;
                strcount = strcat('a',num2str(count));
            end
            msgbox('New minima set')
            disp(minima)
        else
            msgbox('Please find minima first')
        end
        
    end

end