function lk_plotregbystat(stats,cfg,ifeature,icomparison)

%PLOT EFFECT OF INCREASING TRIAL NUMBER ON CCC
figure('Position', [100, 100, 1450, 1200])

%DEFINE PARTS OF STRUCTURE TO PLOT
%fieldnames(reliability); - can use this for higher versatility
fctoplot = [cfg.feature{ifeature} cfg.comparison{icomparison}];
stattoplot(:)= {'CCC','pearson','ICC'};
statlabel(:) = {'Concordance Correlation Coefficient', 'Pearson Coefficient', 'Intraclass Correlation Coefficient'}';
featurelabel(:) = {'Peak Latency', 'Peak Amplitude', 'Area Under Curve (Centered Window)', 'Area Under Curve (Standard Window)'};
width=length(stattoplot);

colorstring = 'kmcrgb';
Legend= 0;
timetoplot = (cfg.trialincr:cfg.trialincr:cfg.trialnumber)';


for istat = 1:width
    
datatoplot_allreg = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(stattoplot{istat}).mean;
errortoplot_allreg = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(stattoplot{istat}).sem;

for iwndw=1:size(cfg.peak.target,2)
    subplot(size(cfg.peak.target,2),width,(iwndw-1)*width+istat)
    
    hold on
    for ireg = 1:cfg.regnumber
        datatoplot = squeeze(datatoplot_allreg(ireg,iwndw,:));
        errortoplot = squeeze(errortoplot_allreg(ireg,iwndw,:));
        %line = plot(timetoplot,datatoplot,'-o');
        %ALTERNATIVE LINE IF WE WANNA SEE ERROR
        line(ireg) = shadedErrorBar(timetoplot,datatoplot,errortoplot,{['-o' colorstring(ireg)],'markerfacecolor',colorstring(ireg)},1);
    end
    if istat<5; plot([0 cfg.trialnumber],[0.90 0.90],'-.','color','k'); else; end;
    
    hold off
    
    %Add "odd vs even" only on top row of graphs
    if iwndw==1
        %Top middle gets special AUC vs LAT
        if istat == (floor(width/2)+1)
            TITLE = '%s in %s \n %s';
            title(sprintf(TITLE,featurelabel{ifeature},cfg.comparisonlabel{icomparison},statlabel{istat}));
        else
            TITLE = '%s';
            title(sprintf(TITLE,statlabel{istat}));
        end
    else
        

    end
   
        
    if strcmp(stattoplot{istat}, 'SDC') axis( [0 cfg.trialnumber 0 200]);
    else axis( [0 cfg.trialnumber 0 1]);
    end
    
    if iwndw==cfg.wndwnumber
        xlabel('Trial Number'); %ylabel(statlabel{istat});
    else
        xticklabels('off');
    end
    
     if istat==1
        ylabel([num2str(cfg.peak.target(iwndw)) '-ms Peak'],'FontWeight','bold','Rotation',90); %ylabel(statlabel{istat});
    else
    end
    
    box off; grid on;

    
    
end

end
% subplot(4,3,8);
% plotposa = get(gca,'Position');
% subplot(4,3,11);%go to middle bottom
% plotposb = get(gca,'Position');
% hL = legend([line.mainLine],cfg.regs(:).name,'Orientation','Vertical','box','off');
% onebelow = plotposb(2)-(plotposa(2)-plotposb(2));
% legpos = [plotposb(1) onebelow+0.05 0.2 0.2];

subplot(height,width,width);
plotposr = get(gca,'Position');
subplot(height,width,width-1);
plotposl = get(gca,'Position');
hL = legend([line.mainLine],cfg.regs(:).name,'Orientation','Vertical','box','off');
oneover = plotposr(1)+(plotposr(1)-plotposl(1))/2;
legpos = [oneover plotposr(2) 0.2 0.2];
set(hL,'Position', legpos,'box','off');

Date = datestr(today('datetime'));
fname = [cfg.ProjectName '_' cfg.feature{ifeature} '_' cfg.comparison{icomparison} '_' [stattoplot{:}] '_' Date];
cd(cfg.stabilityresults);
ckSTIM_saveFig(fname,10,10,300,'',4,[10 8]);

end