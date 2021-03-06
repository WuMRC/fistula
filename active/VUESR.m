 classdef VUESR < handle
    %This is a dicom image slice viewer with built in scroll, contrast, zoom,
    %,ROI, and image measurement tools.
    %
    %   Use this class to place a self-contained image viewing panel within
    %   a GUI (or any figure). Similar to imtool but with slice scrolling.
    %   Only designed to view grayscale (intensity) images. Use the mouse
    %   to control how the image is displayed. A left click allows window
    %   ad leveling, a right click is for panning, and a middle click is
    %   for zooming. Also the scroll wheel can be used to scroll through
    %   slices.
    %----------------------------------------------------------------------
    %Inputs:
    %
    %   I           An m x n x k image array of grayscale values. Default
    %               is a 100x100x3 random noise image.
    %   position    The position of the panel containing the image and all
    %               the tools. Format is [xmin ymin width height]. Default
    %               position is [0 0 1 1] (units = normalized). See the
    %               setPostion and setUnits methods to change the postion
    %               or units.
    %   h           Handle of the parent figure. If no handles is provided,
    %               a new figure will be created.
    %   range       The display range of the image. Format is [min max].
    %               The range can be adjusted with the contrast tool or
    %               with the setRange method. Default is [min(I) max(I)].
    %----------------------------------------------------------------------
    %Output:
    %
    %   tool        The VUESR object. Use this object as input to the
    %               class methods described below.
    %----------------------------------------------------------------------
    %Constructor Syntax
    %
    %tool = VUESR() creates an VUESR panel in the current figure with
    %a random noise image. Returns the VUESR object.
    %
    %tool = VUESR(I) sets the image of the VUESR panel.
    %
    %tool = VUESR(I,position) sets the position of the VUESR panel
    %within the current figure. The default units are normalized.
    %
    %tool = VUESR(I,position,h) puts the VUESR panel in the figure
    %specified by the handle h.
    %
    %tool = VUESR(I,position,h,range) sets the display range of the
    %image according to range=[min max].
    %
    %Note that you can pass an empty matrix for any input variable to have
    %the constructor use default values. ex. tool=VUESR([],[],h,[]).
    %----------------------------------------------------------------------
    %Methods:
    %
    %   setImage(tool, I) displays a new image.
    %
    %   I = getimage(tool) returns the image being shown by the tool
    %
    %   setPostion(tool,position) sets the position of tool.
    %
    %   position = getPosition(tool) returns the position of the tool
    %   relative to its parent figure.
    %
    %   setUnits(tool,Units) sets the units of the position of tool. See
    %   uipanel properties for possible unit strings.
    %
    %   units = getUnits(tool) returns the units of used for the position
    %   of the tool.
    %
    %   handles = getHandles(tool) returns a structured variable, handles,
    %   which contains all the handles to the various objects used by
    %   VUESR.
    %
    %   setDisplayRange(tool,range) sets the display range of the image.
    %   see the 'Clim' property of an Axes object for details.
    %
    %   range=getDisplayRange(tool) returns the current display range of
    %   the image.
    %
    %   setWindowLevel(tool,W,L) sets the display range of the image in
    %   terms of its window (diff(range)) and level (mean(range)).
    %
    %   [W,L] = getWindowLevel(tool) returns the display range of the image
    %   in terms of its window (W) and level (L)
    %
    %   ROI = getcurrentROI(tool) returns info about the currently selected
    %   region of interest (ROI). If no ROI is currently selected, the
    %   method returns an empty matrix. ROI is a structured variable with
    %   the following fields:
    %       -ROI.mask is a binary mask that defines the pixels within the
    %       ROI.
    %       -ROI.stats is a structured variable containing stats about the
    %       ROI. Included stats are, Area, Perimeter, MaxIntensity,
    %       MinIntensity, MeanIntensity, and STD.
    %
    %   setCurrentSlice(tool,slice) sets the current displayed slice.
    %
    %   slice = getCurrentSlice(tool) returns the currently displayed
    %   slice.
    %
    %----------------------------------------------------------------------
    %Notes:
    %
    %   Based on imtool3D v2.1 by Justin Solomon
    %   Modified by Barry Belmont and Luc Hildebrand to different ends
    %
    %   Requires the image processing toolbox
    
    properties (SetAccess = private, GetAccess = private)
        I               % Image data (MxNxK) matrix of image data (double)
        handles         % Structured variable with all the handles
        handlesROI      % list of ROI handles
        currentROI      % Currently selected ROI
        centers         % list of bin centers for histogram
        calibration     % Converts pixels to mm
        pointLog        % Log of all the points being tracked
        pointLog2       % Log points for the 2 point tracker
        pixelDensity    % Amount of pixels being tracked
        accFrames       % Frames used to find accumulated strain
        map             % Mean Arterial blood pressure
        fRate           % Frame rate in Hz
        hRate           % Hear rate in BPM
        fName           % File opened
        zlocation       % Measurement location on the arm
        zdiameter       % Average measured diameter
        zdistensibility % Average measured distensibility
        zelasticity     % Average measured elasticity
        zpatientID
        pointDistCm
        studydate
        
    end
    
    methods
        
        function tool = VUESR(varargin)  %Constructor
            %%
            %Check the inputs and set things appropriately
            tool.fName = [];
            switch nargin
                case 0  %tool = VUESR()
                    [fileName, filePath] = uigetfile('*.DCM;*.dcm;*.mat;*', ...
                        'Choose DICOM images to import', pwd, ...
                        'MultiSelect', 'off');
                    if filePath(1) == 0
                        disp('No files chosen, exiting function')
                        return;
                    else
                        disp(['User selected: ', fullfile(fileName)]);
                        [~, ~, ext] = fileparts(fileName);
                        if strcmp(ext,'.DCM') || strcmp(ext,'.dcm') || strcmp(ext,'')
                            tool.I = permute(dicomread(fileName),[1, 2, 4, 3]);
                        else
                            load( fileName);
                            tool.I = permute(image_change,[1 2 4 3]);
                        end
                        position=[0, 0, 1, 1];
                        heightHistogram=  figure('Position', [400 200 650 600],'Name','VUESR Imaging Toolbox - alpha','NumberTitle','off');
                        set(heightHistogram,'Toolbar','none','Menubar','none');                
                        pixelValueRange = [min(tool.I(:)), max(tool.I(:))];
                        tool.fName = fileName;
                    end
                case 1  %tool = VUESR(I)
                    tool.I = varargin{1}; position=[0 0 1 1];
                    heightHistogram= figure('Position', [400 200 600 600]);
                    set(heightHistogram,'Toolbar','none','Menubar','none')
                    pixelValueRange = [min(tool.I(:)), max(tool.I(:))];
                case 2  %tool = VUESR(I,position)
                    tool.I=varargin{1}; position=varargin{2};
                    heightHistogram=figure;
                    set(heightHistogram,'Toolbar','none','Menubar','none')
                    pixelValueRange=[min(tool.I(:)), max(tool.I(:))];
                case 3  %tool = VUESR(I,position,h)
                    tool.I=varargin{1};
                    position=varargin{2};
                    heightHistogram=varargin{3};
                    pixelValueRange=[min(tool.I(:)), max(tool.I(:))];
                case 4  %tool = VUESR(I,position,h,range)
                    tool.I=varargin{1};
                    position=varargin{2};
                    heightHistogram=varargin{3};
                    pixelValueRange=varargin{4};
            end
            
            if isempty(tool.I)
                tool.I=random('unif',-50,50,[100 100 3]);
            end
            %oldI = tool.I; %Save backup of original image data so that it can be recalled later.
                        if isempty(position)
                position=[0 0 1 1];
            end
            
            if isempty(heightHistogram)
                heightHistogram=figure;
            end
            
            if isempty(pixelValueRange)
                pixelValueRange=[min(tool.I(:)), max(tool.I(:))];
            end
               
            %Make the aspect ratio of the figure match that of the image
            if nargin<3
                set(heightHistogram,'Units','Pixels');
                pos=get(heightHistogram,'Position');
                Af=pos(3)/pos(4);   %Aspect Ratio of the figure
                AI=size(tool.I,2)/size(tool.I,1); %Aspect Ratio of the image
                if Af>AI    %Figure is too wide, make it taller to match
                    pos(4)=pos(3)/AI;
                elseif Af<AI    %Figure is too long, make it wider to match
                    pos(3)=AI*pos(4);
                end
                set(heightHistogram,'Position',pos)
                set(heightHistogram,'Units','normalized');
            end
            tool.handles.fig = heightHistogram;
            
            initializeVUESR(tool);
            
            %%
            % Create the panels and slider
            widthSidePanel = 30; %Pixel width of the side panels
            heightHistogram = 110; %Pixel height of the histogram panel
            widthButtons = 20; %Pixel size of the buttons
            
            createSliderandPanels(tool,position,pixelValueRange,widthSidePanel,heightHistogram);            
            
            %%
            % Set up mouse button controls
            fun=@(hObject,eventdata) imageButtonDownFunction(hObject,eventdata,tool);
            set(tool.handles.I,'ButtonDownFcn',fun)
            
            % Create the tool buttons
            wp = widthSidePanel;
            widthSidePanel = widthButtons;
            buff = (wp - widthSidePanel)/2;
            
            %%
            %Create the histogram plot
            tool.handles.HistAxes = ...
                axes('Position',[0.025, 0.15, 0.95, 0.55],...
                'Parent',tool.handles.Panels.Hist);
            im = tool.I(:,:,1);
            
            tool.centers = linspace(min(double(tool.I(:))),max(double(tool.I(:))),256);
            nElements = hist(im(:),tool.centers);
            nElements = nElements./max(nElements);
            tool.handles.HistLine=plot(tool.centers,nElements,'-w','LineWidth',1);
            set(tool.handles.HistAxes,'Color','none',...
                'XColor','w','YColor','w','FontSize',9,'YTick',[])
            axis on
            hold on
            axis fill
            xlim(get(gca,'Xlim'))
            
            tool.handles.Histrange(1) = plot([pixelValueRange(1),...
                pixelValueRange(1) pixelValueRange(1)],[0, 0.5, 1],'.-r');
            tool.handles.Histrange(2) = plot([pixelValueRange(2),...
                pixelValueRange(2) pixelValueRange(2)],[0, 0.5, 1],'.-r');
            tool.handles.Histrange(3) = plot([mean(pixelValueRange),...
                mean(pixelValueRange), mean(pixelValueRange)],[0, 0.5, 1],'.--r');
            
            tool.handles.HistImageAxes = axes('Position',[0.025 0.75 0.95 0.2],...
                'Parent',tool.handles.Panels.Hist);
            set(tool.handles.HistImageAxes,'Units','Pixels');
            pos = get(tool.handles.HistImageAxes,'Position');
            set(tool.handles.HistImageAxes,'Units','Normalized');
            
            tool.handles.HistImage = ...
                imshow(repmat(tool.centers,[round(pos(4)) 1]),pixelValueRange);
            set(tool.handles.HistImageAxes,'XColor','w','YColor','w',...
                'XTick',[],'YTick',[])
            axis on;
            axis normal;
            box on;
            
            tool.centers = tool.centers;
            fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,1);
            set(tool.handles.Histrange(1),'ButtonDownFcn',fun);
            fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,2);
            set(tool.handles.Histrange(2),'ButtonDownFcn',fun);
            fun = @(hObject,evnt)histogramButtonDownFunction(hObject,evnt,tool,3);
            set(tool.handles.Histrange(3),'ButtonDownFcn',fun);
            
            % Create histogram checkbox
            tool.handles.Tools.Hist = uicontrol(tool.handles.Panels.Tools,...
                'Style','Checkbox','String','Hist?',...
                'Position',[buff, buff, 2.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Show Histogram',...
                'BackgroundColor','k','ForegroundColor','w');
            fun=@(hObject,evnt) ShowHistogram(hObject,evnt,tool,wp,heightHistogram);
            set(tool.handles.Tools.Hist,'Callback',fun)
            lp = buff+2.5*widthSidePanel;
            
            %%
            % Set up the resize function
            fun=@(x,y) panelResizeFunction(x,y,tool,wp,heightHistogram,widthButtons);
            set(tool.handles.Panels.Large,'ResizeFcn',fun)
            
            
            % Create window and level boxes
            tool.handles.Tools.TW = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','text','String','W','Position',...
                [lp+buff buff widthSidePanel widthSidePanel],...
                'BackgroundColor','k','ForegroundColor','w',...
                'TooltipString','Window Width');
            tool.handles.Tools.W = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','Edit','String',...
                num2str(pixelValueRange(2)-pixelValueRange(1)),...
                'Position',[lp+buff+widthSidePanel buff 2*widthSidePanel widthSidePanel],...
                'TooltipString','Window Width');
            tool.handles.Tools.TL = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','text','String','L','Position',...
                [lp+2*buff+3*widthSidePanel, buff, widthSidePanel, widthSidePanel],...
                'BackgroundColor','k','ForegroundColor','w',...
                'TooltipString','Window Level');
            tool.handles.Tools.L = ...
                uicontrol(tool.handles.Panels.Tools,'Style','Edit','String',...
                num2str(mean(pixelValueRange)),'Position',...
                [lp+2*buff+4*widthSidePanel, buff, 2*widthSidePanel, widthSidePanel],...
                'TooltipString','Window Level');
            lp = lp+buff+7*widthSidePanel;
            
            % Create window and level callbacks
            fun = @(hobject,evnt) WindowLevel_callback(hobject,evnt,tool);
            set(tool.handles.Tools.W,'Callback',fun);
            set(tool.handles.Tools.L,'Callback',fun);
            
            % Create view restore button
            tool.handles.Tools.ViewRestore = ...
                uicontrol(tool.handles.Panels.Tools,'Style','pushbutton',...
                'String','','Position',[lp, buff, widthSidePanel, widthSidePanel],...
                'TooltipString','Reset Pan and Zoom');
            [iptdir, MATLABdir] = ipticondir;
            icon_save = makeToolbarIconFromPNG([iptdir '/overview_zoom_in.png']);
            set(tool.handles.Tools.ViewRestore,'CData',icon_save);
            fun = @(hobject,evnt) resetViewCallback(hobject,evnt,tool);
            set(tool.handles.Tools.ViewRestore,'Callback',fun)
            lp = lp + widthSidePanel + 2*buff;
            
            % Create grid checkbox and grid lines
            axes(tool.handles.Axes)
            tool.handles.Tools.Grid = ...
                uicontrol(tool.handles.Panels.Tools,'Style','checkbox',...
                'String','Grid?','Position',...
                [lp, buff, 2.5*widthSidePanel, widthSidePanel],...
                'BackgroundColor','k','ForegroundColor','w');
            nGrid = 7;
            nMinor = 4;
            x = linspace(1,size(tool.I,2),nGrid);
            y = linspace(1,size(tool.I,1),nGrid);
            hold on;
            tool.handles.grid=[];
            gColor=[255, 38, 38]./256;
            mColor=[255, 102, 102]./256;
            for i = 1:nGrid
                tool.handles.grid(end+1) = ...
                    plot([0.5 size(tool.I,2)-0.5],[y(i) y(i)],'-',...
                    'LineWidth',1.2,'HitTest','off','Color',gColor);
                tool.handles.grid(end+1) = ...
                    plot([x(i) x(i)],[0.5 size(tool.I,1)-0.5],'-',...
                    'LineWidth',1.2,'HitTest','off','Color',gColor);
                
                if i < nGrid
                    xm = linspace(x(i),x(i+1),nMinor+2);
                    xm = xm(2:end-1);
                    ym = linspace(y(i),y(i+1),nMinor+2);
                    ym = ym(2:end-1);
                    
                    for j = 1:nMinor
                        tool.handles.grid(end+1) = ...
                            plot([.5 size(tool.I,2)-.5],[ym(j) ym(j)],'-r',...
                            'LineWidth',.9,'HitTest','off','Color',mColor);
                        tool.handles.grid(end+1) = ...
                            plot([xm(j) xm(j)],[.5 size(tool.I,1)-.5],'-r',...
                            'LineWidth',.9,'HitTest','off','Color',mColor);
                    end
                end
            end
            tool.handles.grid(end+1) = ...
                scatter(0.5+size(tool.I,2)/2,0.5+size(tool.I,1)/2,'r','filled');
            set(tool.handles.grid,'Visible','off')
            fun = @(hObject,evnt) toggleGrid(hObject,evnt,tool);
            set(tool.handles.Tools.Grid,'Callback',fun)
            set(tool.handles.Tools.Grid,'TooltipString','Toggle Gridlines')
            lp = lp+3*widthSidePanel;
            
            % Create colormap pulldown menu
            mapNames = ...
                {'Gray','Hot','Jet','HSV','Cool',...
                'Spring','Summer','Autumn','Winter',...
                'Bone','Copper','Pink','Lines',...
                'colorcube','flag','prism','white'};
            tool.handles.Tools.Color = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','popupmenu',...
                'String',mapNames,...
                'Position',[lp, buff, 4*widthSidePanel, widthSidePanel]);
            fun = @(hObject,evnt) changeColormap(hObject,evnt,tool);
            set(tool.handles.Tools.Color,'Callback',fun)
            set(tool.handles.Tools.Color,'TooltipString','Select a colormap')
            lp = lp + 3*widthSidePanel;
            
            createButtons(tool,lp,buff,widthSidePanel);
            
        end

        function setPosition(tool,~)
            set(tool.handles.Panels.Large,'Position',newPosition)
        end
        
        function position = getPosition(tool)
            position = get(tool.handles.Panels.Large,'Position');
        end
        
        function setUnits(tool,units)
            set(tool.handles.Panels.Large,'Units',units)
        end
        
        function units = getUnits(tool)
            units = get(tool.handles.Panels.Large,'Units');
        end
        
        function setImage(varargin)
            switch nargin
                case 1
                    tool=varargin{1}; tool.I=random('unif',-50,50,[100 100 3]);
                    range=[-50 50];
                case 2
                    tool=varargin{1}; tool.I=varargin{2};
                    range=[min(tool.I(:)) max(tool.I(:))];
                case 3
                    tool=varargin{1}; tool.I=varargin{2};
                    range=varargin{3};
            end
            
            if isempty(tool.I)
                tool.I=random('unif',-50,50,[100 100 3]);
            end
            if isempty(range)
                range=[min(tool.I(:)) max(tool.I(:))];
            end
            
            
            
            % Update the histogram
            im=tool.I(:,:,1);
            tool.centers=linspace(min(tool.I(:)),max(tool.I(:)),256);
            nelements=hist(im(:),tool.centers);
            nelements=nelements./max(nelements);
            set(tool.handles.HistLine,'XData',tool.centers,'YData',nelements);
            axes(tool.handles.HistAxes);
            xlim([tool.centers(1) tool.centers(end)])
            axis fill
            
            %Update the window and level
            setWL(tool,diff(range),mean(range))
            
            %Update the image
            set(tool.handles.I,'CData',im)
            axes(tool.handles.Axes);
            xlim([0 size(tool.I,2)])
            ylim([0 size(tool.I,1)])
            
            %Update the gridlines
            axes(tool.handles.Axes);
            delete(tool.handles.grid)
            nGrid=7;
            nMinor=4;
            x=linspace(1,size(tool.I,2),nGrid);
            y=linspace(1,size(tool.I,1),nGrid);
            hold on;
            tool.handles.grid=[];
            gColor=[255 38 38]./256;
            mColor=[255 102 102]./256;
            for i=1:nGrid
                tool.handles.grid(end+1)=plot([.5 size(tool.I,2)-.5],[y(i) y(i)],'-','LineWidth',1.2,'HitTest','off','Color',gColor);
                tool.handles.grid(end+1)=plot([x(i) x(i)],[.5 size(tool.I,1)-.5],'-','LineWidth',1.2,'HitTest','off','Color',gColor);
                if i<nGrid
                    xm=linspace(x(i),x(i+1),nMinor+2); xm=xm(2:end-1);
                    ym=linspace(y(i),y(i+1),nMinor+2); ym=ym(2:end-1);
                    for j=1:nMinor
                        tool.handles.grid(end+1)=plot([.5 size(tool.I,2)-.5],[ym(j) ym(j)],'-r','LineWidth',.9,'HitTest','off','Color',mColor);
                        tool.handles.grid(end+1)=plot([xm(j) xm(j)],[.5 size(tool.I,1)-.5],'-r','LineWidth',.9,'HitTest','off','Color',mColor);
                    end
                end
            end
            tool.handles.grid(end+1)=scatter(.5+size(tool.I,2)/2,.5+size(tool.I,1)/2,'r','filled');
            toggleGrid(tool.handles.Tools.Grid,[],tool)
            
            %Update the slider
            setupSlider(tool)
            
            %Show the first slice
            showSlice(tool)
            
            
        end
        
        function I = getImage(tool)
            I=tool.I;
        end
        
        function handles=getHandles(tool)
            handles=tool.handles;
        end
        
        function setDisplayRange(tool,range)
            W=diff(range);
            L=mean(range);
            setWL(tool,W,L);
        end
        
        function range=getDisplayRange(tool)
            range=get(tool.handles.Axes,'Clim');
        end
        
        function setWindowLevel(tool,W,L)
            setWL(tool,W,L);
        end
        
        function [W,L] = getWindowLevel(tool)
            range=get(tool.handles.Axes,'Clim');
            W=diff(range);
            L=mean(range);
        end
        
        function ROI = getcurrentROI(tool)
            if ~isempty(tool.currentROI)
                if isvalid(tool.currentROI)
                    mask = createMask(tool.currentROI);
                    im=get(tool.handles.I,'CData');
                    stats= regionprops(mask,im,'Area','Perimeter','MaxIntensity','MinIntensity','MeanIntensity');
                    stats.STD=std(im(mask));
                    ROI.mask=mask;
                    ROI.stats=stats;
                end
            else
                ROI=[];
            end
        end
        
        function setCurrentSlice(tool,slice)
            showSlice(tool,slice)
        end
        
        function slice = getCurrentSlice(tool)
            slice=round(get(tool.handles.Slider,'value'));
        end
        
    end
    
    methods (Access = private)
        
        function addhandlesROI(tool,h)
            tool.handlesROI{end+1}=h;
        end
        
        function scrollWheel(~,evnt,tool)
            %Check to see if the mouse is hovering over the axis
            units=get(tool.handles.fig,'Units');
            set(tool.handles.fig,'Units','Pixels')
            point=get(tool.handles.fig, 'CurrentPoint');
            set(tool.handles.fig,'Units',units)
            
            units=get(tool.handles.Panels.Large,'Units');
            set(tool.handles.Panels.Large,'Units','Pixels')
            pos_p=get(tool.handles.Panels.Large,'Position');
            set(tool.handles.Panels.Large,'Units',units)
            
            units=get(tool.handles.Panels.Image,'Units');
            set(tool.handles.Panels.Image,'Units','Pixels')
            pos_a=get(tool.handles.Panels.Image,'Position');
            set(tool.handles.Panels.Image,'Units',units)
            
            xmin=pos_p(1)+pos_a(1); xmax=xmin+pos_a(3);
            ymin=pos_p(2)+pos_a(2); ymax=ymin+pos_a(4);
            
            if point(1)>=xmin && point(1)<=xmax && point(2)>=ymin && point(2)<=ymax
                newSlice=get(tool.handles.Slider,'value')-evnt.VerticalScrollCount;
                if newSlice>=1 && newSlice <=size(tool.I,3)
                    set(tool.handles.Slider,'value',newSlice);
                    showSlice(tool)
                end
            end
            
        end
        
        function showSlice(varargin)
            switch nargin
                case 1
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));
                case 2
                    tool=varargin{1};
                    n=varargin{2};
                otherwise
                    tool=varargin{1};
                    n=round(get(tool.handles.Slider,'value'));
            end
            
            if n < 1
                n=1;
            end
            
            if n > size(tool.I,3)
                n=size(tool.I,3);
            end
            
            set(tool.handles.I,'CData',tool.I(:,:,n))
            set(tool.handles.SliceText,'String',[num2str(n) '/' num2str(size(tool.I,3))])
            if get(tool.handles.Tools.Hist,'value')
                im=tool.I(:,:,n);
                nelements=hist(im(:),tool.centers); nelements=nelements./max(nelements);
                set(tool.handles.HistLine,'YData',nelements);
            end
            
        end
        
        function setupSlider(tool)
            n=size(tool.I,3);
            if n==1
                set(tool.handles.Slider,'visible','off');
            else
                set(tool.handles.Slider,'visible','on');
                set(tool.handles.Slider,'min',1,'max',size(tool.I,3),'value',1)
                set(tool.handles.Slider,'SliderStep',[1/(size(tool.I,3)-1) 1/(size(tool.I,3)-1)])
                fun=@(hobject,eventdata)showSlice(tool,[],hobject,eventdata);
                set(tool.handles.Slider,'Callback',fun);
            end
            
        end
        
        function setWL(tool,W,L)
            set(tool.handles.Axes,'Clim',[L-W/2 L+W/2])
            set(tool.handles.Tools.W,'String',num2str(W));
            set(tool.handles.Tools.L,'String',num2str(L));
            set(tool.handles.HistImageAxes,'Clim',[L-W/2 L+W/2])
            set(tool.handles.Histrange(1),'XData',[L-W/2 L-W/2 L-W/2])
            set(tool.handles.Histrange(2),'XData',[L+W/2 L+W/2 L+W/2])
            set(tool.handles.Histrange(3),'XData',[L L L])
        end
        
        function WindowLevel_callback(~,~,tool)
            range=get(tool.handles.Axes,'Clim');
            Wold=range(2)-range(1); Lold=mean(range);
            W=str2num(get(tool.handles.Tools.W,'String'));
            if isempty(W) || W<=0
                W=Wold;
                set(tool.handles.Tools.W,'String',num2str(W))
            end
            L=str2num(get(tool.handles.Tools.L,'String'));
            if isempty(L)
                L=Lold;
                set(tool.handles.Tools.L,'String',num2str(L))
            end
            setWL(tool,W,L)
        end
        
        function imageButtonDownFunction(~,~,tool)
            cp=get(tool.handles.Axes,'CurrentPoint');
            cp=[cp(1,1) cp(1,2)];
            switch get(tool.handles.fig,'SelectionType')
                case 'normal'   %Adjust window and level
                    CLIM=get(tool.handles.Axes,'Clim');
                    W=CLIM(2)-CLIM(1);
                    L=mean(CLIM);
                    fun=@(src,evnt) adjustContrastMouse(src,evnt,cp,tool.handles.Axes,tool,W,L);
                    fun2=@(src,evnt) buttonUpFunction(src,evnt,tool);
                    set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
                case 'extend'  %Zoom
                    fun=@(src,evnt) adjustZoomMouse(src,evnt,cp,tool.handles.Axes,tool);
                    fun2=@(src,evnt) buttonUpFunction(src,evnt,tool);
                    set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
                case 'alt'
                    xlims=get(tool.handles.Axes,'Xlim');
                    ylims=get(tool.handles.Axes,'Ylim');
                    fun=@(src,evnt) adjustPanMouse(src,evnt,cp,tool.handles.Axes,xlims,ylims);
                    fun2=@(src,evnt) buttonUpFunction(src,evnt,tool);
                    set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            end
        end
        
        function histogramButtonDownFunction(~,~,tool,line)
            
            switch line
                case 1 %Lower limit of range
                    fun=@(src,evnt) newLowerRangePosition(src,evnt,tool.handles.HistAxes,tool);
                    fun2=@(src,evnt) buttonUpFunction(src,evnt,tool);
                    set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
                case 2 %Upper limt of range
                    fun=@(src,evnt) newUpperRangePosition(src,evnt,tool.handles.HistAxes,tool);
                    fun2=@(src,evnt) buttonUpFunction(src,evnt,tool);
                    set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
                case 3 %Middle line
                    fun=@(src,evnt) newLevelRangePosition(src,evnt,tool.handles.HistAxes,tool);
                    fun2=@(src,evnt) buttonUpFunction(src,evnt,tool);
                    set(tool.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
            end
        end
        
        function toggleGrid(hObject,~,tool)
            if get(hObject,'Value')
                set(tool.handles.grid,'Visible','on')
            else
                set(tool.handles.grid,'Visible','off')
            end
        end
        
        function changeColormap(hObject,~,~)
            n=get(hObject,'Value');
            maps=get(hObject,'String');
            colormap(maps{n})
        end
        
        function exportROI(~,~,tool)
            if ~isempty(tool.currentROI)
                if isvalid(tool.currentROI)
                    mask = createMask(tool.currentROI);
                    im=get(tool.handles.I,'CData');
                    stats= regionprops(mask,im,'Area','Perimeter','MaxIntensity','MinIntensity','MeanIntensity');
                    stats.STD=std(im(mask));
                    ROI.mask=mask;
                    ROI.stats=stats;
                    name = inputdlg('Enter variable name');
                    name=name{1};
                    assignin('base', name, ROI)
                end
            end
        end
        
        function measureImageCallback(~,~,tool,type)
            
            switch type
                case 'ellipse'
                    fcn = makeConstrainToRectFcn('imellipse',[1 size(tool.I,2)],[1 size(tool.I,1)]);
                    h = imellipse(tool.handles.Axes,'PositionConstraintFcn',fcn);
                    addhandlesROI(tool,h)
                    fcn=@(pos) newROIposition(pos,h,tool);
                    addNewPositionCallback(h,fcn);
                    setPosition(h,getPosition(h));
                    tool.pointLog = [];
                            
                case 'rectangle'
                    fcn = makeConstrainToRectFcn('imrect',[1 size(tool.I,2)],[1 size(tool.I,1)]);
                    h = imrect(tool.handles.Axes,'PositionConstraintFcn',fcn);
                    addhandlesROI(tool,h)
                    fcn=@(pos) newROIposition(pos,h,tool);
                    addNewPositionCallback(h,fcn);
                    setPosition(h,getPosition(h));
                    tool.pointLog = [];
                    
                case 'polygon'
                    fcn = makeConstrainToRectFcn('impoly',[1 size(tool.I,2)],[1 size(tool.I,1)]);
                    h = impoly(tool.handles.Axes,'PositionConstraintFcn',fcn);
                    addhandlesROI(tool,h)
                    fcn=@(pos) newROIposition(pos,h,tool);
                    addNewPositionCallback(h,fcn);
                    setPosition(h,getPosition(h));
                    tool.pointLog = [];
                     
                case 'ruler'
                    h = imdistline(tool.handles.Axes);
                    fcn = makeConstrainToRectFcn('imline',[1 size(tool.I,2)],[1 size(tool.I,1)]);
                    setPositionConstraintFcn(h,fcn);
           
                case 'profile'
                    axes(tool.handles.Axes);
                    improfile(); grid on;
                otherwise
            end
            
            
        end
        
        function deletecurrentROI(~,~,tool)
            %if ~ISEMPTY(tool.currentROI)
                if isvalid(tool.currentROI)
                    delete(tool.currentROI)
                    set(tool.handles.ROIinfo,'String','STD:                    Mean:                    ');
                    tool.pointLog = [];
                end
            %end
        end
        
        function displayHelp(~,~,~)
            
            message={'Welcome to VUESR', ...
                '',...
                'Left Mouse Button: Window and Level', ...
                'Right Mouse Button: Pan', ...
                'Middle Mouse Button: Zoom', ...
                'Scroll Wheel: Change Slice',...
                '',...
                };
            
            msgbox(message)
        end
        
        function CropImageCallback(~,~,tool)
            [~, rect] = imcrop(tool.handles.Axes);
            rect=round(rect);
            setImage(tool, tool.I(rect(2):rect(2)+rect(4)-1,rect(1):rect(1)+rect(3)-1,:))
            tool.pointLog = [];
        end
        
        function AutoCropCallback(~,~,tool)
           %Crop the image to only show ultrasound measurements
           x = dicominfo(tool.fName);
           xmin = x.SequenceOfUltrasoundRegions.Item_1.RegionLocationMinX0;
           xmax = x.SequenceOfUltrasoundRegions.Item_1.RegionLocationMaxX1;
           ymin = x.SequenceOfUltrasoundRegions.Item_1.RegionLocationMinY0;
           ymax = x.SequenceOfUltrasoundRegions.Item_1.RegionLocationMaxY1;
           
           setImage(tool, tool.I(ymin:ymax,xmin:xmax,:));
        end
        
        function CropFramesCallback(~, ~,tool)
            g = figure('Visible','off','Position',[200,200,150,120],'NumberTitle', 'off','ToolBar','none','MenuBar','none','Name','Edit/Export Data');
                                  
              frameRange = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
                           'String', 'New frame range:', 'Position', [25 80 120 20], 'BackgroundColor', [.8,.8,.8]);
              currentRange = uicontrol('Style', 'text','FontSize',6,'HorizontalAlignment','left',...
                           'String', ['(Current Frame Range: ' '1 - ' num2str(size(tool.I,3)) ')'] , 'Position', [12 30 150 20], 'BackgroundColor', [.8,.8,.8]);
              minFrame = uicontrol('Style', 'edit','FontSize', 10,...
                         'String', num2str(tool.accFrames(1)), 'Position', [30 60 30 20]);
               maxFrame = uicontrol('Style', 'edit','FontSize', 10,...
                         'String', num2str(tool.accFrames(2)), 'Position', [ 80 60 30 20]);
               to = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
                           'String', 'to', 'Position', [64 60 12 20], 'BackgroundColor', [.8,.8,.8]);
                Crop = uicontrol('Style', 'pushbutton', 'String', 'Crop',...
                    'FontSize', 10,'Position', [10 10 60 20],'Callback', @Crop_callback);
                Cancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel',...
                    'FontSize', 10,'Position', [80 10 60 20], 'Callback', @Cancel_callback);

                set(g,'Name','Crop Frames')
                set([g,frameRange, currentRange, minFrame, to, maxFrame, Crop, Cancel], 'Units','normalized') 
                % Move the GUI to the center of the screen. 
                movegui(g,'center')
                % Make the GUI visible. 
                set(g,'Visible','on','Resize','off');

                function Cancel_callback(~,~)
                     %Closes window without saving changes
                      close(g);
                end
                function Crop_callback(~,~)
                    setImage(tool, tool.I(:,:,round(str2double(get(minFrame,'String'))):round(str2double(get(maxFrame,'String')))))
                    tool.pointLog = [];
                    tool.accFrames = [1 size(tool.I,3)-1];
                    close(g);
                    msgbox('New frame range set')
                end
        end
        
        function openImageCallback(~,~,tool)
                [fileName, filePath] = uigetfile('*.DCM;*.dcm;*.mat;*', ...
                    'Choose DICOM images to import', pwd, ...
                    'MultiSelect', 'off');
                if filePath(1) == 0
                    disp('No files chosen, exiting function')
                    return;
                else
                    disp(['User selected: ', fullfile(fileName)]);
                    [~, ~, ext] = fileparts(fileName);
                    if strcmp(ext,'.DCM') || strcmp(ext,'.dcm') || strcmp(ext,'')
                        tool.I = permute(dicomread(fileName),[1, 2, 4, 3]);
                    else
                        load( fileName);
                        tool.I = permute(image_change,[1 2 4 3]);
                    end       
                    tool.fName = fileName;
                end
                initializeVUESR(tool);
                setImage(tool,tool.I);
                initializeVUESR(tool);
                
        end
        
        function resetViewCallback(~,~,tool)
            set(tool.handles.Axes,'Xlim',get(tool.handles.I,'XData'))
            set(tool.handles.Axes,'Ylim',get(tool.handles.I,'YData'))
        end
        
        function createSliderandPanels(tool,position,pixelValueRange,widthSidePanel,heightHistogram)
            tool.handles.Panels.Large = ...
                uipanel(tool.handles.fig,'Position',position,'Title','');
            set(tool.handles.Panels.Large,'Units','Pixels');
            pos = get(tool.handles.Panels.Large,'Position');
            set(tool.handles.Panels.Large,'Units','normalized');
            
            tool.handles.Panels.Hist = ...
                uipanel(tool.handles.Panels.Large,'Units','Pixels', ...
                'Position',[widthSidePanel, pos(4)-widthSidePanel-heightHistogram, ...
                pos(3)-2*widthSidePanel, heightHistogram],'Title','');
            
            tool.handles.Panels.Image = ...
                uipanel(tool.handles.Panels.Large,'Units','Pixels',...
                'Position',[widthSidePanel, widthSidePanel, ...
                pos(3)-3.8*widthSidePanel, pos(4)-2*widthSidePanel],'Title','');
            
            tool.handles.Panels.Tools = ....
                uipanel(tool.handles.Panels.Large,'Units','Pixels', ....
                'Position',[0, pos(4)-widthSidePanel, ...
                pos(3), widthSidePanel],'Title','');
            
            tool.handles.Panels.ROItools = ...
                uipanel(tool.handles.Panels.Large,'Units','Pixels',...
                'Position',[pos(3)-2.8*widthSidePanel,  widthSidePanel, ...
               2.8*widthSidePanel, pos(4)-2*widthSidePanel],'Title','');
            
            tool.handles.Panels.Slider = ...
                uipanel(tool.handles.Panels.Large,'Units','Pixels',...
                'Position',[0, widthSidePanel, ...
                widthSidePanel, pos(4)-2*widthSidePanel],'Title','');
            
            tool.handles.Panels.Info = ...
                uipanel(tool.handles.Panels.Large,'Units','Pixels',...
                'Position',[0, 0, pos(3), widthSidePanel],'Title','');
            
            set(cell2mat(struct2cell(tool.handles.Panels)),...
                'BackgroundColor','k','ForegroundColor','w','HighlightColor','k')
            
            %%
            % Create slider to scroll through image stack
            tool.handles.Slider = ...
                uicontrol(tool.handles.Panels.Slider,'Style','Slider',...
                'Units','Normalized','Position',[0, 0, 1, 1],...
                'TooltipString','Change Slice (can use scroll wheel also)');
            setupSlider(tool)
            fun = @(scr,evnt) scrollWheel(scr,evnt,tool);
            set(tool.handles.fig,'WindowScrollWheelFcn',fun);
            
            % Create image axis
            tool.handles.Axes = ...
                axes('Position', [0, 0, 1, 1], ...
                'Parent',tool.handles.Panels.Image,'Color','none');
            tool.handles.I = imshow(tool.I(:,:,1),pixelValueRange);
            set(tool.handles.Axes,'Position',[0, 0, 1, 1],...
                'Color','none','XColor','r','YColor','r',...
                'GridLineStyle','--','LineWidth',1.5,...
                'XTickLabel','','YTickLabel','');
            axis off
            grid off
            axis fill
            
            % Set up image info display
            tool.handles.Info = uicontrol(tool.handles.Panels.Info,...
                'Style','text','String','(x,y) val','Units','Normalized',...
                'Position',[0, 0.1, 0.5, 0.8],'BackgroundColor','k',...
                'ForegroundColor','w','FontSize',12,...
                'HorizontalAlignment','Left');
            tool.handles.ROIinfo = uicontrol(tool.handles.Panels.Info,...
                'Style','text','String',...
                'STD:                    Mean:                    ',...
                'Units','Normalized','Position',[0.5, 0.1, 0.5, 0.8],...
                'BackgroundColor','k','ForegroundColor','w',....
                'FontSize',12,'HorizontalAlignment','Right');
            fun = @(src,evnt)getImageInfo(src,evnt,tool);
            set(tool.handles.fig,'WindowButtonMotionFcn',fun);
            tool.handles.SliceText=uicontrol(tool.handles.Panels.Tools,...
                'Style','text','String',['1/' num2str(size(tool.I,3))], ...
                'Units','Normalized','Position',[0.5, 0.1, 0.48, 0.8], ...
                'BackgroundColor','k','ForegroundColor','w', ...
                'FontSize',12,'HorizontalAlignment','Right');
        end
        
        % ***********************NEW***********************************************************
        function pixelCalibrateCallback(~,~,tool)
            %Select Points to Track
            uiwait(msgbox('Select two points with a know distance, then hit "Enter"'));
   
            figHandle = gcf;
            [poiX, poiY] = getpts(figHandle);

            poiX = round(poiX);     poiY = round(poiY);
            %Calculate the distance in pixels
            pixels = sqrt ((poiX(1) - poiX(2))^2+(poiY(1) - poiY(2))^2);
            
            %Have user input distance in cm
            prompt = {'Input distance between 2 points (cm):'};
                    dlg_title = 'Input';
                    num_lines = 1;
                    default = {'1'};
                    options.Resize='on';
                    options.WindowStyle='normal';
                    answer = inputdlg(prompt,dlg_title,num_lines,default,options);
                    cm = str2double(answer{1,1});
            
           tool.calibration = cm/pixels;
           disp(tool.calibration)
           msgbox('Calibration Complete')
                
        end
        
        function pixelSettingsCallback(~,~,tool)
            
            prompt = {'cm/pixel calibration factor:', '% of pixels analyzed (1-100%):','Frame range for accumulated strain (separated by a comma):','Mean Arterial Blood Pressure (mmHg)','Frame Rate (Hz):'};
                    dlg_title = 'Settings';
                    num_lines = [1, 60; 1, 60; 1, 60; 1, 60; 1,60];
                    cal = num2str(tool.calibration);
                    pixels = num2str(tool.pixelDensity);
                    oldpixels = tool.pixelDensity;
                    accRange = strcat([num2str((tool.accFrames(1))),',',num2str((tool.accFrames(2)))]);
                    oldRange = tool.accFrames;
                    bloodp = num2str(tool.map);
                    frameRate = num2str(tool.fRate);
                    %accRange = '1,10';
                    %disp(accRange); disp(size(accRange)); disp(cal); disp(size(cal)); disp(pixels);
                    default = {cal,pixels,accRange,bloodp,frameRate};
                    options.Resize='on';
                    options.WindowStyle='normal';
                    answer = inputdlg(prompt,dlg_title,num_lines,default,options);
                    if ~isempty(answer)
                        tool.calibration = str2double(answer{1,1});
                        tool.pixelDensity = str2double(answer{2,1});
                        tool.accFrames = str2num(answer{3,1});
                        tool.map = str2num(answer{4,1});
                        tool.fRate = str2num(answer{5,1});
                    end
                    if oldpixels ~= tool.pixelDensity | oldRange ~= tool.accFrames
                        tool.pointLog = [];
                    end
        end
        
        function pixelTrack2Callback(~,~,tool)
              
                    dicomFrames = size(tool.I,3);
                    newI = uint8(tool.I); 
                    J = uint8(tool.I);
                    % Get region of interest
                    framenum = 1;
                    objectFrame = J(:,:,framenum);
                   
                    %Select Points to Track
                    uiwait(msgbox('Select two points to track, then hit "Enter"'));
                    
                    figHandle = gcf;
                    [poiX, poiY] = getpts(figHandle);

                    poiX = round(poiX);     poiY = round(poiY);
                    nPoints = size(poiX,1);
                   
                    if  nPoints  ~= 2
                        warndlg('Please select only 2 points. Exiting function', 'Warning');
                        return;
                    end
                    tool.pointLog2 = zeros(nPoints, 2, dicomFrames);
                    points = [poiX, poiY];
                    pointImage = insertMarker(objectFrame, points, '+', 'Color', 'white');
                    newI(:,:,1) = pointImage(:,:,1);
                    pointDist = zeros(1,dicomFrames);
                    
                    % Create object tracker
                    tracker = vision.PointTracker('MaxBidirectionalError', 3);

                    % Initialize object tracker
                    initialize(tracker, points(:,:,1), objectFrame);

                    % Show the points getting tracked
                    while framenum <= dicomFrames
                         %Track the points     
                          frame =J(:,:,framenum);
                          [points, validity] = step(tracker, frame);
                          tool.pointLog2(:,:,framenum) = points;
                          out = insertMarker(frame, points(validity, :), '+', 'Color', 'white');
                          newI(:,:,framenum) = out(:,:,1);

                          %Compute the distance between the 2 points
                          pointDist(framenum) = sqrt ((tool.pointLog2(1,1,framenum) - tool.pointLog2(2,1,framenum))^2+(tool.pointLog2(1,2,framenum) - tool.pointLog2(2,2,framenum))^2);

                          framenum = framenum + 1;
                    end
                    
                    %Convert pixels to cm and percent
                    cm = tool.calibration;
                    tool.pointDistCm = pointDist.*cm;
                    pointDistPercent = pointDist.*100./max(max(pointDist));
                    
                    %Distensibility = dVolume / (Original V * dPressure)
                    %Compliance = dVolume / dPressure
                    pressure = tool.map*133.32; %mmHg to Pa
                    %volume = pi.*(tool.pointDistCm./200).^2; %Volume of circle in m2
                    %deltaV = max(volume) - min(volume);
                    %compliance = deltaV/(min(volume)*pressure);
                    
                    %hoopStress = pressure*mean(tool.pointDistCm)/(2*thickness);
                    %radialStress = -pressure/2;
                    
                    pointDistTp = tool.pointDistCm - min(tool.pointDistCm);
                    pointDistTpPercent = pointDistPercent-min(pointDistPercent);
                    
                    tool.zdiameter = mean(tool.pointDistCm);
                    tool.zdistensibility = mean(pointDistTp);
                    %tool.zcompliance = mean(compliance);
                    
                    sampleFreq = tool.fRate;
                    time = (1:dicomFrames)/sampleFreq;
                    
                    %Find heart rate by looking at mins in cardiac cycle
                    [~,indd]=lmin(tool.pointDistCm,1);
                    indd = indd/sampleFreq;
                    
                    avgbeat = mean(diff(indd));
                    tool.hRate = 60/avgbeat; %Heart rate in bpm
                    
