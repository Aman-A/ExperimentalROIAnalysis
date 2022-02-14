function output_data = plotTrial(img_name,exp_settings,rois_or_roiset_filename,...
                                trace_axis,varargin)
% PLOTTRIAL Plot image and response vs. time data from single trial
%  
% Default file organization expected by plotTrial:
% <data_fold>/<exp_date>/<reporter>/<dish>/<condition>/<img_name>
%   Inputs 
%   ------ 
%   img_name : string
%              Image stack file name. If file extension is not included,
%              assumes format is .fits. Allows for .fits or .tiff. If
%              data_fold, exp_date, reporter, dish, and condition not
%              input, assumes in current working directory, otherwise 
%              should include full path to file
%   exp_settings: ExperimentalSettings object
%                 instance of ExperimentalSettings object containing
%                 parameters for experimental recording, stimulation times, 
%                 and desired baseline window
%   rois_or_roiset_filename: string or ROIs objct
%                             Either the filename of a ROI set saved from
%                             ImageJ, or an already created ROIs object
%                             containing a set of ROI positions/sizes
%   trace_axis : axis handle
%                Axis to plot trace of desired function to, e.g., deltaF_F0.
%                Can be specified using optional argument 'plot_func' below
%   Optional Inputs 
%   --------------- 
%   data_fold : string
%               Path to top-level data folder, used to construct path and 
%               saved with Recording data
%   exp_date : string
%              Date of experiment (typically YYYYMMDD, but not required),
%              e.g., '20210927', used to construct path and saved with
%              Recording data
%   reporter : string
%              Name of reporter, e.g., 'GluSnFR3', used to construct path
%              and saved with Recording data
%   dish : string
%          Name of dish, e.g., 'dish1', used to construct path and saved
%          with Recording data
%   condition : string
%               Name of experimental condition, e.g. 'control', used to 
%               construct path and saved with Recording data
%   position : string
%              Name of stage position, e.g. 'Pos0' (NOTE: currently not 
%              used by any code in ExperimentalROIAnalysis, but saved with
%              Recording data)
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
in.data_fold = pwd;
in.exp_date = '';
in.reporter = '';
in.dish = '';
in.div = [];
in.condition = '';
in.position = '';
in.filedir = ''; % placeholder for inputs from plotTrials
in.show_diff_image = []; % for diffImage, specify which plots to include, can include 1, 2, 3 in
                         %  any order (1 - Baseline, 2 - Peak, 3 - Difference)                         
in.filt_width = 0; % gaussian filter width, used on peak deltaF to refine 
               % ROI positions

in.funcs = {'baseline','deltaF_F0'}; % functions to compute
in.plot_func = 'deltaF_F0'; % function to plot in ROI (plotROIfunc), otherwise 'none' or 0 for no plot
in.roi_func_mode = 'combine';
in.save_processed_data = 1;
in.load_processed_data = 0; 
in.y_lim = [];
in.x_lim = []; 
in.recenterROIs = 'peak'; 
in.roiset_filedir = []; % default set below (one directory above img directory)
in.roi_func_fig_size = [19.8 9.1];
in.roi_func_fig_units = 'centimeters';
in.transform_type = 'none'; % 'displace','translation','rigid','similarity','affine' - Image coregistration
in.registration_rec = ''; % full path to Recording to register for shifting ROIs or Recording object
in.save_fig = 0; % 1 just plots images for trial, 2 also plots funcs in ROI for trial
in.overlay_trials = 1; % relevant for plotTrials
in.close_img_after_save = 1; in.show_roi_labels = 0;
in.pixel_size = 0.4; % um (pixel size on Thor camera with 40x objective)
in.bin_size = 1; % 1x1 binning
in.sort_traces = 0; % 1 to sort traces by plotROIfunc 
in.offset_factor = 1.01; % sets trace offset for separate ROIs in plotROIfunc 
in = sl.in.processVarargin(in,varargin); 
%% Load trial data
% Hold off on loading image in case processed data exists and
% load_processed_data == 1
img = Recording(img_name,'position',in.position,'condition',in.condition,...
                'dish',in.dish,'reporter',in.reporter,'exp_date',in.exp_date,...
                'data_fold',in.data_fold,'pixel_size',in.pixel_size,...
                'div',in.div,'bin_size',in.bin_size);             
% Prepare filename for saving data and check if it exists
[~,img_name_no_ext] = fileparts(img_name); 
if ischar(rois_or_roiset_filename)
    roiset_filename_no_ext = getROIset_name(rois_or_roiset_filename,...
                                            in.transform_type,...
                                            in.registration_rec);    
else
    roiset_filename_no_ext = 'custom';
end
fig_dir = fullfile(img.filedir,['figs_',roiset_filename_no_ext]);
save_data_filename = fullfile(img.filedir,sprintf('%s-%s-%s-data.mat',...
                                                  img_name_no_ext,in.roi_func_mode,...
                                                  roiset_filename_no_ext));
