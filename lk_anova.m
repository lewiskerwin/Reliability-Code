
function [anovadata, stats] = lk_anova(data,cfg)

iTI = floor(cfg.trialnumber/cfg.trialincr);
cfg.trialmax = iTI * cfg.trialincr;
splitlength=cfg.trialmax/cfg.numsplit;
cnt=1;
cfg.anovagroup = {'Subject','Day','Condition','Split'};

for iday = 1:cfg.daynumber
    for icond = 1:cfg.condnumber
        for isplit= 1:cfg.numsplit
            %startingrow = ...
             %   (iday-1)*cfg.condnumber*cfg.trialnumber + ...
              %  (icond-1)*cfg.trialnumber + ...
               % (isplit-1)*splitlength;
            %anovatrialkey(startingrow+1:startingrow+splitlength,1) = splitrange + startingrow;
            %anovatrialkey(startingrow+1:startingrow+splitlength,2) = iday;
            %anovatrialkey(startingrow+1:startingrow+splitlength,3) = icond;
            %anovatrialkey(startingrow+1:startingrow+splitlength,4) = isplit;
            
            
            anovagroups_nosub(cnt,:) = [iday, icond, isplit];
            
            %AVERAGE TOGETHER DATA FOR THIS BLOCK
            anovadata(:,:,cnt,:) = mean(data.amp(:,:,(1:splitlength) + (isplit-1)*splitlength,icond,iday,:),3);
            %elec x time x block x sub
            
            

            cnt=cnt+1;
        end
    end
end

%QUANITFY PEAKS
[anovapeaks] = lk_findwndw_sortfirst(anovadata,cfg); 
%feature . reg x wndw x block x sub

%RESHAPE DATA SO SUBJECT IS ONE MORE GROUP
dimensions = size(anovapeaks.amplat);
for ifeature = 1:size(cfg.feature,2)
    anovapeaks_r(ifeature,:,:,:) = ...
        reshape(anovapeaks.(cfg.feature{ifeature}),[dimensions(1),dimensions(2),dimensions(3)*dimensions(4)]);
    %feature x reg x wndw x block(now including subs)
end

%ADD SUBJECT AS A ROW TO GROUPS MATRIX
dimensions = size(anovagroups_nosub);
for isub = 1:cfg.subnumber
   blockrange = (1:dimensions(1)) +(isub-1)*dimensions(1);
    anovagroups(blockrange,1+(1:dimensions(2))) = anovagroups_nosub;
    anovagroups(blockrange,1) = isub;
    % rows are blocks; columns are categories (sub, day, cond, split)
end

%RUN ANOVA 
for ifeature = 1:size(cfg.feature,2)
    for ireg = 1:cfg.regnumber
        for iwndw = 1:cfg.wndwnumber
            [p, tbl] = anovan(anovapeaks_r(ifeature,ireg,iwndw,:),anovagroups,...
                'varnames',cfg.anovagroup,...
                'display','off'); %'nested' is an  option, but not relevant here because even split spans many days and subs
            
            stats.(cfg.feature{ifeature}).anova.F(ireg,iwndw,1:length(cfg.anovagroup))...
                = ([tbl{2:length(cfg.anovagroup)+1,6}])';
            stats.(cfg.feature{ifeature}).anova.P(ireg,iwndw,1:length(cfg.anovagroup))...
                = ([tbl{2:length(cfg.anovagroup)+1,7}])';
            
        end
    end
end

%PLOT ANOVA
figure('Position', [100, 100, 600, 1200])
for iwndw =1:cfg.wndwnumber
    
    datatoplot = squeeze(stats.(cfg.feature{ifeature}).anova.F(:,iwndw,:));
    subplot(cfg.wndwnumber,1,iwndw)
     boxplot(datatoplot)
     switch iwndw
         case 1
             TITLE = 'Sources of Variance of %s \n %d-ms'; 
             title(sprintf(TITLE,cfg.featurelabel{ifeature},cfg.peak.target(iwndw)));
             xticklabels('')
         case cfg.wndwnumber   
            xlabel('Variable','fontweight','Bold'); xticklabels(cfg.anovagroup); set(gca,'fontweight','bold');
            TITLE ='%d-ms';
            title(sprintf(TITLE,cfg.peak.target(iwndw)));
         otherwise
            TITLE ='%d-ms';
            title(sprintf(TITLE,cfg.peak.target(iwndw)));
            xticklabels('')
     end
     ylabel('F-Value','fontweight','normal','rot',90);
     %ADD HORIZONTAL LINE FOR WEHRE P VALUE IS! There's a matlab function
     %for this
end

end

