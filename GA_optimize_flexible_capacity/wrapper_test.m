%% Wrapper script for sdp_climate_opt_flex.m - January 2021
% This file is a wrapper function to find the optimal flexible dam design
% for either a DDP optimized or greedy algorithm operated dam using a genetic
% algorithm approach. The script finds the small and large dam capacities 
% [50:5:150] MCM that minimize the 95 percentile of total costs from 
% forward simultions.

% Note: To optimize the dam design for a DDP optimized dam, set 
% gaParam.optReservoir = true; for greedy algorithm operated dam, set
% gaParam.optReservoir = true.

% This version has been updated by Keani (new sizing constraints)

%% Setup 

% Set Project root folder and Add subfolders to path; runs either on desktop 
% or on a cluster using SLURM queueing system 
if ~isempty(getenv('SLURM_JOB_ID'))
    projpath = '/home/users/keaniw/Fletcher_2019_Learning_Climate';
    jobid = getenv('SLURM_JOB_ID');  
else
    projpath = 'C:/Users/kcuw9/Documents/Fletcher_2019_Learning_Climate';
    jobid = 'na';
end
addpath(genpath(projpath))

%% Set up optimization scenario for the genetic algorithm

gaParam = struct;

% Set emissions pathway
emisScenario = {'RCP19' 'RCP26' 'RCP34' 'RCP45' 'RCP6' 'RCP7' 'RCP85'};
gaParam.setPathway = emisScenario{7};

% If true, perform DDP to optimize reservoir operatations in the water
% system model. If false, use non-optimized fixed rule curve for reservoir
% operations
gaParam.optReservoir = false;

%% create function to optimize flex sizing using a genetic algorithm

nvars = 2; % corresponds to small and large dam capacity
%ObjectiveFunction = @run_model;
%ConstraintFunction = @simple_constraint;

ObjectiveFunction = @(x) run_model(x, gaParam);

% int means that the input variables 1 and 2 are integers
Int = [1 2];

% lower bound, upper bound, and starting values for each variable:
% In the run_model_RCP45 script, I multiply the values to get the actual
% dam sizes I want, but having the input variables be low integer numbers
% was easier
LB2 = [1 2]; 
UB2 = [20 21];
X02 = [7 15]; % corresponds to x1 = 80 MCM, x2 = 120 MCM

% specify the linear constraints of the solution: x(1)-x(2)<0 where x(1) is
% the small capacity and x(2) is the large capacity
A = [1, -1]; % x(1) - x(2)
b = [0]; % x(1) - x(2) <=0

%% Run the genetic algorithm

%options.InitialPopulationMatrix = X0;
options = optimoptions('ga', 'Display', 'iter', ...
    'InitialPopulationMatrix', X02, 'MutationFcn', @mutationadaptfeasible,...
    'UseParallel', true, 'PlotFcn', {@gaplotbestf, @gaplotstopping}, ...
    'MaxGenerations', 100);

[x, fval, exitFlag, Output] = ga(ObjectiveFunction, nvars, A, b,[],[],LB2,UB2, [],Int, options);