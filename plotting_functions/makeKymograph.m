function makeKymograph(recording,line_roi,sampling_rate,varargin)
%MAKEKYMOGRAPH ... 
%  
%   Inputs 
%   ------ 
%   recording : Recording object
%   sampling_rate : scalar
%                 sampling rate in frames per second

%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if ~recording.loaded
    recording.load(); 
end
vals = recording.vals; 
pixel_size = recording.pixel_size; 
in.start_frame = 1;
in.end_frame = size(vals,3);
in.stim_vals1 = [];
in.stim_pulse_dur1 = [];
in.stim_vals2 = [];
in.stim_pulse_dur2 = []; 
in.t_rel_stim = 2; % 1 - make time relative to stim 1, 2 - make time relative to stim2
% Temporal filter
in.mov_ave_window = 0; 
% Spatial filter
in.filt_size = []; 
in.filt_sigma = []; 
in.roi_ind = 1; % index of ROI within ROIs (RoiSet)
in.log_scale = 0; 
in.show_frame = 1;
% Plot settings
in.stim1_y=0.05; 
in.stim2_y=0.02; 
in.sbar_len = 5; % microns
in.sbar_x_factor = 0.7;
in.sbar_y_factor = 0.2;
in.sbar_text_x_factor = 1.2;
in.colormap = 'inferno';
in.cax_lims = []; 
in.fig_units = 'inches';
in.fig_size = [];
in.font_size = 16; 
in.point_marker_size = 12;
in.save_figs = 0;
in.fig_fold = '.';
in.fig_name = '';
in = sl.in.processVarargin(in,varargin);
%% Clip movie by ROI
vals = vals(:,:,in.start_frame:in.end_frame);
num_frames = size(vals,3);
% Spatial Filter
if ~isempty(in.filt_size) && in.filt_size > 0
    vals = spatialFilter(vals,in.filt_size,in.filt_sigma);
end
%% Get time values
t = (0:num_frames-1)'/sampling_rate;
% Convert stim times (sec) to frames
stim_vals1 = sort(in.stim_vals1(:)*sampling_rate,'ascend'); % linearize stim defined in multiple rows (trains)
stim_vals2 = sort(in.stim_vals2(:)*sampling_rate,'ascend');
% stim_pulse_dur1 = in.stim_pulse_dur1*sampling_rate; 
% stim_pulse_dur2 = in.stim_pulse_dur2*sampling_rate;
% remove stimuli outside of included frames
stim_vals1 = stim_vals1(stim_vals1>=in.start_frame & stim_vals1 <=in.end_frame); 
stim_vals2 = stim_vals2(stim_vals2>=in.start_frame & stim_vals2 <=in.end_frame);
stim_vals1 = stim_vals1 - in.start_frame+1; % relative to first included frame
stim_vals2 = stim_vals2 - in.start_frame+1; 
if in.t_rel_stim == 1
    t = t-t(stim_vals1(1));
elseif in.t_rel_stim == 2
    t = t-t(stim_vals2(1));
end
%% Extract values along ROI
if ischar(line_roi)
    line_roi = ROIs(line_roi);
end
% extract first frame to get dimensions
[x,y,F] = improfile(vals(:,:,1),line_roi.x{in.roi_ind},line_roi.y{in.roi_ind});
F_all = repmat(F,1,num_frames); % num_points x num_frames 
for i = 2:num_frames
    [~,~,Fi] = improfile(vals(:,:,i),...
                    line_roi.x{in.roi_ind},line_roi.y{in.roi_ind});
    if in.mov_ave_window > 1
        Fi = smooth(Fi,in.mov_ave_window,'moving');
    end
    F_all(:,i) = Fi;
end

% Convert to log scale
if in.log_scale
    F_all = log10(F_all);
end
% Get colorscale
if isempty(in.cax_lims)
    % cax_lims = [min(vals,[],'all'),max(vals,[],'all')];
    cax_lims = [quantile(F_all(:),0.05),quantile(F_all(:),0.999)];
