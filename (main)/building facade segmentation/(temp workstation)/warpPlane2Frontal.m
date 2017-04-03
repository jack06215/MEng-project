%% Construct homography matrix
planeID = 1;
ax=X(planeID*2-1);ay=X(planeID*2);az=X3(planeID*3);
% ax=X(1);ay=X(2);az=0.6;
% flag1 = ax >= 1 || ax <= -1;
% flag2 = ay >= 1 || ay <= -1;
% flag3 = az >



%% Ortg 
R1=makehgtform('xrotate',ax,'yrotate',ay);
R3=makehgtform('zrotate',az);
% R1=makehgtform('xrotate',ax,'yrotate',ay,'zrotate',az); 
R1=R1(1:3,1:3);
R3=R3(1:3,1:3);
C_center = [1,0, -center(1);
            0,1, -center(2);
            0,0,1];

       
H1= K*((R3 * R1)/K)*C_center;
% %% Ortg 
% R1=makehgtform('xrotate',ax, 'yrotate', ay);
% R2=makehgtform('yrotate',ay);
% R3=makehgtform('zrotate',az);
% % R1=makehgtform('xrotate',ax,'yrotate',ay,'zrotate',az); 
% R1=R1(1:3,1:3);
% R2=R2(1:3,1:3);
% R3=R3(1:3,1:3);
% C_center = [1,0, -center(1);
%             0,1, -center(2);
%             0,0,1];
% 
%        
% H1= K*((R1 * R3)/K)*C_center;

%%
s = norm(H1(:,2)) / norm(H1(:,1));
% det > 0
if (0)
    det = H1(1,1)*H1(2,2) - H1(2,1)*H1(1,2); disp(det);
    if (det <= 0)
        error('det is out of range, program stop');
    else
        disp('det passed');
    end
    % 0 < sqrt(N1_N2) < 1
    N1 = sqrt(H1(1,1)*H1(1,1)+H1(2,1)*H1(2,1)); disp(N1);
    N2 = sqrt(H1(1,2)*H1(1,2)+H1(2,2)*H1(2,2)); disp(N2);
    if (N1 <= 0 || N1 >= 1 || N2 <= 0 || N2 >= 1)
        error('N1/N2 is out of range, program stop');
    else
        disp('N1,N2 passed');
    end
    % 0 < sqrt(N3) < 0.001
    N3 = sqrt(H1(3,1)*H1(3,1)+H1(3,2)*H1(3,2)); disp(N3);
    if (N3 <= 0 || N3 >= 0.0015)
        error('N3 is out of range, program stop');
    else
        disp('N3 passed');
    end
end

%%
% s = norm(H1(:,2)) / norm(H1(:,1));
% A_s = [1,1/s,1];
% AA_s = diag(A_s);
% H1 = H1 * AA_s;

%


%% Calclating Resultant Translation and Scale
Rect = [0,0,1; size(im,2),0,1; size(im,2),size(im,1),1; 0,size(im,1),1]';
Rect_out = homoTrans(H1, Rect);
% bb = repmat(Rect_out_1(3),3,4);
% Rect_out = Rect_out_1;%./bb;
%% Fix scaling, based on length.
scale_fac = abs((max(Rect_out(1,2), Rect_out(1,3))- min(Rect_out(1,1), Rect_out(1,4)))/size(im,2));
Rect_out = Rect_out./repmat(scale_fac,3,4);
%% Shift the Rect_out back to "pixel coordinate" w.r.t. Rect
Rect_out(1,2) = Rect_out(1,2) - Rect_out(1,1);
Rect_out(2,2) = Rect_out(2,2) - Rect_out(2,1);
Rect_out(1,3) = Rect_out(1,3) - Rect_out(1,1);
Rect_out(2,3) = Rect_out(2,3) - Rect_out(2,1);
Rect_out(1,4) = Rect_out(1,4) - Rect_out(1,1);
Rect_out(2,4) = Rect_out(2,4) - Rect_out(2,1);
Rect_out(1,1) = Rect_out(1,1) - Rect_out(1,1);
Rect_out(2,1) = Rect_out(2,1) - Rect_out(2,1);
% Conversion: dropping off the 'w coordinate', and transpose
Rect = Rect(1:2,:)'; 
Rect_out = Rect_out(1:2,:)';
%% Fit geometric transform between Rect and Rect_out
T1 = fitgeotrans(Rect,Rect_out,'projective');

aaa = [cos(az),sin(az),0;-sin(az),cos(az),0;0,0,1];
tform_in = projective2d(aaa);

im_new = imwarp(im, T1');


hfrom_in = [cos(az),sin(az),0;-sin(az),cos(az),0;0,0,1];
% im_new_t = imrotate(im_new,rad2deg(-az),'bilinear');
im_new_t = im_new;
p1 = T1.T;
p2 = hfrom_in;
p1p2 = p1*p2;

tformm = projective2d(p1p2);
result_tform = tformm.T;
im_aa = imwarp(im,tformm');
imwrite(im_aa, 'reference.png');
% figure,imshow(im_aa)
% inv_tformm=invert(tformm);
% im_aaa = imwarp(im_aa,inv_tformm');
% figure,imshow(im_aaa)


hFig=[hFig az_fig];
set(hFig(1,end),'Name','Gap Filled and Extended Lines');
imagesc(im_new), axis equal;