%                     ImageViewer(newI); "Imageviewer function isn't often
%                     working in many computers. Instead of using this
%                     function parameters are saved for post processing."
                        save newI.mat;
                        
                    % Plot the tracked pixel movement in a switchable GUI
                    % Create and then hide the GUI as it is being constructed. 
                    f = figure('Visible','off','Position',[360,500,525,350]); %Left bottom width height

                    % Construct the components. 

                    hpopup = uicontrol('Style','popupmenu',... 
                        'String',{'Distance [cm]','Distance [%]','Distensibility [cm]','Distensibility [%]'},... 
                        'Position',[25,320,100,25],...
                        'Callback',{@popup_menu_Callback});

                    hdrawrange = uicontrol('Style','pushbutton',... 
                        'String','Select Strain Range','Position',[150,320,125,25],...
                        'Callback',{@drawrange_button_Callback});
                    
                    hcropframes =uicontrol('Style','pushbutton',... 
                        'String','Crop # frames','Position',[300,320,100,25],...
                        'Callback',{@cropframes_button_Callback});
                    
                    
                    ha = axes('Units','pixels','Position',[25,25,425,270]); 

                    % Change units to normalized so components resize automatically. 
                    set([f,ha,hpopup,hdrawrange, hcropframes],'Units','normalized');

                    % Create a plot in the axes. 
                    plot(time, tool.pointDistCm)
                    xlabel('Time [s]'); ylabel('Distance [cm]')
                    title('Distance between 2 points')
                    

                    % Assign the GUI a name to appear in the window title. 
                    set(f,'Name','Distance Between 2 Points')
                    % Move the GUI to the center of the screen. 
                    movegui(f,'center')
                    % Make the GUI visible. 
                    set(f,'Visible','on');

                    % Pop-up menu callback. Read the pop-up menu and display property

                        function popup_menu_Callback(source,~) 
                            % Determine the selected data set. 
                            str = get(source, 'String'); 
                            val = get(source,'Value'); 

                            % Set current data to the selected data set.
                            switch str{val}; 
                                case 'Distance [cm]' % User selects cm
                                    plot(time, tool.pointDistCm)
                                    xlabel('Time [s]'); ylabel('Distance [cm]')
                                    title('Distance between 2 points')
                                case 'Distensibility [cm]' % User selects cm
                                    plot(time, pointDistTp)
                                    xlabel('Time [s]'); ylabel('Distance [cm]')
                                    title('Distensibility between 2 points')    
                                case 'Distance [%]'   % User selects percent
                                    plot(time, pointDistPercent)
                                    xlabel('Time [s]'); ylabel('Distance [%]')
                                    title('Distance between 2 points')
                                case 'Distensibility [%]' % User selects cm
                                    plot(time, pointDistTpPercent)
                                    xlabel('Time [s]'); ylabel('Distance [%]')
                                    title('Distensibility between 2 points')   
                            end
                        end

                         function drawrange_button_Callback(~,~)
                                uiwait(msgbox({'Draw line for the lower limit of the accumulated strain range' 'Double click to save positions'}));
                                hmin = imline;
                                pos1 = wait(hmin);
                                uiwait(msgbox({'Draw line for the upper limit of the accumulated strain range.'  'Double click to save positions'}));
                                hmax = imline;
                                pos2 = wait(hmax);
                                tool.accFrames = [round((pos1(1,1)+pos1(2,1))*sampleFreq/2) , round((pos2(1,1)+pos2(2,1))*sampleFreq/2)];
                                msgbox(['Frame range set as: ' num2str(tool.accFrames(1)) '-' num2str(tool.accFrames(2))]);    
                         end
                         
                         function cropframes_button_Callback(~,~)
                                  g = figure('Visible','off','Position',[200,200,150,120],'NumberTitle', 'off','ToolBar','none','MenuBar','none','Name','Edit/Export Data');
                                  
                                  frameRange = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
                                               'String', 'New frame range:', 'Position', [25 80 120 20], 'BackgroundColor', [.8,.8,.8]);
                                  currentRange = uicontrol('Style', 'text','FontSize',6,'HorizontalAlignment','left',...
                                               'String', ['(Current Frame Range: ' '1 - ' num2str(size(tool.I,3)) ')'] , 'Position', [12 30 150 20], 'BackgroundColor', [.8,.8,.8]);
                                  minFrame = uicontrol('Style', 'edit','FontSize', 10,...
                                             'String', num2str(tool.accFrames(1)), 'Position', [30 60 30 20]);
                                   maxFrame = uicontrol('Style', 'edit','FontSize', 10,...
                                             'String', num2str(tool.accFrames(2)), 'Position', [ 80 60 30 20]);
                                   to = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
                                               'String', 'to', 'Position', [64 60 12 20], 'BackgroundColor', [.8,.8,.8]);
                                    Crop = uicontrol('Style', 'pushbutton', 'String', 'Crop',...
                                        'FontSize', 10,'Position', [10 10 60 20],'Callback', @Crop_callback);
                                    Cancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel',...
                                        'FontSize', 10,'Position', [80 10 60 20], 'Callback', @Cancel_callback);
                         
                                    set(g,'Name','Crop Frames')
                                    set([g,frameRange, currentRange, minFrame, to, maxFrame, Crop, Cancel], 'Units','normalized') 
                                    % Move the GUI to the center of the screen. 
                                    movegui(g,'center')
                                    % Make the GUI visible. 
                                    set(g,'Visible','on','Resize','off');
                                    
                                    function Cancel_callback(~,~)
                                         %Closes window without saving changes
                                          close(g);
                                    end
                                    function Crop_callback(~,~)
                                        setImage(tool, tool.I(:,:,round(str2double(get(minFrame,'String'))):round(str2double(get(maxFrame,'String')))))
                                        tool.pointLog = [];
                                        tool.accFrames = [1 size(tool.I,3)-1];
                                        close(g);
                                        msgbox('New frame range set')
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

                                   elseif x(i)==x(i+1)&&x(i)==x(i+2)	% 'long' flat spot
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
                           if filt>0 && ~isempty(indd),
                                if (indd(1)<= 3)||(indd(length(indd))+2>length(xx)), 
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
                        
                         
        end
            
        function pixelStrainCallback(~,~,tool)
                 tool.pointLog = tool.pointLog;
                 if (isempty(tool.pointLog))
                     msgbox('Tracking all points'); pause(1); close;
                     TrackAll(tool);
                 end
                   dicomFrames = size(tool.I,3);
                   choice = questdlg('Which measurement would you like to display?', ...
                        'Select strain type', 'Displacement','Strain','Strain');
                   
                    if ~isempty(tool.currentROI)                 
                                  if isvalid(tool.currentROI)
                                        pos = round(getPosition(tool.currentROI));
                                        pixelsX = pos(3); pixelsY = pos(4);
                                  else
                                      pixelsX =size(tool.I,2); pixelsY = size(tool.I,1);    
                                  end
                     else
                         pixelsX =size(tool.I,2); pixelsY = size(tool.I,1);    
                     end
                      
                    pixelsXtracked = round(pixelsX*tool.pixelDensity/100);
                    pixelsYtracked = round(pixelsY*tool.pixelDensity/100);
                    trackedPixels = pixelsXtracked*pixelsYtracked;
                    
                    startFrame = 1;
                    endFrame = size(tool.pointLog,3);
                    
                    switch choice
                       case 'Displacement'
                           count = 1;
                           for indFrames = startFrame:endFrame-1
                                    pointLogDiff(:,:,count) = tool.pointLog(:,:,indFrames+1) ...
                                    - tool.pointLog(:,:,startFrame); 
                                    count = count+1;
                           end
                            %Separate x and y differences for each point on the image
                            counter = 1;
                            for indFrame = startFrame:endFrame-1
                                for ind = 1:pixelsYtracked:trackedPixels
                                    xDiff(:,counter,indFrame) = pointLogDiff(ind:(ind+pixelsYtracked-1),1,indFrame);
                                    yDiff(:,counter,indFrame) = pointLogDiff(ind:(ind+pixelsYtracked-1),2,indFrame);
                                    counter = counter+1;
                                end
                                counter = 1;
                            end
                            totalDiff = sqrt(xDiff.^2 + yDiff.^2);
                            %disp([max(max(totalDiff)) mean(mean(totalDiff))])
