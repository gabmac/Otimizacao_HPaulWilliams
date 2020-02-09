clear all;clc;

crude_numbers = [1:2];%oleos brutos
petrols = ["Premium_Fuel" "Regular_Fuel"];
end_product_names = ["Premium_fuel"  "Regular_fuel"  "Jet_fuel"  "Fuel_oil"  "Lube_oil"];%produtos finais
distillation_products_names = ["Light_naphtha"  "Medium_naphtha"  ...
    "Heavy_naphtha" "Light_oil"  "Heavy_oil"  "Residuum"];%produtos destilados
naphthas = ["Light_naphtha"  "Medium_naphtha"  "Heavy_naphtha"];
intermediate_oils = ["Light_oil"  "Heavy_oil"];
cracking_products_names = ["Cracked_gasoline"  "Cracked_oil"];%produtos feitos apos o cracking
used_for_motor_fuel_names = ["Light_naphtha"  "Medium_naphtha"  "Heavy_naphtha" ...
                             "Reformed_gasoline"  "Cracked_gasoline"];%produtos usados para produzir petrols
used_for_jet_fuel_names = ["Light_oil"  "Heavy_oil"  "Residuum"  "Cracked_oil"];%produtos usados para produzir combutivel de jato

crude_bounds = [20000 30000];%quantidade de barris de crude que podem ser usados por dia

%bounds para producao de oleo lubrificante
lb_lube_oil = 500;
ub_lube_oil = 1000;

max_crude = 45000;%maximo de barris de crude que podem ser destilados no dia
max_reform = 10000;%maximo de barris de naphta que podem ser reformados no dia
max_cracking = 8000;%maximo de barris de oleo que podem ser quebrados no dia

%
distillation_splitting_coefficients = [.1 .2 .2 .12 .2 .13;
                                        .15 .25 .18 .08 .19 .12];%crude x produtos
                                    %LO %HO
cracking_splitting_coefficients = [.28 .2 %Prod Cracked_gasoline
                                    .68 .75];%Cracked_oil;

reforming_splitting_coefficients = [.6 .52 0.45];%naphtas ->reformed gasoline
end_product_profit = [7 6 4 3.5 1.5];%contribuicao nas vendas do produto final
blending_coefficients = [10 3 4 1]/18;%Lo;HO;CO;R

octance_number_fuel = [ 94 84];%PF;RF

octance_number_coefficients = [90 80 70 115 105];%LN;MN;HN;RG;CG
                       
%

lube_oil_factor = 0.5;
pmf_rmf_ratio = 0.4;%porcentagem de combustivel premium

vapor_pressure_constants = [.6 1.5 .05];%pressao dos vapores para HO;R,LO

%%Variaveis


crudes  = optimvar('cr', crude_numbers, 'LowerBound', 0,'UpperBound',crude_bounds);


end_products   = optimvar('end_prod', end_product_names, 'LowerBound',0);



distillation_products = optimvar('dist_prod', distillation_products_names,...
    'LowerBound', 0);

reform_usage = optimvar('napthas_to_reformed_gasoline ', naphthas,...
    'LowerBound', 0);

reformed_gasoline = optimvar('reformed_gasoline');

cracking_usage  = optimvar('intermediate_oils_to_cracked_gasoline', intermediate_oils,...
    'LowerBound', 0);

cracking_products  = optimvar('cracking_prods', cracking_products_names,...
    'LowerBound', 0);

used_for_regular_motor_fuel = optimvar('motor_fuel_to_regular_motor_fuel', used_for_motor_fuel_names,...
    'LowerBound', 0);

used_for_premium_motor_fuel = optimvar('motor_fuel_to_premium_motor_fuel', used_for_motor_fuel_names,...
    'LowerBound', 0);

used_for_jet_fuel = optimvar('jet_fuel ', used_for_jet_fuel_names,...
    'LowerBound', 0);

used_for_lube_oil  = optimvar('residuum_used_for_lube_oil',...
    'LowerBound', 0);

%%Constrains
lowerBoundLubOil = end_products("Lube_oil") >= lb_lube_oil;

upperBoundLubOil = end_products("Lube_oil") <= ub_lube_oil;

maximun_crude = sum(crudes) <= max_crude;%capacidade de destilacao

maximun_reform = sum(reform_usage) <= max_reform;%capacidade de reformacao da naphta

maximun_cracking = sum(cracking_usage) <= max_cracking;%capacidade de cracking do oleo
        
