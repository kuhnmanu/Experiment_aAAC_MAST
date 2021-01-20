% Preliminary stuff
% check for Opengl compatibility, abort otherwise:
AssertOpenGL;

%%% Get subject and run

%%%%%%%%%%%%%% GET POPUP WINDOW INPUT HERE %%%%%%%%%%%%%%%%

response = inputdlg({'ADMS_aACC ID#:', 'VAMS#:' 'Comment:'},...
    'aAAC Task - Please enter information', [1 75]);
subject                 = response{1};
vamsNumber              = str2double(response{2});
comment                 = response{3};

if isempty(subject) || isempty(vamsNumber)
        error('Please specify details (subID and VAMS#).');
end



%%%% Preparations
[~, hostname] = system('hostname');
v.hostname                     = deblank(hostname);
v.hostaddress = java.net.InetAddress.getLocalHost ;
v.hostIPaddress = char( v.hostaddress.getHostAddress);
v.path.experiment              = [pwd filesep];

v.subID                        = sprintf('ADMS_aACC_%03d',str2double(subject));
v.vamsNumber                   = vamsNumber;
v.timestamp                    = datestr(now,30);
v.path.subject                 = [v.path.experiment 'logs' filesep v.subID filesep];
if ~exist(v.path.subject,'dir'); mkdir(v.path.subject); end
v.path.save                    = [v.path.subject filesep v.subID '_VAMS_' num2str(v.vamsNumber) '_' v.timestamp];
v.comment                      = comment;
addpath([pwd filesep 'VAMS']);

% Apearances
v.scala.colors.bgColor      = [50 50 50];
v.scala.colors.scalacolor   = [255 255 255];
v.scala.linelength          = 15;
v.scala.scalalength         = 0.64;
v.scala.startposition       = 'center';
v.scala.stepsize            = 3;
v.scala.displayposition     = 0;
v.scala.scalaposition       = 0.5;
v.scala.width               = 7;
v.scala.range               = 2;
% Keys
HideCursor;
KbName('UnifyKeyNames');
v.keys.left  = KbName('g');
v.keys.right = KbName('b');
v.keys.select  = KbName('r');

% Back ground colour


% Get information about the screen and set general things
Screen('Preference', 'SuppressAllWarnings',1);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebuglevel', 0);

% Creating screen etc.
[myScreen, rect] = Screen('OpenWindow', 1, v.scala.colors.bgColor);

questions = {{'How do you feel at this moment?', 'Happy', 'Sad'},...
    {'How do you feel at this moment?', 'Tense', 'Relaxed'},...
    {'How do you feel at this moment?', 'Friendly', 'Hostile'}};
v.totalQuestions = size(questions,2);

for q = 1:size(questions,2)
    
    currQ = questions{q};
    % Input for slide scale
    question  = currQ{1};
    endPoints = {currQ{2}, currQ{3}};
    
    [position, RT, answer] = slideScale(myScreen, ...
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
        'range', v.scala.range);
    logFieldName = ['Question' num2str(q)];
    v.log.(logFieldName).question = currQ{1};
    v.log.(logFieldName).leftAnchor = currQ{2};
    v.log.(logFieldName).rightAnchor = currQ{3};
    v.log.(logFieldName).response = round(position);
    v.log.(logFieldName).reactionTimeInMs = RT;
    v.log.(logFieldName).answeredYesNo = answer;
    
end

%%%%%%%%%% SAVE ANSWERS INTO STRUCT AND FILE %%%%%%%%%%%%%%
save(v.path.save ,'v');
% Close window
Screen('CloseAll')