%                             for ind =startFrame:endFrame-1
%                                 totalDiff(:,:,ind) = 205.*totalDiff(:,:,ind)./max(max(max(totalDiff)));
%                             end
                            for ind = startFrame:endFrame-1
                                totalDiff(:,:,ind) = medfilt2(totalDiff(:,:,ind));
                            end
%                             ImageViewer(totalDiff);
                                save totalDiff.mat;
                       case 'OldFrame to Frame'
                            % Simple difference
                            for indFrames = startFrame:endFrame
                                pointLogDiff(:,:,indFrames) = tool.pointLog(:,:,indFrames+1) ...
                                    - tool.pointLog(:,:,indFrames);       
                            end
                        case 'Strain'

                           counter = 1;
                           for indFrames = startFrame:endFrame
                                 for ind = 1:pixelsYtracked:trackedPixels
                                    xMatrix(:,counter,indFrames) = tool.pointLog(ind:(ind+pixelsYtracked-1),1,indFrames);
                                    yMatrix(:,counter,indFrames) = tool.pointLog(ind:(ind+pixelsYtracked-1),2,indFrames);
                                    counter = counter+1;
                                 end
                                 counter = 1;
                           end
                           %areas = zeros;
                           e_xy = zeros; e_xx = zeros; e_yy = zeros;
                           xLengths = zeros; yLengths = zeros; theta = zeros;
                           for indFrames = startFrame:endFrame
                               for i = 1:(size(xMatrix,1)-1)
                                   for j = 1:(size(xMatrix,2)-1)
                                       %Find the change in area to approximate normal strain                              
                                       %xLengths(i,j,indFrames) = .5*(xMatrix(i+1,j,indFrames)+xMatrix(i+1,j+1,indFrames)-xMatrix(i,j,indFrames)-xMatrix(i,j+1,indFrames));
                                       %yLengths(i,j,indFrames) = .5*(yMatrix(i+1,j,indFrames)+yMatrix(i+1,j+1,indFrames)-yMatrix(i,j,indFrames)-yMatrix(i,j+1,indFrames));
                                       areas(i,j,indFrames) = polyarea([xMatrix(i,j:j+1,indFrames), xMatrix(i+1,j+1,indFrames), xMatrix(i+1,j,indFrames)],[yMatrix(i,j:j+1,indFrames), yMatrix(i+1,j:j+1,indFrames)]);
                                       
                                       %Find shear strain from change in angle
                                       dU = [xMatrix(i+1,j+1,indFrames)-xMatrix(i,j+1,indFrames) yMatrix(i+1,j+1,indFrames)-yMatrix(i,j+1,indFrames)];
                                       dV = [xMatrix(i,j,indFrames)-xMatrix(i,j+1,indFrames) yMatrix(i,j,indFrames)-yMatrix(i,j+1,indFrames)];
                                       cosTheta = dot(dU,dV) ./ (norm(dU) * norm(dV));
                                       theta(i,j,indFrames) = acos(cosTheta);
                                       
                                       %Find normal and shear strains
                                           %e_xx(i,j,indFrames) = (xLengths(i,j,indFrames)-xLengths(i,j,indFrames-1))/xLengths(i,j,indFrames-1);
                                           %e_yy(i,j,indFrames) = (yLengths(i,j,indFrames)-yLengths(i,j,indFrames-1))/yLengths(i,j,indFrames-1);
                                           e_xy(i,j,indFrames) = theta(i,j,indFrames) - theta(i,j,1);
                                           e_xx(i,j,indFrames) = (areas(i,j,indFrames) - areas(i,j,1))./(areas(i,j,1));
                                           e_yy(i,j,indFrames) = 0;
                                       
                                   end
                               end
                           end
                           %disp ([max(max(e_xy(:,:,1:10)))  min(min(e_xy(:,:,1:10)))])
                           
                           for indFrames = startFrame+1:endFrame
                               %Find principal strains (for intensity)
                               e_1(:,:,indFrames) = .5*(e_xx(:,:,indFrames) + e_yy(:,:,indFrames)) + sqrt((.5*e_xx(:,:,indFrames).^2+.5*e_yy(:,:,indFrames)).^2 + (e_xy(:,:,indFrames)/2).^2); %
                               e_2(:,:,indFrames) = .5*(e_xx(:,:,indFrames) + e_yy(:,:,indFrames)) -  sqrt((.5*e_xx(:,:,indFrames).^2+.5*e_yy(:,:,indFrames)).^2 + (e_xy(:,:,indFrames)/2).^2 ); % 
                           end
                           %Determine which principal strain is the
                           %largest, then assign that as the strain value
                           %for the region
                           strain = zeros;
                           for indFrames = startFrame+1:endFrame
                               for i = 1:(size(xMatrix,1)-1)
                                   for j = 1:(size(xMatrix,2)-1)
                                       if isnan(e_1(i,j,indFrames)) || isinf(e_1(i,j,indFrames)) || isnan(e_2(i,j,indFrames)) || isinf(e_2(i,j,indFrames))
                                           strain(i,j,indFrames-1) = 0;
                                       elseif abs(e_1(i,j,indFrames)) >= abs(e_2(i,j,indFrames))
                                           strain(i,j,indFrames-1) = abs(e_1(i,j,indFrames));
                                       else
                                           strain(i,j,indFrames-1) = abs(e_2(i,j,indFrames));
                                       end
                                   end
                              end
                           end
                           strain = 200.*(strain)./(max(max(max(strain))));
                           
