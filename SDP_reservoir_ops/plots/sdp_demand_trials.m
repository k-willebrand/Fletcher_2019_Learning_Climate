% this script compares outputs from the sdp script for different demand and
% costing scenarios

figure(1:4)
T_states = {'T State = 1', 'T State = 2', 'T State = 3', 'T State = 4', 'T State = 5'};

%% Domestic Demand Scenarios vs. Inflow
figure(1)

s_T_abs = [26.25, 26.75, 27.25, 27.95, 28.8];
s_P_abs = 66:1:97;
load('runoff_by_state_June16_knnboot_1t.mat'); 

% inflow scenarios
T = 12;
Ny = length(runoff{1,12,1})/T*100;
            
Q_warm_dry = mean(reshape( runoff{5,1,1}', T, Ny ),2); % MCM/Y
Q_cool_wet = mean(reshape( runoff{1,32,1}', T, Ny ),2); % MCM/Y
Q_init = mean(reshape( runoff{1,12,1}', T, Ny ),2);% MCM/Y

% demand scenarios
dmd_ag = 12*[2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1]; % MCM/Y
low_demand = cmpd2mcmpy(150000) + dmd_ag; % MCM/Y
high_demand = cmpd2mcmpy(186000) + dmd_ag; % MCM/Y
dmd_ag = [2.5 1.5 0.8 2.0 1.9 2.9 3.6 0.6 0.5 0.3 0.2 3.1];
low_demand_old = cmpd2mcmpy(150000) + dmd_ag; % MCM/Y

plot(Q_cool_wet)
hold on
plot(Q_init)
hold on
plot(Q_warm_dry)
hold on
plot(low_demand,'--')
hold on
plot(high_demand,'--')
hold on
plot(low_demand_old,'--')
xlabel('Month of Year')
ylabel('Monthly Inflow or Demand (MCM/Y)')
title('Monthly Inflow and Demand Scenarios')
legend('Cool, wet climate average inflow (T state = 1, P state = 32)','Initial climate average inflow (T state = 1, P state = 12)',...
    'Warm, dry climate average inflow (T state = 5, P state = 1)','Low Demand Scenario (domDemand = 150,000 m3/d)','Higher Demand Scenario (domDemand = 186,000 m3/d)','Prev. Low Demand Scenario (domDemand = 150,000 m3/d)')
xlim([1,12])
ylim([0,225])

%% runParam.domDemand=150,000 m3/d, costParam.domShortage=1, costParam.agShortage=0 (MCM)
load('sdp_adaptive_shortage_cost_domCost1_RCP85_s85.mat')
v1_shortageCost = shortageCost';
v1_unmet = unmet';
v1_unmet_dom = unmet_dom';
v1_unmet_dom2 = unmet_dom2';

% runParam.domDemand=150,000 m3/d, costParam.domShortage=1, costParam.agShortage=0 (CM)
load('V2sdp_adaptive_shortage_cost_domCost1_RCP85_s85.mat')
v2_shortageCost = shortageCost';
v2_unmet = unmet';
v2_unmet_dom = unmet_dom';
v2_unmet_dom2 = unmet_dom2';

% runParam.domDemand=186,000 m3/d, costParam.domShortage=1, costParam.agShortage=0 (CM)
load('V3sdp_adaptive_shortage_cost_domCost1_RCP85_s85.mat')
v3_shortageCost = shortageCost';
v3_unmet = unmet';
v3_unmet_dom = unmet_dom';
v3_unmet_dom2 = unmet_dom2';

% runParam.domDemand=186,000 m3/d, costParam.domShortage=1, costParam.agShortage=1 (CM)
load('V4sdp_adaptive_shortage_cost_domagCost1_RCP85_s85.mat')
v4_shortageCost = shortageCost';
v4_unmet = unmet';
v4_unmet_dom = unmet_dom';
v4_unmet_dom2 = unmet_dom2';
v4_unmet_ag = unmet_ag';
v4_unmet_ag2 = unmet_ag2';

%% Changing Units

figure(1)
subplot(3,2,1)
plot(v1_shortageCost)
xlabel('Precipitation State')
ylabel('Shortage Cost ($)')
title({'Shortage Cost vs. Precipitation State';'Shortage Units: MCM'})
legend(T_states)
subplot(3,2,2)
plot(v2_shortageCost)
xlabel('Precipitation State')
ylabel('Shortage Cost ($)')
title({'Shortage Cost vs. Precipitation State';'Shortage Units: CM'})
legend(T_states)
subplot(3,2,3)
plot(v1_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (MCM)')
title({'Shortage Cost vs. Precipitation State';'Shortage Units: MCM'})
legend(T_states)
subplot(3,2,3)
plot(v1_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (MCM)')
title({'Shortage Cost vs. Precipitation State';'Shortage Units: MCM'})
legend(T_states)
subplot(3,2,4)
plot(v2_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (CM)')
title({'Shortage Cost vs. Precipitation State';'Shortage Units: CM'})
legend(T_states)
subplot(3,2,5)
plot(v1_unmet_dom2)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand Squared (MCM^2)')
title({'Shortage Cost vs. Precipitation State';'Shortage Units: MCM'})
legend(T_states)
sgtitle({'Comparison of MCM and CM';'Dom. Demand = 150,000 m3/d, Dom. Cost = 1, Ag. Cost = 0'})
subplot(3,2,6)
plot(v2_unmet_dom2)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand Squared (CM^2)')
title({'Shortage Cost vs. Precipitation State';'Shortage Units: CM'})
legend(T_states)
sgtitle({'Comparison of MCM and CM';'Dom. Demand = 150,000 m3/d, Dom. Cost = 1, Ag. Cost = 0'})

%% Demand Scenarios: Shortage Cost 150,000 m3/d vs. 186,000 m3/d (V2 vs. V3)

figure(2)
subplot(2,2,1)
plot(v2_shortageCost)
ylabel('Shortage Cost ($)')
title({'domDemand = 150,000 m3/d'; 'Dom. Cost = 1 & Ag. Cost = 0'})
legend(T_states)
xlim([1,32])
subplot(2,2,2)
plot(v3_shortageCost)
ylabel('Shortage Cost ($)')
title({'domDemand = 186,000 m3/d'; 'Dom. Cost = 1 & Ag. Cost = 0'})
legend(T_states)
xlim([1,32])
subplot(2,2,3)
plot(log(v2_shortageCost))
xlabel('Precipitation State')
ylabel('Log(Shortage Cost) (Log($))')
legend(T_states)
ylim([0,34])
xlim([1,32])
subplot(2,2,4)
plot(log(v3_shortageCost))
xlabel('Precipitation State')
ylabel('Log(Shortage Cost) (Log($))')
legend(T_states)
xlim([1,32])
ylim([0,34])

sgtitle({'SDP Shortage Cost vs. Precipitation State';'Comparison of Dom. Demand Scenario for 85 MCM Dam'},'FontWeight','bold')


%% Demand Scenarios: Unmet Demands 150,000 m3/d vs. 186,000 m3/d (V2 vs. V3)

figure(3)
subplot(3,2,1)
plot(v2_unmet)
ylabel('Total Unmet Demand (m^3)')
title({'domDemand = 150,000 m3/d'; 'Total Unmet Demand'})
legend(T_states)
xlim([1,32])
ylim([0,3E8])
subplot(3,2,2)
plot(v3_unmet)
ylabel('Total Unmet Demand (m^3)')
title({'domDemand = 186,000 m3/d'; 'Total Unmet Demand'})
legend(T_states)
xlim([1,32])
ylim([0,3E8])
subplot(3,2,3)
plot(v2_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Domestic Demand (m^3)')
legend(T_states)
title('Unmet Domestic Demand')
xlim([1,32])

subplot(3,2,4)
plot(v3_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (m^3)')
title('Unmet Domestic Demand')
legend(T_states)
xlim([1,32])

subplot(3,2,5)
plot(v2_unmet - v2_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Agriculture Demand (m^3)')
legend(T_states)
title('Unmet Agriculture Demand')
xlim([1,32])
ylim([0,3E8])
subplot(3,2,6)
plot(v3_unmet - v3_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Agriculture Demand (m^3)')
title('Unmet Agriculture Demand')
legend(T_states)
xlim([1,32])
ylim([0,3E8])

sgtitle({'SDP Unmet Demands vs. Precipitation State';'Comparison of Dom. Demand Scenario for 85 MCM Dam'},'FontWeight','bold')



%%

subplot(3,2,1)
plot(v2_shortageCost)
xlabel('Precipitation State')
ylabel('Shortage Cost ($)')
title({'Shortage Cost vs. Precipitation State';'Dom. Demand: 150,000 m3/d'})
legend(T_states)
subplot(3,2,2)
plot(v3_shortageCost)
xlabel('Precipitation State')
ylabel('Shortage Cost ($)')
title({'Shortage Cost vs. Precipitation State';'Dom. Demand: 186,000 m3/d'})
legend(T_states)
subplot(3,2,3)
plot(v2_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (MCM)')
title({'Shortage Cost vs. Precipitation State';'Dom. Demand: 150,000 m3/d'})
legend(T_states)
subplot(3,2,4)
plot(v3_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (MCM)')
title({'Shortage Cost vs. Precipitation State';'Dom. Demand: 186,000 m3/d'})
legend(T_states)
subplot(3,2,5)
plot(v2_unmet_dom2)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand Squared (MCM^2)')
title({'Shortage Cost vs. Precipitation State';'Dom. Demand: 150,000 m3/d'})
legend(T_states)
subplot(3,2,6)
plot(v3_unmet_dom2)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand Squared (CM^2)')
title({'Shortage Cost vs. Precipitation State';'Dom. Demand: 186,000 m3/d'})
legend(T_states)
sgtitle({'Comparison of MCM and CM';'Shortage Units: CM, Dom. Cost = 1, Ag. Cost = 0'})

%% Shortage Cost Parameter Plots: Shortage cost (V3 and V4)
% shortage cost comparison
figure(3)
subplot(2,2,1)
plot(v3_shortageCost)
ylabel('Shortage Cost ($)')
title({'Dom. Cost = 1 & Ag. Cost = 0'; 'domDemand = 186,000 m3/d'})
legend(T_states)
xlim([1,32])
subplot(2,2,2)
plot(v4_shortageCost)
ylabel('Shortage Cost ($)')
title({'Dom. Cost = 1 & Ag. Cost = 1'; 'domDemand = 186,000 m3/d'})
legend(T_states)
xlim([1,32])
figure(3)
subplot(2,2,3)
plot(log(v3_shortageCost))
xlabel('Precipitation State')
ylabel('Log(Shortage Cost) (Log($))')
legend(T_states)
ylim([0,34])
xlim([1,32])
subplot(2,2,4)
plot(log(v4_shortageCost))
xlabel('Precipitation State')
ylabel('Log(Shortage Cost) (Log($))')
legend(T_states)
xlim([1,32])
ylim([0,34])

sgtitle({'SDP Shortage Cost vs. Precipitation State';'Sensitivity to Cost Parameters for 85 MCM Dam'},'FontWeight','bold')


%% Shortage Cost Parameter Plots: Unmet Demands (V3 and V4)


figure(3)
subplot(3,2,1)
plot(v3_unmet)
ylabel('Total Unmet Demand (m^3)')
title({'Dom. Cost = 1 & Ag. Cost = 0';'domDemand = 186,000 m3/d'})
legend(T_states)
xlim([1,32])
ylim([0,3E8])
subplot(3,2,2)
plot(v4_unmet)
ylabel('Total Unmet Demand (m^3)')
title({'Total Unmet Demand'})
legend(T_states)
xlim([1,32])
ylim([0,3E8])
subplot(3,2,3)
plot(v3_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Domestic Demand (m^3)')
legend(T_states)
title('Unmet Domestic Demand')
xlim([1,32])

subplot(3,2,4)
plot(v4_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (m^3)')
title('Unmet Domestic Demand')
legend(T_states)
xlim([1,32])

subplot(3,2,5)
plot(v3_unmet - v3_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Agriculture Demand (m^3)')
legend(T_states)
title('Unmet Agriculture Demand')
xlim([1,32])
ylim([0,3E8])
subplot(3,2,6)
plot(v4_unmet - v4_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Agriculture Demand (m^3)')
title('Unmet Agriculture Demand')
legend(T_states)
xlim([1,32])
ylim([0,3E8])

sgtitle({'SDP Unmet Demands vs. Precipitation State';'Comparison of Cost Parameter Scenario for 85 MCM Dam'},'FontWeight','bold')

%% Shortage Cost Parameter Plots: Unmet Demands (V3 and V4)
figure(4)
subplot(1,2,1)
plot(v3_unmet)
hold on
plot(v3_unmet_dom)
hold on
plot(v3_unmet-v3_unmet_dom) % unmet_ag
hold on
plot(repmat(sum(1/12*high_demand)*20,1,32))
xlabel('Precipitation State')
ylabel('Unmet Demand (MCM)')
title({'Shortage Cost vs. Precipitation State';'Ag. Cost = 0'})
legend(T_states)

subplot(3,2,4)
plot(v3_unmet_dom)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand (MCM)')
title({'Shortage Cost vs. Precipitation State';'Ag. Cost = 1'})
legend(T_states)
subplot(3,2,5)
plot(v3_unmet_dom2)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand Squared (MCM^2)')
title({'Shortage Cost vs. Precipitation State';'Ag. Cost = 0'})
legend(T_states)
subplot(3,2,6)
plot(v4_unmet_dom2)
xlabel('Precipitation State')
ylabel('Unmet Dom. Demand Squared (CM^2)')
title({'Shortage Cost vs. Precipitation State';'Ag. Cost = 1'})
legend(T_states)
sgtitle({'Comparison of MCM and CM';'Shortage Units: CM, Dom. Cost = 1, Ag. Cost = 0'})
