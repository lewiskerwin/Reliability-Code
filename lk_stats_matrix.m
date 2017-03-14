%NOW MAKE INPUT A MATRIX CONTAINING ALL FEATURES REGS AND WNDWS
function [pearson, tp, CCC, ICC, SDC] =lk_stats(statmat,cfg)
 
%statmat = squeeze(reliability.ampauccond(ireg,iwndw,:,:,:,iTI))';
nsub = size(statmat,4);
ndist = size(statmat,5);% represents ncond or nsplit

% width = 3; %This is the width (or number of columns) of multi-plot figure
% %FigHandle = figure('Position', [100, 100, 1450, 1200]);

pearson = corr(statmat(:,:,:,:,1),statmat(:,:,:,:,2));
[th,tp] = ttest(statmat(:,1),statmat(:,2));
variances = cov(statmat);
CCC = 2*variances(1,2)/(variances(1,1)+variances(2,2)+(mean(statmat(:,1))-mean(statmat(:,2)))^2);

%SS TOTAL
grandmean = mean(mean(statmat));
SST = sum(sum((statmat-grandmean).^2));
%SS BETWEEN SUBS
submean = mean(statmat,2);
SSB = sum((submean-grandmean).^2)*ndist;
DOFB = nsub-1;
MSB = SSB/DOFB;
%SS WITHIN SUBS
SSW = sum(sum((statmat-submean).^2 ));
DOFW = nsub * (ndist-1);
MSW = SSW/DOFW;
%disp(sprintf('As QC SSB + SSW - SST should be zero and here is %d',SSB+SSW-SST));

%CACULATE ICC VIA SHOUT EXN
ICC = (MSB-MSW) / (MSB+(ndist-1)*MSW);

%CALCULATE SDC - ASK MANJARI!?!
VARB = (MSB-MSW)/(ndist); %Per Shrout 
VARW = MSW;
VART = SST/(numel(statmat)-1);
VARresid = VART - (VARB + VARW); %Ug - I tried subtracting and have a negative number!!!
VARresid = VART - (MSB - MSW); % and still negative when I try shrout's correction
SDC = (MSW)^.5 * 2^.5 * 1.96; % So This is the cop out... but might be correct. ask manjari?

end