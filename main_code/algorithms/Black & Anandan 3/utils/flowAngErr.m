function [mang, stdang, mepe]=flowAngErr(tu, tv, u, v, bord, varargin)
% return the Barron et al angular error.  bord is the pixel width of the
% border to be ingnored.
smallflow=0.0;

% if length(varargin) == 1
%     % mask
%     tu(~varargin{1}) = 0;
%     tv(~varargin{1}) = 0;
% end;
    
stu=tu(bord+1:end-bord,bord+1:end-bord);
stv=tv(bord+1:end-bord,bord+1:end-bord);
su=u(bord+1:end-bord,bord+1:end-bord);
sv=v(bord+1:end-bord,bord+1:end-bord);

% ignore a pixel if both u and v are zero 
%ind2=find((stu(:).*stv(:)|sv(:).*su(:))~=0);
ind2=find(abs(stu(:))>smallflow|abs(stv(:)>smallflow)); 
%length(ind2)
n=1.0./sqrt(su(ind2).^2+sv(ind2).^2+1);
un=su(ind2).*n;
vn=sv(ind2).*n;
tn=1./sqrt(stu(ind2).^2+stv(ind2).^2+1);
tun=stu(ind2).*tn;
tvn=stv(ind2).*tn;
ang=acos(un.*tun+vn.*tvn+(n.*tn));
mang=mean(ang);
mang=mang*180/pi;

if nargout >= 2
    stdang = std(ang*180/pi);
end;

if nargout == 3
    epe = sqrt((stu-su).^2 + (stv-sv).^2);
    epe = epe(ind2);
    mepe = mean(epe(:));
end;

% show which pixels were ignored
% tmp=zeros(size(su));
% tmp(ind2)=1;
% imagesc(tmp)