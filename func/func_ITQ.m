function [ROC, mAP, Precision, tt0, HR2_Precision, success]=func_ITQ(traindata, testdata, traingnd, testgnd, tn, r, range)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% data_{n x d} = [traindata; testdata]; gnd=[traingnd; testgnd];
%%%% tn: the number of test data
%%%% r: the bit number
%%%% range: how many neighbors to check?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;

%%%%%%%%%%%%%% training
[n,d] = size(traindata);
mvec = mean(traindata,1);
% traindata = traindata-repmat(mvec,n,1);
traindata = bsxfun(@minus, traindata, mvec);
cov = traindata'*traindata;
[U,V] = eig(cov); clear cov;
eigenvalue = diag(V)'; clear V;
[eigenvalue,order] = sort(eigenvalue,'descend'); clear eigenvalue;
W = U(:,order(1:r)); clear U; clear order;

Y = traindata*W;
[Y, R] = ITQ(Y, 50); clear temp traindata;

% Y = Y*R; Y = (Y>0);
% B = compactbit(Y);
% Y = single(Y); tep = find(Y<=0); Y(tep) = -1; clear tep;

W = W*R;

%% testing
testdata = testdata-repmat(mvec,tn,1);
tY = testdata*W; 
% tY = single(tY>0);
% tep = find(tY<=0); tY(tep) = -1;
tY = mexsign(tY);
clear tep testdata;

tt0=toc;

%%%% Hamming ranking evaluation
[ROC, Precision, mAP]=eval_HammingRanking(Y, tY, traingnd, testgnd, range);

%%%% Hamming Radius 2 Hash Lookup
Y(Y<=0)=0;  tY(tY<=0)=0;
[HR2_Precision, success]=eval_HammingRadius2HashLookup(Y, tY, traingnd, testgnd, range);

%savetomat(Y, tY, traindata, testdata, traingnd, testgnd)

return


function savetomat(trainHash, testHash, traindata, testdata, traingnd, testgnd)

disp('Save mnist hash code');

save mnist_hash trainHash testHash traindata testdata traingnd testgnd