%                             ImageViewer(strain);
                                save strain.mat
                    end

                
                         function TrackAll(tool)

                            
                            firstFrame = tool.accFrames(1); 
                            lastFrame = tool.accFrames(2);
                            dicomFrames = lastFrame - firstFrame + 1;
                            newI = uint8(tool.I); 
                            J = uint8(tool.I);
                            if ~isempty(tool.currentROI)                 
                                  if isvalid(tool.currentROI)
                                        pos = round(getPosition(tool.currentROI));
                                  end
                            end
                            %Create grid of points on the image                    
                            if tool.pixelDensity >100
                                tool.pixelDensity = 100;
                            elseif tool.pixelDensity <=0;
                                tool.pixelDensity = 1;
                            end

                            if ~isempty(tool.currentROI)                 
                                  if isvalid(tool.currentROI)
                                      %If there is an roi get dimensions
                                      pixelsX = pos(3); pixelsY = pos(4);
                                      offsetX = round(pos(1)); offsetY = round(pos(2));
                                  else
                                      %If no roi get dimensions for entire image
                                      pixelsX =size(tool.I,2); pixelsY = size(tool.I,1);
                                      offsetX = 0.001; offsetY = 0.001;                              
                                  end
                            else
                                %If no roi get dimensions for entire image
                                pixelsX =round(size(tool.I,2)); pixelsY = round(size(tool.I,1));
                                offsetX = .0001; offsetY = .0001;   
                            end
                            % Find pixel spacing using pixel density factor (tool.pixelDensity)
                            pixelsBetweenX = (pixelsX-1)/round((pixelsX-1)*tool.pixelDensity/100); 
                            pixelsBetweenY = (pixelsY-1)/round((pixelsY-1)*tool.pixelDensity/100); 
                            count = 1;
                            countX = 1+offsetX;
                            % We get a grid that is %PixelDensity^2*(pixelsX*pixelsY)
                            points = zeros(1,2);
                            while countX <= pixelsX+offsetX
                                countY=1+offsetY;
                                while countY <= pixelsY+offsetY
                                    points(count,:) = [round(countX) round(countY)];
                                    countY = countY + pixelsBetweenY;
                                    count = count+1;
                                end
                                countX = countX + pixelsBetweenX;
                            end
                            nPoints = count - 1;
                            tool.pointLog = zeros(nPoints, 2, dicomFrames);
                            tool.pointLog(:,:,1) = points;
                            framenum = firstFrame+1;
                            objectFrame = newI(:,:,firstFrame);
                            pointImage = insertMarker(objectFrame, points, '+', 'Color', 'white');
                            newI(:,:,firstFrame) = pointImage(:,:,1);
                            quality = ones(1,dicomFrames);
                            % Create object tracker
                            tracker = vision.PointTracker('MaxBidirectionalError', 3);
                            ii = 2;
                            % Initialize object tracker
                            initialize(tracker, points(:,:,1), objectFrame);
                            h = waitbar(0,'Running pixel tracker...');
                            % Show the points getting tracked
                            while framenum <= lastFrame 
                                 %Track the points     
                                  frame =J(:,:,framenum);
                                  [points, validity] = step(tracker, frame);
                                  tool.pointLog(:,:,ii) = points;
                                  out = insertMarker(frame, points(validity, :), '+', 'Color', 'white');
                                  newI(:,:,framenum) = out(:,:,1);
                                  framenum = framenum + 1;  ii = ii +1;
                                  quality(ii) = sum(validity)/length(validity);
                                  

                                  waitbar(ii/dicomFrames)
                            end
                            close(h)
