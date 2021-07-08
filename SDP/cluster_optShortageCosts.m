function  [shortageCost, yield, K, unmet_dom, unmet_ag, unmet_dom_squared, unmet_ag_squared]  =...
    cluster_optShortageCosts(inflow, T, P, runParam, climParam, costParam,index_s_p,index_s_t, storage, s, date)

% DESCRIPTION:
%   Uses DDP to find the optimal release policy if runParam.optReservoir == true
%   that minimizes the shortage costs, accounting for the cost of agriculture
%   and domestic shortages seperately as defined in costParam. This script
%   structure has been adapted for running on the cluster and does not
%   consider desalination. Run for each temperature and precipitation state
%   combination and save results in individual files (note - currently for
%   each storage

% INPUTS:
%   inflow is a monthly time series of runoff in MCM/y starting in January
%   T is a monthly time series of temperature for 100 samples corresponding to index_s_t (from cell of T_ts{_,_,_})
%   P is a monthly time series of precipitation for 100 samples corresponding to index_s_p (from cell of P_ts{_,_,_})
%   storage is the total storage capacity of the reservoir in MCM (i.e. [80, 120])
%   costParam is a structure defined in sdp_climate that defines agricultural and domestic shortage costs

% OUTPUTS:
%   shortageCost is the mean expected shortage cost for the T and P states
%   yield is a monthly time series of met demand from releases from the optimized reservoir
%   K is a monthly time series of effective reservoir storages (no dead storage) for the optimized
%   reservoir

numYears = runParam.steplen;
[numRuns,~] = size(T);

% check numRuns correct
dmd_dom = cmpd2mcmpy(runParam.domDemand) * ones(numRuns,12*numYears); % MCM/Y
%dmd_ag = repmat([2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1], numRuns,numYears); % MCM/month
dmd_ag = repmat(12*[2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1], numRuns,numYears); % MCM/Y
demand = dmd_dom + dmd_ag; % MCM/Y (monthly demand rate in MCM/Y)
dead_storage = 20;
env_flow = 0;

K = zeros(numRuns,numYears*12); % define effective storage time series (K)
release = zeros(numRuns,numYears*12);
desalsupply = zeros(numRuns,numYears*12);

% optimize reservoir operation to minimize shortage costs using DDP for
% each capacity

eff_storage = storage - dead_storage; %should have [60, 100]

[E]  = evaporation_sdp(storage, T, P, climParam, runParam);
net_inflow = inflow-env_flow-E;
%K0 = eff_storage; % assume reservoir storage is initially full
K0 = 30; % MCM - assume constant initial storage

for run=1:numRuns % for each possible temperature state
    [yield_ddp,~, K_ddp] = opt_ddp(net_inflow(run,:), eff_storage, dmd_dom(run,:), dmd_ag(run,:), costParam);
    release(run,:)=yield_ddp; % release does not consider overflow
    K(run,:)=K_ddp(1:length(yield_ddp)); % K is the optimized eff_storage time series
end

% Ag demand is unmet first
delta = 1/12; % time step in years
yield_mdl = release;
%unmet_mdl = max(demand - release - desalsupply, 0);
unmet_mdl = max((demand - release - desalsupply)*delta, 0); % MCM
unmet_ag_mdl = min(unmet_mdl, dmd_ag*delta); % MCM
unmet_dom_mdl = unmet_mdl - unmet_ag_mdl; % MCM

unmet_ag = mean(sum(unmet_ag_mdl,2));
unmet_dom = mean(sum(unmet_dom_mdl,2));
unmet_ag_squared = mean(sum(unmet_ag_mdl.^2,2)); % MCM
unmet_dom_squared = mean(sum(unmet_dom_mdl.^2,2)); % MCM
yield = mean(sum(yield_mdl,2));

% Calculate shortage costs incurred for unmet demand, using
% differentiated costs for agriculture and domestic shortages and
% quadratic formulation
shortageCost =  (unmet_ag_squared * costParam.agShortage + unmet_dom_squared * costParam.domShortage) * 1E6;

savename_shortageCost = strcat('reservoir_results/cluster_shortage_costs_st',num2str(index_s_t),'_sp',num2str(index_s_p),'_s',num2str(storage),'_', date)
%save(savename_shortageCost, 'shortageCost', 'yield', 'unmet_ag', 'unmet_dom', 'unmet_ag_squared', 'unmet_dom_squared')
save(savename_shortageCost, 'shortageCost')

end