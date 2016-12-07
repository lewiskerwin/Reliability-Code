function data = lk_simpleAUC(data, wndw, wndw_Names)
%Note: EEG.data is 3 dimensional array with dimensions
%1:electrodes (64) 2:milliseconds (1500) 3:trials (~150)
for isubs = 1:size(data,1)% Go through each subject
    for iconds = 1:size(data,2)%Go through each condition
        
        for ielec = 1:size(data(isubs,iconds).EEG.data,1)%each electrode
            for iwndw = 1:size(wndw,1)% each time window 
                for itrial = 1:size(data(isubs,iconds).EEG.data,3)% each trial
                    
                    TEPtimes = data(isubs,iconds).EEG.times; %Name array for the TEP times from raw data
                    datatimes = find( TEPtimes >= wndw(iwndw,1) & TEPtimes <= wndw(iwndw,2)); %Make array of idx of desired times
                    tmp = trapz(datatimes,data(isubs,iconds).EEG.data(ielec,datatimes,itrial)); %Intgrate data at that index
                    %tmp = tmp/(data(isubs,iconds).EEG.baseline_variance)^0.5; %An optional step here, where we normalize by dividing by standard deviation of baseline
                    data(isubs,iconds).EEG.AUC(ielec,iwndw,itrial) = tmp; %Name 'AUC' in data and equate it to the integral above
                    data(isubs,iconds).EEG.AUCdim1 = 'electrode';
                    data(isubs,iconds).EEG.AUCdim2 = 'window';
                    data(isubs,iconds).EEG.AUCdim3 = 'trial';
                    
                
                end
            end
        end
        
    end
end
end