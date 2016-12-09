function reliability = lk_varianceTI(reliability, cfg)

clear reliability.ICC
for iTI=1:cfg.trialnumber/cfg.trialincr
    for ireg = 1:size(reliability.ampauc,1) %Go through 6 regions
        for iwndw = 1:size(reliability.ampauc,2) %go through 4 windows
            clear miniAUC tdAUC grandmean %Clear the table that will get rid of dimensions with 1 element, and 2D table
            %Reminder: dimensions of AUC are: reg, wndw, split, cond, sub
            miniAUC = squeeze(reliability.ampauc(ireg,iwndw,:,:,:,iTI)); %Let's look only at non-one dimensions: split, condition and subject
            ndim = ndims(miniAUC);
            grandmean = mean(mean(mean(miniAUC)));
            SST = sum(sum(sum((miniAUC(:,:)-grandmean).^2))); %AS quality control, we show the total sum of squares which equals SSB + SSW
            %Here we fill the final row in our anova table: the totals
            reliability.SSB(ireg,iwndw,ndim+2,iTI) = SST;%Redord total sum of squares
            reliability.DOFB(ireg,iwndw,ndim+2,iTI) = numel(miniAUC)-1;%total degrees of freedom
            reliability.MSB(ireg,iwndw,ndim+2,iTI) = reliability.SSB(ireg,iwndw,ndim+2)/reliability.DOFB(ireg,iwndw,ndim+2);
            reliability.VAR(ireg,iwndw,ndim+2,iTI) = reliability.MSB(ireg,iwndw,ndim+2);
            
            for idim=1:3
                DOFB = size(miniAUC,1)-1; %Degrees of freedom for between-splits, then conds, then subs
                DOFW = (size(miniAUC,2)*size(miniAUC,3)-1)*size(miniAUC,1);%Degrees of freedom for within-splits, then conds, then subs
                
                %See older matlab backups for loop algorithm, this si quicker
                MSB = var(mean(mean(miniAUC,2),3))*size(miniAUC,2)*size(miniAUC,3);%Variance of averaged times number of data points each avg represetns
                SSB = var(mean(mean(miniAUC,2),3))*size(miniAUC,2)*size(miniAUC,3)*DOFB;
                SSW = SST - SSB; %To calculate Meansquares of within-subject variance, we first find SS with subtraction,
                MSW = SSW/DOFW; %...then divide by DOF
                
                %We coudl apply this to all dimensions with code: miniAUC = permute(miniAUC, [3, 1, 2]);
                
                
                %See email backup for old ANOVA method
                
                %now calculate true variance usign Manjari's paper (Shrout 1979):
                %MSB = varB*k + varW (varW is essentially the same as MSW)
                reliability.VAR(ireg,iwndw,idim,iTI) = (MSB-MSW)/(size(miniAUC,2)*size(miniAUC,3));
                reliability.VAR_B(ireg,iwndw,idim,iTI) = var(mean(mean(miniAUC,2),3));%Alternatively, we could just take variance which ignores the snd term in paper's fomrula
                %Another way to calculate the above line: = (MSB)/(size(miniAUC,2)*size(miniAUC,3))
                
                %Using similar formulat from same paper calculate ICC
                reliability.ICC(ireg,iwndw,idim,iTI) = (MSB-MSW)/(MSB+(size(miniAUC,2)*size(miniAUC,3)-1)*MSW);
                reliability.SSB(ireg,iwndw,idim,iTI) = SSB; reliability.SSW(ireg,iwndw,idim,iTI)=SSW; reliability.MSB(ireg,iwndw,idim,iTI)=MSB; reliability.MSW(ireg,iwndw,idim,iTI)=MSW;
                reliability.DOFB(ireg,iwndw,idim,iTI) = DOFB;reliability.DOFW(ireg,iwndw,idim,iTI) = DOFW;
                %At some point calculate Mean square metrics (how to get from MSB
                %to actual variance)
                
                %Now c
                
                miniAUC = permute(miniAUC,[2 3 1]);
            end
            %Now calculate residual sum squares and DOF
            reliability.SSB(ireg,iwndw,ndim+1,iTI) = reliability.SSB(ireg,iwndw,ndim+2,iTI) - sum(reliability.SSB(ireg,iwndw,1:ndim,iTI));
            reliability.DOFB(ireg,iwndw,ndim+1,iTI)= reliability.DOFB(ireg,iwndw,ndim+2,iTI) - sum(reliability.DOFB(ireg,iwndw,1:ndim,iTI));
            reliability.MSB(ireg,iwndw,ndim+1,iTI) = reliability.SSB(ireg,iwndw,ndim+1,iTI)/reliability.DOFB(ireg,iwndw,ndim+1,iTI);
            reliability.VAR(ireg,iwndw,ndim+1,iTI) = reliability.MSB(ireg,iwndw,ndim+1,iTI);
            reliability.VAR_B(ireg,iwndw,ndim+1,iTI) = reliability.MSB(ireg,iwndw,ndim+1,iTI);
            
            
            %         %These lines told us that total vairance (=MSB total doesnt'
            %         acutally equal the sum of other variances :P unless I'm wrong on how to calculate residual variance
            %         reliability.VAR(ireg,iwndw,5)-sum(reliability.VAR(ireg,iwndw,1:ndim))
            %         reliability.VAR(ireg,iwndw,5)-sum(reliability.VAR_ALT(ireg,iwndw,1:ndim))
            
            
            %Fnd SEMeas using formula from Schambra et al
            tempvar= reliability.VAR_B(ireg,iwndw,ndim+1,iTI);%residual variance
            for idim=1:3
                tempvar = tempvar+ reliability.VAR_B(ireg,iwndw,idim,iTI);%add to it the variance of each dim
                reliability.SEM(ireg,iwndw,idim,iTI) = (tempvar)^.5;
                reliability.SDC(ireg,iwndw,idim,iTI) = reliability.SEM(ireg,iwndw,idim,iTI)*2^.5*1.96;
                reliability.SDCpercent(ireg,iwndw,idim,iTI) = reliability.SDC(ireg,iwndw,idim,iTI)/ abs(mean(mean(mean(reliability.ampauc(ireg,iwndw,:,:,:,10),3),4),5));
                display(['In ' cfg.regs(ireg).name ' the minimum change in AUC to ensure a change between two ' reliability.AUCdim{2+idim} 's is ' num2str(reliability.SDC(ireg,iwndw,idim,iTI))]);
            end
            
            
        end
    end
end
reliability.ICCdim = {'Split', 'Condition', 'Subject'};
end