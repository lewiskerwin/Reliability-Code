function [reliability] = lk_BLC(reliability,cfg);

%SUBTRACT BASELINE AMPLITUDE
% %The below code tells me that the period is at least 60 ms and therefore
% %that avg over 10 trials will not swamp.
% toplot = squeeze(mean(reliability.amp(cfg.regs(1).chan,400:550,18:20,1,1),1));
% plot(toplot);
baselinerange = (cfg.ponset-11):(cfg.ponset-1);
reliability.BLA(:,:,:,:) = mean(reliability.amp(:,baselinerange,:,:,:),2);
%elec x trials x cond x sub

% %And this code displays the same trials to doublecheck
%mean(reliability.BLA(cfg.regs(1).chan,18:20,1,1),1)
for ireg=1:cfg.regnumber
    for itrial = 1:cfg.trialnumber
        for icond = 1:cfg.condnumber
            for isub = 1:cfg.subnumber
                reliability.amp(cfg.regs(ireg).chan,:,itrial,icond,isub) = reliability.amp(cfg.regs(ireg).chan,:,itrial,icond,isub) - reliability.BLA(ireg,itrial,icond,isub);
            end 
        end
    end
end

end