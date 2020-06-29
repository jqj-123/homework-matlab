% --------------------生成GUI必要代码--------------------
function varargout = illsimulation(varargin)
    gui_Singleton = 1;
    gui_State = struct('gui_Name', mfilename, ...
        'gui_Singleton', gui_Singleton, ...
        'gui_OpeningFcn', @illsimulation_OpeningFcn, ...
        'gui_OutputFcn', @illsimulation_OutputFcn, ...
        'gui_LayoutFcn', [], ...
        'gui_Callback', []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
function varargout = illsimulation_OutputFcn(~, ~, handles) 
    varargout{1} = handles.output;

% --------------------GUI窗口初始化设置--------------------
% --- Executes just before illsimulation is made visible.
function illsimulation_OpeningFcn(hObject, ~, handles, varargin)
    set(handles.radio_static, 'value', 1);
    set(handles.panel_static, 'Visible', 'on');
    set(handles.panel_dynamic, 'Visible', 'off');
    set(handles.panel_excel, 'Visible', 'off');
    set(handles.panel_ppt, 'Visible', 'off');
    handles.output = hObject;
    guidata(hObject, handles);


% -------------------------!GUI选择读取数据文件!-------------------------%
% --- Executes on button press in Button_handdata.
function Button_handdata_Callback(hObject, ~, handles)
    [Filename, Pathname] = uigetfile({'*.xls';'All Files(*.*)'},'Choose a file');
    L = length(Filename);
    if L<5
        errordlg('Wrong File','File open error')
        return
    end
    filetype = Filename(1,L-3:L);
    switch filetype
        case '.xls'
        try
            str = [ Pathname Filename];
            set(handles.fileshow,'string',str);
            h = waitbar(0,'请稍等，正在开始读取文件…');
            [data ,~, ~] = xlsread(str);
            pause(0.5);
            waitbar(1,h,'文件读取已完成');
            assignin('base', 'data', data);
            handles.data = data;    
            Tstart =1; Tend =56; data(isnan(data))=0;
            handles.pat_infected = data(Tstart:Tend,2);
            handles.pat_died = data(Tstart:Tend,4);
            handles.pat_recover = data(Tstart:Tend,5);
            handles.data = data;
            handles.true_patient = data(:,2) -data(:,4)-data(:,5);
            guidata(hObject,handles); 
            waitbar(1,h,'数据导入已完成');
            delete(h);
        catch
            disp('Excel com内核占用，请关闭excel\解除com占用并且重启Matlab')
            return
        end
        otherwise
            errordlg('Wrong File','File open error')
            return
    end
    
% -------------------------!功能1：快速仿真画图!-------------------------%
% --- Executes on button press in Button_update.
function Button_update_Callback(hObject, ~, handles)
    % ----------数据拟合获取r参数----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_recover);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    r = fitresult.p1; %拟合获得的患者康复的概率

    % ----------数据拟合获取d参数----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_died);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    d = fitresult.p1; %拟合获得的患者死亡的概率

    % ----------仿真参数设置和初始化状态----------
    S = 50e4; % S:易感人群人数
    E = 111; % E:潜伏期患者
    I = 270; % I:感染者
    R = 25; % R:康复者
    N = S + E + I + R; % N:总人数

    r1 = 10; % 潜伏期患者每天接触到的人
    r2 = 10; %感染者每天接触到的人
    p1 = 0.05; % p1:潜伏期患者接触后感染的概率
    p2 = 0.05; % p2:感染者接触后感染的概率
    a = 0.07; % a:1/14潜伏期患者出现症状的概率

    % ----------仿真参数动态设置----------
    axes(handles.axes_main); cla;
    Menus = [handles.Menu_r1, handles.Menu_r2]; dyparams = [r1, r2];
    for k = 1:2
        index = get(Menus(k), 'Value');
        switch index
            case 2
                dyparams(k) = 30;
            case 3
                dyparams(k) = 20;
            case 4
                dyparams(k) = 10;
            case 5
                dyparams(k) = 5;
            case 6
                dyparams(k) = 0;
        end
    end
    r1 = dyparams(1); r2 = dyparams(2);
    Menus = [handles.Menu_p1, handles.Menu_p2]; dyparams = [p1, p2];
    for k = 1:2
        index = get(Menus(k), 'Value');
        switch index
            case 2
                dyparams(k) = 0.15;
            case 3
                dyparams(k) = 0.05;
            case 4
                dyparams(k) = 0.005;
        end
    end
    p1 = dyparams(1); p2 = dyparams(2);
    % ----------根据模型进行预测----------
    Days = 100;
    for k = 1:Days
        S(k + 1) = S(k) - (r1 * p1 * E(k) * (S(k) / N(k)) + r2 * p2 * I(k) * (S(k) / N(k)));
        E(k + 1) = E(k) + (r1 * p1 * E(k) * (S(k) / N(k)) + r2 * p2 * I(k) * (S(k) / N(k))) - (E(k) * a);
        I(k + 1) = I(k) + (E(k) * a) - (I(k) * r + I(k) * d);
        R(k + 1) = R(k) + I(k) * r;
        N(k + 1) = S(k + 1) + E(k + 1) + I(k + 1) + R(k + 1);
    end

    % ----------画出模型的预测结果----------
    x = 1:Days + 1;
    plot(x, S, x, E, '-o', x, I, '-*', x, R); grid on
    xlabel('天数'); ylabel('人数')
    legend('易感者', '潜伏者', '感染者', '康复者')

    % ----------预测结果导出----------
    handles.XX = x;
    handles.SS = S;
    handles.II = I;
    handles.RR = R;
    handles.NN = N;
    guidata(hObject, handles)

