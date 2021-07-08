function [s1,r1] = massBalance( s, u, q, moy ,s_max, sys_param)
% Output:
%      s1 - final storage. 
%      r1 - release over the 24 hours. 
%
% Input:
%       s - initial storage. 
%       u - release decision 
%       q - inflow 
%       dt - day of the year
%
% See also MIN_RELEASE, MAX_RELEASE

%global sys_param

HH = sys_param.integration_substep;
delta = sys_param.simulation.delta/HH; % Y
s_ = nan(HH+1,1);
r_ = nan(HH+1,1);
evap = sys_param.simulation.ev  ; % evap in MCM/Y

s_(1) = s;
for i=1:HH
    s_eff = max(s_(i) + delta*q - delta*evap(moy),0); % effective storage
    [r_min, r_max] = min_max_relG3(s_eff, moy, s_max, sys_param) ;
    r_(i+1) = min( r_max , max( r_min , u ) ); % MCM/Y
    s_(i+1) = s_eff - delta*r_(i+1); % MCM
end

s1 = s_(HH);
r1 = mean(r_(2:end));

