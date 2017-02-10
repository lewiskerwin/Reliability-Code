function lk_plotTIbar(data,stats,cfg,ifeature,istat)


TIcompnumber = size(cfg.TItocompare,2);

%PLOT EFFECT OF INCREASING TRIAL NUMBER ON CCC
figure('Position', [100, 100, 1450, 1200])

%DEFINE PARTS OF STRUCTURE TO PLOT
%fieldnames(reliability); - can use this for higher versatility
clear stattoplot
ifeature = 3; %Adjust here
icomparison = cfg.compnumber; %and here
fctoplot = [cfg.feature{ifeature} cfg.comparison{icomparison}];
stattoplot(:)= {'CCC','pearson','tp'};
statlabel(:) = {'Concordance Correlation Coefficient', 'Pearson Coefficient', 'Intraclass Correlation Coefficient'}';
featurelabel(:) = {'Peak Latency', 'Peak Amplitude', 'Area Under Curve (Centered Window)', 'Area Under Curve (Standard Window)'};
width= cfg.regnumber;
istat = 3;
colorstring = 'ymcrgb';
Legend= 0;
timetoplot = (cfg.trialincr:cfg.trialincr:cfg.trialnumber)';



for ireg = 1:cfg.regnumber    
%comparisonlabeled =0;

for iwndw=1:size(cfg.peak.target,2) 
    %FOR THIS REG/WNDW
    %1) SPECIFIY SUBPLOT
    subplot(size(cfg.peak.target,2),width,(iwndw-1)*width+ireg)
    
    %2) LOAD DATA POINTS AND CCC BETWEEN
    peakdatatoplot = squeeze(data.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).mean(ireg,iwndw,cfg.TItocompare,:));
    % TI(selected) x data points (this is the actual data
    statdatatoplot = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(stattoplot{istat}).mean(ireg,iwndw,cfg.TItocompare);
     % TI(selected) (this is the T test)
    statdatatoplot = squeeze(statdatatoplot);
    %errortoplot = stats.(cfg.feature{ifeature}).(cfg.comparison{icomparison}).(stattoplot{istat}).std(ireg,iwndw,cfg.TItocompare);
    %errortoplot = squeeze(errortoplot);

    
    %3) PLOT
   % hold on
    %for idist = 1:size(peaktoplot,1)
        
        ind = plot(1:TIcompnumber,peakdatatoplot', 'Marker','+','Linestyle','none','Color','b');
        %boxplot(peakdatatoplot')
        %ALTERNATIVE LINE IF WE WANNA SEE ERROR
        %line(ireg) = shadedErrorBar(timetoplot,datatoplot,errortoplot,{['-o' colorstring(ireg)],'markerfacecolor',colorstring(ireg)},1);
        %end
        hold on
        xlim([0 TIcompnumber+1]);
        yl = ylim;
        ylim([yl(1) (yl(2))*(1+(0.1*(TIcompnumber)))]);
        
        set(gca,'Xtick',1:TIcompnumber,'XTickLabel',cfg.TItocompare*cfg.trialincr);

        xt = xticks;
        for idist = 1:TIcompnumber-1
            %for jdist = idist+1:size(peakdatatoplot,1)
                if statdatatoplot(idist) < 0.05
                    plot([xt(idist) xt(TIcompnumber)], [1 1]*max(max(peakdatatoplot))*(1+(0.1*(2*idist-1))), '-k');
                    text(mean(xt([idist TIcompnumber])), max(max(peakdatatoplot))*(1+(0.1*(2*idist))), num2str(round(statdatatoplot(idist),2)));
                else; end;
                
                %avg = plot(TItocompare*cfg.trialincr,mean(peakdatatoplot(:,:),2),'Marker','o','Linestyle','none','Color','r');
            %end
        end
        
        xticklabels(cfg.TItocompare*cfg.trialincr)
        hold off
        
    %Add "stat" only on top row of graphs
    if iwndw==1
        %Top middle gets special AUC vs LAT
        if ireg == (floor(width/2)+1)
            TITLE = '%s for R DLPFC Stimulation \n %s \n %s-ms peak';
            title(sprintf(TITLE,featurelabel{ifeature},cfg.regs(ireg).name,cfg.peak.wndwnames{iwndw}));
        else
            TITLE = '%s \n %s-ms peak';
            title(sprintf(TITLE,cfg.regs(ireg).name,cfg.peak.wndwnames{iwndw}));
        end
    else
        TITLE = '%s-ms peak';
        title(sprintf(TITLE,cfg.peak.wndwnames{iwndw}));

    end
   
    
    xlabel('Trial Number'); %ylabel(featurelabel{ifeature});
    
%     if strcmp(stattoplot{istat}, 'SDC') axis( [0 cfg.trialnumber 0 200]);
%     else axis( [0 cfg.trialnumber 0 1]);
%     end
%     box off; grid on;
% 
%     
    
end

end
% middlepenultimate = (cfg.wndwnumber-2)*cfg.compnumber+floor((cfg.compnumber+1)/2);
% subplot(cfg.wndwnumber,cfg.compnumber,middlepenultimate);
% plotposa = get(gca,'Position');
% middlebottom = (cfg.wndwnumber-1)*cfg.compnumber+floor((cfg.compnumber+1)/2);
% subplot(cfg.wndwnumber,cfg.compnumber,middlebottom);
% plotposb = get(gca,'Position');
% hL = legend([line.mainLine],cfg.regs(:).name,'Orientation','horizontal','box','off');
% onebelow = plotposb(2)-(plotposa(2)-plotposb(2));
% legpos = [plotposb(1) onebelow+0.05 0.2 0.2];
%         set(hL,'Position', legpos,'box','off');

Date = datestr(today('datetime'));
fname = [cfg.ProjectName '_scatter_' cfg.feature{ifeature} '_' stattoplot{istat} '_' Date];
cd(cfg.stabilityresults);
ckSTIM_saveFig(fname,10,10,300,'',4,[10 8]);
end