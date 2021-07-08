% DESCRIPTION: This script is a post-processing script that combines the
% cluster shortage cost files. This is for the 5 T state and 32 P state
% discretization (deterministic model)

%% Setup 

% Set Project root folder and Add subfolders to path; runs either on desktop 
% or on a cluster using SLURM queueing system 
if ~isempty(getenv('SLURM_JOB_ID'))
    projpath = '/home/users/keaniw/Fletcher_2019_Learning_Climate';
    jobid = getenv('SLURM_JOB_ID');
    folder = '/home/users/keaniw/Fletcher_2019_Learning_Climate/SDP/reservoir_results';
else
    projpath = 'C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate';
    jobid = 'na';
    folder = 'C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate/SDP/reservoir_results'; 
end
addpath(genpath(projpath))
mkdir('post_process_reservoir_results')

% NOTE: Prior to running this script, be sure to update the folder path
% under the folder variable

% Identify the files for post processing (cluster_shortage_costs...mat files)
% NOTE: replace the folder name to the local folder containing the cluster shortage cost files
cluster_files = dir(fullfile(folder,'cluster_shortage_costs_st*_sp*_s*.mat'));

% find which storage files are in the folder (unique)
s_name = zeros(length(cluster_files),1);
sp_name = zeros(length(cluster_files),1);
st_name = zeros(length(cluster_files),1);
for i = 1:length(cluster_files)
    index_file_name = cluster_files(i).name;
    indices = str2double(regexp(index_file_name,'\d+','match'));
    st_name(i) = indices(1);
    sp_name(i) = indices(2);
    s_name(i) = indices(3);
end
s_names = unique(s_name);
sp_names = unique(sp_name);
st_names = unique(st_name);

% Define number of temperature states (s_T_abs) and precipation states (s_P_abs), decision
% periods (N), and reservoir capacity options (ns)
M_T_abs = 5;
M_P_abs = 32;
ns = length(s_names); % number of storage capacities considered
N = 1; % Usually 5 when we use for the SDP: for now, let N = 1 just to save the file in smaller form

% Preallocate final combined variables
shortageCost_post = NaN(M_T_abs, M_P_abs, ns, N); 
% yield_post = NaN(M_T_abs, M_P_abs, ns, N);
% unmet_dom_post= NaN(M_T_abs, M_P_abs, ns, N);
% unmet_ag_post = NaN(M_T_abs, M_P_abs, ns, N);
% unmet_dom_squared_post = NaN(M_T_abs, M_P_abs, ns, N);
% unmet_ag_squared_post = NaN(M_T_abs, M_P_abs, ns, N);
% desal_opex = []; % Currently, under the optimized reservoir scenario, desalination is not considered thus let desal_opex = []


% For each post processing cluster file, use the file name indexes (st, sp,
% and s) to combine the files into a single data file that mirrors the output
% from sdp_climate.m

for i = 1:length(cluster_files)
    index_file_name = cluster_files(i).name;
    indices = str2double(regexp(index_file_name,'\d+','match'));
    index_s_t = indices(1);
    index_s_p = indices(2);
    s_name = indices(3);
    s = find(s_name == s_names); % we seek to save each storage in its own file thus let s = 1
    t = 1; % here, t represents the N = 1 decision period
    
    load(index_file_name);
    shortageCost_post(index_s_t, index_s_p, s, t) = shortageCost;
%     yield_post(index_s_t, index_s_p, s, t) = yield;
%     unmet_dom_post(index_s_t, index_s_p, s, t)= unmet_dom;
%     unmet_ag_post(index_s_t, index_s_p, s, t) = unmet_ag;
%     unmet_dom_squared_post(index_s_t, index_s_p, s, t) = unmet_dom_squared;
%     unmet_ag_squared_post(index_s_t, index_s_p, s, t) = unmet_ag_squared;
end

%savename_shortageCost = strcat('shortage_costs_pt2_', jobid,'_', string(datetime(indices(4),'ConvertFrom','yyyymmdd','Format','dd_MMM_yyy')));
for i = 1:length(s_names)
    savename_shortageCost = strcat('post_process_reservoir_results/detT_ddp_shortage_cost_domCost1_RCP85_s', string(s_names(i)));
    shortageCost = shortageCost_post(:,:,i,1);
%     yield = yield_post(:,:,i);
%     unmet_dom = unmet_dom_post(:,:,i);
%     unmet_ag = unmet_ag_post(:,:,i);
%     unmet_ag_squared = unmet_ag_squared_post(:,:,i);
%     unmet_dom_squared = unmet_dom_squared_post(:,:,i);
    save(savename_shortageCost, 'shortageCost')
end