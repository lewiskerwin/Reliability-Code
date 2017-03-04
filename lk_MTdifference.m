
(ireg)

iTI = 10;
textsize = 16;
fwidth=10; fheight=8;
clear MTquantconcat

%Load MT
cd(cfg.stabilityresults); cd ..; cd Figures;
MTread = xlsread('Motor_Threshold');
MTmat = zeros(size(MTread));

%Organize MT
keep =1;
cnt = 1;
for irow = 1:size(MTread,1)
   %Overwrites prior row if not wanted
%     if keep==0
%        irow = irow-1;
%    else;end
   rowsub =num2str(MTread(irow,1));
   rowsub=rowsub(1:3);
    for isub=1:cfg.subnumber
        if  strcmp(rowsub,cfg.file.subs{isub})
            MTmat(cnt,1) = isub;
            MTmat(cnt,2:end) = MTread(irow,2:end);
           cnt=cnt+1;
            
            break;
        else;  end 
    end 
end
MTmat(cfg.subnumber+1:end,:)=[];
MTmat=MTmat(:,2:end);

figure('units','inches','Position', [1, 1, fwidth, fheight]);

width=3;
height=cfg.wndwnumber;

%START PLOTTING
for ifeature = 1:width 
    %Make Matrix of peak Quantification
        MTquant =squeeze(mean(data.(cfg.feature{ifeature}).MTcomp.mean(:,:,:,:,:),1));%day so as to get whole day
       %feature . wndw x dist x sub x day
        %NOW SUBTRACT Cond 1 from 2 and divide by average
        numerator = MTquant(:,1,:,:)-MTquant(:,2,:,:);
        denominator = mean(MTquant,2); 
        MTquantdiff = abs(squeeze(numerator./denominator));
        %wndw x sub x day
      
        
    for iwndw = 1:height
        MTquantconcat = reshape(MTquantdiff(iwndw,:,:),cfg.subnumber*cfg.daynumber,1); %Note day 1 and 2 are separated here
        %subday
        MTmatconcat = reshape(MTmat,[],1);
      
        subplot(height,width,(iwndw-1)*width+ifeature)
        plot(MTmatconcat,MTquantconcat,'O');
        hold on
        fitline = fit(MTmatconcat,MTquantconcat,'poly1');
        plot(fitline); legend('off');
        pearson = corr(MTquantconcat,MTmatconcat);
        ylim=get(gca,'ylim');
        xlim=get(gca,'xlim');
        text(xlim(1)+range(xlim)*.1,ylim(1)+range(ylim)*0.9,['Pearson Coeff: ' num2str(pearson)])
        hold off
        xlabel(''); xticklabels(''); 
        if ifeature == 1; ylabel([num2str(cfg.peak.target(iwndw)) '-ms Peak']); else ylabel(''); end
        
        set(gca,'FontSize',textsize,'FontWeight','bold','linewidth',0.5)
        
        switch iwndw
            case 1 %top
                if ifeature == 2 %middle
                    TITLE = 'Cond 1 vs 2 difference as a Function of Motor Threshold \n %s ';
                    title(sprintf(TITLE,cfg.featureaxislabel{ifeature}),'FontSize',12);
                else
                    TITLE = '%s';
                    title(sprintf(TITLE,cfg.featureaxislabel{ifeature}),'FontSize',12);
                end;
%             case 2
%                 YLABEL = '%s \n %s-ms Peak';
%                 ylabel(sprintf(YLABEL,cfg.featureaxislabel{ifeature},num2str(cfg.peak.target(iwndw))));
            case height %bottom
                xlabel('Motor Threshold'); xticklabels('auto');
                
            otherwise
        end
        
        
       
    end
end

Date = datestr(today('datetime'));
fname = [cfg.ProjectName '_FeatureDiff=F(MT)_based_on_first_' num2str(iTI*cfg.trialincr) '_trials' Date];
cd(cfg.stabilityresults);
ckSTIM_saveFig(fname,10,10,300,'',4,[fwidth fheight]);