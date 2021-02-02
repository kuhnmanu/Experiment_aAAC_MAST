function S00_aAACPracticeTrial_mockscanner(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    aAAC_runExperiment_MAST(num2str(subject),0)
else
    aAAC_runExperiment_MAST
end
end