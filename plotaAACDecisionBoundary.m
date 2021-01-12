function [varargout] = plotaAACDecisionBoundary(averOffer,rewOffer,take,condition,axH,params)
% [boundary, stats] = plotARCDecisionBoundary(aver,rew,take,conditions,axH,params)
% 
% averOffer: vector of aversion levels
% rewOffer: vector of reward offers
% take: vector of take decisions
% conditions: divides trials into conditions and calculates the decision
%              boundary for each separately. if empty, assumed to be one
%              condition
% axH: axis on which to plot, if empty then function will create a figure
% params: optionally provide other parameteres
% returns boundary: [a1 a2] where aversion = a1*reward + a2
% returns stats: structure with:
%         stats.se(numconditions,2): 95% confidence interval for boundary coefficients
%         stats.distance(numConditions,numTrials) = for each trial the distance from the decision boundary (in reward/aversion units)

% deal with parameters, defaults, etc.
if (nargin < 6 || isempty(params))
    params.blank = [];
end

if (~ismember(lower('gridSize'),lower(fieldnames(params)))), params.gridSize = 100; end % grid for pseudocolor plots
if (~ismember(lower('rewardRange'),lower(fieldnames(params)))), params.rewardRange= [1 100]; end    % range of rewards
if (~ismember(lower('averRange'),lower(fieldnames(params)))), params.averRange= [1 100]; end    % range of aversive risk

if (~ismember(lower('calculateDecisionBoundary'),lower(fieldnames(params)))), params.calculateDecisionBoundary = 1; end % perform the decision boundary calcuation or just use what was provided in params.boundary
if (~ismember(lower('boundaryMethod'),lower(fieldnames(params)))), params.boundaryMethod = 'logistic'; end  % only option implemented is logistic
if (~ismember(lower('boundary'),lower(fieldnames(params)))), params.boundary = []; end    % can provide a previously calculated boundary 
if (~ismember(lower('plotTakePassColor'),lower(fieldnames(params)))), params.plotTakePassColor = 1; end % plot with pseudocolor shading representing take vs. pass probability
if (~ismember(lower('imageSmooth'),lower(fieldnames(params)))), params.imageSmooth = 10; end    % smoothing factor for plots
if (~ismember(lower('imageInterpolation'),lower(fieldnames(params)))), params.imageInterpolation= 'greedy'; end % interpolation for pseudocolor plots: 'local' or 'greedy' or 'gridded'  

if (~ismember(lower('plotIndividualOffers'),lower(fieldnames(params)))), params.plotIndividualOffers = 1; end   % plot individual offers or only pseudocolor +/- boundary

if (~ismember(lower('markerSize'),lower(fieldnames(params)))), params.markerSize= 6; end    % individual offer marker size
if (~ismember(lower('markerEdgeWidth'),lower(fieldnames(params)))), params.markerEdgeWidth= 2; end  % individual offer edge width
if (~ismember(lower('boundaryLineWidth'),lower(fieldnames(params)))), params.boundaryLineWidth= 4; end  % boundary line plot width
if (~ismember(lower('conditionColor'),lower(fieldnames(params)))), params.conditionColor= [.5 .5 .5]; end   % color for different stimulation conditions, each row is a color
if (~ismember(lower('axisParams'),lower(fieldnames(params)))), params.axisParams= []; end   % can pass a set of axis parameters for the plots
if (~ismember(lower('boundaryLevels`'),lower(fieldnames(params)))), params.boundaryLevels= []; end  % can plot a reference boundary
if (~ismember(lower('colorMap'),lower(fieldnames(params)))), params.colorMap= []; end   % color map for pseudocolor plots

if (~ismember(lower('suppressPlot'),lower(fieldnames(params)))), params.suppressPlot= 0; end    % don't plot anything


% Clean up passed parameters
switch params.boundaryMethod
    case {'logistic','svm'}
    otherwise
        params.boundaryMethod = 'logistic';
end

switch params.imageInterpolation
    case {'local','greedy','gridded'}
    otherwise
        params.boundaryMethod = 'greedy';
end

if (~params.suppressPlot && (nargin < 5 || isempty(axH) || ~ishandle(axH))) % make figure
    f_ = figure;
    axH = gca;
