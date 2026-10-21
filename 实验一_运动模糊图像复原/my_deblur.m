function J = my_deblur(I, PSF, K)
% Wiener restoration with a known PSF. J = my_deblur(I, PSF, K)
% I is a uint8 grayscale blur image, PSF is the normalized kernel,
% K is a positive constant. The filter is built here; no toolbox
% deconvolution routine is used.

if K <= 0
    error('K must be positive.');
end

X = im2double(I);
H = psf2otf(PSF, size(X));
W = conj(H) ./ (abs(H) .^ 2 + K);
R = real(ifft2(fft2(X) .* W));
R = min(max(R, 0), 1);
J = im2uint8(R);
end
