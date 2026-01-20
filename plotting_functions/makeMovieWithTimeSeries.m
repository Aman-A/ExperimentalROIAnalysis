function makeMovieWithTimeSeries(recording, rois, exp_settings, output_file, varargin)
% makeMovieWithTimeSeries
% Creates a movie with (top) imaging frames and (bottom) ROI fluorescence traces
% scrolling through time, with a "current time" vertical line centered in the window.
%
% Inputs
%   recording    : Recording object OR numeric image stack (rows x cols x T)
%   rois         : ROIs object (your custom class)
%   exp_settings : struct with field exp_settings.sampling_rate (frames/sec), passed to calcROIfuncs
%   output_file  : output video filename (e.g. 'out.mp4')
%
% Optional name/value via varargin: see defaults below.

% ---------- sampling rate ----------
sampling_rate = exp_settings.sampling_rate;

% ---------- inputs / defaults ----------
if isa(recording,'Recording')
    if ~recording.loaded
        recording.load();
    end
    rec  = recording;
    vals = recording.vals;
    in.pixel_size = recording.pixel_size;
elseif isnumeric(recording)
    rec  = [];
    vals = recording;
    in.pixel_size = [];
else
    error('recording must be a Recording object or a numeric image stack');
end

in.video_profile = 'MPEG-4';
in.start_frame = 1;
in.end_frame   = size(vals,3);
in.ROI         = [1, size(vals,1), 1, size(vals,2)]; % [lower y, upper y, left x, right x]
in.movie_slow_down_factor = 0.5;
in.target_fps = 50;   % desired output video FPS (independent of slow_down)

% Scale bar
in.sbar_len = 5; % microns
in.sbar_x_factor = 0.7;
in.sbar_y_factor = 0.2;
in.sbar_text_x_factor = 1.2;
in.sbar_text_y_factor = [];
in.sbar_color = 'w';
in.sbar_show_text = 1;

% Stim (same schema)
in.stim_vals1 = []; in.stim_pulse_dur1 = []; in.stim1_x = 0.05; in.stim1_y = 0.9;
in.stim1_marker = 'o'; in.stim1_marker_size = 16;
in.stim_vals2 = []; in.stim_pulse_dur2 = []; in.stim2_x = 0.05; in.stim2_y = 0.75;
in.stim2_marker = 'DC on';
in.t_rel_stim = 2;

% Plot settings
in.colormap = 'inferno';
in.cax_lims = [];
in.gamma_fac = 1;
in.fig_units = 'inches';
in.fig_size  = [];
in.YDir = 'normal';
in.filt_size = [];
in.filt_sigma = [];
in.time_text_x = 0.05;
in.time_text_y = 0.05;
in.time_color = 'w';
in.time_color2 = 'w';
in.font_size = 16;
in.show_time_str = 1;
in.mask = [];
in.plot_mode = 'imagesc';
in.show_colorbar = 0;

% Time series settings
in.ts_win_sec         = 10;
in.ts_offset_factor   = 1.2;
in.ts_line_width      = 1.5;
in.ts_show_stim_lines = 1;
in.ts_sbar_len = 0.5; % in data units (e.g., ΔF/F0)

% Parse varargin (uses your helper)
in = sl.in.processVarargin(in,varargin);


% ---------- crop movie ----------
vals = vals(in.ROI(3):in.ROI(4), in.ROI(1):in.ROI(2), in.start_frame:in.end_frame);
if ~isempty(in.mask)
    in.mask = in.mask(in.ROI(3):in.ROI(4), in.ROI(1):in.ROI(2));
end
num_frames = size(vals,3);

% ---------- crop ROIs and compute time series (deltaF/F0) ----------
rois_crop = rois.copy(); 
inside_ROI = rois_crop.x>in.ROI(1) & rois_crop.x<in.ROI(2) & rois_crop.y>in.ROI(3) & rois_crop.y<in.ROI(4); 
rois_crop.shift([-in.ROI(1),-in.ROI(3)]);
rois_crop.removeROIs(~inside_ROI)

func_out = calcROIfuncs(rec, rois, {'mean','baseline','deltaF_F0'}, exp_settings, ...
    'separate', 'blank_frame_inds', 1);
