% RANSAC4 based on RANSAC3 (from 3D rectification)
% modiefied for use with 2D rectification
%
% RANSAC3 based on RANSAC2
% modified to use random sample of interplanar relationships instead of
% planes. For every random sample, it fits a DAQ model and computes inliers
% using the provided fitting and distance functions.
% @input:   x,A are the same as in RANSAC2
% @output:  M is a 4X4 matrix representin the best DAQ model

% RANSAC2 based on Peter Kovesi's RANSAC function
% adapted for multi-planar structure rectification
% in this case the data points are the planes but the number of inliers are
% the interplanar relationships that follow the orthogonality or planarity
% the only changes are in the fitting and distance functions used and
% calculation of ninliers and N (number of trials)
% @input:   x is the 4Xn, n>5, matrix of n plane vectors
%           A is the nXn planar adjacency matrix
%           rest are the same as described below for ransac
% @output:  M is the 3D homography
%           inliers is a binary matrix of size nXn (for n planes) with ones
%                   indicating the inlier relationships


% RANSAC - Robustly fits a model to data with the RANSAC algorithm
%
% Usage:
%
% [M, inliers] = ransac(x, fittingfn, distfn, degenfn, s, t, maxDataTrials, maxTrials)
%
% Arguments:
%     x         - Data sets to which we are seeking to fit a model M
%                 It is assumed that x is of size [d x Npts]
%                 where d is the dimensionality of the data and Npts is
%                 the number of data points.
%
%     fittingfn - Handle to a function that fits a model to s
%                 data from x.  It is assumed that the function is of the
%                 form:
%                    M = fittingfn(x)
%                 Note it is possible that the fitting function can return
%                 multiple models (for example up to 3 fundamental matrices
%                 can be fitted to 7 matched points).  In this case it is
%                 assumed that the fitting function returns a cell array of
%                 models.
%                 If this function cannot fit a model it should return M as
%                 an empty matrix.
%
%     distfn    - Handle to a function that evaluates the
%                 distances from the model to data x.
%                 It is assumed that the function is of the form:
%                    [inliers, M] = distfn(M, x, t)
%                 This function must evaluate the distances between points
%                 and the model returning the indices of elements in x that
%                 are inliers, that is, the points that are within distance
%                 't' of the model.  Additionally, if M is a cell array of
%                 possible models 'distfn' will return the model that has the
%                 most inliers.  If there is only one model this function
%                 must still copy the model to the output.  After this call M
%                 will be a non-cell object representing only one model.
%
%     degenfn   - Handle to a function that determines whether a
%                 set of datapoints will produce a degenerate model.
%                 This is used to discard random samples that do not
%                 result in useful models.
%                 It is assumed that degenfn is a boolean function of
%                 the form:
%                    r = degenfn(x)
%                 It may be that you cannot devise a test for degeneracy in
%                 which case you should write a dummy function that always
%                 returns a value of 1 (true) and rely on 'fittingfn' to return
%                 an empty model should the data set be degenerate.
%
%     s         - The minimum number of samples from x required by
%                 fittingfn to fit a model.
%
%     t         - The distance threshold between a data point and the model
%                 used to decide whether the point is an inlier or not.
%
%     maxDataTrials - Maximum number of attempts to select a non-degenerate
%                     data set. This parameter is optional and defaults to 100.
%
%     maxTrials - Maximum number of iterations. This parameter is optional and
%                 defaults to 1000.
%
%
% Returns:
%     M         - The model having the greatest number of inliers.
%     inliers   - An array of indices of the elements of x that were
%                 the inliers for the best model.
%
% For an example of the use of this function see RANSACFITHOMOGRAPHY or
% RANSACFITPLANE

% References:
%    M.A. Fishler and  R.C. Boles. "Random sample concensus: A paradigm
%    for model fitting with applications to image analysis and automated
%    cartography". Comm. Assoc. Comp, Mach., Vol 24, No 6, pp 381-395, 1981
%
%    Richard Hartley and Andrew Zisserman. "Multiple View Geometry in
%    Computer Vision". pp 101-113. Cambridge University Press, 2001

% Copyright (c) 2003-2006 Peter Kovesi
% School of Computer Science & Software Engineering
% The University of Western Australia
% pk at csse uwa edu au
% http://www.csse.uwa.edu.au/~pk
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in 
% all copies or substantial portions of the Software.
%
% The Software is provided "as is", without warranty of any kind.
%
% May      2003 - Original version
% February 2004 - Tidied up.
% August   2005 - Specification of distfn changed to allow model fitter to
%                 return multiple models from which the best must be selected
% Sept     2006 - Random selection of data points changed to ensure duplicate
%                 points are not selected.
% February 2007 - Jordi Ferrer: Arranged warning printout.
%                               Allow maximum trials as optional parameters.
%                               Patch the problem when non-generated data
%                               set is not given in the first iteration.

