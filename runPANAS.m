function runPANAS(subject, panasNumber, comment)
%Preliminary stuff
% check for Opengl compatibility, abort otherwise:
AssertOpenGL;

%%% Get input

if nargin < 2
    %%%%%%%%%%%%%% GET POPUP WINDOW INPUT HERE %%%%%%%%%%%%%%%%
    response = inputdlg({'ADMS_aACC ID#:', 'PANAS#:' 'Comment:'},...
        'Please enter information', [1 75]);
    subject                 = str2double(response{1});
    panasNumber              = str2double(response{2});
    comment                 = response{3};
    
    if isempty(subject) || isempty(panasNumber)
        error('Please specify details (subID and PANAS#).');
    end
end

if ~exist('comment', 'var')
    comment = '';
end
ListenChar(2);

screenNumber = 2;
%%%% Preparations
[~, hostname] = system('hostname');
pn.hostname                     = deblank(hostname);
pn.hostaddress = java.net.InetAddress.getLocalHost ;
pn.hostIPaddress = char( pn.hostaddress.getHostAddress);
pn.path.experiment              = [pwd filesep];

pn.subID                        = sprintf('ADMS_aACC_%03d', subject);
pn.panasNumber                   = panasNumber;
pn.timestamp                    = datestr(now,30);
pn.path.subject                 = [pn.path.experiment 'logs' filesep pn.subID filesep 'PANAS' filesep];
if ~exist(pn.path.subject,'dir'); mkdir(pn.path.subject); end
pn.path.save                    = [pn.path.subject filesep pn.subID '_PANAS_' num2str(pn.panasNumber) '_' pn.timestamp];
pn.comment                      = comment;
addpath([pwd filesep 'addResources']);
pn.colors.bgColor = [50 50 50];


% function handles
n2s = @num2str;
% Keys
HideCursor;
KbName('UnifyKeyNames');

pn.keys.left  = KbName('g');
pn.keys.right = KbName('b');
pn.keys.select  = KbName('r');

% Back ground colour