%                             ImageViewer(newI);
                            frames = (1:dicomFrames);
                            quality = quality*100;
                             %figure;
                             %plot(frames, quality)
                             %xlabel('Frames'); ylabel('% of Points Tracked')
                             %title('Tracking Quality')
                         end
                         
        end
        
        function pixelShearCallback(~,~,tool)
%             if ~isempty(tool.currentROI)                 
%                   if isvalid(tool.currentROI)
%                        if (isempty(tool.pointLog))
%                            msgbox('Please run pixel tracking first to get strain')
%                        else
                          
                            J = uint8(tool.I);
                            dicomFrames = size(J,3);
                            %Select Points to Track
                            uiwait(msgbox('Select 2 points, 1 on  the vessel edge, and 1 near the vessel center, then hit "Enter"'));
                            figHandle = gcf;
                            [poiX, poiY] = getpts(figHandle);
                            poiX = round(poiX);     poiY = round(poiY);
                            point = [poiX(1), poiY(1)];                       
                            nPoints = size(poiX,1);
                            if  nPoints  ~= 2
                                warndlg('Please select only 2 points. Exiting function', 'Warning');
                                return;
                            end
                            % Create object tracker
                            tracker = vision.PointTracker('MaxBidirectionalError', 3);

                            % Initialize object tracker
                            framenum=1;
                            objectFrame = J(:,:,framenum);
                            initialize(tracker, point(:,:,1), objectFrame);

                            % Show the points getting tracked
                            while framenum <= dicomFrames
                                 %Track the points     
                                  frame =J(:,:,framenum);
                                  [point, validity] = step(tracker, frame);
                                  points(:,:,framenum) = point;
                                  framenum = framenum + 1;
                            end
                            
                            slope = (poiY(2)-poiY(1))/(poiX(2)-poiX(1));
                            shearPoints = 15;
                            if abs(slope) >= 1.5
                                voffset = 1;
                                if poiY(1) > poiY(2)
                                    voffset = voffset * -1;
                                end
                                hoffset = voffset/slope;
                            else
                                hoffset = 1;
                                if poiX(1) > poiX(2)
                                    hoffset = hoffset * -1;
                                end
                                voffset = hoffset*slope;
                            end
                            for ind = 1:dicomFrames
                                for count = 2:shearPoints
                                    points(count,1,ind) = points(count-1,1,ind)+hoffset;
                                    points(count,2,ind) = points(count-1,2,ind)+voffset;
                                end
                            end
                            
                            pointsTracked = size(points,1);
                            shear = J;
                            % Create new image showing shear rate magnitudes
                            h = waitbar(0,'Calculating wall shear rate...');
                            for indFrame = 1:dicomFrames-1
                                waitbar(indFrame/dicomFrames)
                                for ind = 1:pointsTracked
