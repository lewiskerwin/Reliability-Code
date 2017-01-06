function lk_waveformplot(reliability,cfg,iTI,ireg,isub)

clear timeidx

span=10;
timerange = 1:300;
timeidx = find(reliability.times(:,1,1)==timerange(1)):find(reliability.times(:,1,1)==timerange(end));
%Note: time idx currently does not include zero 
trialmax=iTI*10;
fewtrials =5;
figure
clear splitrange trialstoplot latencytoplot AUCtoplot legendnames   


cnt=1;
for icond =1:cfg.condnumber
for itrial=1:trialmax
    
   %splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;
   trialstoplot(:,cnt) = mean(mean(reliability.amp(cfg.regs(ireg).chan,timeidx,itrial,icond,isub),1),3);
  
   latencytoplot (:,cnt) = reliability.amplat(ireg,:,itrial,icond,isub,iTI);
   peakmax = max(max(max(abs(reliability.ampmax(ireg,:,1:trialmax,:,isub,iTI)))));
   aucmax =  max(max(max(abs(reliability.ampauc(ireg,:,1:trialmax,:,isub,iTI)))));
   AUCtoplot(:,cnt) = (reliability.ampauc(ireg,:,itrial,icond,isub,iTI)*peakmax)/aucmax;
   legendnames{cnt} = sprintf('Condition %d Split %d',icond,itrial);
   
   cnt=cnt+1;
end
end

figcnt=1;
%PLOT TRIALS
subplot(4,1,figcnt)
plot(timerange,trialstoplot(:,1:trialmax),'LineWidth',2);
title('Load Individual Trials (for a given region of interest)');
figcnt=figcnt+1;
box off;xlabel('ms'); ylabel('uV');

%PLOT AVG (OF ALL TRIALS)
trialavg = mean(trialstoplot,2);
subplot(4,1,figcnt)
plot (timerange, trialavg,'LineWidth',2)
figcnt=figcnt+1;
title('Take the Average Waveform');
box off;xlabel('ms'); ylabel('uV');


%SMOOTH AND ABS
smoothed = abs(smooth(trialavg,5));
subplot(4,1,figcnt)
plot (timerange, smoothed,'LineWidth',2);
title('Smooth and Rectify Average to Find Peaks in Windows of Interest');
hold on
aucx = reliability.avgamplat(ireg,:,isub,iTI);
aucidx = aucx +1 - reliability.times(1,icond,isub);

plot ( aucx, smoothed(aucx),'o')
hold off;
box off;xlabel('ms'); ylabel('uV');
figcnt=figcnt+1;

%ADD WINDOW LINES TO TRIALS WITH INTEGRATION
subplot(4,1,figcnt)
plot(timerange,trialstoplot(:,1:fewtrials),'LineWidth',2);
title('Integrate Area Under Curve for Each Trial');

hold on;
for iwndw = 1:cfg.wndwnumber
    peakrange =  reliability.avgamplat(ireg,iwndw,isub,iTI) - cfg.peak.width(iwndw):reliability.avgamplat(ireg,iwndw,isub,iTI) + cfg.peak.width(iwndw);
    yline=get(gca,'ylim');
    plot([peakrange(1) peakrange(1)],yline,[peakrange(end) peakrange(end) ],yline,'Color',[1 0 0]);
    for itrial = 1:fewtrials
        area(peakrange,trialstoplot(peakrange,itrial))
    end
end
box off;xlabel('ms'); ylabel('uV');
hold off;
figcnt=figcnt+1;


% %ADD WINDOW LINES TO TRIALS AND FIND LATENCIES!
% subplot(4,1,figcnt)
% plot(timerange,trialstoplot(:,1:fewtrials),'LineWidth',2);
% title('Integrate Area Under Curve for Each Trial');
% 
% hold on;
% for iwndw = 1:cfg.wndwnumber
%     peakrange =  reliability.avgamplat(ireg,iwndw,isub,iTI) - cfg.peak.width(iwndw):reliability.avgamplat(ireg,iwndw,isub,iTI) + cfg.peak.width(iwndw);
%     yline=get(gca,'ylim');
%     plot([peakrange(1) peakrange(1)],yline,[peakrange(end) peakrange(end) ],yline,'Color',[1 0 0]);
%     
%     
%     %for itrial = 1:fewtrials
%         aucx = reliability.amplat(ireg,iwndw,1:cfg.fewtrials,:,isub,iTI);
%     %end
% end
% box off;xlabel('ms'); ylabel('uV');
% hold off;
% figcnt=figcnt+1;


% 
% %ADD AUC TO AVG (OF ALL TRIALS)
% subplot(2,3,figcnt)
% plot (timerange, trialavg)
% hold on;
% linemax= max(trialavg);
% 
% plot(aucx,mean(mean(reliability.ampauc(ireg,:,:,:,isub,iTI),3),4),'o');
% hold off;
% figcnt=figcnt+1;
% 
% %OTHER
% subplot(3,2,figcnt)
% plot(reliability.times(500:750,icond,isub),trialstoplot);
% hold on
% plot(latencytoplot,AUCtoplot,'o');
% hold off
% %legend(isplit,'Location','southeast')
% figcnt= figcnt+1;
%  TITLE = sprintf('Subject %d %s \n Circles indicate avg latency and AUC',isub,cfg.regs(ireg).name);
%  title(TITLE);
% legend(legendnames,'Location','southeast');



%APPLY COREY'S FUNCTION

Date = datestr(today('datetime'));
fname = [cfg.ProjectName '_Wave_Reg' num2str(ireg) 'Sub' num2str(isub) 'TI' num2str(iTI) '_' Date];
cd(cfg.stabilityresults);
ckSTIM_saveFig(fname,10,10,300,'',4,[10 8]);


% TITLE = sprintf('Waveforms of Split Halves \n with Avg Latency and AUC');
% matfilerange = [cfg.file.subs{1},'-',cfg.file.subs{cfg.subnumber}];
% regionname = cfg.regs(ireg).name;
% filename = strrep(sprintf('%s_Waveform_AUC_Latency_%s',matfilerange,regionname),' ','_');
% cd(cfg.stabilityresults);
% ck_save_figure(filename,10,10,1,TITLE,1)

end