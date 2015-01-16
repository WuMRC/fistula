load mri

videoOriginal = permute(D, [1 2 4 3]);
imageOriginal = videoOriginal(:,:,27);

%% Resize with Movement

nFrames = 50;

imageResize = zeros(size(imageOriginal,1), size(imageOriginal,2), nFrames);
imageResize(:,:,1) = imageOriginal;
for indFrames = 2:nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), .98,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
end
for indFrames = nFrames/5+1:2*nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), 1.02,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
end
for indFrames = 2*nFrames/5+1:3*nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), .98,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
end
for indFrames = 3*nFrames/5+1:4*nFrames/5
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), 1.02,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
end
for indFrames = 4*nFrames/5+1:nFrames
    imageResize(:,:,indFrames) = imresize(imageResize(:,:,indFrames-1), .98,...
        'bicubic', 'Outputsize', [size(imageOriginal,1), size(imageOriginal,2)]);
end
imageResize = uint8(imageResize);
implay(imageResize)
imageResizedcm = permute(imageResize, [1 2 4 3]);
