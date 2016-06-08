%% Intermidiate Result Debug
%% --> Extract Inliers
inlier1 = inliers{2};
[ar,ac]=find(inlier1>0);
myFig = [];
savepath = 'captured\mmexport1458908621320.jpg';
for i=1:size(ar,1)
    myFig = [myFig,az_fig];
    set(myFig(1,end),'Name','Extracted line-pairs');
    imagesc(im),axis equal;
    hold on;
    plot(LS([1,3],ac(i)), LS([2,4],ac(i)),'color','red','LineWidth',2);
    plot(LS([1,3],ar(i)), LS([2,4],ar(i)),'color','red','LineWidth',2);
    title(['Inlier #', num2str(i)]);
    hold off;
    
    name = [savepath '_experiment_' num2str(i) '_' get(myFig(1,i),'Name') '.jpg'];
    print(myFig(i), '-djpeg', name);
    close;
end
% for i = 1:length(myFig)
%     
% end

%% --> LSD
% lines = getLines(rgb2gray(im),40);
% lines = lines(:,1:4)';
% lines = [lines(1,:); lines(3,:); lines(2,:); lines(4,:)];
% % img_ls_center = img_ls - repmat(center,2,size(img_ls,2));
% figure,imshow(im);
% hold on;
% for i = 1:size(lines,2)
%     plot(lines([1,3],i), lines([2,4],i),'color','red','LineWidth',2);
% end