%                                     IX = J(:,:,indFrame);                  %Frame 1
%                                     IY = J(:,:,indFrame+1);              %Frame 2
                                    %FILT = ones(5);                           %Filter matrix
                                    KRNL_LMT = [3 3];                   %Group of pixels you're trying to find in next image
                                    SRCH_LMT = [2 2];                   %Region
                                    POS = round(points(ind,:,indFrame));  %Origin of krnl and srch
                                    %[RHO]=corr2D(IX,IY,FILT,KRNL_LMT,SRCH_LMT,POS);
                                    [RHO]=newcorr2D(KRNL_LMT,SRCH_LMT,POS,indFrame);
                                    rho(ind,indFrame) = mean(mean(RHO));
                                    rho2(ind,indFrame) = max(max(RHO));
                                    %shear(POS(2)-2:POS(2)+2,POS(1)-2:POS(1)+2,indFrame) = max(max(RHO));
                                end
                            end
                            close(h);
                            %Normalize rho values to display as image
                            %intensities
                            for indFrame = 1:dicomFrames-1
                                for ind = 1:pointsTracked
                                    POS = round(points(ind,:,indFrame)); 
                                    maxrho = max(max(rho));
                                    newrho = 200.*rho./maxrho;
                                    shear(POS(2),POS(1),indFrame) = newrho(ind,indFrame);
                                end
                            end
%                             ImageViewer(shear);
                                   save shear.mat
                            for ind = 1:shearPoints
                                wallshear(ind) = mean(rho(ind,:));
                                wallshear2(ind) = mean(rho2(ind,:));
                            end
                            
                           
                            time = 1:dicomFrames-1;
                            z1 = rho(1,:); z2=rho(2,:); z3=rho(3,:); z4 = rho(4,:); z5 = rho(5,:);
                            figure;
                            d1(1:dicomFrames-1) = 1; d2(1:dicomFrames-1) = 2; d3(1:dicomFrames-1) = 3;
                            d4(1:dicomFrames-1) = 4; d5(1:dicomFrames-1) = 5;
                            plot3(d1,time,z1,d2,time,z2,d3,time,z3,d4,time,z4,d5,time,z5);
                            %surf(rho);
                            xlabel('Time'); ylabel('Distance from Wall'); zlabel('Wall Shear');
                            figure;
                            dist = 1:shearPoints;
                            plot(dist, wallshear2)
                            xlabel('Distance from Wall'); ylabel('Wall Shear'); 
                            title('Wall Shear')
                            
                            function correlation = newcorr2D(krnl,srch,pos,frame)
%
                                correlation = zeros(2*srch(1)+1,2*srch(2)+1);
                                for i = 1:(2*srch(1)+1)
                                    for j = 1:(2*srch(2)+1)
                                        x = -srch(1)+i-1;
                                        y = -srch(2)+j-1;
                                        kernel = J(pos(1)-krnl(1):pos(1)+krnl(1),pos(2)-krnl(2):pos(2)+krnl(2),frame);
                                        search = J(pos(1)-krnl(1)+x:pos(1)+krnl(1)+x,pos(2)-krnl(2)+y:pos(2)+krnl(2)+y,frame+1);
                                        correlation(i,j) = corr2(kernel,search);
                                    end
                                end
                            end
%                        end   
%                   else
%                        msgbox('Please select a region of interest');
%                        return;
%                   end
%             else
%                   msgbox('Please select a region of interest');
%                   return;  
%             end

        end
        
        function pixelWallCallback(~,~,tool)
            %Wall Strain
            J = uint8(tool.I);
           dicomFrames = size(tool.I,3);

            %Select Points to Track
            uiwait(msgbox('Select 2 points, 1 on  the vessel edge, and 1 near the vessel center, then hit "Enter"'));
            figHandle = gcf;
            [poiX, poiY] = getpts(figHandle);
            poiX = round(poiX);     poiY = round(poiY);
            point = [poiX(1), poiY(1)];
            
            slope = (poiY(2)-poiY(1))/(poiX(2)-poiX(1));
            if abs(slope) >= 1.5
                voffset = 4;
                if poiY(1) > poiY(2)
                    voffset = voffset * -1;
                end
                hoffset = voffset/slope;
            else
                hoffset = 4;
                if poiX(1) > poiX(2)
                    hoffset = hoffset * -1;
                end
                voffset = hoffset*slope;
            end
            point(2,1) = point(1,1)+hoffset;
            point(2,2) = point(1,2)+voffset;
            point(3,1) = point(1,1)-hoffset;
            point(3,2) = point(1,2)-voffset;
            
            points(:,:,1) = point;
            distX(1) = points(2,1,1)-points(3,1,1);
            distY(1) = points(2,2,1)-points(3,2,1);
            dist(1) = sqrt(distX(1)^2+distY(1)^2);

            % Create object tracker
            tracker = vision.PointTracker('MaxBidirectionalError', 1);
            
            % Initialize object tracker
            framenum=1;
            objectFrame = J(:,:,framenum);
            initialize(tracker, point(:,:,1), objectFrame);
            pointImage = insertMarker(objectFrame, points, '+', 'Color', 'white');
            newI(:,:,1) = pointImage(:,:,1);

            % Show the points getting tracked
            while framenum < dicomFrames
                 %Track the points     
                  frame =J(:,:,framenum);
                  [point, validity] = step(tracker, frame);
                  framenum = framenum + 1;
                  points(:,:,framenum) = point;
                  out = insertMarker(frame, point(validity, :), '+', 'Color', 'white');
                  newI(:,:,framenum) = out(:,:,1);
                  distX(framenum) = points(2,1,framenum)-points(3,1,framenum);
                  distY(framenum) = points(2,2,framenum)-points(3,2,framenum);
                  dist(framenum) = sqrt(distX(framenum)^2+distY(framenum)^2);
            end

            avgdist = mean(dist);
            for ind = 1:dicomFrames
                strain(ind) = (dist(ind)-avgdist)/avgdist;
            end
%             ImageViewer(newI);
            frame = 1:dicomFrames;
            figure;
            plot(frame, strain)
            xlabel('Distance from wall'); ylabel('Wall Strain')
            title('Wall Strain')            
        end
        
        function pixelEdgeCallback(~,~,tool)
            if ~isempty(tool.currentROI)                 
                  if isvalid(tool.currentROI)
                       %imageROI = tool.currentROI;
                       disp(tool.currentROI);
                      % GRAYTHRESH EDGE DETECT
                        indFrame = 1;
                        imageROI = uint8(tool.I);
                        nFrames = size(tool.I,3);
                        while indFrame <= nFrames
                            imageROI_adjusted(:,:,indFrame) = imadjust(imageROI(:,:,indFrame));
                            imageROI_level(indFrame) = graythresh(imageROI_adjusted(:,:,indFrame));
                            imageROI_BW(:,:,indFrame) = im2bw(imageROI_adjusted(:,:,indFrame),...
                                imageROI_level(indFrame)*.3);
                            indFrame = indFrame + 1;
                        end
                        imageROI_BW = uint8(imageROI_BW);
%                        ImageViewer(imageROI_BW)
                        % An interesting result
                        time = (1:nFrames)./16;
                        figure;
                        plot(time,imageROI_level)
                        xlabel('Time [s]')
                        ylabel('Graythreshold')
                        title('A heartbeat measure by image contrast')
                        else
                            msgbox('Please select a region of interest');
                            return;
                   end
             else
                  msgbox('Please select a region of interest');
                  return;
             end

        end
        
        function filterImageCallback(~,~,tool)
            for i=1:size(tool.I,3)
                    a(:,:,i) = medfilt2(tool.I(:,:,i));
            end
            tool.I = a;
        end
        
    end
end

function newLowerRangePosition(~,~,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
range(1)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(1)>=Xlims(1)
    setWL(tool,W,L)
end
end

function newUpperRangePosition(~,~,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
range(2)=cp(1);
W=diff(range);
L=mean(range);
if W>0 && range(2)<=Xlims(2)
    setWL(tool,W,L)
end
end

function newLevelRangePosition(~,~,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
range=get(tool.handles.Axes,'Clim');
Xlims=get(hObject,'Xlim');
L=cp(1);
W=diff(range);
if L>=Xlims(1) && L<=Xlims(2)
    setWL(tool,W,L)
end
end

function newROIposition(~,hObject,tool)
handlesROI=tool.handlesROI;
for i=1:length(handlesROI)
    if isvalid(handlesROI{i})
        setColor(handlesROI{i},'b');
    end
end
setColor(hObject,'r');
mask = createMask(hObject);
im=get(tool.handles.I,'CData');
m=mean(im(mask));
noise=std(im(mask));
set(tool.handles.ROIinfo,'String',['STD:' num2str(noise,'%+.4f') '   Mean:' num2str(m,'%+.4f')])
tool.currentROI=hObject;
end

function adjustContrastMouse(~,~,dp,hObject,tool,W,L)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
d=round(cp-dp);
W2=W+d(1); L=L-d(2);
if W2>=1
    W=W2;
end
setWL(tool,W,L)
end

function adjustZoomMouse(~,~,dp,hObject,tool)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
d=cp(2)-dp(2);
zFactor=.025;
if d>0
    zoom(1+zFactor)
elseif d<0
    zoom(1-zFactor)
end
fun=@(Newsrc,Newevnt) adjustZoomMouse(Newsrc,Newevnt,cp,tool.handles.Axes,tool);
set(tool.handles.fig,'WindowButtonMotionFcn',fun)
axis fill

end

function adjustPanMouse(~,~,map,hObject,xlims,ylims)
cp = get(hObject,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
d=(map-cp)/1.25;
set(hObject,'Xlim',xlims+d(1),'Ylim',ylims+d(2))
end

function buttonUpFunction(src,~,tool)

fun=@(src,evnt)getImageInfo(src,evnt,tool);
set(src,'WindowButtonMotionFcn',fun);

end

function getImageInfo(~,~,tool)
pos=round(get(tool.handles.Axes,'CurrentPoint'));
pos=pos(1,1:2);
Xlim=get(tool.handles.Axes,'Xlim');
Ylim=get(tool.handles.Axes,'Ylim');
n=round(get(tool.handles.Slider,'value'));
if n == 0
    n = 1;
end
if pos(1)>0 && pos(1)<=size(tool.I,2) && pos(1)>=Xlim(1) && pos(1) <=Xlim(2) && pos(2)>0 && pos(2)<=size(tool.I,1) && pos(2)>=Ylim(1) && pos(2) <=Ylim(2)
    set(tool.handles.Info,'String',['(' num2str(pos(1)) ',' num2str(pos(2)) ') ' num2str(tool.I(pos(2),pos(1),n))])
else
    set(tool.handles.Info,'String','(x,y) val')
end



end

function panelResizeFunction(~,~,tool,w,h,~)
units=get(tool.handles.Panels.Large,'Units');
set(tool.handles.Panels.Large,'Units','Pixels')
pos=get(tool.handles.Panels.Large,'Position');
set(tool.handles.Panels.Large,'Units',units)
if get(tool.handles.Tools.Hist,'value')
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-3.8*w pos(4)-2*w-h])
else
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-3.8*w pos(4)-2*w])
end
%set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
set(tool.handles.Panels.Hist,'Position',[w pos(4)-w-h pos(3)-2*w h])
set(tool.handles.Panels.Tools,'Position',[0 pos(4)-w pos(3) w])
set(tool.handles.Panels.ROItools,'Position',[pos(3)-2.8*w  w 2.8*w pos(4)-2*w])
set(tool.handles.Panels.Slider,'Position',[0 w w pos(4)-2*w])
set(tool.handles.Panels.Info,'Position',[0 0 pos(3) w])
axis(tool.handles.Axes,'fill');
%buff=(w-wbutt)/2;
%pos=get(tool.handles.Panels.ROItools,'Position');


