%% WRAPPER FOR STABILITY CODE
% EDITED 11/03
% ---------------------------------
close all
[cfg] = spTMS_start();      % INITIALIZES ALL VALUES

% ---------------------------------
% INPUT VALUES FOR CODE
subs = {'105';'106'};excl = {'rTMS';'RTMS'}; conds = {'_1_';'_2_'};%'final';'washout'};
cond_include = {'fromConcat_post'}; cond_exclude = {'arm';'PostRTMS'};
% ---------------------------------

%%
%So I call on load data using the inclusion and exclusion criteria
data = lk_loaddata(cfg,subs,conds,cond_include,cond_exclude);

        
%%
%Now extract AUCs from data of each cell in data and break it into array of
%Dimensions: (electrode, timeframe, trial- the same order of dimensions in
%raw data)
wndw = [0 50;50 100;100 150;180 220];
wndwNames = {'0-50';'50-100';'100-150';'180-220'};

data = lk_simpleAUC(data, wndw, wndwNames);
%NOTE: all the code below is now in the function lk_simpleAUC
% %Note: EEG.data is 3 dimensional array with dimensions
% %1:electrodes (64) 2:milliseconds (1500) 3:trials (~150)
% for isubs = 1:length(subs)% Go through each subject
%     for iconds = 1:length(conds)%Go through each condition
%         
%         for ielec = 1:size(data(isubs,iconds).EEG.data,1)%each electrode
%             for iwndw = 1:size(wndw,1)% each time window 
%                 for itrial = 1:size(data(isubs,iconds).EEG.data,3)% each trial
%                     
%                     TEPtimes = data(isubs,iconds).EEG.times; %Name array for the TEP times from raw data
%                     datatimes = find( TEPtimes >= wndw(iwndw,1) & TEPtimes <= wndw(iwndw,2)); %Make array of idx of desired times
%                     tmp = trapz(datatimes,data(isubs,iconds).EEG.data(ielec,datatimes,itrial)); %Intgrate data at that index
%                     data(isubs,iconds).EEG.AUC(ielec,iwndw,itrial) = tmp; %Name 'AUC' in data and equate it to the integral above
%                     data(isubs,iconds).EEG.AUCdim1 = 'electrode';
%                     data(isubs,iconds).EEG.AUCdim2 = 'window';
%                     data(isubs,iconds).EEG.AUCdim3 = 'trial';
%                 end
%             end
%         end
%         
%     end
% end

%%
%So lets find out how we'll bin up the AUCs
 % CHANNELS FOR ROI ANALYSIS
    cfg.regs = [];
    cfg.regs(1).name = 'Left DLPFC';cfg.regs(1).chan = [17 18 29 30];
    cfg.regs(2).name = 'Right DLPFC';cfg.regs(2).chan = [8 9 20 21];
    cfg.regs(3).name = 'Left Parietal';cfg.regs(3).chan = [26 27];
    cfg.regs(4).name = 'Right Parietal';cfg.regs(4).chan = [23 24];
    cfg.regs(5).name = 'Occipital';cfg.regs(5).chan = [49 50 51];
    cfg.regs(6).name = 'Central';cfg.regs(6).chan = 1:7;
  

%%
%Now that we have AUCs, let's get an AUC array made up of the desired
%dimensions
  %Number of bins of trials
    numsplit = 2;

reliability = lk_binAUC(data,cfg,numsplit,wndw,subs,conds)

clear tobin reliability

for isubs = 1:length(subs)% Go through each subject
    for iconds = 1:length(conds)%Go through each condition
        
        for ireg = 1:length(cfg.regs)
            for iwndw = 1:size(wndw,1)% each time window
                splitlength = floor(size(data(isubs,iconds).EEG.data,3)/numsplit);
                for isplit = 1:numsplit %Go through each split
                    
                    tobin = data(isubs,iconds).EEG.AUC(cfg.regs(ireg).chan,iwndw,1+(isplit-1)*splitlength:isplit*splitlength);
                    reliability.AUC(isubs,iconds,ireg,iwndw,isplit) = mean(mean(tobin));
                   
                end
            end
        end
        
    end
end
%Label the dimensions of AUC
reliability.AUCdim{1} = 'subject';
reliability.AUCdim{2} = 'condition';
reliability.AUCdim{3} = 'region';
reliability.AUCdim{4} = 'window';
reliability.AUCdim{5} = 'split';



