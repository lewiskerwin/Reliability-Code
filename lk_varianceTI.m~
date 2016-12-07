function reliability = lk_varianceTI(reliability, cfg)

clear reliability.ICC
for itrial=1:cfg.trialnumber/cfg.trialincr
    for ireg = 1:size(reliability.ampauc,1) %Go through 6 regions
        for iwndw = 1:size(reliability.ampauc,2) %go through 4 windows
            clear miniAUC tdAUC grandmean %Clear the table that will get rid of dimensions with 1 element, and 2D table
            %Reminder: dimensions of AUC are: reg, wndw, split, cond, sub
            miniAUC = squeeze(reliability.ampauc(ireg,iwndw,:,:,:,itrial)); %Let's look only at non-one dimensions: split, condition and subject
            ndim = ndims(miniAUC);
            grandmean = mean(mean(mean(miniAUC)));
            SST = sum(sum(sum((miniAUC(:,:)-grandmean).^2))); %AS quality control, we show the total sum of squares which equals SSB + SSW
            %Here we fill the final row in our anova table: the totals
            reliability.SSB(ireg,iwndw,ndim+2,itrial) = SST;%Redord total sum of squares
            reliability.DOFB(ireg,iwndw,ndim+2,itrial) = numel(miniAUC)-1;%total degrees of freedom
            reliability.MSB(ireg,iwndw,ndim+2,itrial) = reliability.SSB(ireg,iwndw,ndim+2)/reliability.DOFB(ireg,iwndw,ndim+2);
            reliability.VAR(ireg,iwndw,ndim+2,itrial) = reliability.MSB(ireg,iwndw,ndim+2);
            
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
                reliability.VAR(ireg,iwndw,idim,itrial) = (MSB-MSW)/(size(miniAUC,2)*size(miniAUC,3));
                reliability.VAR_B(ireg,iwndw,idim,itrial) = var(mean(mean(miniAUC,2),3));%Alternatively, we could just take variance which ignores the snd term in paper's fomrula
                %Another way to calculate the above line: = (MSB)/(size(miniAUC,2)*size(miniAUC,3))
                
                %Using similar formulat from same paper calculate ICC
                reliability.ICC(ireg,iwndw,idim,itrial) = (MSB-MSW)/(MSB+(size(miniAUC,2)*size(miniAUC,3)-1)*MSW);
                reliability.SSB(ireg,iwndw,idim,itrial) = SSB; reliability.SSW(ireg,iwndw,idim,itrial)=SSW; reliability.MSB(ireg,iwndw,idim,itrial)=MSB; reliability.MSW(ireg,iwndw,idim,itrial)=MSW;
                reliability.DOFB(ireg,iwndw,idim,itrial) = DOFB;reliability.DOFW(ireg,iwndw,idim,itrial) = DOFW;
                %At some point calculate Mean square metrics (how to get from MSB
                %to actual variance)
                
                %Now c
                
                miniAUC = permute(miniAUC,[2 3 1]);
            end
            %Now calculate residual sum squares and DOF
            reliability.SSB(ireg,iwndw,ndim+1,itrial) = reliability.SSB(ireg,iwndw,ndim+2,itrial) - sum(reliability.SSB(ireg,iwndw,1:ndim,itrial));
            reliability.DOFB(ireg,iwndw,ndim+1,itrial)= reliability.DOFB(ireg,iwndw,ndim+2,itrial) - sum(reliability.DOFB(ireg,iwndw,1:ndim,itrial));
            reliability.MSB(ireg,iwndw,ndim+1,itrial) = reliability.SSB(ireg,iwndw,ndim+1,itrial)/reliability.DOFB(ireg,iwndw,ndim+1,itrial);
            reliability.VAR(ireg,iwndw,ndim+1,itrial) = reliability.MSB(ireg,iwndw,ndim+1,itrial);
            reliability.VAR_B(ireg,iwndw,ndim+1,itrial) = reliability.MSB(ireg,iwndw,ndim+1,itrial);
            
            
            %         %These lines told us that total vairance (=MSB total doesnt'
            %         acutally equal the sum of other variances :P unless I'm wrong on how to calculate residual variance
            %         reliability.VAR(ireg,iwndw,5)-sum(reliability.VAR(ireg,iwndw,1:ndim))
            %         reliability.VAR(ireg,iwndw,5)-sum(reliability.VAR_ALT(ireg,iwndw,1:ndim))
            
            
            %Fnd SEMeas using formula from Schambra et al
            tempvar= reliability.VAR_B(ireg,iwndw,ndim+1,itrial);%residual variance
            for idim=1:3
                tempvar = tempvar+ reliability.VAR_B(ireg,iwndw,idim,itrial);%add to it the variance of each dim
                reliability.SEM(ireg,iwndw,idim,itrial) = (tempvar)^.5;
                reliability.SDC(ireg,iwndw,idim,itrial) = reliability.SEM(ireg,iwndw,idim,itrial)*2^.5*1.96;
                display(['In ' cfg.regs(ireg).name ' the minimum change in AUC to ensure a change between two ' reliability.AUCdim{2+idim} 's is ' num2str(reliability.SDC(ireg,iwndw,idim,itrial))]);
            end
            
            
        end
    end
end
reliability.ICCdim = {'Split', 'Condition', 'Subject'};
end