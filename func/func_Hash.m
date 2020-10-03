% function [ROC, mAP, Precision, tt0, HR2_Precision, success]=func_Hash(method, traindata, testdata, traingnd, testgnd, r, opt)
function [Y, tY, tt0, W]=func_Hash(method, traindata, testdata, r, opt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% method: hash algorithm
%%%% data_{n x d} = [traindata; testdata]; gnd=[traingnd; testgnd];
%%%% tn: the number of test data
%%%% r: the bit number
%%%% opt.range: how many neighbors to check?
%%%% opt.step: sample ratio for sub-selective version of hash algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic;
[dim1, dim2] = size(traindata);
if dim1 < dim2
    testdata=testdata';
    traindata=traindata';
end
toc

tic;

if ~exist('opt', 'var'),
    opt = [];
end

% range = opt.range;

%%%%%%%%%%%%%% training
[n,d] = size(traindata);
mvec = mean(traindata,1);
% traindata = traindata-repmat(mvec,n,1);
traindata = bsxfun(@minus, traindata, mvec);

switch(method) 
    case 'ITQ'
        % PCA
        cov = traindata'*traindata;
        [U,V] = eig(cov); clear cov;
        eigenvalue = diag(V)'; clear V;
        [eigenvalue,order] = sort(eigenvalue,'descend'); clear eigenvalue;
        W = U(:,order(1:r)); clear U; clear order;

        Y = traindata*W;
        [Y, R] = ITQ(Y, 50); clear temp traindata;

        W = W*R;
    case 'PCA'
        cov = traindata'*traindata;

        [U,V] = eig(cov); clear cov;
        eigenvalue = diag(V)'; clear V;
        [eigenvalue,order] = sort(eigenvalue,'descend'); clear eigenvalue;
        W = U(:,order(1:r)); clear U; clear order;

        Y = traindata*W;
        Y = mexsign(Y);
    case 'LSH'
        W = randn(d, r);

        V = traindata*W; clear temp traindata;
        Y = mexsign(V); 
    case 'SH'
        SHparam.nbits = r; % number of bits to code each sample

        % training
        SHparam = trainSH(traindata, SHparam);
        
        % compress training and test set
        [~, Y] = compressSH(traindata, SHparam);
        Y = mexsign(Y);
        W = SHparam;
    case 'ITQ-SS'
        step = opt.step;
        rnum=1:step:n;
        sub = traindata(rnum, :);
        cov = sub'*sub;

        [U,V] = eig(cov); clear cov;
        eigenvalue = diag(V)'; clear V;
        [eigenvalue,order] = sort(eigenvalue,'descend'); clear eigenvalue;
        W = U(:,order(1:r)); clear U; clear order;

        Y = traindata*W;
        [Y, R] = ITQSS(Y, 50, step); clear temp traindata;

        W = W*R;
    case 'PCA-SS'
        step = opt.step;
        rnum=1:step:n;
        sub = traindata(rnum, :);
        cov = sub'*sub;

        [U,V] = eig(cov); clear cov;
        eigenvalue = diag(V)'; clear V;
        [eigenvalue,order] = sort(eigenvalue,'descend'); clear eigenvalue;
        W = U(:,order(1:r)); clear U; clear order;

        Y = traindata*W;
        Y = mexsign(Y);
    case 'SKLSH'
        RFparam.gamma = 1;
        RFparam.D = d;
        RFparam.M = r;
        RFparam = RF_train(RFparam);
        [~, Y] = RF_compress(traindata, RFparam);
        W = RFparam;
    otherwise
        error('Unknown method');
end

%% testing
if strcmpi(method, 'SH'),
    [~,tY] = compressSH(testdata, SHparam);
elseif strcmp(method, 'SKLSH'),
    testdata = testdata-repmat(mvec,tn,1);
    [~, tY] = RF_compress(testdata, RFparam);
else
    tn = size(testdata, 1);
    testdata = testdata-repmat(mvec,tn,1);
    tY = testdata*W; 
end
tY = mexsign(tY);
clear tep testdata;

tt0=toc;

%savetomat(Y, tY, traindata, testdata, traingnd, testgnd)

return


function savetomat(trainHash, testHash, traindata, testdata, traingnd, testgnd)

disp('Save mnist hash code');

save mnist_hash trainHash testHash traindata testdata traingnd testgnd
