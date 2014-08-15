load mri

videoOriginal = permute(D,[1 2 4 3]);
imageOriginal = videoOriginal(:,:,27);
imageOriginal = checkerboard(20);


%% UP/DOWN

upPerFrame = 1;
translateUp = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, 0], 'OutputSize', 'Same as input image');

nFrames = 100;
imageUp = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageUp(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageUp(:,:,indFrames) = step(translateUp,imageUp(:,:,indFrames-1));
end

implay(imageUp./max(max(max(imageUp))))

%% LEFT/RIGHT 

leftPerFrame = 1;
translateLeft = vision.GeometricTranslator(...
    'Offset', [0, -leftPerFrame], 'OutputSize', 'Same as input image');


nFrames = 100;
imageSide = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageSide(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageSide(:,:,indFrames) = step(translateLeft,imageSide(:,:,indFrames-1));
end

implay(imageSide./max(max(max(imageSide))))

%% DIAGONAL  

upPerFrame = 1;
leftPerFrame = 1;
translateDiag = vision.GeometricTranslator(...
    'Offset', [-upPerFrame, -leftPerFrame], 'OutputSize', 'Same as input image');


nFrames = 100;
imageUp = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageUp(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
    imageUp(:,:,indFrames) = step(translateDiag,imageUp(:,:,indFrames-1));
end

implay(imageUp./max(max(max(imageUp))))

%% ROTATE  

anglePerFrame = 30; %in degrees
% rotation = vision.GeometricRotator(...
%     'Angle', anglePerFrame, 'OutputSize', 'Same as input image');


nFrames = 100;
imageRotate = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageRotate(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
%     imageRotate(:,:,indFrames) = step(rotation,imageRotate(:,:,indFrames-1));
    imageRotate(:,:,indFrames) = imrotate(...
        imageRotate(:,:,indFrames-1),-anglePerFrame,'bicubic','crop');

end

implay(imageRotate./max(max(max(imageRotate))))

%% ROTATE  

anglePerFrame = 89; %in degrees
% rotation = vision.GeometricRotator(...
%     'Angle', anglePerFrame, 'OutputSize', 'Same as input image');


nFrames = 100;
imageRotate = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageRotate(:,:,1) = imageOriginal;
for indFrames = 2:nFrames
%     imageRotate(:,:,indFrames) = step(rotation,imageRotate(:,:,indFrames-1));
    imageRotate(:,:,indFrames) = imrotate(...
        imageRotate(:,:,indFrames-1),-anglePerFrame,'bicubic','crop');

end

implay(imageRotate./max(max(max(imageRotate))))