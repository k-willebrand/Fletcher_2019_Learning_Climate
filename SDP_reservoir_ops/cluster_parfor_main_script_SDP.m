%% SDP RESERVOIR OPERATIONS - CALCULATE SHORTAGE COSTS
% This version of the script is parallized and can be run on the HPC cluster.

% SDP implemenation to design the optimal operating policy for different
% storage capacities for the Mwache Dam in Mombasa, Kenya.
% (adapted from M3O toolbox)

% DESCRIPTION:
% Calculate shortage costs and unmet demands using an SDP adaptive or
% non-adaptive operating policy. To run this script, update the storage 
% values (can be an array), date, and filepath. Set the values for runParam, 
% costParam, climParam, and sys_param fields accordingly.

% NOTE: For climate-adaptive operations, set runParam.adaptiveOps = true 
% else set runParam.adaptiveOps = false. Set runParam.adaptiveOps in
% outside and within the parallized loop.

%% Set file path

clear all;
clc

%cd('C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate/SDP_reservoir_ops')

if ~isempty(getenv('SLURM_JOB_ID'))
    projpath = '/home/users/keaniw/Fletcher_2019_Learning_Climate';
    jobid = getenv('SLURM_JOB_ID');
else
    projpath = 'C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate';
    jobid = 'na';
end

addpath(genpath(projpath))
mkdir('sdp_reservoir_ops_results')

addpath('data')
addpath('SDP_code')
addpath('SDP_reservoir_ops')

%% Set run parameters for shortage cost calculations

date = '07012021'; % set date for save name

% If true, then use climate adaptive inflow distributions in the SDP.
% If false, use non-adaptive inflow distribution in the SDP.
runParam.adaptiveOps = true;
        
s_T_abs = [26.25, 26.75, 27.25, 27.95, 28.8];
s_P_abs = 66:1:97;
load('runoff_by_state_June16_knnboot_1t.mat'); % synthetic inflow data (MCM/Y)

% number of temperature and precipation states to calculate shortage costs
num_T_states = size(runoff,1); % temperature states
num_P_states = size(runoff,2); % precipitation states

% Define reservoir capacities (can be an array of capacities)
storage_vals = [85:5:95]; % set reservoir capacities (MCM)

if ~isempty(getenv('SLURM_JOB_ID'))
     %poolobj = parpool('local', str2num(getenv('SLURM_NTASKS')));
     poolobj = parpool('local', str2num(getenv('SLURM_CPUS_PER_TASK')));
     fprintf('Number of workers: %g\n', poolobj.NumWorkers)
end

