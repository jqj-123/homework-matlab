# matlab-homework
<p>matlab/作业/现学现卖GUI，冗余的代码，逃~</p>
<p>可以生成exe,大概6Mb,不过开源性不好，就不上传release了</p>
<h3> 首先感谢两位B站up</h3>
<p>1.思路来源参考：https://www.bilibili.com/video/BV1j7411z7KQ?from=search&seid=10391321658210734361</p>
<p>2.部分代码参考：https://www.bilibili.com/video/BV1u7411W7dF?from=search&seid=254432281824175386</p>
<h3> 代码说明</h3>
<p>1、本系统代码环境 Matlab 2017b 中文版</p>
<p>2、本系统实现1、快速仿真2、动态仿真3、数据观察4、疫情演示四大功能；</p>
<p>3、为简化代码阅读难度，以下为仿真核心代码（仿真无GUI版）代码长度64行</p>
<p>clear; clc;</p>
<h5>% ----------疫情本地数据读取----------</h5>
<p>try<br> 
    [data ,~, ~] = xlsread('.\data\湖北省新冠状肺炎数据.xls');<br> 
    Tstart =1; Tend =100; data(isnan(data))=0;<br> 
    pat_infected = data(Tstart:Tend,2);<br> 
    pat_died = data(Tstart:Tend,4);<br> 
    pat_recover = data(Tstart:Tend,5);<br> 
catch<br> 
    disp('Excel com内核占用，请关闭excel\解除com占用并且重启Matlab')<br> 
    return<br> 
end<br> 
</p>

<h5>% ----------数据拟合获取r参数----------</h5>
<p>
[xData, yData] = prepareCurveData( pat_infected, pat_recover );<br> 
ft = fittype( 'poly1' );<br> 
[fitresult, ~] = fit( xData, yData, ft);<br> 
r = fitresult.p1;     %拟合获得的患者康复的概率<br> 
</p>
% ----------数据拟合获取d参数----------
[xData, yData] = prepareCurveData( pat_infected, pat_died );
ft = fittype( 'poly1' );
[fitresult, ~] = fit( xData, yData, ft);
d = fitresult.p1;     %拟合获得的患者死亡的概率
</p>
<h5>% ----------仿真参数设置和初始化状态----------</h5>
<p>
S = 50e4;                    % S:易感人群人数 <br> 
E = 111;                         % E:潜伏期患者<br> 
I = 270;                              % I:感染者<br> 
R = 25;                              % R:康复者<br> <br> 
N = S + E + I + R;                  % N:总人数<br> 

r1 = 10;             % 潜伏期患者每天接触到的人<br> 
r2 = 10;                  %感染者每天接触到的人<br> 
p1 = 0.05;      % p1:潜伏期患者接触后感染的概率<br> 
p2 = 0.05;          % p2:感染者接触后感染的概率<br> 
a = 0.07;      % a:1/14潜伏期患者出现症状的概率<br> 
% r = 0.1;                      %患者康复的概率<br> 
% d = 0.1;                      %患者死亡的概率<br> 
</p>

<h5>% ----------根据模型进行预测----------</h5>
<p>
Days = 100;<br> 
for k = 1:Days<br> 
    S(k + 1) = S(k) - (r1 * p1 * E(k) * (S(k) / N) + r2 * p2 * I(k) * (S(k) / N));<br> 
    E(k + 1) = E(k) + (r1 * p1 * E(k) * (S(k) / N) + r2 * p2 * I(k) * (S(k) / N)) - (E(k) * a);<br> 
    I(k + 1) = I(k) + (E(k) * a) - (I(k) * r + I(k) * d);<br> 
    R(k + 1) = R(k) + I(k) * r;<br> 
    N = S(k + 1) + E(k + 1) + I(k + 1) + R(k + 1);<br> 
end<br> 
</p>

<h5>% ----------画出模型的预测结果----------</h5>
<p>
x = 1:Days + 1;<br> 
plot(x, S, x, E,'-o', x, I,'-*', x, R);hold on;<br> 
true_patient = data(:,2) -data(:,4)-data(:,5);<br> 
plot(x,true_patient(1:length(x)),'-.');<br> 
% ----------误差线评估----------<br> 
error = 0.5*(true_patient(1:length(I))-I');<br> 
errorbar(x,I,error,'k');hold off<br> 
grid on<br> 
xlabel('天数')% set(get(gca, 'XLabel'), 'String', '天数');<br> 
ylabel('人数')% set(get(gca, 'YLabel'), 'String', '人数');<br> 
legend('易感人群', '潜伏期患者', '感染者', '康复者','实际感染人数','误差线')<br> 
</p>