if exist(save_data_filename,'file') && in.load_processed_data
    % Load processed data (skips showing diff image, even if set in
    % show_diff_image)
    output_data = load(save_data_filename); 
    if isfield(output_data,'Recording') 
    % Temporary fix to make code backwards compatible with old processed data
       output_data.recording = output_data.Recording;
       output_data.settings = output_data.Settings; 
       output_data.rois = output_data.ROIs;
       output_data = rmfield(output_data,{'Recording','Settings','ROIs'});
       save(save_data_filename,'-STRUCT','output_data'); 
       fprintf('Replaced old field names Recording/Settings/ROIs with recording/settings/rois and resaved\n');       
    end
    func_output = output_data.func_output;
    fprintf('Loaded processed data from %s\n',save_data_filename); 
    % Plot baseline, peak, diff images
    fig_hands = plotDiffImage(output_data.mean_bsline_img,output_data.peak_stim_img,...
                  output_data.diff_img,img.img_name,exp_settings,...
                  'include_plots',in.show_diff_image,'filt_width',in.filt_width,...
                  'pixel_size',img.pixel_size);               
    addROIoverlayAndSave(fig_hands,output_data.rois,in.save_fig,fig_dir,img.img_name,...
                         in.close_img_after_save,in.show_roi_labels);
else
    img.load();  % Load image data
    %% Output peak image
    [mean_bsline_img,peak_stim_img,diff_img,fig_hands] = diffImage(img,...
                                                        exp_settings,...                                                        
                                                        'include_plots',...
                                                        in.show_diff_image,...
                                                        'filt_width',...
                                                        in.filt_width);                          
    %% Load saved ROIs
    if isempty(in.roiset_filedir)
       in.roiset_filedir = [img.filedir filesep '..']; % default location
    end
    rois = ROIs(rois_or_roiset_filename,'roi_set_filedir',...
                in.roiset_filedir); % assume directory above data for this condition
    if ischar(rois_or_roiset_filename)
        if regexp(rois_or_roiset_filename,'pc')
            % TEMPORARY FIX: include 'pc' in file name to indicate ROIs created on
            % Windows ImageJ, require y axis to be inverted when
            % importing to MATLAB
            rois.invert_y(img.imsize); 
        end
    end
    % Coregister Images and shift ROIs
    if ~strcmp(in.transform_type,'none') &&  ~isempty(in.transform_type)
        if ischar(in.registration_rec)
            fixed_rec = Recording(in.registration_rec); 
        elseif isa(in.registration_rec,'Recording')
            fixed_rec = in.registration_rec; 
        end
        if ~strcmp(fixed_rec.filepath,img.filepath)
            [~,~,rois] = coregisterImagesAndROIs(fixed_rec,img,rois,exp_settings,...
                                                'plot_result',0,...
                                                'transform_type',in.transform_type); 
        else
            fprintf('Registering to same recording, skipping...\n'); 
        end
    end
    % Recenter using peak, diff, or baseline image
    if in.recenterROIs ~= 0
        if ischar(in.recenterROIs) 
            if strcmp(in.recenterROIs,'diff')
                recenter_img = diff_img;
            elseif strcmp(in.recenterROIs,'peak')
                recenter_img = peak_stim_img;
            elseif strcmp(in.recenterROIs,'baseline')
                recenter_img = mean_bsline_img;
            end
        elseif in.recenterROIs == 1
            recenter_img = diff_img; % recenter on this by default if no mode specified
        end
        rois.recenterROIsLoop(recenter_img,0,1); % recenter to peak value repeatedly until no further shift occurs
    end    
    if any(in.show_diff_image)
        % Overlay on diff image and save        
        addROIoverlayAndSave(fig_hands,rois,in.save_fig,fig_dir,img.img_name,...
                             in.close_img_after_save,in.show_roi_labels);
    else
        fprintf('Skipping diff image plot\n'); 
    end   
    %% Calculate deltaF/F0 
    func_output = calcROIfuncs(img,rois,in.funcs,exp_settings,in.roi_func_mode);
    %% Generate output data structure
    output_data = struct();
    output_data.recording = img.unload(); % save with data unloaded, reduce HD usage
    output_data.settings = exp_settings;    
    output_data.rois = rois; 
    output_data.mean_bsline_img = mean_bsline_img;
    output_data.peak_stim_img = peak_stim_img;
    output_data.diff_img = diff_img; 
    output_data.funcs = in.funcs; 
    output_data.func_output = func_output;     
    output_data.fig_dir = fig_dir; 
    %% Save processed data    
    if in.save_processed_data                    
        save(save_data_filename,'-STRUCT','output_data'); 
        fprintf('Saved data to %s\n',save_data_filename); 
    end
end
%% Plot data
% only plot if plot_func is not 0, empty, or 'none'
if ~strcmp(in.plot_func,'none') && ~isempty(in.plot_func) && all(in.plot_func~=0) 
    if isempty(trace_axis)                       
        fig = figure; 
        trace_axis = gca;
    else
        fig = trace_axis.Parent;    
    end
    fig.Units = in.roi_func_fig_units;
    fig.Position(3:4) = in.roi_func_fig_size;
    if ~isempty(in.x_lim)
       trace_axis.XLim = in.x_lim;     
    end
    if ~isempty(in.y_lim)            
        trace_axis.YLim = in.y_lim;         
    end
    show_legend = 0;
%     if strcmp(in.roi_func_mode,'combine')
%         show_legend = 0; 
%     else
%         show_legend = 0;
%     end
    plotROIfunc(func_output,in.plot_func,exp_settings.stim_vals,...
                    exp_settings.sampling_rate,'rois',output_data.rois,...
                    'ax',trace_axis,'show_legend',show_legend,...
                    'sort_traces',in.sort_traces,'offset_factor',in.offset_factor);
    drawnow; 
    if in.save_fig > 1 % set to 2 to plot individual trials   
       fig_name = [img.img_name '_' in.plot_func]; 
       printFig(fig,fig_dir,fig_name); 
    end
end
end
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
                    