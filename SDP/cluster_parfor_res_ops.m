%% Script to run DDP optimized reservoir operations on cluster 


%% Setup 

% Set Project root folder and Add subfolders to path; runs either on desktop 
% or on a cluster using SLURM queueing system 
if ~isempty(getenv('SLURM_JOB_ID'))
    projpath = '/home/users/keaniw/Fletcher_2019_Learning_Climate';
    jobid = getenv('SLURM_JOB_ID');
    
else
    projpath = 'C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate';
    jobid = 'na';
end
addpath(genpath(projpath))
mkdir('reservoir_results')


%% Parameter

% Set up run paramters
% Two purposes: 1) different pieces can be run independently using
% saved results and 2) different planning scenarios (table 1) can be run

runParam = struct;

% Number of time periods
runParam.N = 5; % Current SDP model requires N = 5 

% If true, run SDP to calculate optimal policies
runParam.runSDP = false; 

% Number of years to generate in T, P, streamflow time series
runParam.steplen = 20; 

% If true, simulate runoff time series from T, P time series using CLIRUN. If false, load saved.
runParam.runRunoff = false; 

% If true, simulate T, P time series from mean T, P states using stochastic weather gen. If false, load saved.
runParam.runTPts = false; 

% If true, change indices of saved runoff time series to correspond to T, P states (needed for parfor implementation)
runParam.runoffPostProcess = false; 

% If true, use optimal policies from SDP to do Monte Carlo simulation to esimate performance
runParam.forwardSim = false; 

% If true, calculate Bellman transition matrix from BMA results. If false, load saved.
runParam.calcTmat = false; 

% If true, perform DDP to optimize reservoir operatations in the water
% system model. If false, use non-optimized fixed rule curve for reservoir
% operations
runParam.optReservoir = true;

% If true, calculate water shortage costs from runoff times series using water system model. If false, load saved.
runParam.calcShortage = true; 

% Urban water demand scenarios (low = 150,000; high = 300,000)[m3/d](Fletcher 2019)
runParam.domDemand = 150000; 

% If false, do not include deslination plant (planning scenarios A and B
% with current demand in table 1). If true, include desalination plant
% (planning scenario C with higher deamnd).
runParam.desalOn = false; 

% Size of desalination plant for small and large versions [MCM/y]
runParam.desalCapacity = [60 80];

% If using pre-saved runoff time series, name of .mat file to load
%runParam.runoffLoadName = 'runoff_by_state_Mar16_knnboot_1t';
runParam.runoffLoadName = 'runoff_by_state_June16_knnboot_1t';

% If using pre-saved shortage costs, name of .mat file to load
runParam.shortageLoadName = 'shortage_costs_28_Feb_2018_17_04_42';

% If true, save results
runParam.saveOn = true;

% Set up climate parameters
climParam = struct;

%  Number of simulations to use in order to estimate absolute T and P
%  values based on relative difference from one time period to the next
climParam.numSamp_delta2abs = 100000;

% Number of T,P time series to generate using stochastic weather generator
climParam.numSampTS = 100;

% If true, test number of simulated climate values are outside the range of
% the state space in order to ensure state space validity
climParam.checkBins = false;


% Set up cost parameters; vary for sensitivity analysis
costParam = struct;

% Value of shortage penalty for domestic use [$/m3]
costParam.domShortage = 1;

% Value of shortage penalty for ag use [$/m3]
costParam.agShortage = 0;

% Discount rate
costParam.discountrate = 0.03;


%% SDP State and Action Definitions 

N = runParam.N;

% Define state space for mean 20-year precipitation and temperature

% Percent change in precip from one time period to next
climParam.P_min = -.3;
climParam.P_max = .3;
climParam.P_delta = .02; 
s_P = climParam.P_min : climParam.P_delta : climParam.P_max;
climParam.P0 = s_P(15);
climParam.P0_abs = 77; %mm/month
M_P = length(s_P);

% Change in temperature from one time period to next
climParam.T_min = 0;
climParam.T_max = 1.5;
climParam.T_delta = 0.05; % deg C
s_T = climParam.T_min: climParam.T_delta: climParam.T_max;
climParam.T0 = s_T(1);
climParam.T0_abs = 26;
M_T = length(s_T);

% Absolute temperature values
T_abs_max = max(s_T) * N;
s_T_abs = climParam.T0_abs : climParam.T_delta : climParam.T0_abs+ T_abs_max;
M_T_abs = length(s_T_abs);
T_bins = [s_T_abs-climParam.T_delta/2 s_T_abs(end)+climParam.T_delta/2];
T_Temp_abs = zeros(M_T_abs,M_T_abs,N);

% Absolute percip values
P_abs_max = max(s_P) * N;
s_P_abs = 66:1:97;
M_P_abs = length(s_P_abs);
P_bins = [s_P_abs-climParam.P_delta/2 s_P_abs(end)+climParam.P_delta/2];
T_Precip_abs = zeros(M_P_abs,M_P_abs,N);

% State space for capacity variables
s_C = 1:4; % 1 - small;  2 - large; 3 - flex, no exp; 4 - flex, exp
M_C = length(s_C);
storage = [80]; % small dam, large dam capacity in MCM

% Actions: Choose dam option in time period 1; expand dam in future time
% periods
a_exp = 0:4; % 0 - do nothing; 1 - build small; 2 - build large; 3 - build flex
            % 4 - expand flex 
 

%% Load runoff

% If not calculating runoff now, load previously calculated runoff 
load(runParam.runoffLoadName);

%% Use reservoir operation model to calculate yield and shortage costs


% prefdir
% 
% distcomp.feature( 'LocalUseMpiexec', false );
% 
% poolobj = gcp('nocreate');
% delete(poolobj);
% pc = parcluster('local');
% pc.JobStorageLocation
% 
% 
if ~isempty(getenv('SLURM_JOB_ID'))
     %poolobj = parpool('local', str2num(getenv('SLURM_NTASKS')));
     poolobj = parpool('local', str2num(getenv('SLURM_CPUS_PER_TASK')));
     fprintf('Number of workers: %g\n', poolobj.NumWorkers)
end

date='20210701'
t = 1;

parfor index_s_p = 1:length(s_P_abs)
    %for index_s_t= 1:length(s_T_abs) 
    for index_s_t= 1:size(runoff,1) % number of s_T_abs
        for s = 1:length(storage)
             savename_shortageCost = strcat('reservoir_results/cluster_shortage_costs_st',...
                 num2str(index_s_t),'_sp',num2str(index_s_p),'_s',num2str(storage(s)),'_', date, '.mat') % note - removed from name "reservoir_results/"
             if isfile(savename_shortageCost)
                 fprintf('File already exists: %s', savename_shortageCost)
             else
                 cluster_optShortageCosts(runoff{index_s_t,index_s_p,t}, T_ts{index_s_t,t}, P_ts{index_s_p,t}, ...
                 runParam, climParam, costParam,index_s_p,index_s_t, storage(s), s, date);       
             end
        end
    end
end