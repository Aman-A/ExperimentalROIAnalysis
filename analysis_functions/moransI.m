function [I] = moransI(weights,y)
% Comput Moran's I of spatial autocorrelation given weights (distance)
% matrix and values of some function at each position
% From definition at https://rspatial.org/analysis/3-spauto.html
% z score definition from https://blogs.oregonstate.edu/geo599spatialstatistics/2016/06/08/spatial-autocorrelation-morans/#:~:text=Spatial%20Autocorrelation%20(Moran%27s%20I)%3A,value%20between%20%2D1%20and%201.
% Author : Aman Aberra
mean_y = mean(y); 
n = length(y);
assert(n == size(weights,1) && n == size(weights,2),'weights dimensions should match y');
I = 0; 
for i = 1:n
    for j = 1:n
        I = I + weights(i,j)*(y(i) - mean_y)*(y(j) - mean_y);
    end
end
% Moran's I index
I = n*I/(sum(weights,'all')*sum((y-mean_y).^2));

% z score
% E = -1/(n-1);
% S0 = sum(weights)
% V = (n^2*(n-1)*S1 - n*(n-1)*S2 - 2*S0^2)/((n+1)*(n-1)^2*S0^2);
% z = (I - E)/sqrt(V);
