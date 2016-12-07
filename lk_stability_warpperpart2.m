%% WRAPPER FOR STABILITY CODE (meant to be run after data loaded via LK_stability_wrapper)
% EDITED 11/02

[cfg] = spTMS_start()

%%
%%Sets up size of fake data array
numSplit = 2;
numCond = 2;
numDays = 2;
numSubjects = 10;
numTEPcomp = 4;

clear AUC

% FAKE DATA (uniformly distributed)
AUC = rand(numSplit, numCond, numDays, numSubjects, numTEPcomp);


% FAKE DATA with a particular dimesion selected to explain most of variance
% (Alternative to line above)
for i=1:numSubjects
    AUC(:,:,:,i,:) = rand(numSplit, numCond, numDays, numTEPcomp)*i;
end

AUC = stability(cfg,data)



%%
%This is where call an independent function to run analysis on AUC
%for given dimension (dim)
%lk_reliability_stats(cfg,AUC,4)

%%
%Alternatively, I have the whole function below:

%Define a new array cAUC that will hold the concatenated data
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

for i=1:4
    SEM(i) = (cell2mat(tbl2(i,4))+cell2mat(tbl2(4,4)))^0.5;
    SDC(i) = SEM(i)*(2)^0.5*1.96;
    variability(i) = (cell2mat(tbl2(i,4))-cell2mat(tbl2(5,4)))/size(AUC,i);
    ICC(i) = cell2mat(tbl2(i,4))/sum(cell2mat(tbl2(:,4)));
    disp([ 'The SEM for dimension ' num2str(i) ' is ' num2str(SEM(i))]);
    disp([ 'The ICC for dimension ' num2str(i) ' is ' num2str(ICC(i))]);

end

%Note: For INTRACLASS correlation, the class is the dimension in question.
%So a high ICC for say varabile 1 (split) means that the first half is
%significantly different from the second half, which is NOT what we want.

%%
%all below is scratchpaper

%%Set up Sum of Squares
TEPcomp = 1; % designates which peak we are focusing on
for var_dim = 1:3 %pick different dimensions across whcih to measure variance
    for temp=1:2 %assigns the deminsions across which we will average during this measurement of variance
        disp(['Split number: ' num2str(var_dim) ' temp: ' num2str(temp)])
           
        if var_dim ~= temp; 
            com_dim(temp)=temp;
            temp=temp+1;
        else
           com_dim(temp)=temp+1;
           temp=temp+2;
        end
    end
        
    clear i; clear j;
    for i=1:size(AUC,com_dim(1))%Adds up sum of squares
        for j=1:size(AUC,com_dim(2))
           Anova(var_dim).ss
       
        Anova(dim,1)= Sum(
    end

    
    

    end
