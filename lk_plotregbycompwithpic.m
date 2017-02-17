function lk_plotregbycomp(stats,cfg,ifeature,istat)


%PLOT EFFECT OF INCREASING TRIAL NUMBER ON CCC
figure('Position', [100, 100, 1450, 1200])

%DEFINE PARTS OF STRUCTURE TO PLOT
%fieldnames(reliability); - can use this for higher versatility
fctoplot = [cfg.feature{ifeature}];
%stattoplot(:)= {'CCC','pearson','ICC'};
%statlabel(:) = {'Concordance Correlation Coefficient', 'Pearson Coefficient', 'Intraclass Correlation Coefficient'}';
featurelabel(:) = {'Peak Latency', 'Peak Amplitude', 'Area Under Curve (Centered Window)', 'Area Under Curve (Standard Window)'};
width= size(cfg.comparison,2);

colorstring = 'kmcrgb';
Legend= 0;
timetoplot = (cfg.trialincr:cfg.trialincr:cfg.trialnumber)';


for icomparison = 1:cfg.compnumber
    
    comparisonlabeled =0;
    datatoplot_allreg = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).mean;
    errortoplot_allreg = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).sem;
    
    %LOAD IMAGE OF COMP
    cd(cfg.stabilityresults); cd ..; cd Figures;
    compimage = imread(['comp' num2str(icomparison) '.png']);
    subplot(size(cfg.peak.target,2)+1,width,icomparison)
    imshow(compimage);
    if icomparison == 3
            TITLE = '%s of %s \n \n %s';
           % titlebox = text(0,1450,sprintf(TITLE,cfg.stat{istat},featurelabel{ifeature}),'FontSize',12);
            title(sprintf(TITLE,cfg.stat{istat},featurelabel{ifeature},cfg.comparisonlabel{icomparison}),'FontSize',12);
    else
        TITLE = '%s';
         % titlebox = text(0,1450,sprintf(TITLE,cfg.stat{istat},featurelabel{ifeature}),'FontSize',12);
        title(sprintf(TITLE,cfg.comparisonlabel{icomparison}),'FontSize',12);
    end;
    

for iwndw=1:size(cfg.peak.target,2)
    subplot(size(cfg.peak.target,2)+1,width,(iwndw)*width+icomparison)
    
    hold on
    for ireg = 1:cfg.regnumber
        datatoplot = squeeze(datatoplot_allreg(ireg,iwndw,:));
        errortoplot = squeeze(errortoplot_allreg(ireg,iwndw,:));
        %line = plot(timetoplot,datatoplot,'-o');
        %ALTERNATIVE LINE IF WE WANNA SEE ERROR
        line(ireg) = shadedErrorBar(timetoplot,datatoplot,errortoplot,{['-o' colorstring(ireg)],'markerfacecolor',colorstring(ireg)},1);
        
    end
    if istat<5; plot([0 cfg.trialnumber],[0.80 0.80],'-.','color','k'); else; end;
    hold off
   
    if iwndw==cfg.wndwnumber
        xlabel('Trial Number'); %ylabel(statlabel{istat});
    else
    end
    
     if icomparison==1
        ylabel([cfg.peak.wndwnames{iwndw} '-ms Peak'],'FontWeight','bold','Rotation',90); %ylabel(statlabel{istat});
    else
    end
    
    if strcmp(cfg.stat{istat}, 'SDC') axis( [0 cfg.trialnumber 0 200]);
    else axis( [0 cfg.trialnumber 0 1]);
    end
    box off; grid on;

    
    
end

end

middlepenultimate = ((cfg.wndwnumber-2)+1)*cfg.compnumber+floor((cfg.compnumber+1)/2);
subplot(cfg.wndwnumber+1,cfg.compnumber,middlepenultimate);
plotposa = get(gca,'Position');
middlebottom = ((cfg.wndwnumber-1)+1)*cfg.compnumber+floor((cfg.compnumber+1)/2);
subplot(cfg.wndwnumber+1,cfg.compnumber,middlebottom);
plotposb = get(gca,'Position');
hL = legend([line.mainLine],cfg.regs(:).name,'Orientation','horizontal','box','off');
onebelow = plotposb(2)-(plotposa(2)-plotposb(2));
legpos = [plotposb(1) onebelow+0.01 0.2 0.2];
        set(hL,'Position', legpos,'box','off');

Date = datestr(today('datetime'));
fname = [cfg.ProjectName '_' cfg.feature{ifeature} '_' cfg.stat{istat} '_' [cfg.comparison{:}] '_' Date];
cd(cfg.stabilityresults);
ckSTIM_saveFig(fname,10,10,300,'',4,[10 8]);
end