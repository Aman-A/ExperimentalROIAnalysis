function lgi1_data = analyzeLGI1pHmScarletTrial(img_name,exp_settings,roiset_filename,...
                                    background_roiset_filename,varargin)

in = plotTrialSettings('plot_func','none','show_diff_image',1,...
                        'funcs',{'mean','median'});
in = sl.in.processVarargin(in,varargin);
% in.load_processed_data = 0; 
%
in.rem_pbleach = 0; % incompatible with LGI1 trials
lgi1_rois = plotTrial(img_name,exp_settings,roiset_filename,[],in);

if isempty(background_roiset_filename)
    background_roiset_filename = [roiset_filename '_background']; 
end

lgi1_bg =  plotTrial(img_name,exp_settings,background_roiset_filename,[],in);

if in.save_processed_data
    % Save
    dish_fold = fullfile(in.data_fold,in.exp_date,in.reporter,in.dish);
    lgi1_data = struct('data',lgi1_rois,'background',lgi1_bg,'plot_settings',in);
    roiset_filename_no_exti = getROIset_name(roiset_filename,...
                                             in.transform_type,...
                                             in.registration_rec);  
    lgi1_datafile = sprintf('%s_%s_%s_%s_%s_%s_%s',in.exp_date,...
                                in.reporter,in.dish,...
                                in.roi_func_mode,...
                                roiset_filename_no_exti,...
                                in.condition,img_name);       
    lgi1_datafilepath = fullfile(dish_fold,lgi1_datafile);            
    save(lgi1_datafilepath,'-STRUCT','lgi1_data');
    fprintf('Saved LGI1 data to %s\n',lgi1_datafile);
end
if ~isempty(in.show_diff_image) && all(in.show_diff_image ~= 0)
   % Plot settings
    in.cmap = 'inferno';
    in.formats = {'png'};
    in.resolutions = {'-r300'};
    in.fig_settings = {'Units','normalized','Position',[0 0.1667 0.75 0.744],...
        'Color','k'};
    in.cb_settings = {'Color','w','FontSize',14};
    in.title_settings = {'Interpreter','none','Color','w'};
    in.cax_mode = 'quantile'; % 'quantile', 'abs', or 'auto'
    in.cax_lims = [0.02 0.998]; % color limits, units defined in cax_mode
    % Plot
    normF_img = lgi1_rois.mean_bsline_img/mean(lgi1_bg.func_output.mean);
    fig = figure(in.fig_settings{:});
    imagesc(normF_img)
    ax = gca;
    axis(ax,'equal','off'); hold(ax,'on');
    colormap(ax,in.cmap);
    colorbar(ax, in.cb_settings{:});
    axis(ax,[0 size(normF_img,2) 0 size(normF_img,1)]);
    title(ax,'LGI1 fluorescence normalized to background',in.title_settings{:});
    if strcmp(in.cax_mode,'quantile')
        caxis(ax,quantile(normF_img(:),in.cax_lims))
    elseif strcmp(in.cax_mode,'abs')
        caxis(ax,in.cax_lims);
    end % if cax_mode 'auto', leave as is
    if ~isempty(in.pixel_size)
        % get integer length (µm) and convert back to pixels
        addScaleBar(in.pixel_size,size(normF_img),ax,...
            'Color',in.cb_settings{find(strcmp('Color',in.cb_settings))+1})
    end
    ax.YDir = 'normal';
    lgi1_rois.rois.plot('g',ax,1,1);
    lgi1_bg.rois.plot('w',ax,1,1);
    if in.save_fig
        roiset_filename_no_ext = getROIset_name(roiset_filename,...
            in.transform_type,...
            in.registration_rec);
        printFig(fig,fullfile(in.data_fold,in.exp_date,in.reporter,in.dish,...
            in.condition,['figs_' roiset_filename_no_ext]),...
            [lgi1_rois.recording.img_name '_' 'normbg'],...
            'formats',in.formats,'resolutions',in.resolutions);
    end
end
end
