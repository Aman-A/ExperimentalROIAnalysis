function [mean_correl_img,norm_correl_img] = correlationImage(img_vals,...
                                                              exp_settings,...
                                                              varargin)
%CORRELATIONIMAGE Compute temporal correlation of pixels with neighboring
%pixels, as in Cai et al. Plos Comp Biol 2021  
%  
%   Inputs 
%   ------ 
%   img_vals : N x M x num_time_points array 
%              z stack of images taken at multiple timepoints
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 

% AUTHOR    : Aman Aberra 
in.num_neighbors = 8; % number of neighboring pixels to compute temporal correlation
in.filt_order = 0; % Order of high-pass filter (acausal), set to 0 to turn off
in.filt_cutoff = 0.5; % cutoff frequencies of filters [low high] (Hz) Default: [0.5 Hz]
in.print_level = 1;
in = sl.in.processVarargin(in,varargin); 

%% Apply high pass filter to remove exponential decay from bleaching 
if in.filt_order > 0
    if length(in.filt_cutoff) == 1
        filt_str = 'high';
    else
        filt_str = 'bandpass';
    end
    tic;
    [b,a] = butter(in.filt_order,in.filt_cutoff/(exp_settings.sampling_rate/2),filt_str);
    filt_img_vals = zeros(size(img_vals));
    for i = 1:size(img_vals,1)
        for j = 1:size(img_vals,2)
            filt_img_vals(i,j,:) = filtfilt(b,a,squeeze(img_vals(i,j,:))); 
        end
    end
    elapsed_time = toc; 
    if in.print_level > 0
        fprintf('Applied %g order butterworth filter with fc = %.2f Hz in %.2f sec\n',...
                  in.filt_order,in.filt_cutoff,elapsed_time);
    end
end
%% Average temporal correlation of each pixel with its in.num_neighbors 
% neighboring pixels
[X,Y] = meshgrid(1:size(img_vals,2),1:size(img_vals,1)); % coordinates of each pixel
mean_correl_img = zeros(size(img_vals,[1 2])); 
% figure; % for testing
% imagesc(img_vals(:,:,1)); hold on; axis equal;
peak_cross_correls_temp = zeros(1,in.num_neighbors); 
N = numel(mean_correl_img);
tic
for i = 1:N
   neighbor_inds = getPixelNeighbors(X,Y,i,in.num_neighbors);      
   [r,c] = ind2sub(size(img_vals,[1,2]),[i;neighbor_inds]);
   ri = r(1); ci = c(1); 
   for j = 2:(length(neighbor_inds)+1)
       % compute peak of cross correlation of pixel i with jth neighboring pixel       
       peak_cross_correls_temp(j) = max(xcorr(squeeze(img_vals(ri,ci,:)),...
                                              squeeze(img_vals(r(j),c(j),:)))); 
   end
   % Average peak cross correlations with all neighbors for ith pixel
   mean_correl_img(ri,ci) = mean(peak_cross_correls_temp); 
   
%    [y,x] = ind2sub(size(img_vals,[1,2]),i); % for testing
%    [yn,xn] = ind2sub(size(img_vals,[1,2]),neighbor_inds);
%    if i > 1
%       delete(pi); delete(pn);  
%    end
%    pi = plot(x,y,'r','LineStyle','none','Marker','*'); 
%    pn = plot(xn,yn,'g','LineStyle','none','Marker','sq'); 
%    axis([x-in.num_neighbors*3 x+in.num_neighbors*3 y-in.num_neighbors*3 y+in.num_neighbors]);   
%    drawnow; 
    if in.print_level > 1
        fprintf('Finished pixel %g of %g\n',i,N); 
    end
end
toc
%% Normalize by subtracting mean and dividing by standard deviation across pixels
mean_across_pixels = mean(mean_correl_img(:)); 
std_across_pixels = std(mean_correl_img(:),0); 
norm_correl_img = (mean_correl_img - mean_across_pixels)/std_across_pixels; 
end
function neighbor_inds = getPixelNeighbors(X,Y,pixel_ind,num_neighbors)    
    xi = X(pixel_ind); yi = Y(pixel_ind); % spatial coordinate of pixel of interest
%     R = abs((X-xi)) + abs((Y-yi)); % L1 norm of all pixels from pixel of interest 
    R = sqrt((X-xi).^2 + (Y-yi).^2); % L2 norm of all pixels from pixel of interest 
    [~,inds] = sort(R(:),'ascend'); 
    neighbor_inds = inds(2:1+num_neighbors); % num_neighbors closest indices
end