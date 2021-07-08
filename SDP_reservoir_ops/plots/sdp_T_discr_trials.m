% Graphs of shortage costs comparing different temperature discretization
% options based on Jenny's analysis.

%% LINE PLOT COMPARISONS

load('V2adaptive_shortage_cost_domCost1_RCP85_s80.mat')

% Deterministic model
figure
subplot(3,1,1)
plot(shortageCost')
xlim([1,32])
xlabel('Precipitation State')
ylabel('Shortage Cost ($)')
title('Shortage Cost vs. Precipitation State for 80 MCM Dam')
legend('N=1 (26.25 deg. C)','N=2 (26.75 deg. C)','N=3 (27.25 deg. C)','N=4 (27.95 deg. C)','N=5 (28.8 deg. C)')
ylim([0,7E5])

% Median of temperature states model
subplot(3,1,2)
plot(shortageCost(3,:)')
xlim([1,32])
xlabel('Precipitation State')
ylabel('Shortage Cost ($)')
title('Shortage Cost vs. Precipitation State for 80 MCM Dam')
legend('N=1,2,3,4,5 (Median 27.25 deg. C)')
ylim([0,7E5])

% Mean of temperature states model
load('V3adaptive_shortage_cost_domCost1_RCP85_s80.mat')

subplot(3,1,3)
plot(shortageCost')
xlim([1,32])
xlabel('Precipitation State')
ylabel('Shortage Cost ($)')
title('Shortage Cost vs. Precipitation State for 80 MCM Dam')
legend('N=1,2,3,4,5 (Mean 27.4 deg. C)')
ylim([0,7E5])

sgtitle('SDP Shortage Costs via RCP 8.5 0.05-degree Simulated Median')

%% BAR GRAPH COMPARISON

% Bar plot of shortage costs for 2 precipitation states (wet and dry) for 
% the different temperatures:(1) lowest deterministic temperature state (N=1) 
%(2)highest deterministic temperature state (N=5) (3) Median of the
% temperature states in the model (4) Mean of the temperature states in the
% model.

P_STATES = [1,32];
T_STATES = [6,16,26,40,57,26,29];

load('V2adaptive_shortage_cost_domCost1_RCP85_s80.mat')
y_deterministic_P1 = [shortageCost(1,P_STATES(1)),shortageCost(5,P_STATES(1))];
y_deterministic_P2 = [shortageCost(1,P_STATES(2)),shortageCost(5,P_STATES(2))];

y_median_P1 = [shortageCost(3,P_STATES(1))];
y_median_P2 = [shortageCost(3,P_STATES(2))];

load('V3adaptive_shortage_cost_domCost1_RCP85_s80.mat')
y_mean_P1 = [shortageCost(1,P_STATES(1))];
y_mean_P2 = [shortageCost(1,P_STATES(2))];

Y1 = [y_deterministic_P1, y_median_P1, y_mean_P1];
Y2 = [y_deterministic_P2, y_median_P2, y_mean_P2];

figure
subplot(1,2,1)
bar(Y1)
ylim([0,4E5])
ylabel('Shortage Cost ($)')
title('Shortage Cost (Driest P State = 1)')
xticklabels({'26.25', '28.8', '27.25', '27.4'})
xlabel('Temperature State Value (deg. C)')

subplot(1,2,2)
bar(Y2)
ylim([0,4E5])
ylabel('Shortage Cost ($)')
title('Shortage Cost (Wettest P State = 32)')
xticklabels({'26.25', '28.8', '27.25', '27.4'})
xlabel('Temperature State Value (deg. C)')

