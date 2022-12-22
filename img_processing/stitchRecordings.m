function varargout = stitchRecordings(recs_or_imgstack,xy)
%STITCHRECORDINGS ... 
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
if iscell(recs_or_imgstack)
    r = recs_or_imgstack{1}.imsize(1);
    c = recs_or_imgstack{1}.imsize(2);
    N = length(recs_or_imgstack);
else
    [r,c] = size(recs_or_imgstack,[1,2]);
    N = size(recs_or_imgstack,3);
end
xy = xy - xy(1,:); % set first position to (0,0)
% xy(:,2) = -xy(:,2);
min_x = min(xy(:,1));
% sort_x = sort(xy(:,1),'descend');
min_y = min(xy(:,2)); 
% sort_y = sort(xy(:,2),'descend');
x0 = round(abs(min_x));
y0 = round(abs(min_y));
% full_img = nan(round(max_y-min_y),round(max_x-min_x));
% full_img = zeros(round(max_y-min_y + r*2),round(max_x-min_x + c*2));
% x_overlap = sort_x(2) + c - max_x;
% y_overlap = sort_y(2) + r - max_y;
maxrow = 1; maxcol = 1;
for i = 1:N
    row0i = y0 + round(xy(i,2));
    col0i = x0 + round(xy(i,1)); 
    if max(row0i+1:row0i+r) > maxrow
        maxrow = max(row0i+1:row0i+r);
    end
    if max(col0i+1:col0i+c) > maxcol
        maxcol = max(col0i+1:col0i+c);
    end
end

if iscell(recs_or_imgstack)
    recs = recs_or_imgstack; 
    full_rec = zeros(maxrow,maxcol,recs{1}.imsize(3));
    for i = 1:N
        if recs{i}.loaded ==0
            recs{i}.load();
        end
        row0i = y0 + round(xy(i,2));
        col0i = x0 + round(xy(i,1));        
        full_rec(row0i+1:row0i+r,col0i+1:col0i+c,:) = full_rec(row0i+1:row0i+r,col0i+1:col0i+c,:) + recs{i}.vals;
    end
    full_rec = full_rec/N;
    varargout = {full_rec};
else
    img_stack = recs_or_imgstack;
    full_img = zeros(maxrow,maxcol);
    for i = 1:N
        row0i = y0 + round(xy(i,2));
        col0i = x0 + round(xy(i,1));
        full_img(row0i+1:row0i+r,col0i+1:col0i+c) = full_img(row0i+1:row0i+r,col0i+1:col0i+c) + img_stack(:,:,i);        
    end
    full_img = full_img/N;
    varargout = {full_img};
end