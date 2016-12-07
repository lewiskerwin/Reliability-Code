%start with split 1 vs 2
function reliability=lk_pearson(reliability,cfg)

clear axisname cnt
for ireg=1:length(cfg.regs)
    
    axisname{ireg} = cfg.regs(ireg).name;
    
end

PearsonAUC = reliability.AUC;
cnt=1;
FigHandle = figure('Position', [100, 100, 1450, 1200]);
colorbar
colormap jet

for(idim=1:2)%Goes through splits, then through condtions
    
    
    for jdim=1:size(reliability.AUC,5-idim)%Goes through each condition when idim is 1 and each split when idim is 2
        for iwndw=1:size(cfg.peak.wndw,1) %Look at one window
            
            
            for ireg=1:length(cfg.regs)
                for jreg=1:length(cfg.regs)
                    x = reshape(PearsonAUC(ireg,iwndw,1,jdim,:), [], 1);
                    y = reshape(PearsonAUC(jreg,iwndw,2,jdim,:), [], 1);
                    reliability.pearson(ireg,jreg,iwndw,idim,jdim) = corr(x,y);
                end
                
            end
            pearson_summary(:,iwndw) = diag(reliability.pearson(:,:,iwndw,idim,jdim));%This will become the final, summary pearson plot
            
            subplot(size(reliability.AUC,3)+size(reliability.AUC,4),size(reliability.AUC,2)+1,cnt)
            imagesc(reliability.pearson(:,:,iwndw,idim,jdim))
            title (['Pearson Correlation from ' cfg.peak.wndwnames{iwndw} ' ms' ])
            set(gca,'YTickLabel', axisname);
            set(gca,'XTickLabel', axisname);
            set(gca, 'XAxisLocation', 'top');
            xlabel([reliability.AUCdim{5-idim} ' ' num2str(jdim) ' ' reliability.AUCdim{idim+2} ' 1']);
            ylabel([reliability.AUCdim{5-idim} ' ' num2str(jdim) ' ' reliability.AUCdim{idim+2} ' 2']);
            caxis([min(-1) max(1)]);
            cnt=cnt+1;
        end
    
    
    %This adds a summary table (columns are windows, rows are regions)  
    subplot(size(reliability.AUC,3)+size(reliability.AUC,4),size(reliability.AUC,2)+1,cnt)
    imagesc(pearson_summary)
    colorbar
    colormap jet
    TITLE = 'Pearson Correlation Summary Table \n of %s %d between %ss';
    title (sprintf(TITLE,reliability.AUCdim{5-idim},jdim,reliability.AUCdim{idim+2}))
    set(gca,'YTickLabel', axisname,'XTick',1:4,'XTickLabel', cfg.peak.wndwnames);
    set(gca, 'XAxisLocation', 'top');
    xlabel({'Window'});ylabel({'Region'});
    caxis([min(-1) max(1)]);
    cnt=cnt+1;
    end
%     %Adding this in loop to show SEM
%     reliability.SEM(:,:,idim) = reliability.MSB(:,:,idim)
%     
%     reliability.SST(3,4)-sum(reliability.SSB(3,4,:))/13
%     reliability.SST(3,4)
%     
%     subplot(length(wndw)+2,1,length(wndw)+2)
%     imagesc(pearson_summary)
%     colorbar
%     colormap hot
%     title (['Pearson Correlation Summary Table'])
%     set(gca,'YTickLabel', axisname,'XTick',1:4,'XTickLabel', cfg.peak.wndwnames);
%     set(gca, 'XAxisLocation', 'top');
%     xlabel({'Window'});ylabel({'Region'});
%     caxis([min(-1) max(1)]);
    
    
    PearsonAUC = permute(PearsonAUC, [1 2 4 3 5]);
end

end