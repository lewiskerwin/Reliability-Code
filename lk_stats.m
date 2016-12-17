%finitepearson is designed to show correlation between splits, conditions AND
%SUBJECTS. Unlike pearson2 it uses every split,sub,and cond as indvl point.
function reliability=lk_stats(reliablity,cfg,ireg,iwndw,iTI)
 reliability.finitepearson= []; reliability.finitettest =[];

 
statmat = squeeze(reliability.ampauccond(ireg,iwndw,:,:,:,iTI))';
nsub = size(statmat,1);
ndist = size(statmat,2);% represents ncond or nsplit

% width = 3; %This is the width (or number of columns) of multi-plot figure
% %FigHandle = figure('Position', [100, 100, 1450, 1200]);

reliability.ampauccondp (ireg, iwndw, iTI)  = corr(statmat(:,1),statmat(:,2));
[reliability.ampauccondth(ireg, iwndw, iTI),reliability.ampauccondtp(ireg,iwndw,iTI)] = ttest(statmat(:,1),statmat(:,2));
variances = cov(statmat);
reliability.ampauccondccc = 2*variances(1,2)/(variances(1,1)+variances(2,2)+(mean(statmat(:,1))-mean(statmat(:,2)))^2);

%SS TOTAL
grandmean = mean(mean(statmat));
SST = sum(sum((statmat-grandmean).^2))
%SS BETWEEN SUBS
submean = mean(statmat,2);
SSB = sum((submean-grandmean).^2)*ndist;
DOFB = nsub-1;
MSB = SSB/DOFB;
%SS WITHIN SUBS
SSW = sum(sum((statmat-submean).^2 ))
DOFW = nsub * (ndist-1);
MSW = SSW/DOFW;
%disp(sprintf('As QC SSB + SSW - SST should be zero and here is %d',SSB+SSW-SST));

%CACULATE ICC VIA SHOUT EXN
reliability.ampauccondicc(ireg, iwndw, iTI) = (MSB-MSW) / (MSB+(ndist-1)*MSW);

%REPRESENTITVE T TEST
            if (ivar~=jvar & represented==0)
            subplot(3,width,(idim-startdim)*width+1)
            boxplot([x,y]);
            t_value = sprintf('p value = %4.3f',reliability.ttest.p(ivar,jvar,idim,iTI));
           text(1.5,60,t_value)
            %bar([1 2],[mean(x),mean(y)])
%             hold on
%             xloc=ones(size(x)); plot(xloc,x,'*',2*xloc,y,'*');
%             
%               xlabel(sprintf('%s',reliability.aucdim{idim+2}));
%              ylabel(sprintf('Area Under Curve'));
%            hold off
%             %Plot best fit
%             hold on
%             fit_coef = polyfit(x,y,1);
%             yfit=polyval(fit_coef,[axmin axmax]);
%             plot([axmin axmax],yfit);
%             center_x = double(mean([axmin axmax])); center_y = double(polyval(fit_coef,center_x));
%             r_value = sprintf('r = %d',reliability.pearson_2(ivar,jvar,idim,iTI));
%             text(center_x,center_y,r_value)
%             hold off
            
            
            %REPRESENTITIVE SCATTERPLOT
            subplot(3,width,(idim-startdim)*width+2)
            scatter(x,y);
            xlabel(sprintf('%s %d',reliability.aucdim{idim+2},ivar));
            ylabel(sprintf('%s %d',reliability.aucdim{idim+2},jvar));
            axmin= min(cat(1,x,y)); axmax = max(cat(1,x,y));
            axis([axmin,axmax,axmin,axmax]);
            %Plot best fit
            hold on
            fit_coef = polyfit(x,y,1);
            yfit=polyval(fit_coef,[axmin axmax]);
            plot([axmin axmax],yfit);
            center_x = double(mean([axmin axmax])); center_y = double(polyval(fit_coef,center_x));
            r_value = sprintf('r = %d',reliability.finitepearson(ivar,jvar,idim,iTI));
            text(center_x,center_y,r_value)
            hold off
            represented=1;
            else end
            
            
           
 
        end
        
    end
    
    %COLORPLOT OF ALL PEARSON
    subplot(3,width,(idim-startdim)*width+3)
    colormap jet 
    imagesc(squeeze(reliability.finitepearson(:,:,idim,iTI)))
    title ({['Pearson Correlation  between ' reliability.aucdim{idim+2} 's'] ; ['Each pixel represents data points from ' num2str(size(PearsonAUC,1)*size(PearsonAUC,2)) ' region-peak combinations']})
   
    set(gca,'XTick', 1:size(PearsonAUC,startdim),'yTick', 1:size(PearsonAUC,startdim));
    set(gca, 'XAxisLocation', 'top');
    xlabel([reliability.aucdim{idim+2}]);
    ylabel([reliability.aucdim{idim+2}]);
    caxis([min(-1) max(1)]);
    colorbar
    axis([0.5,size(PearsonAUC,startdim)+0.5,0.5,size(PearsonAUC,startdim)+0.5])
    
%     %TTEST
%     subplot(3,width,(idim-startdim)*width+3)
%     colormap jet 
%     imagesc(squeeze(reliability.ttest.h(:,:,idim,iTI)))
%     title ({['Significant Difference by T-Test' reliability.aucdim{idim+2} 's'] ; ['Each pixel represents data points from ' num2str(size(PearsonAUC,1)*size(PearsonAUC,2)) ' region-peak combinations']})
%    
%     set(gca,'XTick', 1:size(PearsonAUC,startdim),'yTick', 1:size(PearsonAUC,startdim));
%     set(gca, 'XAxisLocation', 'top');
%     xlabel([reliability.aucdim{idim+2}]);
%     ylabel([reliability.aucdim{idim+2}]);
%     caxis([min(-1) max(1)]);
%     colorbar
%     axis([0.5,size(PearsonAUC,startdim)+0.5,0.5,size(PearsonAUC,startdim)+0.5])
%     
    
    
    PearsonAUC = permute(PearsonAUC, [2 3 1]);
end
end