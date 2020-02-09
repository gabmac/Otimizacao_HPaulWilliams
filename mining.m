clear all;clc

mines = [1:4]; %quantidade de minas
years = [1:5];%qtd de anos
Royalties = [5 4 4 5]*1e6;%Royalties por mina
ExtractLimit = [2 2.5 1.3 3]*1e6;%Limite de Extracao de cada mina
OreQuality  = [1 .7 1.5 .5];%Qualidade de Minerio de cada mina
BlendedQuality = [.9 .8 1.2 .6 1];%Qualidade da Mistura por ano
discount = [];%taxa de desconto de 10 por cento ao ano

for year=1:1:length(years)
   discount = [discount (1/(1+1/10.0))^(year-1)]; 
end

mines_limit = 3;%limite de minas operantes ao ano
sell_price = 10;%preco de venda


%Variaveis
out = optimvar('output', string(mines), string(years), 'LowerBound', 0);
quan = optimvar('quantity',string(years), 'LowerBound', 0);
work = optimvar('working', string(mines), string(years), 'Type', 'integer', ...
    'LowerBound', 0, 'UpperBound', 1); %variavel binaria
open = optimvar('open', string(mines), string(years), 'Type', 'integer', ...
    'LowerBound', 0, 'UpperBound', 1); %variavel binaria

%Restricoes

AtMost3Mines = sum(work) <= mines_limit;%por ano no maximo 3 minas podem estar operante

Quality = sum(repmat(OreQuality',1,length(years)).*out,1) == BlendedQuality.*quan;%relacao da mistura entre o que foi retirado das minas e o que precisa ser entregue

OutQty = sum(out) == quan;%o produzido eh igual ao que foi retirado

ExtractLimit = out <= repmat(ExtractLimit',1,5).*work; % oque foir retirado em cada mina naquele ano nao pode exceder o limite

WorkingOpen = work <= open;%para uma mina estar trabalhando ela precisa estar aberta

SubsequentOpen = open(string(mines),string(years(2:length(years)))) <= open(string(mines),string(years(1:length(years)-1)));%uma mina uma vez fechada nao e reaberta


%Objetivo
Objetivo = sum(sell_price*discount.*quan) - sum( sum((Royalties'*discount).*open,2));

prob = optimproblem('ObjectiveSense', 'maximize');
prob.Objective = Objetivo

prob.Constraints.AtMost3Mines = AtMost3Mines;
prob.Constraints.Quality = Quality;
prob.Constraints.OutQty = OutQty;
prob.Constraints.ExtractLimit = ExtractLimit;
prob.Constraints.WorkingOpen = WorkingOpen;
prob.Constraints.SubsequentOpen = SubsequentOpen;

opts = optimoptions('intlinprog','Heuristics','none');
[sol1,fval1,exitstatus1,output1] = solve(prob,'options',opts)

