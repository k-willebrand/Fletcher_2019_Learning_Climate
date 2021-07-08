% Use this script to combine preloaded shortage cost files for either the
% optimized or non-optimized reservoir operations model

% Inputs:
storage = [85 125];
costParam.domShortage = 1;
runParam.setPathway = 'RCP85';
runParam.optReservoir = true;

% Combining files:
shortageCost = NaN(M_T_abs, M_P_abs, length(storage), N);

s_small = string(storage(1));
s_large = string(storage(2));

if runParam.optReservoir
    s_small_filename = strcat('ddp_shortage_cost_domCost',string(costParam.domShortage),'_',string(runParam.setPathway),'_s',s_small,'.mat');
    s_large_filename = strcat('ddp_shortage_cost_domCost',string(costParam.domShortage),'_',string(runParam.setPathway),'_s',s_large,'.mat');
    shortageCost_small = load(s_small_filename,'shortageCost').shortageCost;
    shortageCost_large = load(s_large_filename,'shortageCost').shortageCost;
    shortageCost(:,:,1,1) = shortageCost_small;
    shortageCost(:,:,2,1) = shortageCost_large;
    
    savename_shortageCost = strcat('opt_shortage_costs_domCost',string(costParam.domShortage),'_',string(runParam.setPathway),'_s',s_small,s_large,'.mat');
    save(savename_shortageCost, 'shortageCost')   
else
    s_small_filename = strcat('nonopt_shortage_cost_domCost',string(costParam.domShortage),'_',string(runParam.setPathway),'_s',s_small,'.mat');
    s_large_filename = strcat('nonopt_shortage_cost_domCost',string(costParam.domShortage),'_',string(runParam.setPathway),'_s',s_large,'.mat');
    shortageCost_small = load(s_small_filename,'shortageCost').shortageCost;
    shortageCost_large = load(s_large_filename,'shortageCost').shortageCost;
    shortageCost(:,:,1,1) = shortageCost_small;
    shortageCost(:,:,2,1) = shortageCost_large;
    
    savename_shortageCost = strcat('nonopt_shortage_costs_domCost',string(costParam.domShortage),'_',string(runParam.setPathway),'_s',s_small,s_large,'.mat');
    save(savename_shortageCost, 'shortageCost')       
end