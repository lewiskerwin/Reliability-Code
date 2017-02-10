function [tempdata, cfg] = lk_loaddata(cfg)
% THIS LOOP LOADS RELEVANT MAT FILES INTO the STRUCTURE 'DATA'
cd(cfg.DrivePathData); 
% if cfg.ProjectName == 'vlpfc_TBS'    cd('matfiles');cd('For_Lewis');
% else  cd('matfiles');%We're looking at Matfiles
% end
clear tempdata idx fNames  include 
tmp = dir('*.mat'); %tmp is a structure that contains all these names
fNames = cell(size(tmp,1),1); %fNames is an array of cells of same size as tmp
cnt = 1;%counts number of mat files loaded. Unsure if necessary
cfg.trialnumber =150;


for i = 1:size(tmp,1);%Go through each file in folder that ends in mat
    fNames{i,1} = tmp(i).name(1:end-4);%Adds file to list of names (w/o '.mat')
    
    %%
    %Inclusion Criteria
    if ~isempty(cfg.file.precond_include)
        for icondinclude = 1:size(cfg.file.precond_include,1) %go through each inclusion criteria
            if isempty(strfind(fNames{i,1},cfg.file.precond_include{icondinclude}))%Does file have this inclusion criteria
                idx(i) = 0;
                break
            else idx(i) = 1;
            end
        end
        if ~idx(i),continue,end
    else
    end
    %%
    %Exclusion Criteria
    for iexclude=1:length(cfg.file.precond_exclude)%Now go through exclusion criteria
        if ~isempty(strfind(fNames{i,1},cfg.file.precond_exclude{iexclude}))%Narrow list by excluding strings
            idx(i)=0; %Don't load file if it has this exclusion criteria
            break
        else idx(i) =1;
        end
    end
    if ~idx(i),continue,end
    
    %%
    %Make sure file contains one of the desired subs
    for isub = 1:length(cfg.file.subs)% Go through each relevant subject
        if ~isempty(strfind(fNames{i,1},cfg.file.subs{isub}))
            idx(i) =1;
            break
        else idx(i) = 0;
        end
    end
    if ~idx(i),continue,end
    
    %%
    %Make sure file contains one of desired conditions
    for icond=1:length(cfg.file.preconds)% Go through each relevant condition
        for iprefix = 1:size(cfg.file.precondprefix,1)
            if ~isempty(strfind(fNames{i,1},[cfg.file.precondprefix{iprefix,1} cfg.file.preconds{icond} cfg.file.precondprefix{iprefix,2}]))
                idx(i)=1; break
            else idx(i) =0;
            end
        end
        if idx(i);break; else; end  
            
    end
    if ~idx(i),continue,end

    %%
    %Actually load data if we've made it this far
    tempdata(isub,icond) = load(fNames{i,1});%Load tempdata
    tempdata(isub,icond).EEG.condition = cfg.file.preconds{icond};%save cond name
    tempdata(isub,icond).EEG.conditionidx = icond;%Save cond idx MAY BE UNECESSARY IF DATA is 2D
    tempdata(isub,icond).EEG.subject = cfg.file.subs{isub};%save sub name
    tempdata(isub,icond).EEG.subjectidx = isub; %save sub idx MAY BE UNECESSARY IF DATA is 2D
    disp(['Loading matfile for sub ' cfg.file.subs{isub} ' condition ' cfg.file.preconds{icond}  '...']);
    %Now Load and label each data file...
    tempdata(isub,icond).EEG.baseline_variance=nanmean(nanmean(var(tempdata(isub,icond).EEG.data,1)));
    
    if cfg.trialnumber > size(tempdata(isub,icond).EEG.data,3)
    cfg.trialnumber = size(tempdata(isub,icond).EEG.data,3);
    end
    
    cnt = cnt + 1;
    

end
idx = find(idx);
cfg.trialnumber = floor(cfg.trialnumber/cfg.trialincr)*cfg.trialincr;
cfg.condnumber= size(tempdata,2);
cfg.subnumber= size(tempdata,1);
cfg.tpnumber= 1;

end