function [T,R,states]=oneArmedMouselabMDP(nr_cells,mu_reward,sigma_reward,cost)

sigma0=sqrt(nr_cells)*sigma_reward;
mu_other=mu_reward*nr_cells;

resolution=sigma0/50;
mu_values=(mu_reward-2*sigma0):resolution:(mu_reward+2*sigma0);
sigma_values=sigma_reward*(0:nr_cells);
[MUs,SIGMAs]=meshgrid(mu_values,sigma_values);
nr_states=numel(MUs)+1; %each combination of mu and sigma is a state and there is one additional terminal state
nr_actions=2; %action 1: sample, action 2: act

%b) define transition matrix
T=zeros(nr_states,nr_states,nr_actions);
R=zeros(nr_states,nr_states,nr_actions);

R(:,:,1)=-cost; %cost of sampling

for from=1:(nr_states-1)
    
    current_mu=MUs(from);
    current_sigma=SIGMAs(from);
    
    if current_sigma>0 %there is still something to be observed
        sample_values=(mu_reward-3*current_sigma):resolution:(mu_reward+3*current_sigma);
        p_samples=discreteNormalPMF(sample_values,mu_reward,current_sigma);
        
        %In this case, the prior is the likelihood. Hence, both have the
        %same precision. Therefore, the posterior mean is the average of
        %the prior mean and the observation, and the posterior precision is
        %twice as high as the current precision.
        
        posterior_means  = (current_mu + sample_values - mu_reward );
        posterior_sigmas = sqrt(current_sigma^2-sigma_reward^2);
        
        [discrepancy_mu, mu_index] = min(abs(repmat(posterior_means,[numel(delta_mu_values),1])-...
            repmat(delta_mu_values',[1,numel(posterior_means)])));
        
        [discrepancy_sigma, sigma_index] = min(abs(repmat(posterior_sigmas,[numel(sigma_values),1])-...
            repmat(sigma_values',[1,numel(posterior_sigmas)])));
        
        to=struct('mu',delta_mu_values(mu_index),'sigma',sigma_values(sigma_index),...
            'index',sub2ind([numel(sigma_values),numel(delta_mu_values)],sigma_index,mu_index));
        
        %sum the probabilities of all samples that lead to the same state
        T(from,unique(to.index),1)=grpstats(p_samples,to.index,{@sum});
        
    else
        T(from,:,1)=[zeros(1,nr_states-1),0];
        R(from,:,1)=-cost;
    end
    
    %reward of acting
    R(from,nr_states,2)=max(mu_other,current_mu);
end
T(:,:,2)=repmat([zeros(1,nr_states-1),1],[nr_states,1]);
T(end,:,:)=repmat([zeros(1,nr_states-1),1],[1,1,2]);

start_state.index=sub2ind(size(MUs),find(sigma_values==start_state.sigma),...
    find(delta_mu_values==start_state.delta_mu));

states.MUs=MUs;
states.SIGMAs=SIGMAs;
states.start_state=start_state;
states.delta_mu_values=delta_mu_values;
states.sigma_values=sigma_values;
end