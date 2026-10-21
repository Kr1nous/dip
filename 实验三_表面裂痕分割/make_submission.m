function make_submission
rootDir = fileparts(mfilename('fullpath'));
out = fopen(fullfile(rootDir, 'submission.csv'), 'w');
assert(out > 0);
cleaner = onCleanup(@() fclose(out));
fprintf(out, 'id,png_base64\n');
for k = 1:20
    id = sprintf('image%02d', k);
    pngFile = fullfile(rootDir, 'result', [id '.png']);
    in = fopen(pngFile, 'rb');
    assert(in > 0);
    bytes = fread(in, Inf, '*uint8');
    fclose(in);
    assert(numel(bytes) > 26 && ...
        isequal(bytes(1:8).', uint8([137 80 78 71 13 10 26 10])) && ...
        bytes(25) == 8 && bytes(26) == 0);
    [M, map] = imread(pngFile);
    if islogical(M), M = uint8(255 * M); end
    assert(isa(M, 'uint8') && isequal(size(M), [384 384]) && isempty(map));
    assert(all(M(:) == 0 | M(:) == 255));
    encoded = char(matlab.net.base64encode(bytes));
    fprintf(out, '%s,%s\n', id, encoded);
end
end
