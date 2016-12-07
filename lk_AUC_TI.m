function reliability = lk_AUC_TI(reliability,cfg)
%Note: EEG.data is 3 dimensional array with dimensions
%1:electrodes (64) 2:milliseconds (1500) 3:trials (~150)
for iTI = 1:cfg.trialnumber/cfg.trialincr
    for isub = 1:size(reliability.amp,5)% Go through each subject
        for icond = 1:size(reliability.amp,4)%Go through each condition
            
            for ireg = 1:length(cfg.regs)%Go through each region
                % for ielec = 1:size(data(isub,icond).EEG.data,1)%each electrode
                
                for iwndw = 1:size(cfg.peak.target,2)% each time window
                    for isplit = 1:cfg.numsplit% each trial
                        
                        
                        TEPtimes = reliability.times(:,icond,isub); %Name array for the TEP times from raw data
                        peakrange = find( cfg.peak.width >= abs(TEPtimes - reliability.amplat(ireg,iwndw,isplit,icond,isub,iTI))); %Make array of idx of desired times
                        splitrange = ((isplit-1)*iTI*cfg.trialincr/cfg.numsplit)+1:isplit*iTI*cfg.trialincr/cfg.numsplit;

                        tmp = trapz(peakrange,mean(mean(reliability.amp(cfg.regs(ireg).chan,peakrange,splitrange,icond,isub),1),3)); %Intgrate data at that index
                        %tmp = tmp/(data(isub,icond).EEG.baseline_variance)^0.5; %An optional step here, where we normalize by dividing by standard deviation of baseline
                        reliability.ampauc(ireg,iwndw,isplit,icond,isub,iTI) = tmp; %Name 'AUC' in data and equate it to the integral above
                      
                        
                        
                    end
                end
            end
            
        end
    end
end
end