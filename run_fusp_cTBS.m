function [ ] = run_fusp_cTBS(subjID,outputdir)

   if nargin < 2
    outputdir = '/home/houde/data/cTBS';
    if nargin < 1
        subjID = input('Enter participant ID number:  ','s');
    end
end
if ~exist(fullfile(outputdir, subjID))
    mkdir(fullfile(outputdir, subjID))
end

% Set the fields for struct expt
expt.snum = subjID;

cd(fullfile(outputdir, expt.snum));
expt.words = {'head'};
expt.vowels = {'EH'};
expt.shift.F1 = -150;

savedir = fullfile(outputdir, expt.snum);
save(fullfile(savedir, 'expt.mat'), 'expt');
% Load predetermined lpc
 nlpc2use = 11;
 fpreemph_cut2use = 1500;
cd(outputdir)

% Set number of trials per phase and per block
baseline_n = 20;
shift1_n = 50;
washout_n = 20;

expt.ntrials = baseline_n + shift1_n + washout_n;
expt.ntrials_per_block = 9;
expt.nblocks = expt.ntrials ./ expt.ntrials_per_block;
savedir = fullfile(outputdir, expt.snum);
save(fullfile(savedir, 'expt.mat'), 'expt');
% Set up word list
expt.allWords = ceil(randperm(expt.ntrials)/(expt.ntrials/length(expt.words)));
expt.listWords = expt.words(expt.allWords);
expt.listVowels = expt.vowels(expt.allWords);
savedir = fullfile(outputdir, expt.snum);
save(fullfile(savedir, 'expt.mat'), 'expt');
%Experiment conditions   

      expt.conds = {'baseline' 'shift1' 'washout_n'};
      expt.allConds = [ones(1,baseline_n) 2.*ones(1,shift1_n) 3.*ones(1,washout_n)];
      expt.condValues.F1 = [zeros(1,baseline_n) repmat(expt.shift.F1,1,shift1_n) zeros(1,washout_n)];
      savedir = fullfile(outputdir, expt.snum);

    
savedir = fullfile(outputdir, expt.snum);
save(fullfile(savedir, 'expt.mat'), 'expt');


ps = [0 0 1 1];

% Set experiment-specific FUSP parameters
p.fusp_datadir = outputdir;
p.yes_running_fake_fusp = 0;
p.yes_debug = 0;

% init parameters
p.fusp_init.expr_dir = fullfile(sprintf('%s', expt.snum));
p.fusp_init.nframes_per_trial = 600;
p_fusp_init.ntrials_per_block = expt.ntrials_per_block;
p.fusp_init.nblocks = expt.nblocks;

% Control parameters
  p.fusp_ctrl.outbuffer_scale_fact = 10;
  p.fusp_ctrl.noise_scale_fact = 0;
% fusp_ctrl.inbuffer_source =
% fusp_ctrl.process_inbuffer =

% Start FUSP
[p,ffd] = init_fusp_lite(p);

% Save initial FUSP params
savefile = fullfile(outputdir,expt.snum,'p.mat');
save(savefile,'p');

% Experiment Code


n_trial = 1;
 h_fig = figure('units','normalized','outerposition',ps); 
        set(h_fig, 'Color', 'black')
       
for iblock=1:expt.nblocks
    fusp_advance_block(p,iblock);	% Tell FUSP what block it is
    for itrial = 1:expt.ntrials_per_block
        fusp_advance_trial(itrial);	% Tell FUSP what trial it is 
       
        text(.5,.5,expt.listWords{n_trial},'FontSize',96,'HorizontalAlignment','center') % Display the word to be spoken
        send_fusp_cpset('F1shift_Hz',expt.condValues.F1(n_trial)); % Tell fusp to shift F1
       
        
        fusp_record_start;          % Record for nframes_per_trial (init parameter, set above)
        fusp_record_stop;           % Stop recording
        pause(0.5);
        cla
        pause(0.5);
        n_trial = n_trial +1;
    end
    fusp_save_vec_hists(ffd); % Save data at end of each block
    % Take a break
    text(.5,.5, 'Take a break! Press space to continue.','FontSize',32,'HorizontalAlignment','center')
    waitforbuttonpress
    cla ;
    pause(0.5);
end
close(h);

% Close FUSP
fusp_lite_finish(ffd,p);

% Save data
savedir = fullfile(outputdir, expt.snum);
exprparams = p.fusp_init;
save(fullfile(savedir, 'exprparams.mat'), '-struct', 'exprparams')
save(fullfile(savedir, 'expt.mat'), 'expt')