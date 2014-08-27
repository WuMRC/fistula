load mri

videoOriginal = permute(D, [1 2 4 3]);
imageOriginal = videoOriginal(:,:,27);
%imageOriginal = checkerboard(20);
%implay(videoOriginal)

%% UP/DOWN

upPerFrame = 1;
translateUp = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, 0], 'OutputSize', 'Same as input image');

nFrames = 50;
imageUp = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageUp(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageUp(:,:,indFrames) = step(translateUp,imageUp(:,:,indFrames-1));
    %imageUp = uint8(imageUp);
end
%imageUp = imageUp./max(max(max(imageUp)));
imageUp = uint8(imageUp);
%implay(imageUp)
imageUpdcm = permute(imageUp, [1 2 4 3]);


%% LEFT/RIGHT 

leftPerFrame = 1;
translateLeft = vision.GeometricTranslator(...r
    'Offset', [0, -leftPerFrame], 'OutputSize', 'Same as input image');


nFrames = 50;
imageSide = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageSide(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageSide(:,:,indFrames) = step(translateLeft,imageSide(:,:,indFrames-1));
end
%imageSide = imageSide./max(max(max(imageSide)));
imageSide = uint8(imageSide);
%implay(imageSide)
imageSidedcm = permute(imageSide, [1 2 4 3]);

%% DIAGONAL  

upPerFrame = 1;
leftPerFrame = 1;
translateDiag = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, -leftPerFrame], 'OutputSize', 'Same as input image');


nFrames = 50;
imageDiag = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageDiag(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageDiag(:,:,indFrames) = step(translateDiag,imageDiag(:,:,indFrames-1));
end
%imageDiag = imageDiag./max(max(max(imageDiag)));
imageDiag = uint8(imageDiag);
implay(imageDiag)
imageDiagdcm = permute(imageDiag, [1 2 4 3]);

%% ROTATE  

anglePerFrame = 10; %in degrees
% rotation = vision.GeometricRotator(...
%     'Angle', anglePerFrame, 'OutputSize', 'Same as input image');


nFrames = 50;
imageRotate = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageRotate(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
%     imageRotate(:,:,indFrames) = step(rotation,imageRotate(:,:,indFrames-1));
    imageRotate(:,:,indFrames) = imrotate(...
        imageRotate(:,:,indFrames-1),-anglePerFrame,'bicubic','crop');

end
%imageRotate = imageRotate./max(max(max(imageRotate)));
imageRotate = uint8(imageRotate);
%implay(imageRotate)
imageRotatedcm = permute(imageRotate, [1 2 4 3]);

%% ROTATE  

% anglePerFrame = 89; %in degrees
% % rotation = vision.GeometricRotator(...
% %     'Angle', anglePerFrame, 'OutputSize', 'Same as input image');
% 
% 
% nFrames = 50;
% imageRotate = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
% imageRotate(:,:,1) = imageOriginal;
% for indFrames = 2:nFrames
% %     imageRotate(:,:,indFrames) = step(rotation,imageRotate(:,:,indFrames-1));
%     imageRotate(:,:,indFrames) = imrotate(...
%         imageRotate(:,:,indFrames-1),-anglePerFrame,'bicubic','crop');
% 
%     endv
% %implay(imageRotate)
% imageRotate = uint8(imageRotate);
% imageRotdcm = permute(imageRotate, [1 2 4 3]);
%% ROTATE and TRANS

anglePerFrame = 5; %in degrees

upPerFrame = 1;
leftPerFrame = 1;

translateDiag = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, -leftPerFrame], 'OutputSize', 'Same as input image');

nFrames = 50;
imageRotate = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageRotate(:,:,1) = imageOriginal;
imageRotandTrans = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageRotandTrans(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageRotate(:,:,indFrames) = imrotate(...
        imageRotate(:,:,indFrames-1),-anglePerFrame,'bicubic','crop');

end
for indFrames = 2:nFrames
    imageRotandTrans(:,:,indFrames) = step(translateDiag,imageRotate(:,:,indFrames));
    upPerFrame = upPerFrame + 1;
    leftPerFrame = leftPerFrame + 1;
    translateDiag = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, -leftPerFrame], 'OutputSize', 'Same as input image');
end

%imageRotandTrans = imageRotandTrans./max(max(max(imageRotandTrans)));
imageRotandTrans = uint8(imageRotandTrans);
%implay(imageRotandTrans)
imageRotandTransdcm = permute(imageRotandTrans, [1 2 4 3]);