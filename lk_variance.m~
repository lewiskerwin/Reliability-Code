function reliability = lk_variance(reliability, cfg)

clear reliability.ICC
for ireg = 1:size(reliability.AUC,1) %Go through 6 regions
    for iwndw = 1:size(reliability.AUC,2) %go through 4 windows
        clear miniAUC tdAUC grandmean %Clear the table that will get rid of dimensions with 1 element, and 2D table
        %Reminder: dimensions of AUC are: reg, wndw, split, cond, sub
        miniAUC = squeeze(reliability.AUC(ireg,iwndw,:,:,:)); %Let's look only at non-one dimensions: split, condition and subject
        ndim = ndims(miniAUC);
        grandmean = mean(mean(mean(miniAUC)));
        SST = sum(sum(sum((miniAUC(:,:)-grandmean).^2))); %AS quality control, we show the total sum of squares which equals SSB + SSW
        %Here we fill the final row in our anova table: the totals
        reliability.SSB(ireg,iwndw,ndim+2) = SST;%Redord total sum of squares
        reliability.DOFB(ireg,iwndw,ndim+2) = numel(miniAUC)-1;%total degrees of freedom
        reliability.MSB(ireg,iwndw,ndim+2) = reliability.SSB(ireg,iwndw,ndim+2)/reliability.DOFB(ireg,iwndw,ndim+2);
        reliability.VAR(ireg,iwndw,ndim+2) = reliability.MSB(ireg,iwndw,ndim+2);
        
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
            reliability.VAR(ireg,iwndw,idim) = (MSB-MSW)/(size(miniAUC,2)*size(miniAUC,3));
            reliability.VAR_B(ireg,iwndw,idim) = var(mean(mean(miniAUC,2),3));%Alternatively, we could just take variance which ignores the snd term in paper's fomrula
            %Another way to calculate the above line: = (MSB)/(size(miniAUC,2)*size(miniAUC,3))
            
            %Using similar formulat from same paper calculate ICC 
            reliability.ICC(ireg,iwndw,idim) = (MSB-MSW)/(MSB+(size(miniAUC,2)*size(miniAUC,3)-1)*MSW);
            reliability.SSB(ireg,iwndw,idim) = SSB; reliability.SSW(ireg,iwndw,idim)=SSW; reliability.MSB(ireg,iwndw,idim)=MSB; reliability.MSW(ireg,iwndw,idim)=MSW;
            reliability.DOFB(ireg,iwndw,idim) = DOFB;reliability.DOFW(ireg,iwndw,idim) = DOFW;
            %At some point calculate Mean square metrics (how to get from MSB
            %to actual variance)
            
            %Now c
                       
            miniAUC = permute(miniAUC,[2 3 1]);
        end
        %Now calculate residual sum squares and DOF
        reliability.SSB(ireg,iwndw,ndim+1) = reliability.SSB(ireg,iwndw,ndim+2) - sum(reliability.SSB(ireg,iwndw,1:ndim));
        reliability.DOFB(ireg,iwndw,ndim+1)= reliability.DOFB(ireg,iwndw,ndim+2) - sum(reliability.DOFB(ireg,iwndw,1:ndim));
        reliability.MSB(ireg,iwndw,ndim+1) = reliability.SSB(ireg,iwndw,ndim+1)/reliability.DOFB(ireg,iwndw,ndim+1);
        reliability.VAR(ireg,iwndw,ndim+1) = reliability.MSB(ireg,iwndw,ndim+1);
        reliability.VAR_B(ireg,iwndw,ndim+1) = reliability.MSB(ireg,iwndw,ndim+1);
        
        
%         %These lines told us that total vairance (=MSB total doesnt'
%         acutally equal the sum of other variances :P unless I'm wrong on how to calculate residual variance 
%         reliability.VAR(ireg,iwndw,5)-sum(reliability.VAR(ireg,iwndw,1:ndim))
%         reliability.VAR(ireg,iwndw,5)-sum(reliability.VAR_ALT(ireg,iwndw,1:ndim))
        
        
        %Fnd SEMeas using formula from Schambra et al
        tempvar= reliability.VAR_B(ireg,iwndw,ndim+1);%residual variance
        for idim=1:3
           tempvar = tempvar+ reliability.VAR_B(ireg,iwndw,idim);%add to it the variance of each dim
           reliability.SEM(ireg,iwndw,idim) = (tempvar)^.5;
           reliability.SDC(ireg,iwndw,idim) = reliability.SEM(ireg,iwndw,idim)*2^.5*1.96;
           display(['In ' cfg.regs(ireg).name ' the minimum change in AUC to ensure a change between two ' reliability.AUCdim{2+idim} 's is ' num2str(reliability.SDC(ireg,iwndw,idim))]);
        end
        
       
    end
end
reliability.ICCdim = {'Region', 'Window', '1=sub, 2=cond, 3=reg'};