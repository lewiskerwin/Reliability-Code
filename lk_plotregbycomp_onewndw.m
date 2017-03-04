function lk_plotregbycomp_onewndw(stats,cfg,ifeature,istat,iwndw)


%PLOT EFFECT OF INCREASING TRIAL NUMBER ON CCC
figure('Position', [100, 100, 1450, 1200])

%DEFINE PARTS OF STRUCTURE TO PLOT
%fieldnames(reliability); - can use this for higher versatility
fctoplot = [cfg.feature{ifeature}];
%stattoplot(:)= {'CCC','pearson','ICC'};
%statlabel(:) = {'Concordance Correlation Coefficient', 'Pearson Coefficient', 'Intraclass Correlation Coefficient'}';
featurelabel(:) = {'Peak Latency', 'Peak Amplitude', 'Area Under Curve (Centered Window)', 'Area Under Curve (Standard Window)'};
width= size(iwndw,1)+2;%One for images one for legend
height = cfg.compnumber-1;
textsize= 16;
colorstring = 'kmcrgb';
Legend= 0;
timetoplot = (cfg.trialincr:cfg.trialincr:cfg.trialnumber)';

%GO THROUGH EACH COMPARISON
for icomparison = 1:height %Rows (unlike multi-wndw function)
    %LOAD DATA
    datatoplot_allreg = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).mean;
    errortoplot_allreg = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(cfg.stat{istat}).sem;
    
    %LOAD IMAGE OF COMPARISON
    cd(cfg.stabilityresults); cd ..; cd Figures;
    compimage = imread(['comp' num2str(icomparison) '.png']);
    subplot(height,width,((icomparison-1)*width)+1);
    imshow(compimage);
   
    TITLE = '%s';
    % titlebox = text(0,1450,sprintf(TITLE,cfg.stat{istat},featurelabel{ifeature}),'FontSize',textsize);
    title(sprintf(TITLE,cfg.comparisonlabel{icomparison}),'FontSize',textsize);
    %SAVE FOR LEGEND POSITIONING
    if icomparison==2
        legpos(1,:)=get(gca,'Position');
    else; end
    
    

    subplot(height,width,((icomparison-1)*width)+2)
    
    hold on
    for ireg = 1:cfg.regnumber
        datatoplot = squeeze(datatoplot_allreg(ireg,iwndw,:));
        errortoplot = squeeze(errortoplot_allreg(ireg,iwndw,:));
        %line = plot(timetoplot,datatoplot,'-o');
        %ALTERNATIVE LINE IF WE WANNA SEE ERROR
        line(ireg) = shadedErrorBar(timetoplot,datatoplot,errortoplot,{['-o' colorstring(ireg)],'markerfacecolor',colorstring(ireg)},1);
        
    end
    if istat<5; 
        plot([0 cfg.trialnumber],[0.80 0.80],'-.','color','k');
        plot([0 cfg.trialnumber],[0.60 0.60],'-.','color','k');
    else; end;
    %Increase Height of plots
    h = get(gca,'Position');
    set(gca,'Position',[h(1) h(2) h(3) h(4)+.03])
   box off; grid on;
    hold off

    switch icomparison
        case 1 %PUT IN FIGURE TITLE
            TITLE = '%s of %s of %d-ms peak';
            title(sprintf(TITLE,cfg.stat{istat},featurelabel{ifeature},cfg.peak.target(iwndw)),...
                'FontSize',textsize,'HorizontalAlignment','center');
             xticklabels('');
            
        case 2 %PUT IN LEGEND TO RIGHT OF THIS 
            legpos(2,:) = get(gca,'Position');
            legpos(3,:)=2*legpos(2,:)-legpos(1,:);
            hL = legend([line.mainLine],cfg.regs(:).name,'Orientation','vertical','box','off');
            set(hL,'Position', legpos(3,:),'box','off');
            xticklabels('');
   
        case height %HAVE X TICK LABELS AND X LABEL
            xlabel('Trial Number'); %ylabel(statlabel{istat});
            xticks('auto');
            xticklabels('auto');
        otherwise
            xticklabels('');
    end
    
    %CHANGE AXIS IF SDC
    if strcmp(cfg.stat{istat}, 'SDC') axis( [0 cfg.trialnumber 0 200]);
    else axis( [0 cfg.trialnumber 0 1]);
    end
    
 
    
end

%SAVE FIGURE
Date = datestr(today('datetime'));
fname = [cfg.ProjectName '_Plot_Wndw_Indvidually_' cfg.peak.wndwnames{iwndw} '-ms_' cfg.feature{ifeature} '_' cfg.stat{istat} '_' Date];
cd(cfg.stabilityresults);
ckSTIM_saveFig(fname,textsize,textsize,300,'',4,[10 8]);
end