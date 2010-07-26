function [ang, epe]=flowAngErr(tu, tv, u, v)
%
% very messy
%
% return the Barron et al angular error.  bord is the pixel width of the
% border to be ingnored.
smallflow=0.0;
bord = 0;
stu=tu(bord+1:end-bord,bord+1:end-bord);
stv=tv(bord+1:end-bord,bord+1:end-bord);
su=u(bord+1:end-bord,bord+1:end-bord);
sv=v(bord+1:end-bord,bord+1:end-bord);

% ignore a pixel if both u and v are zero
%ind2=find(abs(stu(:))>smallflow|abs(stv(:)>smallflow));
ind2 = [1:length(tu(:))];
n=1.0./sqrt(su(ind2).^2+sv(ind2).^2+1);
un=su(ind2).*n;
vn=sv(ind2).*n;
tn=1./sqrt(stu(ind2).^2+stv(ind2).^2+1);
tun=stu(ind2).*tn;
tvn=stv(ind2).*tn;
ang=acos(un.*tun+vn.*tvn+(n.*tn));
ang=ang*180/pi;

epe = sqrt((stu-su).^2 + (stv-sv).^2);

ang = reshape(ang, size(stu, 1), size(stu, 2));
epe = reshape(epe, size(stu, 1), size(stu, 2));

% dont do areas with no flow
%mask = (tu(:,:,1)<200);
% border = 10;
% mask(1:border,:) = 0;
% mask(end-border:end,:) = 0;
% mask(:,1:border) = 0;
% mask(:,end-border:end) = 0;
%epe = epe.*mask;
%ang = ang.*mask;