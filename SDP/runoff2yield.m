function  [yield, K, demand, unmet_dom, unmet_ag, desalsupply, desalfill]  = runoff2yield(inflow, T, P, storage, capacity, runParam, climParam,costParam)

% Inflow is a monthly time series in MCM/y starting in January
% Storage is a scalar

desalsupply = [];
desalfill = [];

numYears = runParam.steplen;
[numRuns,~] = size(T);

% check numRuns correct
dmd_dom = cmpd2mcmpy(runParam.domDemand) * ones(numRuns,12*numYears);
if runParam.desalOn
    dmd_dom = cmpd2mcmpy(300000); % high domestic demand scenario for desalination
end
dmd_ag = repmat([2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1], numRuns,numYears);
demand = dmd_dom + dmd_ag;
dead_storage = 20;
env_flow = 0; % MCM/Y
eff_storage = storage - dead_storage; % MCM

[E]  = evaporation_sdp(storage, T, P, climParam, runParam);

net_inflow = inflow-env_flow-E;

K = zeros(numRuns,numYears*12); % define effective storage time series (K)
release = zeros(numRuns,numYears*12);
K0 = eff_storage; % assume reservoir storage is initially full
desalsupply = zeros(numRuns,numYears*12);

if ~runParam.desalOn % no desalination, consider only the reservoir operation
    
    if ~runParam.optReservoir % non-optimized reservoir operation (greedy algorithm)
        
    % The following code below is from inflow2yield non-optimized
    % reservoir operation (updated since Fletcher et al. 2019)
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
        
    else % optimized reservoir operation to minimize shortage costs using DDP
        for run=1:numRuns % for each possible temperature state
            [yield_ddp,~, K_ddp] = opt_ddp(net_inflow(run,:), eff_storage, dmd_dom(run,:), dmd_ag(run,:), costParam);
            release(run,:)=yield_ddp; % release does not consider overflow
            K(run,:)=K_ddp(1:length(yield_ddp)); % K is the optimized eff_storage time series
        end
    end
    
else % with desalination
    desalfill = zeros(numRuns,numYears*12);
    desalthreshold = capacity;
    
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
        
        
        % If demand was not fully met by inflows and storage, desalinate as much as needed and can
        desalsupply(:,t) = min( max(demand(:,t) - release(:,t),0), capacity);
        
        % If storage is less than half capacity and desal capacity remains, fill to half or as much as can
        remainingcapacity = capacity - desalsupply(:,t);
        desalfill(:,t) = min(remainingcapacity, max(storage/2 - K(:,t), 0));
        K(:,t) = K(:,t) + desalfill(:,t);
    end
    
    % Check not overusing desal
    desaltotal = desalfill + desalsupply;
    if desaltotal > capacity
        error('desal supply exceeds capacity')
    end
end

% Ag demand is unmet first
unmet = max(demand - release - desalsupply, 0);
unmet_ag = min(unmet, dmd_ag);
unmet_dom = unmet - unmet_ag;

yield = release;
end