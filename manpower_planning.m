clc;clear all

years = {'0' '1' '2'};
skill_levels = {'Unskilled'  'Semiskilled'  'Skilled'};  % 0 = Unskilled, 1 = Semiskilled, 2 = Skilled
Unskilled = 0;
Semiskilled = 1;
Skilled = 2;

CurrentStrength = [2000, 1500, 1000];
Requirement = [...
    1000 1400 1000
    500  2000 1500
    0    2500 2000];

LeaveFirstYear = [0.25, 0.20, 0.10]; %Saem no primeiro ano
LeaveEachYear = [0.10, 0.05, 0.05]; %saem por ano
ContinueFirstYear = ones(1,length(years))-LeaveFirstYear;
ContinueEachYear = ones(1,length(years))-LeaveEachYear;
LeaveDownGraded = 0.50; %saido dos que rebaixarao
ContinueDownGraded = 1 - LeaveDownGraded;
MaxRecruit = [500, 800, 500];
MaxRetrainUnskilled = 200; %200 podem Unskilled -> Semiskilled
MaxOverManning = 150; %pode-se contratar 150 funcionarios a mais
MaxShortTimeWorking = 50;%50 funcionarios de cada categoria podem trabalhar meio periodo
RetrainSemiSkilled = 0.25;%conversao do semi -> skilled
ShortTimeUsage = 0.50; %short time = metade do tempo total

RetrainCost = [400, 500, 0];
RedundantCost = [200, 500, 500];%custo para manter a redundacia
ShortTimeCost = [500, 400, 400]; %custo pelo meio periodo
OverManningCost = [1500, 2000, 3000]; %preco pela contratacao dos 150 funcionarios a mais


%%variable
Recruit = optimvar('Recruit',skill_levels,years,'LowerBound',0,...
    'UpperBound',[MaxRecruit;MaxRecruit;MaxRecruit],'Type','integer');
ShortTime = optimvar('ShortTime',skill_levels,years,'LowerBound',0,...
    'UpperBound',MaxShortTimeWorking,'Type','integer');
LaborForce  = optimvar('LaborForce ',skill_levels,years,'LowerBound',0,'Type','integer')
Redundant = optimvar('Redundant',skill_levels,years,'LowerBound',0,'Type','integer');
OverManned = optimvar('OverManned',skill_levels,years,'LowerBound',0,'Type','integer','Type','integer');
Retrain  = optimvar('Retrain',skill_levels,skill_levels,years,'LowerBound',0,'Type','integer');

%%CONSTRAINTS
cont = [];
cond = [];
for year=1:1:length(years)
    a = 0;
    for level=1:1:length(skill_levels)
        sum1 = 0;
        sum2 = 0;
        for level2=1:1:length(skill_levels)
            if level2 < level
                sum1 = sum1 + Retrain(skill_levels(level),skill_levels(level2),years(year))-ContinueEachYear(level)*Retrain(skill_levels(level2),skill_levels(level),years(year));
            else
                sum1 = sum1 +  0;
            end
            if level2 > level
                sum2 = sum2 +  Retrain(skill_levels(level),skill_levels(level2),years(year)) -.5 * Retrain(skill_levels(level2),skill_levels(level),years(year));
            else
                sum2 = sum2 +  0;
            end
        end
        a = LaborForce(skill_levels(level),years(year)) + Redundant(skill_levels(level),years(year)) - ...
            ContinueFirstYear(level)*Recruit(skill_levels(level),years(year))+ ...
            sum1+sum2;
        cont = [cont;a];
        if year == 1
            cond = [cond;ContinueEachYear(level)*CurrentStrength(level)];
        else
            cond = [cond;ContinueEachYear(level)*LaborForce(skill_levels(level),years(year-1))];
        end
    end
end

Continuity = cont == cond;

RetrainMaxUnskilled = Retrain('Unskilled','Semiskilled',years) <= MaxRetrainUnskilled ;%limita a capacitacao Un->Semi
ForbidRetrainUnskilledToSkilled = Retrain('Unskilled','Skilled',years) <= 0; %impede de pular de Uns para skilled


RetrainingSemiSkilled = squeeze(Retrain('Semiskilled', 'Skilled',years)) <= RetrainSemiSkilled * LaborForce('Skilled', years)';

Overmanning = sum(OverManned(:,years)) <= MaxOverManning; %limitacao dos funcionarios sobressalentes 

Requirements = LaborForce == Requirement'+OverManned +ShortTimeUsage*ShortTime;

%%OBJECTIVE
% objective = 0;
% for year=1:1:length(years)
%     for level=1:1:length(skill_levels)
%         if level < 3
%             aux = Retrain(skill_levels(level),skill_levels(level+1),years(year));
%         else
%             aux = 0;
%         end
%         objective = objective + RetrainCost(level)*aux + RedundantCost(level)*Redundant(skill_levels(level),years(year))...
%             +ShortTimeCost(level)*ShortTime(skill_levels(level),years(year)) + OverManningCost(level)*OverManned(skill_levels(level),years(year));
%     end
% end


prob = optimproblem('ObjectiveSense', 'minimize');
% prob.Objective = objective;
prob.Objective = sum(sum(Redundant));

prob.Constraints.Continuity = Continuity;
prob.Constraints.RetrainMaxUnskilled = RetrainMaxUnskilled;
prob.Constraints.ForbidRetrainUnskilledToSkilled = ForbidRetrainUnskilledToSkilled;
prob.Constraints.RetrainingSemiSkilled = RetrainingSemiSkilled;
prob.Constraints.Overmanning = Overmanning;
prob.Constraints.Requirements = Requirements;

opts = optimoptions('intlinprog','Heuristics','none','Display','iter');
[sol1,fval1,exitstatus1,output1] = solve(prob,'options',opts)

