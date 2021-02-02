function S07_VAMS4_postAAC_C5(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    runVAMS(subject,4);
else
    runVAMS;
end
end