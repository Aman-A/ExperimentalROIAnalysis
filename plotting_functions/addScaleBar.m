function addScaleBar(pixel_size,imsize,ax,varargin)
if nargin < 3
   ax = gca; 
end
in.x_factor = 0.1;
in.y_factor = [];
in.text_y_factor = [];
in.color = 'w';
in.show_text = 1; 
in = sl.in.processVarargin(in,varargin); 
% get integer length (µm) and convert back to pixels
if strcmp(ax.YDir,'normal')    
    vert_align = 'bottom';
    if isempty(in.y_factor)
        y_factor = 0.9;
    end
    if isempty(in.text_y_factor)
        text_y_factor = 0.87;
    end
else
    vert_align = 'top';
    if isempty(in.y_factor)
        y_factor = 0.1;
    end
    if isempty(in.text_y_factor)
        text_y_factor = 1.11;
    end
end
sbar_len = 5*floor(0.15*imsize(2)*pixel_size/5); % round to nearest multiple of 5 
sbar_pixel_len = sbar_len/pixel_size; 
plot(ax,[in.x_factor*imsize(2),in.x_factor*imsize(2) + sbar_pixel_len],...
        y_factor*imsize(1)*[1 1],...
        'Color',in.color,'LineWidth',4);
if in.show_text
    text(0.1*imsize(2) + sbar_pixel_len/2,...
            text_y_factor*y_factor*imsize(1),sprintf('%g \\mu m',sbar_len),...
            'VerticalAlignment',vert_align,'HorizontalAlignment','center',...
            'Color',in.color,'FontSize',16,'FontWeight','bold'); 
end
end