Y    = func_out.deltaF_F0(:,inside_ROI);   % [T x K] - only ROIs in viewing region
t_ts = func_out.trec;     % [T x 1]



% ---------- subset t/Y to included frames (if present) ----------
if ~isempty(Y) && ~isempty(t_ts)
    if numel(t_ts) < in.end_frame
        error('func_out.trec is shorter than requested end_frame.');
    end
    frame_idx = (in.start_frame:in.end_frame).';
    t = t_ts(frame_idx);
    Y = Y(frame_idx, :);
else
    t = (0:num_frames-1)'/sampling_rate;
end

% ---------- optional filtering ----------
if ~isempty(in.filt_size) && in.filt_size > 0
    vals = spatialFilter(vals, in.filt_size, in.filt_sigma);
    fprintf('Applied spatial filter with size %g, width %g\n',in.filt_size,in.filt_sigma);
end

% ---------- gamma correction ----------
if in.gamma_fac ~= 1
    vals = vals.^in.gamma_fac;
    fprintf('Applied %g gamma factor\n',in.gamma_fac);
end

% ---------- colorscale ----------
if isempty(in.cax_lims)
    cax_lims = [quantile(vals(:),0.05), quantile(vals(:),0.9999)];
else
    cax_lims = in.cax_lims;
end

% ---------- stim: convert seconds -> frame indices (relative to included frames) ----------
stim_vals1 = sort(in.stim_vals1(:) * sampling_rate, 'ascend');
stim_vals2 = sort(in.stim_vals2(:) * sampling_rate, 'ascend');
stim_pulse_dur1 = in.stim_pulse_dur1 * sampling_rate;
stim_pulse_dur2 = in.stim_pulse_dur2 * sampling_rate;

stim_vals1 = stim_vals1(stim_vals1>=in.start_frame & stim_vals1<=in.end_frame);
stim_vals2 = stim_vals2(stim_vals2>=in.start_frame & stim_vals2<=in.end_frame);
stim_vals1 = stim_vals1 - in.start_frame + 1;
stim_vals2 = stim_vals2 - in.start_frame + 1;

% Optional: make time relative to stim
if in.t_rel_stim == 1 && ~isempty(stim_vals1)
    t = t - t(stim_vals1(1));
    stim_vals1_plot = stim_vals1 - stim_vals1(1);     
    stim_vals2_plot = stim_vals2 - stim_vals1(1);    
elseif in.t_rel_stim == 2 && ~isempty(stim_vals2)
    t = t - t(stim_vals2(1));
    stim_vals1_plot = stim_vals1 - stim_vals2(1);
    stim_vals2_plot = stim_vals2 - stim_vals2(1);
end
stim_vals1_plot = stim_vals1_plot / sampling_rate; % (sec)
stim_vals2_plot = stim_vals2_plot / sampling_rate; % (sec)
% ---------- choose colormap ----------
cmap = localPickColormap(in.colormap, cax_lims);

% ---------- figure / layout ----------
fig = figure('Units', in.fig_units, 'Color','w');
fig.Position(1:2) = [0.5 0.5];
if ~isempty(in.fig_size)
    fig.Position(3:4) = in.fig_size;
end

tl = tiledlayout(fig, 2, 1, 'TileSpacing','compact', 'Padding','compact');

% Top axis: imaging
axImg = nexttile(tl, 1);
valsi = vals(:,:,in.start_frame);
if ~isempty(in.mask), valsi(~in.mask) = nan; end

if strcmp(in.plot_mode,'imagesc')
    hImg = imagesc(axImg, valsi);
else
    hImg = surf(axImg, zeros(size(valsi)), valsi, 'EdgeColor','none');
    axImg.View = [0 90];
end
hold(axImg,'on');
axis(axImg, 'equal', 'tight', 'off');
clim(axImg, cax_lims);
colormap(axImg, cmap);
axImg.YDir = in.YDir;
if in.show_colorbar, colorbar(axImg); end

% Time text on image
if in.show_time_str
    hTimeText = text(axImg, axImg.XLim(1)+diff(axImg.XLim)*in.time_text_x, ...
                           axImg.YLim(1)+diff(axImg.YLim)*in.time_text_y, ...
        sprintf('t = %.2f sec', t(1)), 'Color', in.time_color, 'FontSize', in.font_size);
