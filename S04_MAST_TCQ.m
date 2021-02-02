function S04_MAST_TCQ(subject)
addpath([pwd filesep 'addResources']);
if nargin == 1
    runMAST(num2str(subject));
else
    runMAST;
end
end