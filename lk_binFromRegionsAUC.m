function reliability = lk_binFromRegionsAUC(data,cfg)

clear tobin reliability isplit isub icond

for isub = 1:size(data,1)% Go through each subject
    for icond = 1:size(data,2)%Go through each condition
        
        for ireg = 1:size(data(isub,icond).EEG.AUC,1)%Go through each of 6 regions
            for iwndw = 1:size(data(isub,icond).EEG.AUC,2)% each time window
                splitlength = floor(size(data(isub,icond).EEG.data,3)/cfg.numsplit);
                for isplit =1:cfg.numsplit %Go through each split
                    
                    tobin = data(isub,icond).EEG.AUC(ireg,iwndw,1+(isplit-1)*splitlength:isplit*splitlength);
                    reliability.AUCsplit(ireg,iwndw,isplit,icond,isub) = mean(tobin);
                    
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

