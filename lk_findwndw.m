function [amplat] = lk_findwndw(reliability,cfg)

clear lat amplat

for iTI = 1:cfg.trialnumber/cfg.trialincr

    for isplit = 1:cfg.numsplit
                    splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;            
                    
    for ireg = 1:size(cfg.regs,2)
        for icond = 1:size(cfg.file.preconds)
            for isub = 1:size(cfg.file.subs)
                
                %These are the arrays of peak locations and peak amplitudes that are near each PEAK
                
                for iPEAK = 1:length(cfg.peak.target) %Go through each PEAK (e.g. 50, 100 200)
                   
                    
                    wider= 0;
                    clear loc; peak = [];
                    alltimes = reliability.times(:,icond,isub);
                    while 1
                    
                    targettimerange = [cfg.peak.target(iPEAK)-cfg.peak.wiggle(iPEAK)-wider, cfg.peak.target(iPEAK)+cfg.peak.wiggle(iPEAK)+wider];
                    targettimeidx = find( alltimes >= targettimerange(1) & alltimes <= targettimerange(2));
                    targetdata = smooth(double(abs(mean(mean(reliability.amp(cfg.regs(ireg).chan,targettimeidx,splitrange,icond,isub),1),3)')));
                    [peak, loc] = findpeaks(targetdata);
                    if isempty(peak) wider = wider +5; 
                    else break; end
                    end
                    [bestpeak, bestidx] = max(peak);
                    bestloc = loc(bestidx);
                     
                    amplat(ireg,iPEAK,isplit,icond,isub,iTI) = bestloc-1 + (cfg.peak.target(iPEAK)-cfg.peak.wiggle(iPEAK));
                    %QC
                    %plot(targettimerange(1):targettimerange(2),targetdata)
                end
                
                %Now delcare new latencies (one is added here because the
                %index of peak #150 is 1 so the index of best peak is one
                %more than its distance from the bottom of targettimerange
                
            end
        end
    end
end
end

end