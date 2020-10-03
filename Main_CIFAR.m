function [results] = Main_CIFAR()
% clc; 
close all;  
dbstop if error

addpath mex

styles = {'b-d','r-d','y-d','k-d','m-d','g-d','c-d'};

dbname = 'CIFAR';
opt.step = 40; 
maxiter = 5;
range = 100; %r = 24*1;
bitrange = [16, 32, 64, 128, 256];
% bitrange = [16, 32, 64];

methods = {'ITQ', 'PCA', 'LSH', 'SH', 'ITQ-SS', 'PCA-SS'};
% methods = {'ITQ-SS', 'PCA-SS'};

results = containers.Map;

load('cifar_split.mat');
% traindata = traindata(1:25:end, :);

for mi = 1:length(methods),
    result = []; k = 0;
    
    disp(methods{mi});
    for r = bitrange,
        for iter=1:maxiter,
            [Y, tY, tt1(iter)] = func_Hash(methods{mi}, traindata, testdata, r, opt);
            
            %%%% Hamming ranking evaluation
            [PR(:,:,iter), Precision(iter), mAP(iter)]=eval_HammingRanking(Y, tY, traingnd, testgnd, range);

            %%%% Hamming Radius 2 Hash Lookup
            Y(Y<=0)=0;  tY(tY<=0)=0;
            [HR2_Precision(iter), success(iter)]=eval_HammingRadius2HashLookup(Y, tY, traingnd, testgnd, range);
        end
        
        PR=mean(PR, 3); mAP=mean(mAP); Precision=mean(Precision); tt1=mean(tt1); HR2_Precision = mean(HR2_Precision); success = mean(success);
        
        k = k + 1;
        result(k).r = r; 
        result(k).maxiter = maxiter;
        result(k).PR=PR; result(k).mAP=mAP; result(k).Precision=Precision; result(k).tt1=mean(tt1); result(k).HR2_Precision = HR2_Precision; result(k).success = success;
        
        fprintf('mAP=%f; Precision=%f; time=%f (%s %d bit) \n', mAP, Precision, tt1, methods{mi}, r);
        fprintf('HR2_Precision=%f; success=%f (%s %d bit) \n', HR2_Precision, success, methods{mi}, r);
        
        figure(k); hold on;
        plot(PR(1:end,1),PR(1:end,2), styles{mi}, 'linewidth', 3); 
        xlabel('Recall'); ylabel('Precision');
        legend(methods)
        grid;
        set(gca,'FontSize',12);
        set(findall(gcf,'type','text'),'FontSize',14,'fontWeight','bold')
    end
    results(methods{mi}) = result;
end

%***** Save result
outdir = fullfile('output', dbname);
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
save(fullfile(outdir, 'result.mat'), 'results');


