%Normalization (by stdev of -400 to -100 ms in each electrode)

function data = lk_normalize(data)
%First plot data
temp = nanmean(data(1,1).EEG.data,3);        
temp = temp(1:10,:);
figure
subplot(2,1,1);
plot (permute(temp(:,:),[2 1]))

%Now normalize by baseline
for isub = 1:size(data,1) %Go through 6 regions
    for icond = 1:size(data,2) %go through 4 windows
        for ielec = 1:size(data(isub,icond).EEG.data,1) % go through each electrode
            
            normalizer = squeeze(data(isub,icond).EEG.data(ielec,:,:)); %define a temp matrix
            normalizer = normalizer(100:400,:); %Focus on pre-stimulus all trials
            normalizer = squeeze(nanmean(normalizer,2)); % average over trials
            normalizer = var(normalizer)^.5;
            data(isub,icond).EEG.data(ielec,:,:) = data(isub,icond).EEG.data(ielec,:,:)/normalizer;      
            
        end
        
    end
end
%Plot again!
temp2 = nanmean(data(1,1).EEG.data,3);        
temp2 = temp2(1:10,:);
subplot(2,1,2);
plot (permute(temp2(:,:),[2 1]))


end