function folders = getfolders(path)

folders = dir(path);

for k = length(folders):-1:1
    % Remove non-folders
    if ~folders(k).isdir
        folders(k) = [ ];
        continue
    end

    % Remove folders starting with .
    fname = folders(k).name;
    if fname(1) == '.'
        folders(k) = [ ];
    end
end