clear all;clc;

meses = {'Janeiro','Fevereiro','Marco','Abril','Maio','Junho'};
oleos = {'VEG1', 'VEG2', 'OIL1', 'OIL2', 'OIL3'};
vegoils = {'VEG1', 'VEG2'};
nonveg = {'OIL1', 'OIL2', 'OIL3'};
estoqueMaximo = 1000; % estoque maximo de cada oleo
maxUsoVeg = 200; % limite do uso de oleos vegetais
maxUsoNonVeg = 250; % limite de uso de oleos nao vegetaus
precoVenda = 150; % preco de venda final de cada oleo
custoEstoque = 5; % custo do estoque
incioEstoque = 500; % estoque no inicio e no fim
hmin = 3;
hmax = 6; 
h = [8.8,6.1,2,4.2,5.0];
precoOleoMes = [...
110 120 130 110 115
130 130 110  90 115
110 140 130 100  95
120 110 120 120 125
100 120 150 110 105
 90 100 140  80 135]; %custo dos oleos por mes

usado = optimvar('sell', meses, oleos, 'LowerBound', 0);
compra = optimvar('buy', meses, oleos, 'LowerBound', 0);
estoque = optimvar('store', meses, oleos, 'LowerBound', 0, 'UpperBound', estoqueMaximo);

producao = sum(usado,2); %producao eh soma de  tudo que foi vendido/consumido

prob = optimproblem('ObjectiveSense', 'maximize');
prob.Objective = sum(precoVenda*producao) - sum(sum(precoOleoMes.*compra)) - sum(sum(custoEstoque*estoque));

estoque('Junho', :).LowerBound = 500;
estoque('Junho', :).UpperBound = 500;

vegoiluse = usado(:, vegoils); %a soma do que foi refinado de oleo vegetal nao pode superar o limite
vegused = sum(vegoiluse, 2) <= maxUsoVeg;

nonvegoiluse = usado(:,nonveg);%a soma do que foi refinado de oleo nao vegetal nao pode superar o limite
nonvegused = sum(nonvegoiluse,2) <= maxUsoNonVeg


hardmin = sum(repmat(h, 6, 1).*usado, 2) >= hmin*producao; %hardness
hardmax = sum(repmat(h, 6, 1).*usado, 2) <= hmax*producao;

estoqueIncial = 500 + compra(1, :) == usado(1, :) + estoque(1, :); %o que foi comprado + estocado no mes anterior
%tem que ser igual ao que foi usado + estocado no mes
estoqueAtual = estoque(1:5, :) + compra(2:6, :) == usado(2:6, :) + estoque(2:6, :);





prob.Constraints.vegused = vegused;
prob.Constraints.nonvegused = nonvegused;
prob.Constraints.hardmin = hardmin;
prob.Constraints.hardmax = hardmax;
prob.Constraints.initstockbal = estoqueIncial;
prob.Constraints.stockbal = estoqueAtual;


opts = optimoptions('intlinprog','Heuristics','none');
[sol1,fval1,exitstatus1,output1] = solve(prob,'options',opts)

