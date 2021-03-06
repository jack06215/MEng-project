function [x,currinliers,x3]=nextRANSAChypo(L,remadj,alladj,K,highthresh,numPairs,maxTrials,maxDataTrials,poptype,talk)

% hypo2 uses all adjacent pairs to compute inliers in the EM loop but still
% uses only remaining adjacent pairs in RANSAC (need to be changed in RANSAC)
% hypo3: changed to exclude any region processing

[H,currinliers,x]=ransacfitH(L,K,remadj,highthresh,numPairs,poptype,maxTrials,maxDataTrials,talk);
xx = x;
% [ar,ac] = find(currinliers>0);
% tmp = [41,42,43,69,72,73];
% index_tmp = sub2ind(size(currinliers),ar(tmp),ac(tmp));
% currinliers(index_tmp) = 0;

% currinliers = load('tmp_inliers.mat');
% currinliers = currinliers.tmp_inliers;
% mat2cell(currinliers,size(currinliers,1),size(currinliers,2));

% EM on inliers and homography
[tempH,tempx]=rectifyOrthoR(L,K,currinliers,xx,0);
[H3,x3] = rectifyInplaneR(L,K,currinliers,0,tempx,talk);
tempinliers=findHinliers(tempH,L,highthresh).*alladj;
while sum(sum(tempinliers))>sum(sum(currinliers))
    if talk
        fprintf(1,'inliers icrease from %d to %d\n',sum(sum(currinliers)),sum(sum(tempinliers)));
    end
    currinliers=tempinliers;
    x=tempx;
    
    % fit new model and inliers
    [tempH,tempx]=rectifyOrthoR(L,K,currinliers,xx,1);
    [H3,x3] = rectifyInplaneR(L,K,currinliers,x3(3),tempx,talk);
    tempinliers=findHinliers(tempH,L,highthresh).*alladj;
end

[ind1,ind2]=find(currinliers>0);
ind=union(ind1,ind2);

if talk
    fprintf(1,'----\npercent inliers: %f\n',sum(sum(currinliers))/sum(sum(alladj)));
    fprintf(1,'orthogonal pairs: %d\n',sum(sum(currinliers)));
    fprintf(1,'line inliers: %d\n',length(ind));
    if talk>2, pause, else pause(1), end
end