function lk_waveformplot(reliability,cfg,iTI,ireg)

isub = 1;
icond =1;
iTI=10;
span=10;
timerange = 0:250;
timeidx = find(reliability.times(:,1,1)==timerange(1)):find(reliability.times(:,1,1)==timerange(end));

trialmax=iTI*10;
fewtrials =5;
figure
clear splitrange trialstoplot latencytoplot AUCtoplot legendnames   


cnt=1;
for icond =1:cfg.condnumber
for itrial=1:trialmax %FIRST TEN TRIALS
    
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
plot(timerange,trialstoplot);
title('Individual Trials');
figcnt=figcnt+1;

%PLOT AVG (OF ALL TRIALS)
trialavg = mean(trialstoplot,2);
subplot(4,1,figcnt)
plot (timerange, trialavg)
figcnt=figcnt+1;
title('Average Waveform');

%SMOOTH AND ABS
smoothed = smooth(abs(trialavg),5);
subplot(4,1,figcnt)
plot (timerange, smoothed);
title('Smoothed and Rectified Average');
hold on
aucx = reliability.avgamplat(ireg,:,isub,iTI);
aucidx = aucx +1 - reliability.times(1,icond,isub);

plot ( aucx, smoothed(aucx),'o')
hold off;
figcnt=figcnt+1;

%ADD WINDOW LINES TO TRIALS
subplot(4,1,figcnt)
plot(timerange,trialstoplot(:,1:fewtrials));
title('Integrate AUC for Each Trial (not all shown)');

hold on;
for iwndw = 1:cfg.wndwnumber
    peakrange =  avgamplat(ireg,iwndw,isub,iTI) - cfg.peak.width:avgamplat(ireg,iwndw,isub,iTI) + cfg.peak.width;
    yline=get(gca,'ylim');
    plot([peakrange(1) peakrange(1)],yline,[peakrange(end) peakrange(end) ],yline,'Color',[1 0 0])
    for itrial = 1:fewtrials
        area(peakrange,trialstoplot(peakrange,itrial))
    end
end
hold off;
figcnt=figcnt+1;


%ADD AUC TO AVG (OF ALL TRIALS)
subplot(2,3,figcnt)
plot (timerange, trialavg)
hold on;
plot(aucx,reliability.ampauc(1
figcnt=figcnt+1;

%OTHER
subplot(3,2,figcnt)
plot(reliability.times(500:750,icond,isub),trialstoplot);
hold on
plot(latencytoplot,AUCtoplot,'o');
hold off
%legend(isplit,'Location','southeast')
figcnt= figcnt+1;
 TITLE = sprintf('Subject %d %s \n Circles indicate avg latency and AUC',isub,cfg.regs(ireg).name);
 title(TITLE);
legend(legendnames,'Location','southeast');



%APPLY COREY'S FUNCTION
TITLE = sprintf('Waveforms of Split Halves \n with Avg Latency and AUC');
matfilerange = [cfg.file.subs{1},'-',cfg.file.subs{cfg.subnumber}];
regionname = cfg.regs(ireg).name;
filename = strrep(sprintf('%s_Waveform_AUC_Latency_%s',matfilerange,regionname),' ','_');
cd(cfg.stabilityresults);
ck_save_figure(filename,10,10,1,TITLE,1)

end