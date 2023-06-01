function [params_gaussian_all,peaks_rois_successes_all,Pr] = estimateQuantalContentRecs(rec_names,roiset_files,...
                                                        exp_settings,varargin)
%ESTIMATEQUANTALCONTENTRECS(rec_names,roiset_files,exp_settings,varargin) 
% Fit peak histogram of single boutons to multiguassian 
% to estimate amplitude of single vesicle release events, from multiple raw
% recordings of same boutons(helper function for estimateQuantalContent)
%  
%   Inputs 
%   ------ 
%   rec_names : 1 x Nrecordings cell array
%               cell array of recording names (strings)
%   roiset_files : 1 x Nrecordings cell array
%                  cell array of ROIset files corresponding to each
%                  recording
%   exp_settings : ExperimentSettings object or object array
%                  Experiment settings associated with recordings, either
%                  the same for all or one for each recording
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
if nargin == 0
    rec_names = {'3mABi_0mAG/3mABi_0mAG','3mABi_0.05mAG/3mABi_0.05mAG.fits',...
                '3mABi_0.05mAG/3mABi_0.05mAG_1.fits','3mABi_-0.05mAG/3mABi_-0.05mAG.fits',...
                '3mABi_-0.05mAG/3mABi_-0.05mAG_2.fits'};    
    roiset_files = repmat({'RoiSet_pc_SynmRuby_pos5_2.zip'},1,length(rec_names));    
%     rec_names = {'3mABi_0mAG/3mABi_0mAG.fits'};    
%     roiset_files = {'RoiSet_auto_pos5_2.mat'};    
    exp_settings = ExperimentSettings(0.5:0.5:30,0.4,0.15,...
                                      'sec',100); % automatically converts to frames
end
in.data_dir = '/Volumes/MyPassport/Dartmouth_data/Aman_Olympus/DC_mod_experiments/230117/GluSnFR3_SynmRuby/dish1/'; 
in.show_diff_image = []; 
in.load_processed_data = 1; 
in.save_processed_data = 0; 
in.save_figs = 0; 
in.std_threshold = 3.5; % threshold to consider peak success vs. failure, 
                      % defined as multiple of std of local baseline for
                      % each stimulus, i.e. peak > 4 x std(baseline) is
                      % success for in.std_threshold = 4. 
% in.min_width = [18e-3 60e-3]; % sec - min FWHM of stim evoked response to consider successful response (if >std_threshold)
in.min_width = 0; 
in.plot_func = ''; % plot traces, either 'deltaF_F0' for full traces 
                   % or 'deltaF_F0_aligned' for stimulus averaged traces in
                   % each ROI
% histogram fitting parameters, adapted from Mendonca 2022 Quantal_Analysis.m
in.plot_fits = 1; % Plot histograms for all ROIs
in.lw = 2;      % line width of the fit in plots
in.N_bootstrap = 1e6; % number of bootstrap events
in.alpha = 1.5; % scaling factor for STD of fluorescence signals to generate bootstrapped events
              % Higher alpha gives larger spread for a given signal
              % variance
in.num_bins_per_std_B = 4.5; % Number of histogram bins scaled by STD of fluorescence signals
in.Multi_Gauss_threshold = 6; % minimum number of events to try multi gaussian fitting
in.alpha_fit_dx = 0.005; % step size for test normalization values
in.dx = 0.001; % fit function x step
in.smooth_bs_dist = 1; % smooth bootstrapped peak distributions with 5 point moving average
in.include_sat_param = 0; % include parameter for saturation of indicator at higher quanta
in.n_G = 3;
in.roi_func_fig_size = []; 
in = sl.in.processVarargin(in,varargin);
%% Load recordings
if isempty(in.data_dir)
    in.data_dir = fileparts(rec_names{1});    
end
ps = plotTrialSettings;
ps.plot_func = in.plot_func;
ps.roi_func_mode = 'separate';
ps.funcs = {'mean','baseline','deltaF_F0'};
ps.show_diff_image = in.show_diff_image; 
ps.save_fig = in.save_figs; 
ps.show_roi_labels = 1;
ps.load_processed_data = in.load_processed_data;
ps.transform_type = 'none';
if exp_settings.num_stim > 0
    ps.x_lim = [-exp_settings.convert2Time(exp_settings.stim_vals(1)),...
                diff(exp_settings.convert2Time([exp_settings.stim_vals(1),exp_settings.stim_vals(end)]))]; 