% Get information about the screen and set general things
Screen('Preference', 'SuppressAllWarnings',1);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebuglevel', 0);
FontName = 'Arial';
% Creating screen etc.
[pn.ptb.w, ScrRect] = Screen('OpenWindow', screenNumber, pn.colors.bgColor);
Screen('TextStyle', pn.ptb.w, 1);                                   % Make Text Bold
Screen('BlendFunction', pn.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
Screen('Flip',pn.ptb.w);                                            % Make the bg
Screen('TextFont',pn.ptb.w,FontName);


% screen setup
Black = [0 0 0];
White = [255 255 255];
Red = [255 0 0];
Yellow = [255 255 0];
FontName = 'Arial';
FontLg = 32;
Xres = ScrRect(3);
Yres = ScrRect(4);
%Dres = sqrt(Xres^2+Yres^2)/1750;
Screen('FillRect',pn.ptb.w, pn.colors.bgColor);
Screen('TextFont',pn.ptb.w,FontName);
Screen('TextSize',pn.ptb.w,FontLg);


% set datafile name and check for existing file
fileName = fullfile(pn.path.subject,[pn.subID  '_PANAS_' num2str(pn.panasNumber) '_' pn.timestamp '.csv']);
dataFile = fopen(fileName, 'a');

% print header
fprintf(dataFile,'*********************************************\n');
fprintf(dataFile,['* PANAS Questionnaire ' num2str(pn.panasNumber) '\n']);
fprintf(dataFile,['* Date/Time: ' datestr(now, 0) '\n']);
fprintf(dataFile,['* Subject Number: ' pn.subID '\n']);
fprintf(dataFile,'*********************************************\n\n');

% print column labels
fprintf(dataFile,['subject,'... %subject number
    'question,'...               % TCQ question
    'response,'...             % response
    'responseTimeInS,'...             % response
    '\n']);

% button setup
KbName('UnifyKeyNames')
LEFT  = KbName('g');
RIGHT = KbName('b');
DOWN  = KbName('r');

%                 LEFT  = KbName('4');
%                 RIGHT = KbName('6');
%                 DOWN  = KbName('5');

% load questions
question{1}  = 'Interested';
question{2}  = 'Distressed';
question{3}  = 'Excited';
question{4}  = 'Upset';
question{5}  = 'Strong';
question{6}  = 'Guilty';
question{7}  = 'Scared';
question{8}  = 'Hostile';
question{9}  = 'Enthusiastic';
question{10} = 'Proud';
question{11} = 'Irritable';
question{12} = 'Alert';
question{13} = 'Ashamed';
question{14} = 'Inspired';
question{15} = 'Nervous';
question{16} = 'Determined';
question{17} = 'Attentive';
question{18} = 'Jittery';
question{19} = 'Active';
question{20} = 'Afraid';

pn.totalQuestions = size(question,2);

%% trial loop
% makes sure the subject is ready
DrawFormattedText(pn.ptb.w,'Press any button when ready to begin questionnaire.','center','center',White);
Screen('Flip',pn.ptb.w);
KbWait(-1);
WaitSecs(1);

% generates digit rectangle
reccen = [Xres/2 Yres/3];
digrec = [Xres/2-350 Yres/2; ...
    Xres/2-175 Yres/2; ...
    
    Xres/2 Yres/2; ...
    
    Xres/2+175 Yres/2; ...
    Xres/2+350 Yres/2;];
digs = [1 2 3 4 5];

%Scale headers
% initialize block variables
runStart = GetSecs;
trial = 1;
run = 0;
block = 0;
block_type = 0;
blockStart = GetSecs;



% loops through question trials;
for trial = 1:size(question,2)
    startTime = GetSecs;
    % draw question
    DrawFormattedText(pn.ptb.w,'This scale consists of a number of words that describe different feelings and emotions. Read each statement and then respond using the scale below to indicate how you FEEL RIGHT NOW AT THIS MOMENT.','center',Yres/7,White, 55,[],[],1.25);

    DrawFormattedText(pn.ptb.w,question{trial},'center',Yres/2.75,Yellow);
    
    DrawFormattedText_mod(pn.ptb.w,sprintf('Very slightly'),'center',Yres/1.8, Red, -350);
    DrawFormattedText_mod(pn.ptb.w,sprintf('or not at all'),'center',Yres/1.8+(1.25*FontLg),Red, -350);
    %DrawFormattedText_mod(pn.ptb.w,sprintf(''),'center',Yres/1.8+(2*FontLg),Red, -350);
    DrawFormattedText_mod(pn.ptb.w,sprintf('A little'),'center',Yres/1.8,Red, -175);
    DrawFormattedText_mod(pn.ptb.w,sprintf('Moderately'),'center',Yres/1.8,Red, 0);
    DrawFormattedText_mod(pn.ptb.w,sprintf('Quite'),'center',Yres/1.8,Red, 175);
    DrawFormattedText_mod(pn.ptb.w,sprintf('a bit'),'center',Yres/1.8+(1.25*FontLg),Red, 175);
    DrawFormattedText_mod(pn.ptb.w,sprintf('Extremely'),'center',Yres/1.8,Red, 350);
    
    
    
    % draw digit rec
    for i = 1:5
        DrawFormattedText(pn.ptb.w,n2s(digs(i)),digrec(i,1),digrec(i,2),White);
    end
    
    % generates default red box around "1"
    Rbox = CenterRectOnPointd([0,0,40,40],digrec(1,1),digrec(1,2));
    %Rbox = Rbox + [10 21 10 21];
    Rbox = Rbox + [10 -10 10 -10]; % for new PC
    Screen('FrameRect',pn.ptb.w,Red,Rbox,2);
    Screen('Flip',pn.ptb.w);
    % trial start (from subject's POV)
    confirm = false;
    bpos = 1;
    moveCycles = 1;
    first_press =0;
    while ~confirm%(confirm == 0)
        %(strcmp(confirm, 'false'))
        FlushEvents('keyDown');
        [pressed,t,keyCode] = KbCheck(-3);
        
        % continue checking keyboard until pressed
        while ~pressed
            [pressed,t,keyCode] = KbCheck(-3);
        end
        %if moveCycles == 1
        %    first_press = t-blockStart;
        %end
        % reacts to response
        if keyCode(LEFT);
            % if participant hit left, move box to end
            if bpos == 1;
                bpos = 5;
            else
                bpos = bpos-1;
            end
        elseif keyCode(RIGHT);
            % if participant hit right, move box right
            if bpos == 5;
                bpos = 1;
            else
                bpos = bpos+1;
            end
        elseif keyCode(DOWN);
            % if participant hit down, end trial
            confirm = true;
            
        end
        
        % redraw screen with new box position
        for i = 1:5
            DrawFormattedText(pn.ptb.w,n2s(digs(i)),digrec(i,1),digrec(i,2),White);
        end
        Rbox = CenterRectOnPointd([0,0,40,40],digrec(bpos,1),digrec(bpos,2));
        %Rbox = Rbox + [10 21 10 21];
        Rbox = Rbox + [10 -10 10 -10]; % for new PC
        if confirm
            Screen('FrameRect',pn.ptb.w,Yellow,Rbox,2);
            confirm = '';
            
        else
            Screen('FrameRect',pn.ptb.w,Red,Rbox,2);
        end
        
        DrawFormattedText(pn.ptb.w,'This scale consists of a number of words that describe different feelings and emotions. Read each statement and then respond using the scale below to indicate how you FEEL RIGHT NOW AT THIS MOMENT.','center',Yres/7,White, 55,[],[],1.25);
        
        DrawFormattedText(pn.ptb.w,question{trial},'center',Yres/2.75,Yellow);
        
        DrawFormattedText_mod(pn.ptb.w,sprintf('Very slightly'),'center',Yres/1.8, Red, -350);
        DrawFormattedText_mod(pn.ptb.w,sprintf('or not at all'),'center',Yres/1.8+(1.25*FontLg),Red, -350);
        %DrawFormattedText_mod(pn.ptb.w,sprintf('all'),'center',Yres/1.8+(2*FontLg),Red, -350);
        DrawFormattedText_mod(pn.ptb.w,sprintf('A little'),'center',Yres/1.8,Red, -175);
        DrawFormattedText_mod(pn.ptb.w,sprintf('Moderately'),'center',Yres/1.8,Red, 0);
        DrawFormattedText_mod(pn.ptb.w,sprintf('Quite'),'center',Yres/1.8,Red, 175);
        DrawFormattedText_mod(pn.ptb.w,sprintf('a bit'),'center',Yres/1.8+(1.25*FontLg),Red, 175);
        DrawFormattedText_mod(pn.ptb.w,sprintf('Extremely'),'center',Yres/1.8,Red, 350);
        
        
        Screen('Flip',pn.ptb.w);
        % Pauses to avoid moving box too quickly
        WaitSecs(.1);
        moveCycles = moveCycles+1;
        responseTime = GetSecs() - startTime;
    end
    
    % creates output variables
    %question = question{trial};
    %response = bpos;
    
    % writes output to file
    fprintf(dataFile,'%s ,%s,%f,%f\n',pn.subID,question{trial},bpos, responseTime);
    trial = trial+1;
end

fclose('all');
save(pn.path.save ,'pn');
%MAST trials
DrawFormattedText(pn.ptb.w,'Wait for experimenter.','center','center',White);
Screen('Flip',pn.ptb.w);
%RestrictKeysForKbCheck([23]);
KbWait(0);
commandwindow;
ListenChar(0);
sca;

%%% Put space press here!
%RestrictKeysForKbCheck([]);