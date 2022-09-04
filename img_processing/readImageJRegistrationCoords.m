function [coords,img_names] = readImageJRegistrationCoords(filename)
if exist(filename,'file')
    text = strsplit(fileread(filename),'\n')'; 
else
    fprintf('%s does not exist\n',filename); 
    return; 
end
dim_line = find(strncmp(text,'dim',3)); 
num_dims = str2double(text{dim_line(1)}(regexp(text{dim_line(1)},' = ')+3));
start_line = find(strncmp(text,'# Define the image coordinates',30))+1; 
end_line = length(text)-1;
num_coord = end_line+1 - start_line; 
coords = zeros(num_coord,num_dims); 
img_names = cell(num_coord,1); 
for i = 1:num_coord
    linei = text{start_line + i - 1}; 
    start_indi = regexp(linei,'(');
    end_indi = regexp(linei,')');
    coords(i,:) = str2num(linei(start_indi+1:end_indi-1));     %#ok<*ST2NM>
    % get name
    name_end_indi = regexp(linei,';'); 
    img_names{i} = linei(1:name_end_indi(1)-1);
end
end