% Dehazing. One run reads all 20 hazy images, saves PNGs, and scores them.

rootDir = fileparts(mfilename('fullpath'));
if isempty(rootDir)
    rootDir = pwd;
end
cd(rootDir);

hazyDir = fullfile(rootDir, 'data', 'hazy');
gtDir = fullfile(rootDir, 'data', 'GT');
resultDir = fullfile(rootDir, 'result');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

n = 20;
fprintf('%-12s %10s %10s %10s %10s\n', 'image', 'hazyPSNR', 'hazySSIM', 'outPSNR', 'outSSIM');
hP = zeros(n, 1);
hS = zeros(n, 1);
oP = zeros(n, 1);
oS = zeros(n, 1);
for i = 1:n
    name = sprintf('image%02d.png', i);
    I = imread(fullfile(hazyDir, name));
    G = imread(fullfile(gtDir, name));
    check_gray512(I, fullfile(hazyDir, name));
    check_gray512(G, fullfile(gtDir, name));

    J = my_dehaze(I);
    outPath = fullfile(resultDir, name);
    imwrite(J, outPath);
    saved = imread(outPath);
    check_gray512(saved, outPath);

    [hP(i), hS(i)] = course_pair(I, G);
    [oP(i), oS(i)] = course_pair(saved, G);
    fprintf('%-12s %10.3f %10.4f %10.3f %10.4f\n', name, hP(i), hS(i), oP(i), oS(i));
end

fprintf('Hazy   mean PSNR %.3f dB, mean SSIM %.4f\n', mean(hP), mean(hS));
fprintf('Result mean PSNR %.3f dB, mean SSIM %.4f\n', mean(oP), mean(oS));
if mean(oP) >= 12 && mean(oS) >= 0.30
    fprintf('Course thresholds: PASS\n');
else
    fprintf('Course thresholds: FAIL\n');
end

make_submission;

function check_gray512(img, path)
if ~isa(img, 'uint8') || ~isequal(size(img), [512, 512])
    error('Expected 512x512 uint8 grayscale: %s', path);
end
end

function [p, s] = course_pair(A, B)
A = double(A(3:end-2, 3:end-2));
B = double(B(3:end-2, 3:end-2));
mse = mean((A(:) - B(:)) .^ 2);
if mse == 0
    p = inf;
else
    p = 10 * log10((255 ^ 2) / mse);
end
s = course_ssim(A, B);
end

function s = course_ssim(A, B)
window = fspecial('gaussian', 11, 1.5);
window = window / sum(window(:));
L = 255;
C1 = (0.01 * L) ^ 2;
C2 = (0.03 * L) ^ 2;
muA = filter2(window, A, 'valid');
muB = filter2(window, B, 'valid');
sigA = max(filter2(window, A .* A, 'valid') - muA .^ 2, 0);
sigB = max(filter2(window, B .* B, 'valid') - muB .^ 2, 0);
sigAB = filter2(window, A .* B, 'valid') - muA .* muB;
num = (2 * muA .* muB + C1) .* (2 * sigAB + C2);
den = (muA .^ 2 + muB .^ 2 + C1) .* (sigA + sigB + C2);
s = mean(num(:) ./ den(:));
end
