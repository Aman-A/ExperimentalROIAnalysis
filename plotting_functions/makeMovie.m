function makeMovie(recording,sampling_rate,output_file,varargin)
%MAKEMOVIE ... 
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
if isa(recording,'Recording')
    if ~recording.loaded
        recording.load(); 
    end
    vals = recording.vals;     
    in.pixel_size = recording.pixel_size; 
elseif isnumeric(recording)
    vals = recording; 
else
    error('recording must be Recording object or direct input of image stack')
end
in.video_profile = 'MPEG-4';
in.start_frame = 1;
in.end_frame = size(vals,3);
in.ROI = [1, size(vals,1),1, size(vals,2)]; % [lower y, upper y, left x, right x]
in.movie_slow_down_factor = 0.5; % movie_slow_down_factor *sampling rate = frames per second 
                                 % (e.g. for 1 kHz recording, 0.01 gives 10 fps)
in.sbar_len = 5; % microns
in.sbar_x_factor = 0.7;
in.sbar_y_factor = 0.2;
in.sbar_text_x_factor = 1.2;
in.sbar_text_y_factor = []; 
in.sbar_color = 'w';
in.sbar_show_text = 1; 
in.rotate_movie = 0; % 
in.stim_vals1 = []; % stim times in sec
in.stim_pulse_dur1 = [];
in.stim1_x = 0.05; 
in.stim1_y = 0.9; 
in.stim1_marker = 'o';
in.stim1_marker_size = 16;
in.stim_vals2 = []; % stim times in sec
in.stim_pulse_dur2 = []; 
in.stim2_x = 0.05; 
in.stim2_y = 0.75; 
in.stim2_marker = 'DC on';
in.rois = []; 
% Plot settings
in.colormap = 'inferno';
in.cax_lims = []; 
in.gamma_fac = 1; % gamma factor for mapping of fluorescence values to colormap
in.fig_units = 'inches';
in.fig_size = [];
in.YDir = 'normal';
in.filt_size = []; 
in.filt_sigma = []; 
in.time_text_x = 0.05; % factor of XLim to place time text
in.time_text_y = 0.05; % factor of YLim to place time text
in.time_color = 'w';
in.font_size = 16; 
in.t_rel_stim = 2; % 1 - make time relative to stim 1, 2 - make time relative to stim2
in.show_time_str = 1; 
in.pixel_size = []; % input if not using Recording object
in.mask = []; 
in.plot_mode = 'imagesc'; % 'imagesc' or 'surf'
in.show_colorbar = 0; 
in = sl.in.processVarargin(in,varargin);

%% Crop movie by ROI
vals = vals(in.ROI(3):in.ROI(4),in.ROI(1):in.ROI(2),in.start_frame:in.end_frame);
if ~isempty(in.mask) % crop mask as well
    in.mask = in.mask(in.ROI(3):in.ROI(4),in.ROI(1):in.ROI(2));
end
num_frames = size(vals,3);
% Filter
if ~isempty(in.filt_size) && in.filt_size > 0
    vals = spatialFilter(vals,in.filt_size,in.filt_sigma);
    fprintf('Applied spatial filter with size %g, width %g\n',in.filt_size,in.filt_sigma);
end
% Gamma correction
if in.gamma_fac ~= 1
    vals = vals.^in.gamma_fac;
    fprintf('Applied %g gamma factor\n',in.gamma_fac);
end
% Get colorscale
if isempty(in.cax_lims)
    % cax_lims = [min(vals,[],'all'),max(vals,[],'all')];
    cax_lims = [quantile(vals(:),0.05),quantile(vals(:),0.9999)];
else
    cax_lims = in.cax_lims; 
end
% Get time values
t = (0:num_frames-1)'/sampling_rate;
% Convert stim times (sec) to frames
stim_vals1 = sort(in.stim_vals1(:)*sampling_rate,'ascend'); % linearize stim defined in multiple rows (trains)
stim_vals2 = sort(in.stim_vals2(:)*sampling_rate,'ascend');
stim_pulse_dur1 = in.stim_pulse_dur1*sampling_rate; 
stim_pulse_dur2 = in.stim_pulse_dur2*sampling_rate;
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
%% Make movie
if strcmp(in.colormap,'inferno')
    cmap = inferno(1000);
elseif strcmp(in.colormap,'bluewhitered')
    cmap = bluewhitered(1000,[],'lims',cax_lims);
