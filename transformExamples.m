load mri

videoOriginal = permute(D,[1 2 4 3]);
imageOriginal = videoOriginal(:,:,27);
%imageOriginal = checkerboard(20);


%% UP/DOWN

upPerFrame = 50;
translateUp = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, 0], 'OutputSize', 'Same as input image');

nFrames = 30;
imageUp = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageUp(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageUp(:,:,indFrames) = step(translateUp,imageUp(:,:,indFrames-1));
end
imageUp = imageUp./max(max(max(imageUp)));
%implay(imageUp)

%imageUp = permute(imageUp, [1 2 4 3]);
%dicomwrite(imageUp, 'mriUp.dcm');

%% LEFT/RIGHT 

leftPerFrame = 1;
translateLeft = vision.GeometricTranslator(...
    'Offset', [0, -leftPerFrame], 'OutputSize', 'Same as input image');


nFrames = 30;
imageSide = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageSide(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageSide(:,:,indFrames) = step(translateLeft,imageSide(:,:,indFrames-1));
end
imageSide = imageSide./max(max(max(imageSide)));
%implay(imageSide)


%% DIAGONAL  

upPerFrame = 1;
leftPerFrame = 1;
translateDiag = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, -leftPerFrame], 'OutputSize', 'Same as input image');


nFrames = 30;
imageUp = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageUp(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageUp(:,:,indFrames) = step(translateDiag,imageUp(:,:,indFrames-1));
end
imageDiag = imageUp./max(max(max(imageUp)));
%implay(imageDiag)

%% ROTATE  

anglePerFrame = 30; %in degrees
% rotation = vision.GeometricRotator(...
%     'Angle', anglePerFrame, 'OutputSize', 'Same as input image');


nFrames = 30;
imageRotate = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageRotate(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
%     imageRotate(:,:,indFrames) = step(rotation,imageRotate(:,:,indFrames-1));
    imageRotate(:,:,indFrames) = imrotate(...
        imageRotate(:,:,indFrames-1),-anglePerFrame,'bicubic','crop');

end
imageRotate = imageRotate./max(max(max(imageRotate)));
%implay(imageRotate)


%% ROTATE  

anglePerFrame = 89; %in degrees
% rotation = vision.GeometricRotator(...
%     'Angle', anglePerFrame, 'OutputSize', 'Same as input image');


nFrames = 30;
imageRotate = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageRotate(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
%     imageRotate(:,:,indFrames) = step(rotation,imageRotate(:,:,indFrames-1));
    imageRotate(:,:,indFrames) = imrotate(...
        imageRotate(:,:,indFrames-1),-anglePerFrame,'bicubic','crop');

end
imageRotate = imageRotate./max(max(max(imageRotate)));
%implay(imageRotate)

%% ROTATE and TRANS

anglePerFrame = 5; %in degrees

upPerFrame = 1;
leftPerFrame = 1;

translateDiag = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, -leftPerFrame], 'OutputSize', 'Same as input image');

nFrames = 30;
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

imageRotandTrans = imageRotandTrans./max(max(max(imageRotandTrans)));
%implay(imageRotandTrans)