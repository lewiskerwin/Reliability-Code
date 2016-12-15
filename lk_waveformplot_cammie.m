function lk_waveformplot(reliability,cfg,ireg)

span = 10; figcnt =1;
figure
clear splitrange splitstoplot latencytoplot AUCtoplot legendnames       

for isub = 1:cfg.subnumber
    cnt = 1;
    
    for iTI=1:2:floor(cfg.trialnumber/cfg.trialincr)
        for icond =1:1
            for isplit=1:cfg.numsplit
                
                splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;
                splitstoplot(:,cnt) = smooth(mean(mean(reliability.amp(cfg.regs(ireg).chan,500:750,splitrange,icond,isub),1),3),span);
                
                latencytoplot (:,cnt) = reliability.amplat(ireg,:,isplit,icond,isub,iTI);
                AUCtoplot(:,cnt) = reliability.ampauc(ireg,:,isplit,icond,isub,iTI)*5./max(max(max(abs(reliability.ampauc(ireg,:,:,:,isub,iTI)))));
                legendnames{cnt} = sprintf('Condition %d with %d trials',icond,iTI*cfg.trialincr);
                
                cnt=cnt+1;
            end
        end
    end
subplot(cfg.subnumber,1,figcnt)
plot(reliability.times(500:750,icond,isub),splitstoplot);
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