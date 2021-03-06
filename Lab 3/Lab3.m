close all 
clear all
clc;

%step 1 Camera 1 is set to world frame
au1 = 100; av1 = 120; uo1 = 128; vo1 = 128;
height1 = 256;
width1 = 256; %Image size: 256 x 256
R1 = eye(3,3);
T1 = zeros (3,1);

%step 2 Camera 2
au2 = 90; av2 = 110; uo2 = 128; vo2 = 128;
ax = 0.1; by = pi/4 ; cz = 0.2 ;
tx = -1000; ty = 190 ; tz = 230 ;
height2 = 256;
width2 = 256; %Image size: 256 x 256

%step 3  intrinsic transformation matrices
I1 = [au1, 0, uo1;
       0, av1, vo1;
       0, 0, 1];
I2 = [au2,0,uo1;
        0,av2,vo2;
        0,0,1];
    
Rotx = [1,0,0;
        0, cos(ax), -sin(ax);
        0, sin(ax),  cos(ax)];
        
Roty = [cos(by), 0, sin(by);
        0, 1, 0;
        -sin(by), 0, cos(by)];

Rotz = [cos(cz),-sin(cz),0;
         sin(cz), cos(cz),0;
         0,0,1]; 
R2 = Rotx*Roty* Rotz;
T2 = [tx;ty;tz];

%step 4 Fundamental Matrix
T_cross = [0,-T2(3),T2(2);
            T2(3),0,-T2(1);
            -T2(2), T2(1),0];
