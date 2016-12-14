function data = lk_loaddata(cfg)
% THIS LOOP LOADS RELEVANT MAT FILES INTO the STRUCTURE 'DATA'
cd(cfg.DrivePathData);cd('matfiles')%We're looking at Matfiles
clear data idx fNames  include 
clear reliability
tmp = dir('*.mat'); %tmp is a structure that contains all these names
fNames = cell(size(tmp,1),1); %fNames is an array of cells of same size as tmp
cnt = 1;%counts number of mat files loaded. Unsure if necessary

for i = 1:size(tmp,1);%Go through each file in folder that ends in mat
    fNames{i,1} = tmp(i).name(1:end-4);%Adds file to list of names (w/o '.mat')
    
    %%
    %Inclusion Criteria
    for icondinclude = 1:size(cfg.file.precond_include,1) %go through each inclusion criteria
        if isempty(strfind(fNames{i,1},cfg.file.precond_include{icondinclude}))%Does file have this inclusion criteria
            idx(i) = 0;
            break
        else idx(i) = 1;
        end
    end
    if ~idx(i),continue,end
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
        if idx(i)==1;break; else; end  
            
    end
    if ~idx(i),continue,end

    %%
    %Actually load data if we've made it this far
    data(isub,icond) = load(fNames{i,1});%Load data
    data(isub,icond).EEG.condition = cfg.file.preconds{icond};%save cond name
    data(isub,icond).EEG.conditionidx = icond;%Save cond idx MAY BE UNECESSARY IF DATA is 2D
    data(isub,icond).EEG.subject = cfg.file.subs{isub};%save sub name
    data(isub,icond).EEG.subjectidx = isub; %save sub idx MAY BE UNECESSARY IF DATA is 2D
    disp(['Loading matfile for sub ' cfg.file.subs{isub} ' condition ' cfg.file.preconds{icond}  '...']);
    %Now Load and label each data file...
    data(isub,icond).EEG.baseline_variance=nanmean(nanmean(var(data(isub,icond).EEG.data,1)));
    cnt = cnt + 1;
    

end
idx = find(idx);
end