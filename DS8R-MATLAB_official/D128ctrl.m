function [success, d128] = D128ctrl(command,varargin)
% Matlab interface to Digitimer DSR devices which provides an 
% easy-to-use interface for loading and % calling functions in the
% Digitimer-provided Proxy DLL (D128RProxy.dll)
%
% This function uses the Matlab 'loadlibrary' function which requres
% a supported third party compiler to be installed. See matlab help
% documentation on setting up the compiler.
%
% For basic help on most commands, enter a command with no additional 
% arguments. Refer to the Digitimer help documentation for detailed
% information on specific functionality.
%
% Valid commands are: open, close, trigger, upload, status, mode,
% 	polarity, source, enable, demand, pulsewidth, dwell, recovery
%
% The commands mode, polarity, source, enable, demand, pulse, dwell,
% 	and recovery do not directly change the device settings. The upload
%	command must be called after these commands to actually change
%	the device settings. Valid parameters to each setting can be viewed
%   by calling the command with no arguements (e.g. D128('source');)
%
% The d128 is Matlab structure can be viewed to see the current
% settings. While this structure can be modified directly, it is 
% recommended to use the commands above to modify the structure.
%
% Example usage:
%	[success, d128] = D128ctrl('open');
%	[success, d128] = D128ctrl('status', d128);
%	[success, d128] = D128ctrl('dwell', d128, 400);
%	success = D128ctrl('upload', d128);
%
% This work was created by employees of the US Federal governement
% and is under the Public Domain.

% Path of D128RProxy.dll, must terminate in '/'
% This must reside in c:/windows/syswow64
% PATH_PROXY = 'C:/Windows/SysWOW64/';
% PATH_PROXY = ''; %added after Gareth's suggestion on 64bit systems
% PATH_PROXY = 'C:\Program Files\Digitimer Limited\D128RProxy\';
PATH_PROXY = 'H:\My Drive\T32 Research\Other Project\aAAC\Shocker Setup\Digitimer\code\DS8R-MATLAB_official\';
% Path of D128RProxy.h
PATH_H = './';
% Name of Digitimer supplied proxy DLL
NAME_PROXY = 'D128RProxy.dll';
% Name of Digitimer supplied header file.
NAME_H = 'D128RProxy.h';

% Alias for loaded library
ALIAS_PROXY = 'D128RProxy';

% Map user friendly names to actual values
D128Mode = containers.Map;
D128Mode('Mono-phasic') = int32(1);
D128Mode('Bi-phasic') = int32(2);
D128Mode('NoChange') = int32(7);

D128Pol = containers.Map;
D128Pol('Positive') = int32(1);
D128Pol('Negative') = int32(2);
D128Pol('Alternating') = int32(3);
D128Pol('NoChange') = int32(7);

D128Src = containers.Map;
D128Src('Internal') = int32(1);
D128Src('External') = int32(2);
D128Src('NoChange') = int32(7);

nargin = size(varargin,2);
success = 0;

if (strcmpi(command,'open'))
    if (nargin == 0)
        success = Init();
        if (success) 
            success = Open();
            d128.mode = 0;
            d128.polarity = 0;
            d128.source = 0;
            d128.demand = 0;
            d128.pulsewidth = 0;
            d128.dwell = 0;
            d128.recovery = 0;
            d128.enabled = 0;
        end
    else
        fprintf('Unexpected number of arguments for open command\n');
        fprintf('\tThe open command accepts no arguments\n');
    end
