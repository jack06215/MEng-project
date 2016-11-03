function [im,K,center,LS,LS_c,X,Ladj,hFig,L,inliers,numhyp,x3] = computeSegmentation(impath,talk)

%% This function computes segmentation for the given image.
%
%   The segmentation process is carried out by the following steps:
%       1) Read the image and its focal length by EXIF data
%       2) Detect the lines and extend them using LSD
%       3) Get the orientations of various planes in image, using RANSAC
%
%   Inputs:
%       impath      -   image path to compute segmentation
%       talk        -   set to 1 to show the intermediate debug output
%   Outputs:
%       im          -   image matrix in [(X,Y,3)]uint8 format
%       K           -   Camera matrix
%       center      -   image center
%       LS          -   All line segments
%       LS_c        -   All line segments, with image center subtracted
%       hFig        -   List of figure handles showing the results


%% Reads config parameters
% saveFig = getParameter('saveFig');
gapfillflag = getParameter('gapfillflag');  % fill gaps between colinear line segments
extendflag = getParameter('extendflag');   % extend lines
scaleimageflag = getParameter('scaleimageflag');
LSDscale = getParameter('LSDscale');
maxlines = getParameter('maxlines');
athreshgap = getParameter('athreshgap');
dthreshgap = getParameter('dthreshgap');
athreshadj = getParameter('athreshadj');
highthresh = getParameter('highthresh');
numPairs = getParameter('numPairs');
maxTrials = getParameter('maxTrials');
maxDataTrials = getParameter('maxDataTrials');
poptype = getParameter('poptype');

%% Read the input, detect lines, preprocess
% [im,K,center] = cameraInputs(impath,scaleimageflag);
im=imread(impath);
if scaleimageflag == 1 && max([size(im,1),size(im,2)])>1000
    imscale=1000/max([size(im,1),size(im,2)]);
    im=imresize(im,imscale);
end
% K = [498.949848064801,0,0;0,498.949848064801,0;0,0,1];
K = [4.771474878444084e+02,0,0;0,4.771474878444084e+02,0;0,0,1];
% K = [791,0,0;0,791,0;0,0,1];
% K = [1,0,0;0,1,0;0,0,1];
center = [size(im,2)/2;size(im,1)/2]; % Landscape
% center = [size(im,1)/2;size(im,2)/2];   % Protrait
[LS,Ladj,LS_c,L,hFig] = lineDetection(im,center,LSDscale,gapfillflag,extendflag,maxlines,athreshgap,dthreshgap,athreshadj,talk);

%% Form plane orientation hypotheses
disp('into plane orientation');
[X,inliers,numhyp,x3] = getPlaneOrientation(Ladj,L,K,highthresh,numPairs,maxTrials,maxDataTrials,poptype,talk);

%% Find unique region labels
disp('into getquads')
% [Ladj,rectangles,inds,numRectangles,quads_c,qseg] = getRectangles(Ladj,LS_c,L,x3,inliers,numhyp,K,center);
% Extract only a inliers pair (debug code)
% test = find(qseg==2);
% rectangles(:,test) = [];
% qseg(test) = [];























% 
% 
% 
% 
% %% compute their hypothesis scores
% fprintf(1,'computing hypotheses scores\n');
% inpercent = getRectanglesHypothesisScore(L,Ladj,rectangles,numRectangles,quads_c,inliers,numhyp);
% 
% %% compute their adjacency matrix
% fprintf(1,'computing quadrangle adjacency\n');
% qadj=findOverlapWithSAP(rectangles);
% 
% %% conflict removal
% [goodquads2,goodqseg2,goodqadj2,badquads2,badqseg2,goodqadj2vis,goodinds] = removeConflicts(inpercent,rectangles,qadj,qseg,inds);

%% visualize results
% hFig=[];
% if talk
%     hFig=[hFig az_fig];showquads(im,rectangles,qseg,LS,0.1);
%     axis([0,size(im,2),0,size(im,1)]); set(hFig(1,end),'Name','All Rectangles');
% %     hFig=[hFig az_fig];showquads(im,goodquads2,goodqseg2,LS,0.1);
% %     axis([0,size(im,2),0,size(im,1)]); set(hFig(1,end),'Name','Good Rectangles');
% %     hFig=[hFig az_fig];showquads(im,badquads2,badqseg2,LS,0.1);
% %     axis([0,size(im,2),0,size(im,1)]); set(hFig(1,end),'Name','Bad Rectangles');
% %     hFig=[hFig az_fig]; subplot(1,2,1), imshow(qadj),  subplot(1,2,2), imshow(goodqadj2vis),set(hFig(1,end),'Name','Adjacency Matrices');
% % 
% %     fprintf(1, '\n---\nTotal %d\nGood %d\n\n',size(rectangles,2),size(goodquads2,2));
% end
end



