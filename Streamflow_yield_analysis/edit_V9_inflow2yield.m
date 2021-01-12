function  [yield, K, demand, unmet_dom, unmet_ag, Hf,net_inflow]  = edit_V9_inflow2yield(inflow, T, P, storage, runParam, costParam)

% PURPOSE OF THIS SCRIPT - when there are no release decisions (i.e.
% reservoir is EMPTY) what should the system do? This occurs when the inflows are VERY low...Also what should H be?

% IN THIS V9, THE OPTIMAL FUNCTION IS THE SHORTAGE COST FUNCTION 

% Inflow is a monthly time series in MCM/y starting in January
% Storage is a scalar 

numYears = length(inflow)/12;

dmd_dom = cmpd2mcmpy(150000) * ones(1,12*numYears);
dmd_ag = repmat([2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1], 1,numYears);
demand = dmd_dom + dmd_ag;
dead_storage = 20;
env_flow = 0;
eff_storage = storage - dead_storage;

[E]  = evaporation(storage, T, P );  

net_inflow = inflow-env_flow-E; %net inflow

K = zeros(1,length(inflow));
release = zeros(1,length(inflow));
comp_release = zeros(1,length(inflow)); %comp_release is the release for optimized res that assumes if release>demand, release is equilvalent to the demand for comparison purposes

K0 = eff_storage;

n = length(inflow); % number of decision seasons (nodes)

% allocate space for the final cost function (TDS)
Hf = zeros(1,n);

