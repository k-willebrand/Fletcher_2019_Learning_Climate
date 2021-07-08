function [J, s_GIII, r_GIII, unmet_GIII, unmet_ag_GIII, unmet_dom_GIII] = simulateGibe( q, s_in, policy, sys_param, runParam, costParam )
    
%global sys_param runParam costParam
        
% day of the year
q_sim = [ nan; q ];
H = length(q_sim) - 1;
T = 12;

% vectors initialization 
s_GIII = nan(length(q_sim),1);
r_GIII = nan(length(q_sim),1);

% initial conditions
s_GIII(1) = s_in ;

% simulation loop
%disp('simulation running..')
for t = 1:H
    %disp(t);
    moy = mod(t,12);
    moy( moy == 0 ) = 12;
    
    % release decision
    discr_s = sys_param.algorithm.discr_s;
    discr_q = sys_param.algorithm.discr_q;
    discr_u = sys_param.algorithm.discr_u;
    
    min_rel = sys_param.algorithm.min_rel;
    max_rel = sys_param.algorithm.max_rel;
    
    sys_param.algorithm.stat_t = sys_param.algorithm.q_stat(moy,:) ;
    
    % Minimum and maximum release for current storage and inflow:
    [ ~ , idx_q ] = min( abs( discr_q - q_sim(t+1) ) );
    
    v =interp1q( discr_s , min_rel( : , idx_q, moy ) , s_GIII(t) );
    sys_param.simulation.vv = repmat( v, 1, length(discr_q) );
    
    V = interp1q( discr_s , max_rel( : , idx_q, moy ) , s_GIII(t) );
    sys_param.simulation.VV = repmat( V, 1, length(discr_q) );
    [ ~, idx_u ] = Bellman_sdp( policy.H(:,moy) , s_GIII(t), moy, sys_param, runParam, costParam);
    
    % Choose one decision value (idx_u can return multiple equivalent decisions)
    uu = extractor_ref( idx_u , discr_u ); % corresponding discretized optimal release decision
    
    [s_GIII(t+1), r_GIII(t+1)] = massBalance( s_GIII(t), uu, q_sim(t+1), moy, discr_s(end), sys_param);
end

% shortage cost calculation
% demands
numYears = runParam.steplen;
dmd_dom = cmpd2mcmpy(runParam.domDemand) * ones(T*numYears,1);
if runParam.desalOn
    dmd_dom = cmpd2mcmpy(300000)* ones(T*numYears,1); % high domestic demand scenario for desalination
end
dmd_ag = repmat(12*[2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1],1, numYears)'; % MCM/Y
demand = dmd_dom + dmd_ag; % MCM/Y

% Calclate unmet demands from releases and this period's shortage cost (G)
% ag demands are unmet before dom demands
delta = 1/12; % timestep in Y
unmet_GIII = max((demand - r_GIII(2:end))*delta*1E6, 0); % CM
unmet_ag_GIII = min(unmet_GIII, dmd_ag*delta*1E6); % CM
unmet_dom_GIII = unmet_GIII - unmet_ag_GIII; % CM

% 20 year shortage costs ($) 
J = (costParam.domShortage*(unmet_dom_GIII).^2 +costParam.agShortage*(unmet_ag_GIII).^2); % CUBIC METERS ^ 2

end


