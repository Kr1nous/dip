function BW = my_segment(I)
% Crack mask from one grayscale image. Three required stages:
%   1. dark-line enhancement by multi-orientation bottom-hat
%   2. threshold on the enhanced response
%   3. connected-component cleanup
% BW is logical, true = crack. GT is not an input.

lineLength = 35;
percentile = 95;
minArea = 160;
angles = [0, 45, 90, 135];

resp = zeros(size(I));
for k = 1:numel(angles)
    se = strel('line', lineLength, angles(k));
    bh = imbothat(I, se);
    resp = max(resp, double(bh));
end

thr = max(percentile_linear(resp, percentile), 1);
BW = resp >= thr;
BW = bwareaopen(BW, minArea);
end

function t = percentile_linear(A, pct)
% Same linear percentile as a sorted-sample interpolation. No toolbox.
v = sort(A(:));
n = numel(v);
if n == 1
    t = v;
    return;
end
pos = (n - 1) * (pct / 100); % 0-based
lo = floor(pos);
hi = ceil(pos);
if lo == hi
    t = v(lo + 1);
else
    frac = pos - lo;
    t = v(lo + 1) * (1 - frac) + v(hi + 1) * frac;
end
end