end

function icon = makeToolbarIconFromPNG(filename)
% makeToolbarIconFromPNG  Creates an icon with transparent
%   background from a PNG image.

%   Copyright 2004 The MathWorks, Inc.
%   $Revision: 1.1.8.1 $  $Date: 2004/08/10 01:50:31 $

% Read image and alpha channel if there is one.
[icon,map,alpha] = imread(filename);

% If there's an alpha channel, the transparent values are 0.  For an RGB
% image the transparent pixels are [0, 0, 0].  Otherwise the background is
% cyan for indexed images.
if (ndims(icon) == 3) % RGB
    
    idx = 0;
    if ~isempty(alpha)
        mask = alpha == idx;
    else
        mask = icon==idx;
    end
    
else % indexed
    
    % Look through the colormap for the background color.
    for i=1:size(map,1)
        if all(map(i,:) == [0 1 1])
            idx = i;
            break;
        end
    end
    
    mask = icon==(idx-1); % Zero based.
    icon = ind2rgb(icon,map);
    
end

% Apply the mask.
icon = im2double(icon);

for p = 1:3
    
    tmp = icon(:,:,p);
    if ndims(mask)==3
        tmp(mask(:,:,p))=NaN;
    else
        tmp(mask) = NaN;
    end
    icon(:,:,p) = tmp;
    
end

end

function saveImage(~,~,tool)
cmap = colormap;
switch get(tool.handles.Tools.SaveOptions,'value')
    case 1 %Save just the current slice
        I=get(tool.handles.I,'CData'); lims=get(tool.handles.Axes,'CLim');
        I=gray2ind(mat2gray(I,lims),256);
        [FileName,PathName] = uiputfile({'*.png';'*.tif';'*.jpg';'*.bmp';'*.gif';'*.hdf'; ...
            '*.jp2';'*.pbm';'*.pcx';'*.pgm'; ...
            '*.pnm';'*.ppm';'*.ras';'*.xwd'},'Save Image');
        
        if FileName == 0
        else
            imwrite(I,cmap,[PathName FileName])
        end
    case 2 %Save entire dicom stack
        lims=get(tool.handles.Axes,'CLim');
        [FileName,PathName] = uiputfile({'*.dcm';'*.tif'},'Save Image Stack');
        [~, ~, ext] = fileparts(FileName);

        if FileName == 0
        else
            if strcmp(ext,'.tif') || strcmp(ext,'.TIF')
                for i=1:size(tool.I,3)
                    imwrite(gray2ind(mat2gray(tool.I(:,:,i),lims),256),cmap, [PathName FileName], 'WriteMode', 'append',  'Compression','none');
                end
            elseif strcmp(ext,'.DCM') || strcmp(ext,'.dcm')
                   dicomwrite(permute(uint8(tool.I), [1 2 4 3]), FileName);
            else
            end
        end
end
end

function exportCallback(~,~,tool)
     
    f = figure('Visible','off','Position',[360,500,320,280],'NumberTitle', 'off','ToolBar','none','MenuBar','none','Name','Edit/Export Data');
    
    % Create headers and text boxes
    patientIDText = uicontrol('Style', 'edit','FontSize', 10,...
           'String', num2str(tool.zpatientID), 'Position', [140 240 120 20]);
   dicomFileText = uicontrol('Style', 'text','FontSize', 10,'BackgroundColor', [.8,.8,.8],...
           'String', tool.fName, 'Position', [140 220 120 20]);
    locationText = uicontrol('Style', 'edit','FontSize', 7,...
           'String', cellstr(tool.zlocation), 'Position', [140 200 120 20]);
    diameterText = uicontrol('Style', 'edit','FontSize', 10,...
           'String', num2str(tool.zdiameter), 'Position', [140 180 120 20]);
    distensibilityText = uicontrol('Style', 'edit','FontSize', 10,...
           'String', num2str(tool.zdistensibility), 'Position', [140 160 120 20]);
    elasticityText = uicontrol('Style', 'edit','FontSize', 10,...
           'String', num2str(tool.zelasticity), 'Position', [140 120 120 20]);
    mapText = uicontrol('Style', 'edit','FontSize', 10,...
           'String', num2str(tool.map), 'Position', [140  80 120 20]);
    hrText = uicontrol('Style', 'edit','FontSize', 10,...
           'String', num2str(tool.hRate), 'Position', [140 60 120 20]);

     patientIDHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'Patient ID:', 'Position', [10 240 128 20], 'BackgroundColor', [.8,.8,.8]);
     dicomFileHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'DICOM File:', 'Position', [10 220 128 20], 'BackgroundColor', [.8,.8,.8]);
     locationHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'Blood Vessel Type:', 'Position', [10 200 128 20], 'BackgroundColor', [.8,.8,.8]);
      diameterHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'Blood Vessel Diam:', 'Position', [10 180 128 20], 'BackgroundColor', [.8,.8,.8]);
      distensibilityHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'Distensibility:', 'Position', [10 160 128 20], 'BackgroundColor', [.8,.8,.8]);
      elasticityHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'Elasticity:', 'Position', [10 120 128 20], 'BackgroundColor', [.8,.8,.8]);
      mapHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'Mean Art. Pressure:', 'Position', [10 80 128 20], 'BackgroundColor', [.8,.8,.8]);
      hrHeader = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'Heart Rate:', 'Position', [10 60 128 20], 'BackgroundColor', [.8,.8,.8]);
       
      diameterUnits = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'cm', 'Position', [262 180 30 20], 'BackgroundColor', [.8,.8,.8]);
      distensibilityUnits = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'cm', 'Position', [262 160 30 20], 'BackgroundColor', [.8,.8,.8]);
      elasticityUnits = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', '', 'Position', [262 120 30 20], 'BackgroundColor', [.8,.8,.8]);
      mapUnits = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'mmHg', 'Position', [262 80 40 20], 'BackgroundColor', [.8,.8,.8]);
      hrUnits = uicontrol('Style', 'text','FontSize', 10,'HorizontalAlignment','left',...
           'String', 'bpm', 'Position', [262 60 30 20], 'BackgroundColor', [.8,.8,.8]);
       
       
     % Create push buttons
    Export = uicontrol('Style', 'pushbutton', 'String', 'Export',...
        'FontSize', 11,'Position', [10 10 65 25],'Callback', @Export_callback);
     Ok = uicontrol('Style', 'pushbutton', 'String', 'Ok',...
        'FontSize', 11,'Position', [160 10 70 25],'Callback', @OK_callback);
    Cancel = uicontrol('Style', 'pushbutton', 'String', 'Cancel',...
        'FontSize', 11,'Position', [240 10 80 25], 'Callback', @Cancel_callback);
    
    %Create check boxes
    pulsgraph = uicontrol('Style', 'checkbox', 'FontSize', 9,'HorizontalAlignment','left',...
        'String', 'Include pulsatility graph', 'Position', [100 141 200 18], 'BackgroundColor', [.8,.8,.8]);
    elastgraph = uicontrol('Style', 'checkbox', 'FontSize', 9,'HorizontalAlignment','left',...
        'String', 'Include elasticity graph', 'Position', [100 101 200 18], 'BackgroundColor', [.8,.8,.8]);
    
    % Assign the GUI a name to appear in the window title. 
    set(f,'Name','Edit or Export Data')
     set([f, patientIDText, dicomFileText, locationText, diameterText, distensibilityText, elasticityText, mapText, hrText,...
              patientIDHeader, dicomFileHeader, locationHeader, diameterHeader, distensibilityHeader, elasticityHeader, mapHeader, hrHeader,...
              diameterUnits, distensibilityUnits, elasticityUnits, mapUnits, hrUnits, Export, Ok, Cancel, pulsgraph,elastgraph],'Units','normalized');
    
    % Move the GUI to the center of the screen. 
    movegui(f,'center')
    % Make the GUI visible. 
    set(f,'Visible','on','Resize','off');
    
    function Cancel_callback(~,~)
         %Closes window without saving changes
          close;
    end
    function OK_callback(~,~)
          
          choice = questdlg('Are you sure you want to overwrite data?', ...
                'Warning', ...
                'Yes','No','No');
            % Handle response
            switch choice
                case 'Yes'
                      %Saves changes, then closes window
                      tool.zpatientID = str2double(get(patientIDText,'String'));
                      tool.fName = get(dicomFileText,'String');
                      tool.zlocation =get(locationText, 'String');
                      tool.zdiameter =str2num(get(diameterText, 'String'));
                      tool.zdistensibility =str2num(get(distensibilityText, 'String'));
                      tool.map = str2num(get(mapText, 'String'));
                      tool.zelasticity =str2num(get(elasticityText,'String'));
                      tool.hRate = str2num(get(hrText, 'String'));
                      close;
                case 'No'
                    %Don't save changes
            end
    end

    function Export_callback(~,~)
          disp('Export')
          %Exports data to excel
          patientID = cellstr(get(patientIDText, 'String'));
          dicomfile = cellstr(get(dicomFileText, 'String'));
          location =  cellstr(get(locationText, 'String'));
          diameter =  cellstr(get(diameterText, 'String'));
          distensibility =  cellstr(get(distensibilityText, 'String'));
          MAP =  cellstr(get(mapText, 'String'));
          elasticity =  cellstr(get(elasticityText, 'String'));
          heartrate =  cellstr(get(hrText, 'String'));
          time = transpose((1:size(tool.I,3))/tool.fRate);
          pulsatility = transpose(tool.pointDistCm);
          disp(size(time)); disp(size(pulsatility));
          T1 = table(patientID, dicomfile, location, diameter, distensibility, MAP, elasticity, heartrate);     

          %Save data to .csv file
          fileName = strcat('patient', patientID, '_', location, '.xlsx');
          [filename,pathname] = uiputfile(fileName,'Save data file');                      
          if isequal(filename,0) || isequal(pathname,0)
             disp('User selected Cancel')
          else
             disp(['User selected ',fullfile(pathname,filename)])
             writetable(T1,fullfile(pathname,filename),'Sheet',1);
             if length(pulsatility) == length(time) 
                 if get(pulsgraph,'Value') == 1 && get(elastgraph,'Value') == 1
                       T2 = table(time, pulsatility);
                       writetable(T2,fullfile(pathname,filename),'Sheet',2);
                 elseif get(pulsgraph,'Value') == 1
                      T2 = table(time, pulsatility);
                      writetable(T2,fullfile(pathname,filename), 'Sheet',2);
                 elseif get(elastgraph,'Value') == 1
                 end
             else
                 msgbox('Variables are not the same size')
             end
             msgbox('Data export successful')      
          end
          
    end
        
end

function ShowHistogram(~,~,tool,w,h)
set(tool.handles.Panels.Large,'Units','Pixels')
pos=get(tool.handles.Panels.Large,'Position');
set(tool.handles.Panels.Large,'Units','normalized')

if get(tool.handles.Tools.Hist,'value')
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w-h])
else
    set(tool.handles.Panels.Image,'Position',[w w pos(3)-2*w pos(4)-2*w])
end
axis(tool.handles.Axes,'fill');
showSlice(tool)

end

