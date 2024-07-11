[X,Y] = extract_salinasA();
data_name = 'SalinasA';
load('salinasA-HP.mat');

G = extract_graph(X, Hyperparameters);
p = KDE(X,Hyperparameters);

t = 43;

[C, K, Dt] = LearningbyUnsupervisedNonlinearDiffusion(X, t, G, p);

disp("Cluster labels:" +  C);
disp("Number of clusters:" + K);
% disp("Diffusion distances:" + Dt);