function [M, inliers, xp] = ransac4(x,K,A,fittingfn,distfn,degenfn,s,t,poptype, maxDataTrials, maxTrials,talk)
  % Test number of parameters
  error ( nargchk ( 9, 12, nargin ) );
  error ( nargoutchk ( 2, 3, nargout ) );

%   talk=1;
  
  [rows, npts] = size(x);                 
  p = 0.99;    % Desired probability of choosing at least one sample
               % free from outliers
%   p = 1 - (npts^-4);
  if nargin < 12; maxTrials = 200;    end; % Maximum number of trials before we give up.
  if nargin < 11; maxDataTrials = 1000; end; % Max number of attempts to select a non-degenerate data set.
  if nargin < 10; poptype = 1; end; % set population type to adjacent only, anything else would mean all population

  bestM = NaN;      % Sentinel value allowing detection of solution failure.
  trialcount = 0;
  bestscore =  -1;
  N = 1;            % Dummy initialisation for number of trials.

  while N > trialcount && trialcount <= maxTrials;
                % Select at random s datapoints to form a trial model, M.
                % In selecting these points we have to check that they are not in
                % a degenerate configuration.
                degenerate = 1;
                count = 1;
                while degenerate && count <= maxDataTrials;
                  % Generate s random indicies in the range 1..npts
                  % (If you do not have the statistics toolbox, or are using Octave,
                  % use the function RANDOMSAMPLE from my webpage)
                  if poptype==1
                      [ar,ac]=find(A>0);
                      ind = randsample(length(ar), s);
                      indr=ar(ind);
                      indc=ac(ind);
                  else
                      ind = randsample(npts*(npts-1), s);
                      [indr,indc] = get2DIndex(npts,ind);
                  end
                  % Test that these points are not a degenerate configuration.
                  degenerate = feval(degenfn, x(:,indr), x(:,indc));

                  if ~degenerate;
                    % Fit model to this random selection of data points.
                    % Note that M may represent a set of models that fit the data in
                    % this case M will be a cell array of models
                    [M, xp, fval] = feval(fittingfn, x(:,indr), x(:,indc), K, talk);

                    % Depending on your problem it might be that the only way you
                    % can determine whether a data set is degenerate or not is to
                    % try to fit a model and see if it succeeds.  If it fails we
                    % reset degenerate to true.
                    if fval>t
                        degenerate = 1;
                        fprintf(1,'* degenerate solution (best score: %d)\n\n',bestscore);
                    end;
                  end

                  % Safeguard against being stuck in this loop forever
                  count = count + 1;
                end

                if degenerate;
                  warning ( 'MATLAB:ransac:Output', ...
                            'Unable to select a nondegenerate data set!' );

                  trialcount = trialcount + 1;
                    if talk 
                        disp(['Trial#', num2str(trialcount), ', ninliers: -------, bestscore:', num2str(bestscore)]);
                    end
                  break;
                end

                % Once we are out here we should have some kind of model...        
                % Evaluate distances between points and model returning the indices
                % of elements in x that are inliers.  Additionally, if M is a cell
                % array of possible models 'distfn' will return the model that has
                % the most inliers.  After this call M will be a non-cell object
                % representing only one model.
                [inliers, M] = feval(distfn, M, x, t);
                inliers=inliers.*A;

                % Find the number of inliers to this model.
                if poptype==1
%                     size(inliers),size(A)
%                     ninliers = sum(sum(inliers.*A));
                    ninliers=sum(sum(inliers));
                else
                    ninliers = sum(sum(inliers));
                end

                if ninliers > bestscore;   % Largest set of inliers so far...
                  bestscore = ninliers;    % Record data for this model
                  bestinliers = inliers;
                  bestM = M;
                  bestxp = xp;
                  % Update estimate of N, the number of trials to ensure we pick,
                  % with probability p, a data set with no outliers.
                  if poptype==1
                    fracinliers =  ninliers/(sum(sum(A)));
                  else
                    fracinliers =  ninliers/(npts*npts/4);
                  end
                  pOutliers = 1 -  fracinliers^s;
                  pOutliers = min(1-eps, pOutliers);  % Avoid division by 0
                  pOutliers = max(eps, pOutliers);% Avoid log of zero
                  N = log(1-p)/log(pOutliers);
                end

                trialcount = trialcount + 1;

                if talk 
                    disp(['Trial#', num2str(trialcount), ', ninliers:', num2str(ninliers), ', bestscore:', num2str(bestscore)]);
                end
  end

  % Safeguard against being stuck in this loop forever
  if trialcount > maxTrials;
    warning ( 'MATLAB:ransac:Output', ...
              sprintf ( 'Ransac reached the maximum number of %d trials!', maxTrials ) );
  end   

  if (bestscore>s && ~any(any(isnan(bestM))))   % We got a solution
    M = bestM;
    inliers = bestinliers;
    xp = bestxp;
  else
    M = [];
    inliers = [];
    warning ( 'MATLAB:ransac:Output', '\nRansac was unable to find a useful solution!' );
  end
end