end
if ~isempty(in.roi_func_fig_size)
    ps.roi_func_fig_size = in.roi_func_fig_size;
end
ps.offset_factor = 0.4;     
Nrecs = length(rec_names); % number of recording files
peaks_all = cell(1,Nrecs);
peaks_rois_successes = cell(1,Nrecs);
successes_all = cell(1,Nrecs);
if length(in.min_width) == 1
    in.min_width = [in.min_width inf]; % if specific min width only, add max width
end
if length(exp_settings) == 1
    exp_settings = repmat(exp_settings,1,Nrecs);
end
assert(length(exp_settings) == Nrecs,'Number of ExperimentSettings objects should be 1 or %g',Nrecs)
data_all = cell(Nrecs,1);
for i = 1:Nrecs
    reci = Recording(fullfile(in.data_dir,rec_names{i}));
%     roisi = ROIs(fullfile(in.data_dir,roiset_files{i}));
    datai = plotTrial(reci,exp_settings(i),fullfile(in.data_dir,roiset_files{i}),[],ps);
    data_all{i} = datai; 
    roisi = datai.rois; 
    analysis_out = analyzeStimAlignedTraces(datai.func_output.deltaF_F0_aligned,exp_settings(i),...
                                        'funcs',{'peaks'},...
                                        'save_analysis',0,'load',0);
    peaksi = analysis_out.peaks; 
    std_baselinesi = squeeze(std(datai.func_output.deltaF_F0_aligned(1:exp_settings(i).baseline_wind,:,:),0,1));
    successesi = peaksi > in.std_threshold.*std_baselinesi; 
    peaks_all{i} = peaksi;
    % Extract successful peaks within each ROI (remove failures)
    peaks_rois_successes{i} = cell(roisi.num_rois,1);
    t = exp_settings(i).getTimeVector(size(datai.func_output.deltaF_F0_aligned,1));
    t = t - t(exp_settings(i).baseline_wind + 1);
    for j = 1:roisi.num_rois
        successesij = successesi(j,:);
        widthsij = zeros(1,length(successesij));
        if in.min_width(1) > 0           
            for k = find(successesij) % check width peaks > std threshold
                widthsij(k) = spikeWidth(t,datai.func_output.deltaF_F0_aligned(:,j,k),...
                                         exp_settings(i).baseline_wind+1,0.5,0);
            end
            successesij = successesij & widthsij > in.min_width(1) & widthsij < in.min_width(2);
        end        
        peaks_rois_successes{i}{j} = peaksi(j,successesij);
    end    
    successes_all{i} = successesi; 
end
num_rois = roisi.num_rois; 
% Convert to [num_rois x num_stim] matrix
% peaks_mat_all = cell2mat(peaks_all); % assumes same number of ROIs in each recording
successes_mat = cell2mat(successes_all);
Pr = mean(successes_mat,2); % [num_rois x 1] vector of release probabilities (>=1 SV)
peaks_rois_successes_all = cell(num_rois,1);
% Combine across recordings within ROI
for i = 1:Nrecs
    for j = 1:roisi.num_rois
        peaks_rois_successes_all{j} = [peaks_rois_successes_all{j},peaks_rois_successes{i}{j}];
    end
end
% Use last trial to get std of full trace for setting bin size
deltaF_F0 = datai.func_output.deltaF_F0;
opts = struct(); 
opts.plot_fits = in.plot_fits;
opts.lw = in.lw;
opts.N_bootstrap = in.N_bootstrap;
opts.alpha = in.alpha;
opts.num_bins_per_std_B = in.num_bins_per_std_B;
opts.Multi_Gauss_threshold = in.Multi_Gauss_threshold;
opts.alpha_fit_dx = in.alpha_fit_dx; 
opts.dx = in.dx;
opts.smooth_bs_dist = in.smooth_bs_dist;
opts.include_sat_param = in.include_sat_param;
opts.n_G = in.n_G;
[params_gaussian_all] = estimateQuantalContent(peaks_rois_successes_all,deltaF_F0,opts); 
end