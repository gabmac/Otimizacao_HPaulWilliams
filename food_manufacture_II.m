clc;clear all

meses = {'Janeiro','Fevereiro','Marco','Abril','Maio','Junho'};
oleos = {'VEG1', 'VEG2', 'OIL1', 'OIL2', 'OIL3'};
vegoils = {'VEG1', 'VEG2'};
nonveg = {'OIL1', 'OIL2', 'OIL3'};
estoqueMaximo = 1000; % estoque maximo de cada oleo
maxUsoVeg = 200; % limite do uso de oleos vegetais
maxUsoNonVeg = 250; % limite de uso de oleos nao vegetais
precoVenda = 150; % preco de venda final de cada oleo
custoEstoque = 5; % custo do estoque
incioEstoque = 500; % estoque no inicio e no fim
minimoUsado = 20; % toneladas minimas de oleo usado por producao
maxOleos = 3; % quantidade maximade oleos usados em uma mistura
hmin = 3; % Minimum hardness of refined oil
hmax = 6; % Maximum hardness of refined oil
h = [8.8,6.1,2,4.2,5.0];
precoOleoMes = [...
110 120 130 110 115
130 130 110  90 115
110 140 130 100  95
120 110 120 120 125
100 120 150 110 105
 90 100 140  80 135]

usado = optimvar('usado', meses, oleos, 'LowerBound', 0);
compra = optimvar('compra', meses, oleos, 'LowerBound', 0);
estoque = optimvar('estoque', meses, oleos, 'LowerBound', 0, 'UpperBound', estoqueMaximo);

usadoBin = optimvar('usadoBin', meses, oleos, 'Type', 'integer', ...
    'LowerBound', 0, 'UpperBound', 1); %variavel binaria indicando quais oleos foram usados em cada mes



producao = sum(usado,2); %producao eh soma de  tudo que foi vendido/consumido


prob = optimproblem('ObjectiveSense', 'maximize');
prob.Objective = sum(precoVenda*producao) - sum(sum(precoOleoMes.*compra)) - sum(sum(custoEstoque*estoque));


estoque('Junho', :).LowerBound = 500;%em Junho tem que haver um estoque de 500 toneladas por oleo no mes
estoque('Junho', :).UpperBound = 500;


vegoiluse = usado(:, vegoils);%a soma do que foi refinado de oleo vegetal nao pode superar o limite
vegused = sum(vegoiluse, 2) <= maxUsoVeg;


nonvegoiluse = usado(:,nonveg);%a soma do que foi refinado de oleo nao vegetal nao pode superar o limite
nonvegused = sum(nonvegoiluse,2) <= maxUsoNonVeg;


hardmin = sum(repmat(h, 6, 1).*usado, 2) >= hmin*producao;
hardmax = sum(repmat(h, 6, 1).*usado, 2) <= hmax*producao;

estoqueIncial = 500 + compra(1, :) == usado(1, :) + estoque(1, :);%o que foi comprado + estocado no mes anterior
%tem que ser igual ao que foi usado + estocado no mes
estoqueAtual = estoque(1:5, :) + compra(2:6, :) == usado(2:6, :) + estoque(2:6, :);

minuse = usado >= minimoUsado*usadoBin;

maxusev = usado(:, vegoils) <= maxUsoVeg*usadoBin(:, vegoils);
maxusenv = usado(:, nonveg) <= maxUsoNonVeg*usadoBin(:, nonveg);

maxnuse = sum(usadoBin, 2) <= maxOleos;

deflogic1 = sum(usadoBin(:,vegoils), 2) <= usadoBin(:,'OIL3')*numel(vegoils);

prob.Constraints.vegused = vegused;
prob.Constraints.nonvegused = nonvegused;
prob.Constraints.hardmin = hardmin;
prob.Constraints.hardmax = hardmax;
prob.Constraints.initstockbal = estoqueIncial;
prob.Constraints.stockbal = estoqueAtual;
prob.Constraints.minuse = minuse;
prob.Constraints.maxusev = maxusev;
prob.Constraints.maxusenv = maxusenv;
prob.Constraints.maxnuse = maxnuse;
prob.Constraints.deflogic1 = deflogic1;


opts = optimoptions('intlinprog','Heuristics','none');
[sol1,fval1,exitstatus1,output1] = solve(prob,'options',opts)