else
    hTimeText = [];
end

% Scale bar (once)
if in.sbar_len > 0
    if isempty(in.pixel_size) && ~isempty(rec)
        in.pixel_size = rec.pixel_size;
    end
    if ~isempty(in.pixel_size)
        addScaleBar(in.pixel_size, size(vals,[1 2]), axImg, ...
            'sbar_len', in.sbar_len, 'x_factor', in.sbar_x_factor, 'y_factor', in.sbar_y_factor, ...
            'sbar_orientation', 'vert', 'text_x_factor', in.sbar_text_x_factor, ...
            'text_y_factor', in.sbar_text_y_factor, 'color', in.sbar_color, ...
            'show_text', in.sbar_show_text);
    end
end
% ROIs (once)
% rois_crop.plot('y',axImg,1,0);
rois_crop.plot(lines(rois_crop.num_rois),axImg,1,0,30,1.5);

% Bottom axis: time series (offset traces)
axTr = nexttile(tl, 2);
hold(axTr,'on'); 
grid(axTr,'off');

if ~isempty(Y)
    K = size(Y,2);
    offsets = (K-1:-1:0) * in.ts_offset_factor;
    plot(axTr, t, Y + offsets, 'LineWidth', in.ts_line_width);
    
    yAll = Y + offsets;
    yMin = min(yAll(:)); yMax = max(yAll(:));
    pad  = 0.08 * (yMax - yMin + eps);
    ylim(axTr, [yMin-pad, yMax+pad]);
else
    text(axTr, 0.5, 0.5, 'No ROI traces (rois empty)', 'Units','normalized', ...
        'HorizontalAlignment','center');
end

xlabel(axTr,'Time (s)');
axTr.YAxis.Visible = 'off';
% ylabel(axTr,'\DeltaF/F_0 (offset)');
% y_tick_labels = length(offsets):-1:1;
% axTr.YTick = fliplr(offsets);
% axTr.YTickLabel = y_tick_labels;

% Optional stim lines on trace axis
if in.ts_show_stim_lines
    if ~isempty(stim_vals1) 
        stimpoints_hand1 = addStimPointsToPlot(stim_vals1_plot,1,axTr,...
                                               'color','k','plot_y_factor',0.95);
    end
    if ~isempty(stim_vals2)
        stimpoints_hand2 = addStimPointsToPlot(stim_vals2_plot,3,axTr,...
                                               'color','r',...
                                               'stim_pulse_dur',stim_pulse_dur2 / sampling_rate,...
                                               'plot_y_factor',0.99,...
                                               'lw_mode3',2);
    end
end

% Add current time vertical line
hNow = xline(axTr, t(1), 'Color',0.4*[1 1 1],'LineStyle','-', 'LineWidth', 1.5);

xlim(axTr, localCenteredWindow(t, 1, in.ts_win_sec));

% ---- Time-series vertical scale bar (top-left; fixed in axes coords) ----
% Add this after you finish setting axTr.YLim (and after plotting), before the loop.

% position in normalized axes coordinates
x0 = 1;        % from left
yTop = 0.92;      % from bottom (top-ish)

% convert desired bar length (data units) -> normalized height
bar_h = in.ts_sbar_len / diff(axTr.YLim);

% draw bar as annotation (fixed on figure, aligned to axTr)
p = axTr.Position; % [x y w h] in figure-normalized units

x_fig = p(1) + x0   * p(3);
y1_fig = p(2) + yTop * p(4);
y0_fig = y1_fig - bar_h * p(4);

ts_sbar = annotation(fig, 'line', [x_fig x_fig], [y0_fig y1_fig], ...
    'Color', 0.2*[1 1 1], 'LineWidth', 2);

% optional text label to the right of the bar
% ts_sbar_txt = annotation(fig, 'textbox', [x_fig+0.01, y0_fig, 0.1, 0.05], ...
%     'String', sprintf('%g', in.ts_sbar_len), ...
%     'EdgeColor','none', 'Color', 0.2*[1 1 1], ...
%     'FontSize', in.font_size, 'VerticalAlignment','bottom');

