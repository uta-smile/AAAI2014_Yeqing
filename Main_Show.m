function Main_Show()
clc;clear;close all

styles = {'b-d','r-d','y-d','k-d','m-d','g-d','c-d'};

% dbname = 'MNIST';
dbname = 'CIFAR';
fn = fullfile('output', dbname, 'result.mat');
load(fn);

methods = results.keys();

for mi = 1:length(methods),
    result = results(methods{mi});
    bits = [];
    mAPs = [];
    Pres = [];
    times = [];
    for k = 1:length(result),
        res = result(k);
        fields = fieldnames(res);
        for i = 1:length(fields),
            eval([fields{i} ' = res.' fields{i} ';'])
        end
        if exist('mAP1', 'var'), mAP = mAP1; end
        fprintf('mAP=%f; Precision=%f; time=%f (%s %d bit) \n', mAP, Precision, tt1, methods{mi}, r);
        fprintf('HR2_Precision=%f; success=%f (%s %d bit) \n', HR2_Precision, success, methods{mi}, r);
        
        bits = [bits, r];
        mAPs = [mAPs, mAP];
        Pres = [Pres, Precision];
        times = [times, tt1];
        
        % Precision-Recall plot
        figure(k); hold on;
        xlabel('Recall'); ylabel('Precision');
        plotCurve(PR(1:end,1),PR(1:end,2), styles{mi});
        legend(methods)
    end
    X = 1:numel(bits);
    % mAP plot
    figure(10); hold on;
    xlabel('Number of Bits'); ylabel('mAP');
    plotCurve(X, mAPs, styles{mi}, true, bits);
    legend(methods) 
    
    % Precision plot
    figure(11); hold on;
    xlabel('Number of Bits'); ylabel('Precision');
    plotCurve(X, Pres, styles{mi}, true, bits);
    legend(methods) 
    
    % Running time plot
    figure(12); hold on;
    xlabel('Number of Bits'); ylabel('Training Time (seconds)');
    plotCurve(X, times, styles{mi}, true, bits);
    legend(methods) 
end

function plotCurve(X, Y, sty, setticks, bits)

if ~exist('setticks', 'var'),
    setticks = false;
end

plot(X, Y, sty, 'linewidth', 3); 
grid off;
box on;
set(gca,'FontSize',12);
set(findall(gcf,'type','text'),'FontSize',14,'fontWeight','bold')

if setticks,
    set(gca,'XTick', 1:numel(bits))
    set(gca,'XTickLabel', strread(num2str(bits),'%s'))
end
