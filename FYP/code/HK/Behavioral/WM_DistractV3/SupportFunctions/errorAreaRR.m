function [h_plot h_patch] = errorAreaDB(x,y_mean,y_error,color_line,color_area)

% function [h_plot h_patch] =
% errorAreaDB(x,y_mean,y_error,color_line,color_area)
% 
% Instead of error bars, make error areas. Designed to behave similar to
% "errorbar"
% 
% color_line and color_area are RGB triplets (range 0-1) for the color of
% the plot line and the surrounding area, respectively. If not defined,
% these are red and pink. I recommend that the area color is lighter than
% the line color. 
% 
% The area will be 50% transparent. 
% 
% Returns handles to the plot and patch. 
% 
% by Devin Brady, April 2008

try
    
    hold on

    % Define defaults
    if ~exist('color_line','var')
        color_line = [1 0 0]; % red
    end
    if ~exist('color_area','var')
        color_line = [1 0.2 0.2]; % pink
    end

    % make all points into 1-column vectors
    if size(x,1) < size(x,2)
        x = x';
    end
    if size(y_mean,1) < size(y_mean,2)
        y_mean = y_mean';
    end
    if size(y_error,1) < size(y_error,2)
        y_error = y_error';
    end

    % Plot the mean line
    h_plot = plot(x,y_mean);%,'Color',colorRGB);

    % Make list of X and Y points for each vertex of error area
    patch_X = [x; flipud(x)];
    patch_Y = [(y_mean + y_error); flipud(y_mean - y_error)];

    
    % Plot the area
    h_patch = patch(patch_X,patch_Y,color_area,'EdgeColor','none');


    % Set colors
    set(h_plot,'Color',color_line);
%     set(h_patch,'Color',color_area);

catch ME

    % Save all variables to workspace
    varlist = who;
    for file = 1:length(varlist)
        eval(['tmp = ' char(varlist(file)) ';']);
        assignin('base',char(varlist(file)),tmp);
    end
    
    rethrow(ME);
end