else
    cax_lims = in.cax_lims; 
end
if strcmp(in.colormap,'inferno')
    cmap = inferno(1000);
end
% Convert pixel coordinates to distance in microns
r = sqrt(x.^2 + y.^2);
r = r-r(end); 
r_um = r*pixel_size; % convert to um
%% Plot
fig = figure('Units',in.fig_units);
if ~isempty(in.fig_size)
    fig.Position(3:4) = in.fig_size; 
end
imagesc('YData',r_um,'XData',t,'CData',F_all)
ax = gca;
ax.YDir = 'reverse';
ax.XLim = [t(1),t(end)];
ax.YLim = [r_um(end)-range(r_um)*0.05,r_um(1)+range(r_um)*0.05];
hold on;
xlabel('time (sec)');
ylabel('Distance (\mu m)');
cb = colorbar('FontSize',in.font_size);
if in.log_scale
    cb.Label.String = 'log( F )';
else
    cb.Label.String = 'F (a.u.)';
end
cb.Label.Rotation = -90;
% cb.Label.Interpreter = 'latex';
if ~isempty(stim_vals1)
    % plot(ax,t(stim_vals1),ax.YLim(1) + range(ax.YLim)*in.stim1_y*ones(1,length(stim_vals1)),...
    %     'LineStyle','none','Color','r','Marker','.','MarkerSize',in.point_marker_size);
     plot(ax,[t(stim_vals1)';t(stim_vals1)';nan(size(stim_vals1'))],...
            [ax.YLim'.*[1;0.99].*ones(2,length(stim_vals1'));nan(size(stim_vals1'))],...
            'Color','w','LineStyle','--','LineWidth',1);
end
if ~isempty(stim_vals2)
    plot(ax,[t(stim_vals2)';t(stim_vals2)'+in.stim_pulse_dur2;nan(size(stim_vals2'))],...
          [ax.YLim(1)+range(ax.YLim).*[in.stim2_y;in.stim2_y].*ones(2,length(stim_vals2'));nan(size(stim_vals2'))],...
            'Color','k','LineStyle','-','LineWidth',2);
end
clim(ax,cax_lims);
colormap(ax,cmap);
if in.save_figs
    if isempty(in.fig_name)
        in.fig_name = sprintf('kymo_%s_%s_f%g-%g_log%g_avewind%g',recording.img_name,...
            line_roi.roiset_filename,in.start_frame,in.end_frame,in.log_scale,...
            in.mov_ave_window);
    end
    printFig(fig,in.fig_fold,in.fig_name);
end
%% Plot image and ROI
x_range = round([min(x),max(x)]);
y_range = round([min(y),max(y)]);
vals_crop = vals(y_range(1):y_range(2),x_range(1):x_range(2),:);
x_c = x - x_range(1)+1;
y_c = y - y_range(1)+1;
fig2 = figure('Units','inches'); 
fig2.Position(4)= in.fig_size(2);
imagesc(vals_crop(:,:,in.show_frame));
hold on;
plot(x_c,y_c,'--','Color','y');
ax = gca;
ax.YDir = 'normal';
axis(ax,'equal','tight','off');
colormap(ax,cmap);
clim(ax,[quantile(vals_crop(:,:,in.show_frame),0.05,'all'),quantile(vals_crop(:,:,in.show_frame),0.9999,'all')]);
if in.sbar_len > 0
    addScaleBar(recording.pixel_size,size(vals_crop,[1 2]),ax,'sbar_len',in.sbar_len,...
        'x_factor',in.sbar_x_factor,'y_factor',in.sbar_y_factor,...
        'sbar_orientation','vert','text_x_factor',in.sbar_text_x_factor);
end
if in.save_figs
    in.fig_name2 = sprintf('kymo_img_%s_%s_f%g',recording.img_name,...
            line_roi.roiset_filename,in.show_frame);
    printFig(fig2,in.fig_fold,in.fig_name2);
end
end