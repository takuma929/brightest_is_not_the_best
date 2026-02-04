function MB_vector = spectralvectortoMB_400to700nm(multispectralVector)

load(fullfile(pwd,'data','lms_400to700.mat'),'lms_400to700');
    
Lw = 0.689903;
Mw = 0.348322;
Sw = 0.0371597/0.0192; 

Rlms = multispectralVector*lms_400to700(:,2:4);

MB_vector = zeros(length(multispectralVector),3);

Lum = Lw*Rlms(:,1) + Mw*Rlms(:,2);
r = Lw*Rlms(:,1)./Lum;
b = Sw*Rlms(:,3)./Lum;
r(isnan(r))=0;
b(isnan(b))=0;

MB_vector(:,3) = Lum;
MB_vector(:,1) = r;
MB_vector(:,2) = b;

end
