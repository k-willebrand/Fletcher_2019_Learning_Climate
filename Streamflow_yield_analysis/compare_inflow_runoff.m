
load('runoff_by_state_Mar16_knnboot_1t.mat')
T = T_ts{90,1}(6,:);
P = P_ts{30,1}(6,:);
storage = 120;
capacity = 0;
runParam = struct;
runParam.steplen = 20; 
runParam.desalOn = false; 
runParam.N = 5;
climParam = struct;
runParam.domDemand = 150000; %keani added this for her version of runoff2yield
runParam.optReservoir = false;

compare_yield = zeros(151,32);
compare_unmet_dom = zeros(151,32);
for j = 90 %1:151
for i = 30%1:32
 inflow = runoff{j,i,1}(6,:);
 [yield_inflow, ~, ~, unmet_dom_inflow, unmet_ag_inflow] = inflow2yield(inflow, T, P, storage);
 [yield_runoff, ~, ~, unmet_dom_runoff, unmet_ag_runoff, desalsupply, desalfill] = runoff2yield(inflow, T, P, storage, capacity, runParam, climParam);
 compare_yield(j,i) = sum(yield_runoff ~= yield_inflow);
 compare_unmet_dom(j,i) = sum(unmet_dom_runoff ~= unmet_dom_inflow);
end
end
sum(sum(compare_yield))
sum(sum(compare_unmet_dom))

 
 