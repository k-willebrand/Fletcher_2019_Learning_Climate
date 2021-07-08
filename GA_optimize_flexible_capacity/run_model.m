function perc95 = run_model(x, gaParam) % return 95 percentile total cost

% Set project root folder and add subfolders to path; runs either on desktop 
% or on a cluster using SLURM queueing system 
if ~isempty(getenv('SLURM_JOB_ID'))
    projpath = '/home/users/keaniw/Fletcher_2019_Learning_Climate';
    jobid = getenv('SLURM_JOB_ID');  
else
    projpath = 'C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate';
    jobid = 'na';
end
addpath(genpath(projpath))

% let x(1) be the small capacity dam size and x(2) be the large expanded
% dam size
x(1) = 50 + (x(1)-1)*5;
x(2) = 50 + (x(2)-1)*5; 
run('sdp_climate_opt_flex.m');

% looked at different ways of measuring the optimal dam size

%medCostFlex = median(sum(totalCostTime(:,:,3), 2));
%meanCostFlex = mean(sum(totalCostTime(:,:,3), 2));
%perc75 = prctile(sum(totalCostTime(:,:,3), 2),75);
perc95 = prctile(sum(totalCostTime(:,:,3), 2),95);
disp(perc95)

% act = 1-sum(action(:,1,end)==3)/10000; % while the flexible dam is chosen, not always expanded
% act = 1 - sum(action(:,2:5,end)==4,'all')/10000; % find where the flexible dam is expanded
% disp(act)