function chan_resp_shift = doIEM_TRs(x, n_ori_chans, trn_data, tst_data, tst_label, stim_mask, shift_to) 
% run an IEM by looping over all points intermediate to the basis function
% centers. This will produce a 180 point TF in the case of orientation.
% This will run over all the timepoints you give it in your input data.
% js 06.27.2017, debugged by rr 07.12.2017, adapted by RR 05.28.2018
% 
% input:
% --> x: x-axis (in degree)
% --> n_ori_chans: number of basis functions (say, 9)
% --> trn_data: IEM training data (num_train_trials x num_voxels)
% --> tst_data: Test data (num_TRs x num_voxels x num_wm_trials)
% --> tst_label: orientation labels of test data (vector of num_trials) 
% --> stim_mask: matrix of num_trials x 180 degree with a "1" for each 
%       trial at the orientation presented, and zeros everywhere else
% --> shift_to: center on this orientation (default is 90). 

if nargin < 7
    shift_to = 90;
end

% set some stuff up...
nt = size(tst_data,3); % number of trials in test data
ntrs = size(tst_data,1); % number of trials in test data
chan_resp  = NaN(ntrs,length(x),nt);           
chan_resp_shift = NaN(ntrs,length(x),nt);

% anonymous function to make basis set of tuning functions
basis_pwr = n_ori_chans-1;
make_basis_function = @(xx,mu) (cosd(xx-mu)).^basis_pwr;
% Note: in a circular space with xx from 0-pi, mu would be between
% 0 and pi, and the function would use cos instead of cosd
        

step_size = length(x)/n_ori_chans; % will need this many steps to cover 180 degrees
for b = 1:step_size
    
    chan_center = b:step_size:180;
    
    % make basis functions
    basis_set = NaN(180,n_ori_chans); % basis-set can go in here
    for cc = 1:n_ori_chans
        basis_set(:,cc) = make_basis_function(x,chan_center(cc));
    end
    
    % now generate the design matrix
    trnX = stim_mask*basis_set;
    if rank(trnX)~=size(trnX,2)
        fprintf('\nrank deficient training set Design Matrix\nReturning...\n')
        return;
    end
            
    % compute weights
    w = trnX\trn_data; % uses design matrix (for these channel centers) and training data 

    % compute the stimulus reconstruction for each timepoint, filling in the
    % predicted orientations corresponding to the current centers of the 
    % basis functions. So here we reconstruct the memory orientation (after
    % having trained on the localizer donut)
    for tr = 1:ntrs
        chan_resp(tr,chan_center,:) = ((w*w')\w*squeeze(tst_data(tr,:,:)));
    end
    
end % end loop over basis set centers.        

% then center the TFs from each trial on a common point. 
for tr = 1:ntrs
    for trial = 1:nt % for every test trial
        chan_resp_shift(tr,:,trial) =  wshift('1D', chan_resp(tr,:,trial),tst_label(trial)-shift_to);
    end
end


