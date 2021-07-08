% LOGNORMAL DISTRIBUTION ASSUMPTION
% Test that monthly inflow for each climate state follows a log normal
% distribution that is statistically significant (K-S test)

% load runoff data
load('runoff_by_state_June16_knnboot_1t.mat'); % 5 T states, 32 P states

% set algorithm parameters
sys_param.algorithm.name = 'sdp';
sys_param.algorithm.Hend = 0 ; % penalty set to 0
sys_param.algorithm.T = 12;    % the period is equal 1 year
climParam.numSampTS = 100;
runParam.steplen = 20;
sys_param.algorithm.numSampTS = climParam.numSampTS;
sys_param.algorithm.gamma = 1; % set future discount factor
tol = -1;    % accuracy level for termination
max_it = 10; % maximum iteration for termination

% Estimate cyclostationary pdf (assuming log-normal distribution)
T = sys_param.algorithm.T ;

% test climate states and storage capacities
%test_P = [1, 11, 22, 32]; % test precipitation states

%% Run K-S test for each month of the year for each climate state

h_table = cell(5, 32);
p_table = cell(5, 32);

% calculate test statistics
for s_p=1:32
    
    P_state = s_p;
    
    for s_t=1:5
        
        T_state = s_T;
        
        qq = runoff{T_state,P_state,1}';
        sys_param.simulation.q = qq;
        Ny = length(sys_param.simulation.q)/T*sys_param.algorithm.numSampTS;
   
        Q = reshape( sys_param.simulation.q, T, Ny );
        q_stat = nan(T,2);
        h = nan(T,1);
        p = nan(T,1);
        
        
        for i = 1:12 % for each month
            qi = Q(i,:);
            q_stat(i,:) = lognfit(qi);
            mu = q_stat(i,1);
            sigma = q_stat(i,2);
            r = lognrnd(mu,sigma);
            [h(i,1),p(i,1)] = kstest2(r,qi);
        end
        h_table{s_t, s_p} = h; % h parameter of ln inflow
        p_table{s_t,s_p} = p; % p-value of ln inflow
        
    end
end

%% Plot K-S test results (p-value)

% K-S test p-value plots (multiple figures)
s_ts = 1:5;


for i=1:4
    
    figure('units','normalized','outerposition',[0 0 1 1])
    if i == 1
        s_ps = 1:8;
    elseif i == 2
        s_ps = 9:16;
    elseif i == 3
        s_ps = 17:24;
    else
        s_ps = 25:32;
    end
    
    for p=1:length(s_ps)
        for t=1:length(s_ts)
            s_t = s_ts(t);
            s_p = s_ps(p);
            subplot(length(s_ps),length(s_ts),(p-1)*length(s_ts)+t);
            bar(1:12,p_table{s_t,s_p});
            hold on
            plot(0:13,ones(14)*0.05,'r');
            ylim([0,1]);
            if mod((p-1)*length(s_ts)+t,length(s_ts)) == 1
                label_p = ylabel(strcat('P State: ', string(s_p)),'fontweight','bold');
                label_p.Position(1) = -5; % change horizontal position of ylabel
                set(get(gca,'YLabel'),'Rotation',0)
            end
            if p == 1
                title(strcat('T State: ',string(s_t)))
            end
            if p == length(s_ps)
                xlabel('month of year')
            end
        end
    end
    sgtitle({strcat('K-S Test p-values: Log Normal Inflow (', string(i), '/4)');'\alpha = 0.05'})
end


%% Plot K-S test statistic (statistic)

figure
for t=1:length(s_ts)
    s_t = s_ts(t);
    for p=1:length(s_ps)
        s_p = s_ps(p);
        subplot(length(s_ps),length(s_ts),(t-1)*length(s_ps)+p);
        bar(1:12,h_table{s_t,s_p});
        ylim([0,1]);
        title(strcat('T: ',string(s_t),' P: ',string(s_p)))
        xlabel('month of year')
        ylabel('p value')
    end
end
sgtitle('K-S Test Statistic')


