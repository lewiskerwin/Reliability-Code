function lk_waveformplot(reliability,cfg,iTI,ireg)

span = 10; figcnt =1; trialmax=10;
figure
clear splitrange trialstoplot latencytoplot AUCtoplot legendnames       
for isub = 1:cfg.subnumber
cnt = 1; 
for icond =1:cfg.condnumber
for itrial=1:trialmax %FIRST TEN TRIALS
    
   %splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;
   trialstoplot(:,cnt) = smooth(mean(mean(reliability.amp(cfg.regs(ireg).chan,500:750,itrial,icond,isub),1),3),span);
  
   latencytoplot (:,cnt) = reliability.amplat(ireg,:,itrial,icond,isub,iTI);
   peakmax = max(max(max(abs(reliability.ampmax(ireg,:,1:trialmax,:,isub,iTI)))));
   aucmax =  max(max(max(abs(reliability.ampauc(ireg,:,1:trialmax,:,isub,iTI)))));
   AUCtoplot(:,cnt) = (reliability.ampauc(ireg,:,itrial,icond,isub,iTI)*peakmax)/aucmax;
   legendnames{cnt} = sprintf('Condition %d Split %d',icond,itrial);
   
   cnt=cnt+1;
end
end
subplot(cfg.subnumber,1,figcnt)
plot(reliability.times(500:750,icond,isub),trialstoplot);
hold on
plot(latencytoplot,AUCtoplot,'o');
hold off
%legend(isplit,'Location','southeast')
figcnt= figcnt+1;
 TITLE = sprintf('Subject %d %s \n Circles indicate avg latency and AUC',isub,cfg.regs(ireg).name);
 title(TITLE);
legend(legendnames,'Location','southeast');
end


%APPLY COREY'S FUNCTION
TITLE = sprintf('Waveforms of Split Halves \n with Avg Latency and AUC');
matfilerange = [cfg.file.subs{1},'-',cfg.file.subs{cfg.subnumber}];
regionname = cfg.regs(ireg).name;
filename = strrep(sprintf('%s_Waveform_AUC_Latency_%s',matfilerange,regionname),' ','_');
cd(cfg.stabilityresults);
ck_save_figure(filename,10,10,1,TITLE,1)

end