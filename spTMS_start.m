function [cfg] = spTMS_start()
% LOCATE LOCAL AND GOOGLE DRIVE FOLDERS AND SET PATH OF ALL TMS-EEG TOOLBOXES
% [cfg] = spTMS_start()
% UPDATED 9/30/2016

clc;warning('OFF', 'all');
set(0, 'DefaultUICOntrolFontSize', 14)
  
% SPECIFY THE LOCAL DRIVE FOR TMS-EEG DATA
clc,disp(sprintf('Select (or make and then select) the local folder for TMS-EEG data \n (one step back from project folder)'));
[cfg.localFilePath] = uigetdir('','Select (or make and then select) the local folder for TMS-EEG data (one step back from project folder)');
% FIND ALL PROJECTS IN DIRECTORY TO LIST PROJECTS NEXT
d = dir(cfg.localFilePath);isub = [d(:).isdir];listProjects = {d(isub).name}';listProjects(1:2) = [];
    
% SPECIFY PROJECT NAME
clc,disp(sprintf('Pick the project you are working on'));
[tm] = listdlg('PromptString','Pick the project you are working on','ListString',listProjects,'selectionmode','multiple','ListSize',[250 150]);
cfg.ProjectName = listProjects{tm};

% SPECIFY GDRIVE FOLDER WITH SCRIPTS AND ADD TO PATH
clc,disp(sprintf('Pick the gdrive folder  \n called TMS-EEG-pipelineScripts'));
[cfg.DrivePathScripts] = uigetdir('','Pick the gdrive folder called TMS-EEG-pipelineScripts');

% SPECIFY GDRIVE FOLDER WITH DATA
clc,disp(sprintf('Pick the gdrive folder in TMS-EEG-Pipeline that has your data  \n (make sure there are folders called QC, matfiles, ICA,  \n and results within that folder)'));
[cfg.DrivePathData] = uigetdir('','Pick the gdrive folder in TMS-EEG-Pipeline that has your data (make sure there are folders called QC, matfiles, ICA, and results within that folder)');
% [cfg.DrivePathData] = uigetdir('','Pick the gdrive folder called TMS-EEG-Pipeline');

% ALSO SET ALLRESULTS FOLDER
clc,disp(sprintf('Pick the gdrive subfolder in TMS-EEG-Pipeline \n within AllResults (typically located in \n TMS-EEG-Pipeline/InputFiles/AllResults/). \n Need to be inside the project folder \n within AllResults when you click select)  \n Example is within rTMS within AllResults folder '));
[cfg.DrivePathAllResults] = uigetdir('','Pick the gdrive folder in TMS-EEG-Pipeline called AllResults (typically located in TMS-EEG-Pipeline/InputFiles/AllResults/');

% Check Whether pre or post-processing. If Pre, then specify local drive.
TypeAnalysis = questdlg('Are you running ARTIST or Post-Processing?', ...
    '','ARTIST','Post-Procesing','Post-Procesing');if strcmp(TypeAnalysis,'ARTIST');FTbottom = 1;else FTbottom = 0;end

% % IF YOU WANT ARTIST TO RUN THROUGH AND ASK ABOUT WHICH FILES TO
% % CONCATENATE
% tmp = questdlg('Do you have spTMS conditions to concatenate in ARTIST (ICA) for this project?', ...
%     '','Yes','No','Yes');if strcmp(tmp,'Yes');cfg.isConcat = 1;else cfg.isConcat = 0;end

if strcmp(TypeAnalysis,'ARTIST')
    cfg.InputEEGFileDir = [cfg.localFilePath '/' cfg.ProjectName '/'];
else
    cfg.InputEEGFileDir = [];
end

% CREATE FOLDER NAMES GOING INTO ARTIST
cfg.gDriveMatfileDir = [cfg.DrivePathData '/matfiles'];
cfg.scriptsDir   = [cfg.DrivePathScripts '/toolboxes/activeScripts'];
cfg.outputDir    = cfg.gDriveMatfileDir;

% KEEP THESE AS IS
cfg.satamp       = 3280; % microvolt; saturation amplitude for single trial-single channel rejection
cfg.ponset       = 500;
cfg.maxlatency   = 1000;
cfg.plotICA      = 0;       % IF ZERO, WILL AUTOMATICALLY PLOT LAST ICA RUN. IF YOU WANT ALL OF THEM, MAKE THIS 1
cfg.clean        = 1;       % IF YOU WANT NOTCH REMOVAL, MAKE THIS 1
cfg.downsample   = 1000;    % HOW MUCH TO DOWNSAMPLE

% ADD ARTIST SCRIPT FOLDERS
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'configurationTemplates']),'-END');
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'ICAautoRejScripts']),'-END');
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'automatedartrejectionscript']),'-END');

% ADD TOOLBOXES
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'brainstorm3_tms-eeg']),'-END');
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'eeglab13_3_2b']),'-END');

% CHECK WHICH MATLAB VERSION
tmp = questdlg('Which matlab do you have?', ...
    '','2015b or later','Earlier than 2015b','Earlier than 2015b');if strcmp(tmp,'2016');matlabVersion2016 = 1;else matlabVersion2016 = 0;end


% NOW ADD FIELDTRIP
if FTbottom==1
    if matlabVersion2016==1
        addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'fieldtrip-20160406']),'-END');
    else
        addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'fieldtrip-20141231']),'-END');
    end
else
    if matlabVersion2016==1
        addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'fieldtrip-20160406']));
    else
        addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'fieldtrip-20141231']));
    end
end
addpath(genpath([cfg.DrivePathScripts '/pipelineScripts/']), '-END');
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'activeScripts']),'-END');
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'cleanline']),'-END')
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'BCILAB-1.1']),'-END');
addpath(genpath([cfg.DrivePathScripts '/toolboxes/' 'bvaio1_57']),'-END');
