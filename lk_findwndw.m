function [lat] = lk_findwndw(reliability,cfg)

clear lat 

for iTI = 1:cfg.trialnumber/cfg.trialincr
for ireg = 1:size(cfg.regs,2)
    for isplit = 1:cfg.numsplit
        for icond = 1:size(cfg.file.preconds)
            for isub = 1:size(cfg.file.subs)
                
                clear peak loc %These two arrays are of all peaks in data and their locations
                splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;
                peakrange = double(abs(mean(mean(reliability.amp(cfg.regs(ireg).chan,:,splitrange,icond,isub),1),3)'));
                [peak, loc] = findpeaks(peakrange);
                
                %Remove the ones out of range
                for ipeak = 1:size(peak)
                    if ~(loc(ipeak)-cfg.ponset >0 & loc(ipeak)-cfg.ponset < 300); peak(ipeak) = 0; loc(ipeak)=0; end
                end
                peak = peak(peak ~=0);%These are the amplitudes of peaks within condcomb
                loc = loc(loc ~=0);%These are the locations of peaks within condcomb
                
                %Find peaks near each desired peak location
                clear nearloc 
                nearpeak = [];
                %These are the arrays of peak locations and peak amplitudes that are near each PEAK
                for iPEAK = 1:length(cfg.peak.target) %Go through each PEAK (e.g. 50, 100 200)
                    cnt = 1;
                    wider= 0;
                    while 1
                        for ipeak = 1:length(peak) %go through each peak in data
                            if abs(loc(ipeak) - cfg.ponset - cfg.peak.target(iPEAK))>(cfg.peak.wiggle+wider);continue;
                            else nearpeak(cnt,iPEAK)=peak(ipeak);nearloc(cnt,iPEAK)=loc(ipeak);cnt=cnt+1; end
                            
                        end
                        if size(nearpeak,2)<iPEAK; wider = wider +5; else break; end;%If we didn't find any peaks within wiggle, we expand our view
                    end
                    [bestpeak(iPEAK), bestidx] = max(nearpeak(:,iPEAK));
                    bestloc(iPEAK) = nearloc(bestidx,iPEAK);
                end
                
                %Now delcare new latencies
                lat(ireg,:,isplit,icond,isub,iTI) = bestloc(:)-cfg.ponset;
                
            end
        end
    end
end
end

end