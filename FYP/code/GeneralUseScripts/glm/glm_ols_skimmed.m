

function res = glm_ols_skimmed(Data,Model,Contrasts,Mask,DOFadjust,Annotation);

% res = glm_ols(Data,Model,Contrasts,Mask,DOFadjust,Annotation);
%    
% Returns OLS estimates for the GLM specified by Data, Model and Contrast
% Data, Model and Contrasts are 2D matrices.
% res will return a structure of t scores, PE's, COPE's and
% VARCOPES.
%   
   
   if(nargin<4)
     Mask = ones(1,size(Data,2)); 
   end;

   
   if(length(size(Data))==4)
      xdim = size(Data,1);
      ydim = size(Data,2);
      zdim = size(Data,3);
      tdim = size(Data,4);
      Data = reshape(Data,xdim*ydim*zdim,tdim)';
   else
     xdim = size(Data,2);
     ydim = 1;
     zdim = 1;
     tdim = size(Data,1); 
   end;
  
   if(size(Mask(:))==size(Data,1))
     Data=Data(:,Mask);
   end;
   
   %OLS
   beta = pinv(Model)*Data;
   resi  = Data - Model * beta;
    
   nu=size(Model,1)-size(Model,2);
   
   sigsq = sum(resi.^2)./nu;
 
   if(nargin>5)
      nu = nu - DOFadjust;
   end;
 
   cbeta = Contrasts'*beta;
   varcb = diag(Contrasts'*pinv(Model)*pinv(Model)'*Contrasts)*sigsq;
   
   t = cbeta./(sqrt(varcb));
%    p=1-tcdf(t,nu); %this is one tailed
   p = 2 * tcdf(-abs(t), nu); %this is two-tailed
   
   res.beta = beta;
   res.residual=resi;
   res.sigsq=sigsq;
   res.varcb = varcb;
   res.cbeta = cbeta;
   res.dof = nu;
   res.t=t;
   res.p=p;
 
   if(nargin>6)
      res.what = Annotation;
   end;
   