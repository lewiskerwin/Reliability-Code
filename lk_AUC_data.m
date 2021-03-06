function data = lk_simpleAUC(data,cfg)
%Note: EEG.data is 3 dimensional array with dimensions
%1:electrodes (64) 2:milliseconds (1500) 3:trials (~150)
for isub = 1:size(data,1)% Go through each subject
    for iconds = 1:size(data,2)%Go through each condition
        
         for ireg = 1:length(cfg.regs)%Go through each region
       % for ielec = 1:size(data(isub,iconds).EEG.data,1)%each electrode
           
            for iwndw = 1:size(cfg.peak.wndw,2)% each time window 
                for itrial = 1:size(data(isub,iconds).EEG.data,3)% each trial
                   
                    
                    TEPtimes = data(isub,iconds).EEG.times; %Name array for the TEP times from raw data
                    datatimes = find( TEPtimes >= cfg.peak.wndw(ireg,iwndw,isub)-cfg.peak.width & TEPtimes <= cfg.peak.wndw(ireg,iwndw,isub)+cfg.peak.width); %Make array of idx of desired times
                    tmp = trapz(datatimes,mean(data(isub,iconds).EEG.data(cfg.regs(ireg).chan,datatimes,itrial),1)); %Intgrate data at that index
                    %tmp = tmp/(data(isub,iconds).EEG.baseline_variance)^0.5; %An optional step here, where we normalize by dividing by standard deviation of baseline
                    data(isub,iconds).EEG.AUC(ireg,iwndw,itrial) = tmp; %Name 'AUC' in data and equate it to the integral above
                    data(isub,iconds).EEG.AUCdim1 = 'electrode';
                    data(isub,iconds).EEG.AUCdim2 = 'window';
                    data(isub,iconds).EEG.AUCdim3 = 'trial';
                    
                
                end
            end
        end
        
    end
end
end