% ----------误差线评估----------
function Button_error_Callback(~, ~, handles)
    axes(handles.axes_main); cla;
    x = handles.XX; I = handles.II; true_patient = handles.true_patient;
    error = 0.5 * (true_patient(1:length(I)) - I');
    plot(x, true_patient(1:length(I)), '-.'); hold on;
    plot(x, I, '-*');
    errorbar(x, I, error, 'k'); grid on; hold off;
    legend('实际感染人数', '仿真感染人数', '误差线')

    
% -------------------------!功能2：动态仿真画图!-------------------------%
% ----------代码与功能1相似，增加变量与动图显示，详见补充代码区----------
% -------------------------!功能3：Excel数据观察!-------------------------%
% --- Executes on selection change in Menu_excelpic.
function Menu_excelpic_Callback(~, ~, handles)
    axes(handles.Axes_excel)
    h2 = plot(handles.data(:, 2)); hold on; set(h2, 'Visible', 'off')
    h3 = plot(handles.data(:, 4)); set(h3, 'Visible', 'off')
    h4 = plot(handles.data(:, 5)); set(h4, 'Visible', 'off')
    h5 = plot(handles.data(:, 2) - handles.data(:, 4) - handles.data(:, 5)); set(h5, 'Visible', 'off')
    hold off; xlabel('天数'); ylabel('人数');
    index = get(handles.Menu_excelpic, 'Value');

    switch index
        case 2
            set(h2, 'Visible', 'on'); legend('累计确诊人数')
        case 3
            set(h3, 'Visible', 'on'); legend('累计死亡人数')
        case 4
            set(h4, 'Visible', 'on'); legend('累计康复人数')
        case 5
            set(h5, 'Visible', 'on'); legend('现存确诊人数')
        case 6
            set([h2, h3, h4, h5], 'Visible', 'on');
            legend('累计确诊人数', '累计死亡人数', '累计死亡人数', '现存确诊人数')
    end

    
% -------------------------!功能4：疫情可视化演示!-------------------------%
% --- Executes on selection change in Menu_ppt.
function Menu_ppt_Callback(~, ~, handles)
    axes(handles.Axes_ppt)
    index = get(handles.Menu_ppt, 'Value');
    h1 = scatter([], [], 'r', 'filled'); hold on; h2 = scatter([], [], 'g', 'filled');
    h3 = scatter([], []); hold off; h4 = text(50, 50, '', 'fontsize', 20, 'HorizontalAlignment', 'center');

    switch index
            case 2
            % ----------Excel数据疫情传播演示----------
            N = 50e4; I = handles.data(:, 2) - handles.data(:, 4) - handles.data(:, 5); R = handles.data(:, 5);
            maxindex = find(I == max(I)); Step = 10; Decline = N / 1000;

            for k = 1:Step:length(I)
                num = round(I(k) / Decline);
                X1 = 100 * rand(1, num); Y1 = 100 * rand(1, num);
                set(h1, 'XData', X1, 'YData', Y1')
                num = round(R(k) / Decline);
                X2 = 100 * rand(1, num); Y2 = 100 * rand(1, num);
                set(h2, 'XData', X2, 'YData', Y2);
                num = round((N - I(k) - R(k)) / Decline);
                X3 = 100 * rand(1, num); Y3 = 100 * rand(1, num);
                set(h3, 'XData', X3, 'YData', Y3)
                legend([h1, h2, h3], '现存感染者', '康复者', '易感者')
                if abs(k -maxindex) < floor(Step / 2) + 1
                    set(h4, 'String', '疫情高潮'); pause(1.5);
                    set(h4, 'String', '')
                end
                pause(0.5)
            end
            set(h4, 'String', '演示结束')
            case 3
            % ----------仿真数据疫情传播演示----------
            N = handles.NN; R = handles.RR; I = handles.II;
            maxindex = find(I == max(I)); Step = 10; Decline = max(N) / 1000;
            for k = 1:Step:length(I)
                num = round(I(k) / Decline);
                X1 = 100 * rand(1, num); Y1 = 100 * rand(1, num);
                set(h1, 'XData', X1, 'YData', Y1')
                num = round(R(k) / Decline);
                X2 = 100 * rand(1, num); Y2 = 100 * rand(1, num);
                set(h2, 'XData', X2, 'YData', Y2);
                num = round((N(k) - I(k) - R(k)) / Decline);
                X3 = 100 * rand(1, num); Y3 = 100 * rand(1, num);
                set(h3, 'XData', X3, 'YData', Y3)
                legend([h1, h2, h3], '现存感染者', '康复者', '易感者')
                if abs(k -maxindex) < floor(Step / 2) + 1
                    set(h4, 'String', '疫情高潮'); pause(1.5);
                    set(h4, 'String', '')
                end
                pause(0.5)
            end
            set(h4, 'String', '演示结束')
    end

% -------------------------!退出仿真系统!-------------------------%
function Button_exit_Callback(~, ~, ~)
    clc; clear; close(gcf);
% -------------------------!以上为系统核心代码区-------------------------%





% -------------------------!以下为系统补充代码区-------------------------%
% -------------------------!功能2：动态仿真画图!-------------------------%
function Button_dynamic_Callback(~, ~, handles)
    % ----------数据拟合获取r参数----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_recover);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    r = fitresult.p1; %拟合获得的患者康复的概率
    % ----------数据拟合获取d参数----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_died);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    d = fitresult.p1; %拟合获得的患者死亡的概率

    % ----------仿真参数设置和初始化状态----------
    S = 50e4; % S:易感人群人数
    E = 111; % E:潜伏期患者
    I = 270; % I:感染者
    R = 25; % R:康复者
    N = S + E + I + R; % N:总人数

    % ----------根据模型进行预测----------
    axes(handles.Axes_dynamic)
    h1 = plot(0, 0); hold on;
    h2 = plot(0, 0, '-o'); h3 = plot(0, 0, '-*'); h4 = plot([0], [0]); hold off; grid on
    h5 = title('');
    set(get(gca, 'XLabel'), 'String', '天数');
    set(get(gca, 'YLabel'), 'String', '人数');

    Days = 150; params = [10, 10, 0.05, 0.05];
    a = 0.07; % a:潜伏期患者出现症状的概率
    index = get(handles.Menuparams, 'Value');

    for temp = handles.valstart:handles.valstep:handles.valend
        params(index - 1) = temp;

        for k = 1:Days
            S(k + 1) = S(k) - (params(1) * params(3) * E(k) * (S(k) / N(k)) + params(2) * params(4) * I(k) * (S(k) / N(k)));
            E(k + 1) = E(k) + (params(1) * params(3) * E(k) * (S(k) / N(k)) + params(2) * params(4) * I(k) * (S(k) / N(k))) - (E(k) * a);
            I(k + 1) = I(k) + (E(k) * a) - (I(k) * r + I(k) * d);
            R(k + 1) = R(k) + I(k) * r;
            N(k + 1) = S(k + 1) + E(k + 1) + I(k + 1) + R(k + 1);
        end

        % ----------画出模型的预测结果----------
        x = 1:Days + 1;
        set(h1, 'XData', x, 'YData', S); set(h2, 'XData', x, 'YData', E);
        set(h3, 'XData', x, 'YData', I); set(h4, 'XData', x, 'YData', R);
        legend('易感者', '潜伏者', '感染者', '康复者'); set(h5, 'String', ['variable:', num2str(temp)]);
        pause(0.7)
    end

    
% -------------------------!GUI自动读取数据文件!-------------------------%
% --- Executes on button press in Button_autodata.
function Button_autodata_Callback(hObject, ~, handles)
    try
        set(handles.fileshow, 'string', '湖北省新冠状肺炎数据.xls');
        h = waitbar(0, '请稍等，正在开始读取文件…');
        [data, ~, ~] = xlsread('.\data\湖北省新冠状肺炎数据.xls');
        pause(0.5);
        waitbar(1, h, '文件读取已完成');
        assignin('base', 'data', data);
        handles.data = data;
        Tstart = 1; Tend = 56; data(isnan(data)) = 0;
        handles.pat_infected = data(Tstart:Tend, 2);
        handles.pat_died = data(Tstart:Tend, 4);
        handles.pat_recover = data(Tstart:Tend, 5);
        handles.true_patient = data(:, 2) -data(:, 4) - data(:, 5);
        waitbar(1, h, '数据导入已完成');
        guidata(hObject, handles);
        delete(h);
    catch
        disp('自动读取失败，请在同目录文件下放入数据文件->关闭excel/解除com占用->重启Matlab')
        return
    end


% -------------------------!以下为辅助显示控件-------------------------%
% ----------功能按钮组---------
function uibuttongroups_CreateFcn(~, ~, ~)
function uibuttongroups_SelectionChangedFcn(hObject, ~, handles)
    str = get(hObject, 'string'); %单引号和双引号不能共用
    H = [handles.panel_static, handles.panel_dynamic, handles.panel_excel, handles.panel_ppt];
    switch str
            case '快速仿真'
            index = 1;
            case '动态仿真'
            index = 2;
            case '数据作图'
            index = 3;
            case '疫情演示'
            index = 4;
    end
    for k = 1:4
        set(H(k), 'Visible', 'off')
        if k == index
            set(H(k), 'Visible', 'on')
        end
    end

% ----------设置快速仿真参量---------
function Button_update_CreateFcn(~, ~, ~)
    % --- Executes on button press in Button_defaultstatic.
function Button_defaultstatic_Callback(~, ~, handles)
    set(handles.Menu_r1, 'Value', 4);
    set(handles.Menu_r2, 'Value', 4);
    set(handles.Menu_p1, 'Value', 3);
    set(handles.Menu_p2, 'Value', 3); axes(handles.axes_main); cla;

function Menu_r1_Callback(~, ~, ~)
function Menu_r1_CreateFcn(hObject, ~, ~)

    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

    set(hObject, 'String', {'r1:潜伏者接触数/天', 'r1=30', 'r1=20', 'r1=10', 'r1=5', 'r1=0'});

function Menu_r2_Callback(~, ~, ~)
function Menu_r2_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'r2:感染者接触数/天', 'r2=30', 'r2=20', 'r2=10', 'r2=5', 'r2=0'});

