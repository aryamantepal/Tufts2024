%{
This script loads a dataset and visualizes partitions generated by the
Multiscale Learning by Unsupervised Nonlinear Diffusion (M-LUND) clustering
algorithm.

One can load and analyze any of the following four datsets:

    1. Overlapping Gaussians in R^3.
    2. Concentric nonlinear rings in R^2.
    3. Data with bottlenecks in R^2. 
    4. The real-world Salinas A hyperspectral image.

Comparisons against related algorithms are supported on the Salinas A HSI
but not on synthetic datasets.

The figures generated by this script appear in the following paper: 

     - Murphy, James M and Polk, Sam L. "A Multiscale Environment for 
       Learning By Diffusion." In Preparation (2021).

(c) Sam L. Polk: samuel.polk@tufts.edu

%}
%%
profile off;
profile on;

%% Choose the dataset

prompt = 'Which dataset? \n 1) 3D Gaussians \n 2) 2D Nonlinear \n 3) 2D Bottleneck \n 4) 2D Manifold Data \n 5) Salinas A HSI\n';
DataSelected = input(prompt);

if DataSelected == 1
    
    disp('Finding suitable sample...')
    [X,Y] = gaussian_sample(1,3,1000,1000,100);
    compare_on = 0;
    data_name = 'Gaussians';
    load('gaussians-HP.mat')
    disp('Dataset generated')

elseif DataSelected ==2
    
    disp('Finding suitable sample...')
    [X,Y] = nonlinear_sample(0.2, 1.2, 4, 180, 1200, 4000, 100);
    compare_on = 0;
    data_name = 'Nonlinear';
    load('nonlinear-HP.mat')
    disp('Dataset generated')
    
elseif DataSelected == 3 
    
    disp('Finding suitable sample...') 
    [X,Y] = bottleneck_sample(0.35,  1, 5, 12, 1000, 1000, 100);
    compare_on = 0;

    data_name = 'Bottleneck';
    load('bottleneck-HP.mat')
    disp('Dataset generated')
    
elseif DataSelected == 4
    
    disp('Finding suita1ble sample...') 
    [X,Y] = multimodal_sample();
    compare_on = 0;
    
    data_name = 'Manifold';
    load('manifold-HP.mat')
    disp('Dataset generated')
    
elseif DataSelected == 5
    
    [X,Y] = extract_salinasA();
    data_name = 'SalinasA';
    load('salinasA-HP.mat')
    
    prompt = 'Should we compare against other algorithms? \n 1) Yes \n 2) No\n';
    compareSelected = input(prompt);
    
    if compareSelected == 1
        compare_on = 1;
        mms_on = check_MMS();
        disp('MMS clustering not in path, so it will not be evaluated.')
        disp('To run comparisons against MMS clustering, download these & add to your path:')
        disp(' - https://github.com/barahona-research-group/GraphBasedClustering')
        disp(' - https://www.imperial.ac.uk/~mpbara/Partition_Stability/')
    else
        compare_on = 0;
    end
    
else
    disp('Incorrect prompt input. Please enter one of [1,2,3,4].')
end

%% Choose whether to save results

prompt = 'Should we save everything? \n 1) Yes \n 2) No\n ';
SaveSelected = input(prompt);

if SaveSelected == 1

    save_on = 1;
    
elseif SaveSelected == 2

    save_on = 0;    
    
else
    disp('Incorrect prompt input. Please enter one of [1,2].')
end

%% Choose whether to plot results

prompt = 'Should we plot everything? \n 1) Yes \n 2) No\n';
PlotSelected = input(prompt);

if PlotSelected == 1

    plot_on = 1;
    
    % Choose whether to plot stochastic complements
    prompt = 'Should we plot the intervals? \nStochastic Complementation is computationally expensive. \n 1) Yes \n 2) No\n';
    PlotSelected = input(prompt);

    if PlotSelected == 1

        sc_on = 1;

    elseif PlotSelected == 2

        sc_on = 0;    

    else
        disp('Incorrect prompt input. Please enter one of [1,2].')
    end
    
    
    
elseif PlotSelected == 2

    plot_on = 0;    
    
else
    disp('Incorrect prompt input. Please enter one of [1,2].')
end


%% Run M-LUND

