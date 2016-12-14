%finitepearson is designed to show correlation between splits, conditions AND
%SUBJECTS. Unlike pearson2 it uses every split,sub,and cond as indvl point.
function reliability=lk_finitepearson(reliability,cfg,ireg,iwndw,iTI)
 reliability.finitepearson= []; reliability.finitettest =[];

 
PearsonAUC = squeeze(reliability.ampauc(ireg,iwndw,:,:,:,iTI));
width = 3; %This is the width (or number of columns) of multi-plot figure
%FigHandle = figure('Position', [100, 100, 1450, 1200]);

startdim=1;
for idim=startdim:3
    %axisname{idim} = cfg.regs(ireg).name;
    axisname = cfg.file.subs;
    %So I want to compare the four windows and six regions as 24 data points!
    represented=0;
    for ivar=1:size(PearsonAUC,startdim)%Go through splits, conds, subs
        for jvar=1:size(PearsonAUC,startdim)
            x = reshape(PearsonAUC(ivar,:,:), [], 1);
            y = reshape(PearsonAUC(jvar,:,:), [], 1);
            reliability.finitepearson(ivar,jvar,idim,iTI) = corr(x,y);
            [reliability.finitettest.h(ivar,jvar,idim,iTI),reliability.ttest.p(ivar,jvar,idim,iTI)]= ttest(x,y);
            variances = cov(x,y);
            reliability.finiteCCC(ivar,jvar,ireg,iwndw,idim,iTI)= 2*variances(1,2)/(variances(1,1)+variances(2,2)+(mean(x)-mean(y))^2);
           % disp(sprintf('between %s %d and %d CCC is %s,reliability.aucdim{idim+2},ivar,jvar,reliability.CCC(ivar,jvar,idim,iTI)'));
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