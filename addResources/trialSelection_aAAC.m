function [p] = trialSelection_aAAC(p)

%%% Read in to shorten
if (isfield(p.TrialRecord,'BoundaryBlurVariBound'))
    BoundaryBlurVariBound = p.TrialRecord.BoundaryBlurVariBound;
end
if (isfield(p.TrialRecord,'BoundaryBlurCloseBound'))
    BoundaryBlurCloseBound = p.TrialRecord.BoundaryBlurCloseBound;
end
if (isfield(p.TrialRecord,'AversionLow'))
    AversionLow = p.TrialRecord.AversionLow;
end
if (isfield(p.TrialRecord,'AversionHigh'))
    AversionHigh = p.TrialRecord.AversionHigh;
end
if (isfield(p.TrialRecord,'RewardLow'))
    RewardLow = p.TrialRecord.RewardLow;
end
if (isfield(p.TrialRecord,'RewardHigh'))
    RewardHigh = p.TrialRecord.RewardHigh;
end
if (isfield(p.TrialRecord,'NumInitialGridTrials'))
    NumInitialGridTrials = p.TrialRecord.NumInitialGridTrials;
end
if (isfield(p.TrialRecord,'RewOfferRound'))
    RewOfferRound = p.TrialRecord.RewOfferRound;
end
if (isfield(p.TrialRecord,'AverOfferRound'))
    AverOfferRound = p.TrialRecord.AverOfferRound;
end
if (isfield(p.TrialRecord,'CondProb'))
    CondProb = p.TrialRecord.CondProb;
end
if (isfield(p.TrialRecord,'CondPseudorandBlocksize'))
    CondPseudorandBlocksize = p.TrialRecord.CondPseudorandBlocksize;
end
if (isfield(p.TrialRecord,'RewardGridSteps'))
    RewardGridSteps = p.TrialRecord.RewardGridSteps;
end
if (isfield(p.TrialRecord,'AversionGridSteps'))
    AversionGridSteps = p.TrialRecord.AversionGridSteps;
end
% [ZY-edit] Addition
if (isfield(p.TrialRecord,'minorGridSize'))
    minorGridSize = p.TrialRecord.minorGridSize;
else
    minorGridSize = 1;
end
AversionRange = [AversionLow AversionHigh];   % range of possible aversion risk
RewardRange = [RewardLow RewardHigh];    % range of possible rewards
CLOSEBOUND_TR = 1; VARIBOUND_TR = 2; RAND_TR = 3; % Numeric values for conditions

%%% Initialize TrialRecord field for recording
if (p.TrialRecord.Initialized == 0)
    p.TrialRecord.sampleGrid = ones(RewardGridSteps,AversionGridSteps);
    p.TrialRecord.condSelectVector = [];
    p.TrialRecord.RewOffer = [];
    p.TrialRecord.AverOffer = [];
    p.TrialRecord.trialType = [];
    p.TrialRecord.trialCond = [];
    p.TrialRecord.take = [];
    p.TrialRecord.Initialized = 1;
end

% [ZY-edit] 
% posAverValues =AversionRange(1):AversionRange(2);    % possible values
% posRewValues = RewardRange(1):RewardRange(2);
posAverValues   =   AversionRange(1):minorGridSize: AversionRange(2);    % possible values
posRewValues    =   RewardRange(1)  :minorGridSize: RewardRange(2);

% ----------------------------------------------------------
% DO THE TRIAL SELECTION
% ----------------------------------------------------------
% Rrefill condSelectVector if necessary
if (p.TrialRecord.CurrentTrialNumber > p.TrialRecord.NumInitialGridTrials && isempty(p.TrialRecord.condSelectVector))
    p.TrialRecord.condSelectVector = fillCondSelectVector(CondProb,CondPseudorandBlocksize);
end
% choose a trial condition randomly within the condSelectVector
if (p.TrialRecord.CurrentTrialNumber > p.TrialRecord.NumInitialGridTrials)
    i = randi([1 length(p.TrialRecord.condSelectVector)],1);
    trialCond = p.TrialRecord.condSelectVector(i);
    p.TrialRecord.condSelectVector(i) = [];   % eliminate the one we chose
end
if (p.TrialRecord.CurrentTrialNumber <= NumInitialGridTrials)
    trialCond = 0;
