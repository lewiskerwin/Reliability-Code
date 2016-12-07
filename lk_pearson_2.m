%Pearson_2 is designed to show correlation between splits, conditions AND
%SUBJECTS. Rather than using each subject as a data point, it uses each
%region-window combination as a data point (24 per distribution).
function reliability=lk_pearson_2(reliability,cfg)

PearsonAUC = reliability.AUC;

%FigHandle = figure('Position', [100, 100, 1450, 1200]);

startdim=3;
for idim=startdim:5
    %axisname{idim} = cfg.regs(ireg).name;
    axisname = cfg.file.subs;
    %So I want to compare the four windows and six regions as 24 data points!
    for ivar=1:size(PearsonAUC,startdim)%Go through subs
        for jvar=1:size(PearsonAUC,startdim)
            x = reshape(mean(mean(PearsonAUC(:,:,ivar,:,:),5),4), [], 1);
            y = reshape(mean(mean(PearsonAUC(:,:,jvar,:,:),5),4), [], 1);
            reliability.pearson_2(idim,ivar,jvar) = corr(x,y);
        end
        
    end
    
    %pearson_summary(:,iwndw) = diag(reliability.pearson(:,:,iwndw,idim,jdim));%This will become the final, summary pearson plot
%     clear tickname
%     if idim ==3
%        tickname = cfg.file.subs;
%     else tickname = num2str(1:size(PearsonAUC,startdim));
%     end
    
    
    subplot(3,1,idim-startdim+1)

    colormap jet
    
    imagesc(squeeze(reliability.pearson_2(idim,:,:)))
    title ({['Pearson Correlation  between ' reliability.AUCdim{idim} 's'] ; ['Each pixel represents data points from ' num2str(size(PearsonAUC,1)*size(PearsonAUC,2)) ' region-peak combinations']})
    
    
    set(gca,'XTick', 1:size(PearsonAUC,startdim),'yTick', 1:size(PearsonAUC,startdim));
    if idim == 5    set(gca,'XTickLabel',cfg.file.subs,'yTickLabel', cfg.file.subs);
    else           set(gca,'XTickLabelMode','auto');
    end
    set(gca, 'XAxisLocation', 'top');
    xlabel([reliability.AUCdim{idim}]);
    ylabel([reliability.AUCdim{idim}]);
    caxis([min(-1) max(1)]);
    colorbar
    axis([0.5,size(PearsonAUC,startdim)+0.5,0.5,size(PearsonAUC,startdim)+0.5])
   
%     
%     %This adds a summary table (columns are windows, rows are regions)
%     subplot(size(reliability.AUC,3)+size(reliability.AUC,4),size(reliability.AUC,2)+1,cnt)
%     imagesc(pearson_summary)
%     colorbar
%     colormap jet
%     TITLE = 'Pearson Correlation Summary Table \n of %s %d between %ss';
%     title (sprintf(TITLE,reliability.AUCdim{5-idim},jdim,reliability.AUCdim{idim+2}))
%     set(gca,'YTickLabel', axisname,'XTick',1:4,'XTickLabel', cfg.peak.wndwNames);
%     set(gca, 'XAxisLocation', 'top');
%     xlabel({'Window'});ylabel({'Region'});
%     caxis([min(-1) max(1)]);
%     cnt=cnt+1;
%     
    
    PearsonAUC = permute(PearsonAUC, [1 2 4 5 3]);
end
end