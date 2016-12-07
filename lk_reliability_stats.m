function [] = variance(cfg,AUC,dim)

%Make array of data into two dimensions in order to run ANOVA easily
n=1;
%Fird row is y values
cAUC = zeros(5,size(AUC,1)*size(AUC,2)*size(AUC,3)*size(AUC,4))
%Following rows are the factors
cAUC(1,:)=reshape(AUC(:,:,:,:,1),[1,size(AUC,1)*size(AUC,2)*size(AUC,3)*size(AUC,4)])
for l=1:size(AUC,4)
    for k=1:size(AUC,3)
        for j=1:size(AUC,2)
            for  i=1:size(AUC,1)
                cAUC(2,n)=i;
                cAUC(3,n)=j;
                cAUC(4,n)=k;
                cAUC(5,n)=l;
                n=n+1;
            end
        end
    end
end

%Now run ANOVA
[p,tbl,stats]= anovan(cAUC(1,:),{cAUC(2,:),cAUC(3,:),cAUC(4,:),cAUC(5,:)},'varnames',{'Split','Cond','Day','Sub'})




%Fill an array with the sum of squares, Smallest detectable change,
%variability, and ICC
SEM = zeros(4,1);
SDC = zeros(4,1);
variability = zeros(5,1);
variability(5) = cell2mat(tbl(6,5));
tbl2 = tbl(2:size(tbl,1),2:size(tbl,2));

SEM(dim) = (cell2mat(tbl2(dim,4))+cell2mat(tbl2(5,4)))^0.5;
SDC(dim) = SEM(dim)*(2)^0.5*1.96;
variability(dim) = (cell2mat(tbl2(dim,4))-cell2mat(tbl2(5,4)))/size(AUC,dim);
ICC(dim) = cell2mat(tbl2(dim,4))/sum(cell2mat(tbl2(:,4)));
disp([ 'The SEM for dimension ' num2str(dim) ' is ' num2str(SEM(dim))]);
disp([ 'The ICC for dimension ' num2str(dim) ' is ' num2str(ICC(dim))]);
%Note: For INTRACLASS correlation, the class is the dimension in question.
%So a high ICC for say varabile 1 (split) means that the first half is
%significantly different from the second half, which is NOT what we want.


end
