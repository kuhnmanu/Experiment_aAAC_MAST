% Simple example program to demonstrate control of D128

% open device and return handle for further calss
[success, d128] = D128ctrl('open');

% Download status from device
[success, d128] = D128ctrl('status', d128);

[success, d128] = D128ctrl('enable', d128, 0);

% Set value of pulsewidth, but does not upload to device
[success, d128] = D128ctrl('source', d128, 'Internal');
[success, d128] = D128ctrl('pulsewidth', d128, 1000);
[success, d128] = D128ctrl('demand', d128, 60);
[success, d128] = D128ctrl('dwell', d128, 400);

% Uploads all parameters to device
success = D128ctrl('upload', d128);

[success, d128] = D128ctrl('enable', d128, 1);

% trigger the device
success = D128ctrl('Trigger', d128);

% Download status from device
[success, d128] = D128ctrl('status', d128);
d128

% Close device
success = D128ctrl('close', d128);



