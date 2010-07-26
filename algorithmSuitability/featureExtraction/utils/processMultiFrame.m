scene = 'cruiserMe'
for i=1:10
    load([scene num2str(i)])
    [angBA epeBA] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvBA(:,:,1), uvBA(:,:,2));
    [angTV epeTV] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvTV(:,:,1), uvTV(:,:,2));
    [angHS epeHS] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvHS(:,:,1), uvHS(:,:,2));
    [angFL epeFL] = flowAngErrMe(tuv(:,:,1), tuv(:,:,2), uvFL(:,:,1), uvFL(:,:,2));

    % write epe
    ba = ((epeBA.*mask)./max(max(epeBA.*mask)));
    tv = ((epeTV.*mask)./max(max(epeTV.*mask)));
    hs = ((epeHS.*mask)./max(max(epeHS.*mask)));
    fl = ((epeFL.*mask)./max(max(epeFL.*mask)));
    
    imwrite(ba, ['epe/ba/ba' num2str(i) '_' num2str(i+1) 'epe.png'], 'PNG')
    imwrite(tv, ['epe/tv/tv' num2str(i) '_' num2str(i+1) 'epe.png'], 'PNG')
    imwrite(hs, ['epe/hs/hs' num2str(i) '_' num2str(i+1) 'epe.png'], 'PNG')
    imwrite(fl, ['epe/fl/fl' num2str(i) '_' num2str(i+1) 'epe.png'], 'PNG')

    %flow
    imwrite(flowToColor(uvBA), ['flow/ba/ba' num2str(i) '_' num2str(i+1) 'flow.png'], 'PNG')
    imwrite(flowToColor(uvTV), ['flow/tv/tv' num2str(i) '_' num2str(i+1) 'flow.png'], 'PNG')
    imwrite(flowToColor(uvHS), ['flow/hs/hs' num2str(i) '_' num2str(i+1) 'flow.png'], 'PNG')
    imwrite(flowToColor(uvFL), ['flow/fl/fl' num2str(i) '_' num2str(i+1) 'flow.png'], 'PNG')
end