function [peakdata] = lk_findwndw_sortfirst(sorted,cfg)

clear amplat ampmax ampcauc ampsauc


for ireg = 1:size(cfg.regs,2)
    for iwndw = 1:length(cfg.peak.target) %Go through each PEAK (e.g. 50, 100 200)
        standardpeakidx = find( cfg.alltimes == cfg.peak.target(iwndw));
        
        for isub = 1:cfg.subnumber
            
            %COMMENTED OUT BECAUSE NOT SURE IF WE NEED AVG FOR SUBJECT
            %Find peaks of all splits and conds combined
            
            %FOR EACH COND/SPLIT/ALT...
            for icond = 1:size(cfg.file.preconds)
                wider= 0;
                clear loc; peak = [];
                while 1
                    targettimerange = [cfg.peak.target(iwndw)-cfg.peak.wiggle(iwndw)-wider, cfg.peak.target(iwndw)+cfg.peak.wiggle(iwndw)+wider];
                    targettimeidx = find( cfg.alltimes >= targettimerange(1) & cfg.alltimes <= targettimerange(2));
                    targetdata = smooth(double(abs(mean(sorted(cfg.regs(ireg).chan,targettimeidx,icond,isub),1)')),5);
                    [peak, loc] = findpeaks(targetdata);
                    
                    if isempty(peak) wider = wider +5;
                    else break; end
                end
                
                if size(peak,1)==1 bestpeak=peak; bestidx=1;
                else [bestpeak, bestidx] = max(peak);
                end
                
                %SAVE LATENCY OF THIS DATA POINT
                bestloc = loc(bestidx);
                peakdata.amplat(ireg,iwndw,icond,isub) = bestloc-1 + (cfg.peak.target(iwndw)-cfg.peak.wiggle(iwndw));
                ampidx(ireg,iwndw,icond,isub) = bestloc-1 +  targettimeidx(1); %Add rank (in target range) to location of target-range
                %translate latency back into the full data spectrum
                peakrangeidx = ampidx(ireg,iwndw,icond,isub) - cfg.peak.width(iwndw):  ampidx(ireg,iwndw,icond,isub) + cfg.peak.width(iwndw);
                peakrangelat = cfg.alltimes(peakrangeidx);
                %
                
                %SAVE AMP OF THIS DATA POINT
                peakdata.ampmax(ireg,iwndw,icond,isub) = bestpeak;
                
                
                %CALC AUC CENTERED ON LATENCY (cauc for 'centered auc')
                tmp = trapz(peakrangeidx,mean(sorted(cfg.regs(ireg).chan,peakrangeidx,icond,isub),1)); %Intgrate data at that index
                %tmp = tmp/(data(isub,icond).EEG.baseline_variance)^0.5; %An optional step here, where we normalize by dividing by standard deviation of baseline
                peakdata.ampcauc(ireg,iwndw,icond,isub) = tmp; %Name 'AUC' in data and equate it to the integral above
                
                %CALC AUC CENTERED ON TARGET (sauc for 'standardized auc')
                standardpeakrangeidx = standardpeakidx - cfg.peak.width(iwndw): standardpeakidx + cfg.peak.width(iwndw);
                tmp = trapz(standardpeakrangeidx,mean(sorted(cfg.regs(ireg).chan,standardpeakrangeidx,icond,isub),1)); %Intgrate data at that index
                %tmp = tmp/(data(isub,icond).EEG.baseline_variance)^0.5; %An optional step here, where we normalize by dividing by standard deviation of baseline
                peakdata.ampsauc(ireg,iwndw,icond,isub) = tmp; %Name 'AUC' in data and equate it to the integral above
              
            end
        end
    end
    
end

    
end