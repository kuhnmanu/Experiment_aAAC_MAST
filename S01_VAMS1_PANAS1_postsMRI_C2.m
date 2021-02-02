function S01_VAMS1_PANAS1_postsMRI_C2(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    runVAMS(subject,1);
    runPANAS(subject,1);
else
    runVAMS;
    runPANAS;
end
end