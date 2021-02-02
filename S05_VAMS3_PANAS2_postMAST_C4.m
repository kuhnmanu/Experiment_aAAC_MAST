function S05_VAMS3_PANAS2_postMAST_C4(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    runVAMS(subject,3);
    runPANAS(subject,2);
else
    runVAMS;
    runPANAS;
end
end