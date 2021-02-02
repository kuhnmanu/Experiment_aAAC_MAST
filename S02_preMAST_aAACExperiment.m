function S02_preMAST_aAACExperiment(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    aAAC_runExperiment_MAST(num2str(subject),1);
else
    aAAC_runExperiment_MAST;
end
end