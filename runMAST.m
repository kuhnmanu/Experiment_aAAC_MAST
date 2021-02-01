function runMAST
%
subject = '';

response = inputdlg({'ADMS_aACC ID#:'},...
    'run MAST - Please enter information', [1 75],...
    {subject});
if isempty(response)
    error(['User pressed "Cancel" for run #: ' num2str(runNumber) '. Please restart for this run.']);
end
subject                 = response{1};

KbName('UnifyKeyNames');
p.keys.space                            = KbName('space');
p.keys.next                             = KbName('RightArrow');
p.keys.prev                             = KbName('LeftArrow');
p.ptb.screenNumber                      = 2;

commandwindow;
clear mex global
p.stim.bg                               = [50 50 50];
ListenChar(2);
%%%%%%%%%%%%%%%%%%%%%%%%%%% Default parameters
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'TextAntiAliasing',2);                        % Enable textantialiasing high quality
Screen('Preference', 'VisualDebuglevel', 0);
HideCursor(p.ptb.screenNumber);                                % Hide the cursor
%%%%%%%%%%%%%%%%%%%%%%%%%%% Open a graphics window using PTB
[p.ptb.w, ScrRect]                    = Screen('OpenWindow', p.ptb.screenNumber,p.stim.bg);
Screen('TextStyle', p.ptb.w, 1);                                   % Make Text Bold
Screen('BlendFunction', p.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
Screen('Flip',p.ptb.w);                                            % Make the bg

% screen setup
Black = [0 0 0];
White = [255 255 255];
Red = [255 0 0];
Yellow = [255 255 0];
FontName = 'Arial';
FontLg = 32;
Xres = ScrRect(3);
Yres = ScrRect(4);
%Dres = sqrt(Xres^2+Yres^2)/1500;
Screen('FillRect',p.ptb.w,p.stim.bg);
Screen('TextFont',p.ptb.w,FontName);
Screen('TextSize',p.ptb.w,FontLg);



%%%%%%%%%%%%%%%%%%%%%%%%%%% Load the GETSECS mex files so call them at least once
GetSecs;
WaitSecs(0.001);


% MAST instructions, TCQ and trials (press key to go through)
% MAST instructions
DrawFormattedText(p.ptb.w,'In the following task you will be asked to immerse \n your entire hand, including your wrist, \n in ice cold water for as long as possible. \n There will be multiple trials where you have to immerse \n your hand in the water and the duration of each \n trial is randomly chosen by the computer.','center','center',White,90,[],[],1.25);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
DrawFormattedText(p.ptb.w,'We will also tell you when to put your hand in and \n take it out. \n Because you will go back into the scanner \n after this task, you must not move \n your head when putting your hand into the water.','center','center',White,90,[],[],1.25);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
DrawFormattedText(p.ptb.w,'When the computer signals that it is time to \n take your hand out of the water \n you will remove your hand from the water and \n immediately start a mental arithmetic test \n where you must count backwards from the number shown \n on the screen in steps of 17 as quickly as possible.', 'center','center', White,90,[],[],1.25);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
DrawFormattedText(p.ptb.w,'You can rest your hand on the towel during the \n arithmetic test. \n You must continue with the arithmetic test until \n the computer signals the start of the next \n hand immersion trial.','center','center',White,90,[],[],1.25);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
DrawFormattedText(p.ptb.w,'Your counting will be monitored by the evaluators. \n Every time you make a mistake you will \n start the test over. \n Insufficient results on the test will require you to \n do the whole task again, so try to perform \n as well as possible.','center','center',White,90,[],[],1.25);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
DrawFormattedText(p.ptb.w,'The ice water is very cold and if it becomes \n unbearable you have the right to remove your hand \n if you really need to.  \n However, on each trial, we ask that you try to keep \n your hand in the water for as long as possible.','center','center',White,90,[],[],1.25);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
DrawFormattedText(p.ptb.w,'During this portion of the study you will be videotaped \n and later the videotapes will be analysed \n for facial expressions of pain.','center','center',White,90,[],[],1.5);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);

%TCQ - pre
% function handles
n2s = @num2str;

% sets random seed
try
    randinfo = rng('shuffle');
catch
    randinfo.Seed = sum(100*clock);
    rand('seed',randinfo.Seed)
end
% sets directories
HomeDir = pwd;
DataDir = 'logs';

