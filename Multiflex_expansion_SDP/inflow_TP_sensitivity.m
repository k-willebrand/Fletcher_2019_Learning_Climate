% Purpose: this script investigates the sensitivity of the net inflow time
% series (runoff - evaporation) for the temperature and precipitation
% states. The goal is to understand what level of discritization is
% appropriate for development of an SDP reservoir operations model.

load('runoff_by_state_Mar16_knnboot_1t.mat')
% Set up climate parameters
climParam = struct;
% set up relevant run parameters
runParam = struct;
runParam.steplen = 20; 

num_Pstates = size(runoff,2); % total number of precipitation states
num_Tstates = size(runoff,1);

%% Precipitation state constant - test sensitivity to temperature state

% If true, net inflow. If false, runoff only.
SubEvap = true;

% if true, use 24000 values in distribution. Else take average across
% simulations
total = true;

% test for 4 possible precipitation states (low, intermediate, and high):
num_Ptest = 4; % number of P states to test
test_Pstates = round(linspace(1,num_Pstates,num_Ptest));
storage = 80; % let storage be 80 MCM

LNall_mu_Pstate = zeros(num_Ptest,num_Tstates+1); %let first column write test_Pstate
LNall_sigma_Pstate = zeros(num_Ptest,num_Tstates+1);

LNyearly_mu_Pstate = zeros(num_Ptest,num_Tstates+1); %let first column write test_Pstate
LNyearly_sigma_Pstate = zeros(num_Ptest,num_Tstates+1);

