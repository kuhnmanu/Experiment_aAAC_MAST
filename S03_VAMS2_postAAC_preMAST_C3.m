function S03_VAMS2_postAAC_preMAST_C3(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    runVAMS(subject,2);
else
    runVAMS;
end
end