splitting_distillation = sum(distillation_splitting_coefficients.*repmat(crudes',1,length(distillation_products_names))) == distillation_products;%a quantidade de produto destilado vai ser igual
%a a quantidade de crude usado na mistura

splitting_reforming = sum(reform_usage.*reforming_splitting_coefficients) == reformed_gasoline;%conversao do que foi usado naphta para gasolina reformada

splitting_cracking = sum(cracking_splitting_coefficients.*repmat(cracking_usage,2,1),2) == cracking_products';%convesao do Light Oil e Heavy Oil para Cracked gasoline e Cracked Oil

continuity = reform_usage + used_for_regular_motor_fuel(naphthas) + used_for_premium_motor_fuel(naphthas) == distillation_products(naphthas);% a soma do que foi usado de naphta tem que ser igual ao que tinha

continuity_cracked_gasoline = used_for_regular_motor_fuel("Cracked_gasoline") + used_for_premium_motor_fuel("Cracked_gasoline") == cracking_products("Cracked_gasoline");%soma do que foi usado de gasoline tem que ser igaul ao que tinha

continuity_reformed_gasoline = used_for_regular_motor_fuel("Reformed_gasoline") + used_for_premium_motor_fuel("Reformed_gasoline") == reformed_gasoline;%oque foi usado de gasolia reformado tem que ser igaul ao quanto tinha 

continuity_premium_fuel = sum(used_for_premium_motor_fuel) == end_products("Premium_fuel");%a quantidade de produtos usados para produzir o combustivel premium tem que ser manter ao final

continuity_regular_fuel = sum(used_for_regular_motor_fuel) == end_products("Regular_fuel");%a quantidade de produtos usados para produzir o combustivel regular tem que ser manter ao final

continuity_jet_fuel = sum(used_for_jet_fuel) == end_products("Jet_fuel");%a quantidade de produtos usados para produzir o combustivel de jato tem que ser manter ao final

fixed_proportion_oil_for_blending = cracking_usage(intermediate_oils) + used_for_jet_fuel(intermediate_oils)+ ...
    blending_coefficients(1:2)*end_products("Fuel_oil") == distillation_products(intermediate_oils);

fixed_proportion_cracked_oil_for_blending = used_for_jet_fuel("Cracked_oil") + blending_coefficients(3)*end_products("Fuel_oil") == ...
                cracking_products("Cracked_oil");

fixed_proportion_residuum_for_blending = used_for_lube_oil + used_for_jet_fuel("Residuum")+ blending_coefficients(4)*end_products("Fuel_oil") == ...
                distillation_products("Residuum");

lune_oil_is_05_of_residuum_used = lube_oil_factor*used_for_lube_oil == end_products("Lube_oil");%0.5 barril de oleo lubrificante e produzido por barril de residuum

pmf_div_rmf_must_be_40 = end_products("Premium_fuel") >= pmf_rmf_ratio*end_products("Regular_fuel");% aproducao de combustivel premium tem que ser no minmo  mais que 40% de combustivel regular

Octane_number_regular_fuel = sum(used_for_regular_motor_fuel.*octance_number_coefficients) >= octance_number_fuel(2) * end_products("Regular_fuel");%garatia da octagem do combustive regular

Octane_number_premium_fuel = sum(used_for_premium_motor_fuel.*octance_number_coefficients) >= octance_number_fuel(1) * end_products("Premium_fuel");%garatia da octagem do combustive premium

vapour_pressure = used_for_jet_fuel("Light_oil") + sum(vapor_pressure_constants.*used_for_jet_fuel(["Heavy_oil" "Cracked_oil" "Residuum"])) <= end_products("Jet_fuel");%Condicao de vapor

prob = optimproblem('ObjectiveSense', 'maximize');

prob.Constraints.lowerBoundLubOil = lowerBoundLubOil;
prob.Constraints.upperBoundLubOil = upperBoundLubOil;
prob.Constraints.maximun_crude = maximun_crude;
prob.Constraints.maximun_reform = maximun_reform;
prob.Constraints.maximun_cracking = maximun_cracking;
prob.Constraints.splitting_distillation = splitting_distillation;
prob.Constraints.splitting_reforming = splitting_reforming;
prob.Constraints.splitting_cracking = splitting_cracking;
prob.Constraints.continuity = continuity;
prob.Constraints.continuity_cracked_gasoline = continuity_cracked_gasoline;
prob.Constraints.continuity_reformed_gasoline = continuity_reformed_gasoline;
prob.Constraints.continuity_premium_fuel = continuity_premium_fuel;
prob.Constraints.continuity_regular_fuel = continuity_regular_fuel;
prob.Constraints.continuity_jet_fuel = continuity_jet_fuel;
prob.Constraints.fixed_proportion_oil_for_blending = fixed_proportion_oil_for_blending;
prob.Constraints.fixed_proportion_cracked_oil_for_blending = fixed_proportion_cracked_oil_for_blending;
prob.Constraints.fixed_proportion_residuum_for_blending = fixed_proportion_residuum_for_blending;
prob.Constraints.lune_oil_is_05_of_residuum_used = lune_oil_is_05_of_residuum_used;
prob.Constraints.pmf_div_rmf_must_be_40 = pmf_div_rmf_must_be_40;
prob.Constraints.Octane_number_regular_fuel = Octane_number_regular_fuel;
prob.Constraints.Octane_number_premium_fuel = Octane_number_premium_fuel;
prob.Constraints.vapour_pressure = vapour_pressure;

%%Objetivo

Objetivo = sum(end_products.*end_product_profit);

prob.Objective = Objetivo

opts = optimoptions('intlinprog','Heuristics','none');
[sol1,fval1,exitstatus1,output1] = solve(prob,'options',opts)




