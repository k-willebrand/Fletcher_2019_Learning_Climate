%This is a quick script to combine the cluster results from Sarah and those
%on my computer!

load('ddp_results');

shortageCost_post = shortageCost;
yield_post = yield;
unmet_dom_post= unmet_dom;
unmet_ag_post = unmet_ag;
unmet_dom_squared_post = unmet_dom_squared;
unmet_ag_squared_post = unmet_ag_squared;
desal_opex = [];

load('ddp_results_pt2')

shortageCost_post(1:151,32,2,1)=shortageCost(1:151,32,2,1);
shortageCost_post(1:80,29:31,2,1)=shortageCost(1:80,29:31,2,1);
yield_post(1:151,32,2,1)=yield(1:151,32,2,1);
yield_post(1:80,29:31,2,1)=yield(1:80,29:31,2,1);
unmet_dom_post(1:151,32,2,1)=unmet_dom(1:151,32,2,1);
unmet_dom_post(1:80,29:31,2,1)=unmet_dom(1:80,29:31,2,1);
unmet_ag_post(1:151,32,2,1)=unmet_ag(1:151,32,2,1);
unmet_ag_post(1:80,29:31,2,1)=unmet_ag(1:80,29:31,2,1);
unmet_dom_squared_post(1:151,32,2,1)=unmet_dom_squared(1:151,32,2,1);
unmet_dom_squared_post(1:80,29:31,2,1)=unmet_dom_squared(1:80,29:31,2,1);
unmet_ag_squared_post(1:151,32,2,1)=unmet_ag_squared(1:151,32,2,1);
unmet_ag_squared_post(1:80,29:31,2,1)=unmet_ag_squared(1:80,29:31,2,1);

load('ddp_results_pt1')

shortageCost_post(81:151,28:31,2,1)=shortageCost(81:151,28:31,2,1);
yield_post(81:151,28:31,2,1)=yield(81:151,28:31,2,1);
unmet_dom_post(81:151,28:31,2,1)=unmet_dom(81:151,28:31,2,1);
unmet_ag_post(81:151,28:31,2,1)=unmet_ag(81:151,28:31,2,1);
unmet_dom_squared_post(81:151,28:31,2,1)=unmet_dom_squared(81:151,28:31,2,1);
unmet_ag_squared_post(81:151,28:31,2,1)=unmet_ag_squared(81:151,28:31,2,1);

shortageCost = shortageCost_post;
yield = yield_post;
unmet_dom = unmet_dom_post;
unmet_ag = unmet_ag_post;
unmet_ag_squared = unmet_ag_squared_post;
unmet_dom_squared = unmet_dom_squared_post;

savename_shortageCost = strcat('ddp_results_domCost1');
save(savename_shortageCost, 'shortageCost', 'yield', 'unmet_ag', 'unmet_dom', 'unmet_ag_squared', 'unmet_dom_squared','desal_opex')