function initializeVUESR(tool)
          
           % Initialize Variables
            tool.handlesROI = [];
            tool.currentROI = [];
            %tool.calibration = 1;
            tool.pixelDensity = 10;
            tool.accFrames = [1 size(tool.I,3)-1];
            tool.map = 50;
            tool.hRate = [];
            %tool.fRate = [];
            tool.I = double(tool.I);
            %tool.zlocation = []; 
            tool.zdiameter = [];
            tool.zdistensibility = []; 
            tool.zelasticity =[]; 
            tool.pointDistCm = [];
            
            %Do optical character recognition to find measurement location
            bottom = size(tool.I,1);
            BW = im2bw(uint8(tool.I(bottom/1.5:bottom,:,1)), 0.5);
            ocrResults = ocr(BW);
            str = ocrResults.Text;
            str = regexprep(str,'[^a-zA-Z]','');
             tool.zlocation =str;
            
            %Do optical character recognition to find the frame rate in hz
            right = size(tool.I,2);
            BW = im2bw(uint8(tool.I(:,round(right/1.5):right,1)), 0.5);
            ocrResults = ocr(BW);
            results = char(ocrResults.Text);
             k = strfind(results,'Hz');
             if length(k) > 1
                 k = k(2);
             end
             if ~isempty(k)
                 hz = results(k-3:k-2);
                 tool.fRate = str2double(hz);
            else
                disp('No frame rate detected')
             end
            
            %Use dicominfo to read important metadata from file
            x = dicominfo(tool.fName);
            
            tool.calibration = x.SequenceOfUltrasoundRegions.Item_1.PhysicalDeltaX;
            tool.studydate = x.StudyDate;
           
           %x.MechanicalIndex
            %tool.fRate = ocrResults.Text;
end

function createButtons(tool,lp,buff,widthSidePanel)
% BUTTONS
           [iptdir, MATLABdir] = ipticondir;
            % Create save button
            tool.handles.Tools.Save = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','pushbutton',...
                'String','',...
                'Position', [lp+1.1*widthSidePanel, buff, widthSidePanel, widthSidePanel]);
            icon_save = makeToolbarIconFromPNG([MATLABdir '/file_save.png']);
            set(tool.handles.Tools.Save,'CData',icon_save);
            lp = lp+2*widthSidePanel;
            
            tool.handles.Tools.SaveOptions = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','popupmenu',...
                'String',{'as single slice','as entire stack'},...
                'Position',[lp+buff, buff, 5.5*widthSidePanel, widthSidePanel]);
            fun = @(hObject,evnt) saveImage(hObject,evnt,tool);
            set(tool.handles.Tools.Save,'Callback',fun)
            set(tool.handles.Tools.Save,'TooltipString','Save image as slice or entire stack')
            lp = lp+5.7*widthSidePanel;
            
             % Export button
            tool.handles.Tools.Export = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','pushbutton',...
                'String','Edit/Export Data',...
                'Position', [lp+buff, buff, 5*widthSidePanel, widthSidePanel],...
                'TooltipString','Export Data To Excel');
            fun = @(hObject,evnt) exportCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Export,'Callback',fun)
            lp = lp+5.2*widthSidePanel;
            
            % Open New File
            tool.handles.Tools.OpenImage = ...
                uicontrol(tool.handles.Panels.Tools,...
                'Style','pushbutton',...
                'String','New Image',...
                'Position',[lp+buff, buff, 4*widthSidePanel, widthSidePanel],...
                'TooltipString','Open New Image to Analyze');
            fun=@(hObject,evnt) openImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.OpenImage ,'Callback',fun)

            % Create Circle ROI button
            tool.handles.Tools.CircleROI = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','',...
                'Position',[buff+2.25*widthSidePanel, buff+2*widthSidePanel, widthSidePanel, widthSidePanel],...
                'TooltipString','Create Elliptical Region of Interest');
            icon_ellipse = makeToolbarIconFromPNG([MATLABdir '/tool_shape_ellipse.png']);
            set(tool.handles.Tools.CircleROI,'Cdata',icon_ellipse)
            fun = @(hObject,evnt) measureImageCallback(hObject,evnt,tool,'ellipse');
            set(tool.handles.Tools.CircleROI,'Callback',fun)
            
            % Create Square ROI button
            tool.handles.Tools.SquareROI = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','',...
                'Position',[buff+.25*widthSidePanel, buff+2*widthSidePanel, widthSidePanel, widthSidePanel],...
                'TooltipString','Create Rectangular Region of Interest');
            icon_rect = makeToolbarIconFromPNG([MATLABdir '/tool_shape_rectangle.png']);
            set(tool.handles.Tools.SquareROI,'Cdata',icon_rect)
            fun = @(hObject,evnt) measureImageCallback(hObject,evnt,tool,'rectangle');
            set(tool.handles.Tools.SquareROI,'Callback',fun)
            
            % Create Polygon ROI button
            tool.handles.Tools.PolyROI = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','\_/',...
                'Position',[buff+1.25*widthSidePanel, buff+2*widthSidePanel, widthSidePanel, widthSidePanel],...
                'TooltipString','Create Polygon Region of Interest');
            fun = @(hObject,evnt) measureImageCallback(hObject,evnt,tool,'polygon');
            set(tool.handles.Tools.PolyROI,'Callback',fun)
            
            % Create Delete Button
            tool.handles.Tools.DeleteROI = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Delete ROI',...
                'Position',[buff, buff+widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Delete Region of Interest');
            fun = @(hObject,evnt) deletecurrentROI(hObject,evnt,tool);
            set(tool.handles.Tools.DeleteROI,'Callback',fun)
            
            % Create Export ROI Button
            tool.handles.Tools.ExportROI = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Export ROI',...
                'Position',[buff, buff, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Export Region of Interest to Workspace',...
                'ForegroundColor','k');
            fun = @(hObject,evnt) exportROI(hObject,evnt,tool);
            set(tool.handles.Tools.ExportROI,'Callback',fun)
            
            % Create Ruler button
            tool.handles.Tools.Ruler = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','',...
                'Position',[buff+2.25*widthSidePanel, buff+6.25*widthSidePanel, widthSidePanel, widthSidePanel],...
                'TooltipString','Measure Distance');
            icon_distance = makeToolbarIconFromPNG([MATLABdir '/tool_line.png']);
            set(tool.handles.Tools.Ruler,'CData',icon_distance);
            fun = @(hObject,evnt) measureImageCallback(hObject,evnt,tool,'ruler');
            set(tool.handles.Tools.Ruler,'Callback',fun)
            
            % Create Line Profile button
            tool.handles.Tools.Profile = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','',...
                'Position',[buff+1.25*widthSidePanel, buff+6.25*widthSidePanel, widthSidePanel, widthSidePanel],...
                'TooltipString','Get Line Profile');
            icon_profile = makeToolbarIconFromPNG([iptdir '/profile.png']);
            set(tool.handles.Tools.Profile,'Cdata',icon_profile)
            fun = @(hObject,evnt) measureImageCallback(hObject,evnt,tool,'profile');
            set(tool.handles.Tools.Profile,'Callback',fun)
            
            % Create Crop tool button
            tool.handles.Tools.Crop = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','',...
                'Position',[buff+.25*widthSidePanel, buff+6.25*widthSidePanel, widthSidePanel, widthSidePanel],...
                'TooltipString','Crop Image');
            icon_profile = makeToolbarIconFromPNG([iptdir '/crop_tool.png']);
            set(tool.handles.Tools.Crop ,'Cdata',icon_profile)
            fun=@(hObject,evnt) CropImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Crop ,'Callback',fun)
            
            % Create Crop # frames button
            tool.handles.Tools.Cropframes = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','# frames',...
                'Position',[buff+.25*widthSidePanel, buff + 4.25*widthSidePanel, 3*widthSidePanel, widthSidePanel],...
                'TooltipString','Crop # of frames in the cine loop',...
                'ForegroundColor','k');
            fun=@(hObject,evnt) CropFramesCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Cropframes ,'Callback',fun)
            
            % Create Auto Crop button
            tool.handles.Tools.AutoCrop = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Auto Crop',...
                'Position',[buff+.25*widthSidePanel, buff + 5.25*widthSidePanel, 3*widthSidePanel, widthSidePanel],...
                'TooltipString','Automatically crop image',...
                'ForegroundColor','k');
            fun=@(hObject,evnt) AutoCropCallback(hObject,evnt,tool);
            set(tool.handles.Tools.AutoCrop ,'Callback',fun)
            
            
            % ********************************NEW STUFF**************************

            %Filter image
            tool.handles.Tools.FilterImage = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Filter',...
                'Position',[buff, buff+20*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Use median filter to smooth image');
            fun=@(hObject,evnt) filterImageCallback(hObject,evnt,tool);
            set(tool.handles.Tools.FilterImage ,'Callback',fun)
            
            % Create 2 pixel tracking button
            tool.handles.Tools.Track2 = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Pulsatility',...
                'Position',[buff, buff+12*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Track 2 Points in the Image ');
            fun=@(hObject,evnt) pixelTrack2Callback(hObject,evnt,tool);
            set(tool.handles.Tools.Track2 ,'Callback',fun)
            
            %Create Strain button
            tool.handles.Tools.Strain = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Strain',...
                'Position',[buff, buff+11*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Find Strain for Entire Region');
            fun=@(hObject,evnt) pixelStrainCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Strain ,'Callback',fun)
            
            %Create Wall Shear button
            tool.handles.Tools.Shear = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Shear',...
                'Position',[buff, buff+10*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Find Wall Shear Rate in Region of Interest ');
            fun=@(hObject,evnt) pixelShearCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Shear ,'Callback',fun)

            %Create Wall Strain button
            tool.handles.Tools.Wall = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Wall Strain',...
                'Position',[buff, buff+9*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Find strain near the vessel wall');
            fun=@(hObject,evnt) pixelWallCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Wall ,'Callback',fun)
             
            %Create Calibration Button
            tool.handles.Tools.Calibrate = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Calibrate',...
                'Position',[buff, buff+16*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Calibrate image pixels to cm ');
            fun = @(hObject,evnt) pixelCalibrateCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Calibrate,'Callback',fun)
            
            %Create Settings Button
            tool.handles.Tools.Settings = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Settings',...
                'Position',[buff, buff+17*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','File Settings');
            fun = @(hObject,evnt) pixelSettingsCallback(hObject,evnt,tool);
            set(tool.handles.Tools.Settings,'Callback',fun)
            
            % Create Help Button
            tool.handles.Tools.Help = ...
                uicontrol(tool.handles.Panels.ROItools,...
                'Style','pushbutton',...
                'String','Help',...
                'Position',[buff, buff+15*widthSidePanel, 3.5*widthSidePanel, widthSidePanel],...
                'TooltipString','Help with VUESR');
            fun = @(hObject,evnt) displayHelp(hObject,evnt,tool);
            set(tool.handles.Tools.Help,'Callback',fun)
                      
             %Create text boxes for user guidance
             tool.handles.Tools.SetUp = uicontrol(tool.handles.Panels.ROItools,'Style','text',...
                'String','Set Up','BackgroundColor','k','ForegroundColor','w','FontWeight','bold',...
                'Position',[buff, buff+18*widthSidePanel, 3.5*widthSidePanel, widthSidePanel]);
            tool.handles.Tools.ROI = uicontrol(tool.handles.Panels.ROItools,'Style','text',...
                'String','ROI Tools','BackgroundColor','k','ForegroundColor','w','FontWeight','bold',...
                'Position',[buff, buff+3*widthSidePanel, 3.5*widthSidePanel, 1*widthSidePanel]);
            tool.handles.Tools.Image = uicontrol(tool.handles.Panels.ROItools,'Style','text',...
                'String','Image Tools','BackgroundColor','k','ForegroundColor','w','FontWeight','bold',...
                'Position',[buff, buff+7.25*widthSidePanel, 3.5*widthSidePanel, widthSidePanel]);        
            tool.handles.Tools.Analyze = uicontrol(tool.handles.Panels.ROItools,'Style','text',...
                'String','Analysis','BackgroundColor','k','ForegroundColor','w','FontWeight','bold',...
                'Position',[buff, buff+13*widthSidePanel, 3.5*widthSidePanel, widthSidePanel]);        
%             tool.handles.Tools.ImageTracking = uicontrol(tool.handles.Panels.ROItools,'Style','text',...
%                 'String', 'Image Tracking','BackgroundColor','k','ForegroundColor','w','FontWeight','bold',...
%                 'Position',[buff, buff+15*widthSidePanel, 3.5*widthSidePanel, 2*widthSidePanel]);
            
            % Set font size of all the tool objects
            set(cell2mat(struct2cell(tool.handles.Tools)),...
                'FontSize',9,...
                'Units','Pixels')
            

end