% Define total reservoir capacity and dead storage (MCM)
for ss=1:length(storage_vals)
    
    storage = storage_vals(ss); % reservoir capacity (MCM)
    dead_storage = 20; % MCM
    
    parfor s_P=1:num_P_states
        
        P_state = s_P;
        
        % Define adaptive or non-adaptive operations
        runParam = struct;
        sys_param = struct;
        grids = struct;
        policy = struct;
        climParam = struct;
        costParam = struct;
        
        % If true, then use climate adaptive inflow distributions in the SDP.
        % If false, use non-adaptive inflow distribution in the SDP.
        runParam.adaptiveOps = true; % must match runParam.adaptiveOps above
        
        %% Set relevant sdp_climate.m main script parameters
        
        % Number of time periods
        runParam.N = 5; % Current SDP model requires N = 5
        
        % Number of years to generate in T, P, streamflow time series
        runParam.steplen = 20;
        
        % Urban water demand scenarios (low = 150,000; high = 300,000)[m3/d](Fletcher 2019)
        runParam.domDemand = 186000; % 2020 design demand
        
        % If false, do not include deslination plant (planning scenarios A and B
        % with current demand in table 1). If true, include desalination plant
        % (planning scenario C with higher deamnd).
        runParam.desalOn = false;
        
        % If true, save results
        runParam.saveOn = false;
        
        % Number of T,P time series to generate using stochastic weather generator
        climParam.numSampTS = 100;
        
        % Value of shortage penalty for domestic use [$/m3]
        costParam.domShortage = 2; % Fletcher et al. (2019) utilized 5
        
        % Value of shortage penalty for ag use [$/m3]
        costParam.agShortage = 1; % previously 0
        
        % demand variables
        dmd_dom = cmpd2mcmpy(runParam.domDemand); % MCM/Y
        if runParam.desalOn
            dmd_dom = cmpd2mcmpy(300000); % high domestic demand scenario for desalination (MCM/Y)
        end
        dmd_ag = 12*[2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1]; % MCM/Y
        demand = dmd_dom + dmd_ag; % MCM/Y
        
        %% calculate average shortage costs from the optimal policy for each climate state
        
        for s_T = 1:num_T_states
            
            T_state = s_T;
            disp(strcat('s: ', string(storage),' s_T:   ',string(s_T),' s_P:   ',string(s_P)));
            
            % structure with system paramenters
            sys_param.simulation.s_in  = 30 ; % initial effective storage not including dead storage (MCM)
            sys_param.simulation.delta = 1/12; % monthly time step (1/12 of a year)
            env_flow = 0; % MCM/Y
            sys_param.MEF = repmat(env_flow,12,1); % maximum environmental flow (MCM/Y)
            
            %% set SDP optimization
            
            % load synthetic inflow and evaporation data
            if runParam.adaptiveOps % adaptive: use current climate state data
                qq  = runoff{T_state,P_state,1}' ; % inflow
                ee = evaporation_sdp(storage, T_ts{T_state,1},P_ts{P_state,1},climParam, runParam)';  % cyclostationary
         
            else % non-adaptive: use initial climate state data
                qq  = runoff{1,12,1}' ; % inflow
                ee = evaporation_sdp(storage, T_ts{1,1},P_ts{12,1},climParam, runParam)';  % cyclostationary
            end
            
            sys_param.simulation.q = qq ; % MCM/Y
            
            % discretization of variables' domain (Hoa Binh case: ns=68, nu=17, nq=101)
            grids.discr_s = [0:1:(storage-dead_storage)]'; % MCM (effective storage)
            grids.discr_u = [[0:3:max(demand,[],'all')+env_flow+10],[135:25:335],[350:250:3000]]' ; % MCM/Y
            grids.discr_q = [[0:3:max(prctile(runoff{1,32,1},90))],[400:250:max(runoff{1,32,1},[],'all')+250]]' ; % MCM/Y
            sys_param.algorithm = grids;
            sys_param.integration_substep = 100; % number of mass balance monthly substeps
            
            % set algorithm parameters
            sys_param.algorithm.name = 'sdp';
            sys_param.algorithm.Hend = 0 ; % penalty set to 0
            sys_param.algorithm.T = 12;    % the period is equal 1 year
            sys_param.algorithm.gamma = 1; % set future discount factor
            tol = -1;    % accuracy level for termination
            max_it = 10; % maximum iteration for termination
            
            % Estimate cyclostationary pdf (assuming log-normal distribution)
            T = sys_param.algorithm.T ;
            Ny = length(sys_param.simulation.q)/T*climParam.numSampTS;
            
            Q = reshape( sys_param.simulation.q, T, Ny ); % uses defined inflow (i.e., adaptive or non-adaptive)
            sys_param.algorithm.q_stat = nan(T,2) ;
            
            for i = 1:T
                qi = Q(i,:) ;
                sys_param.algorithm.q_stat(i,:) = lognfit(qi); % inflow distribution parameters for policy development
            end
            
            % reshape evaporation to consider the expected monthly evaporation
            ee =  mean(reshape( ee, T, Ny ),2)';
            sys_param.simulation.ev = ee ; % MCM/Y
            
            [vv, VV] = construct_rel_matrices(grids,sys_param); % compute minimum/maximum release for each climate state
            %save ./minRel_table.mat vv
            %save ./maxRel_table.mat VV
            %load ./minRel_table.mat
            %load ./maxRel_table.mat
            
            sys_param.algorithm.min_rel = vv;
            sys_param.algorithm.max_rel = VV;
            
            %% run SDP optimization
            
            Hopt =  opt_sdp(tol, max_it, sys_param, runParam, costParam) ;
            policy.H = Hopt ;
            %save -ascii ./BellmanSDP.txt Hopt
            
            %% load Bellman function
            
            %load ./BellmanSDP.txt
            %policy.H = BellmanSDP ;
            %% run simulation of SDP-policies
            
            % simulate policy using the actual climate state data
            
            if ~runParam.adaptiveOps % non adaptive: use actual climate state data in simulations
                qq  = runoff{T_state,P_state,1}' ; % inflow for initial climate state is (1,12,1)
                ee = evaporation_sdp(storage, T_ts{T_state,1},P_ts{P_state,1},climParam, runParam)';
                sys_param.simulation.q = qq ; % MCM/Y
                
                ee =  mean(reshape( ee, T, Ny ),2);
                sys_param.simulation.ev = ee ; % MCM/Y
            end
            
            q_sim = sys_param.simulation.q;
            s_init = 30 ; % set constant initial effective reservoir storage (MCM)
            J = NaN(runParam.steplen*T,climParam.numSampTS);
            s = NaN(runParam.steplen*T+1,climParam.numSampTS);
            r = NaN(runParam.steplen*T+1,climParam.numSampTS);
            dmd_unmet = NaN(runParam.steplen*T,climParam.numSampTS);
            dmd_unmet_ag = NaN(runParam.steplen*T,climParam.numSampTS);
            dmd_unmet_dom = NaN(runParam.steplen*T,climParam.numSampTS);
            
            disp('simulation running..')
            for i=1:climParam.numSampTS
                [J(:,i), s(:,i), r(:,i), dmd_unmet(:,i), dmd_unmet_ag(:,i), dmd_unmet_dom(:,i)] = simulateGibe( q_sim(:,i), s_init, policy, sys_param, runParam, costParam);
            end
            
            shortageCost = mean(sum(J)); % $
            unmet = mean(sum(dmd_unmet)); % CM
            unmet_ag = mean(sum(dmd_unmet_ag)); % CM
            unmet_ag2 = mean(sum(dmd_unmet_ag.^2)); % CM
            unmet_dom = mean(sum(dmd_unmet_dom)); % CM
            unmet_dom2 = mean(sum(dmd_unmet_dom.^2)); % CM^2

            if runParam.saveOn
                if runParam.adaptiveOps
                    filename = strcat('sdp_reservoir_ops_results/V5adaptive_shortage_cost_domagCost21_RCP85_st',num2str(s_T),'_sp',num2str(s_P),'_s',string(storage),'_',date,'.mat');
                else
                    filename = strcat('sdp_reservoir_ops_results/V5nonadaptive_shortage_cost_domagCost21_RCP85_st',num2str(s_T),'_sp',num2str(s_P),'_s',string(storage),'_',date,'.mat');
                end
                parsave(filename, shortageCost, unmet, unmet_ag, unmet_ag2, unmet_dom, unmet_dom2);
            end
        end
    end
end


% post-processing to combine shortage cost files
cluster_main_script_SDP_postProcessing

