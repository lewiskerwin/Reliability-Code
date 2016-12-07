%This bins AUC data found the old way (i.e. with predetermined windows)
%where data.EEG.AUC is 64x#wndwsx150 array (New function combines
%electrodes across conditions and makes this array 7x#wndwsx150, this new
%array should be fed into function lk_binFromRegionsAUC)
function reliability = lk_binFromElectrodesAUC(data,cfg,numsplit,wndw,subs,conds)

clear tobin reliability isplit isubs iconds

for isubs = 1:size(data,1)% Go through each subject
    for iconds = 1:size(data,2)%Go through each condition
        
        for ireg = 1:length(cfg.regs)%Go through each of 6 regions
            for iwndw = 1:size(wndw,1)% each time window
                splitlength = floor(size(data(isubs,iconds).EEG.data,3)/numsplit);
                for isplit =1:numsplit %Go through each split
                    
                    tobin = data(isubs,iconds).EEG.AUC(cfg.regs(ireg).chan,iwndw,1+(isplit-1)*splitlength:isplit*splitlength);
                    reliability.AUC(ireg,iwndw,isplit,iconds,isubs) = mean(mean(tobin));
                    
                end
            end
        end
        
    end
end
%Label the dimensions of AUC
reliability.AUCdim{1} = 'region';
reliability.AUCdim{2} = 'window';
reliability.AUCdim{3} = 'split';
reliability.AUCdim{4} = 'condition';
reliability.AUCdim{5} = 'subject';



end

