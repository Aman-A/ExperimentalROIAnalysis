function addROIoverlayAndSave(fig_hands,rois,save_fig,fig_dir,img_name,...
                               close_after_save,show_roi_labels)
for i = 1:length(fig_hands)
    ax = fig_hands(i).Children(end);    
    rois.plot('y',ax,0); % plot starting
    rois.plot('g',ax,1,show_roi_labels); % plot current after shift    
%     rois.plot(jet(rois.num_rois),ax,1,show_roi_labels); % plot current after shift    
    drawnow; 
    if save_fig  % Save images with ROI overlays (if exist)
        printFig(fig_hands(i),fig_dir,[img_name,'_',fig_hands(i).Name],...
            'formats','png','resolutions','-r300')
        if close_after_save
            close(fig_hands(i));
        end
    end
end
end