elseif ~params.suppressPlot
%     axes(axH);
    hold(axH,'on'); 
end

if (nargin < 4 || isempty(condition))
    condition = ones(size(take));   % assumed to be one condition
end

if (nargin < 3)
    disp('ERROR: plotARCDecisionBoundary requires at least three arguments');
    return
end

% boundary line figure settings
pd = [.5 params.boundaryLevels];
ls = [{'-'} repmat({'--'},1,length(params.boundaryLevels))];

% make sure there is a conditionColor specificed for each condition
% specified
condID = unique(condition);
numcon = length(condID);
numcolors = size(params.conditionColor,1);
if (numcolors < numcon)
    params.conditionColor = repmat(params.conditionColor,ceil(numcon/numcolors),1);
end
    
% ------------------------------------------------
% Process data and plot behavior
% ------------------------------------------------    
if ((params.plotTakePassColor)  && (~params.suppressPlot)) % prepare the colorized plots
    switch params.imageInterpolation    
    case {'greedy','local'}
        Atake = zeros(params.gridSize,params.gridSize);
        Atotal = zeros(params.gridSize,params.gridSize);
        for trI = 1:length(averOffer)
            if (isnan(take(trI)))
                % skip
            elseif (take(trI) == 1)
                Atake(averOffer(trI),rewOffer(trI)) = Atake(averOffer(trI),rewOffer(trI)) + 1;
                Atotal(averOffer(trI),rewOffer(trI)) = Atotal(averOffer(trI),rewOffer(trI)) + 1;
            elseif (take(trI) == 0)
                Atake(averOffer(trI),rewOffer(trI)) = Atake(averOffer(trI),rewOffer(trI)) - 1;
                Atotal(averOffer(trI),rewOffer(trI)) = Atotal(averOffer(trI),rewOffer(trI)) + 1;
            else
                disp(fprintf('ERROR: take was undefined, take = %d',take(trI)));
            end
        end
        A = Atake./Atotal;
        A(isinf(A) | isnan(A)) = 0;

        % pseudocolor decision
        G = fspecial('gaussian',params.imageSmooth*25,params.imageSmooth); 

        switch params.imageInterpolation
            case 'greedy'
                AF = imfilter(Atake,G,'conv')./imfilter(Atotal,G,'conv');
            case 'local' 
                AF = imfilter(A,G,'conv');
        end
    case 'gridded'
        [c,~,rewInd] = unique(rewOffer);
        xgrid = length(c);
        [c,~,averInd] = unique(averOffer);
        ygrid = length(c);

        Atake = zeros(params.gridSize,params.gridSize);
        Atotal = zeros(params.gridSize,params.gridSize);

        averIndN = averInd/max(averInd);
        rewIndN = rewInd/max(rewInd);
        for trI = 1:length(averOffer)
            averIndRng = ceil((averIndN(trI)-1/xgrid)*params.gridSize) + 1 : ceil(averIndN(trI)*params.gridSize);
            rewIndRng = ceil((rewIndN(trI)-1/ygrid)*params.gridSize) + 1 : ceil(rewIndN(trI)*params.gridSize);
            if (isnan(take(trI)))
                % skip
            elseif (take(trI) == 1)
                Atake(averIndRng,rewIndRng) = Atake(averIndRng,rewIndRng) + 1;
                Atotal(averIndRng,rewIndRng) = Atotal(averIndRng,rewIndRng) + 1;
            elseif (take(trI) == 0)
                Atake(averIndRng,rewIndRng) = Atake(averIndRng,rewIndRng) - 1;
                Atotal(averIndRng,rewIndRng) = Atotal(averIndRng,rewIndRng) + 1;
            else
                disp(fprintf('ERROR: take was undefined, take = %d',take(trI)));
            end
        end
        A = Atake./Atotal;
        A(isinf(A) | isnan(A)) = 0;
        if ~isnan(params.imageSmooth)
            G = fspecial('gaussian',params.imageSmooth*25,params.imageSmooth); 
            AF = imfilter(A,G,'conv');
        end;
    end
end

