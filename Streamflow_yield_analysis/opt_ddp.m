function [TSD_tot] = opt_ddp(K0,eff_inflow)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% Initialization
numNodes = length(inflow);


% Define the max and min possible effective storage states
Kmin = 0;
Kmax = K0; % assumes initial effective storage is at maximum

% Discretize storage states into n_s states
n_s = 5; %
discr_storage = linspace(0,Kmax,n_s); % discretize storage states


% In DDP, assume that T,P, and inflow are known such that the effective
% inflow (Q) is:
Q = inflow - env_flow - E; % effective inflow over time

K_t = Kmax; %establish the condition that storage is full at t=1

H = zeros(n_s,numNodes+1); %setup Bellman for storage

% Develop reservoir operating rule curve via DDP
for n = 1:numNodes
    t=numnodes+1-n;
    Q_t = Q(t);
    K_t=Knext
    
    Knext = K_t+Q_t;
        
    
    Kprev = Kprev +
release_max = K(t)+inflow(t)-env_flow-E(t); % max release
release_min = 0; % min release






H(i,t) = Bellman_ddp(H(:,t+1),discr_storage(i),eff_inflow(t));

Hend = H(:,end);
H= zeros(n_K,n_inflow_eff+1); % create Bellman
H(:,end) = Hend; % initialize Bellman to penalty function

for t = n_inflow_eff: -1:1
    for i=1:n_K; %for each discretization level of state, storage
        % calculate the TDS?
        
        opt_eq = min(TDS(t)+TDS(t+1)
        
        H(i,t) = Bellman_ddp(H(:,t+1),discr_storage(i),eff_inflow(t));
    end
end


outputArg1 = inputArg1;
outputArg2 = inputArg2;
end