for i=1:num_Ptest
    P_state = test_Pstates(i)
    LNall_mu_Pstate(i,1) = P_state;
    LNall_sigma_Pstate(i,1) = P_state;
    for j=1:num_Tstates
        T_state = j;
        inflow = runoff{j,P_state,1};
        if SubEvap == 1
            [E]  = evaporation_sdp(storage, j, i, climParam, runParam);
        elseif SubEvap == 0
            E = 0;
        end
        net_inflow = inflow - E;
        net_inflow(net_inflow<0)=0.00001;
        
        all_mean_net_inflow = mean(net_inflow);
        reshaped_mean_net_inflow = reshape(all_mean_net_inflow,[12,20]);
        yearly_mean_net_inflow = mean(reshaped_mean_net_inflow'); % monthly mean (12-months)
        
        % fit LN distributions to net inflows
        if total == 1
            [all_params, all_CI] = lognfit(reshape(net_inflow,1,[]));
        elseif total == 0
            [all_params, all_CI] = lognfit(all_mean_net_inflow);
        end
        LNall_mu_Pstate(i,j+1) = all_params(1);
        LNall_sigma_Pstate(i,j+1) = all_params(2);
        
        [yearly_params, yearly_CI] = lognfit(yearly_mean_net_inflow);
        LNyearly_mu_Pstate(i,j+1) = yearly_params(1);
        LNyearly_sigma_Pstate(i,j+1) = yearly_params(2);
        
    end
end

% plots for all (20 year)
figure
for i=1:num_Ptest
    subplot(num_Ptest,1,i)
    plot(LNall_mu_Pstate(i,2:end))
    ylabel('Location, mu')
    ylim([4.3,5])
    hold on
    yyaxis right
    plot(LNall_sigma_Pstate(i,2:end))
    ylim([0.25, 0.45])
    xlabel('Temperature State')
    ylabel('Scale, sigma')
    title(compose('20-Year LN parameters (P state = %i)', test_Pstates(i)));
    xlim([1,num_Tstates])
end

% plots for yearly (cyclo-stationary)
figure
for i=1:num_Ptest
    subplot(num_Ptest,1,i)
    plot(LNyearly_mu_Pstate(i,2:end))
    ylabel('Location, mu')
    ylim([4.3,5])
    hold on
    yyaxis right
    plot(LNyearly_sigma_Pstate(i,2:end))
    ylim([0.25, 0.45])
    xlim([1,num_Tstates])
    xlabel('Temperature State')
    ylabel('Scale, sigma')
    title(compose('Yearly LN parameters (P state = %i)', test_Pstates(i)));
end

% Parameter plots
figure
subplot(1,2,1)
for i=1:num_Ptest
    plot(LNyearly_mu_Pstate(i,2:end))
    hold on
end
legend_labels = compose('P state: %i', test_Pstates(1:end));
legend(legend_labels ,'Location','north','Orientation','horizontal')
ylabel('Location, mu')
xlabel('Temperature State')
xlim([1,num_Tstates])
title('Location Parameter (mu) vs. T State')
subtitle('Storage = 80 MCM')

subplot(1,2,2)
for i=1:num_Ptest
    plot(LNyearly_sigma_Pstate(i,2:end))
    hold on
end
legend(legend_labels ,'Location','north','Orientation','horizontal')
ylabel('Scale, sigma')
xlabel('Temperature State')
xlim([1,num_Tstates])
title('Scale Parameter (sigma) vs. T State')
subtitle('Storage = 80 MCM')
if SubEvap == 1
    ylim([0.25,0.65])
elseif SubEvap == 0
    ylim([0.25,0.45])
end

if SubEvap == 1
    sg1 = sgtitle('MLE Fitted Lognormal Parameter Values for Net Inflow vs. T State');
    sg1.FontSize = 15;
elseif SubEvap == 0
    sg1 = sgtitle('MLE Fitted Lognormal Parameter Values for Runoff vs. T State');
    sg1.FontSize = 15;
end

%% Temperature state constant - test sensitivity to precipiation state

% If true, net inflow. If false, runoff only.
SubEvap = true;

% test for 4 possible precipitation states (low, intermediate, and high):
num_Ttest = 5; % number of T states to test
test_Tstates = round(linspace(1,num_Tstates,num_Ttest));
storage = 80; % let storage be 80 MCM

LNall_mu_Tstate = zeros(num_Ttest,num_Tstates+1); %let first column write test_Pstate
LNall_sigma_Tstate = zeros(num_Ttest,num_Tstates+1);

LNyearly_mu_Tstate = zeros(num_Ttest,num_Tstates+1); %let first column write test_Pstate
LNyearly_sigma_Tstate = zeros(num_Ttest,num_Tstates+1);

for i=1:num_Ttest
    T_state = test_Tstates(i)
    LNall_mu_Tstate(i,1) = T_state;
    LNall_sigma_Tstate(i,1) = T_state;
    for j=1:num_Pstates
        P_state = j;
        inflow = runoff{T_state,j,1};
        if SubEvap == 1
            [E]  = evaporation_sdp(storage, i, j, climParam, runParam);
        elseif SubEvap == 0
            E = 0;
        end
        net_inflow = inflow - E;
        net_inflow(net_inflow<0)=0.00001;
        
        all_mean_net_inflow = mean(net_inflow);
        reshaped_mean_net_inflow = reshape(all_mean_net_inflow,[12,20]);
        yearly_mean_net_inflow = mean(reshaped_mean_net_inflow'); % monthly mean (12-months)
        
        % fit LN distributions to net inflows
         if total == 1
            [all_params, all_CI] = lognfit(reshape(net_inflow,1,[]));
        elseif total == 0
            [all_params, all_CI] = lognfit(all_mean_net_inflow);
         end
        LNall_mu_Tstate(i,j+1) = all_params(1);
        LNall_sigma_Tstate(i,j+1) = all_params(2);
        
        [yearly_params, yearly_CI] = lognfit(yearly_mean_net_inflow);
        LNyearly_mu_Tstate(i,j+1) = yearly_params(1);
        LNyearly_sigma_Tstate(i,j+1) = yearly_params(2);
        
    end
end


% Parameter plots
figure
subplot(1,2,1)
for i=1:num_Ttest
    plot(LNyearly_mu_Tstate(i,2:end))
    hold on
end
legend_labels = compose('T state: %i', test_Tstates(1:end));
legend(legend_labels ,'Location','southeast')
ylabel('Location, mu')
ylim([3.8,5])
%ylim([4.2,5])
xlabel('Precipitation State')
xlim([1,num_Pstates])
title('Location Parameter (mu) vs. P State')
subtitle('Storage = 80 MCM')

subplot(1,2,2)
for i=1:num_Ttest
    plot(LNyearly_sigma_Tstate(i,2:end))
    hold on
end
%legend(legend_labels ,'Location','westoutside','Orientation','horizontal')
legend(legend_labels ,'Location','northeast')
ylabel('Scale, sigma')
xlabel('Precipitation State')
xlim([1,num_Pstates])
title('Scale Parameter (sigma) vs. P State')
subtitle('Storage = 80 MCM')
if SubEvap == 1
    ylim([0.25,0.65])
    %ylim([0.25,0.45])
elseif SubEvap == 0
    ylim([0.25,0.45])
end

if SubEvap == 1
    sg1 = sgtitle('MLE Fitted Lognormal Parameter Values for Net Inflow vs. P State');
    sg1.FontSize = 15;
elseif SubEvap == 0
    sg1 = sgtitle('MLE Fitted Lognormal Parameter Values for Runoff vs. P State');
    sg1.FontSize = 15;
end