% set subject directory
p.timestamp                    = datestr(now,30);
p.subID = sprintf('ADMS_aACC_%03d',str2double(subject));
mkdir(fullfile(HomeDir,DataDir,p.subID  ));

% set datafile name and check for existing file
fileName = fullfile(HomeDir,DataDir,p.subID,['TCQ_' p.subID '_preMAST_' p.timestamp '.csv']);
dataFile = fopen(fileName, 'a');

% print header
fprintf(dataFile,'*********************************************\n');
fprintf(dataFile,'* Threat Challenge Questionnaire_pre_MAST\n');
fprintf(dataFile,['* Date/Time: ' datestr(now, 0) '\n']);
fprintf(dataFile,['* Subject Number: ' p.subID '\n']);
fprintf(dataFile,['* Random seed: ' n2s(randinfo.Seed) '\n']);
fprintf(dataFile,'*********************************************\n\n');

% print column labels
fprintf(dataFile,['subject,'... %subject number
    'question,'...               % TCQ question
    'response,'...             % response
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
question{1} = 'The upcoming cognitive task \n is very demanding';
question{2} = 'I am uncertain about how I \n will perform during the task';
question{3} = 'The cognitive task will take a \n lot of effort to complete';
question{4} = 'The cognitive task will be very stressful';
question{5} = 'I feel that I have the cognitive abilities\n to perform the cognitive task successfully';
question{6} = 'It is very important to me that I perform \n well on the cognitive task';
question{7} = 'I''m the type of person who does well in \n these types of situations';
question{8} = 'Poor performance on the task would be \n very distressing for me';
question{9} = 'I expect to perform well on the \n cognitive task';
question{10} = 'I view the cognitive task as a \n positive challenge';
question{11} = 'I think the cognitive task represents \n a threat to me';

%% trial loop
% makes sure the subject is ready
DrawFormattedText(p.ptb.w,'Press any button when ready to begin questionnaire.','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
WaitSecs(0.5);

% generates digit rectangle
reccen = [Xres/2 Yres/3];
digrec = [Xres/2-300 Yres/2; ...
    Xres/2-200 Yres/2; ...
    Xres/2-100 Yres/2; ...
    Xres/2 Yres/2; ...
    Xres/2+100 Yres/2; ...
    Xres/2+200 Yres/2; ...
    Xres/2+300 Yres/2];
digs = [1 2 3 4 5 6 7];

%Scale headers
% initialize block variables
runStart = GetSecs;
trial = 1;
run = 0;
block = 0;
block_type = 0;
blockStart = GetSecs;

% loops through 11 question trials;
for trial = 1:11
    
    % draw question
    DrawFormattedText(p.ptb.w,'Please indicate how you are feeling right now about \n the cognitive task you are about to begin','center',Yres/5,White,90,[],[],1.25);
    
    DrawFormattedText(p.ptb.w,question{trial},'center',Yres/2.8,Yellow,90,[],[],1.25);
    
    DrawFormattedText(p.ptb.w,'Strongly disagree',Xres/2-380,Yres/1.8,Red);
    DrawFormattedText(p.ptb.w,'Neutral',Xres/2-40,Yres/1.8,Red);
    DrawFormattedText(p.ptb.w,'Strongly agree',Xres/2+200,Yres/1.8,Red);
    
    
    % draw digit rec
    for i = 1:7
        DrawFormattedText(p.ptb.w,n2s(digs(i)),digrec(i,1),digrec(i,2),White);
    end
    
    % generates default red box around "1"
    Rbox = CenterRectOnPointd([0,0,40,40],digrec(1,1),digrec(1,2));
    %Rbox = Rbox + [10 21 10 21];
    Rbox = Rbox + [10 -10 10 -10]; % for new PC
    Screen('FrameRect',p.ptb.w,Red,Rbox,2);
    Screen('Flip',p.ptb.w);
    WaitSecs(0.5);
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
                bpos = 7;
            else
                bpos = bpos-1;
            end
        elseif keyCode(RIGHT);
            % if participant hit right, move box right
            if bpos == 7;
                bpos = 1;
            else
                bpos = bpos+1;
            end
        elseif keyCode(DOWN);
            % if participant hit down, end trial
            confirm = true;
            
        end
        
        % redraw screen with new box position
        for i = 1:7
            DrawFormattedText(p.ptb.w,n2s(digs(i)),digrec(i,1),digrec(i,2),White);
        end
        Rbox = CenterRectOnPointd([0,0,40,40],digrec(bpos,1),digrec(bpos,2));
        %Rbox = Rbox + [10 21 10 21];
        Rbox = Rbox + [10 -10 10 -10]; % for new PC
        if confirm
            Screen('FrameRect',p.ptb.w,Yellow,Rbox,2);
            confirm = '';
            
        else
            Screen('FrameRect',p.ptb.w,Red,Rbox,2);
        end
        DrawFormattedText(p.ptb.w,'Please indicate how you are feeling right now about \n the cognitive task you are about to begin','center',Yres/5,White,90,[],[],1.25);
        
        DrawFormattedText(p.ptb.w,question{trial},'center',Yres/2.8,Yellow,90,[],[],1.25);
        
        DrawFormattedText(p.ptb.w,'Strongly disagree',Xres/2-380,Yres/1.8,Red);
        DrawFormattedText(p.ptb.w,'Neutral',Xres/2-40,Yres/1.8,Red);
        DrawFormattedText(p.ptb.w,'Strongly agree',Xres/2+200,Yres/1.8,Red);
        
        Screen('Flip',p.ptb.w);
        % Pauses to avoid moving box too quickly
        WaitSecs(.1);
        moveCycles = moveCycles+1;
        
    end
    
    % creates output variables
    %question = question{trial};
    %response = bpos;
    
    % writes output to file
    fprintf(dataFile,'%s ,%s,%f,\n',p.subID,question{trial},bpos)
    trial = trial+1;
end

fclose('all');

%MAST trials
DrawFormattedText(p.ptb.w,'Wait for experimenter.','center','center',White);
Screen('Flip',p.ptb.w);
%RestrictKeysForKbCheck([23]);
KbWait(-3);                 %%% Put space press here!
%RestrictKeysForKbCheck([]);



while 1
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown
        if find(keyCode) == p.keys.space
            break;
        end
    end
end

 
DrawFormattedText(p.ptb.w,'Put your hand in the water','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(90);
DrawFormattedText(p.ptb.w,'Take your hand out of the water and count \n backwards from 2043 in steps of 17','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(90);;
DrawFormattedText(p.ptb.w,'Put your hand in the water','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(60);
DrawFormattedText(p.ptb.w,'Take your hand out of the water and count \n backwards from 2064 in steps of 17','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(60);
DrawFormattedText(p.ptb.w,'Put your hand in the water','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(45);
DrawFormattedText(p.ptb.w,'Take your hand out of the water and count \n backwards from 2032 in steps of 17','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(90);
DrawFormattedText(p.ptb.w,'Put your hand in the water','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(90);
DrawFormattedText(p.ptb.w,'Take your hand out of the water and count \n backwards from 2091 in steps of 17','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(60);
DrawFormattedText(p.ptb.w,'Put your hand in the water','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(45);




% sets random seed
try
    randinfo = rng('shuffle');
catch
    randinfo.Seed = sum(100*clock);
    rand('seed',randinfo.Seed)
end
p.timestamp                    = datestr(now,30);
% set datafile name and check for existing file
fileName = fullfile(HomeDir, DataDir,p.subID,['TCQ_' p.subID '_postMAST_' p.timestamp '.csv']);
dataFile = fopen(fileName, 'a');

% print header
fprintf(dataFile,'*********************************************\n');
fprintf(dataFile,'* Threat Challenge Questionnaire_post_MAST\n');
fprintf(dataFile,['* Date/Time: ' datestr(now, 0) '\n']);
fprintf(dataFile,['* Subject Number: ' p.subID '\n']);
fprintf(dataFile,['* Random seed: ' n2s(randinfo.Seed) '\n']);
fprintf(dataFile,'*********************************************\n\n');

% print column labels
fprintf(dataFile,['subject,'... %subject number
    'question,'...               % TCQ question
    'response,'...             % response
    '\n']);

%load questions
question{1} = 'The cognitive task \n was very demanding';
question{2} = 'I was very uncertain about how I \n performed during the cognitive task';
question{3} = 'The cognitive task took a \n lot of effort to complete';
question{4} = 'The cognitive task was very stressful';
question{5} = 'I felt that I had the cognitive abilities \n to perform the cognitive task successfully';
question{6} = 'It was very important to me that I performed \n well on the cognitive task';
question{7} = 'I''m the kind of person who does well in \n these types of situations';
question{8} = 'Poor performance on the task would be \n very distressing for me';
question{9} = 'Before beginning, I expected to perform \n well on the cognitive task';
question{10} = 'I viewed the cognitive task as a \n positive challenge';
question{11} = 'I thought the cognitive task represented\n  a threat to me';

%% trial loop
% makes sure the subject is ready
DrawFormattedText(p.ptb.w,'Press any button when ready to begin questionnaire.','center','center',White);
Screen('Flip',p.ptb.w);
WaitSecs(1);
KbWait(-3);
WaitSecs(0.5);

% generates digit rectangle
reccen = [Xres/2 Yres/3];
digrec = [Xres/2-300 Yres/2; ...
    Xres/2-200 Yres/2; ...
    Xres/2-100 Yres/2; ...
    Xres/2 Yres/2; ...
    Xres/2+100 Yres/2; ...
    Xres/2+200 Yres/2; ...
    Xres/2+300 Yres/2];
digs = [1 2 3 4 5 6 7];

%Scale headers


% initialize block variables
runStart = GetSecs;
trial = 1;
run = 0;
block = 0;
block_type = 0;
blockStart = GetSecs;

% loops through 11 question trials;
for trial = 1:11
    
    % draw question
    DrawFormattedText(p.ptb.w,'Please indicate how you are feeling right now about \n the cognitive task you are about to begin','center',Yres/5,White,90,[],[],1.25);
    
    DrawFormattedText(p.ptb.w,question{trial},'center',Yres/2.8,Yellow,90,[],[],1.25);
    
    DrawFormattedText(p.ptb.w,'Strongly disagree',Xres/2-380,Yres/1.8,Red);
    DrawFormattedText(p.ptb.w,'Neutral',Xres/2-40,Yres/1.8,Red);
    DrawFormattedText(p.ptb.w,'Strongly agree',Xres/2+200,Yres/1.8,Red);
    
    
    % draw digit rec
    for i = 1:7
        DrawFormattedText(p.ptb.w,n2s(digs(i)),digrec(i,1),digrec(i,2),White);
    end
    
    % generates default red box around "1"
    Rbox = CenterRectOnPointd([0,0,40,40],digrec(1,1),digrec(1,2));
    %Rbox = Rbox + [10 21 10 21];
    Rbox = Rbox + [10 -10 10 -10]; % for new PC
    Screen('FrameRect',p.ptb.w,Red,Rbox,2);
    Screen('Flip',p.ptb.w);
    WaitSecs(0.5);
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
                bpos = 7;
            else
                bpos = bpos-1;
            end
        elseif keyCode(RIGHT);
            % if participant hit right, move box right
            if bpos == 7;
                bpos = 1;
            else
                bpos = bpos+1;
            end
        elseif keyCode(DOWN);
            % if participant hit down, end trial
            confirm = true;
            
        end
        
        % redraw screen with new box position
        for i = 1:7
            DrawFormattedText(p.ptb.w,n2s(digs(i)),digrec(i,1),digrec(i,2),White);
        end
        Rbox = CenterRectOnPointd([0,0,40,40],digrec(bpos,1),digrec(bpos,2));
        %Rbox = Rbox + [10 21 10 21];
        Rbox = Rbox + [10 -10 10 -10]; % for new PC
        if confirm
            Screen('FrameRect',p.ptb.w,Yellow,Rbox,2);
            confirm = '';
            
        else
            Screen('FrameRect',p.ptb.w,Red,Rbox,2);
        end
        DrawFormattedText(p.ptb.w,'Please indicate how you are feeling right now about \n the cognitive task you are about to begin','center',Yres/5,White,90,[],[],1.25);
        
        DrawFormattedText(p.ptb.w,question{trial},'center',Yres/2.8,Yellow,90,[],[],1.25);
        
        DrawFormattedText(p.ptb.w,'Strongly disagree',Xres/2-380,Yres/1.8,Red);
        DrawFormattedText(p.ptb.w,'Neutral',Xres/2-40,Yres/1.8,Red);
        DrawFormattedText(p.ptb.w,'Strongly agree',Xres/2+200,Yres/1.8,Red);
        
        Screen('Flip',p.ptb.w);
        % Pauses to avoid moving box too quickly
        WaitSecs(.1);
        moveCycles = moveCycles+1;
        
    end
    
    % creates output variables
    %question = question{trial};
    %response = bpos;
    
    % writes output to file
    fprintf(dataFile,'%s ,%s,%f,\n',p.subID,question{trial},bpos)
    trial = trial+1;
end
ListenChar(0);
fclose('all');
sca;
end