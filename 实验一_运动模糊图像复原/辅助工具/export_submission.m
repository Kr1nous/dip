function export_submission(resultDir, csvPath)
% Encode 20 result PNGs into a CSV; image processing is done by student code.
ids = arrayfun(@(i) sprintf('image%02d', i), 1:20, 'UniformOutput', false);
rows = cell(20, 1);
for i = 1:20
    path = fullfile(resultDir, [ids{i} '.png']);
    source = fopen(path, 'rb');
    if source < 0, error('Cannot read PNG: %s', path); end
    bytes = fread(source, Inf, '*uint8');
    fclose(source);
    signature = uint8([137; 80; 78; 71; 13; 10; 26; 10]);
    if numel(bytes) < 33 || ~isequal(bytes(1:8), signature) || ...
            ~isequal(bytes(13:16), uint8('IHDR')') || bytes(25) ~= 8 || bytes(26) ~= 0
        error('Expected an 8-bit grayscale PNG: %s', path);
    end
    img = imread(path);
    if ~isa(img, 'uint8') || ~isequal(size(img), [512, 512])
        error('Expected a 512-by-512 uint8 grayscale image: %s', path);
    end
    rows{i} = encode_bytes(bytes);
end
fid = fopen(csvPath, 'w');
if fid < 0, error('Cannot create submission CSV.'); end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'id,png_base64\n');
for i = 1:20, fprintf(fid, '%s,%s\n', ids{i}, rows{i}); end
fprintf('Submission CSV saved: %s\n', csvPath);
end

function text = encode_bytes(bytes)
% Pure MATLAB Base64, also usable in Octave for compatibility verification.
alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
b = uint32(bytes(:));
pad = mod(-numel(b), 3);
b = [b; zeros(pad, 1, 'uint32')];
v = reshape(b, 3, []);
k = zeros(4, size(v, 2), 'uint32');
k(1,:) = bitshift(v(1,:), -2);
k(2,:) = bitshift(bitand(v(1,:), 3), 4) + bitshift(v(2,:), -4);
k(3,:) = bitshift(bitand(v(2,:), 15), 2) + bitshift(v(3,:), -6);
k(4,:) = bitand(v(3,:), 63);
text = reshape(alphabet(double(k(:)) + 1), 1, []);
if pad > 0, text(end-pad+1:end) = '='; end
end