if (~params.suppressPlot)   % skip if not plotting
    if (params.plotTakePassColor)   % colorized plots
        if (~isempty(params.colorMap))
            colormap(axH,params.colorMap);
        end
        
        switch params.imageInterpolation    
        case {'greedy','local'}
            pcolor(axH,AF); 
            shading(axH,'flat');
            caxis(axH,[-1 1])
            axis(axH,[1 100 1 100]);
            %axis(axH,[8 110 8 110]);
            hold on 
        case 'gridded'
            imagesc(axH,A);
            shading(axH,'flat');
            caxis(axH,[-1 1])
            axis(axH,[1 100 1 100]);
            hold on             
        end
    end

    if (params.plotIndividualOffers)
        for cI = 1:numcon
            tI = (take == 1 & condition==condID(cI));
            pI = (take == 0 & condition==condID(cI));
            
%             plot(axH,rewOffer(tI),averOffer(tI),'o','markerfacecolor',params.conditionColor(cI,:),'markeredgecolor',params.conditionColor(cI,:),...
%                 'markersize',params.markerSize,'linewidth',params.markerEdgeWidth);
%             hold on
%             plot(axH,rewOffer(pI),averOffer(pI),'o','markerfacecolor','none','markeredgecolor',params.conditionColor(cI,:),...
%                 'markersize',params.markerSize,'linewidth',params.markerEdgeWidth);  
            
            %%% Adapted to add a little jitter
            %plot(axH,rewOffer(tI)+rand(1,length(rewOffer(tI)),1)*2,averOffer(tI)-rand(1,length(averOffer(tI)),1)*2,'o','markerfacecolor',params.conditionColor(cI,:),'markeredgecolor',params.conditionColor(cI,:),...
            %    'markersize',params.markerSize,'linewidth',params.markerEdgeWidth);
            %hold on
            %plot(axH,rewOffer(pI)+rand(1,length(rewOffer(pI)),1)*2,averOffer(pI)-rand(1,length(averOffer(pI)),1)*2,'o','markerfacecolor','none','markeredgecolor',params.conditionColor(cI,:),...
            %    'markersize',params.markerSize,'linewidth',params.markerEdgeWidth);
            plot(axH,rewOffer(tI)+rand(1,length(rewOffer(tI)),1)*2-2,averOffer(tI)-rand(1,length(averOffer(tI)),1)*2-2,'o','markerfacecolor',params.conditionColor(cI,:),'markeredgecolor',params.conditionColor(cI,:),...
                'markersize',params.markerSize,'linewidth',params.markerEdgeWidth);
            hold on
            plot(axH,rewOffer(pI)+rand(1,length(rewOffer(pI)),1)*2-2,averOffer(pI)-rand(1,length(averOffer(pI)),1)*2-2,'o','markerfacecolor','none','markeredgecolor',params.conditionColor(cI,:),...
                'markersize',params.markerSize,'linewidth',params.markerEdgeWidth);
         end
    end
end

% decision boundary calculation
if (params.calculateDecisionBoundary)
    boundary = zeros(numcon,2);
elseif (~params.calculateDecisionBoundary)
    boundary = params.boundary; % if not going to calculate the boundary, then used the one passed in