F= inv(I2') * R2' * T_cross * inv(I1);
F = F./F(9);

%step 5

V(:,1) = [100;-400;2000;1];
V(:,2) = [300;-400;3000;1];
V(:,3) = [500;-400;4000;1];
V(:,4) = [700;-400;2000;1];
V(:,5) = [900;-400;3000;1];
V(:,6) = [100;-50;4000;1];
V(:,7) = [300;-50;2000;1];
V(:,8) = [500;-50;3000;1];
V(:,9) = [700;-50;4000;1];
V(:,10) = [900;-50;2000;1];
V(:,11) = [100;50;3000;1];
V(:,12) = [300;50;4000;1];
V(:,13) = [500;50;2000;1];
V(:,14) = [700;50;3000;1];
V(:,15) = [900;50;4000;1];
V(:,16) = [100;400;2000;1];
V(:,17) = [300;400;3000;1];
V(:,18) = [500;400;4000;1];
V(:,19) = [700;400;2000;1];
V(:,20) = [900;400;3000;1];
%for more points from 20 to 200
more_range = 21:200;
V(1,more_range) = randi(1000,1,length(more_range));
V(2,more_range) = round(800 * rand(1,length(more_range)) - 400);
V(3,more_range) = randi(4000,1,length(more_range));
V(4,more_range) = ones(1,length(more_range));
pn = size(V,2);

%step 6 

% Define intrinsic and extrinsic matrix first
IN1 = [I1,[0;0;0]];% 3*4 intrinsic matrix for camera1
IN2 = [I2,[0;0;0]];% 3*4 intrinsic matrix for camera2
EX1 = [R1,T1;0,0,0,1];% 4*4 extrinsic matrix for camera1
EX2 = inv([R2,T2;0,0,0,1]); %4*4 extrinsic matrix for camera2 (Transfer from world coordinate to image2 coordinate)

% Compute the 2D points in both image planes

v1 = zeros(3,20);
v2 = zeros(3,20);

for i = 1 : 20
   v1(:,i) = IN1 * EX1 * V(:,i);
   v1(:,i) = v1(:,i) ./ v1(3,i);
   v2(:,i) = IN2 * EX2 * V(:,i);
   v2(:,i) = v2(:,i) ./ v2(3,i);
end

%step 7 Plotting the projected points for camera 1 and camera 2
figure, scatter(v1(1,:), v1(2,:),'MarkerFaceColor','red'), 
title('Projected points for camera 1');
figure, scatter(v2(1,:), v2(2,:), 'MarkerFaceColor','red'),
title('Projected points for camera 2');

%step 8 and 9 Compute Fundamental matrix with 8 point method and Least Squares 

step8 = Fundamental_matrix(v1,v2);

%step 9

% F and step 8 matrix are same 
mean_dif = mean(mean((step8 - F)));

%step 10 Plotting epipolar geometry

% Plot image plane 1
epi_plot(v1(:,1:20),v2(:,1:20),F',[0,256],[-340, 256]);
%plot(pl(1),pl(2),'b*','MarkerSize',10);
title('Epipoles and Epipolar lines in image plane 1');

% Plot image plane 2
epi_plot(v2(:,1:20),v1(:,1:20),F,[0,256],[0,400]);
title('Epipoles and Epipolar lines in image plane 2');

Tr1 = IN1 * EX1; % world point to frame 1
Tr2 = IN2 * EX2; % world point to frame 2

%step 11 Add gaussian noise to 2D Points
%Adding noise for [-1,+1]

std_noise = 0.5;

vn1 = v1;
vn1(1:2,:) = vn1(1:2,:) + std_noise * randn(2,size(vn1,2)); % Get noisy 2D points

vn2 = v2;
vn2(1:2,:) = vn2(1:2,:) + std_noise * randn(2,size(vn2,2)); % Get noisy 2D points
%% Repeat Step8 up to 10 with the noisy 2D points
noise_range = 20;

Tr1 = IN1 * EX1; % Transform from world frame to image 1
Tr2 = IN2 * EX2; % Transform from world frame to image 2

pr_tmp = Tr2 * [0;0;0;1];
pl_tmp = Tr1 * [tx;ty;tz;1];
pr = [pr_tmp(1)/pr_tmp(3),pr_tmp(2)/pr_tmp(3)];
pl = [pl_tmp(1)/pl_tmp(3),pl_tmp(2)/pl_tmp(3)];

% Step8 : Compute fundamental matrix
F_n_svd = compute_F(vn1(:,1 : noise_range),vn2(:,1 : noise_range));

[m,d] = epi_plot(vn1(:,1 : noise_range),vn2(:,1 : noise_range),F_n_svd',[0,height1],[-340, width1]);
plot(pl(1),pl(2),'b*','MarkerSize',10);
%plot(plot::Rectangle,LineColor = RGB::Black, LineStyle = Dashed);

%plot(Rectangle,LineColor = RGB::Black, LineStyle = Dashed);
%rectangle('Position', [0 0 256 256]);
title('Epipoles and Epipolar lines in image plane 1 with noise');
mean_dis_image_1 = computeMeanDis(vn1(:,1 : noise_range),m,d)

[m,d] = epi_plot(vn2(:,1 : noise_range),vn1(:,1 : noise_range),F_n_svd,[0,256],[0,400]);
plot(pr(1),pr(2),'b*','MarkerSize',10);
title('Epipoles and Epipolar lines in image plane 2 with noise');
mean_dis_image_2 = computeMeanDis(vn2(:,1 : noise_range),m,d)


% epi_plot(vn1,vn2,F_n',[0,256],[-340, 256]);

%%step 13  Adding noise for [-2,+2]
%std_noise = 1;

% <<< ---------------------     PART 2 - -- - - -- -- -- - - - - -- -->

%step 14
%compute F matrix with SVD
F_svd = compute_F_svd(v1,v2);
F_n_svd = compute_F_svd(vn1(:,1 : noise_range),vn2(:,1 : noise_range));

%repeat the steps from step 10 by replacing with SVD matrix
% Plot image plane 1
epi_plot_svd(v1(:,1:20),v2(:,1:20),(F_svd)',[0,256],[-340, 256]);
%plot(pl(1),pl(2),'b*','MarkerSize',10);
title('Epipoles and Epipolar lines in image plane 1');

% Plot image plane 2
epi_plot_svd(v2(:,1:20),v1(:,1:20),F_svd,[0,256],[0,400]);
title('Epipoles and Epipolar lines in image plane 2');

Tr1 = IN1 * EX1; % world point to frame 1
Tr2 = IN2 * EX2; % world point to frame 2

%step 11 Add gaussian noise to 2D Points
%Adding noise for [-1,+1]

std_noise = 0.5;

vn1 = v1;
vn1(1:2,:) = vn1(1:2,:) + std_noise * randn(2,size(vn1,2)); % Get noisy 2D points

vn2 = v2;
vn2(1:2,:) = vn2(1:2,:) + std_noise * randn(2,size(vn2,2)); % Get noisy 2D points
%% Repeat Step8 up to 10 with the noisy 2D points
noise_range = 20;

Tr1 = IN1 * EX1; % Transform from world frame to image 1
Tr2 = IN2 * EX2; % Transform from world frame to image 2

pr_tmp = Tr2 * [0;0;0;1];
pl_tmp = Tr1 * [tx;ty;tz;1];
pr = [pr_tmp(1)/pr_tmp(3),pr_tmp(2)/pr_tmp(3)];
pl = [pl_tmp(1)/pl_tmp(3),pl_tmp(2)/pl_tmp(3)];

% Step8 : Compute fundamental matrix
F_n_svd = compute_F(vn1(:,1 : noise_range),vn2(:,1 : noise_range));

[m,d] = epi_plot_svd(vn1(:,1 : noise_range),vn2(:,1 : noise_range),F_n_svd',[0,height1],[-340, width1]);
plot(pl(1),pl(2),'b*','MarkerSize',10);
%plot(plot::Rectangle,LineColor = RGB::Black, LineStyle = Dashed);

%plot(Rectangle,LineColor = RGB::Black, LineStyle = Dashed);
%rectangle('Position', [0 0 256 256]);
title('Epipoles and Epipolar lines with SVD in image plane 1 with noise');
mean_dis_image_1_svd = computeMeanDis(vn1(:,1 : noise_range),m,d)

[m,d] = epi_plot_svd(vn2(:,1 : noise_range),vn1(:,1 : noise_range),F_n_svd,[0,256],[0,400]);
plot(pr(1),pr(2),'b*','MarkerSize',10);
title('Epipoles and Epipolar lines with SVD in image plane 2 with noise');
mean_dis_image_2_svd = computeMeanDis(vn2(:,1 : noise_range),m,d)






% <<< ---------------------     PART 3 - -- - - -- -- -- - - - - -- -->
%% Plot system

figure;
ps_idx = 1:4;
ps_3D = V(1:3,ps_idx);

% plot a 3D point
scatter3(ps_3D(1,:),ps_3D(2,:),ps_3D(3,:)); hold on; title('Epipolar system');
xlabel('x'); ylabel('y'); zlabel('z')

% plot the axis of camera 1
o_c1 = [0;0;0;1];% origin of camera 1
x_c1 = [1;0;0;0];% x axis of camera 1
y_c1 = [0;1;0;0];% y axis of camera 1
z_c1 = [0;0;1;0];% z axis of camera 1

plot3(o_c1(1)+[0, 100*x_c1(1), nan, 0, 100*y_c1(1), nan, 0, 100*z_c1(1)], o_c1(2)+[0, 100*x_c1(2), nan, 0, 100*y_c1(2), nan, 0, 100*z_c1(2)],o_c1(3)+[0, 100*x_c1(3), nan, 0, 100*y_c1(3), nan, 0, 100*z_c1(3)] );
t_c1 = text(o_c1(1), o_c1(2), o_c1(3), '\leftarrow camera 1','FontSize',10);

% Plot the image plane of camera 1

f=80;% focal length for both camera. Unit: mm

cp = [0 256 256 0;0 0 256 256]; % 4 corner points of the image plane
cp1_w = im2world(cp,R1,T1,f,uo1,vo1,au1,av1);

plane_x = [cp1_w(1,:),cp1_w(1,1)];
plane_y = [cp1_w(2,:),cp1_w(2,1)];
plane_z = [cp1_w(3,:),cp1_w(3,1)];
plot3(plane_x,plane_y,plane_z);

% plot the project point in the image plane of camera 1
ps_2D1 = v1(1:2,ps_idx);
ps_2D1_w = im2world(ps_2D1,R1,T1,f,uo1,vo1,au1,av1);
scatter3(ps_2D1_w(1,:),ps_2D1_w(2,:),ps_2D1_w(3,:),'r+');

% Plot camera 2 system

o_c2 = [tx;ty;tz;1];% origin of camera 2
x_c2 = R2*[1;0;0];% x axis of camera 2 (transform to world coordinate)
y_c2 = R2*[0;1;0];% y axis of camera 2 
z_c2 = R2*[0;0;1];% z axis of camera 2

plot3(o_c2(1)+[0, 100*x_c2(1), nan, 0, 100*y_c2(1), nan, 0, 100*z_c2(1)], o_c2(2)+[0, 100*x_c2(2), nan, 0, 100*y_c2(2), nan, 0, 100*z_c2(2)],o_c2(3)+[0, 100*x_c2(3), nan, 0, 100*y_c2(3), nan, 0, 100*z_c2(3)] );
t_c2 = text(o_c2(1), o_c2(2), o_c2(3), '\leftarrow camera 2','FontSize',10);


% Plot the image plane of camera 2

cp = [0 256 256 0;0 0 256 256];% 4 corner points of the image plane
cp_w = im2world(cp,R2,T2,f,uo2,vo2,au2,av2);

plane2_x = [cp_w(1,:),cp_w(1,1)];
plane2_y = [cp_w(2,:),cp_w(2,1)];
plane2_z = [cp_w(3,:),cp_w(3,1)];
plot3(plane2_x,plane2_y,plane2_z);

% plot the project point in the image plane of camera 2
ps_2D2 = v2(1:2,ps_idx);
ps_2D2_w = im2world(ps_2D2,R2,T2,f,uo2,vo2,au2,av2);
scatter3(ps_2D2_w(1,:),ps_2D2_w(2,:),ps_2D2_w(3,:),'r+');

% plot epipoles for both camera
pl_w = im2world(pl',R1,T1,f,uo1,vo1,au1,av1);
pr_w = im2world(pr',R2,T2,f,uo2,vo2,au2,av2);

plot3(pl_w(1),pl_w(2),pl_w(3),'b*');
plot3(pr_w(1),pr_w(2),pr_w(3),'b*');


% Plot the pi plane
for i = 1 : length(ps_idx)
    plot3([o_c1(1),o_c2(1),ps_3D(1,i),o_c1(1)],[o_c1(2),o_c2(2),ps_3D(2,i),o_c1(2)],[o_c1(3),o_c2(3),ps_3D(3,i),o_c1(3)],'-');
end