% % After loading the data
% [X, Y] = extract_salinasA();
% 
% % Apply PCA for dimensionality reduction
% [coeff, score, latent] = pca(X);
% explained = cumsum(latent) / sum(latent);
% numComponents = find(explained >= 0.95, 1); % Keep 95% of variance
% X_reduced = score(:, 1:numComponents);
% 
% % Use X_reduced instead of X for clustering
% Clusterings = M_LUND(X_reduced, Hyperparameters);
% 
% % Calculate and display accuracy for each non-trivial clustering
% n = length(X);
% nt_K = unique(Clusterings.K(and(Clusterings.K>=2, Clusterings.K<n/2)));
% for k = 1:length(nt_K)
%     t = find(Clusterings.K == nt_K(k), 1, 'first');
%     [accuracy, ~] = calculate_clustering_accuracy(Y, Clusterings.Labels(:,t));
%     disp(['Clustering with K = ', num2str(nt_K(k)), ' (t = ', num2str(t), '):']);
%     disp(['Accuracy: ', num2str(accuracy * 100, '%.2f'), '%']);
% end
% Load SalinasA data
[X, Y] = extract_salinasA();
data_name = 'SalinasA';

% Run M-LUND on original data
tic;
Clusterings_original = M_LUND(X, Hyperparameters);
time_original = toc;

% Apply LLE for dimensionality reduction
tic;
K = 12; % number of nearest neighbors, you may need to adjust this
d = 2;  % reduced dimensionality
X_lle = lle(X', K, d)'; % Note: lle function expects N x D input, so we transpose

% Run M-LUND on LLE reduced data
Clusterings_lle = M_LUND(X_lle, Hyperparameters);
time_lle = toc;

% After running M-LUND on both original and LLE reduced data
n = length(X);
nt_K_original = unique(Clusterings_original.K(and(Clusterings_original.K>=2, Clusterings_original.K<n/2)));
nt_K_lle = unique(Clusterings_lle.K(and(Clusterings_lle.K>=2, Clusterings_lle.K<n/2)));

% Combine unique K values from both clusterings
nt_K = unique([nt_K_original; nt_K_lle]);

for k = 1:length(nt_K)
    t_original = find(Clusterings_original.K == nt_K(k), 1, 'first');
    t_lle = find(Clusterings_lle.K == nt_K(k), 1, 'first');
    
    if ~isempty(t_original)
        [accuracy_original, ~] = calculate_clustering_accuracy(Y, Clusterings_original.Labels(:,t_original));
        disp(['Original data accuracy (K = ', num2str(nt_K(k)), '): ', num2str(accuracy_original * 100, '%.2f'), '%']);
    else
        disp(['Original data: No clustering found for K = ', num2str(nt_K(k))]);
    end
    
    if ~isempty(t_lle)
        [accuracy_lle, ~] = calculate_clustering_accuracy(Y, Clusterings_lle.Labels(:,t_lle));
        disp(['LLE reduced data accuracy (K = ', num2str(nt_K(k)), '): ', num2str(accuracy_lle * 100, '%.2f'), '%']);
    else
        disp(['LLE reduced data: No clustering found for K = ', num2str(nt_K(k))]);
    end
    
    disp('---');
end

disp(['Time for original data: ', num2str(time_original), ' seconds']);
disp(['Time for LLE reduced data (including LLE): ', num2str(time_lle), ' seconds']);

% Continue with the rest of your script (visualization, etc.)
if plot_on
    results_plot_original = plot_results(X, Clusterings_original, data_name, sc_on);
    results_plot_lle = plot_results(X_lle, Clusterings_lle, [data_name '_lle'], sc_on);
    
    % Additional visualization for LLE reduced data
    figure;
    scatter(X_lle(:,1), X_lle(:,2), 10, Y, 'filled');
    title('LLE of Salinas A data');
    xlabel('LLE 1');
    ylabel('LLE 2');
    colorbar;
end

% Continue with the rest of your script (visualization, etc.)
if plot_on
    results_plot_original = plot_results(X, Clusterings_original, data_name, sc_on);
    results_plot_reduced = plot_results(X_reduced, Clusterings_reduced, [data_name '_reduced'], sc_on);
end

%% 
if compare_on
    [C_MMS, C_HSC, C_SLC, C_SLLUND] = make_comparisons(X, Clusterings, mms_on, plot_on);
end

if save_on 
    if compare_on
        save(strcat('M_LUND_Results_', data_name, '.mat'), 'Clusterings', 'X', 'Y', 'Hyperparameters', 'data_name', 'C_MMS', 'C_HSC', 'C_SLC')
    else
        save(strcat('M_LUND_Results_', data_name, '.mat'), 'Clusterings', 'X', 'Y', 'Hyperparameters', 'data_name')
    end
end
%%

close all 
if plot_on
    % results_plot = plot_results(X, Clusterings, data_name, sc_on);
    % Visualize the reduced data
    figure;
    scatter3(score(:,1), score(:,2), score(:,3), 10, Y, 'filled');
    title('LLE of Salinas A data');
    xlabel('First Principal Component');
    ylabel('Second Principal Component');
    zlabel('Third Principal Component');
    colorbar;
    
    % Then call the original visualization function
    if plot_on
        results_plot = plot_results(X_reduced, Clusterings, data_name, sc_on);
    end
end