end
% selecting trials from randomly selected condition or selectRandomTrial
% for initialGridTrials
if ((p.TrialRecord.CurrentTrialNumber <= NumInitialGridTrials) || trialCond==RAND_TR)
    selectRandomTrial;  % using nested function, sets rewOut and averOut
    trialTypeOut = 'R';
elseif (trialCond==VARIBOUND_TR) % decision boundary trial selection, chosen only for non-stim boundary (condition==1)
    [rewOut, averOut] = selectBoundaryTrial(1,BoundaryBlurVariBound);
    trialTypeOut = 'V';
elseif (trialCond==CLOSEBOUND_TR)
    [rewOut, averOut] = selectBoundaryTrial(1,BoundaryBlurCloseBound);
    trialTypeOut = 'C';
end
% Record outcomes for this trial and append
p.TrialRecord.trialType = [p.TrialRecord.trialType, trialTypeOut];
p.TrialRecord.trialCond = [p.TrialRecord.trialCond trialCond];
p.TrialRecord.RewOffer = [p.TrialRecord.RewOffer rewOut];
p.TrialRecord.AverOffer = [p.TrialRecord.AverOffer averOut];

% ----------------------------------------------------------
% selectBoundaryTrial: NESTED FUNCTION TO CHOOSE BOUNDARY TRIAL
% ----------------------------------------------------------
    function [rOut, aOut] = selectBoundaryTrial(numTrials,boundaryBlur)
        
        dbCorrection = 'fixed'; % or 'random' for "original" behavior / This avoids selecting only random trials if participant approaches almost all trials
        
        boundary = p.TrialRecord.boundary(1,:,end);   % TODO CHECK IF BOUNDARY RECORD FORMAT IS SAME HERE
        
        % [ZY-edit] 
        %px = repmat(RewardRange(1):RewardRange(2),diff(AversionRange)+1,1);
        %py = repmat([AversionRange(1):AversionRange(2)]',1,diff(RewardRange)+1);
        pxx = posRewValues;   %RewardRange(1)    :minorGridSize    :RewardRange(2);
        pyy = posAverValues;  %AversionRange(1)  :minorGridSize  :AversionRange(2);
        [px,py] = meshgrid(pxx,pyy);
        
        for bI = 1:size(boundary,1)
            bo = 1/boundary(bI,1) * px + py;   % slope of line orthogonal to boundary at each point
            if isinf(bo)    % special case where the boundary slope is zero (and orthogonal line has infinite slope)
                yint = boundary(bI,2);
                d(:,:,bI) = abs(py-yint);
            else % all other cases
                xi = (bo - boundary(bI,2)) / (boundary(bI,1) + 1/boundary(bI,1));    % x-intersection
                yi = boundary(bI,1) * xi + boundary(bI,2);    % y-intersection
                d(:,:,bI) = sqrt((px-xi).^2 + (py-yi).^2);  % distance to boundary at each point
            end
        end
        d = min(d,[],3);    % weighting according to the shortest distance to either boundary
        
        switch dbCorrection
            case 'random'
                if min(d) > 1     % if boundary is entirely outside of the space, just choose randomly
                    disp('--- boundary outside of space, select random trial ---');
                    selectRandomTrial;  % using the nested function
                    rOut = rewOut;
                    aOut = averOut;
                else % choose using the boundary
                    % [ZY-edit] >>>
                    %xweight = -1000:1000;
                    %weight = normpdf(xweight,0,boundaryBlur); % gaussian weighting from boundary
                    %A = weight(round(d) + round(length(xweight)/2));    % matrix A (of possible rew/aver combos) with weights
                    weight=normpdf(reshape(d,1,[]),0,boundaryBlur);
                    A = reshape(weight,size(d,1),[]);
                    % [ZY-edit] <<<
                    cum = cumsum(reshape(A,1,[]));  %add up all the weights
                    
                    for trI = 1:length(numTrials)
                        randval = cum(end) * rand(1);   % pick a random value from cummulative weights
                        ind = find(cum > randval,1,'first');
                        [averOutInd, rewOutInd] = ind2sub(size(A),ind); % pull out the index
                        
                        rOut(trI) = round(posRewValues(rewOutInd)/RewOfferRound) * RewOfferRound;  % actual value, rounded
                        aOut(trI) = round(posAverValues(averOutInd)/AverOfferRound) * AverOfferRound;
                    end
                end
            case 'fixed'
                if min(d) > 1     % if boundary is entirely outside of the space, just choose randomly
                    disp('\n --- boundary outside of space, set boundary to x =1, I = 90 ---');
                    boundary(1) = 1;
                    boundary(2) = 90;
                    %p.TrialRecord.boundary(1,:,end) = boundary;
                    for bI = 1:size(boundary,1)
                        bo = 1/boundary(bI,1) * px + py;   % slope of line orthogonal to boundary at each point
                        if isinf(bo)    % special case where the boundary slope is zero (and orthogonal line has infinite slope)
                            yint = boundary(bI,2);
                            d(:,:,bI) = abs(py-yint);
                        else % all other cases
                            xi = (bo - boundary(bI,2)) / (boundary(bI,1) + 1/boundary(bI,1));    % x-intersection
                            yi = boundary(bI,1) * xi + boundary(bI,2);    % y-intersection
                            d(:,:,bI) = sqrt((px-xi).^2 + (py-yi).^2);  % distance to boundary at each point
                        end
                    end
                end
                d = min(d,[],3);    % weighting according to the shortest distance to either boundarys 
                % [ZY-edit] >>>
                %xweight = -1000:1000;
                %weight = normpdf(xweight,0,boundaryBlur); % gaussian weighting from boundary
                %A = weight(round(d) + round(length(xweight)/2));    % matrix A (of possible rew/aver combos) with weights
                % [ZY-edit] <<<
                weight=normpdf(reshape(d,1,[]),0,boundaryBlur);
                A = reshape(weight,size(d,1),[]);
                cum = cumsum(reshape(A,1,[]));  %add up all the weights
                
                for trI = 1:length(numTrials)
                    randval = cum(end) * rand(1);   % pick a random value from cummulative weights
                    ind = find(cum > randval,1,'first');
                    [averOutInd, rewOutInd] = ind2sub(size(A),ind); % pull out the index
                    
                    rOut(trI) = round(posRewValues(rewOutInd)/RewOfferRound) * RewOfferRound;  % actual value, rounded
                    aOut(trI) = round(posAverValues(averOutInd)/AverOfferRound) * AverOfferRound;
                    
                end       
        end
    end


% ----------------------------------------------------------
% selectRandomTrial: NESTED FUNCTION TO CHOOSE RANDOM TRIAL FROM GRID
% ----------------------------------------------------------

    function selectRandomTrial
        optionsRemaining = find(p.TrialRecord.sampleGrid(:,:));
        ind = ceil(length(optionsRemaining) * rand(1));
        [rInd, aInd] = ind2sub(size(p.TrialRecord.sampleGrid),optionsRemaining(ind));
        
        rewStep = diff(RewardRange)/RewardGridSteps;
        averStep = diff(AversionRange)/AversionGridSteps;
        
        rewRand = rand(1) * rewStep;
        averRand = rand(1) * averStep;
        
        rewOut =  (rInd-1) * rewStep + rewRand + RewardRange(1);
        averOut = (aInd-1) * averStep + averRand + AversionRange(1);
        
        p.TrialRecord.sampleGrid(rInd,aInd) = 0;
        rewOut = round(rewOut/RewOfferRound) * RewOfferRound;  % actual value, rounded
        averOut = round(averOut/AverOfferRound) * AverOfferRound;
        
        if (isempty(find(p.TrialRecord.sampleGrid))) % then refill p.TrialRecord.sampleGrid
            p.TrialRecord.sampleGrid(:,:) = ones(RewardGridSteps,AversionGridSteps);
        end
    end



% ----------------------------------------------------------
% fillCondSelectVector: function to initialize / refill condition selection vector
% ----------------------------------------------------------
    function condSelectVector = fillCondSelectVector(CondProb,CondPseudorandBlocksize)
        numcon = length(CondProb);
        conds = ceil(CondPseudorandBlocksize*CondProb);
        condSelectVector = [];
        for i = 1:numcon
            condSelectVector = [condSelectVector repmat(i,1,conds(i))];
        end
    end

end
