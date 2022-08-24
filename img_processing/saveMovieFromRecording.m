function saveMovieFromRecording(recording,sampling_rate,slow_down_factor,...
                                movie_name,movie_dir,save_movie,varargin)
%SAVEMOVIEFROMRECORDING Create and save animation from Recording or 
% m x n x T matrix to .avi 
%  
%   Inputs 
%   ------ 
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% TODO: REDUCE RUN TIME AND MAKE DISPLAY OPTIONS CONFIGURABLE
% AUTHOR    : Aman Aberra 
in.fig_size = [];
in.fig_units = '';
in.cmap = inferno(1000);
% in.compress_ratio = 2; % for Motion JPEG 2000 only
in.vid_quality = 100; 
in = sl.in.processVarargin(in,varargin);
if ischar(recording)    
    recording = Recording(recording);
    if ~recording.loaded
        recording.load(); 
    end
    vals = recording.vals;     
elseif isnumeric(recording)
    vals = recording; % input recording as 3D array    
elseif isa(recording,'Recording')
    if ~recording.loaded
        recording.load(); 
    end
    vals = recording.vals;         
end
if nargin < 6
    save_movie = 1; % set to 0 to play only
end
if nargin < 5
    movie_dir = pwd; 
end
if nargin < 4 || isempty(movie_name)
    if isa(recording,'Recording')
        movie_name = sprintf('%s_%gx',recording.img_name,slow_down_factor); 
    else
        movie_name = sprintf('rec_%gx%gx%g_%gx',size(vals,1),size(vals,2),...
                                                size(vals,3),slow_down_factor); 
        fprintf('WARNING: no file name input, using %s\n',movie_name);
    end
end
if nargin < 3
    slow_down_factor = 0.5; 
end
%% Get frames of movie
% fig = figure; 
% if ~isempty(in.fig_units)
%     fig.Units = in.fig_units;
% end
% if ~isempty(in.fig_size)
%     fig.Position(3:4) = fig_size; 
% end
% frames = struct('cdata',[],'colormap',[]); 
% nT = size(vals,3);
% times = (0:nT-1)/sampling_rate; 

% for j = 1:nT
%    ax = gca;
%    imagesc(ax,vals(:,:,j)); 
%    axis equal; axis off; axis tight;    
%    text(ax.XLim(1)+diff(ax.XLim)*0.8,ax.YLim(1) + diff(ax.YLim)*0.05,...
%         sprintf('t = %.3f sec',times(j)),'Color','w',...
%         'FontSize',12);
%    if ~isempty(in.cmap)
%        if ischar(in.cmap) && strcmp(in.cmap,'bwr')
%            colormap(ax,bluwhitered(1000));
%        else
%            colormap(ax,in.cmap);
%        end
%    end
% %    drawnow; 
%    frames(j) = getframe(ax); 
% end

%% Save or playback

tic
if save_movie
    movie_filename = fullfile(movie_dir,movie_name);
    v = VideoWriter(movie_filename,'MPEG-4');

%     v.CompressionRatio = in.compress_ratio;
    v.Quality = in.vid_quality;
    v.FrameRate = slow_down_factor*sampling_rate;
    open(v);
    nT = size(vals,3);
    for i = 1:nT
        framei = sc(vals(:,:,i),in.cmap);
        writeVideo(v,framei);
    end
    close(v);
    fprintf('Saved movie to %s\n',movie_filename);
else    
    replay = 1; 
    while replay
        movie(frames,1,round(slow_down_factor*sampling_rate)); 
        res = input('Replay movie? (y/n)');
        if strncmpi(res,'y',1)
            replay = 1;
        else
            replay = 0;
        end
    end
end

elapsed_time = toc;
fprintf('Time elapsed = %.3f sec\n',elapsed_time);

end