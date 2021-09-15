function fig_hands = plotDiffImage(mean_bsline_img,peak_stim_img,diff_img,img_name,...
                                    settings,varargin)
% Plots and saves single frame images output by diffImage (baseline,
% peak, and peak - baseline)
in.cmap = 'inferno';
in.include_plots = [1,2,3];
in.filt_width = 0;
in.formats = {'png'};
in.resolutions = {'-r300'};
in.save_fig = 0;
in.fig_dir = './figs'; % default to current directory
in.fig_settings = {'Units','normalized','Position',[1 0.1667 0.75 0.744],...
                    'Color','k'};
in.cb_settings = {'Color','w','FontSize',14};
in.title_settings = {'Interpreter','none','Color','w'}; 

in = sl.in.processVarargin(in,varargin); 
if in.filt_width > 0
    filt_str = sprintf('filter window %g',in.filt_width);
else
    filt_str = 'filtering off';
end

%% Plot
fig_hands = {}; 
if any(in.include_plots==1) % Mean baseline image
    fig = figure(in.fig_settings{:});
    % subplot(3,1,1);
    title_str = sprintf('%s: Mean baseline (frames %g to %g), %s',img_name,...
                        settings.baseline_wind_inds(1),settings.baseline_wind_inds(end),...
                        filt_str);
    plot_img(mean_bsline_img,title_str,in.cmap,in.cb_settings,in.title_settings);            
    fig_hands = [fig_hands,fig];
    fig_name = sprintf('bsline_meanF_%g-%g',settings.baseline_wind_inds(1),...
                                           settings.baseline_wind_inds(end));   
    fig.Name = fig_name; % assign name to fig for external use
    if in.save_fig
        printFig(fig,in.fig_dir,fig_name,'formats',in.formats,'resolutions',in.resolutions)
    end
end
if any(in.include_plots==2) % Peak image
    % subplot(3,1,2);
    fig = figure(in.fig_settings{:});
    title_str = sprintf('%s: Peak during stim (frames %g to %g), %s',img_name,...
                        settings.stim_wind_inds(1),settings.stim_wind_inds(end),filt_str);    
    plot_img(peak_stim_img,title_str,in.cmap,in.cb_settings,in.title_settings);            
    fig_hands = [fig_hands,fig];
    fig_name = sprintf('peakF_%g-%g',settings.stim_wind_inds(1),...
                                    settings.stim_wind_inds(end));
    fig.Name = fig_name; % assign name to fig for external use
    if in.save_fig
        printFig(fig,in.fig_dir,fig_name,'formats',in.formats,...
                 'resolutions',in.resolutions)
    end
end
if any(in.include_plots==3) % Difference image
    % subplot(3,1,3);
    fig = figure(in.fig_settings{:});
    title_str = sprintf('%s: Peak - mean baseline, %s',img_name,filt_str);
    plot_img(diff_img,title_str,in.cmap,in.cb_settings,in.title_settings);        
    fig_hands = [fig_hands,fig];
    fig_name = sprintf('peakF-bslineF_%g-%g_%g-%g',settings.baseline_wind_inds(1),...
                        settings.baseline_wind_inds(end),...
                        settings.stim_wind_inds(1),...
                        settings.stim_wind_inds(end));
    fig.Name = fig_name; % assign name to fig for external use
    if in.save_fig
        printFig(fig,in.fig_dir,fig_name,'formats',in.formats,'resolutions',in.resolutions)
    end
end
end
function plot_img(vals,title_str,cmap,cb_settings,title_settings)
    imagesc(vals)
    ax = gca; 
    axis(ax,'equal','off'); hold(ax,'on'); 
    colormap(cmap); 
    colorbar(cb_settings{:});
    axis([0 size(vals,2) 0 size(vals,1)]);
    title(title_str,title_settings{:}); 
end