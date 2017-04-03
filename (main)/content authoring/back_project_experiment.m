%% Compute frontal-parallel view from 3 rotation parameters
addpath(genpath('.'));
close all;
% Waiting for user input
im_obj = imread('Alphabet_board_our.jpg');
im_obj_rect = [1,size(im_obj,2),size(im_obj,2),1;
                1,1,size(im_obj,1),size(im_obj,1)];
% Pre-defined image center and camera intrinsic matrix
center = [size(im,2)/2; 
          size(im,1)/2];  % Image center
K = [477, 0,  0;
     0,  477,0;
     0,  0,  1];          % Intrinsic matrix
% Compute frontal-parallel view homography
H_form = computeFrontalH2(1,X3,center, K, im);
H = H_form.T;
%% Get 4 points from user
im_warp = imwarp(im, H_form);
while (1)
    figure, imshow(im_warp);
    hold on;
    line = imrect;
    my_roi = wait(line);
    % The corner points of an user-defined rectnagle has the following
    % sequence.
    %
    % (1)------------------(2)
    %  |                    |
    %  |                    |
    %  |                    |
    %  |                    |
    % (4)------------------(3)
    position = [my_roi(1),  my_roi(1)+my_roi(3),    my_roi(1)+my_roi(3),    my_roi(1);
                my_roi(2),      my_roi(2),          my_roi(2)+my_roi(4),    my_roi(2)+my_roi(4)];
    hold off;
    close;
    % Break if 4 points are defined
    if (size(position,2)==4)
        break;
    end
end
%% Look-up table for original-prespective pixel mapping(Scene)
% Find the size of img
sz = size(im);
% Construct pixel location index for background image (The image scene)
[rows,cols]= meshgrid(1:sz(1), 1:sz(2));
imageScene_Index = [reshape(cols,1,[]);
                    reshape(rows,1,[]);
                    ones(1,length(rows(:)))]; 
imageScene_pstIndex = H' * imageScene_Index;
imageScene_pstIndex = imageScene_pstIndex ./ [imageScene_pstIndex(3,:); imageScene_pstIndex(3,:); imageScene_pstIndex(3,:)];
imageScene_pstIndex = int32(imageScene_pstIndex); % Resolve truncating issue

ptXp = position(1,:);
ptYp = position(2,:);

lsX = ptXp + double(repmat(min(imageScene_pstIndex(1,:)) - 1,1)); 
lsY = ptYp + double(repmat(min(imageScene_pstIndex(2,:)) - 1,1));
%% Construct 2 lines from 4 points, then apply inverse H to obtain the corresponding lines
ls1p = [lsX(1); lsY(1); lsX(2); lsY(2)];
ls2p = [lsX(3); lsY(3); lsX(4); lsY(4)];
% lv1p = twopts2L(ls1p);
% lv2p = twopts2L(ls2p);
pts=[[ls1p(1:2),ls1p(3:4),ls2p(1:2),ls2p(3:4)];[1,1,1,1]];
ptsp=inv(H)'*pts; 
ptsp=ptsp(1:2,:)./[ptsp(3,:);ptsp(3,:)]; % Normalise w dimension

% Extract the back-project points coordinate
ls1p_back=[ptsp(:,1);ptsp(:,2)];
ls1p_back = floor(ls1p_back); % resolve truncate issue

ls2p_back=[ptsp(:,3);ptsp(:,4)];
ls2p_back = floor(ls2p_back); % resolve truncate issue

im_rect = [ls1p_back(1),ls1p_back(3),ls2p_back(1),ls2p_back(3);
            ls1p_back(2),ls1p_back(4),ls2p_back(2),ls2p_back(4)];
T = fitgeotrans(im_obj_rect',im_rect','projective');
im_obj_warp = imwarp(im_obj, T);
T_H = T.T;

%% Look-up table for original-prespective pixel mapping(Scene)
% Find the size of img
sz = size(im_obj);
% Original pixel index lookup table
[rows,cols]= meshgrid(1:sz(1), 1:sz(2));
B = [reshape(cols,1,[]);
     reshape(rows,1,[]);
     ones(1,length(rows(:)))]; 
