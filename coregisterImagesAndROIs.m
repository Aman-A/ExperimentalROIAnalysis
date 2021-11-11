function varargout = coregisterImagesAndROIs(fixed_recording,moving_recording,...
                                             rois,exp_settings,varargin)
%COREGISTERIMAGESANDROIS Coregisters images and shifts ROIs accordingly (circular only)
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
% image registration settings
in.transform_type = 'displace'; % 'translation','rigid','similarity','affine','displace
in.max_iterations = 300; % Max iterations for registration optimizer
in.z_proj = 'baseline'; % image to use for registration - 'baseline','peak','diff' (peak - baseline)
in.metric = 'MeanSquares'; 
in.roi_disp_shift_mode = 'mean'; % For displacement mode, specify 'mean' or 
                                 % 'center' (TBD) to shift based on mean of 
                                 % disp vector or disp vector at center of
                                 % each ROI
in.dilation_factor = 4; % coregister using pixels within ROIs with radius dilated by this factor                                 
in.plot_result = 0; 
in.save_fig = 0; 
in = sl.in.processVarargin(in,varargin); 
%% Get z-projection of each image to use for registration
[fixed_bsline,fixed_peak, fixed_diff] = diffImage(fixed_recording,exp_settings,...
                                                  'include_plots',[]);
[moving_bsline,moving_peak, moving_diff] = diffImage(moving_recording,exp_settings,...
                                                  'include_plots',[]);
if strcmp(in.z_proj,'baseline')       
    fixed_img = fixed_bsline;
    moving_img = moving_bsline;
elseif strcmp(in.z_proj,'peak')
    fixed_img = fixed_peak;
    moving_img = moving_peak;
elseif strcmp(in.z_proj,'diff')
    fixed_img = fixed_diff;
    moving_img = moving_diff;
else
   error('''%s'' is not a valid setting for z_proj',in.z_proj);  
end
%% Run image registration
if strcmp(in.transform_type,'displace')
    % Coregister using images masked with dilated ROIs 
    rois_reg = rois.copy(); 
    rois_reg.radius = rois_reg.radius*in.dilation_factor; % dilate rois for image used for estimating displacement field
    mask_reg = rois_reg.getMask(fixed_recording.imsize(1:2));
    moving_img2 = moving_img.*mask_reg; moving_img2(isnan(moving_img2)) = 0; 
    fixed_img2 = fixed_img.*mask_reg; fixed_img2(isnan(fixed_img2)) = 0; 
    tic; 
    [D,moving_reg] = imregdemons(moving_img2,fixed_img2,in.max_iterations,...
                                 'DisplayWaitbar',false);     
    
%     [D,moving_reg] = imregdemons(moving_img,fixed_img,in.max_iterations,...
%                                  'DisplayWaitbar',false);     
    % Output new ROIs object with shifted rois
    rois2 = rois.copy(); 
    if strcmp(in.roi_disp_shift_mode,'mean')
        dr = zeros(rois.num_rois,2);        
        for i = 1:rois.num_rois
            maski = rois2.getMask(fixed_recording.imsize(1:2),i);
            Dx_i = D(:,:,1).*maski;
            Dy_i = D(:,:,2).*maski;
            dr(i,1) = mean(Dx_i(:),'omitnan');
            dr(i,2) = mean(Dy_i(:),'omitnan');
        end        
    elseif strcmp(in.roi_disp_shift_mode,'center')
        error('''center'' roi_disp_shift_mode not implemented yet'); 
    end
    time_elapsed = toc; 
    rois2.registration_rec = fixed_recording.filepath; 
    rois2.transform_type = in.transform_type; 
    fprintf('Coregistered %s to %s using non-parameteric displacement in %.3f sec \n',...
            moving_recording.img_name,fixed_recording.img_name,time_elapsed); 
    fprintf('Mean displacement (%.3f, %.3f) um\n',...
                 mean(dr(:,1))*fixed_recording.pixel_size,...
                 mean(dr(:,2))*fixed_recording.pixel_size); 
    if max(sqrt(dr(:,1).^2 + dr(:,2).^2))*fixed_recording.pixel_size > 5        
       fprintf('WARNING: Displacement of >5 um on %g ROIs!!!\n', sum(sum(sqrt(dr(:,1).^2 + dr(:,2).^2))>5));
    end
    rois2.shift(dr); % shift each ROI by [x,y] vector (pixels)    
    varargout = {D,dr,rois2}; 
else
    optimizer = imregconfig('monomodal'); % mean squares
    optimizer.MaximumIterations = in.max_iterations; 
    if strcmp(in.metric,'MeanSquares')
       metric = registration.metric.MeanSquares; 
    elseif strcmp(in.metric,'MattesMutualInformation')
        metric = registration.metric.MattesMutualInformation;
    end
    tform = imregtform(moving_img,fixed_img,in.transform_type,optimizer,metric,...
                       'DisplayOptimization',false);    
    varargout = {tform}; 
    % For some reason, output of imwarp with tform is different from output
    % of imregister, should be identical...
    moving_reg2 = imwarp(moving_img,tform,'OutputView',imref2d(size(fixed_img)));
% [moving_reg2,R_reg] = imregister(img2_zproj,img1_zproj,transform_type,optimizer,metric,...
%                                 'DisplayOptimization',true); 
end

if in.plot_result
    vis_method = 'falsecolor'; % 'falsecolor','checkerboard','diff','montage'
    scaling_method = 'independent'; % 'joint','independent', or 'none'
    c_lims = quantile(fixed_img(:),[0.02 0.995]);
    fig = figure;
    ax = subplot_tight(3,1,1); % Before    
    before_overlay = imfuse(fixed_img,moving_img,vis_method,'Scaling',scaling_method);
    imagesc(before_overlay);
    hold(ax,'on'); axis(ax,'off','equal');     
    rois2.plot('y',ax,0); 
    title('Before - Green:fixed/first, Purple:moving/second');
    ax2 = subplot_tight(3,1,2); % After    
    after_overlay = imfuse(fixed_img,moving_reg,vis_method,'Scaling',scaling_method);
    imagesc(after_overlay);
    hold(ax2,'on'); axis(ax2,'off','equal');            
    title('After');
    ax3 = subplot_tight(3,1,3);
    imagesc(moving_img); hold(ax3,'on'); axis(ax3,'off','equal'); colormap('inferno');
    caxis(ax3,c_lims);
    rois2.plot('y',ax3,0); 
    rois2.plot('g',ax3,1); 
   title({'Shifted ROIs overlaid on non-reference (second)',...
       sprintf('Translation = %.3f +/- %.3f (mean +/- std) \\mu m',...
       norm(mean(dr,1))*fixed_recording.pixel_size,...
       norm(std(dr,0,1))*fixed_recording.pixel_size)}); 
    hold(ax3,'on');
    if in.save_fig
        [~,roi_set_filename_no_ext] = fileparts(rois.roi_set_filename);    
        fig_dir = fullfile(moving_recording.filedir,...
                            sprintf('figs_%s_%s_%s',roi_set_filename_no_ext,...
                            fixed_recording.img_name,in.transform_type));         
        fig_name = sprintf('%s_disp_results',moving_recording.img_name); 
        printFig(fig,fig_dir,fig_name);         
    end
end
