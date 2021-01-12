
%% Experimental Psychtoolbox script for adaptive Ap-Av-Conflict Task (aAAC)
%  2020/07
%  Manuel Kuhn | mkuhn@mclean.harvard.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Laboratory for Affective and Translational Neuroscience (LATN)
%  Center for Depression, Anxiety and Stress Research (CDASR)
%  McLean Hospital, Belmont, MA USA | Harvard Medical School Affiliate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Task based on LATN AAC task, published:
%  https://www.biologicalpsychiatryjournal.com/article/S0006-3223(19)31661-0
%  Adaptive compontent by Todd Harrington, MD, PhD:
%  https://www.massgeneral.org/doctors/19705/todd-herrington
%  Published?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  INSTRUCTIONS: PLEASE CHANGE THE FOLLOWING PARAMETERS TO SUIT YOUR SETUP
%  - Joystick parameters
%  - Whatelse?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          _____                          %
%                          /\        /\   / ____|                         %
%                  __ _   /  \      /  \ | |                              %
%                 / _` | / /\ \    / /\ \| |                              %
%                | (_| |/ ____ \  / ____ \ |____                          %
%                 \__,_/_/    \_\/_/    \_\_____|                         %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [p] = aAAC_runExperiment_MAST(subject, runNumber,comment)              % args can be omitted and entered via GUI prompt

sca;

%%%%%%%%%%%%%%%%%%%%%%%%%%% Put in your experiment choices here
debug               = 0;                                                   % Use this function to have a transparent screen
p_mri_on            = 1;                                                   % If on, waits for pulses / never on for run 0 (calibration)
screenNumber        = 2;                                                   % Select which monitor is used for presentatio: 0,1,2
invertScreenCalib   = 1;                                                   % Inverts presentation on screen (e.g., when calibration is done in mock scanner at MIC)
invertScreenRuns    = 0;                                                   % Inverts screen for actual runs (e.g., run1 - run3)
mr_joystick         = 1;                                                   % When MR joystick is used, a different acceleration factor is set.

if ~exist('runNumber','var')
    runNumber       = 0;
end
totalRuns           = 3;

while runNumber <= totalRuns
    % Check inputs from command line or previous run
    if ~exist('subject','var')
        subject = '';
    end
    if ~exist('prePostSession','var')
        prePostSession = '';
    end
    if ~exist('maxShockStrengthInmA', 'var')
        maxShockStrengthInmA = 0;
    end
    if ~exist('minShockStrengthInmA', 'var')
        minShockStrengthInmA = 0;
    end
    if ~exist('comment', 'var')
        comment = 'no comment';
    end
    %%% Print visual feedback for experimenter to confirm
    response = inputdlg({'ADMS_aACC ID#:', 'Session pre ("pre") / post ("post") MAST', 'Shock Min in mA', 'Shock Max in mA', 'Run:', 'Include TCQ before run1:' 'Comment:'},...
        'aAAC Task - Please enter information', [1 75],...
        {subject,  prePostSession, num2str(minShockStrengthInmA), num2str(maxShockStrengthInmA), num2str(runNumber), num2str("1"),  comment});
    if isempty(response)
        error(['User pressed "Cancel" for run #: ' num2str(runNumber) '. Please restart for this run.']);
    end
    subject                 = response{1};
    prePostSession          = response{2};
    minShockStrengthInmA    = str2num(response{3});
    maxShockStrengthInmA    = str2num(response{4});
    runNumber               = str2double(response{5});
    runTCQ                  = response{6};
    comment                 = response{7};
    
    %%% Check if correct session pre-post mast is given.
    if isempty(prePostSession) || all(cellfun(@isempty,(strfind({'pre','post'}, prePostSession))))
        error('Please specify correct pre/post MAST session');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                 Initialize Experiment Environment
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %ListenChar(2);                                                             % Disable pressed keys to printed out
    commandwindow;
    clear mex global
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Load the GETSECS mex files so call them at least once
    GetSecs;
    WaitSecs(0.001);
    
    SetParameters;
    
    SetPTB;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Initialize all variables
    p_ptb_w                         = p.ptb.w;
    p_ptb_ifi                       = p.ptb.ifi;
    p_ptb_midpoint_x                = p.ptb.midpoint(1);
    p_ptb_midpoint_y                = p.ptb.midpoint(2);
    p_com_lpt_scannerPulseOnset     = p.com.lpt.scannerPulseOnset;
    p_com_lpt_ShockOnset            = p.com.lpt.ShockOnset;
    p_com_lpt_duration              = p.com.lpt.duration;
    p_presentation_sessTrialNumber  = [];
    p_stim_distFromCenterAbs        = p.stim.distFromCenterAbs;
    p_stim_dotSize                  = p.stim.dotSize;
    p_stim_white                    = p.stim.white;
    p_stim_baseOfferRect            = p.stim.baseOfferRect;
    p_stim_apprCross                = p.stim.apprCross;
    p_stim_avoidRect                = p.stim.avoidRect;
    p_stim_offerRectsColors         = p.stim.offerRectsColors;
    p_stim_indicatorColors          = p.stim.indicatorColors;
    p_stim_barsFrameColor           = p.stim.barsFrameColor;
    p_stim_barsFrameRect            = p.stim.barsFrameRect;
    p_stim_circle                   = p.stim.circle;
    p_stim_circleSize               = p.stim.circleSize;
    p_stim_penWidthPxlFrame         = p.stim.penWidthPxlFrame;
    p_stim_penWidthPxlCircle        = p.stim.penWidthPxlCircle;
    p_stim_offerHeight              = p.stim.offerHeight;
    p_keys_trigger                  = p.keys.trigger;
    p_joy_accelarationFactor        = p.joy.accelarationFactor;
    p_joy_ScreenRelation            = p.joy.ScreenRelation;
    niDaq                           = p.niDaq;
    p_d128                          = p.d128;
    
    %save again the parameter file
    save(p.path.save ,'p');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %                  Run adaptive Ap-Av-Conflict Experiment
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % init screenFlip
    Screen('Flip', p_ptb_w);
    
    if  runNumber == 0
        putLog(GetSecs, 'Instructions/Practice Start');
        ShowInstruction;
        RunPracticeTrials;
    else
        
        %%% Run TCQ questionnaire before first run of AAC
        if runNumber == 1 && runTCQ == 1
            p = q_TCQ(p);
        end
        
        % Wait for Dummy Scans
        firstScannerPulseTime = WaitForDummyScans(p.mri.dummyScan);
        p.log.mriExpStartTime = firstScannerPulseTime;
        putLog(firstScannerPulseTime, 'FirstMRPulse_ExpStart');
        
        % RUN aAAC Task
        runaAACTask;
        % Show SessionEnd
        if runNumber == totalRuns
            ShowEndSessionText;
            fprintf('\nParticipant earned: %.2f $\n', p.TrialRecord.RewardTakenInCentsAccum/100);
        end
    end
    cleanup;
    %%% Increase runNumber for next Run
    runNumber = runNumber + 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%               End of adaptive Ap-Av-Conflict Experiment
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             SetUp Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set all parameters relevant for the experiment, run, and the subject
    function SetParameters
        p.mri.on                                = p_mri_on;
        if runNumber == 0
            p.mri.on = 0;
            p_mri_on = 0;
        end
        p.mri.dummyScan                         = 2;
        p.totalRuns                             = totalRuns;
        p.comment                               = comment;
        p.runNumber                             = runNumber;
        p.prePostMAST                           = prePostSession;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% create log structure
        p.log.events                            = {{{},{},{},{},{},{}}};
        p.log.mriExpStartTime                   = 0;                       % Initialize as zero
        p.log.eventCount                        = 0;
        p.log.runNumber                         = runNumber;
        p.log.minShockStrengthInmA              = minShockStrengthInmA;
        p.log.maxShockStrengthInmA              = maxShockStrengthInmA;
        p.log.sessTake                          = [];
        p.log.sessRewOffer                      = [];
        p.log.sessRewOfferInCents               = [];
        p.log.sessAverOffer                     = [];
        p.log.sessTotalRewOfferAccum            = 0;
        p.log.sessTotalRewOfferInCentsAccum     = 0;
        p.log.sessRewardTakenAccum              = 0;
        p.log.sessRewardTakenInCentsAccum       = 0;
        p.log.sessShockStrengthsInmA            = [];
        %%%%%%%%%%%%%%%%%%%%%%%%%%% relative paths to stim and experiments
        [~, hostname] = system('hostname');
        p.hostname                     = deblank(hostname);
        p.hostaddress = java.net.InetAddress.getLocalHost ;
        p.hostIPaddress = char( p.hostaddress.getHostAddress);
        p.path.experiment              = [pwd filesep];
        p.path.instructionsFolder      = [p.path.experiment 'instructions/aAAC_Task_instructionsSlides_noButtons/']; % When using instructions without button presses
        p.subID                        = sprintf('ADMS_aACC_%03d_%sMAST',str2double(subject), p.prePostMAST);
        p.timestamp                    = datestr(now,30);
        p.path.subject                 = [p.path.experiment 'logs' filesep p.subID filesep];
        p.path.save                    = [p.path.subject '_tmp_' p.subID '_run' num2str(p.runNumber) '_' p.timestamp];
        if ~exist(p.path.subject,'dir'); mkdir(p.path.subject); end        % Create folder hierarchy
        addpath(genpath([p.path.experiment 'DS8R-MATLAB_official']));      % Add Digitimer dll and functions
        addpath(genpath([p.path.experiment 'daqtoolbox']));                % Add ML NI Daq control functions
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% font size and background gray level
        p.text.fontname                         = 'Arial';
        p.text.fontsize                         = 48; %72; %30; %18;
        p.stim.white                            = [255 255 255];
        p.stim.bg                               = [50 50 50];
        p.stim.distFromCenter                   = 0.5;                     % Distance for ApAv indicators relative from center to edge
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Key Settings - catch trigger from FORP
        KbName('UnifyKeyNames');
        p.keys.space                            = KbName('space');
        p.keys.next                             = KbName('RightArrow');
        p.keys.prev                             = KbName('LeftArrow');
        p.keys.trigger                          = KbName('t');
        
        % Values used for practice trials
        p.practice.rewardLevel         = [80 10 60 60 30 20 100 70 70 20 20 60 90 10 50];
        p.practice.punishLevel         = [30 70 10 60 100 30 70 80 50 100 20 80 50 100 50];
        p.practice.topAversive         = [1 0 0 1 0 1 0 1 0 1 1 0 1 1 0];
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Joystick Settings                      % Change these values for your setup!
        p.joy.mrjoystick                        = mr_joystick;
        if p.joy.mrjoystick
            p.joy.accelarationFactor            = 1;                       % Jump how many pxls
        else
            p.joy.accelarationFactor            = 2;                       % Jump how many pxls
        end
        p.joy.maxY                              = 65535;                   % Adjust this to your Joystick --> ToDo: Provide Routine to get this info
        p.joy.minY                              = 0;
        p.joy.rangeY                            = p.joy.maxY-p.joy.minY;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Digital communication for DS8R and EDA.
        p.niDaq = digitalio('nidaq','Dev1');
        addline(p.niDaq,0:7,0,'out');                                      % Add Line 0-7 of Port 0 for output
        putvalue(p.niDaq,0)
        [~, p.d128] = D128ctrl_MK2020('open');                             % open device and return handle for further class
        [~, p.d128] = D128ctrl_MK2020('status', p.d128);                   % Download status from Digitimer
        [~, p.d128] = D128ctrl_MK2020('enable', p.d128, 0);
        [~, p.d128] = D128ctrl_MK2020('source', p.d128, 'Internal');
        [~, p.d128] = D128ctrl_MK2020('pulsewidth', p.d128, 500);          % Set value of pulsewidth, but does not upload to device in us
        %[success, p.d128] = D128ctrl_MK2020('dwell', p.d128, 400);
        
        % LTP Codes for different events
        p.com.lpt.scannerPulseOnset             = 254; %16 32 64
        p.com.lpt.CueOnset                      = 16;
        p.com.lpt.FixOnset                      = 32;
        p.com.lpt.ShockOnset                    = 65;
        p.com.lpt.FbOnset                       = 128;
        p.com.lpt.duration                      = 0.005;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Stimulus sequence and timings
        % Fixed timings
        p.presentation.choiceDur                = 4;                       % in seconds
        p.presentation.greyOutDur               = 2;
        p.presentation.fbNoTextDur              = 2;
        p.presentation.fbRwTextDur              = 2;
        p.presentation.fbSessDur                = 5;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Adaptive Components
        p.TrialRecord.CurrentRunNumber          = runNumber;
        % Initialize fields
        if runNumber == 1
            p.TrialRecord.CurrentTrialNumber        = 0;
            p.TrialRecord.Initialized               = 0;
            p.TrialRecord.boundary                  = [];
            p.TrialRecord.yTraceFrameRate           = {};
            p.TrialRecord.yTraceFull                = {};
            p.TrialRecord.ReactionTime              = [];
            p.TrialRecord.Choice                    = {};
            p.TrialRecord.JoyInitMoveTime           = [];
            p.TrialRecord.ChoiceDirection           = {};
            p.TrialRecord.RewardTakenAccum          = 0;
            p.TrialRecord.RewardTakenInCentsAccum   = 0;
            p.TrialRecord.TotalOffersAccum          = 0;
            p.TrialRecord.TotalOffersInCentsAccum   = 0;
            p.TrialRecord.TrialShocked              = [];
            p.TrialRecord.ShockStrengtInmA          = [];
            
        end
        % If experiment needed to be restarted and TrialRecordInfo is lost,
        % read in from last uncorrupted logfile.
        if (runNumber > 1) && (~isfield(p.TrialRecord,'take'))
            % find previous log file if
            existingLogs    = ls(p.path.subject);
            prevRunLog     = existingLogs(~cellfun('isempty',strfind(cellstr(existingLogs),['run' num2str(runNumber-1)])),:);
            prevRunLog     = prevRunLog(cellfun('isempty',strfind(cellstr(prevRunLog),'_tmp')),:); %%% Add exception here if no run <runNumber exists (i.e. crashes when using runnumber = 3 but no 2 exists).
            if isempty(prevRunLog)
                error('Previous run was not finished or run, please consider rerunning the previous run!');
            elseif size(prevRunLog,1) > 1
                error('Multiple log files for previous run exist. Please consider to move incorrect runLogs to a "trash" directory!');
            else
                prevRunTrialRecord = load([p.path.subject prevRunLog]);
                p.TrialRecord = prevRunTrialRecord.p.TrialRecord;
            end
        end
        
        %%% Adaptive experimental settings
        p.TrialRecord.FractionCloseBoundOffers = 0.4;  % fraction of offers close to boundary;
        p.TrialRecord.FractionVariBoundaryOffers = 0.3;   % fraction of offers more variable around the boundary
        p.TrialRecord.FractionRandomOffers = 1 - p.TrialRecord.FractionVariBoundaryOffers - p.TrialRecord.FractionCloseBoundOffers; % any offers not "close" or "variable" will be random
        p.TrialRecord.CondProb = [p.TrialRecord.FractionCloseBoundOffers p.TrialRecord.FractionVariBoundaryOffers p.TrialRecord.FractionRandomOffers];   % now "conditions" are CloseBound, VariBoundary and Random
        p.TrialRecord.CondPseudorandBlocksize = 10;   % makes sure that conditions are chosen pseudorandomly over this block size according to probabilities in CondProb
        p.TrialRecord.BoundaryBlurVariBound = 10;  % for VariBound offers
        p.TrialRecord.BoundaryBlurCloseBound = 5; % for matched offers
        p.TrialRecord.AversionLow = 10;
        p.TrialRecord.AversionHigh = 100;
        p.TrialRecord.RewardLow = 10;
        p.TrialRecord.RewardHigh = 100;
        p.TrialRecord.NumInitialGridTrials = 9;  % per condition
        p.TrialRecord.RewardGridSteps = 3;
        p.TrialRecord.AversionGridSteps = 3;
        p.TrialRecord.RewOfferRound = 10;    % limits reward mag to these intervals
        p.TrialRecord.AverOfferRound = 10;    % limits aversion prob to these intervals
        p.TrialRecord.RewardToCentsScaleFactor = 0.5; % e.g., 0.5 means that reward of 100 will be transformed to 50 cents
        p.TrialRecord.NumberOfLevels = length(p.TrialRecord.AversionLow:p.TrialRecord.AverOfferRound:p.TrialRecord.AversionHigh);
        p.log.sessShockLevelsInmA = linspace(p.log.minShockStrengthInmA,p.log.maxShockStrengthInmA,p.TrialRecord.NumberOfLevels);
        
        % Triallist
        timingList                  = load([p.path.experiment 'jitterTimingList.mat']);
        p.timingList                = timingList.jitterTiminglist;
        p.presentation.trialNum     = cell2mat(p.timingList(2:end, 1));
        p.presentation.itd          = cell2mat(p.timingList(2:end, 2));
        p.presentation.itd2         = cell2mat(p.timingList(2:end, 3));
        p.presentation.topAversive  = cell2mat(p.timingList(2:end, 4));
        p.presentation.itd3         = cell2mat(p.timingList(2:end, 5));
        p.presentation.tTrial       = size(p.presentation.trialNum,1);
        p.presentation.sessNTrials  = p.presentation.tTrial/p.totalRuns;
        p.presentation.sessstartTr  = [0 1 2]*p.presentation.sessNTrials+1;
        clearvars timingList
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Save the parameters for this subject
        save(p.path.save ,'p');
    end

%% Set Up the PTB with parameters and initialize drivers
    function SetPTB
        %PsychDefaultSetup(0);
        %screens                     =  Screen('Screens');                 % Find the number of the screen to be opened
        p.ptb.screenNumber          =  screenNumber;                       % Alternatively, use max(screens);
        if debug
            commandwindow;
            PsychDebugWindowConfiguration;                                 % Make everything transparent for debugging purposes.
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Default parameters
        Screen('Preference', 'SkipSyncTests', 1);
        Screen('Preference', 'DefaultFontSize', p.text.fontsize);
        Screen('Preference', 'DefaultFontName', p.text.fontname);
        Screen('Preference', 'TextAntiAliasing',2);                        % Enable textantialiasing high quality
        Screen('Preference', 'VisualDebuglevel', 0);
        %Screen('Preference', 'SyncTestSettings' ,0.001 ,50, 0.1, 5);
        %Screen('Preference', 'SuppressAllWarnings', 0);
        if debug == 0
            HideCursor(p.ptb.screenNumber);                                % Hide the cursor
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Open a graphics window using PTB
        p.ptb.w                     = Screen('OpenWindow', p.ptb.screenNumber, p.stim.bg);
        Screen('TextStyle', p.ptb.w, 1);                                   % Make Text Bold
        Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        Screen('Flip',p.ptb.w);                                            % Make the bg
        p.ptb.slack                 = Screen('GetFlipInterval',p.ptb.w)./2;
        p.ptb.ifi                   = Screen('GetFlipInterval', p.ptb.w);
        [p.ptb.width, p.ptb.height] = Screen('WindowSize', p.ptb.screenNumber);
        p.ptb.midpoint              = [ p.ptb.width./2 p.ptb.height./2];   % Find the mid position on the screen.
        p.ptb.instructionWindow     = [p.ptb.midpoint(1)-(p.ptb.height/2) p.ptb.midpoint(2)-(p.ptb.height*0.75/2)...
            p.ptb.midpoint(1)+(p.ptb.height/2) p.ptb.midpoint(2)+(p.ptb.height*0.75/2)];
        %p.ptb.hertz                 = FrameRate(p.ptb.screenNumber);
        %p.ptb.nominalHertz = Screen('NominalFrameRate', p.ptb.screenNumber);
        p.ptb.pixelSize             = Screen('PixelSize', p.ptb.screenNumber);
        p.ptb.priorityLevel=MaxPriority('GetSecs','KbCheck','KbWait');
        Priority(MaxPriority(p.ptb.w));
        %%% Change arbitrary Joystick units to percent of ScreenSize
        p.joy.ScreenRelation           = p.ptb.height/p.joy.maxY-p.joy.minY;
        p.stim.distFromCenterAbs       = p.ptb.height/2*p.stim.distFromCenter;
        %%% Invert screen for presentation via mirrors, e.g. in mock scanner
        if invertScreenCalib && (runNumber == 0)
            Screen('glTranslate', p.ptb.w, p.ptb.width, 0, 0);             %translate the origin from upper left to upper right for mock scanner use
            Screen('glRotate', p.ptb.w, 180, 0, 1, 0);                     %rotate around y axis for mirror in mock scanner
        end
        if invertScreenRuns && (runNumber >= 1)
            Screen('glTranslate', p.ptb.w, p.ptb.width, 0, 0);             %translate the origin from upper left to upper right for mock scanner use
            Screen('glRotate', p.ptb.w, 180, 0, 1, 0);                     %rotate around y axis for mirror in mock scanner
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%% Fixed Stimuli/Shapes to present
        % Colors
        p.stim.barsFrameColor           = p.stim.white;
        p.stim.offerRectsColors         = [127 127 255; 255 127 127]';
        p.stim.indicatorColors          = p.stim.white;
        % Penwidths
        p.stim.penWidthPxlCircle        = 6;
        p.stim.penWidthPxlFrame         = 1;
        p.stim.dotSize                  = 35;
        p.stim.circleSize               = 70;
        %Shapes
        p.stim.fixCross                 = [CenterRectOnPointd([0 0 p.ptb.height*0.05 p.ptb.height*0.01],p.ptb.midpoint(1),p.ptb.midpoint(2));...
            CenterRectOnPointd([0 0 p.ptb.height*0.01 p.ptb.height*0.05],p.ptb.midpoint(1),p.ptb.midpoint(2))]';
        p.stim.offerHeight              = 70;
        p.stim.baseOfferRect            = [0 0 600 70];
        p.stim.baseAvApIndicatorRect    = [0 0 88 88];
        p.stim.barsFrameRect            = CenterRectOnPointd(...
            p.stim.baseOfferRect.*[1 1 1 2]+[0 0 10 6],...
            p.ptb.midpoint(1),  p.ptb.midpoint(2));
        p.stim.greyOutRect  = CenterRectOnPointd([0 0 980 850],...
            p.ptb.midpoint(1),  p.ptb.midpoint(2));
        
        % Place avoid/approach rects based on Trial Info
        p.stim.avoidRect = CenterRectOnPointd(p.stim.baseAvApIndicatorRect,...
            p.ptb.midpoint(1), p.ptb.midpoint(2));
        p.stim.apprCross = [CenterRectOnPointd(p.stim.baseAvApIndicatorRect.*[1 1 1/3 1],...
            p.ptb.midpoint(1),  p.ptb.midpoint(2));...
            CenterRectOnPointd(p.stim.baseAvApIndicatorRect.*[1 1 1 1/3 ],...
            p.ptb.midpoint(1),  p.ptb.midpoint(2))];
        p.stim.circle = [( p.ptb.midpoint(1)-p.stim.circleSize)...
            (p.ptb.midpoint(2)-p.stim.circleSize)...
            (p.ptb.midpoint(1)+p.stim.circleSize) (p.ptb.midpoint(2)+p.stim.circleSize)];
        
        p.stim.SesFBFrameRect = [p.ptb.midpoint(1)/1.5 p.ptb.midpoint(2)/2 p.ptb.midpoint(1)/1.5+round(p.ptb.midpoint(1)*0.075) (p.ptb.midpoint(2)/2)+p.ptb.midpoint(2)];
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Experimental Phases Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function runaAACTask
        fprintf('\n --------------- Found %d previous trials in TrialRecord ---------------', p.TrialRecord.CurrentTrialNumber);
        %p.presentation.sessNTrials = 2; % Use this for debugging to run a limited number of trials per session.
        for nTrial = 1:p.presentation.sessNTrials
            p.TrialRecord.CurrentTrialNumber = p.TrialRecord.CurrentTrialNumber+1;
            p_presentation_sessTrialNumber = nTrial;
            %%% Calculate decision boundary for this trial based on prev trials
            if p.TrialRecord.CurrentTrialNumber > p.TrialRecord.NumInitialGridTrials % finished initialGrid random trial selection?
                params = [];
                params.calculateDecisionBoundary = 1;
                params.suppressPlot = 1;
                [p.TrialRecord.boundary(1,1:2,p.TrialRecord.CurrentTrialNumber(end))] = plotaAACDecisionBoundary(p.TrialRecord.AverOffer,...
                    p.TrialRecord.RewOffer,p.TrialRecord.take,[],[],params);
            else
                p.TrialRecord.boundary(1,1:2,p.TrialRecord.CurrentTrialNumber) = NaN; % if still choosing initial trials randomly
            end
            p = trialSelection_aAAC(p);                                    % Select trial/condition/averOffer/rewOffer based on current decisionboundary
            %%% Set the variables for trial presentation.
            itd = p.presentation.itd(p.TrialRecord.CurrentTrialNumber(end));
            itd2 = p.presentation.itd2(p.TrialRecord.CurrentTrialNumber(end));
            itd3 = p.presentation.itd3(p.TrialRecord.CurrentTrialNumber(end));
            punishLevel = p.TrialRecord.AverOffer(end);
            rewardLevel = p.TrialRecord.RewOffer(end);
            topAversive = p.presentation.topAversive(p.TrialRecord.CurrentTrialNumber(end));
            %shockStrengthInmA = round(maxShockStrengthInmA*punishLevel./100,1); % Used for lower anchor = 0;
            shockStrengthInmA = round(p.log.sessShockLevelsInmA(p.TrialRecord.AversionLow:p.TrialRecord.AverOfferRound:p.TrialRecord.AversionHigh == punishLevel),1);
            fprintf('\nSess %d, Tr %d of %d,  Rew: %.0f, Pun: %.0f, ShInmA: %.1f, Bound: %1.2f , Type: %s, TopAver: %.0f, ITI: %.1f, ITI2: %.1f',...
                runNumber, p_presentation_sessTrialNumber,p.presentation.sessNTrials, rewardLevel, punishLevel, shockStrengthInmA, p.TrialRecord.boundary(1,1,end), p.TrialRecord.trialType(end), topAversive, itd, itd2);
            save(p.path.save ,'p');
            %%% Start Trial: here is time-wise sensitive and must be optimal
            Trial(itd, itd2,itd3, punishLevel, rewardLevel, topAversive, shockStrengthInmA)
            %%% End Trial
            if p_presentation_sessTrialNumber == p.presentation.sessNTrials% If last trial of session - present session feedback
                showSessionFeedback;
            end
            % If last trial of experiment, plot the boundary plot
            if p.TrialRecord.CurrentTrialNumber == p.presentation.tTrial
                params.suppressPlot = 1;                                   % use 0 to turn on at later time to get nice plot (might need image processing toolbox)
                params.calculateDecisionBoundary = 1;
                [p.TrialRecord.boundary(1,1:2,p.TrialRecord.CurrentTrialNumber(end))] = plotaAACDecisionBoundary(p.TrialRecord.AverOffer,...
                    p.TrialRecord.RewOffer,p.TrialRecord.take,[],[],params);
            end
        end
    end

    function Trial(itd, itd2,itd3, punishLevel, rewardLevel, topAversive, shockStrengthInmA)
        % Trialspecifics preparations
        if topAversive == 1
            curApprPosition = -p_stim_distFromCenterAbs;
        elseif  topAversive == 0
            curApprPosition = p_stim_distFromCenterAbs;
        else
            error('wrong input for currAvoidTop');
        end
        % Prepare offere bars which are trial wise-different
        rewRect         = CenterRectOnPointd(p_stim_baseOfferRect.*[1 1 rewardLevel/p.TrialRecord.RewardHigh  1],...
            p_ptb_midpoint_x,  p_ptb_midpoint_y-p_stim_offerHeight/2);
        punishRect      = CenterRectOnPointd(p_stim_baseOfferRect.*[1 1 punishLevel/p.TrialRecord.AversionHigh 1],...
            p_ptb_midpoint_x,  p_ptb_midpoint_y+p_stim_offerHeight/2);
        % Place avoid/approach rects based on Trial Info
        apprCross       = p_stim_apprCross + [0 curApprPosition 0 curApprPosition ];
        avoidRect       = p_stim_avoidRect - [0 curApprPosition 0 curApprPosition];
        % Combine Rects to compound Stims
        offerRects      = [rewRect; punishRect]';
        indicatorRects  = [avoidRect; apprCross]';
        rewardLevelInCents = rewardLevel*p.TrialRecord.RewardToCentsScaleFactor;
        %%% Run First ITI phase / dot, frame and fixed circle presented
        %         itdEndTime = GetSecs() + itd;
        %         frameN = 0;
        %         while GetSecs < itdEndTime
        %             frameN = frameN+1;
        %             Screen('FrameRect', p_ptb_w, p_stim_barsFrameColor, p_stim_barsFrameRect, p_stim_penWidthPxlFrame);
        %             Screen('DrawDots', p_ptb_w, [p_ptb_midpoint_x p_ptb_midpoint_y], p_stim_dotSize, p_stim_white, [], 2);
        %             Screen('FrameOval',p_ptb_w,p_stim_white, p_stim_circle ,p_stim_penWidthPxlCircle);
        %             lastItdFlip = Screen('Flip', p_ptb_w);                % Last value gets carried over to next phase
        %             if frameN == 1
        %                putLog(lastItdFlip, 'FirstItdFlip');
        %             end
        %         end
        %         putLog(lastItdFlip, 'LastItdFlip');
        
        Screen('FrameRect', p_ptb_w, p_stim_barsFrameColor, p_stim_barsFrameRect, p_stim_penWidthPxlFrame);
        Screen('DrawDots', p_ptb_w, [p_ptb_midpoint_x p_ptb_midpoint_y], p_stim_dotSize, p_stim_white, [], 2,1);
        Screen('FrameOval',p_ptb_w,p_stim_white, p_stim_circle ,p_stim_penWidthPxlCircle);
        FirstitdFlip = Screen('Flip', p_ptb_w);                % Last value gets carried over to next phase
        putLog(FirstitdFlip, 'ItdFirstFlip');
        % Use Itd to upload Digi, define and reset variables
        [~, p_d128] = D128ctrl_MK2020('demand', p_d128, shockStrengthInmA);
        D128ctrl_MK2020('upload', p_d128);
        [~, p_d128] = D128ctrl_MK2020('enable', p_d128, 1);
        % Reset variables
        lock = 0;
        yTraceCount = 0;
        yTrace = 0;
        frameN = 0;
        yTraceFrameRate = [];
        joyInitMoveTime         = 0;
        joyInitMove             = 0;
        [~,joyCalYPosition]     =  WinJoystickMex(0);
        choiceDirection         = 'empty';
        choicePhaseEndTime = FirstitdFlip+itd+p.presentation.choiceDur-p.ptb.slack;
        %Wait until itd is over (subtract half of ifi to allow time for preparation for of screen for first decision phase flip
        WaitSecs('UntilTime',FirstitdFlip+itd-p.ptb.slack);
        %%%% Run Choice phase / dot, circle, bars, frames, indicat presented
        while GetSecs() < choicePhaseEndTime
            % Draw Shapes and flip
            Screen('FillRect', p_ptb_w, p_stim_offerRectsColors, offerRects);
            Screen('FillRect', p_ptb_w, p_stim_indicatorColors, indicatorRects);
            Screen('FrameRect', p_ptb_w, p_stim_barsFrameColor, p_stim_barsFrameRect, p_stim_penWidthPxlFrame);
            Screen('DrawDots', p_ptb_w, [p_ptb_midpoint_x p_ptb_midpoint_y], p_stim_dotSize, p_stim_white, [], 2,1);
            Screen('FrameOval',p_ptb_w,p_stim_white, [(p_ptb_midpoint_x-p_stim_circleSize)...
                (p_ptb_midpoint_y-p_stim_circleSize-(yTrace(end)*p_joy_accelarationFactor))...
                (p_ptb_midpoint_x+p_stim_circleSize) (p_ptb_midpoint_y+p_stim_circleSize-(yTrace(end)*p_joy_accelarationFactor))],p_stim_penWidthPxlCircle);
            vbl = Screen('Flip', p_ptb_w);
            yTraceFrameRate(end+1) = yTrace(end);
            frameN = frameN+1;
            if frameN == 1
                putLog(vbl, 'FirstChoiceFlip');
                putMark(p.com.lpt.CueOnset);
                firstChoiceFlipTime = vbl;
            end
            %%%%%%%%%%%%%%   PROVIDE DESCRIPTION WHY THIS IS DONE HERE IN THIS WAY. BECAUSE JOYSTICK IS NOT SUPPORTED IN
            %%%%%%%%%%%%%%   WINDOWS VIA KBQUEUE. THIS HAS a up to 70kHZ sampling rate. Can be reduced but does have a gap
            %%%%%%%%%%%%%%   for flipping of ifi/2.5 (~6.7ms)
            while (GetSecs() < (vbl + p_ptb_ifi/2.5)) && (lock == 0)
                yTraceCount = yTraceCount+1;
                [~, newY] = WinJoystickMex(0);
                % Check for initial Joystick movement and get time
                if (joyInitMove == 0) && (newY~=joyCalYPosition)
                    joyInitMoveTime  = GetSecs()-firstChoiceFlipTime;
                    joyInitMove      = 1;
                    fprintf('\n --------------- joyInitMoveTime: %.3f ------------',joyInitMoveTime);
                end
                %%% Two possible versions possbile here, both have problems. My preference is picked here.
                yTrace(yTraceCount) = (joyCalYPosition - newY)*p_joy_ScreenRelation;
                %%% This one might be better if joystick returns reliably
                %%% back to middle point (develop-joy doesn't)
                %yTrace(yTraceCount) = (p_joy_midPosition - newY)*p_joy_ScreenRelation;
                
                % Lock if decision is made
                if yTrace(end) >= (p_stim_distFromCenterAbs/p_joy_accelarationFactor)
                    lockTime = GetSecs();
                    yTrace(end) = (p_stim_distFromCenterAbs/p_joy_accelarationFactor);
                    choiceDirection = 'up';
                    fprintf('\n --------------- Subject pushed: %s ------------',choiceDirection);
                    lock = 1;
                elseif yTrace(end) <= (-p_stim_distFromCenterAbs/p_joy_accelarationFactor)
                    lockTime = GetSecs();
                    yTrace(end) = (-p_stim_distFromCenterAbs/p_joy_accelarationFactor);
                    choiceDirection = 'down';
                    fprintf('\n --------------- Subject pushed: %s ------------',choiceDirection);
                    lock = 1;
                end
                %WaitSecs(0.001) % in case we want to reduce sampling rate and reduce yTrace logs.
                %                 %%% DEBUGGING PURPOSE, CAN BE DELETED
                %                 [keyIsDown, t, keyCode] = KbCheck(-1);
                %                 if keyIsDown
                %                     if find(keyCode) == 38
                %                         lockTime = GetSecs();
                %                         choiceDirection = 'up';
                %                         fprintf('\n --------------- Subject pushed: %s ------------',choiceDirection);
                %                         lock = 1;
                %                     elseif find(keyCode) == 40
                %                         lockTime = GetSecs();
                %                         choiceDirection = 'down';
                %                         fprintf('\n --------------- Subject pushed: %s ------------',choiceDirection);
                %                         lock = 1;
                %                     end
                %                 end
                %
            end
        end
        
        %%% Run Feeeback phase / start with + for itd2 secs
        %%% Run ITI2 Part
        Screen('FillRect', p_ptb_w, p_stim_white, p.stim.fixCross);
        itd2StartTime = Screen('Flip', p_ptb_w);
        putLog(itd2StartTime, 'FirstItd2Flip');
        putMark(p.com.lpt.FixOnset);
        itd2EndTime   = itd2StartTime+itd2;
        % Use waitTime to prep feedback
        if (topAversive == 1) && strcmp(choiceDirection, 'up')
            choice = 'approach';
        elseif (topAversive == 0) && strcmp(choiceDirection, 'down')
            choice = 'approach';
        else
            choice = 'avoid';
        end
        putLog(vbl, 'LastChoiceFlip');
        %%% Feedback phase
        if lock == 0
            DrawFormattedText(p.ptb.w,sprintf('No repsonse. \n You earned 0 cents!'),'center',p_ptb_midpoint_y,p_stim_white);
            trialShocked = 0;
            %trialShocked = 1;
            %shockStartTime = putShock(itd2EndTime, p_com_lpt_ShockOnset);
            %putLog(shockStartTime, ['shock: ' num2str(shockStrengthInmA)])     % Could be changed to actual mA level
            take = NaN;
            fprintf('\n --------------- Auto-Avoid ------------');
            %fprintf('\n --------------- Shock given with Level: %.1f ------------',shockStrengthInmA);
            fbFirstFlipTime = Screen('Flip', p_ptb_w,itd2EndTime+itd3-p.ptb.slack);
            choice              = 'auto avoid';
            reactionTime        = NaN;
        elseif lock == 1
            reactionTime = lockTime-firstChoiceFlipTime;
            fprintf('\n --------------- Subject took %.3fs to decide: %s ------------',reactionTime, choice);
            switch choice
                case 'approach'
                    p.log.sessRewardTakenAccum              = p.log.sessRewardTakenAccum + rewardLevel;
                    p.log.sessRewardTakenInCentsAccum       = p.log.sessRewardTakenInCentsAccum + rewardLevelInCents;
                    DrawFormattedText(p.ptb.w,sprintf('You earned %.0f cents!', rewardLevelInCents),'center',p_ptb_midpoint_y,p_stim_white);
                    shockStartTime = putShock(itd2EndTime, p_com_lpt_ShockOnset);
                    putLog(shockStartTime, ['shock: ' num2str(shockStrengthInmA)])
                    fprintf('\n --------------- Shock given with Level: %.1f ------------',shockStrengthInmA);
                    take = 1;
                    trialShocked = 1;
                    if runNumber > 0
                        p.TrialRecord.RewardTakenAccum          = p.TrialRecord.RewardTakenAccum + rewardLevel;
                        p.TrialRecord.RewardTakenInCentsAccum   = p.TrialRecord.RewardTakenInCentsAccum + rewardLevelInCents;
                    end
                    fbFirstFlipTime = Screen('Flip', p_ptb_w,itd2EndTime+itd3-p.ptb.slack);
                case 'avoid'
                    take = 0;
                    trialShocked = 0;
                    DrawFormattedText(p.ptb.w,'You earned 0 cents!','center',p_ptb_midpoint_y,p_stim_white);
                    fbFirstFlipTime = Screen('Flip', p_ptb_w, itd2EndTime+itd3-p.ptb.slack);
            end
        end
        putMark(p.com.lpt.FbOnset);
        [~, p_d128] = D128ctrl_MK2020('enable', p_d128, 0);
        putLog(fbFirstFlipTime, 'FirstFeedbackFlip');
        %%% Record outcomes making use of waitTime
        if runNumber > 0
            p.TrialRecord.take(end+1)               = take;
            p.TrialRecord.TrialShocked(end+1)       = trialShocked;
            p.TrialRecord.yTraceFrameRate(end+1,1)  = {yTraceFrameRate};
            p.TrialRecord.yTraceFull(end+1,1)       = {yTrace};
            p.TrialRecord.ReactionTime(end+1)       = reactionTime;
            p.TrialRecord.JoyInitMoveTime(end+1)    = joyInitMoveTime;
            p.TrialRecord.Choice(end+1)             = {choice};
            p.TrialRecord.ChoiceDirection(end+1)    = {choiceDirection};
            p.TrialRecord.TotalOffersAccum          = p.TrialRecord.TotalOffersAccum + rewardLevel;
            p.TrialRecord.TotalOffersInCentsAccum   = p.TrialRecord.TotalOffersInCentsAccum + rewardLevelInCents;
            p.TrialRecord.ShockStrengtInmA(end+1)   = shockStrengthInmA;
        end
        p.log.sessTake(end+1)                   = take;
        p.log.sessRewOffer(end+1)               = rewardLevel;
        p.log.sessRewOfferInCents(end+1)        = rewardLevelInCents;
        p.log.sessAverOffer(end+1)              = punishLevel;
        p.log.sessTotalRewOfferAccum            = p.log.sessTotalRewOfferAccum + rewardLevel ;
        p.log.sessTotalRewOfferInCentsAccum     = p.log.sessTotalRewOfferInCentsAccum + rewardLevelInCents ;
        p.log.sessShockStrengthsInmA(end+1)     = shockStrengthInmA;
        %%% Wait after last visual feedback flip until end of trial
        WaitSecs('UntilTime', fbFirstFlipTime+p.presentation.fbRwTextDur-p.ptb.slack);
    end

%% %%%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If  p_mrt_on == 1, wait for n dummyscans before actual experiment starts and print out time for starting pulse
    function [t] = WaitForDummyScans(n)
        if p_mri_on == 1
            pulse=0;
            DrawFormattedText(p.ptb.w,'Get Ready','center',p_ptb_midpoint_y,p_stim_white);
            Screen('Flip', p_ptb_w);
            while pulse <=n
                [keyIsDown, t, keyCode] = KbCheck(-1);
                if keyIsDown
                    if find(keyCode) == p_keys_trigger
                        WaitSecs(0.1);
                        keyIsDown   = [];
                        keyCode     = [];
                        pulse       = pulse+1;
                        fprintf('This was scanner pulse number: %d \n', pulse);
                    end
                end
            end
        else
            t = GetSecs;
        end
        putMark(p_com_lpt_scannerPulseOnset);
    end

%% Set Marker for BIOPAC
    function putMark(port)
        putvalue(niDaq,port);
        WaitSecs(p_com_lpt_duration);
        putvalue(niDaq,0);
    end

%% Send trigger for shock
    function shockStartTime = putShock(shockTime,port)
        shockStartTime = WaitSecs('UntilTime', shockTime);
        putvalue(niDaq,port);  % Triggers shocker but at the same time sends marker to BIOPAC
        WaitSecs(p_com_lpt_duration);
        putvalue(niDaq,0);
    end

%% Log all events
    function putLog(ptb_time, event_info)
        p.log.eventCount                     = p.log.eventCount + 1;
        p.log.events(p.log.eventCount,1)     = {p.log.eventCount};
        p.log.events(p.log.eventCount,2)     = {ptb_time};
        p.log.events(p.log.eventCount,3)     = {ptb_time-p.log.mriExpStartTime};
        p.log.events(p.log.eventCount,4)     = {event_info};
        p.log.events(p.log.eventCount,5)     = {p_presentation_sessTrialNumber};
        p.log.events(p.log.eventCount,6)     = {runNumber};
        %     trials1.addData('Yfinal',ylast)           % Can indeed be helpful when looking at fast/weird response times --> e.g. Joystick in weird initial space
        %     trials1.addData('Yinitial',ygo)
    end

%% Present session feedback about taken and accumulated offered reward
    function showSessionFeedback
        DrawFormattedText_mod(p.ptb.w,sprintf('You have earned \n %.2f $',p.log.sessRewardTakenInCentsAccum/100),'center',p_ptb_midpoint_y-(p.ptb.height*0.1),p_stim_white, 250, [],[],[], 1.5);
        Screen('FrameRect', p_ptb_w, p_stim_barsFrameColor, p.stim.SesFBFrameRect, p_stim_penWidthPxlFrame);
        fillSize  =  (p.stim.SesFBFrameRect(4)-p.stim.SesFBFrameRect(2))*(1-p.log.sessRewardTakenAccum/p.log.sessTotalRewOfferAccum);
        Screen('FillRect', p_ptb_w,p_stim_white , p.stim.SesFBFrameRect+[0 fillSize 0 0 ]);
        fbSessFirstFlipTime = Screen('Flip', p_ptb_w);
        putLog(fbSessFirstFlipTime, 'sessionFeedbackFirstFlip');
        WaitSecs(p.presentation.fbSessDur);
    end

%% Instruction Text
    function ShowInstruction
        [p.ptb.instruction_sprites] = CreateStimSprites(p.path.instructionsFolder);
        ShowText(p.ptb.instruction_sprites)
        function [out]=CreateStimSprites(path)
            dummy = dir(path);
            labels = {dummy(:).name};
            labels  =  labels(3:end)';
            FM    = [repmat([fileparts(path) filesep],length(dummy)-2,1) horzcat(cell2mat(labels))]; % Returns the file matrix
            for nStim = 1:size(FM,1)
                filename           = FM(nStim,:);
                [im , ~, ~]        = imread(filename);
                out(nStim)         = Screen('MakeTexture', p.ptb.w, im );
            end
        end
    end

%% RunPracticeTrials

    function RunPracticeTrials
        for pt = 1:length( p.practice.rewardLevel)
            shockStrengthInmA = round(p.log.sessShockLevelsInmA(p.TrialRecord.AversionLow:p.TrialRecord.AverOfferRound:p.TrialRecord.AversionHigh == p.practice.punishLevel(pt)),1);
            fprintf('\nSess Practice, Tr %d of %d,  Rew: %.0f, Pun: %.0f, ShInmA: %.1f',...
                pt,length(p.practice.rewardLevel), p.practice.rewardLevel(pt),  p.practice.punishLevel(pt), shockStrengthInmA);
            Trial(2, 2,2, p.practice.punishLevel(pt), p.practice.rewardLevel(pt), p.practice.topAversive(pt), shockStrengthInmA) % Hard coded ITI's / adjust if you want
        end
    end

%% End session Text
    function ShowEndSessionText
        fprintf('=================\n=================\nHit "space" to end the experiment!\n');
        endText = 'The experiment is now finished.\n\n\nThank you for your participation.\n\n\nPlease wait for further instructions.';
        DrawFormattedText(p.ptb.w,endText,'center','center',p_stim_white);
        Screen('Flip', p_ptb_w);
        while 1
            [keyIsDown, ~, keyCode] = KbCheck(-1);
            if keyIsDown
                if find(keyCode) ==  p.keys.space
                    break;
                end
            end
        end
    end

%% Show Text in a block
    function ShowText(textToShow)
        texti = 0;
        while 1
            texti = texti+1;
            Screen('DrawTexture', p_ptb_w, textToShow(texti), [], p.ptb.instructionWindow );
            Screen('DrawingFinished',p_ptb_w);
            introTextTime = Screen('Flip',p_ptb_w);
            putLog(introTextTime, ['TextSlide_' num2str(texti)]);
            WaitSecs(2);                                                   % Make sure your subject acutally reads the intro text
            while 1
                introTextKeyTime = GetSecs();
                [~,~,~, jsButtons] = WinJoystickMex(0);
                [~, ~, keyCode] = KbCheck(-1);
                if any(jsButtons)
                    if find(jsButtons) == 4
                        break;
                    elseif find(jsButtons) == 3  && texti>1
                        texti = texti-2;                                   % Go to previous slide
                        break;
                    end
                end
                if any(keyCode)
                    if find(keyCode) == p.keys.next      % Go to next slide
                        break;
                    elseif (find(keyCode) == p.keys.prev) && texti>1
                        texti = texti-2;
                        break;
                    end
                end
            end
            putLog(introTextKeyTime, 'TextSlideKbPress');
            if texti == length(textToShow)
                break;
            end
        end
    end

%% Create spreadsheet from logfile with all variables of interest
    function  T = makeSpreadsheet(p)
        VarOIs = {'RewOffer', 'AverOffer', 'take', 'Choice', 'ReactionTime', 'JoyInitMoveTime','TrialShocked' , 'ShockStrengtInmA', 'trialType',  'trialCond', 'boundary', 'ChoiceDirection', 'RewardTakenAccum',...
            'RewardTakenInCentsAccum', 'TotalOffersAccum'  , 'TotalOffersInCentsAccum'};
        T = table(repmat(p.subID,p.presentation.tTrial,1), 'VariableNames', {'ID'});
        T.Trial = (1:p.presentation.tTrial)';
        for v = 1:length(VarOIs)
            fldnme = cell2mat(VarOIs(v));
            if length(size(p.TrialRecord.(fldnme))) == 2
                if length(p.TrialRecord.(fldnme)) == p.presentation.tTrial
                    tmp = table(p.TrialRecord.(fldnme)', 'VariableNames', {fldnme});
                elseif length(p.TrialRecord.(fldnme)) == 1
                    tmp = table(repmat(p.TrialRecord.(fldnme)',p.presentation.tTrial,1), 'VariableNames', {fldnme});
                end
                T = [T tmp];
            elseif length(size(p.TrialRecord.(fldnme))) == 3
                xIntTmp = squeeze(p.TrialRecord.(fldnme))';
                tmp = [ table(xIntTmp(:,2), 'VariableNames', {sprintf('%s_Int',fldnme)}),...
                    table(xIntTmp(:,1), 'VariableNames', {sprintf('%s_x',fldnme)})];
                T = [T tmp];
            else
                stop('Variable of interest does not exist')
            end
        end
    end

%% After experiment is over clean everything and close drivers
    function cleanup
        %%% Set Digitimer to 0 and close it
        [~, p_d128] = D128ctrl_MK2020('demand', p_d128, 0);
        D128ctrl_MK2020('upload', p_d128);
        D128ctrl_MK2020('close', p_d128);
        D128ctrl_MK2020('close', p.d128);
        %%% Clean output files and make spreadsheet
        movefile([p.path.save '.mat'], erase([p.path.save '.mat'],'_tmp_'));
        p.path.save = erase([p.path.save],'_tmp_');
        save(p.path.save ,'p');
        if runNumber == totalRuns
            T = makeSpreadsheet(p);
            writetable(T,[p.path.save '.csv'])
        end
        save(p.path.save ,'p');
        %%% Close all
        sca;                                                               % Close window:
        commandwindow;
        ListenChar(0);                                                     % Use keys again
        %KbQueueRelease(p_ptb_device);
    end
end
%%% TODO
% Add 'makespreadsheetlog' function to save behavioral results
% Add calibration preocedure (extra script, but read-in logfile, maybe via dropdown menue to select file)
% Potentialy open up kbQUEUE for logging MR trigger.