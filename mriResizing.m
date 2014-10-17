load mri

videoOriginal = permute(D, [1 2 4 3]);
imageOriginal = videoOriginal(:,:,27);

%% UP/DOWN


nFrames = 50;

imageResize = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageResize(:,:,1) = imageOriginal;
for indFrames = 2:nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), .98,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
    disp(1)
end
for indFrames = nFrames/5+1:2*nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), 1.02,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
    disp(2)
end
for indFrames = 2*nFrames/5+1:3*nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), .98,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
    disp(3)
end
for indFrames = 3*nFrames/5+1:4*nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), 1.02,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
    disp(4)
end
for indFrames = 4*nFrames/5+1:nFrames
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), .98,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
    disp(5)
end
%imageSize = imageSize./max(max(max(imageSize)));
imageResize = uint8(imageResize);
implay(imageResize)
imageResizedcm = permute(imageResize, [1 2 4 3]);