% ---------- open video writer ----------
v = VideoWriter(output_file, in.video_profile);
% v.FrameRate = in.movie_slow_down_factor * sampling_rate;
v.FrameRate = in.target_fps;
open(v);
playback_rate_fps = sampling_rate * in.movie_slow_down_factor;   % experiment-frames per video-second
step = max(1, round(playback_rate_fps / in.target_fps));
write_frames = 1:step:num_frames;


% ---------- single synchronized loop ----------
last_stim1 = -inf; last_stim2 = -inf;
added_ps1 = false; added_ts2 = false;
ps1 = []; ts2 = [];

% Add label
tx = text(axImg,10,19,'iGluSnFR3 Fluorescence','Color','w','FontSize',in.font_size);

for ii = 1:numel(write_frames)
    i = write_frames(ii);
    % Update image frame
    valsi = vals(:,:,i);
    if ~isempty(in.mask), valsi(~in.mask) = nan; end
    hImg.CData = valsi;
        
    clim(axImg, cax_lims);

    if ~isempty(hTimeText)
        hTimeText.String = sprintf('t = %.2f sec', t(i));
    end

    % Stim markers on image
    if ~isempty(stim_vals1)
        % if any(i==stim_vals1), last_stim1 = i; end
        if any(i>stim_vals1), last_stim1 = stim_vals1(value2ind(i,stim_vals1)); end
        if i >= last_stim1 && i <= last_stim1 + stim_pulse_dur1
            if ~added_ps1
                ps1 = plot(axImg, axImg.XLim(1)+diff(axImg.XLim)*in.stim1_x, ...
                                axImg.YLim(1)+diff(axImg.YLim)*in.stim1_y, ...
                    'Marker', in.stim1_marker, 'Color', in.time_color, ...
                    'MarkerSize', in.stim1_marker_size, 'MarkerFaceColor', in.time_color);
                added_ps1 = true;
            else
                ps1.Visible = 'on';
            end
        elseif added_ps1
            ps1.Visible = 'off';
        end
    end

    if ~isempty(stim_vals2)
        if any(i==stim_vals2), last_stim2 = i; end
        if i >= last_stim2 && i <= last_stim2 + stim_pulse_dur2
            if ~added_ts2
                ts2 = text(axImg, axImg.XLim(1)+diff(axImg.XLim)*in.stim2_x, ...
                                axImg.YLim(1)+diff(axImg.YLim)*in.stim2_y, ...
                    in.stim2_marker, 'FontSize', in.font_size, ...
                    'Color', in.time_color2, 'FontWeight','bold');
                added_ts2 = true;
            else
                ts2.Visible = 'on';
            end
        elseif added_ts2
            ts2.Visible = 'off';
        end
    end

    % Update time-series window + current-time line
    hNow.Value = t(i);
    xlim(axTr, localCenteredWindow(t, i, in.ts_win_sec));

    % drawnow limitrate;
    drawnow; 

    % Capture BOTH axes and write
    fr = getframe(fig);
    writeVideo(v, fr);
end

close(v);
fprintf('Saved movie to %s\n', output_file);

end

% ========================= helpers =========================
function cmap = localPickColormap(name, cax_lims)
name = lower(string(name));
switch name
    case "inferno"
        if exist('inferno','file') == 2
            cmap = inferno(1000);
        else
            cmap = parula(256);
        end
    case {"bluewhitered","bwr"}
        if exist('bluewhitered','file') == 2
            try
                cmap = bluewhitered(1000, [], 'lims', cax_lims);
            catch
                cmap = bluewhitered(1000);
            end
        else
            cmap = parula(256);
        end
    case "coolwarm"
        if exist('coolwarm','file') == 2
            cmap = coolwarm(1000);
        else
            cmap = parula(256);
        end
    case "gray"
        cmap = gray(256);
    case "parula"
        cmap = parula(256);
    otherwise
        cmap = parula(256);
end
end

function xl = localCenteredWindow(t, i, winSec)
    halfWin = winSec/2;
    left  = t(i) - halfWin;
    right = t(i) + halfWin;
    
    if left < t(1)
        left = t(1);
        right = min(t(1) + winSec, t(end));
    elseif right > t(end)
        right = t(end);
        left = max(t(end) - winSec, t(1));
    end
    xl = [left right];
end