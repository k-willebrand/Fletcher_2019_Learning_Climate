function [dcost, ecost] = storage2damcost(storage, flex_storage, percFlex,  percFlexExp)

% if percFlex is not input, default to 0
if ~exist('percFlex', 'var')
    percFlex = 0;
end

if ~exist('percFlexExp', 'var')
    percFlexExp = 0.5;
end
% Load costs as a function of dam height and reservoir storage. These
% values were taken from a dam cost tool developed the Mwache dam for: 
% World Bank Group. (2015). Enhancing the Climate Resilience of Africa?s 
% Infrastructure: The Power and Water Sectors. (R. Cervigni, R. Liden, J. 
% E. Neumann, & K. M. Strzepek, Eds.). Washington, DC: The World Bank. 
% https://doi.org/10.1017/CBO9781107415324.004
load('dam_cost_model')


% Make sure input storage volume is in dam cost lookup table
if ~ismember(storage, costmodel.storage)
   error('invaild storage volume')
end

% Upfront dam cost
index = find(costmodel.storage == storage);
dcost = costmodel.dam_cost(index);

%add capital cost if using flex dam
if flex_storage > 0
    dcost = dcost * (1 + percFlex);
end

% Expansion costs if increase height
ecost = [];
if flex_storage
    added_storage = flex_storage - storage;
    indexFlex = find(costmodel.storage == flex_storage);
    ecost = added_storage * costmodel.unit_cost(indexFlex)*(1 + percFlexExp); % 50% higher unit cost when increasing height
    dcost = dcost;
    
end

end