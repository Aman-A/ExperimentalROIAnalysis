function out = motionCorrectRecording(recording,ref_frames,print_status,...
                                     method)
%MOTIONCORRECTRECORDING Apply motion correction to recording or image stack 
%  
%   Inputs 
%   ------ 
%   recording : Recording object or m x n x T image stack
%   Optional Inputs 
%   --------------- 
%   Outputs 
%   ------- 
%   Examples 
%   --------------- 
% Adapted from spikePursuit by Kaspar Podgorski
%
% AUTHOR    : Aman Aberra 

if ischar(recording)    
    recording = Recording(recording);
    recording.load(); 
    data = recording.vals; 
    out_mode = 1; 
elseif isnumeric(recording)
    data = recording; % input recording as 3D array
    out_mode = 2; 
elseif isa(recording,'Recording')
    if ~recording.loaded
        recording.load();
    end
    data = recording.vals;     
    out_mode = 1; 
end

if nargin < 2
%     N = size(data,3);
%     ref_frames = 1:ceil(N/10); % take first 5% of recording
    ref_frames = 1; % take first frame
end

if nargin < 3
    print_status = 1; 
end
if nargin < 4
    method = 'dft'; % 'dft' discrete fourier transform method
                    % 'imregtform' affine transformation with imregtform
end
ref = mean(data(:,:,ref_frames),3); 
data2 = data; 
switch method    
    case 'dft'
        refFFT = fft2(ref);
        drawnow;        
        % pobj = parpool;
        parfor f = 1:size(data,3)
            if ~mod(f,400) && print_status
                disp(['registering frame: ' int2str(f)])
            end
            %align data
            [~, G] = dftregistration(refFFT,fft2(data(:,:,f)),4);
            data2(:,:,f) = real(ifft2(G));
        end
        % delete(pobj);
    case 'imregtform'
        transform_type = 'rigid';
        [optimizer,metric] = imregconfig('monomodal');
        parfor f = 1:size(data,3)
            if ~mod(f,400) && print_status
                disp(['registering frame: ' int2str(f)])
            end
            tform = imregtform(data(:,:,f),ref,transform_type,optimizer,metric)
            data2(:,:,f) = imwarp(data(:,:,f),tform,...
                            'OutputView',imref2d(size(ref)));
        end
end
disp('Done alignment')

switch out_mode
    case 1 % loaded Recording above
        recording.vals = data2; 
        out = recording;     
    case 2 
        out = data2; % input recording as 3D array
end
end
