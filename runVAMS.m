function runVAMS(subject, vamsNumber)

% Preliminary stuff
% check for Opengl compatibility, abort otherwise:
AssertOpenGL;

%%% Get input

if nargin < 2
    %%%%%%%%%%%%%% GET POPUP WINDOW INPUT HERE %%%%%%%%%%%%%%%%
    response = inputdlg({'ADMS_aAAC ID#:', 'VAMS#:'},...
        'aAAC Task - Please enter information', [1 75]);
    subject                 = str2double(response{1});
    vamsNumber              = str2double(response{2});
    
    if isempty(subject) || isempty(vamsNumber)
        error('Please specify details (subID and VAMS#).');
    end
end

ListenChar(2);
%%%% Preparations
[~, hostname] = system('hostname');
v.hostname                     = deblank(hostname);
v.hostaddress = java.net.InetAddress.getLocalHost ;
v.hostIPaddress = char( v.hostaddress.getHostAddress);
v.path.experiment              = [pwd filesep];

v.subID                        = sprintf('ADMS_aAAC_%03d', subject);
v.vamsNumber                   = vamsNumber;
v.timestamp                    = datestr(now,30);
v.path.subject                 = [v.path.experiment 'logs' filesep v.subID filesep 'VAMS' filesep];
if ~exist(v.path.subject,'dir'); mkdir(v.path.subject); end
v.path.save                    = [v.path.subject filesep v.subID '_VAMS_' num2str(v.vamsNumber) '_' v.timestamp];
addpath([pwd filesep 'addResources']);

% Apearances
v.scala.colors.bgColor      = [50 50 50];
v.scala.colors.scalacolor   = [255 255 255];
v.scala.linelength          = 20;
v.scala.scalalength         = 0.64;
v.scala.startposition       = 'center';
v.scala.stepsize            = 3;
v.scala.displayposition     = 0;
v.scala.scalaposition       = 0.5;
v.scala.width               = 7;
v.scala.rangeSetting        = 2;
if v.scala.rangeSetting == 1
    v.scala.leftEnd = -100;
    v.scala.rightEnd = 100;
elseif v.scala.rangeSetting == 2
    v.scala.leftEnd =    0;
    v.scala.rightEnd = 100;
end
% Keys
HideCursor;
KbName('UnifyKeyNames');
if vamsNumber < 5
    v.keys.left  = KbName('g');
    v.keys.right = KbName('b');
    v.keys.select  = KbName('r');
elseif vamsNumber == 5
    v.keys.left  = KbName('LeftArrow');
    v.keys.right = KbName('RightArrow');
    v.keys.select  = KbName('UpArrow');
end
% Back ground colour


% Get information about the screen and set general things
Screen('Preference', 'SuppressAllWarnings',1);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebuglevel', 0);
FontName = 'Arial';
FontLg = 32;
screenNumber = 2;
% Creating screen etc.
[v.ptb.w, rect] = Screen('OpenWindow', screenNumber, v.scala.colors.bgColor);
Screen('TextStyle', v.ptb.w, 1);                                   % Make Text Bold
Screen('BlendFunction', v.ptb.w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
Screen('Flip',v.ptb.w);                                            % Make the bg
Screen('TextFont',v.ptb.w,FontName);
Screen('TextSize',v.ptb.w,FontLg);

questions = {{'How do you feel at this moment?', 'Happy', 'Sad'},...
    {'How do you feel at this moment?', 'Tense', 'Relaxed'},...
    {'How do you feel at this moment?', 'Friendly', 'Hostile'}};
v.totalQuestions = size(questions,2);


% set datafile name and check for existing file
fileName = fullfile(v.path.subject,[v.subID  '_VAMS_' num2str(v.vamsNumber) '_' v.timestamp '.csv']);
dataFile = fopen(fileName, 'a');

% print header
fprintf(dataFile,'*********************************************\n');
fprintf(dataFile,'* Visual Analog Mood Scale\n');
fprintf(dataFile,['* Date/Time: ' datestr(now, 0) '\n']);
fprintf(dataFile,['* Subject Number: ' v.subID '\n']);
fprintf(dataFile,'*********************************************\n\n');

% print column labels
fprintf(dataFile,['subject,'... %subject number
    'question,'...               % TCQ question
    'response,'...             % response
    'reactionTimeInMs,'...             % response
    'answered,'...             % response
    '\n']);





for q = 1:size(questions,2)
    
    currQ = questions{q};
    % Input for slide scale
    question  = currQ{1};
    endPoints = {currQ{2}, currQ{3}};
    
    [position, RT, answer] = slideScale(v.ptb.w, ...
        question, ...
        rect, ...
        endPoints, ...
        'device', 'keyboard', ...
        'stepsize', v.scala.stepsize, ...
        'scalalength', v.scala.scalalength,...
        'linelength', v.scala.linelength,...
        'scalacolor', v.scala.colors.scalacolor, ...
        'responseKeys', [v.keys.select v.keys.left  v.keys.right], ...
        'startposition', v.scala.startposition, ...
        'displayposition', v.scala.displayposition,...
        'scalaPosition', v.scala.scalaposition,...
        'width', v.scala.width,...
        'range', v.scala.rangeSetting);
    logFieldName = ['Question' num2str(q)];
    v.log.(logFieldName).question = currQ{1};
    v.log.(logFieldName).leftAnchor = currQ{2};
    v.log.(logFieldName).rightAnchor = currQ{3};
    v.log.(logFieldName).response = round(position);
    v.log.(logFieldName).reactionTimeInMs = RT;
    v.log.(logFieldName).answeredYesNo = answer;
    
    fprintf(dataFile,'%s ,%s,%f,%f,%f\n',v.subID,question,round(position), RT, answer);
    
    
end

fclose('all');
%%%%%%%%%% SAVE ANSWERS INTO STRUCT AND FILE %%%%%%%%%%%%%%
save(v.path.save ,'v');
% Close window
ListenChar(0);
Screen('CloseAll')

