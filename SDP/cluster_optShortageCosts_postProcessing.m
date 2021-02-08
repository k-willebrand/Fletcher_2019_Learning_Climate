% DESCRIPTION: This script is a post-processing script that combines the
% cluster shortage cost files.

% NOTE: Prior to running this script, be sure to update the folder path
% under the folder variable

% Identify the files for post processing (cluster_shortage_costs...mat files)
folder = 'C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate-reservoir_ops/DDP_Results pt 1'; % NOTE: replace the folder name to the local folder containing the cluster shortage cost files
cluster_files = dir(fullfile(folder,'cluster_shortage_costs_st*_sp*_s*.mat'));

% Define number of temperature states (s_T_abs) and precipation states (s_P_abs), decision
% periods (N), and reservoir capacity options (ns)
M_T_abs = 151;
M_P_abs = 32;
ns = 2; % number of storage capacities considered
N = 5;

% Preallocate final combined variables
shortageCost_post = NaN(M_T_abs, M_P_abs, ns, N); 
yield_post = NaN(M_T_abs, M_P_abs, ns, N);
unmet_dom_post= NaN(M_T_abs, M_P_abs, ns, N);
unmet_ag_post = NaN(M_T_abs, M_P_abs, ns, N);
unmet_dom_squared_post = NaN(M_T_abs, M_P_abs, ns, N);
unmet_ag_squared_post = NaN(M_T_abs, M_P_abs, ns, N);
desal_opex = []; % Currently, under the optimized reservoir scenario, desalination is not considered thus let desal_opex = []

% For each post processing cluster file, use the file name indexes (st, sp,
% and s) to combine the files into a single data file that mirrors the output
% from sdp_climate.m
for i = 1:length(cluster_files)
    index_file_name = cluster_files(i).name;
    indices = str2double(regexp(index_file_name,'\d+','match'));
    index_s_t = indices(1);
    index_s_p = indices(2);
    s = indices(3);
    t = 1; % here, t represents the N = 1 decision period
    
    load(index_file_name);
    shortageCost_post(index_s_t, index_s_p, s, t) = shortageCost;
    yield_post(index_s_t, index_s_p, s, t) = yield;
    unmet_dom_post(index_s_t, index_s_p, s, t)= unmet_dom;
    unmet_ag_post(index_s_t, index_s_p, s, t) = unmet_ag;
    unmet_dom_squared_post(index_s_t, index_s_p, s, t) = unmet_dom_squared;
    unmet_ag_squared_post(index_s_t, index_s_p, s, t) = unmet_ag_squared;
end

shortageCost = shortageCost_post;
yield = yield_post;
unmet_dom = unmet_dom_post;
unmet_ag = unmet_ag_post;
unmet_ag_squared = unmet_ag_squared_post;
unmet_dom_squared = unmet_dom_squared_post;

%savename_shortageCost = strcat('shortage_costs_pt2_', jobid,'_', string(datetime(indices(4),'ConvertFrom','yyyymmdd','Format','dd_MMM_yyy')));
savename_shortageCost = strcat('ddp_results_pt1');
save(savename_shortageCost, 'shortageCost', 'yield', 'unmet_ag', 'unmet_dom', 'unmet_ag_squared', 'unmet_dom_squared','desal_opex')
