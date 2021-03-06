function [L1,L2,adj,hFig]=getLSadj(im,LSDscale,gapfillflag,extendflag,maxlines,athreshgap,dthreshgap,athreshadj,talk)
% Figure handle
hFig=[];

% Checkig if the image is grayscale, if not then perform conversion
if size(im,3)>1
    imgray=rgb2gray(im);
else
    imgray=im;
end
% Method 1
% LSD and take the first 4 rows containing 2 end points
% L = lsd(double(imgray'),LSDscale);
% L=L(1:4,:);


% Method 2
L = getLines(imgray,15);
L = L(:,1:4)';
L = [L(1,:); L(3,:); L(2,:); L(4,:)];

% Method 3
imgray = im2double(imgray);
%[~, ~, ~, L] = ml_lineSelection(imgray, L);


% DEBUG OUTPUT - Gap filling
if talk
    disp('filling gaps');
end

% Perform gap filling
if gapfillflag
    L1=fillgaps3(L,athreshgap,dthreshgap);
else
    L1=L;
end

% DEBUG OUTPUT - Plot the result
if talk
    hFig=[hFig az_fig];
    set(hFig(1,end),'Name','Original and Gap Filled Lines');
    imagesc(im), axis equal;
    showLS(L1);
    showLS(L,[0,1,0]);
    title('Original in green, Gap-filled in red');
    fprintf(1,'detected lines: %d, after gap-filling: %d\n',size(L,2),size(L1,2));
    if talk>2, pause, else pause(1), end
    disp('extending lines and finding adjacencies');
end
% Sort line segments by descending length
L1=sortLS(L1);

% Extract 70% of LS by its length
maxlines=min([maxlines,floor(0.7*size(L1,2))]);
L1=L1(:,1:maxlines);

% extend lines
if extendflag
    L2=extend_all_LS(L1,size(im));
else
    L2=L1;
end

% compute adjacencies
adj=findadj(L2,athreshadj);

% DEBUG OUTPUT - Fill and extended Lines
if talk
    hFig=[hFig az_fig];
    set(hFig(1,end),'Name','Gap Filled and Extended Lines');
    imagesc(im), axis equal;
    showLS(L2);
    showLS(L1,[0,1,0]);
    title('Gap filled in green, Extended in red')
end
