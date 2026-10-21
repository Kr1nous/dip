function J = my_dehaze(I)
% Grayscale dark-channel dehazing. J = my_dehaze(I)
% Stages: local-minimum dark channel, atmospheric light, transmission,
% then the scattering-model recovery. GT is not an input.

win = 61;
omega = 0.95;
t0 = 0.1;
topRatio = 0.001;

X = im2double(I);
% Square local minimum. imerode ignores out-of-image samples, so the
% border is not forced toward zero.
dark = imerode(X, strel('square', win));

k = max(1, round(numel(dark) * topRatio));
values = dark(:);
[~, order] = sort(values, 'descend');
idx = order(1:k);
A = max(X(idx));
if A < 1e-3
    A = 1e-3;
end

t = 1 - omega * (dark ./ A);
t = min(max(t, t0), 1);
R = (X - A) ./ t + A;
R = min(max(R, 0), 1);
J = im2uint8(R);
end
