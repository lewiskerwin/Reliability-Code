function [wndw, wndwnames] = lk_findwndw(data,cfg)

clear wndw wndwnames condcomb   

for isub = 1:size(cfg.file.subs)
   
    for ireg = 1:size(cfg.regs,2)
        %now avg over trials and conditions in order to find peaks
        conddata = []; 
        %condcomb(:,ireg,isub) = zeros(size(data(isub,icond).EEG.data,2),1);
        for icond=1:size(data,2)
           conddata(icond,:) = (mean(mean(data(isub,icond).EEG.data(cfg.regs(ireg).chan,:,:),1),3));
         
        end
        condcomb(:,ireg,isub) = mean(conddata,1).';
        
        %Find the peaks
        clear peak loc %These two arrays are of all peaks in data and their locations
        [peak, loc] = findpeaks(abs(condcomb(:,ireg,isub)));
        data(isub,icond).combcondpeaks = peak; data(isub,icond).combcondpeaklocs = loc;
        %Remove the ones out of range
        for ipeak = 1:size(peak)
            if ~(loc(ipeak) >500 & loc(ipeak) < 800); peak(ipeak) = 0; loc(ipeak)=0; end
        end
        peak = peak(peak ~=0);%These are the amplitudes of peaks within condcomb
        loc = loc(loc ~=0);%These are the locations of peaks within condcomb
       
        %Find peaks near each desired peak location
        clear nearloc nearpeak %These are the arrays of peak locations and peak amplitudes that are near each PEAK
        for iPEAK = 1:length(cfg.peak.target) %Go through each PEAK (e.g. 50, 100 200)
            cnt = 1;
            wider= 0;
            while 1 
                for ipeak = 1:length(peak) %go through each peak in data
                    if abs(loc(ipeak) - 500 - cfg.peak.target(iPEAK))>(cfg.peak.wiggle+wider);continue;
                    else nearpeak(cnt,iPEAK)=peak(ipeak);nearloc(cnt,iPEAK)=loc(ipeak);cnt=cnt+1; end
                   
                end
                if size(nearpeak,2)<iPEAK; wider = wider +5; else break; end;%If we didn't find any peaks within wiggle, we expand our view
            end
            [bestpeak(iPEAK), bestidx] = max(nearpeak(:,iPEAK));
             bestloc(iPEAK) = nearloc(bestidx,iPEAK);
        end
        
        %Now delcare new windows
        
        
        wndw(:,1,ireg,isub) = bestloc(:)-cfg.peak.width/2-500;
        wndw(:,2,ireg,isub) = bestloc(:)+cfg.peak.width/2-500;
        wndwnames = strread(num2str(cfg.peak.target),'%s');
    
        
    end
end

end