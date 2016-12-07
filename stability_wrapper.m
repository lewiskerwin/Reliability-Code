%% WRAPPER FOR STABILITY CODE
% EDITED 10/22
% ---------------------------------
close all
[cfg] = spTMS_start();      % INITIALIZES ALL VALUES

% ---------------------------------
% INPUT VALUES FOR CODE
subs = {'105';'106'};excl = {'rTMS';'RTMS'};
% ---------------------------------

% FOR EACH SUBJECT FIND MATFILES AND LOAD THEM IN
cd(cfg.DrivePathData);cd('matfiles')
for n = 1:length(subs)
    % GRAB INDEX OF RELEVANT MATFILES FOR THIS SUBJECT
    tmp = dir('*.mat');filenames = cell(size(tmp,1),1);
    clear fNames idx
    for i = 1:size(tmp,1);
        fNames{i,1} = tmp(i).name(1:end-4);
        if ~isempty(strfind(fNames{i,1},subs{1})) % & isempty(strfind(fNames{i,1},excl{1})) & isempty(strfind(fNames{i,1},excl{2}))
            idx(i) = 1;
        else
            idx(i) = 0;
        end
    end;idx = find(idx);
    
    % LOAD RELEVANT MATFILES IN
    cnt = 1;clear data
    for i = idx
        dat = load(fNames{idx(i),1});
        data(cnt).EEG = dat.EEG;
        data(cnt).condName = fNames{idx(i),1};
        cnt = cnt + 1;clear dat
        disp(['Loading matfile:' fNames{idx(i),1} '...'])
    end
    
    % CHANNELS FOR ROI ANALYSIS
    cfg.regs = [];
    cfg.regs(1).name = 'Left DLPFC';cfg.regs(1).chan = [17 18 29 30];
    cfg.regs(2).name = 'Right DLPFC';cfg.regs(2).chan = [8 9 20 21];
    cfg.regs(3).name = 'Left Parietal';cfg.regs(3).chan = [26 27];
    cfg.regs(4).name = 'Right Parietal';cfg.regs(4).chan = [23 24];
    cfg.regs(5).name = 'Occipital';cfg.regs(5).chan = [49 50 51];
    cfg.regs(6).name = 'Central';cfg.regs(6).chan = 1:7;
    
    stability(cfg,data)
end