elseif (strcmpi(command,'close'))
    if (nargin == 1) 
        d128 = varargin{1};
        success = Close();
    else
        fprintf('Unexpected number of arguments for close command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
    end
elseif (strcmpi(command,'trigger'))
    if (nargin == 1)
        Trigger();
        success = 1;
    else
        fprintf('Unexpected number of arguments for trigger command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
    end 
elseif (strcmpi(command,'upload'))
    if (nargin == 1)
        d128 = varargin{1};
        Set(d128);
        success = 1;
    else
        fprintf('Unexpected number of arguments for upload command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
    end    
elseif (strcmpi(command,'status'))
    if (nargin == 1)
        d128 = varargin{1};
        d128 = GetState(d128);
        success = 1;
    else
        fprintf('Unexpected number of arguments for status command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
    end
elseif (strcmpi(command,'mode'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = varargin{2};
        if isKey(D128Mode, tmp)
            d128.mode = D128Mode(tmp);
        else
            fprintf('Unknown mode type %s\n', tmp);
        end
    else
        fprintf('Unexpected number of arguments for mode command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\tmode - %s\n', strjoin(D128Mode.keys(),', '));
    end
elseif (strcmpi(command,'polarity'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = varargin{2};
        if isKey(D128Pol, tmp)
            d128.polarity = D128Pol(tmp)
        else
            fprintf('Unknown polarity type %s\n', tmp);
        end
    else
        fprintf('Unexpected number of arguments for polarity command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\tpolarity - %s\n', strjoin(D128Pol.keys(),', '));
    end  
elseif (strcmpi(command,'source'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = varargin{2};
        if isKey(D128Src, tmp)
            d128.source = D128Src(tmp)
        else
            fprintf('Unknown source type %s\n', tmp);
        end
    else
        fprintf('Unexpected number of arguments for setpolarity command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\tsource - %s\n', strjoin(D128Src.keys(),', '));
    end 
elseif (strcmpi(command,'enable'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = int32(varargin{2});
        if tmp
             d128.enabled = int32(2);
        else
            d128.enabled = int32(1);
        end
    else
        fprintf('Unexpected number of arguments for enable command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\tenable - true or false\n');
    end  
elseif (strcmpi(command,'demand'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = int32(varargin{2});
        d128.demand = int32(tmp) * 10;
    else
        fprintf('Unexpected number of arguments for demand command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\tdemand - demand in mA\n')
    end    
elseif (strcmpi(command,'pulsewidth'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = int32(varargin{2});
        d128.pulsewidth = tmp;
    else
        fprintf('Unexpected number of arguments for pulsewidth command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\tpulsewidth - pulse width in us\n')
    end   
elseif (strcmpi(command,'dwell'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = int32(varargin{2});
        if (tmp >= 1 && tmp <= 990)
             d128.dwell = tmp;
%             else
         else
             fprintf('Dwell must be between 10 and 100\n');
        end
        fprintf('Unexpected number of arguments for dwell command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\tdwell - dwell time in us (1-990)\n')
    end  
elseif (strcmpi(command,'recovery'))
    if (nargin == 2)
        d128 = varargin{1};
        tmp = varargin{2};
        if isa(tmp, 'integer')
            tmp = int32(tmp);
            if (tmp >= 10 && tmp <= 100)
                d128.recovery = tmp;
            else
                fprintf('recovery must be between 10 and 100\n');
            end
        else
            fprintf('Unknown recovery argument %s\n', tmp);
        end
    else
        fprintf('Unexpected number of arguments for recovery command\n');
        fprintf('\td128 - D128 struct returned by open command\n');
        fprintf('\trecovery - recovery time (10-100, bi-phasic only)\n')
    end
end

%end of main program


% nested functions used by main interface above.
    function success = Init()
        full_dll = fullfile(PATH_PROXY, NAME_PROXY);
        full_h = fullfile(PATH_H, NAME_H);
        if (~libisloaded(ALIAS_PROXY))
            [nf, ~] = loadlibrary(full_dll, full_h);
            success = isempty(nf);
            if (~success)
                fprintf('%s was not found!\n', full_dll);
            end
        else
            success = 1;
        end
    end

    function [success] = Open()
        success = 1;
    end

    function success = Close(handle)
        success = 1;
        % unloadlibrary(ALIAS_PROXY)
    end
        
    function Trigger()
        if (libisloaded(ALIAS_PROXY))
            calllib(ALIAS_PROXY, 'DGD128_Trigger');
        else
            fprintf('D128 Proxy Library not loaded.');
            fprintf('\topen command must be called first.\n');
        end
    end

    function Set(d128)
        if (libisloaded(ALIAS_PROXY))
            calllib(ALIAS_PROXY, 'DGD128_Set', ...
                int32(d128.mode), int32(d128.polarity), ...
                int32(d128.source), int32(d128.demand), ...
                int32(d128.pulsewidth), int32(d128.dwell), ...
                int32(d128.recovery), int32(d128.enabled));
        else
            fprintf('D128 Proxy Library not loaded.');
            fprintf('\topen command must be called first.\n');
        end
    end

    function d128 = GetState(d128)
        if (libisloaded(ALIAS_PROXY))
            mode = libpointer('int32Ptr', 0);
            pol = libpointer('int32Ptr', 0);
            source = libpointer('int32Ptr', 0);
            demand = libpointer('int32Ptr', 0);
            pw = libpointer('int32Ptr', 0);
            dwell = libpointer('int32Ptr', 0);
            recovery = libpointer('int32Ptr', 0);
            enabled = libpointer('int32Ptr', 0);
            calllib(ALIAS_PROXY, 'DGD128_Get', ...
                mode, pol, source, demand, pw, dwell, recovery, enabled);
            d128.mode = mode.value;
            d128.polarity = pol.value;
			d128.source = source.value;
            d128.demand = demand.value;
            d128.pulsewidth = pw.value;
            d128.dwell = dwell.value;
            d128.recovery = recovery.value;
            d128.enabled = enabled.value;
        else
            fprintf('D128 Proxy Library not loaded.');
            fprintf(' open command must be called first.\n');
        end
    end  
end