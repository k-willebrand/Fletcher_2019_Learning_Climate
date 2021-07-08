function [mr, MR] = min_max_relG3(s, moy, s_max, sys_param)

% INPUTS: effective available reservoir storage (s), month of the year (moy), maximum
% reservoir storage (s_max)

%global sys_param

HH = sys_param.integration_substep;
delta = sys_param.simulation.delta/HH; % Y
evap = sys_param.simulation.ev ; % evap in units MCM/Y

% MIN RELEASE RATE

% if available storage < env_flow demand, release as much water as possible
if s <= sys_param.MEF(moy)*delta % if initial storage cannot meet min. environmental flow, release available storage
    mr = max(s/delta,0); % MCM/Y
    
% if env_flow will not reduce storage below max, release overflow and env_flow
elseif s > s_max 
    mr = (s - s_max)/delta + sys_param.MEF(moy); % MCM/Y
    
% otherwise release the minimum env_flow
else
    mr = sys_param.MEF(moy); %MCM/Y
end

% MAX RELEASE RATE
MR = max(s/delta,0); % MCM/Y

end

