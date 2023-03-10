%% 单跨梁的静力程序
%   考虑长为L、半径为r的一端简支一端刚固梁受分布力q、中点集中力F作用下的响应
%   解析解为：w = 2*L*L^3/24/E/I*X.*X/L^2.*(X.*X/L^2-5/2*X/L+3/2)
clc;clear all;

%% 初始化梁参数
% L - 梁的长度
% r - 梁的半径
% p - 梁的密度
% E - 杨氏模量
% A - 截面积
% I - 截面惯性矩 圆π*d^4/64
L = 10;
r = 0.02;
p = 8000;
E = 2.1E11;
A = pi * r^2;
I = pi * (2 * r)^4 / 64;

%% 单元离散化及建立单元矩阵
% n - 单元个数
% h - 网格尺度
% X(i) - 节点位置
n = 50;
h = L/n;
X = 0:h:L;

% 建立单元刚度矩阵
%   ke - 单元刚度矩阵
ke = E * I / h^3 .* [12   6*h    -12   6*h;...
                     6*h  4*h^2  -6*h  2*h^2;...
                     -12  -6*h   12    -6*h;...
                     6*h  2*h^2  -6*h  4*h^2];

% 建立单元外力矩阵
%   N(x) - 形函数分量
%   q(x) - 分布力
%   f(x) - 集中力
%   r - 单元位移矩阵
syms x;
q(x) = 0.2 + 0 * x ;
f(x) = 0 * x ; % 直接在总刚度矩阵中修正
N(x) = [1-3*x^2/h^2+2*x^3/h^3 x-2*x^2/h+x^3/h^2 3*x^2/h^2-2*x^3/h^3 -x^2/h+x^3/h^2];
r = int(N(x)'*q(x),x,0,h);

%% 装配整体矩阵
% V - 整体位移矩阵
% K - 整体刚度矩阵
% R - 整体外力矩阵
V = zeros(2*(n+1),1);

K = zeros(2*(n+1));
for i = 1:2:2*(n+1)-3
    K(i:i+1,i:i+1) = K(i:i+1,i:i+1) + ke(1:2,1:2);
    K(i:i+1,i+2:i+3) = K(i:i+1,i+2:i+3) + ke(1:2,3:4);
    K(i+2:i+3,i:i+1) = K(i+2:i+3,i:i+1) + ke(3:4,1:2);
    K(i+2:i+3,i+2:i+3) = K(i+2:i+3,i+2:i+3) + ke(3:4,3:4);
end

R = zeros(2*(n+1),1);
for i = 1:2:2*(n+1)-3
    R(i:i+1) = R(i:i+1)+ r(1:2);
    R(i+2:i+3) = R(i+2:i+3) + r(3:4);
end
f(x) = 0 * x + 0.2;
R((n/2+1)*2+1) = R((n/2+1)*2+1) + double(f(x));

%% 设置边界条件
% 左端刚固 v = 0 a = 0
R(1) = 0;
K(1,1) = E.*K(1,1);
R(2) = 0;
K(2,2) = E.*K(2,2);
% 右端简支 v = 0 
R(2*(n+1)-1) = 0;
K(2*(n+1)-1,2*(n+1)-1) = E.*K(2*(n+1)-1,2*(n+1)-1);

%% 数值方法求解有限元方程
%% 数值方法求解有限元方程
% 方程为4对角的稀疏矩阵，用雅可比迭代法求解
% d = diag(K);
% lu = K - diag(d);
% V0 = V + 1;
% while norm(V-V0)>1e-10
%     V0 = V;
%     V = (R - lu * V0) ./ d;
% end
% 测试发现 雅可比迭代误差远大于LU分解，且非常慢 
% 雅可比迭代慢的原因是迭代矩阵谱半径为0.999998417621995，速度几乎为0
% 雅可比迭代误差大的原因是矩阵K的条件数为6.92273e+16,Kv = R为病态问题,迭代过程中误差累计严重

% 方程为4对角的稀疏矩阵，用LU分解法求解
[c,u] = lu(K);
V = u\(c\R);

%% 数据处理与图像绘制
v = V(1:2:end);
a = V(2:2:end);
plot(X,v,'-*');
hold on;

w1 = double(q(x))*L*L^3/24/E/I*X.*X/L^2 .* (X.*X/L^2 - 5/2*X/L + 3/2);
w2 = double(f(x))*L^3/6/E/I *X.*X/L^2 .* (3/2*1/4*(1+1/2)-(1-3/2*1/4+1/16).*X/L);
w = w1+w2;
plot(X,w);


legend('数值解','解析解');
title('{\bf 挠度曲线}','Color','b');
xlabel('x')
ylabel('扰度w')