function Menu_p1_Callback(~, ~, ~)
function Menu_p1_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'p1:潜伏者接触后发病率', 'p1=0.15', 'p1=0.05', 'p1=0.005'})

function Menu_p2_Callback(~, ~, ~)
function Menu_p2_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'p2:感染者接触后发病率', 'p2=0.15', 'p2=0.05', 'p2=0.005'});

function radio_dynamic_Callback(~, ~, ~)
function edit_step_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end


% ----------设置动态变化参量---------
function panel_dynamic_CreateFcn(~, ~, ~)
    % --- Executes on button press in Button_defaultdynamic.
function Button_defaultdynamic_Callback(hObject, ~, handles)
    set(handles.Menuparams, 'Value', 2);
    set(handles.editstart, 'String', 1); handles.valstart = 1;
    set(handles.editend, 'String', 10); handles.valend = 10;
    set(handles.editstep, 'String', 1); handles.valstep = 1;
    guidata(hObject, handles); axes(handles.Axes_dynamic); cla;

function Menuparams_Callback(~, ~, ~)
function Menuparams_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'选择动态测试的参数', 'r1', 'r2', 'p1', 'p2'});

function text_start_CreateFcn(~, ~, ~)
function text_end_CreateFcn(~, ~, ~)
function text_step_CreateFcn(~, ~, ~)

function editstart_Callback(hObject, ~, handles)
    str = get(hObject, 'String');
    handles.valstart = str2double(str);
    guidata(hObject, handles)

function editstart_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

function editend_Callback(hObject, ~, handles)
    str = get(hObject, 'String');
    handles.valend = str2double(str);
    guidata(hObject, handles);
function editend_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

function editstep_Callback(hObject, ~, handles)
    str = get(hObject, 'String');
    handles.valstep = str2double(str);
    guidata(hObject, handles);
function editstep_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

% ----------显示选择Excel数据---------
function Menu_excelpic_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'数据对象', '累计确诊人数', '累计死亡人数', '累计康复人数', '现存确诊人数', '全部显示'})

% ----------显示疫情动态可视化---------
function Menu_ppt_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', {'演示对象','现实疫情','仿真疫情(数据来源于快速仿真'})

% ----------文件读取可视化---------
function filemenu_Callback(~, ~, ~)
function fileshow_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% ----------简单的菜单功能区---------
function file_exit_Callback(~, ~, ~)
    clc;clear;close(gcf);
function helpmenu_Callback(~, ~, ~)
function readme_Callback(~, ~, ~)
