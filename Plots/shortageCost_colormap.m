%% Original runoff2yield comparison
load('nonopt_results_originalMainScript') % costParam.domCost = 5
shortageCost_nonopt = shortageCost;
unmet_dom_nonopt = unmet_dom;
unmet_dom_squared_nonopt = unmet_dom_squared;

load('ddp_results_domCost5')
shortageCost_opt = shortageCost;
unmet_dom_opt = unmet_dom;
unmet_dom_squared_opt = unmet_dom_squared;

figure
subplot(2,2,1)
colormap jet
z=pcolor(s_P_abs,s_T_abs,shortageCost_nonopt(:,:,1,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Non-Optimized 80 MCM Reservoir')
c = colorbar;
colorbar.limits = [0,10E9];


subplot(2,2,2)
z=pcolor(s_P_abs,s_T_abs,shortageCost_nonopt(:,:,2,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Non-Optimized 120 MCM Reservoir')
colormap jet
c = colorbar;
colorbar.limits = [0,10E9];

subplot(2,2,3)
z=pcolor(s_P_abs,s_T_abs,shortageCost_opt(:,:,1,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Optimized 80 MCM Reservoir')
colormap jet
c = colorbar;
colorbar.limits = [0,10E9];

subplot(2,2,4)
z=pcolor(s_P_abs,s_T_abs,shortageCost_opt(:,:,2,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Optimized 120 MCM Reservoir')
colormap jet
c = colorbar;
colorbar.limits = [0,10E9];

%% Updated shortage cost comparison
load('nonopt_shortage_costs_domCost1_RCP80_s85120') 
shortageCost_nonopt = shortageCost./100;
%unmet_dom_nonopt = unmet_dom;
%unmet_dom_squared_nonopt = unmet_dom_squared;

load('opt_shortage_costs_domCost1_RCP80_s85120')
shortageCost_opt = shortageCost./100;

% set max colorbar limit:
maxcolorbar = max(shortageCost_opt);

figure
%sgtitle('Reservoir Shortage Costs')
subplot(2,2,1)
z = pcolor(s_P_abs,s_T_abs,shortageCost_nonopt(:,:,1,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Non-Optimized 80 MCM Reservoir')
colormap jet
caxis([0,50E6]);
colorbar;

subplot(2,2,2)
z=pcolor(s_P_abs,s_T_abs,shortageCost_nonopt(:,:,2,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Non-Optimized 120 MCM Reservoir')
colormap jet
caxis([0,50E6]);
c2=colorbar;

subplot(2,2,3)
z=pcolor(s_P_abs,s_T_abs,shortageCost_opt(:,:,1,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Optimized 80 MCM Reservoir')
colormap jet
caxis([0,50E6]);
colorbar;

subplot(2,2,4)
z=pcolor(s_P_abs,s_T_abs,shortageCost_opt(:,:,2,1))
xlabel('Mean P (mm/m)')
ylabel('Mean T (degrees C)')
title('Optimized 120 MCM Reservoir')
colormap jet
caxis([0,50E6]);
colorbar;
