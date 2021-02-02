function S08_VAMS5_postPRT_C6(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    runVAMS(subject,5);
else
    runVAMS;
end
end