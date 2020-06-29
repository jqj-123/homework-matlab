1、本系统代码环境 Matlab 2017b 中文版
2、本系统实现1、快速仿真2、动态仿真3、数据观察4、疫情演示四大功能；
3、为简化代码阅读难度，以下为仿真核心代码（仿真无GUI版）代码长度64行

clear; clc;
% ----------疫情本地数据读取----------
try
    [data ,~, ~] = xlsread('.\data\湖北省新冠状肺炎数据.xls');
    Tstart =1; Tend =100; data(isnan(data))=0;
    pat_infected = data(Tstart:Tend,2);
    pat_died = data(Tstart:Tend,4);
    pat_recover = data(Tstart:Tend,5);
catch
    disp('Excel com内核占用，请关闭excel\解除com占用并且重启Matlab')
    return
end

% ----------数据拟合获取r参数----------
[xData, yData] = prepareCurveData( pat_infected, pat_recover );
ft = fittype( 'poly1' );
[fitresult, ~] = fit( xData, yData, ft);
r = fitresult.p1;     %拟合获得的患者康复的概率

% ----------数据拟合获取d参数----------
[xData, yData] = prepareCurveData( pat_infected, pat_died );
ft = fittype( 'poly1' );
[fitresult, ~] = fit( xData, yData, ft);
d = fitresult.p1;     %拟合获得的患者死亡的概率

% ----------仿真参数设置和初始化状态----------
S = 50e4;                    % S:易感人群人数 
E = 111;                         % E:潜伏期患者
I = 270;                              % I:感染者
R = 25;                              % R:康复者
N = S + E + I + R;                  % N:总人数

r1 = 10;             % 潜伏期患者每天接触到的人
r2 = 10;                  %感染者每天接触到的人
p1 = 0.05;      % p1:潜伏期患者接触后感染的概率
p2 = 0.05;          % p2:感染者接触后感染的概率
a = 0.07;      % a:1/14潜伏期患者出现症状的概率
% r = 0.1;                      %患者康复的概率
% d = 0.1;                      %患者死亡的概率


% ----------根据模型进行预测----------
Days = 100;
for k = 1:Days
    S(k + 1) = S(k) - (r1 * p1 * E(k) * (S(k) / N) + r2 * p2 * I(k) * (S(k) / N));
    E(k + 1) = E(k) + (r1 * p1 * E(k) * (S(k) / N) + r2 * p2 * I(k) * (S(k) / N)) - (E(k) * a);
    I(k + 1) = I(k) + (E(k) * a) - (I(k) * r + I(k) * d);
    R(k + 1) = R(k) + I(k) * r;
    N = S(k + 1) + E(k + 1) + I(k + 1) + R(k + 1);
end


% ----------画出模型的预测结果----------
x = 1:Days + 1;
plot(x, S, x, E,'-o', x, I,'-*', x, R);hold on;
true_patient = data(:,2) -data(:,4)-data(:,5);
plot(x,true_patient(1:length(x)),'-.');
% ----------误差线评估----------
error = 0.5*(true_patient(1:length(I))-I');
errorbar(x,I,error,'k');hold off
grid on
xlabel('天数')% set(get(gca, 'XLabel'), 'String', '天数');
ylabel('人数')% set(get(gca, 'YLabel'), 'String', '人数');
legend('易感人群', '潜伏期患者', '感染者', '康复者','实际感染人数','误差线')

