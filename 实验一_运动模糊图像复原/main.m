% Motion-blur restoration. One run reads all 20 images, compares K,
% restores with one shared K, saves PNGs, and prints per-image scores.

rootDir = fileparts(mfilename('fullpath'));
if isempty(rootDir)
    rootDir = pwd;
end
cd(rootDir);

blurDir = fullfile(rootDir, 'data', 'blur');
gtDir = fullfile(rootDir, 'data', 'GT');
resultDir = fullfile(rootDir, 'result');
if ~exist(resultDir, 'dir')
    mkdir(resultDir);
end

S = load(fullfile(rootDir, 'data', 'PSF', 'psf.mat'));
PSF = S.PSF;

n = 20;
blurIm = cell(n, 1);
gtIm = cell(n, 1);
for i = 1:n
    name = sprintf('image%02d.png', i);
    B = imread(fullfile(blurDir, name));
    G = imread(fullfile(gtDir, name));
    check_gray512(B, fullfile(blurDir, name));
    check_gray512(G, fullfile(gtDir, name));
    blurIm{i} = B;
    gtIm{i} = G;
end

% Required comparison points, plus a finer grid around the noise level.
kList = [0.0001, 0.0003, 0.001, 0.003, 0.01, 0.03];
kPsnr = zeros(size(kList));
kSsim = zeros(size(kList));
fprintf('K search on the course metric (crop 2 px):\n');
fprintf('%-10s %10s %10s\n', 'K', 'PSNR', 'SSIM');
for t = 1:numel(kList)
    psnrK = zeros(n, 1);
    ssimK = zeros(n, 1);
    for i = 1:n
        R = my_deblur(blurIm{i}, PSF, kList(t));
        [psnrK(i), ssimK(i)] = course_pair(R, gtIm{i});
    end
    kPsnr(t) = mean(psnrK);
    kSsim(t) = mean(ssimK);
    fprintf('%-10.4g %10.3f %10.4f\n', kList(t), kPsnr(t), kSsim(t));
end

pass = kPsnr >= 28 & kSsim >= 0.78;
if any(pass)
    % Among passing K, prefer higher SSIM, then higher PSNR.
    score = kSsim + 1e-4 * kPsnr;
    score(~pass) = -inf;
    [~, best] = max(score);
else
    score = kPsnr / 28 + kSsim / 0.78;
    [~, best] = max(score);
end
K = kList(best);
fprintf('Selected K = %.4g (mean PSNR %.3f dB, mean SSIM %.4f)\n', ...
    K, kPsnr(best), kSsim(best));

fprintf('\nPer-image scores after saving and re-reading:\n');
fprintf('%-8s %10s %10s %10s %10s\n', 'image', 'blurPSNR', 'blurSSIM', 'outPSNR', 'outSSIM');
blurP = zeros(n, 1);
blurS = zeros(n, 1);
outP = zeros(n, 1);
outS = zeros(n, 1);
for i = 1:n
    name = sprintf('image%02d.png', i);
    J = my_deblur(blurIm{i}, PSF, K);
    outPath = fullfile(resultDir, name);
    imwrite(J, outPath);
    saved = imread(outPath);
    check_gray512(saved, outPath);
    [blurP(i), blurS(i)] = course_pair(blurIm{i}, gtIm{i});
    [outP(i), outS(i)] = course_pair(saved, gtIm{i});
    fprintf('%-8s %10.3f %10.4f %10.3f %10.4f\n', name, blurP(i), blurS(i), outP(i), outS(i));
end

fprintf('Blur   mean PSNR %.3f dB, mean SSIM %.4f\n', mean(blurP), mean(blurS));
fprintf('Result mean PSNR %.3f dB, mean SSIM %.4f\n', mean(outP), mean(outS));
if mean(outP) >= 28 && mean(outS) >= 0.78
    fprintf('Course thresholds: PASS\n');
else
    fprintf('Course thresholds: FAIL\n');
end

addpath(fullfile(rootDir, '辅助工具'));
export_submission(resultDir, fullfile(rootDir, 'submission.csv'));

function check_gray512(img, path)
if ~isa(img, 'uint8') || ~isequal(size(img), [512, 512])
    error('Expected 512x512 uint8 grayscale: %s', path);
end
end

function [p, s] = course_pair(A, B)
% Crop 2 px, PSNR peak 255, SSIM with an 11x11 Gaussian (sigma 1.5).
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
% Population-weighted SSIM on valid 11x11 windows. Negative map values stay.
window = fspecial('gaussian', 11, 1.5);
window = window / sum(window(:));
L = 255;
C1 = (0.01 * L) ^ 2;
C2 = (0.03 * L) ^ 2;
muA = filter2(window, A, 'valid');
muB = filter2(window, B, 'valid');
sigA = filter2(window, A .* A, 'valid') - muA .^ 2;
sigB = filter2(window, B .* B, 'valid') - muB .^ 2;
sigAB = filter2(window, A .* B, 'valid') - muA .* muB;
sigA = max(sigA, 0);
sigB = max(sigB, 0);
num = (2 * muA .* muB + C1) .* (2 * sigAB + C2);
den = (muA .^ 2 + muB .^ 2 + C1) .* (sigA + sigB + C2);
s = mean(num(:) ./ den(:));
end