%%
%PEARSON TIME
%start with split 1 vs 2
for iwndw=1:length(wndw) %Look at one window
  
    
    for ireg=1:length(cfg.regs)
        for jreg=1:length(cfg.regs)
            x = reshape(reliability.AUC(:,:,ireg,iwndw,1),[4 1]);
            y = reshape(reliability.AUC(:,:,ireg,iwndw,2),[4 1]);
            reliability.pearson(ireg,jreg,iwndw,1) = (corr(x,y);
        end
    end
    
end


%%
%Now find variance based across dimensions of interest, looking at one
%window and region at a time

for ireg = 1:size(reliability.AUC,3)
    for iwndw = 1:size(reliability.AUC,4)
        clear miniAUC tdAUC
        
        miniAUC = squeeze(reliability.AUC(:,:,ireg,iwndw,:)); %Let's look only at non-one dimensions: subject, condition and split
        
        cnt =1;
        for isub=1:size(miniAUC,1)
            for iconds=1:size(miniAUC,2)
                for isplit=1:size(miniAUC,3)
                    
                    tdAUC(1,cnt) = miniAUC(isub,iconds,isplit); %This populates a two-dimensional table so that we can feed into ANOVA
                    tdAUC(2,cnt) = isub; tdAUC(3,cnt) = iconds; tdAUC(4,cnt)=isplit;
                    cnt = cnt +1;
                end
            end
        end
        
        %Now run ANOVA
        [p,tbl,stats]= anovan(tdAUC(1,:),{tdAUC(2,:),tdAUC(3,:),tdAUC(4,:)},'varnames',{'Sub','Cond','Split'},'display','off');
        
        %Extract a matrix of variances from the anova
        for idim=1:ndims(miniAUC)+1;
            var(idim) = cell2mat(tbl(idim+1,5));
            reliability.VAR(ireg,iwndw,idim) = var(idim);
        end
        %Then Calculate SEM, SDC and ICC!
        for idim=1:ndims(miniAUC);
            reliability.SEM(ireg,iwndw,idim) = (var(idim)+var(ndims(miniAUC)+1))^0.5;
            reliability.SDC(ireg,iwndw,idim) = reliability.SEM(ireg,iwndw,idim) * 2^0.5 * 1.96;
            reliability.ICC(ireg,iwndw,idim) = var(idim)/sum(var(idim:length(var)));
            
            disp([ 'In the ' cfg.regs(ireg).name ' region and window ' wndwNames{iwndw} ' the SEM across ' tbl{idim+1,1}  ' is ' num2str(reliability.SEM(ireg,iwndw,idim))]);
            disp([ 'In the ' cfg.regs(ireg).name ' region and window ' wndwNames{iwndw} ' the ICC across ' tbl{idim+1,1} ' is ' num2str(reliability.ICC(ireg,iwndw,idim))]);

        end

      
        
        
        
        
%         %Below is algorithm that uses function 'var' but I'm not sure I
%         %know what I'm doing with variance well enough to use it
%         for idim=1:3
%            reliability.stats(ireg,iwndw).variance(idim) = var(squeeze(mean(mean(miniAUC)))) %In this case variance of the average is better than vice versa: squeeze(mean(mean(var(miniAUC))))
%             %Or maybe I should just get sum of squares... good ol' ANOVA
%            
%             miniAUC = permute(miniAUC, [3 2 1]);
%             
%         end
%         
%         for idim=1:3
%             reliability.stats(ireg,iwndw).ICC(idim) = reliability.stats(ireg,iwndw).variance(idim)/ sum(reliability.stats(ireg,iwndw).variance(:));
%             disp(['The ICC of region ' num2str(ireg) ', window ' num2str(iwndw) ', across dimension ' num2str(idim) ' is ' num2str(reliability.stats(ireg,iwndw).ICC(idim))]); 
%         end
%         
        
% BElow is an alternative way, using BOOIL's excel as model        
%         for idim=1:3
%             tdAUC = reshape(miniAUC,size(miniAUC,1),[]) %separate everything by dimension of interest
                
%             reliability.stats(ireg,iwndw).variance(idim) = var(tdAUC,0,2); %Measure variance along this dimension
%             
%             
%             miniAUC = permute(miniAUC,[2 3 1])%now shift the dimensions so we can find variance along 
%             
%             
%             
%             2DAUC( =
%             reliability.stats(ireg,iwndw).variance.subs = var(mean(mean(reliability.AUC(:,:,ireg,iwndw,:),2),5)); %Average across conditions
%             reliability.stats(ireg,iwndw).variance.condition = var(mean(mean(reliability.AUC(:,:,ireg,iwndw,:),1),5));
%         end
        
    end
end

%%
%Now to present the findings...
reliability.dims = {'subject' 'condition' 'split'}

%Define common axes for different comparisons
for idim=1:length(reliability.dims)

MIN(1,idim) = min(min(reliability.ICC(idim)))
MAX(1,idim) = max(max(reliability.ICC(idim)))

MIN(2,idim) = min(min(reliability.SDC(idim)))
MAX(2,idim) = max(max(reliability.SDC(idim)))
end

clear yname
for ireg=1:length(cfg.regs)
   
    yname{ireg} = cfg.regs(ireg).name
    
end


figure
for subploti=1:length(reliability.dims)
    %Plot ICC
    subplot(2,3,subploti)
    C = reliability.ICC(:,:,subploti);
    imagesc(C, 'CDataMapping','scaled')
    colorbar
    colormap hot
    title (['ICC across various ' reliability.dims{subploti} 's'])
    set(gca,'YTickLabel', yname);
    set(gca,'XTick',1:4,'XTickLabel', wndwNames);
   
    %Plot SEM
    subplot(2,3,subploti+3)
    C = reliability.SDC(:,:,subploti);
    imagesc(C, 'CDataMapping','scaled')
    colorbar
    title (['Smallest detectable change between two ' reliability.dims{subploti} 's'])
    caxis manual
    caxis([min(MIN(2,:)) max(MAX(2,:))]);
    set(gca,'YTickLabel', yname);
    set(gca,'XTick',1:4,'XTickLabel', wndwNames);
   
    
end

%%
%QUALITY CONTROL CODE
%Here I compare AUC calculations to raw data...looks fine
 mean(reliability.AUC(:,:,3,3,:),5)

%This should take data for literally ALL conditions and subjects
    %specificed at the top of wrapper
    %getauc(cfg,data) -THIS IS THE NEXT PART TO WORK ON: Take the data in
    %each cell within data and parcel up by 1)split 2)TEP component, then average across each of these and fill an array 
