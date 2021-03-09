load('runoff_by_state_Mar16_knnboot_1t.mat')

%% This is the non-optimized reservoir model from inflow2yield
unmet_inflow2yield = NaN(100,240);
unmet_ag_inflow2yield= NaN(100,240);
unmet_dom_inflow2yield = NaN(100,240);
yield_inflow2yield = NaN(100,240);

numYears = 20;

dmd_dom = cmpd2mcmpy(150000) * ones(1,12*numYears);
dmd_ag = repmat([2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1], 1,numYears);
demand = dmd_dom + dmd_ag;
dead_storage = 20;
env_flow = 0;
storage = 120;
eff_storage = storage - dead_storage;
K0 = eff_storage;


for i=1:100
    inflow = runoff{90,30,1}(i,:);
    [E]  = evaporation(storage, T_ts{90,1}(i,:), P_ts{30,1}(i,:));
    K = NaN(240);
    release = NaN(240);
    for t = 1:length(inflow)
        if t == 1
            Kprev = K0;
        else
            Kprev = K(t-1);
        end
        
        % If demand is less than effective inflow, release all demand and add storage up to limit
        if demand(t) < inflow(t) - env_flow - E(t)
            release(t) = demand(t);
            K(t) = min(Kprev - release(t) + inflow(t) - env_flow - E(t), eff_storage);
            % If demand is greater than effective inflow, but less than available storage, release all demand
        elseif demand(t) < Kprev + inflow(t) - env_flow - E(t) && demand(t) > inflow(t) - env_flow - E(t)
            release(t) = demand(t);
            K(t) = Kprev - release(t) + inflow(t) - env_flow - E(t);
            % If demand is greater than effective inflow and storage, release as much as available
        else
            release(t) = Kprev + inflow(t) - env_flow - E(t);
            K(t) = 0;
        end
    % KEANI JUST ADDED THIS
    
    % Ag demand is unmet first
    unmet_inflow2yield(i,t) = max(demand(t) - release(t), 0);
    unmet_ag_inflow2yield(i,t) = min(unmet_inflow2yield(i,t), dmd_ag(t));
    unmet_dom_inflow2yield(i,t) = unmet_inflow2yield(i,t) - unmet_ag_inflow2yield(i,t);
    yield_inflow2yield(i,t) = release(t);
end
end

%% This is the non-optimized reservoir model in runoff2yield from sdp_climate 
 
clear release

numYears = 20;
[numRuns,~] = size(T_ts{90,1});

dmd_dom = cmpd2mcmpy(150000) * ones(1,12*numYears);
dmd_ag = repmat([2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1], numRuns,numYears);
demand = dmd_dom + dmd_ag;

inflow = runoff{90,30,1};
dead_storage = 20;
env_flow = 0;
storage = 120;
eff_storage = storage - dead_storage;
K0 = eff_storage;

[E]  = evaporation_sdp(storage, T_ts{90,1}, P_ts{30,1}, climParam, runParam);

for t = 1:numYears*12
    if t == 1
        Kprev = K0;
    else
        Kprev = K(t-1);
    end
    
    % If demand is less than effective inflow, release all demand and add storage up to limit
    indLess = demand(:,t) < inflow(:,t) - env_flow - E(:,t);
    release(indLess,t) = demand(indLess,t);
    K(indLess,t) = min(Kprev - release(indLess,t) + inflow(indLess,t) - env_flow - E(indLess,t), eff_storage);
    % If demand is greater than effective inflow, but less than available storage, release all demand
    indMid = demand(:,t) < Kprev + inflow(:,t) - env_flow - E(:,t) & demand(:,t) > inflow(:,t) - env_flow - E(:,t);
    release(indMid,t) = demand(indMid,t);
    K(indMid,t) = Kprev - release(indMid,t) + inflow(indMid,t) - env_flow - E(indMid,t);
    % If demand is greater than effective inflow and storage, release as much as available
    indGreat = ~indLess & ~indMid;
    release(indGreat,t) = Kprev + inflow(indGreat,t) - env_flow - E(indGreat,t);
    K(indGreat,t) = 0;
    
end

% Ag demand is unmet first
unmet_runoff2yield_Fletcher = max(demand - release, 0);
unmet_ag_runoff2yield_Fletcher = min(unmet_runoff2yield, dmd_ag);
unmet_dom_runoff2yield_Fletcher = unmet_runoff2yield - unmet_ag_runoff2yield;
yield_runoff2yield_Fletcher = release;

%% AND THIS IS THE UPDATED RUNOFF TO YIELD AS OF 2/10/2021
clear release

numYears = 20;
[numRuns,~] = size(T_ts{90,1});

dmd_dom = cmpd2mcmpy(150000) * ones(1,12*numYears);
dmd_ag = repmat([2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1], numRuns,numYears);
demand = dmd_dom + dmd_ag;

inflow = runoff{90,30,1};
dead_storage = 20;
env_flow = 0;
storage = 120;
eff_storage = storage - dead_storage;
K0 = eff_storage;

[E]  = evaporation_sdp(storage, T_ts{90,1}, P_ts{30,1}, climParam, runParam);

numYears = runParam.steplen;
[numRuns,~] = size(T_ts{90,1});

 for i=1:numRuns
            for t = 1:length(inflow)
                if t == 1
                    Kprev = K0;
                else
                    Kprev = K(i,t-1);
                end
                
                % If demand is less than effective inflow, release all demand and add storage up to limit
                if demand(i,t) < inflow(i,t) - env_flow - E(i,t)
                    release(i,t) = demand(i,t);
                    K(i,t) = min(Kprev - release(i,t) + inflow(i,t) - env_flow - E(i,t), eff_storage);
                    % If demand is greater than effective inflow, but less than available storage, release all demand
                elseif demand(i,t) < Kprev + inflow(i,t) - env_flow - E(i,t) && demand(i,t) > inflow(i,t) - env_flow - E(i,t)
                    release(i,t) = demand(i,t);
                    K(i,t) = Kprev - release(i,t) + inflow(i,t) - env_flow - E(i,t);
                    % If demand is greater than effective inflow and storage, release as much as available
                else
                    release(i,t) = Kprev + inflow(i,t) - env_flow - E(i,t);
                    K(i,t) = 0;
                end
            end            
 end
        
        

% Ag demand is unmet first
unmet_runoff2yield = max(demand - release, 0);
unmet_ag_runoff2yield = min(unmet_runoff2yield, dmd_ag);
unmet_dom_runoff2yield = unmet_runoff2yield - unmet_ag_runoff2yield;
yield_runoff2yield = release;

%% LARGER CALL FROM SDP_CLIMATE.M AS OF 2/10
 [yield_mdl, K, dmd, unmet_dom_mdl, unmet_ag_mdl, desalsupply, desalfill]  = ...
                            runoff2yield(runoff{90,30,1}, T_ts{90,1}, P_ts{30,1}, 120, 0, runParam, climParam, costParam);