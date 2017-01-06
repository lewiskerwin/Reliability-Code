function [amplat, avgamplat, ampauc, ampmax] = lk_findwndw(reliability,cfg)

clear lat amplat

for iTI = 1:floor(cfg.trialnumber/cfg.trialincr)
    
    for ireg = 1:cfg.regnumber
        for isub = 1:cfg.subnumber
            
            %These are the arrays of peak locations and peak amplitudes that are near each PEAK
            
            for iwndw = 1:length(cfg.peak.target) %Go through each PEAK (e.g. 50, 100 200)
                %Find peaks of all splits and conds combined
                wider= 0;
                clear loc; peak = [];
                alltimes = reliability.times(:,1,1,isub);
                while 1
                    targettimerange = [cfg.peak.target(iwndw)-cfg.peak.wiggle(iwndw)-wider, cfg.peak.target(iwndw)+cfg.peak.wiggle(iwndw)+wider];
                    targettimeidx = find( alltimes >= targettimerange(1) & alltimes <= targettimerange(2));
                    % targetdata = double(abs(mean(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,1:iTI*floor(cfg.trialnumber/cfg.trialincr),:,isub),1),3),4)'));
                    %temporarily took out smoothing
                    
                    
                    targetdata = smooth(double(abs(mean(mean(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,1:iTI*cfg.trialincr,:,:,isub),1),3),4),5)')),5);
                    [peak, loc] = findpeaks(targetdata);
                    
                    if isempty(peak) wider = wider +5;
                    else break; end
                end
                
                if size(peak,1)==1 bestpeak=peak; bestidx=1;
                else [bestpeak, bestidx] = max(peak);
                end
                
                bestloc = loc(bestidx);
                avgamplat(ireg,iwndw,isub,iTI) = bestloc-1 + (cfg.peak.target(iwndw)-cfg.peak.wiggle(iwndw));
                avgampidx(ireg,iwndw,isub,iTI) = bestloc-1 +  targettimeidx(1); %Add rank (in target range) to location of target-range
                %translate latency back into the full data spectrum
                peakrangeidx = avgampidx(ireg,iwndw,isub,iTI) - cfg.peak.width(iwndw):  avgampidx(ireg,iwndw,isub,iTI) + cfg.peak.width(iwndw);
                peakrangelat = alltimes(peakrangeidx);
                
                %FOR EACH TRIAL...
                for itp = 1:cfg.tpnumber
                    for icond = 1:cfg.condnumber
                        for itrial = 1:cfg.trialnumber% each trial
                            %SAVE AMP AT SUB'S AVG LATENCY
                            ampmax(ireg,iwndw,itrial,icond,itp,isub,iTI) = bestpeak;
                            
                            
                            %CALC AUC AT SUB's AVG LATENCY
                            tmp = trapz(peakrangeidx,mean(reliability.amp(cfg.regs(ireg).chan,peakrangeidx,itrial,icond,itp,isub),1)); %Intgrate data at that index
                            %tmp = tmp/(data(isub,icond).EEG.baseline_variance)^0.5; %An optional step here, where we normalize by dividing by standard deviation of baseline
                            ampauc(ireg,iwndw,itrial,icond,isub,iTI) = tmp; %Name 'AUC' in data and equate it to the integral above
                            
                            %CALCULATE LAT FOR GIVEN TRIAL
                            wider= 0;
                            clear loc; peak = [];
                            alltimes = reliability.times(:,icond,itp,isub);
                            while 1
                                newpeaktarget = avgamplat(ireg,iwndw,isub,iTI);
                                targettimerange = [newpeaktarget-cfg.peak.precision(iwndw)-wider, newpeaktarget+cfg.peak.precision(iwndw)+wider];
                                targettimeidx = find( alltimes >= targettimerange(1) & alltimes <= targettimerange(2));
                                targetdata = smooth(double(abs(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,itrial,icond,itp,isub),1),3)')),10);
                                %QC to ensure there's actually data here
                                if ~any(targetdata)
                                    errormsg = 'Error! %s at %d ms in subject %s tp%s cond %s is empty!';
                                    disp(sprintf(errormsg,cfg.regs(ireg).name,cfg.peak.target(iwndw),cfg.file.subs{isub},num2str(itp),cfg.file.preconds{icond}));
                                    break;
                                else end;
                                
                                [peak, loc] = findpeaks(targetdata);
                                if isempty(peak) wider = wider +5;
                                else break; end
                            end
                            [bestpeak, bestidx] = max(peak);
                            bestloc = loc(bestidx);
                            amplat(ireg,iwndw,itrial,icond,itp,isub,iTI) = bestloc-1 + (newpeaktarget-cfg.peak.precision(iwndw));
                        end
                    end
                end
                
                
                
                
                %                     %(NOW WE DO BY TRIAL) CALCULATE LATENCIES FOR EVERY SPLIT
                %                     for isplit = 1:cfg.numsplit
                %                         splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;
                %
                %                         wider= 0;
                %                         clear loc; peak = [];
                %                         alltimes = reliability.times(:,icond,isub);
                %                         while 1
                %                             newpeaktarget = avgamplat(ireg,iwndw,isub,iTI);
                %                             targettimerange = [newpeaktarget-cfg.peak.precision(iwndw)-wider, newpeaktarget+cfg.peak.precision(iwndw)+wider];
                %                             targettimeidx = find( alltimes >= targettimerange(1) & alltimes <= targettimerange(2));
                %                             targetdata = smooth(double(abs(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,splitrange,icond,isub),1),3)')),10);
                %                             %QC to ensure there's actually data here
                %                             if ~any(targetdata)
                %                                 errormsg = 'Error! %s at %d ms in subject %s cond %s is empty!';
                %                                 disp(sprintf(errormsg,cfg.regs(ireg).name,cfg.peak.target(iwndw),cfg.file.subs{isub},cfg.file.preconds{icond}));
                %                                 break;
                %                             else end;
                %
                %                             [peak, loc] = findpeaks(targetdata);
                %                             if isempty(peak) wider = wider +5;
                %                             else break; end
                %                         end
                %                         [bestpeak, bestidx] = max(peak);
                %                         bestloc = loc(bestidx);
                %
                %                         amplat(ireg,iwndw,isplit,icond,isub,iTI) = bestloc-1 + (newpeaktarget-cfg.peak.precision(iwndw));
                %                         %QC
                %                         %plot(targettimerange(1):targettimerange(2),targetdata)
                %                     end
                %
                %                     %Now delcare new latencies (one is added here because the
                %                     %index of peak #150 is 1 so the index of best peak is one
                %                     %more than its distance from the bottom of targettimerange
                %
                %
                
                %
                %                  %PLOT OUT THE CONCEPT
                %                 if (iwndw==length(cfg.peak.target) & iTI==size(cfg.regs,2) & plotted==0);
                %                     temp = squeeze((mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,1:iTI*cfg.trialincr,:,isub),1)));
                %                     alltrials = reshape (temp, [size(temp,1) size(temp,2)*size(temp,3)])
                %                     figure
                %                     subplot(1,6,1)
                %                     plot (targettimerange(1):targettimerange(2), alltrials)
                %                     trialavg = mean(alltrials,2)
                %                     subplot(1,6,2)
                %                     plot (targettimerange(1):targettimerange(2), trialavg)
                %                     smoothed = smooth(abs(trialavg),5)
                %                     subplot(1,6,3)
                %                     plot (targettimerange(1):targettimerange(2), smoothed)
                %                     hold on;
                %                     plot ( avgamplat(ireg,iwndw,isub,iTI), max(peak),'o')
                %                     hold off;
                %                     subplot(2,3,4)
                %                     hold on;
                %                     xline(1) =  avgamplat(ireg,iwndw,isub,iTI) - cfg.peak.width;
                %                     xline(2) =  avgamplat(ireg,iwndw,isub,iTI) + cfg.peak.width;
                %                     plot (targettimerange(1):targettimerange(2), alltrials(:,1:5))
                %                     yline=get(gca,'ylim')
                %                     plot([xline(1) xline(1)],yline,[xline(2) xline(2)],yline,'Color',[1 0 0])
                %                     area(peakrange,alltrials(:,1:5))
                %                     hold off;
                %                       else end;
            end
        end
    end
end



end