end
x = 1:100;
y = [];
switch params.boundaryMethod
    case 'logistic'
        if (params.calculateDecisionBoundary)
            stats.distance = nan(numcon,length(rewOffer));
            for condI = 1:numcon
                trInd = find(condition == condID(condI));
                [b,dev,s] = glmfit([reshape(rewOffer(trInd),[],1),reshape(averOffer(trInd),[],1)],reshape(take(trInd),[],1),'binomial','link','logit');
                for i = 1:length(pd)
                    y{condI,i} = -(b(1) + log(1/pd(i) - 1) + b(2)*x)/b(3);
                    g = groot;
                    if ~isempty(g.Children)
                        hold on;
                    end
                    if (pd(i) == .5)
                        boundary(condI,:) = [-b(2)/b(3), -b(1)/b(3)];    % aversion = boundary(1)*reward + boundary(2)
                        stats.se(condI,1) = abs(boundary(condI,1)) * sqrt((s.se(2)/b(2))^2 + (s.se(3)/b(3))^2);
                        stats.se(condI,2) = abs(boundary(condI,2)) * sqrt((s.se(1)/b(1))^2 + (s.se(3)/b(3))^2);

                        % calculate distance of each point from decision boundary
                        rx = rewOffer(trInd);
                        ay = averOffer(trInd);

                        bo = 1/boundary(condI,1) * rx + ay;   % slope of line orthogonal to boundary at each point
                        xi = (bo - boundary(condI,2)) / (boundary(condI,1) + 1/boundary(condI,1));    % x-intersection
                        yi = boundary(condI,1) * xi + boundary(condI,2);    % y-intersection
                        stats.distance(condI,trInd) = sqrt((rx-xi).^2 + (ay-yi).^2);  % distance to boundary at each point
                        % set the sign : if upper left quadrant then negative, lower right then positive, if other two quandrants 
                        % (i.e. decision boundary slope is negative) then the sign is dominated by the larger value
                        distSign = sign((rx-xi) - (ay-yi));
                        stats.distance(condI,trInd) = stats.distance(condI,trInd) .* reshape(distSign,1,[]);
                    end      
                end
            end
        end

    case 'svm'
        % not fully working yet; attempts to use MATLAB svmtrain function
        pd = [.5];
        ls = {'-'};
        
        svm_x = [reshape(rewOffer,[],1),reshape(averOffer,[],1)];
        model = svmtrain(svm_x,reshape(take,[],1),'ShowPlot',0,'boxconstraint',1); % high boxconstraint -- punish for outliers
        sv = model.SupportVectors;
 
        % see if we need to unscale the data
        scaleData = model.ScaleData;
        if ~isempty(scaleData)
            for c = 1:size(sv, 2)
                sv(:,c) = (sv(:,c)./scaleData.scaleFactor(c)) - scaleData.shift(c);
            end
        end

        lims = [0 100 0 100];   % hard setting the figure limits
        [X,Y] = meshgrid(linspace(lims(1),lims(2)),linspace(lims(3),lims(4)));
        Xorig = X; Yorig = Y;
        
        % need to scale the mesh
        if ~isempty(scaleData)
            X = scaleData.scaleFactor(1) * (X + scaleData.shift(1));
            Y = scaleData.scaleFactor(2) * (Y + scaleData.shift(2));
        end

        % decision value within meshgrid
        [dummy, Z] = svmdecision([X(:),Y(:)],model); 
    
%     % CODE TRYING TO CALCULATE DECISION BOUNDARY DIRECTLY. CAN'T FIGURE IT OUT
%     % CURRENT VERSION DOESN'T CALCULATE BOUNDARY EQUATION
%     w = sum(sv .* svm_x(model.SupportVectorIndices,:),1);
%     b = model.Bias;
%     hold on
%     plot(x,b/w(1) + -w(2) * x / w(1),'-g','linewidth',2)
end

% boundary equation for externally provided boundary
if (~params.suppressPlot && isempty(y) && ~isempty(boundary))
    pd = 0.5;
    for condI = 1:numcon
        for i = 1:length(pd)
            y{condI,i} = x*boundary(condI,1) + boundary(condI,2);
        end
    end
end

% plot decision boundary
if (~params.suppressPlot && ~isempty(y))
    switch params.boundaryMethod
        case 'logistic'
            % axes(axH); hold on
            for condI = 1:numcon
                for i = 1:length(pd)
                    plot(axH,x,y{condI,i},'-','color',params.conditionColor(condI,:),'linewidth',params.boundaryLineWidth,'linestyle',ls{i}); 
                end
            end
        case 'svm'
            % axes(axH); hold on
            contour(Xorig,Yorig,reshape(Z,size(X)),[0 0],'-','color',params.conditionColor,'linewidth',params.boundaryLineWidth);
    end
    % default axis params
    set(axH,'fontsize',18);
    axH.XLabel.String = 'Reward offer (cents)';
    axH.YLabel.String = 'Aversion offer (level)';
    axH.XTick = [10 20:10:100];
    axH.YTick = [10 20:10:100];
    if(~isempty(params.axisParams)) % set any user-specified axis params
        set(axH,params.axisParams);
    end
end
if (~params.suppressPlot && ~isempty(params.axisParams))
    set(axH,params.axisParams);
end

% OUTPUT RESULTS
if nargout == 2
    varargout{1} = boundary;
    varargout{2} = stats;
elseif nargout == 1
    varargout{1} = boundary;
end
    