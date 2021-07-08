function [ u ] = extractor_ref( idx_U , discr_u  )

% Input:
%     idx_U - indices of equivalent optimal decisions
%   discr_u - vector of discretized decision values


u_ = discr_u( idx_U );

if length( u_ ) == 1
  u = u_ ;
else
  u = mean(u_) ;
end