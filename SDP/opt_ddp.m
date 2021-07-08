function  [yield_ddp,release_ddp, K_ddp]  = opt_ddp(net_inflow, eff_storage, dmd_dom, dmd_ag, costParam)
% DESCRIPTION:
%   Uses DDP to find the optimal release policy if runParam.optReservoir == true
%   that minimizes the shortage costs, accounting for the cost of agriculture
%   and domestic shortages seperately as defined in costParam

% INPUTS:
%   net_inflow is the net inflow into the reservoir (inflow - environmental
%   flow - evaporation) in MCM/y starting in January
%   eff_storage (K) is a scalar representing total reservoir storage - dead storage
%   dmd_dom is a monthly time series of domestic demands in MCM/y
%   dmd_ag is a monthly time series of agricultural demand in MCM/y
%   costParam is a structure defined in sdp_climate that defines
%   agricultural and domestic shortage costs

% OUTPUTS:
%   yield_ddp is a monthly time series of met demand from the optimized reservoir
%   release_ddp is a monthly time series of total release from the optimized
%   reservoir (including excess overflow)
%   K_ddp is a monthly time series of effective reservoir storages (no dead storage) for the optimized
%   reservoir

%% == SETUP ==
n = length(net_inflow); % number of decision periods (months)
K_ddp = zeros(1,n+1); % MCM
yield_ddp = zeros(1,n); % MCM/Y
release_ddp = zeros(1,n); % MCM/Y
delta = 1/12; % monthly time step (Y)

%K0 = eff_storage;
K0 = 30; % MCM assume constant initial reservoir storage
demand = dmd_dom + dmd_ag; % MCM/Y

%nK = 150; % assume 150 discrete effective storage states 
%discr_K = linspace(0,eff_storage,nK); % define the nK possible discrete effective storage states
discr_K = [0:1:eff_storage]; % MCM
nK = length(discr_K);
discr_q = net_inflow; % consider n discrete net inflow disturbances(equals net_inflows)

costs_table = cell(nK,n); % create a cell array structure to store shortage costs
poss_release_table = cell(nK,n); % create a cell array structure to store possible releases

H = zeros(nK,n+1); % create the Bellman for cumulative shortage costs (H(n+1) = 0 for initial calculation)

%% == INITIATION FOR FINDING THE OPTIMAL RELEASE POLICY == 
% Find all possible releases and correponding shortage costs for each
% discrete storage state (nK states) at each time/decision period(n)

for t = 1:n
    q_now = discr_q(t); % net inflow disturbance for period t
    targ_dmd_ag = dmd_ag(t); % target agricultural demand for period t
    targ_release = demand(t); % target total release (demand) for period t
    
    % -- FIND ALL POSSIBLE RELEASES AND CORRESONDING SHORTAGE COSTS THROUGH THE MULTI-MONTH NETWORK --
    for k = 1:nK %for each possible discrete effective storage state at time t
        
        K_state = discr_K(k); %define current possible effective storage state
        
        % define minimum and maximum possible releases
        min_release = 0; % limit the minimum release to 0 (or env_flow?)
        %max_release = K_state+q_now; % limit max release to current storage + net inflow
        max_release = K_state/delta+q_now; % MCM/Y
        
        % Calculate all possible release decisions from K_state relative
        % to the defined discrete storage states (discr_K),correcting for 
        % releases outside the calculated max and min limits
        poss_release = (K_state - discr_K)/delta + q_now; % MCM/Y
        poss_release(poss_release<min_release)= []; % release < minimum release not possible 
        poss_release(poss_release>max_release)= max_release;
        % STORE POSSIBLE RELEASES FOR STATE (k) AND PERIOD (t)
        poss_release_table{k,t} = poss_release; 
        
        % Calculate the single-period shortage cost from the possible
        % release decisions. Only penalize release decisions 
        % when release < target release
        
        poss_costs = zeros(1,length(poss_release));
        for i = 1:length(poss_release)
            if poss_release(i)>=targ_release
                poss_costs(1,i) = 0; 
            else % insufficient release, domestic demand is met first
                poss_unmet = max((targ_release - poss_release)*delta, 0); % MCM
                poss_unmet_ag = min(poss_unmet, targ_dmd_ag*delta); % MCM
                poss_unmet_dom = poss_unmet - poss_unmet_ag; % MCM
                poss_costs(1,i) = (costParam.domShortage*(poss_unmet_dom(i))^2 +costParam.agShortage*(poss_unmet_ag(i))^2)*1E6;
            end
        end
        % STORE POSSIBLE SHORTAGE COSTS FOR STATE (k) AND PERIOD (t)
        costs_table{k,t} = poss_costs;
    end
end

%% === FIND THE OPTIMAL POLICY VIA DDP THAT MINIMIZES SHORTAGE COSTS THROUGH THE NETWORK ==
% Find the optimal release decision by minimizing the cost function. 
% Run this loop only once as steady state policy is not required.

release_opt = zeros(nK,n+1); 
K_opt = zeros(nK,n+1); 

for t = n:-1:1 % for each period (backwards recursion)
    for k = 1:nK %for each possible effective storage state
        % accounts for if number of possible releases < nK
        [costs_exist,~] = find(costs_table{k,t}(:)>=0);
        
        % find index that minimizes the cost function. If there exists 
        % multiple minimum costs, select the smaller release decision
        [idx_opt,~] = find(costs_table{k,t}(:)+H(costs_exist,t+1) == min(costs_table{k,t}(:)+H(costs_exist,t+1)));
        [idx_opt,~] = max(idx_opt); % if multiple smaller releases, release the one that yields the greater storage
       
        % STORE MINIMUM SHORTAGE COST FOR STATE (k) AND PERIOD (t)
        costs_opt = costs_table{k,t}(1,idx_opt); 
        
        % Update the cumulative cost function (H) given optimal release decision
        if isempty(costs_opt) == 0
            H(k,t) = H(idx_opt,t+1) + costs_opt;
            
            % Store the optimal release and resulting next storage state
            release_opt(k,t)= poss_release_table{k,t}(1,idx_opt); %the optimal release decision
            K_opt(k,t+1) = discr_K(1,idx_opt); % the optimal next effective storage state
        else
            H(k,t)=nan;
        end
    end
end

%% == APPLY OPTIMIZED RULE CURVE TO ACTUAL SIMULATION TO FIND RELEASE AND UNMET DEMANDS ==
% Note that net inflow is consistent with the discrete disturbance
% states used in the derivation of the optimal policy

K_ddp(1)=K0; % assume that the initial effective storage is full

for t = 1:n
    %Find optimal release decision from optimal policy for storage and time
    [~,idx_r] = find(discr_K == K_ddp(t));
    release_ddp(t) = release_opt(idx_r,t);

    yield_ddp(t) = min(demand(t),release_ddp(t)); %for calculation of yield, overflow is not be considered
    
    %Calculate the next effective storage based on optimal release
    K_ddp(1,t+1)=K_opt(idx_r,t+1); % MCM
end
end