end
fig = figure('Units',in.fig_units); 
fig.Position(1:2) = [0.5 0.5];
if ~isempty(in.fig_size)
    fig.Position(3:4) = in.fig_size; 
end
frames = struct('cdata',[],'colormap',[]);
ax = gca;
last_stim1 = -inf; last_stim2 = -inf; 
added_ps1 = 0; added_ts2 = 0; %flag after adding markers for stim 1 and stim 2
for i = 1:num_frames
    % cla(ax);
    valsi = vals(:,:,i);
    % Mask if input mask
    if ~isempty(in.mask)
        valsi(~in.mask) = nan;
    end
    if strcmp(in.plot_mode,'imagesc')
        if i == 1
            I = imagesc(ax,valsi); 
        else
             I.CData = valsi; 
        end
    else
        if i == 1
            S = surf(ax,zeros(size(valsi)),valsi,'EdgeColor','none');
            ax.View = [0 90];
        else
            S.CData = valsi; 
        end
    end
    hold on;
    axis(ax,'equal','tight','off');
    clim(ax,cax_lims);
    if i == 1
        if strcmp(in.colormap,'bluewhitered') || strcmp(in.colormap,'bwr')
            cmap = bluewhitered(1000);
        elseif strcmp(in.colormap,'coolwarm')
            cmap = coolwarm(1000);
        end    
    end
    colormap(ax,cmap);
    ax.YDir = in.YDir;    
    if in.show_colorbar
        colorbar; 
    end
    if in.show_time_str
        if i == 1
            time_str = text(ax.XLim(1)+diff(ax.XLim)*in.time_text_x,ax.YLim(1) + diff(ax.YLim)*in.time_text_y,...
                    sprintf('t = %.2f sec',t(i)),'Color',in.time_color,...
                    'FontSize',in.font_size);
        else
            time_str.String = sprintf('t = %.2f sec',t(i));
        end
    end
    if ~isempty(stim_vals1)
        if any(i==stim_vals1)
            last_stim1 = i;
        end    
        if i >= last_stim1 && i <= last_stim1 + stim_pulse_dur1
            if ~added_ps1
                ps1 = plot(ax.XLim(1)+diff(ax.XLim)*in.stim1_x,ax.YLim(1) + diff(ax.YLim)*in.stim1_y,...
                     'Marker',in.stim1_marker,'Color',in.time_color,...
                     'MarkerSize',in.stim1_marker_size,'MarkerFaceColor',in.time_color);
                added_ps1 = 1; 
            else
                ps1.Visible = 'on';
            end
        elseif added_ps1
            ps1.Visible = 'off';
        end
    end
    if ~isempty(stim_vals2)
        if any(i == stim_vals2)
            last_stim2 = i;
        end
        if i >= last_stim2 && i <= last_stim2 + stim_pulse_dur2
            if ~added_ts2
                ts2 = text(ax.XLim(1)+diff(ax.XLim)*in.stim2_x,ax.YLim(1) + diff(ax.YLim)*in.stim2_y,...
                     in.stim2_marker,'FontSize',in.font_size,'Color',in.time_color,'FontWeight','bold');
                added_ts2 = 1;
            else
                ts2.Visible = 'on';
            end
        elseif added_ts2
            ts2.Visible = 'off';
        end
    end
    if in.sbar_len > 0 && i == 1
        if isempty(in.pixel_size)
            in.pixel_size = recording.pixel_size;
        end
        addScaleBar(in.pixel_size,size(vals,[1 2]),ax,'sbar_len',in.sbar_len,...
                    'x_factor',in.sbar_x_factor,'y_factor',in.sbar_y_factor,...
                    'sbar_orientation','vert','text_x_factor',in.sbar_text_x_factor,...
                    'text_y_factor',in.sbar_text_y_factor,'color',in.sbar_color,...
                    'show_text',in.sbar_show_text);
    end
    if ~isempty(in.rois) && i == 1
        in.rois.plot('y',ax,1,0);
    end
    drawnow;    
    frames(i) = getframe(ax);        
end
%% Save movie
v = VideoWriter(output_file,in.video_profile);
v.FrameRate = in.movie_slow_down_factor*sampling_rate; 
open(v); 
for i = 1:num_frames
    % fprintf('%g, %g x %g\n',i,size(frames(i).cdata,1),size(frames(i).cdata,2));
    writeVideo(v,frames(i));
end
close(v); 
fprintf('Saved movie to %s\n',output_file);
end
