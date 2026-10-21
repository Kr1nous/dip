% Crack segmentation. One run reads, segments, saves, and scores all 20 images.

rootDir = fileparts(mfilename('fullpath'));
if isempty(rootDir)
    rootDir = pwd;
end
cd(rootDir);

imgDir = fullfile(rootDir, 'data', 'image');
gtDir = fullfile(rootDir, 'data', 'GT');
resultDir = fullfile(rootDir, 'result');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

n = 20;
fprintf('%-12s %10s %10s\n', 'image', 'F1', 'IoU');
f1s = zeros(n, 1);
ious = zeros(n, 1);
for i = 1:n
    name = sprintf('image%02d.png', i);
    I = imread(fullfile(imgDir, name));
    G = imread(fullfile(gtDir, name));
    check_gray384(I, fullfile(imgDir, name));
    check_gray384(G, fullfile(gtDir, name));

    BW = my_segment(I);
    M = uint8(BW) * 255;
    outPath = fullfile(resultDir, name);
    imwrite(M, outPath);

    saved = imread(outPath);
    check_mask(saved, outPath);
    pred = saved > 0;
    gt = G > 0;
    f1s(i) = dice(pred, gt);
    ious(i) = jaccard(pred, gt);
    fprintf('%-12s %10.4f %10.4f\n', name, f1s(i), ious(i));
end

fprintf('Mean F1 %.4f, mean IoU %.4f\n', mean(f1s), mean(ious));
if mean(f1s) >= 0.40 && mean(ious) >= 0.25
    fprintf('Thresholds: PASS\n');
else
    fprintf('Thresholds: FAIL\n');
end

make_submission;

function check_gray384(img, path)
if ~isa(img, 'uint8') || ~isequal(size(img), [384, 384])
    error('Expected 384x384 uint8 grayscale: %s', path);
end
end

function check_mask(img, path)
if ~isa(img, 'uint8') || ~isequal(size(img), [384, 384])
    error('Expected 384x384 uint8 mask: %s', path);
end
if any(img(:) ~= 0 & img(:) ~= 255)
    error('Mask pixels must be 0 or 255: %s', path);
end
end