if runParam.optReservoir
    nK = 150; %define the number of discrete storage states
    discr_K = linspace(0,eff_storage,nK); % define the possible discrete storage state
    discr_q = net_inflow; %for now assume n discrete inflow disturbances(corresponds with known inflows)
    
    H = zeros(nK,n+1); % create the Bellman (with n+1 as zero, we can start with H(x) = 0)
    
    % -- optimize the rule curve via DDP (backward recursive) --
    TSD_table = cell(nK,n); % create a cell array structure to store TSD?
    poss_release_table = cell(nK,n); % create a cell array structure to store possible discrete releases
    

    %% == INITIATION FOR FINDING RELEASE POLICY (H) ==
    %   find all possible releases and correponding TSD values for each nK
    %   storage state and time period/decision period
    
    for t = 1:n
        q_now = discr_q(t); % time period's net inflow disturbance
        targ_release = demand(t); % time period's target minimum release (demand)
        targ_dmd_dom = dmd_dom(t);
        targ_dmd_ag = dmd_ag(t);
     
        % -- FIND ALL POSSIBLE RELEASES AND CORRESONDING TSD THROUGH THE MULTI-MONTH NETWORK --
        
        for k = 1:nK %for each possible storage state at time t
            
            K_state = discr_K(k); %define current possible storage state
            
            % define minimum and maximum possible releases
            min_release = 0; %assume the minimum release to be 0 (or env_flow?)
            max_release = K_state+q_now; %limit max release to current storage + net inflow
            
            % Calculate all possible release decisions from K_state to
            % the other possible storage states (discr_K). Store all
            % options in a cell array called poss_release_table{k,t}
            poss_release = K_state - discr_K + q_now;
            poss_release(poss_release<min_release)=[]; % release < minimum release not possible
            poss_release(poss_release>max_release)=max_release; % release > max release not possible
            poss_release_table{k,t} = poss_release; % STORE THE POSSIBLE RELEASES FOR STATE AND TIME
            
            % Calculate the single-period cost function from the possible 
            % release decisions (TSD from release target). Store associated
            % single-period costs in a cell array called TSD_table{k,t}.
            poss_TSD = zeros(1,length(poss_release));
            
            % only penalize release decisions when release < target release
            poss_unmet = max(targ_release - poss_release, 0);
            poss_unmet_ag = min(poss_unmet, targ_dmd_ag);
            poss_unmet_dom = poss_unmet - poss_unmet_ag;
            for i = 1:length(poss_release)
                if poss_release(i)>=targ_release
                    poss_TSD(1,i) = 0; % minimum release target is accomplished
                else % domestic demand is met first
                    poss_TSD(1,i) = costParam.domShortage*(poss_unmet_dom(i))^2 +costParam.agShortage*(poss_unmet_ag(i))^2; % insufficient release
                end
            end
            TSD_table{k,t} = poss_TSD; % STORE THE POSSIBLE TSD FOR STATE AND TIME
        end
    end
            
    %% === FIND THE OPTIMAL POLICY (PATH THAT MINIMIZES TSD THROUGH THE NETWORK) ==
    
    % -- RUN THIS LOOP TWICE TO MEET STEADY STATE OPERATIONAL POLICY (1st) --
    release_opt = zeros(nK,n+1);
    K_opt = zeros(nK,n+1);
    
    for t = n:-1:1 % for each time step (backwards recursion)
        q_now = discr_q(t); %inflow disturbance for the time period
        
        for k = 1:nK %for each possible storage state
            K_state = discr_K(k); %define current possible storage state
            
            % Find the optimal release decision by minimizing the cost function.
            % When there exists multiple decisions corresonding to a minimum TSD,
            % select the index that corresponds to the smaller release.
            
            % accounts for when number of possible releases < nK
            %if isempty(TSD_table{k,t})== 0 %sometimes in low flow situations, dead end so don't run
            [TSD_exist,~] = find(TSD_table{k,t}(:)>=0);
            
            % find index that minimizes the cost function
            [idx_opt,~] = find(TSD_table{k,t}(:)+H(TSD_exist,t+1) == min(TSD_table{k,t}(:)+H(TSD_exist,t+1)));
            
            % when there exists multiple minimums, select the smaller
            % release (corresponds with the greater index)
            [idx_opt,~] = max(idx_opt);
            TSD_opt = TSD_table{k,t}(1,idx_opt); % MINIMUM TSD FOR INTIAL STATE AND TIME
            
            if isempty(TSD_opt)==0
                % Update the cost function with the optimal release decision
                H(k,t) = H(idx_opt,t+1) + TSD_opt;
                % Store the optimal release and resulting next storage state
                release_opt(k,t)= poss_release_table{k,t}(1,idx_opt); %the optimal release decision
                K_opt(k,t+1) = discr_K(1,idx_opt); %the optimal releases for each storage and inflow/time
            else
                H(k,t)=nan;
            end
        end
    end
    
    %% -- APPLY OPTIMIZED RULE CURVE TO ACTUAL SIMULATION TO FIND RELEASE AND UNMET DEMAND--
        % Note that inflow is consistent with the discrete disturbance
        % states used in the optimization. However now storage will come
        % into play.
        
    K(1)=K0; % assume that the initial effective storage is full
    min_K = 0; % minimum reservoir storage
    max_K = eff_storage; % maximum reservoir storage
    
    Hf = zeros(1,n);

    for t = 1:n
        % Define min and max release from current storage and inflow
        min_rel = 0;
        max_rel = K(t) + net_inflow(t);
       
        
        %Find optimal release decision from optimal policy for storage and time
        [~,idx_r] = find([discr_K == K(t)]);
        R = [release_opt(idx_r,t)];
        
        release(t) = R;
        
        %Calculate the next storage level based on release
        K(t+1)=K_opt(idx_r,t+1);
        
        % Calculate H:
        if release(t)>=demand(t)
            if t == 1
                Hf(1,t) = 0;
            else
                Hf(1,t) = Hf(1,t-1)+0; % if release exceeds the demand, then TSD = 0
            end
        else
            unmet = max(demand(t) - release(t), 0);
            unmet_ag = min(unmet, dmd_ag(t));
            unmet_dom = unmet - unmet_ag;
            if t == 1
                Hf(1,t) = (costParam.domShortage*(unmet_dom)^2 +costParam.agShortage*(unmet_ag)^2);
            else
                Hf(1,t) = Hf(1,t-1)+(costParam.domShortage*(unmet_dom)^2 +costParam.agShortage*(unmet_ag)^2);
            end
        end
    end
         
else
    % Non-optimized reservoir operation rule curve (original Fletcher 2019)
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
        
        unmet = max(demand(t) - release(t), 0);
        unmet_ag = min(unmet, dmd_ag(t));
        unmet_dom = unmet - unmet_ag;
        if t == 1
            Hf(1,t) = costParam.domShortage*(unmet_dom)^2 +costParam.agShortage*(unmet_ag)^2;
        else
            Hf(1,t) = Hf(1,t-1)+costParam.domShortage*(unmet_dom)^2 +costParam.agShortage*(unmet_ag)^2;
        end
        
    end

end

water_balance = round(K(1:end-1)+net_inflow(1:end)-release(1:end)-K(2:end));

% Ag demand is unmet first
unmet = max(demand - release, 0);
unmet_ag = min(unmet, dmd_ag);
unmet_dom = unmet - unmet_ag;
   
yield = release;
end