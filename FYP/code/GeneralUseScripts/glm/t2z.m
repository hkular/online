function Z = t2z(t,dof);

Z=zeros(size(t));

if size(dof,2)~=size(t,2)
  new_dof=ones(1,size(t,2));
  new_dof=new_dof*dof;
  dof=new_dof;
end;

for i=1:size(t,1)
   for j=1:size(t,2)
      Z(i,j) = t2z_asy(t(i,j),dof(j));
   end;
end;
