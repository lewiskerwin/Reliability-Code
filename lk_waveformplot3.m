function lk_waveformplot(data,cfg,iTI,ireg,isub,icond,icomparison)

clear timeidx
xmin=-100;
xmax=300;
span=10;
timerange = xmin:xmax;
timeidx = find(data.times(:,1,1)==timerange(1)):find(data.times(:,1,1)==timerange(end));
%Note: time idx currently does not include zero 
trialmax=iTI*10;
fewtrials =5;
textsize = 16;
figure('Position', [100, 100, 400, 600])
clear splitrange trialstoplot latencytoplot AUCtoplot legendnames  trials 


%WEIRDLY THE CODE BELOW SELECTS TRIALS FROM A VARIABLE WITHOUT SPECIFYING
%WHICH DAY. I DON'T KNOW HOW THIS DOESN'T GIVE IT AN ERROR. AND EXTRA
%WEIRDLY IT WORKS OUT TO LINE UP WITH AMPLAT.COND.MEAN AND
%AMPMAX.COND.MEAN.  WHAT IS DOES IS SELCT ONLY FROM DAY 1, BUT THIS WOULD
%GIVE A WAVEFORM THAT WOULD BE DIFFERENT THAN THE LATENCIES CALCULATED IN
%HALFSAMPLETP, WHICH WOULD USE BOTH DAYS I THINK... WEIRD.

%PEAKPICKING ONLY WORKS WELL WHEN SAMPLING IS 100% Even iit of 50 didn't
%fix

figcnt=1;
%1. PLOT TRIALS
cnt=1;
% for itrial=1:trialmax
%    %splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;
%    trialstoplot(:,cnt) = mean(mean(data.amp(cfg.regs(ireg).chan,timeidx,itrial,icond,cfg.dayforcond,isub),1),3);
%    
   trials = squeeze(cfg.alltrialkey(iTI,icomparison,icond,1:trialmax/2));
      trialstoplot(:,:) = ...
          squeeze(mean(data.amp(cfg.regs(ireg).chan,timeidx,trials,cfg.dayforcond,isub),1));

%    cnt=cnt+1;
% end

subplot(3,1,figcnt)
plot(timerange,trialstoplot(:,1:trialmax/2),'LineWidth',2);
hold on;
ylim=get(gca,'ylim');
xlim = get(gca,'xlim');
axis([xmin,xlim(2),ylim(1),ylim(2)]);
plot([0 0],[ylim(2) ylim(1)],'k-.')
%text(-10,(ylim(2)-(ylim(2)-ylim(1))/10),'Pulse','FontWeight','Bold');
%title('Load Individual Trials (for a given region ofdd interest)');
%Now plot avg
trialavg = mean(trialstoplot,2);
expandedtrialavg = trialavg*(max(max(abs(trialstoplot(:,1:trialmax/2))))/max(abs(trialavg)));
plot (timerange, expandedtrialavg,'-k','LineWidth',4);
plot([xmin xmax],[0 0],'--k');
figcnt=figcnt+1;
box off; xticklabels(''); ylabel('uV','fontsize',textsize); hold off;
set(gca,'fontsize',textsize);

% PLOT AVG (OF ALL TRIALS)
% trialavg = mean(trialstoplot,2);
% plot (timerange, trialavg,'-k','LineWidth',3);
% subplot(3,1,figcnt)
% plot (timerange, trialavg,'LineWidth',2)
% hold on
% ylim=get(gca,'ylim');
% xlim = get(gca,'xlim');
% axis([xmin,xlim(2),ylim(1),ylim(2)]);
% plot([0 0],[ylim(2) ylim(1)],'k-.')
% text(-10,(ylim(2)-(ylim(2)-ylim(1))/10),'Pulse','FontWeight','Bold');
% figcnt=figcnt+1;
% %title('Take the Average Waveform');
% box off;xticklabels('off'); ylabel('uV'); hold off


%3. SMOOTH AND ABS
smoothed = abs(smooth(trialavg,5));
subplot(3,1,figcnt)
plot (timerange, smoothed,'-k','LineWidth',2);
%title('Smooth and Rectify Average to Find Peaks in Windows of Interest');
hold on
%Show Pulse
ylim=get(gca,'ylim');
xlim = get(gca,'xlim');
axis([xmin,xlim(2),ylim(1),ylim(2)]);
plot([0 0],[ylim(2) ylim(1)],'k-.')
%text(-10,(ylim(2)-(ylim(2)-ylim(1))/10),'Pulse','FontWeight','Bold');
%FIND LAT and AMP
peaklat = data.amplat.(cfg.comparison{icomparison}).mean(ireg,:,icond,isub,iTI);
peakamp = data.ampmax.(cfg.comparison{icomparison}).mean(ireg,:,icond,isub,iTI);
plot([peaklat' peaklat']',[zeros(cfg.wndwnumber,1) peakamp']','k--');
plot([zeros(cfg.wndwnumber,1)+xmin peaklat']',[peakamp' peakamp']','k--');
aucidx = peaklat +1 - data.times(1,icond,isub);
% for iwndw= 1:cfg.wndwnumber
%     peaktimeidx(iwndw) = find(data.times(:,1,1)==round(peaklat(iwndw),0));
% end
peaktimeidx = peaklat-xmin;
plot ( round(peaklat,0), smoothed(round(peaktimeidx,0)),'o')
%plot (peaklat,peakamp,'o');
%plot (peaklat, trialavg(round(peaklat,0)),'o')
hold off;
box off;xticklabels(''); ylabel('|uV|','fontsize',textsize);
set(gca,'fontsize',textsize);
figcnt=figcnt+1;


%4. PLOT AVG AGAIN WITH AUC
subplot(3,1,figcnt)
plot (timerange, trialavg,'-k','LineWidth',2)
hold on
%Show pulse
ylim=get(gca,'ylim');
xlim = get(gca,'xlim');
axis([xmin,xlim(2),ylim(1),ylim(2)]);
plot([0 0],[ylim(2) ylim(1)],'k-.')
%text(-10,(ylim(2)-(ylim(2)-ylim(1))/10),'Pulse','FontWeight','Bold');
%Show Integration
for iwndw = 1:cfg.wndwnumber
    peakrange =  peaklat(iwndw) - cfg.peak.width(iwndw) : peaklat(iwndw) + cfg.peak.width(iwndw);
    peakrangeidx = find(timerange ==peakrange(1)): find(timerange ==peakrange(end));
    plot([peakrange(1) peakrange(1)],ylim,[peakrange(end) peakrange(end) ],ylim,'Color',[1 0 0]);
    plot([peaklat(iwndw) peaklat(iwndw)],[ylim(2) 0],'k--')
    ah = area(peakrange,trialavg(peakrangeidx));
    ah.FaceColor = [0.4, 0.4, 0.4]; %    grey = [0.4,0.4,0.4];
end
hold off;
figcnt=figcnt+1;
%title('Integrate Area Under Curve for Avg Waveform');
box off;
xticks([xmin:100:xmax])
set(gca,'xticklabel',[xmin:100:xmax],'fontsize',textsize)
xlabel('ms','fontsize',textsize); ylabel('uV','fontsize',textsize);

%APPLY COREY'S FUNCTION

Date = datestr(today('datetime'));
fname = [cfg.ProjectName '_Wave_Reg' num2str(ireg) 'Sub' num2str(isub) 'TI' num2str(iTI) '_' Date];
cd(cfg.stabilityresults);
ckSTIM_saveFig(fname,textsize,textsize,300,'',4,[6 8]);



end