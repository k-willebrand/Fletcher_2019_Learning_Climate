function parsave(fname, x, y, z, w, u, v)

% save files in parfor loop to avoid workspace transparency error
% fname is the filename (as a string)
% x and y are workspace variables

  renamevars2save(x,y,z,w,u,v,inputname(2),inputname(3),inputname(4),inputname(5), inputname(6), inputname(7))
  save(fname, inputname(2), inputname(3), inputname(4), inputname(5), inputname(6), inputname(7))
end

function renamevars2save(x,y,z,w,u,v,x_name,y_name,z_name,w_name,u_name,v_name)
    assignin('caller', x_name, x)
    assignin('caller', y_name, y)
    assignin('caller', z_name, z)
    assignin('caller', w_name, w)
    assignin('caller', u_name, u)
    assignin('caller', v_name, v)
end