% Perform warping 
BB = T_H' * B;
BB = BB ./ [BB(3,:); BB(3,:); BB(3,:)];
BB = int32(BB); % Truncate from float to int
ptYp_1 = BB(2,:) - min(BB(2,:)) +1;
ptXp_1 = BB(1,:) - min(BB(1,:)) +1;
ptXYp = [ptXp_1;ptYp_1];
% Image index mapping
% ind(n) == y + (x - 1) * y_stride
index_img = zeros(1,4);
index_img(1) = im_obj_rect(1) + (im_obj_rect(2) - 1) * sz(2);
index_img(2) = im_obj_rect(3) + (im_obj_rect(4) - 1) * sz(2);
index_img(3) = im_obj_rect(5) + (im_obj_rect(6) - 1) * sz(2);
index_img(4) = im_obj_rect(7) + (im_obj_rect(8) - 1) * sz(2);
im_warp_corner = [ptXYp(:,index_img(1)),ptXYp(:,index_img(2)),ptXYp(:,index_img(3)),ptXYp(:,index_img(4))];

%% Point coordinates to pixel indices conversion (experiment...)
%Object 
im_warp_corner = double(im_warp_corner);
x_vertices = [im_warp_corner(1),im_warp_corner(3),im_warp_corner(5),im_warp_corner(7),im_warp_corner(1)];
y_vertices = [im_warp_corner(2),im_warp_corner(4),im_warp_corner(6),im_warp_corner(8),im_warp_corner(2)];
mask = poly2mask(x_vertices,y_vertices,size(im_obj_warp,1),size(im_obj_warp,2));
object_index = find(mask==1);
x_vertices = [ls1p_back(1),ls1p_back(3),ls2p_back(1),ls2p_back(3),ls1p_back(1)];
y_vertices = [ls1p_back(2),ls1p_back(4),ls2p_back(2),ls2p_back(4),ls1p_back(2)];
mask = poly2mask(x_vertices,y_vertices,size(im,1),size(im,2));
pixel_index = find(mask==1);
%% Change RGB within the 4 points bounding region defined
img_enplace = im;
img_objectContent = im_obj_warp;
img_stride = size(img_enplace,1) * size(img_enplace,2);
img_content_stride = size(im_obj_warp,1) * size(im_obj_warp,2);
img_enplace(pixel_index) = im_obj_warp(object_index);
img_enplace(pixel_index + img_stride) = im_obj_warp(img_content_stride + object_index);
img_enplace(pixel_index + (2*img_stride)) = im_obj_warp(2*img_content_stride + object_index);

%% Show the points back-projection result
% Show the points selected by user in the prespective view
figure, subplot(2,1,1);
imshow(im_warp);
hold on;
title('rectangle selected by the user in frontal-parallel view');
plot(ptXp(1), ptYp(1), 'x', 'Color', 'red', 'LineWidth', 3);
plot(ptXp(2), ptYp(2), 'x', 'Color', 'cyan', 'LineWidth', 3);
plot(ptXp(3), ptYp(3), 'x', 'Color', 'yellow', 'LineWidth', 3);
plot(ptXp(4), ptYp(4), 'x', 'Color', 'magenta', 'LineWidth', 3);
hold off;
% Back-project points to its original view
subplot(2,1,2);
imshow(im);
hold on;
title('rectangle back-project to original view');
plot(ls1p_back(1), ls1p_back(2), 'x', 'Color', 'red', 'LineWidth', 3);
plot(ls1p_back(3), ls1p_back(4), 'x', 'Color', 'cyan', 'LineWidth', 3);
plot(ls2p_back(1), ls2p_back(2), 'x', 'Color', 'yellow', 'LineWidth', 3);
plot(ls2p_back(3), ls2p_back(4), 'x', 'Color', 'magenta', 'LineWidth', 3);
hold off;
% enplace the image object onto the bounding area in original view
figure, imshow(img_enplace);
title('Augmented result in the original view');