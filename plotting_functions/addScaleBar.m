function addScaleBar(pixel_size,imsize,ax,varargin)
if nargin < 3
   ax = gca; 
end
in.x_factor = 0.1;
in.y_factor = [];
in.text_x_factor = 1.1; 
in.text_y_factor = []; % normalized length below top of scale bar (vert) 
in.color = 'w';
in.show_text = 1; 
in.sbar_lw = 4;
in.sbar_len = []; 
in.font_size = 16;
in.font_name = 'Helvetica';
in.sbar_orientation = 'horz'; % 'horz' or 'vert'
in = sl.in.processVarargin(in,varargin); 
% get integer length (µm) and convert back to pixels
if strcmp(ax.YDir,'normal')    
    vert_align = 'bottom';
    if isempty(in.y_factor)
        y_factor = 0.9;
    else
        y_factor = in.y_factor; 
    end
    if isempty(in.text_y_factor)
        text_y_factor = 0.92;
    else
        text_y_factor = in.text_y_factor;
    end
else
    vert_align = 'top';
    if isempty(in.y_factor)
        y_factor = 0.1;
    end
    if isempty(in.text_y_factor)
        text_y_factor = 1.11;
    else
        text_y_factor = in.text_y_factor;
    end
end
if isempty(in.sbar_len)
    sbar_len = 5*floor(0.15*imsize(2)*pixel_size/5); % round to nearest multiple of 5 
else
    sbar_len = in.sbar_len; 
end
sbar_pixel_len = sbar_len/pixel_size; 
if strcmp(in.sbar_orientation,'horz')
    plot(ax,[in.x_factor*imsize(2),in.x_factor*imsize(2) + sbar_pixel_len],...
            y_factor*imsize(1)*[1 1],...
            'Color',in.color,'LineWidth',in.sbar_lw);
    text_x = in.x_factor*imsize(2) + sbar_pixel_len/2;
    text_y = text_y_factor*y_factor*imsize(1);
elseif strcmp(in.sbar_orientation,'vert')
    plot(ax,[in.x_factor*imsize(2),in.x_factor*imsize(2)],...
            [y_factor*imsize(1),y_factor*imsize(1)-sbar_pixel_len],...
            'Color',in.color,'LineWidth',in.sbar_lw);
    text_y = in.y_factor*imsize(1) - text_y_factor*sbar_pixel_len; 
    text_x = in.text_x_factor*in.x_factor*imsize(2); 
end
if in.show_text
    text(text_x,text_y,sprintf('%g \\mu m',sbar_len),...
            'VerticalAlignment',vert_align,'HorizontalAlignment','center',...
            'Color',in.color,'FontSize',in.font_size,'FontWeight','bold',...
            'FontName',in.font_name); 
end
end