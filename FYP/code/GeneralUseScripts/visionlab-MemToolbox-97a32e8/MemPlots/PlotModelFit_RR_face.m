% PLOTMODELFIT_RR_face plots the probability density function of the model 
% overlaid on a histogram of the data.
%
% NOT IN PROBABILITY THOUGH, BUT FREQUENCY?!
%
% The model and data can either be continuous report model/data or
% 2AFC model/data.
%
%    figHand = PlotModelFit(model, params, data, [optionalParameters])
%
% The 'params' argument can be a maxPosterior, a posteriorSamples or a
% fullPosterior. If it is a fullPosterior or posteriorSamples, the variance
% of the model will be displayed in addition to the best fit model.
%
% Optional parameters to be dset in here:
%  'NumberOfBins' - the number of bins to use in display the data. Default
%  40.
%
%  'PdfColor' - the color to plot the model fit with
%
%  'ShowNumbers' - whether to show the parameter values in the corner of
%  the plot. Default is true.
%
%  'ShowAxisLabels' - whether to show the axis labels (e.g.,
%  'Probability'). Default is true.
%
%  'NewFigure' - whether to make a new figure or plot into the currently
%  active subplot. Default is false (e.g., plot into current plot).
%

function figHand = PlotModelFit_RR_face(model, params, data, varargin)
  % Extra arguments and parsing
  args = struct('PdfColor', [0.99, 0.2, 0.2], 'NumberOfBins', 360, ...
                'ShowNumbers', false, 'ShowAxisLabels', true, 'NewFigure', false);
  args = parseargs(varargin, args);
  if args.NewFigure, figHand = figure(); else figHand = []; end

  
  % Ensure there is a model.prior, model.logpdf and model.pdf
  model = EnsureAllModelMethods(model);
  model = GetModelPdfForPlot(model);

  
  
  
  if isfield(data, 'errors')
    PlotContinuousReport_RR(model, params, data, args);
  end
  
  
  

  % Label the plot with the parameter values
  if args.ShowNumbers && size(params,1) == 1
    topOfY = max(ylim);
    txt = [];
    for i=1:length(params)
      txt = [txt sprintf('%s: %.3f\n', model.paramNames{i}, params(i))];
    end
    text(max(xlim), topOfY-topOfY*0.05, txt, 'HorizontalAlignment', 'right');
  end

  % Allow the user to limit this figure to any subset of the data
  if ~isempty(figHand)
    CreateMenus(data, @redrawFig);
  end
  function redrawFig(whichField, whichValue)
    if strcmp(whichField, 'all')
      cla;
      PlotModelFit(model, params, data, ...
        'ShowAxisLabels', args.ShowAxisLabels, 'NewFigure', false, ...
        'PdfColor', args.PdfColor, 'NumberOfBins', args.NumberOfBins);
    elseif sum(ismember(data.(whichField),whichValue)) > 0
      [datasets,conditionOrder] = SplitDataByField(data, whichField);
      newData = datasets{ismember(conditionOrder,whichValue)};
      cla;
      PlotModelFit(model, params, newData, ...
        'ShowAxisLabels', args.ShowAxisLabels, 'NewFigure', false, ...
        'PdfColor', args.PdfColor, 'NumberOfBins', args.NumberOfBins);
    end
  end
end



function PlotContinuousReport_RR(model, params, data, args)
  % Plot data histogram
  
  
  
  set(gcf, 'Color', [1 1 1]);
  x = -180:4.5:180; %linspace(-180, 180, args.NumberOfBins+1)';
  err_per_sub = reshape(data.errors,90,12);
  for n = 1:12
    output(n,:) = hist(err_per_sub(:,n),x);
  end
  
  
  n = hist(data.errors(:), x);
  normed_n = n./sum(n);
  n2 = [output(1,:)' output(2,:)' output(3,:)' output(4,:)' output(5,:)' output(6,:)' output(7,:)' output(8,:)' output(9,:)' output(10,:)' output(11,:)' output(12,:)'];
  normed_n2 = n2./sum(sum(n2));
  
%   bar(x, normed_n, 'EdgeColor', [1 1 1], 'FaceColor', [.8 .8 .8]);
  colormap(flipud(bone));
  bar(x', normed_n2,'stacked')
  hold on;
  set(gca, 'XTick',[-180 -90 0 90 180],'YTick',[0 .01 .02 .03 .04 .05 .06 .07],'LineWidth',2,'Box','off','YGrid','on','Ylim',[0 .07],'Xlim',[-180 180]);

  % Plot scaled version of the prediction
  vals = linspace(-180, 180, 100)';
  multiplier = length(vals)/length(x);

  
  paramsAsCell = num2cell(params);
  p = model.pdfForPlot(vals, data, paramsAsCell{:});
  h = plot(vals, p(:) ./ sum(p(:)) .* multiplier, 'Color', args.PdfColor, ...
      'LineWidth', 3);
%   if verLessThan('matlab','8.4.0')
%       set(h, 'LineSmoothing', 'on');
%   end


  if args.ShowAxisLabels
    xlabel('error (º)', 'FontSize', 18);
    ylabel('probability', 'FontSize', 18);
  end
  % Always set ylim to 120% of the histogram height, regardless of function
  % fit NO DONT DO THIS
%   topOfY = max(n./sum(n))*1.20;
%   ylim([0 topOfY]);
%   if isfield(model, 'isOrientationModel')
%     xlim([-90 90]);
%   else
%     xlim([-180 180]);
%   end

end

