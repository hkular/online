function Z = t2z_asy(t,dof)

% function Z = t2z_asy(t,dof) 
% t t-statistic 
% dof degrees of freedom 
% Z equivalent z-statistic 
% 
% V. 1.0 Stephen Fromm 2002 Aug 07 
% 
% Math for this code follows p. 5 of Mark Jenkinson and Mark Woolrich, 
% "Asymptotic T to Z and F to Z Statistic Transformations," 
% FMRIB Technical Report TR00MJ1, Oxford Centre for Functional 
% Magnetic Resonance Imaging of the Brain 
% (see http://www.fmrib.ox.ac.uk/analysis/techrep/tr00mj1/tr00mj1/) 
% 
% Note: the work by Jenkinson and Woolrich was part of work done for 
% building FSL (the FMRIB software library; see 
% http://www.fmrib.ox.ac.uk/fsl/ 
% 
% Coding errors are *not* the responsibility of Jenkinson and Woolrich. 
% Use this code at your own risk; there is no warranty covering its use.

logbetaD = -0.5*log(dof) + 0.5*log(2*pi) + 1/(4*dof);

pm = sign(t);
t = abs(t);
log_p = -0.5*log(dof) - logbetaD -log(t) - 0.5*(dof-1)*log(1 + t^2/dof) + log(1 - (dof/(dof +2))*t^(-2) + (3*dof^2/((dof+2)*(dof+4)))*t^(-4));
% 
% (Use conventional methods otherwise:) 
if (dof >= 15 & t < 7.5) 
   Z = pm*t_to_z(t,dof);
elseif (dof < 15 & log_p >= -14.5) 
   error('If dof < 15, need log(p) > -14.5 to guarantee 0.1 % relative error.');
else
    %    
    z = zeros(4,1); 

    % Z_0 in preprint is z(1) here; Z_n there is z(n+1) here

    z(1) = sqrt(-2*log_p - log(2*pi));

    for k=1:3 
      z(k+1) = sqrt(-2*log_p - log(2*pi) - 2*log(z(k)) + 2*log(1 - z(k)^(-2) +3*z(k)^(-4))); 
    end

    Z = pm*z(4); 

end