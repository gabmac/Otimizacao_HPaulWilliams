clc;clear all

products = {'Prod1', 'Prod2', 'Prod3', 'Prod4', 'Prod5', 'Prod6', 'Prod7'};
machines = {'grinder', 'vertDrill', 'horiDrill', 'borer', 'planer'};
time_periods = {'January', 'February', 'March', 'April', 'May', 'June'};

profit_contribution = [10,6,8,4,11,9,3];

time_table = [...
    .5 .7 0 0 .3 .2 .5 %grinder
    .1 .2 0 .3 0 .6 0 %vertDirll
    .2 0 .8 0 0 0 0.6 %horiDrill
    .05 .03 0 .07 .1 0 .08 %borer
     0 0 .01 0 .05 0 .05%planner
    ]; %ferramenta x produto

down = [...
    1 0 0 0 0
    0 0 2 0 0
    0 0 0 1 0
    0 1 0 0 0
    1 1 0 0 0
    0 0 1 0 1];%mes x ferramenta, ferramentas em manutencao

qMachines = [4 2 3 1 1];%quantidade de cada maquina a disposicao

qMaintenance = [2 2 3 1 1];%apenas 2 grinders precisam ficar em manutencao

upper = [...
500 1000 300 300 800 200 100
600 500 200 0 400 300 150
300 600 0 0 500 400 100
200 300 400 500 200 0 100
0 100 500 100 1000 300 0
500 500 100 300 1100 500 60]; %limitacao do mercado


storeCost = 0.5;
storeCapacity = 100;
endStock = 50;
hoursPerMonth = 2*8*24;


manu = optimvar('Manu',time_periods,products,'LowerBound',0); %quantidade manufaturada
held = optimvar('Held',time_periods,products,'LowerBound',0,'UpperBound',storeCapacity);%quantidade estocada
sell = optimvar('Sell',time_periods,products,'LowerBound',0,'UpperBound',upper);%quantidade vendida
d = optimvar('d', time_periods, machines, 'Type', 'integer','LowerBound',0);%numero de maquinas em manutencao


%%CONSTRAINTS
initialBalance = manu(1, :) == sell(1, :) + held(1, :); %sem etoque inicial, o que foi manufaturado ou foi vendido ou estocado
Balance = held(1:5, :) + manu(2:6, :) == sell(2:6, :) + held(2:6, :) % o estocado + o manufaturado = vendido + manufaturado

held('June', :).LowerBound = endStock;
held('June', :).UpperBound = endStock; %e necessario que ao fim exista um certo estoque


gastoProd = []; %gasto por produto no mes
tempo = []
for i=1:1:length(time_periods)
    gastoProd = [gastoProd sum(time_table.*repmat(manu(time_periods(i),:),5,1),2)];
    tempo = [tempo hoursPerMonth * [qMachines-d(time_periods(i),:)]' ];
end
capacity = gastoProd <=tempo; %tempo gasto por mes em cada ferramenta

maintenance = sum(d) == qMaintenance;


%%OBJECTIVE
prob = optimproblem('ObjectiveSense', 'maximize');
prob.Objective = sum(sum(repmat(profit_contribution,6,1).*sell - storeCost*held));

prob.Constraints.initialBalance = initialBalance;
prob.Constraints.Balance = Balance;
prob.Constraints.capacity = capacity;
prob.Constraints.maintenance = maintenance;
%prob.Constraints.up = up;

opts = optimoptions('intlinprog','Heuristics','none');
[sol1,fval1,exitstatus1,output1] = solve(prob,'options',opts)


